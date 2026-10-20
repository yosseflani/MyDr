/// What a synced change is about, in the order changes are applied: a
/// record's parent always comes before it.
enum SyncKind {
  /// Whether a child is shared with the household (not a medical record).
  share,
  member,
  appointment,
  medication,
  question,
  symptom,
  media,
  dose,
}

/// How two version vectors relate.
enum VectorOrder {
  equal,

  /// The first is older: the second has seen everything the first has.
  before,

  /// The first is newer.
  after,

  /// Neither has seen the other's latest change: a concurrent edit.
  concurrent,
}

/// A version vector: for each device, how many of its changes a version
/// includes. Comparing two tells whether one replaced the other or whether
/// they were made concurrently, without trusting any device's clock.
class VersionVector {
  VersionVector([Map<String, int> counters = const {}])
    : counters = Map.unmodifiable({
        for (final MapEntry(:key, :value) in counters.entries)
          if (value > 0) key: value,
      });

  static final VersionVector empty = VersionVector();

  final Map<String, int> counters;

  bool get isEmpty => counters.isEmpty;

  int operator [](String device) => counters[device] ?? 0;

  /// This version plus one more change by [device].
  VersionVector increment(String device) =>
      VersionVector({...counters, device: this[device] + 1});

  /// The smallest version that has seen both.
  VersionVector merge(VersionVector other) => VersionVector({
    for (final device in {...counters.keys, ...other.counters.keys})
      device: this[device] > other[device] ? this[device] : other[device],
  });

  VectorOrder compareTo(VersionVector other) {
    var newer = false;
    var older = false;
    for (final device in {...counters.keys, ...other.counters.keys}) {
      final mine = this[device];
      final theirs = other[device];
      if (mine > theirs) newer = true;
      if (mine < theirs) older = true;
    }
    if (newer && older) return VectorOrder.concurrent;
    if (newer) return VectorOrder.after;
    if (older) return VectorOrder.before;
    return VectorOrder.equal;
  }

  /// Whether this version includes everything [other] does.
  bool includes(VersionVector other) {
    final order = compareTo(other);
    return order == VectorOrder.equal || order == VectorOrder.after;
  }

  @override
  bool operator ==(Object other) =>
      other is VersionVector && compareTo(other) == VectorOrder.equal;

  @override
  int get hashCode => Object.hashAllUnordered(
    counters.entries.map((e) => Object.hash(e.key, e.value)),
  );

  @override
  String toString() => 'VersionVector(${counters.length})';
}

/// Whether this device takes part in a household.
enum SyncState {
  /// No household; nothing is tracked.
  off,

  /// Accepted an invitation; waiting for the inviter to add this account.
  joining,
  active,

  /// This account was removed from the household (or left it).
  removed,
}

/// What a household member may do.
enum HouseholdRole {
  /// Invites and removes members, and changes roles.
  admin,

  /// Syncs and shares children.
  member,
}

/// This device's sync identity and household link.
class SyncSettings {
  const SyncSettings({
    required this.deviceId,
    this.householdId,
    this.accountUid,
    this.role,
    this.state = SyncState.off,
    this.inviteId,
    this.lastSyncAt,
    this.nextSeq = 1,
  });

  /// Random id of this installation; names its change log.
  final String deviceId;
  final String? householdId;

  /// The account that joined the household on this device.
  final String? accountUid;
  final HouseholdRole? role;
  final SyncState state;

  /// The invitation accepted while [state] is [SyncState.joining].
  final String? inviteId;
  final DateTime? lastSyncAt;

  /// Sequence number of this device's next uploaded batch.
  final int nextSeq;

  bool get isActive => state == SyncState.active && householdId != null;

  SyncSettings copyWith({
    String? Function()? householdId,
    String? Function()? accountUid,
    HouseholdRole? Function()? role,
    SyncState? state,
    String? Function()? inviteId,
    DateTime? Function()? lastSyncAt,
    int? nextSeq,
  }) => SyncSettings(
    deviceId: deviceId,
    householdId: householdId != null ? householdId() : this.householdId,
    accountUid: accountUid != null ? accountUid() : this.accountUid,
    role: role != null ? role() : this.role,
    state: state ?? this.state,
    inviteId: inviteId != null ? inviteId() : this.inviteId,
    lastSyncAt: lastSyncAt != null ? lastSyncAt() : this.lastSyncAt,
    nextSeq: nextSeq ?? this.nextSeq,
  );

