import 'dart:io';
import 'dart:typed_data';

/// Why a household cloud action failed. Never carries data.
enum HouseholdCloudError {
  notFound,

  /// Refused by the security rules: not signed in, not a member (any more),
  /// or not allowed for this role.
  permissionDenied,
  network,

  /// The object already exists (objects are never overwritten).
  alreadyExists,
  unknown,
}

class HouseholdCloudException implements Exception {
  const HouseholdCloudException(this.error);

  final HouseholdCloudError error;

  @override
  String toString() => 'HouseholdCloudException(${error.name})';
}

/// A household as the server stores it: no names and no medical data.
class RemoteHousehold {
  const RemoteHousehold({
    required this.id,
    required this.createdBy,
    required this.epoch,
    this.needsRotation = false,
  });

  final String id;
  final String createdBy;

  /// The current key epoch; a new one starts whenever a member leaves.
  final int epoch;

  /// Set when a member left on their own; the next admin sync rotates keys.
  final bool needsRotation;

  @override
  String toString() => 'RemoteHousehold($id)';
}

/// A member entry. [attestation] is an HMAC under the household key of
/// [attestedEpoch] over the household, uid, public key and role: only a
/// member can make one, so the server cannot add or change members unseen.
class RemoteMember {
  RemoteMember({
    required this.uid,
    required List<int> publicKey,
    required this.role,
    required this.addedBy,
    required List<int> attestation,
    required this.attestedEpoch,
    this.label,
  }) : publicKey = Uint8List.fromList(publicKey),
       attestation = Uint8List.fromList(attestation);

  final String uid;
  final Uint8List publicKey;

  /// 'admin' or 'member'.
  final String role;
  final String addedBy;
  final Uint8List attestation;
  final int attestedEpoch;

  /// The member's account email, shown to the other members.
  final String? label;

  RemoteMember copyWith({
    String? role,
    List<int>? attestation,
    int? attestedEpoch,
  }) => RemoteMember(
    uid: uid,
    publicKey: publicKey,
    role: role ?? this.role,
    addedBy: addedBy,
    attestation: attestation ?? this.attestation,
    attestedEpoch: attestedEpoch ?? this.attestedEpoch,
    label: label,
  );

  @override
  String toString() => 'RemoteMember($uid)';
}

/// One epoch's household key, wrapped for one member.
class RemoteWrappedKey {
  RemoteWrappedKey({
    required this.epoch,
    required this.wrappedBy,
    required List<int> wrapped,
  }) : wrapped = Uint8List.fromList(wrapped);

  final int epoch;

  /// The member whose identity key authenticates the wrapping.
  final String wrappedBy;
  final Uint8List wrapped;

  @override
  String toString() => 'RemoteWrappedKey($epoch)';
}

enum InviteStatus { open, accepted, rejected, completed }

/// An invitation, stored under an id derived from its code. Both public
/// keys are authenticated with MACs under keys derived from the code, which
/// the server never sees.
class RemoteInvite {
  RemoteInvite({
    required this.id,
    required this.householdId,
    required this.inviterUid,
    required List<int> inviterPublicKey,
    required List<int> inviterMac,
    required this.createdAt,
    required this.expiresAt,
    this.inviterLabel,
    this.status = InviteStatus.open,
    this.inviteeUid,
    List<int>? inviteePublicKey,
    List<int>? inviteeMac,
    this.inviteeLabel,
  }) : inviterPublicKey = Uint8List.fromList(inviterPublicKey),
       inviterMac = Uint8List.fromList(inviterMac),
       inviteePublicKey = inviteePublicKey == null
           ? null
           : Uint8List.fromList(inviteePublicKey),
       inviteeMac = inviteeMac == null ? null : Uint8List.fromList(inviteeMac);

  final String id;
  final String householdId;
  final String inviterUid;
  final Uint8List inviterPublicKey;
  final Uint8List inviterMac;
  final String? inviterLabel;
  final DateTime createdAt;
  final DateTime expiresAt;
  final InviteStatus status;
  final String? inviteeUid;
  final Uint8List? inviteePublicKey;
  final Uint8List? inviteeMac;
  final String? inviteeLabel;

