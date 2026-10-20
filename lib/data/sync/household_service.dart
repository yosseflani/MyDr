import 'dart:convert';
import 'dart:math';

import 'package:mydr/data/cloud/account_service.dart';
import 'package:mydr/data/cloud/household_cloud.dart';
import 'package:mydr/data/cloud/recovery_key_store.dart';
import 'package:mydr/data/models/sync_state.dart';
import 'package:mydr/data/repositories/sync_state_repository.dart';
import 'package:mydr/data/sync/household_crypto.dart';

/// Why a household action failed. Never carries data.
enum HouseholdFailure {
  network,

  /// Refused by the server's rules.
  permissionDenied,

  /// Mistyped, or no invitation has this code.
  invalidCode,
  expired,

  /// The invitation was already answered or used.
  alreadyUsed,

  /// A key or invitation did not check out: it was changed, or does not
  /// come from who it claims. Nothing was accepted.
  verificationFailed,

  /// Only an admin may do this.
  notAdmin,

  /// The household needs at least one admin.
  lastAdmin,

  /// This device has no key for the household's data.
  keyUnavailable,

  /// This device is already in a household.
  alreadyInHousehold,

  /// Not in a household, or signed in with another account.
  notInHousehold,

  /// This account is no longer a member.
  removed,
  unknown,
}

class HouseholdException implements Exception {
  const HouseholdException(this.failure);

  final HouseholdFailure failure;

  @override
  String toString() => 'HouseholdException(${failure.name})';
}

/// A member as shown to the user.
class HouseholdMemberView {
  const HouseholdMemberView({
    required this.uid,
    required this.role,
    required this.fingerprint,
    required this.isMe,
    required this.verified,
    this.label,
  });

  final String uid;
  final HouseholdRole role;
  final String? label;

  /// Of the member's public key, for comparing in person.
  final String fingerprint;
  final bool isMe;

  /// Whether the entry's attestation checked out under the current key. An
  /// unverified member is never given keys.
  final bool verified;

  @override
  String toString() => 'HouseholdMemberView($uid)';
}

/// An invitation found by its code, already checked against the code.
class InvitePreview {
  const InvitePreview._({
    required this.invite,
    required this.code,
    required this.inviterFingerprint,
  });

  final RemoteInvite invite;
  final InviteCode code;
  final String inviterFingerprint;

  String? get inviterLabel => invite.inviterLabel;
  DateTime get expiresAt => invite.expiresAt;

  @override
  String toString() => 'InvitePreview(${invite.id})';
}

/// An invitation as shown to an admin.
class InviteView {
  const InviteView({
    required this.id,
    required this.status,
    required this.createdAt,
    required this.expiresAt,
    required this.verified,
    this.inviteeLabel,
    this.inviteeFingerprint,
  });

  final String id;
  final InviteStatus status;
  final DateTime createdAt;
  final DateTime expiresAt;

  /// For an accepted invitation: whether the invitee's key checked out
  /// against the code this device holds. Only then can it be completed.
  final bool verified;
  final String? inviteeLabel;
  final String? inviteeFingerprint;

  @override
  String toString() => 'InviteView($id)';
}

/// Creating and managing a household: membership, invitations and keys.
///
/// The server stores memberships so its rules can let only members in, but
/// it is never trusted with keys: every household key is wrapped for each
/// member on a member's device, invitation keys are checked against the
/// code passed outside the app, and member entries carry attestations only
/// a member can make. Removing a member starts a new key epoch.
class HouseholdService {
  HouseholdService({
    required HouseholdCloud cloud,
    required SyncKeyStore keys,
    required SyncStateRepository state,
    DateTime Function() clock = DateTime.now,
    Random? random,
  }) : _cloud = cloud,
       _keys = keys,
       _state = state,
       _clock = clock,
       _random = random ?? Random.secure();

  /// How long an invitation can be answered.
  static const Duration inviteLifetime = Duration(hours: 48);

  final HouseholdCloud _cloud;
  final SyncKeyStore _keys;
  final SyncStateRepository _state;
  final DateTime Function() _clock;
  final Random _random;