  @override
  bool operator ==(Object other) =>
      other is SyncSettings &&
      other.deviceId == deviceId &&
      other.householdId == householdId &&
      other.accountUid == accountUid &&
      other.role == role &&
      other.state == state &&
      other.inviteId == inviteId &&
      other.lastSyncAt == lastSyncAt &&
      other.nextSeq == nextSeq;

  @override
  int get hashCode => Object.hash(
    deviceId,
    householdId,
    accountUid,
    role,
    state,
    inviteId,
    lastSyncAt,
    nextSeq,
  );

  @override
  String toString() => 'SyncSettings($deviceId)';
}

/// What this device knows about one shared record.
class SyncRecordState {
  SyncRecordState({
    required this.kind,
    required this.syncId,
    required this.localId,
    required this.memberId,
    required this.vector,
    required this.updatedAt,
    required this.updatedBy,
    this.deleted = false,
    Map<String, Object?>? base,
    this.parked = false,
  }) : base = base == null ? null : Map.unmodifiable(base);

  final SyncKind kind;

  /// The record's id in the household: its id, except for a dose record,
  /// which is named by its medication and scheduled time (see
  /// [SyncIds.dose]) so the same dose is one record on every device.
  final String syncId;

  /// The record's id in this device's database.
  final String localId;

  /// The shared child the record belongs to.
  final String memberId;
  final VersionVector vector;

  /// When, and on which device, the latest known change was made.
  final DateTime updatedAt;
  final String updatedBy;

  /// A tombstone: the record was deleted.
  final bool deleted;

  /// The content last exchanged with the household; null for a tombstone.
  final Map<String, Object?>? base;

  /// A change from another device waiting for its parent record.
  final bool parked;

  SyncRecordState copyWith({
    String? localId,
    String? memberId,
    VersionVector? vector,
    DateTime? updatedAt,
    String? updatedBy,
    bool? deleted,
    Map<String, Object?>? Function()? base,
    bool? parked,
  }) => SyncRecordState(
    kind: kind,
    syncId: syncId,
    localId: localId ?? this.localId,
    memberId: memberId ?? this.memberId,
    vector: vector ?? this.vector,
    updatedAt: updatedAt ?? this.updatedAt,
    updatedBy: updatedBy ?? this.updatedBy,
    deleted: deleted ?? this.deleted,
    base: base != null ? base() : this.base,
    parked: parked ?? this.parked,
  );

  @override
  bool operator ==(Object other) =>
      other is SyncRecordState &&
      other.kind == kind &&
      other.syncId == syncId &&
      other.localId == localId &&
      other.memberId == memberId &&
      other.vector == vector &&
      other.updatedAt == updatedAt &&
      other.updatedBy == updatedBy &&
      other.deleted == deleted &&
      jsonEquals(other.base, base) &&
      other.parked == parked;

  @override
  int get hashCode => Object.hash(
    kind,
    syncId,
    localId,
    memberId,
    vector,
    updatedAt,
    updatedBy,
    deleted,
    parked,
  );

  @override
  String toString() => 'SyncRecordState(${kind.name} $syncId)';
}

/// A local change waiting to be uploaded.
class PendingChange {
  const PendingChange({
    required this.kind,
    required this.syncId,
    required this.localId,
    required this.changeCount,
  });

  final SyncKind kind;
  final String syncId;
  final String localId;

  /// How many times the record changed since the last upload; an upload
  /// clears the entry only if no change came in while it ran.
  final int changeCount;

  @override
  bool operator ==(Object other) =>
      other is PendingChange &&
      other.kind == kind &&
      other.syncId == syncId &&
      other.localId == localId &&
      other.changeCount == changeCount;

  @override
  int get hashCode => Object.hash(kind, syncId, localId, changeCount);

