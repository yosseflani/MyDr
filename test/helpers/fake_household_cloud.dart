import 'dart:io';
import 'dart:typed_data';

import 'package:mydr/data/cloud/household_cloud.dart';

/// The household side of the cloud, in memory, shared by every simulated
/// device. Enforces what firebase/firestore.rules and storage.rules enforce:
/// only members read or write a household; only admins manage it; logs and
/// media are create-only; a device's log grows by exactly one each time.
class FakeHouseholdServer {
  FakeHouseholdServer({DateTime Function()? now}) : now = now ?? DateTime.now;

  DateTime Function() now;

  final Map<String, RemoteHousehold> households = {};
  final Map<String, Map<String, RemoteMember>> members = {};
  final Map<String, Map<String, Map<int, RemoteWrappedKey>>> keys = {};
  final Map<String, RemoteInvite> invites = {};
  final Map<String, Map<String, RemoteDevice>> devices = {};
  final Map<String, Map<String, Map<int, RemoteLogEntry>>> logs = {};
  final Map<String, Map<String, Uint8List>> media = {};

  /// Everything a server operator could read, for checking that nothing
  /// readable was uploaded.
  Uint8List get allBytes => Uint8List.fromList([
    for (final byDevice in logs.values)
      for (final entries in byDevice.values)
        for (final e in entries.values) ...e.data,
    for (final objects in media.values)
      for (final bytes in objects.values) ...bytes,
  ]);

  int get logEntryCount => [
    for (final byDevice in logs.values)
      for (final entries in byDevice.values) entries.length,
  ].fold(0, (a, b) => a + b);
}

/// One device's view of [FakeHouseholdServer], signed in as [uid].
class FakeHouseholdCloud implements HouseholdCloud {
  FakeHouseholdCloud(this.server, {required this.uid});

  final FakeHouseholdServer server;

  /// The signed-in account; null when signed out.
  String? Function() uid;

  /// Simulates having no connection: every call fails with a network error.
  bool offline = false;

  /// Fails the next append with a network error, after this many succeed.
  int? failAppendAfter;

  int calls = 0;

  String _caller() {
    calls++;
    if (offline) {
      throw const HouseholdCloudException(HouseholdCloudError.network);
    }
    final id = uid();
    if (id == null) _deny();
    return id;
  }

  Never _deny() =>
      throw const HouseholdCloudException(HouseholdCloudError.permissionDenied);

  bool _isMember(String hid, String uid) =>
      server.members[hid]?.containsKey(uid) ?? false;

  bool _isAdmin(String hid, String uid) =>
      server.members[hid]?[uid]?.role == 'admin';

  String _member(String hid) {
    final caller = _caller();
    if (!_isMember(hid, caller)) _deny();
    return caller;
  }

  String _admin(String hid) {
    final caller = _member(hid);
    if (!_isAdmin(hid, caller)) _deny();
    return caller;
  }

  @override
  Future<void> createHousehold({
    required String householdId,
    required RemoteMember creator,
    required RemoteWrappedKey key,
  }) async {
    final caller = _caller();
    if (server.households.containsKey(householdId) ||
        creator.uid != caller ||
        creator.role != 'admin') {
      _deny();
    }
    server.households[householdId] = RemoteHousehold(
      id: householdId,
      createdBy: caller,
      epoch: 1,
    );
    server.members[householdId] = {caller: creator};
    server.keys[householdId] = {
      caller: {key.epoch: key},
    };
  }

  @override
  Future<RemoteHousehold?> household(String householdId) async {
    _member(householdId);
    return server.households[householdId];
  }

  @override
  Future<List<RemoteMember>> members(String householdId) async {
    _member(householdId);
    return server.members[householdId]!.values.toList();
  }

  @override
  Future<List<RemoteWrappedKey>> wrappedKeys(
    String householdId,
    String uid,
  ) async {
    final caller = _member(householdId);
    if (caller != uid) _deny();
    return (server.keys[householdId]?[uid] ?? const {}).values.toList();
  }

  @override
  Future<void> createInvite(RemoteInvite invite) async {
    final caller = _admin(invite.householdId);
    if (invite.inviterUid != caller ||
        invite.status != InviteStatus.open ||
        server.invites.containsKey(invite.id)) {
      _deny();
    }
    server.invites[invite.id] = invite;
  }

  @override
  Future<RemoteInvite?> invite(String inviteId) async {
    _caller();
    return server.invites[inviteId];
  }

  @override
  Future<List<RemoteInvite>> invites(String householdId) async {
    _member(householdId);
    return [
      for (final i in server.invites.values)
        if (i.householdId == householdId) i,
    ];
  }

  @override
  Future<void> respondToInvite(RemoteInvite invite) async {
    final caller = _caller();
    final stored = server.invites[invite.id];
    if (stored == null ||
        stored.status != InviteStatus.open ||
        invite.inviteeUid != caller ||
        !stored.expiresAt.isAfter(server.now()) ||
        _isMember(stored.householdId, caller) ||
        (invite.status != InviteStatus.accepted &&
            invite.status != InviteStatus.rejected) ||
        invite.householdId != stored.householdId ||
        invite.inviterUid != stored.inviterUid) {
      _deny();
    }
    server.invites[invite.id] = invite;
  }