  /// This account's identity on this device, created the first time.
  Future<IdentityKeyPair> identity(String uid) => _guard(() async {
    var seed = await _keys.readIdentitySeed(uid);
    if (seed == null) {
      seed = HouseholdCrypto.newIdentitySeed(_random);
      await _keys.writeIdentitySeed(uid, seed);
    }
    return IdentityKeyPair.fromSeed(seed);
  });

  /// Creates a household with this account as its admin.
  Future<String> create(Account account) => _guard(() async {
    final settings = await _state.settings();
    if (settings.state == SyncState.active ||
        settings.state == SyncState.joining) {
      throw const HouseholdException(HouseholdFailure.alreadyInHousehold);
    }
    final me = await identity(account.uid);
    final householdId = HouseholdCrypto.newId(_random);
    final key = HouseholdCrypto.newHouseholdKey(_random);
    final creator = await _attested(
      householdId: householdId,
      key: key,
      epoch: 1,
      uid: account.uid,
      publicKey: me.publicKey,
      role: HouseholdRole.admin,
      addedBy: account.uid,
      label: account.email,
    );
    final wrapped = await HouseholdCrypto.wrapKey(
      householdKey: key,
      wrapper: me,
      recipientPublicKey: me.publicKey,
      context: _wrapContext(householdId, 1, account.uid, account.uid),
      random: _random,
    );
    await _keys.writeHouseholdKeys(householdId, {1: key});
    try {
      await _cloud.createHousehold(
        householdId: householdId,
        creator: creator,
        key: RemoteWrappedKey(
          epoch: 1,
          wrappedBy: account.uid,
          wrapped: wrapped,
        ),
      );
    } catch (_) {
      await _keys.deleteHouseholdKeys(householdId);
      rethrow;
    }
    await _state.clearHousehold();
    await _state.saveSettings(
      (await _state.settings()).copyWith(
        householdId: () => householdId,
        accountUid: () => account.uid,
        role: () => HouseholdRole.admin,
        state: SyncState.active,
        nextSeq: 1,
      ),
    );
    await _state.saveKnownMember(_known(creator));
    return householdId;
  });

  /// Creates an invitation and returns its code, to show once and pass to
  /// the other parent outside the app. Admins only.
  Future<InviteCode> invite(Account account) => _guard(() async {
    final settings = await _active(account);
    if (settings.role != HouseholdRole.admin) {
      throw const HouseholdException(HouseholdFailure.notAdmin);
    }
    final householdId = settings.householdId!;
    final me = await identity(account.uid);
    final code = InviteCode.generate(_random);
    final id = await HouseholdCrypto.inviteId(code);
    final now = _clock();
    final expiresAt = now.add(inviteLifetime);
    final mac = await HouseholdCrypto.mac(
      code.bytes,
      'invite inviter',
      _inviterParts(
        id: id,
        householdId: householdId,
        uid: account.uid,
        publicKey: me.publicKey,
        label: account.email,
        expiresAt: expiresAt,
      ),
    );
    await _keys.writeInviteSecret(id, code.bytes);
    await _cloud.createInvite(
      RemoteInvite(
        id: id,
        householdId: householdId,
        inviterUid: account.uid,
        inviterPublicKey: me.publicKey,
        inviterMac: mac,
        inviterLabel: account.email,
        createdAt: now,
        expiresAt: expiresAt,
      ),
    );
    return code;
  });