  @override
  String toString() => 'PendingChange(${kind.name} $syncId)';
}

/// Why a change from another device was not applied.
enum ConflictReason {
  /// Both devices changed the same fields differently.
  edited,

  /// Another member deleted a record that is still on this device. Never
  /// applied without the user's confirmation.
  deleted,

  /// Deleted on this device, but changed on another one.
  deletedHere,
}

/// A change from another device waiting for the user's decision.
class SyncConflict {
  SyncConflict({
    required this.kind,
    required this.syncId,
    required this.localId,
    required this.memberId,
    required this.reason,
    Map<String, Object?>? local,
    Map<String, Object?>? remote,
    required this.remoteVector,
    required this.remoteUpdatedAt,
    required this.remoteUpdatedBy,
    List<String> fields = const [],
    required this.detectedAt,
  }) : local = local == null ? null : Map.unmodifiable(local),
       remote = remote == null ? null : Map.unmodifiable(remote),
       fields = List.unmodifiable(fields);

  final SyncKind kind;
  final String syncId;
  final String localId;
  final String memberId;
  final ConflictReason reason;

  /// This device's version; null if it was deleted here.
  final Map<String, Object?>? local;

  /// The other device's version; null if it was deleted there.
  final Map<String, Object?>? remote;
  final VersionVector remoteVector;
  final DateTime remoteUpdatedAt;
  final String remoteUpdatedBy;

  /// The fields both sides changed differently (for [ConflictReason.edited]).
  final List<String> fields;
  final DateTime detectedAt;

  @override
  bool operator ==(Object other) =>
      other is SyncConflict &&
      other.kind == kind &&
      other.syncId == syncId &&
      other.localId == localId &&
      other.memberId == memberId &&
      other.reason == reason &&
      jsonEquals(other.local, local) &&
      jsonEquals(other.remote, remote) &&
      other.remoteVector == remoteVector &&
      other.remoteUpdatedAt == remoteUpdatedAt &&
      other.remoteUpdatedBy == remoteUpdatedBy &&
      jsonEquals(other.fields, fields) &&
      other.detectedAt == detectedAt;

  @override
  int get hashCode => Object.hash(
    kind,
    syncId,
    localId,
    memberId,
    reason,
    remoteVector,
    remoteUpdatedAt,
    remoteUpdatedBy,
    detectedAt,
  );

  @override
  String toString() => 'SyncConflict(${kind.name} $syncId)';
}

/// A household member whose public key this device verified.
class KnownMember {
  const KnownMember({
    required this.uid,
    required this.publicKey,
    required this.role,
    this.label,
  });

  final String uid;

  /// Base64 of the member's X25519 public key.
  final String publicKey;
  final HouseholdRole role;

  /// What the member chose to be shown as (their account's email).
  final String? label;

  KnownMember copyWith({HouseholdRole? role, String? Function()? label}) =>
      KnownMember(
        uid: uid,
        publicKey: publicKey,
        role: role ?? this.role,
        label: label != null ? label() : this.label,
      );

  @override
  bool operator ==(Object other) =>
      other is KnownMember &&
      other.uid == uid &&
      other.publicKey == publicKey &&
      other.role == role &&
      other.label == label;

  @override
  int get hashCode => Object.hash(uid, publicKey, role, label);

  @override
  String toString() => 'KnownMember($uid)';
}

/// Ids of records in the household.
abstract final class SyncIds {
  /// A dose record is named by its scheduled dose, so the same dose marked
  /// on two devices is one record, never two. [scheduledAt] is the stored
  /// local date and time (see `StorageCodecs.encodeLocalDateTime`).
  static String dose(String medicationId, String scheduledAt) =>
      '$medicationId@$scheduledAt';
}

/// Deep equality of JSON-like values (maps, lists, strings, numbers,
/// booleans and null).
bool jsonEquals(Object? a, Object? b) {
  if (a is Map && b is Map) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || !jsonEquals(a[key], b[key])) return false;
    }
    return true;
  }
  if (a is List && b is List) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (!jsonEquals(a[i], b[i])) return false;
    }
    return true;
  }
  return a == b;
}