  RemoteInvite respond({
    required InviteStatus status,
    required String inviteeUid,
    List<int>? inviteePublicKey,
    List<int>? inviteeMac,
    String? inviteeLabel,
  }) => RemoteInvite(
    id: id,
    householdId: householdId,
    inviterUid: inviterUid,
    inviterPublicKey: inviterPublicKey,
    inviterMac: inviterMac,
    inviterLabel: inviterLabel,
    createdAt: createdAt,
    expiresAt: expiresAt,
    status: status,
    inviteeUid: inviteeUid,
    inviteePublicKey: inviteePublicKey,
    inviteeMac: inviteeMac,
    inviteeLabel: inviteeLabel,
  );

  @override
  String toString() => 'RemoteInvite($id)';
}

/// One device's change log: who writes it and its latest batch.
class RemoteDevice {
  const RemoteDevice({
    required this.deviceId,
    required this.uid,
    required this.lastSeq,
  });

  final String deviceId;
  final String uid;
  final int lastSeq;

  @override
  String toString() => 'RemoteDevice($deviceId)';
}

/// One batch of changes, encrypted on the device with the household key of
/// [epoch]. The server sees only who wrote it, its number, epoch and size.
class RemoteLogEntry {
  RemoteLogEntry({
    required this.deviceId,
    required this.seq,
    required this.uid,
    required this.epoch,
    required List<int> data,
  }) : data = Uint8List.fromList(data);

  final String deviceId;
  final int seq;
  final String uid;
  final int epoch;
  final Uint8List data;

  @override
  String toString() => 'RemoteLogEntry($deviceId/$seq)';
}

/// The household's shared space in the cloud: membership, wrapped keys,
/// invitations, each device's append-only change log, and encrypted media.
/// Only ever receives ciphertext and the metadata listed on each type.
/// Every method may throw a [HouseholdCloudException].
abstract interface class HouseholdCloud {
  /// Creates the household with [creator] as its first admin, and the
  /// creator's wrapped key of epoch 1, in one write.
  Future<void> createHousehold({
    required String householdId,
    required RemoteMember creator,
    required RemoteWrappedKey key,
  });

  /// The household, or null if it does not exist. Throws
  /// [HouseholdCloudError.permissionDenied] for anyone but a member.
  Future<RemoteHousehold?> household(String householdId);

  Future<List<RemoteMember>> members(String householdId);

  /// The keys wrapped for [uid]; readable only by that member.
  Future<List<RemoteWrappedKey>> wrappedKeys(String householdId, String uid);

  Future<void> createInvite(RemoteInvite invite);

  /// The invitation with [inviteId], or null.
  Future<RemoteInvite?> invite(String inviteId);

  /// The household's invitations (members only).
  Future<List<RemoteInvite>> invites(String householdId);

  /// Records the invitee's answer: an [RemoteInvite.respond] result.
  Future<void> respondToInvite(RemoteInvite invite);

  Future<void> deleteInvite(String inviteId);

  /// Adds [member] with its wrapped [keys] and marks the invitation used,
  /// in one write (admins only).
  Future<void> addMember({
    required String householdId,
    required RemoteMember member,
    required List<RemoteWrappedKey> keys,
    required String inviteId,
  });

  /// Replaces member entries, e.g. after a role change (admins only).
  Future<void> updateMembers(String householdId, List<RemoteMember> members);

  /// Starts key [epoch]: removes [removeUids] with their keys, replaces
  /// [members] (new attestations) and adds each member's new wrapped key
  /// from [keys] (by uid), in one write (admins only).
  Future<void> rotate({
    required String householdId,
    required int epoch,
    required List<String> removeUids,
    required List<RemoteMember> members,
    required Map<String, RemoteWrappedKey> keys,
  });

  /// Removes [uid]'s own membership and keys and asks the admins to rotate
  /// the key.
  Future<void> leave({required String householdId, required String uid});

  Future<List<RemoteDevice>> devices(String householdId);

  /// The batches of [deviceId] after [afterSeq], oldest first.
  Future<List<RemoteLogEntry>> logEntries(
    String householdId,
    String deviceId, {
    required int afterSeq,
  });

  /// Appends [entry] (its seq must be the device's last seq + 1) and moves
  /// the device's last seq, in one write. Never overwrites.
  Future<void> appendLog(String householdId, RemoteLogEntry entry);

  /// Uploads an encrypted photo or video under [object] (create only).
  Future<void> uploadMedia(String householdId, String object, File file);

  Future<void> downloadMedia(String householdId, String object, File target);
}