  /// Finds the invitation with [codeText] and checks it against the code.
  Future<InvitePreview> lookup(Account account, String codeText) =>
      _guard(() async {
        final settings = await _state.settings();
        if (settings.state == SyncState.active ||
            settings.state == SyncState.joining) {
          throw const HouseholdException(HouseholdFailure.alreadyInHousehold);
        }
        final InviteCode code;
        try {
          code = InviteCode.parse(codeText);
        } on FormatException {
          throw const HouseholdException(HouseholdFailure.invalidCode);
        }
        final id = await HouseholdCrypto.inviteId(code);
        final invite = await _cloud.invite(id);
        if (invite == null) {
          throw const HouseholdException(HouseholdFailure.invalidCode);
        }
        final authentic = await HouseholdCrypto.verifyMac(
          code.bytes,
          'invite inviter',
          _inviterParts(
            id: invite.id,
            householdId: invite.householdId,
            uid: invite.inviterUid,
            publicKey: invite.inviterPublicKey,
            label: invite.inviterLabel,
            expiresAt: invite.expiresAt,
          ),
          invite.inviterMac,
        );
        if (!authentic || invite.id != id) {
          throw const HouseholdException(HouseholdFailure.verificationFailed);
        }
        if (invite.status != InviteStatus.open) {
          throw const HouseholdException(HouseholdFailure.alreadyUsed);
        }
        if (!invite.expiresAt.isAfter(_clock())) {
          throw const HouseholdException(HouseholdFailure.expired);
        }
        if (invite.inviterUid == account.uid) {
          throw const HouseholdException(HouseholdFailure.alreadyInHousehold);
        }
        return InvitePreview._(
          invite: invite,
          code: code,
          inviterFingerprint: HouseholdCrypto.fingerprint(
            invite.inviterPublicKey,
          ),
        );
      });

  /// Accepts or rejects an invitation. Accepting sends this account's
  /// public key, authenticated with the code; the inviter then adds it.
  Future<void> respond(
    Account account,
    InvitePreview preview, {
    required bool accept,
  }) => _guard(() async {
    final invite = preview.invite;
    if (!accept) {
      await _cloud.respondToInvite(
        invite.respond(status: InviteStatus.rejected, inviteeUid: account.uid),
      );
      return;
    }
    final me = await identity(account.uid);
    final mac = await HouseholdCrypto.mac(
      preview.code.bytes,
      'invite invitee',
      _inviteeParts(
        id: invite.id,
        householdId: invite.householdId,
        uid: account.uid,
        publicKey: me.publicKey,
        label: account.email,
      ),
    );
    await _cloud.respondToInvite(
      invite.respond(
        status: InviteStatus.accepted,
        inviteeUid: account.uid,
        inviteePublicKey: me.publicKey,
        inviteeMac: mac,
        inviteeLabel: account.email,
      ),
    );
    await _state.clearHousehold();
    // The inviter's key is verified by the code: it is what this device
    // will accept household keys from.
    await _state.saveKnownMember(
      KnownMember(
        uid: invite.inviterUid,
        publicKey: base64Encode(invite.inviterPublicKey),
        role: HouseholdRole.admin,
        label: invite.inviterLabel,
      ),
    );
    await _state.saveSettings(
      (await _state.settings()).copyWith(
        householdId: () => invite.householdId,
        accountUid: () => account.uid,
        role: () => null,
        state: SyncState.joining,
        inviteId: () => invite.id,
        nextSeq: 1,
      ),
    );
  });

  /// Stops waiting to be added (e.g. the invitation was withdrawn).
  Future<void> cancelJoining() => _guard(() => _state.clearHousehold());

  /// The household's invitations, for an admin.
  Future<List<InviteView>> invites(Account account) => _guard(() async {
    final settings = await _active(account);
    final views = <InviteView>[];
    for (final invite in await _cloud.invites(settings.householdId!)) {
      final verified = await _inviteeVerified(invite);
      final key = invite.inviteePublicKey;
      views.add(
        InviteView(
          id: invite.id,
          status: invite.status,
          createdAt: invite.createdAt,
          expiresAt: invite.expiresAt,
          verified: verified,
          inviteeLabel: invite.inviteeLabel,
          inviteeFingerprint: verified && key != null
              ? HouseholdCrypto.fingerprint(key)
              : null,
        ),
      );
    }
    views.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return views;
  });