  @override
  Future<void> deleteInvite(String inviteId) async {
    final stored = server.invites[inviteId];
    if (stored == null) return;
    _admin(stored.householdId);
    server.invites.remove(inviteId);
  }

  @override
  Future<void> addMember({
    required String householdId,
    required RemoteMember member,
    required List<RemoteWrappedKey> keys,
    required String inviteId,
  }) async {
    _admin(householdId);
    final invite = server.invites[inviteId];
    if (invite == null || invite.status != InviteStatus.accepted) _deny();
    server.members[householdId]![member.uid] = member;
    server.keys[householdId]![member.uid] = {for (final k in keys) k.epoch: k};
    server.invites[inviteId] = invite.respond(
      status: InviteStatus.completed,
      inviteeUid: invite.inviteeUid!,
      inviteePublicKey: invite.inviteePublicKey,
      inviteeMac: invite.inviteeMac,
      inviteeLabel: invite.inviteeLabel,
    );
  }

  @override
  Future<void> updateMembers(
    String householdId,
    List<RemoteMember> members,
  ) async {
    _admin(householdId);
    for (final m in members) {
      server.members[householdId]![m.uid] = m;
    }
  }

  @override
  Future<void> rotate({
    required String householdId,
    required int epoch,
    required List<String> removeUids,
    required List<RemoteMember> members,
    required Map<String, RemoteWrappedKey> keys,
  }) async {
    _admin(householdId);
    final household = server.households[householdId]!;
    if (epoch != household.epoch + 1) _deny();
    for (final uid in removeUids) {
      server.members[householdId]!.remove(uid);
      server.keys[householdId]!.remove(uid);
    }
    for (final m in members) {
      server.members[householdId]![m.uid] = m;
    }
    for (final MapEntry(key: uid, value: key) in keys.entries) {
      server.keys[householdId]!.putIfAbsent(uid, () => {})[key.epoch] = key;
    }
    server.households[householdId] = RemoteHousehold(
      id: householdId,
      createdBy: household.createdBy,
      epoch: epoch,
    );
  }

  @override
  Future<void> leave({required String householdId, required String uid}) async {
    final caller = _member(householdId);
    if (caller != uid) _deny();
    server.members[householdId]!.remove(uid);
    server.keys[householdId]!.remove(uid);
    final household = server.households[householdId]!;
    server.households[householdId] = RemoteHousehold(
      id: householdId,
      createdBy: household.createdBy,
      epoch: household.epoch,
      needsRotation: true,
    );
  }

  @override
  Future<List<RemoteDevice>> devices(String householdId) async {
    _member(householdId);
    return (server.devices[householdId] ?? const {}).values.toList();
  }

  @override
  Future<List<RemoteLogEntry>> logEntries(
    String householdId,
    String deviceId, {
    required int afterSeq,
  }) async {
    _member(householdId);
    final entries = server.logs[householdId]?[deviceId] ?? const {};
    return [
      for (final e in entries.values)
        if (e.seq > afterSeq) e,
    ]..sort((a, b) => a.seq.compareTo(b.seq));
  }

  @override
  Future<void> appendLog(String householdId, RemoteLogEntry entry) async {
    final caller = _member(householdId);
    if (failAppendAfter case final n?) {
      if (n <= 0) {
        failAppendAfter = null;
        throw const HouseholdCloudException(HouseholdCloudError.network);
      }
      failAppendAfter = n - 1;
    }
    final devices = server.devices.putIfAbsent(householdId, () => {});
    final device = devices[entry.deviceId];
    final expected = (device?.lastSeq ?? 0) + 1;
    if (entry.uid != caller ||
        (device != null && device.uid != caller) ||
        entry.seq != expected) {
      _deny();
    }
    final log = server.logs
        .putIfAbsent(householdId, () => {})
        .putIfAbsent(entry.deviceId, () => {});
    if (log.containsKey(entry.seq)) _deny();
    log[entry.seq] = entry;
    devices[entry.deviceId] = RemoteDevice(
      deviceId: entry.deviceId,
      uid: caller,
      lastSeq: entry.seq,
    );
  }

  @override
  Future<void> uploadMedia(String householdId, String object, File file) async {
    _member(householdId);
    final objects = server.media.putIfAbsent(householdId, () => {});
    if (objects.containsKey(object)) _deny();
    objects[object] = await file.readAsBytes();
  }

  @override
  Future<void> downloadMedia(
    String householdId,
    String object,
    File target,
  ) async {
    _member(householdId);
    final bytes = server.media[householdId]?[object];
    if (bytes == null) {
      throw const HouseholdCloudException(HouseholdCloudError.notFound);
    }
    await target.writeAsBytes(bytes);
  }
}