  /// Adds the account that accepted [inviteId]: wraps every household key
  /// for its verified public key. Admins only.
  Future<void> completeInvite(
    Account account,
    String inviteId, {
    required HouseholdRole role,
  }) => _guard(() async {
    final settings = await _active(account);
    if (settings.role != HouseholdRole.admin) {
      throw const HouseholdException(HouseholdFailure.notAdmin);
    }
    final householdId = settings.householdId!;
    final invite = await _cloud.invite(inviteId);
    if (invite == null || invite.householdId != householdId) {
      throw const HouseholdException(HouseholdFailure.invalidCode);
    }
    if (invite.status != InviteStatus.accepted) {
      throw const HouseholdException(HouseholdFailure.alreadyUsed);
    }
    final inviteeUid = invite.inviteeUid;
    final inviteeKey = invite.inviteePublicKey;
    if (inviteeUid == null ||
        inviteeKey == null ||
        !await _inviteeVerified(invite)) {
      throw const HouseholdException(HouseholdFailure.verificationFailed);
    }
    final household = await _requireHousehold(account, householdId);
    final keys = await _keys.readHouseholdKeys(householdId);
    final current = keys[household.epoch];
    if (current == null) {
      throw const HouseholdException(HouseholdFailure.keyUnavailable);
    }
    final me = await identity(account.uid);
    final wrapped = [
      for (final MapEntry(key: epoch, value: key) in keys.entries)
        RemoteWrappedKey(
          epoch: epoch,
          wrappedBy: account.uid,
          wrapped: await HouseholdCrypto.wrapKey(
            householdKey: key,
            wrapper: me,
            recipientPublicKey: inviteeKey,
            context: _wrapContext(householdId, epoch, account.uid, inviteeUid),
            random: _random,
          ),
        ),
    ];
    final member = await _attested(
      householdId: householdId,
      key: current,
      epoch: household.epoch,
      uid: inviteeUid,
      publicKey: inviteeKey,
      role: role,
      addedBy: account.uid,
      label: invite.inviteeLabel,
    );
    await _cloud.addMember(
      householdId: householdId,
      member: member,
      keys: wrapped,
      inviteId: inviteId,
    );
    await _keys.deleteInviteSecret(inviteId);
    await _state.saveKnownMember(_known(member));
  });

  /// Withdraws an invitation (admins).
  Future<void> cancelInvite(String inviteId) => _guard(() async {
    await _cloud.deleteInvite(inviteId);
    await _keys.deleteInviteSecret(inviteId);
  });

  /// While joining: whether the inviter has added this account. Once added,
  /// unwraps the household keys and becomes active.
  Future<bool> checkJoined(Account account) => _guard(() async {
    final settings = await _state.settings();
    final householdId = settings.householdId;
    if (settings.state != SyncState.joining ||
        householdId == null ||
        settings.accountUid != account.uid) {
      throw const HouseholdException(HouseholdFailure.notInHousehold);
    }
    final RemoteHousehold? household;
    try {
      household = await _cloud.household(householdId);
    } on HouseholdCloudException catch (e) {
      if (e.error == HouseholdCloudError.permissionDenied) return false;
      rethrow;
    }
    if (household == null) return false;
    await _unwrapKeys(account, householdId);
    final members = await _verifiedMembers(account, householdId, household);
    final mine = members.where((m) => m.isMe && m.verified).firstOrNull;
    if (mine == null) {
      throw const HouseholdException(HouseholdFailure.verificationFailed);
    }
    await _state.saveSettings(
      (await _state.settings()).copyWith(
        role: () => mine.role,
        state: SyncState.active,
        inviteId: () => null,
      ),
    );
    return true;
  });

  /// The household as the server has it, after checking this account is
  /// still a member; detects removal (and then forgets the household on
  /// this device, keeping all family data).
  Future<RemoteHousehold> household(Account account) => _guard(() async {
    final settings = await _active(account);
    return _requireHousehold(account, settings.householdId!);
  });

  /// Unwraps any household key this device does not have yet, accepting
  /// only keys wrapped by a member whose key this device verified.
  Future<Map<int, List<int>>> ensureKeys(Account account) => _guard(() async {
    final settings = await _active(account);
    return _unwrapKeys(account, settings.householdId!);
  });

  /// The members, each checked against its attestation; verified ones are
  /// remembered (pinned) on this device.
  Future<List<HouseholdMemberView>> members(Account account) =>
      _guard(() async {
        final settings = await _active(account);
        final householdId = settings.householdId!;
        final household = await _requireHousehold(account, householdId);
        return _verifiedMembers(account, householdId, household);
      });

  /// Removes [uid] and starts a new key epoch for everyone else. Admins.
  Future<void> revoke(Account account, String uid) => _guard(() async {
    final settings = await _active(account);
    if (settings.role != HouseholdRole.admin) {
      throw const HouseholdException(HouseholdFailure.notAdmin);
    }
    if (uid == account.uid) {
      throw const HouseholdException(HouseholdFailure.lastAdmin);
    }
    await _rotate(account, settings.householdId!, remove: {uid});
  });

  /// Gives [uid] another role. Admins; the household keeps an admin.
  Future<void> setRole(Account account, String uid, HouseholdRole role) =>
      _guard(() async {
        final settings = await _active(account);
        if (settings.role != HouseholdRole.admin) {
          throw const HouseholdException(HouseholdFailure.notAdmin);
        }
        final householdId = settings.householdId!;
        final household = await _requireHousehold(account, householdId);
        final members = await _cloud.members(householdId);
        final admins = members.where((m) => m.role == HouseholdRole.admin.name);
        if (role != HouseholdRole.admin &&
            admins.length <= 1 &&
            admins.any((m) => m.uid == uid)) {
          throw const HouseholdException(HouseholdFailure.lastAdmin);
        }
        final target = members.where((m) => m.uid == uid).firstOrNull;
        if (target == null) {
          throw const HouseholdException(HouseholdFailure.unknown);
        }
        final key = (await _keys.readHouseholdKeys(
          householdId,
        ))[household.epoch];
        if (key == null) {
          throw const HouseholdException(HouseholdFailure.keyUnavailable);
        }
        final updated = await _attested(
          householdId: householdId,
          key: key,
          epoch: household.epoch,
          uid: uid,
          publicKey: target.publicKey,
          role: role,
          addedBy: target.addedBy,
          label: target.label,
        );
        await _cloud.updateMembers(householdId, [updated]);
        await _state.saveKnownMember(_known(updated));
        if (uid == account.uid) {
          await _state.saveSettings(settings.copyWith(role: () => role));
        }
      });

  /// Leaves the household: this account loses access and an admin's next
  /// sync rotates the key. All family data stays on this device.
  Future<void> leave(Account account) => _guard(() async {
    final settings = await _state.settings();
    final householdId = settings.householdId;
    if (settings.state == SyncState.joining || householdId == null) {
      await _state.clearHousehold();
      return;
    }
    if (settings.accountUid != account.uid) {
      throw const HouseholdException(HouseholdFailure.notInHousehold);
    }
    final members = await _cloud.members(householdId);
    final otherAdmins = members.where(
      (m) => m.uid != account.uid && m.role == HouseholdRole.admin.name,
    );
    if (settings.role == HouseholdRole.admin &&
        members.length > 1 &&
        otherAdmins.isEmpty) {
      throw const HouseholdException(HouseholdFailure.lastAdmin);
    }
    await _cloud.leave(householdId: householdId, uid: account.uid);
    await _forget(householdId, SyncState.off);
  });

  /// Rotates the key if a member left on their own (admins only; others
  /// leave it to an admin).
  Future<void> rotateIfRequested(Account account) => _guard(() async {
    final settings = await _active(account);
    if (settings.role != HouseholdRole.admin) return;
    final householdId = settings.householdId!;
    final household = await _requireHousehold(account, householdId);
    if (household.needsRotation) {
      await _rotate(account, householdId, remove: const {});
    }
  });

  Future<void> _rotate(
    Account account,
    String householdId, {
    required Set<String> remove,
  }) async {
    final household = await _requireHousehold(account, householdId);
    final keys = await _keys.readHouseholdKeys(householdId);
    final views = await _verifiedMembers(account, householdId, household);
    final remote = await _cloud.members(householdId);
    // Unverified entries get no new key: whatever they are, they are out.
    final keep = [
      for (final m in remote)
        if (!remove.contains(m.uid) &&
            views.any((v) => v.uid == m.uid && v.verified))
          m,
    ];
    final removeUids = [
      for (final m in remote)
        if (!keep.contains(m)) m.uid,
    ];
    final epoch = household.epoch + 1;
    final key = HouseholdCrypto.newHouseholdKey(_random);
    final me = await identity(account.uid);
    final wrapped = <String, RemoteWrappedKey>{};
    final members = <RemoteMember>[];
    for (final m in keep) {
      wrapped[m.uid] = RemoteWrappedKey(
        epoch: epoch,
        wrappedBy: account.uid,
        wrapped: await HouseholdCrypto.wrapKey(
          householdKey: key,
          wrapper: me,
          recipientPublicKey: m.publicKey,
          context: _wrapContext(householdId, epoch, account.uid, m.uid),
          random: _random,
        ),
      );
      members.add(
        await _attested(
          householdId: householdId,
          key: key,
          epoch: epoch,
          uid: m.uid,
          publicKey: m.publicKey,
          role: HouseholdRole.values.byName(m.role),
          addedBy: m.addedBy,
          label: m.label,
        ),
      );
    }
    await _keys.writeHouseholdKeys(householdId, {...keys, epoch: key});
    await _cloud.rotate(
      householdId: householdId,
      epoch: epoch,
      removeUids: removeUids,
      members: members,
      keys: wrapped,
    );
    for (final uid in removeUids) {
      await _state.deleteKnownMember(uid);
    }
  }

  Future<Map<int, List<int>>> _unwrapKeys(
    Account account,
    String householdId,
  ) async {
    final have = await _keys.readHouseholdKeys(householdId);
    final wrapped = await _cloud.wrappedKeys(householdId, account.uid);
    final missing = wrapped.where((w) => !have.containsKey(w.epoch)).toList()
      ..sort((a, b) => a.epoch.compareTo(b.epoch));
    if (missing.isEmpty) return have;
    final known = {for (final m in await _state.knownMembers()) m.uid: m};
    final me = await identity(account.uid);
    final added = <int, List<int>>{};
    for (final w in missing) {
      final wrapper = known[w.wrappedBy];
      // Only from a member this device verified; anything else is ignored.
      if (wrapper == null || wrapper.role != HouseholdRole.admin) continue;
      try {
        added[w.epoch] = await HouseholdCrypto.unwrapKey(
          wrapped: w.wrapped,
          recipient: me,
          wrapperPublicKey: base64Decode(wrapper.publicKey),
          context: _wrapContext(householdId, w.epoch, w.wrappedBy, account.uid),
        );
      } on HouseholdCryptoException {
        // Not authentic: never used.
      }
    }
    if (added.isEmpty) return have;
    final all = {...have, ...added};
    await _keys.writeHouseholdKeys(householdId, all);
    return all;
  }

  Future<List<HouseholdMemberView>> _verifiedMembers(
    Account account,
    String householdId,
    RemoteHousehold household,
  ) async {
    final keys = await _keys.readHouseholdKeys(householdId);
    final key = keys[household.epoch];
    final known = {for (final m in await _state.knownMembers()) m.uid: m};
    final remote = await _cloud.members(householdId);
    final views = <HouseholdMemberView>[];
    for (final m in remote) {
      final role = HouseholdRole.values
          .where((r) => r.name == m.role)
          .firstOrNull;
      var verified =
          key != null &&
          role != null &&
          m.attestedEpoch == household.epoch &&
          await HouseholdCrypto.verifyMac(
            key,
            'member attestation',
            _attestationParts(
              householdId,
              household.epoch,
              m.uid,
              m.publicKey,
              m.role,
              m.label,
            ),
            m.attestation,
          );
      final pinned = known[m.uid];
      // A member's key never changes: a different one is not trusted.
      if (pinned != null && pinned.publicKey != base64Encode(m.publicKey)) {
        verified = false;
      }
      if (verified) await _state.saveKnownMember(_known(m));
      views.add(
        HouseholdMemberView(
          uid: m.uid,
          role: role ?? HouseholdRole.member,
          label: m.label,
          fingerprint: HouseholdCrypto.fingerprint(m.publicKey),
          isMe: m.uid == account.uid,
          verified: verified,
        ),
      );
    }
    for (final uid in known.keys) {
      if (!remote.any((m) => m.uid == uid)) await _state.deleteKnownMember(uid);
    }
    views.sort((a, b) {
      if (a.isMe != b.isMe) return a.isMe ? -1 : 1;
      return a.uid.compareTo(b.uid);
    });
    return views;
  }

  /// The household, or [HouseholdFailure.removed] (after forgetting it on
  /// this device) when this account is no longer a member.
  Future<RemoteHousehold> _requireHousehold(
    Account account,
    String householdId,
  ) async {
    RemoteHousehold? household;
    try {
      household = await _cloud.household(householdId);
    } on HouseholdCloudException catch (e) {
      if (e.error != HouseholdCloudError.permissionDenied) rethrow;
    }
    if (household == null) {
      await _forget(householdId, SyncState.removed);
      throw const HouseholdException(HouseholdFailure.removed);
    }
    return household;
  }

  Future<void> _forget(String householdId, SyncState state) async {
    await _state.clearHousehold(state: state);
    await _keys.deleteHouseholdKeys(householdId);
  }

  Future<SyncSettings> _active(Account account) async {
    final settings = await _state.settings();
    if (!settings.isActive || settings.accountUid != account.uid) {
      throw const HouseholdException(HouseholdFailure.notInHousehold);
    }
    return settings;
  }

  Future<bool> _inviteeVerified(RemoteInvite invite) async {
    final uid = invite.inviteeUid;
    final key = invite.inviteePublicKey;
    final mac = invite.inviteeMac;
    if (invite.status != InviteStatus.accepted ||
        uid == null ||
        key == null ||
        mac == null) {
      return false;
    }
    final secret = await _keys.readInviteSecret(invite.id);
    if (secret == null) return false;
    return HouseholdCrypto.verifyMac(
      secret,
      'invite invitee',
      _inviteeParts(
        id: invite.id,
        householdId: invite.householdId,
        uid: uid,
        publicKey: key,
        label: invite.inviteeLabel,
      ),
      mac,
    );
  }

  Future<RemoteMember> _attested({
    required String householdId,
    required List<int> key,
    required int epoch,
    required String uid,
    required List<int> publicKey,
    required HouseholdRole role,
    required String addedBy,
    String? label,
  }) async => RemoteMember(
    uid: uid,
    publicKey: publicKey,
    role: role.name,
    addedBy: addedBy,
    label: label,
    attestedEpoch: epoch,
    attestation: await HouseholdCrypto.mac(
      key,
      'member attestation',
      _attestationParts(householdId, epoch, uid, publicKey, role.name, label),
    ),
  );

  static List<Object> _attestationParts(
    String householdId,
    int epoch,
    String uid,
    List<int> publicKey,
    String role,
    String? label,
  ) => [householdId, '$epoch', uid, publicKey, role, label ?? ''];

  static List<Object> _inviterParts({
    required String id,
    required String householdId,
    required String uid,
    required List<int> publicKey,
    required String? label,
    required DateTime expiresAt,
  }) => [
    id,
    householdId,
    uid,
    publicKey,
    label ?? '',
    '${expiresAt.toUtc().microsecondsSinceEpoch}',
  ];

  static List<Object> _inviteeParts({
    required String id,
    required String householdId,
    required String uid,
    required List<int> publicKey,
    required String? label,
  }) => [id, householdId, uid, publicKey, label ?? ''];

  static String _wrapContext(
    String householdId,
    int epoch,
    String from,
    String to,
  ) => 'household/$householdId/epoch/$epoch/from/$from/to/$to';

  static KnownMember _known(RemoteMember m) => KnownMember(
    uid: m.uid,
    publicKey: base64Encode(m.publicKey),
    role: HouseholdRole.values.byName(m.role),
    label: m.label,
  );

  /// Turns every failure into a [HouseholdException].
  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on HouseholdException {
      rethrow;
    } on HouseholdCloudException catch (e) {
      throw HouseholdException(switch (e.error) {
        HouseholdCloudError.network => HouseholdFailure.network,
        HouseholdCloudError.permissionDenied =>
          HouseholdFailure.permissionDenied,
        HouseholdCloudError.notFound => HouseholdFailure.invalidCode,
        HouseholdCloudError.alreadyExists => HouseholdFailure.alreadyUsed,
        HouseholdCloudError.unknown => HouseholdFailure.unknown,
      });
    } on HouseholdCryptoException {
      throw const HouseholdException(HouseholdFailure.verificationFailed);
    } catch (_) {
      throw const HouseholdException(HouseholdFailure.unknown);
    }
  }
}
