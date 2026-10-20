import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/sync_state.dart';
import 'package:mydr/data/repositories/family_repository.dart';
import 'package:mydr/data/repositories/sync_state_repository.dart';

/// Sync bookkeeping kept in memory only (demo mode and tests). Unlike the
/// local database, it does not notice changes to records by itself: only
/// [markPending] adds pending changes.
class InMemorySyncStateRepository implements SyncStateRepository {
  InMemorySyncStateRepository({
    required FamilyRepository familyRepository,
    String deviceId = 'device-memory',
  }) : _family = familyRepository,
       _settings = SyncSettings(deviceId: deviceId);

  final FamilyRepository _family;
  SyncSettings _settings;
  final Map<String, DateTime> _shared = {};
  final Map<(SyncKind, String), PendingChange> _pending = {};
  final Map<(SyncKind, String), SyncRecordState> _records = {};
  final Map<(SyncKind, String), SyncConflict> _conflicts = {};
  final Map<String, int> _cursors = {};
  final Map<String, KnownMember> _members = {};

  @override
  Future<SyncSettings> settings() async => _settings;

  @override
  Future<void> saveSettings(SyncSettings settings) async =>
      _settings = settings;

  @override
  Future<Set<String>> sharedMemberIds() async =>
      Set.unmodifiable(_shared.keys.toSet());

  @override
  Future<void> setShared(
    String memberId, {
    required bool shared,
    DateTime? at,
  }) async {
    if (!shared) {
      _shared.remove(memberId);
      return;
    }
    final member = await _family.getById(memberId);
    if (member == null || member.relation != FamilyRelation.child) {
      throw StateError('Only an existing child profile can be shared');
    }
    _shared.putIfAbsent(
      memberId,
      () => at ?? (throw ArgumentError.notNull('at')),
    );
  }

  @override
  Future<List<PendingChange>> pendingChanges() async {
    final list = _pending.values.toList()
      ..sort((a, b) {
        final byKind = a.kind.name.compareTo(b.kind.name);
        return byKind != 0 ? byKind : a.syncId.compareTo(b.syncId);
      });
    return List.unmodifiable(list);
  }

  @override
  Future<void> markPending(SyncKind kind, String syncId, String localId) async {
    final existing = _pending[(kind, syncId)];
    _pending[(kind, syncId)] = PendingChange(
      kind: kind,
      syncId: syncId,
      localId: localId,
      changeCount: (existing?.changeCount ?? 0) + 1,
    );
  }

  @override
  Future<void> clearPending(PendingChange change) async {
    final existing = _pending[(change.kind, change.syncId)];
    if (existing != null && existing.changeCount <= change.changeCount) {
      _pending.remove((change.kind, change.syncId));
    }
  }

  @override
  Future<SyncRecordState?> record(SyncKind kind, String syncId) async =>
      _records[(kind, syncId)];

  @override
  Future<SyncRecordState?> recordByLocalId(
    SyncKind kind,
    String localId,
  ) async {
    for (final record in _records.values) {
      if (record.kind == kind && record.localId == localId) return record;
    }
    return null;
  }

  @override
  Future<List<SyncRecordState>> records({
    String? memberId,
    bool? parked,
  }) async {
    final list =
        _records.values
            .where((r) => memberId == null || r.memberId == memberId)
            .where((r) => parked == null || r.parked == parked)
            .toList()
          ..sort((a, b) {
            final byKind = a.kind.name.compareTo(b.kind.name);
            return byKind != 0 ? byKind : a.syncId.compareTo(b.syncId);
          });
    return List.unmodifiable(list);
  }

  @override
  Future<void> saveRecord(SyncRecordState record) async =>
      _records[(record.kind, record.syncId)] = record;

  @override
  Future<List<SyncConflict>> conflicts() async {
    final list = _conflicts.values.toList()
      ..sort((a, b) {
        final byTime = a.detectedAt.compareTo(b.detectedAt);
        if (byTime != 0) return byTime;
        final byKind = a.kind.name.compareTo(b.kind.name);
        return byKind != 0 ? byKind : a.syncId.compareTo(b.syncId);
      });
    return List.unmodifiable(list);
  }

  @override
  Future<SyncConflict?> conflict(SyncKind kind, String syncId) async =>
      _conflicts[(kind, syncId)];

  @override
  Future<void> saveConflict(SyncConflict conflict) async =>
      _conflicts[(conflict.kind, conflict.syncId)] = conflict;

  @override
  Future<void> deleteConflict(SyncKind kind, String syncId) async =>
      _conflicts.remove((kind, syncId));

  @override
  Future<Map<String, int>> cursors() async => Map.unmodifiable(_cursors);

  @override
  Future<void> saveCursor(String deviceId, int lastSeq) async =>
      _cursors[deviceId] = lastSeq;

  @override
  Future<List<KnownMember>> knownMembers() async {
    final list = _members.values.toList()
      ..sort((a, b) => a.uid.compareTo(b.uid));
    return List.unmodifiable(list);
  }

  @override
  Future<void> saveKnownMember(KnownMember member) async =>
      _members[member.uid] = member;

  @override
  Future<void> deleteKnownMember(String uid) async => _members.remove(uid);

  @override
  Future<T> applyingRemote<T>(Future<T> Function() action) => action();

  @override
  Future<void> resetHistory() async {
    _pending.clear();
    _conflicts.clear();
    _records.clear();
    _cursors.clear();
    _shared.clear();
  }

  @override
  Future<void> clearHousehold({SyncState state = SyncState.off}) async {
    await resetHistory();
    _members.clear();
    _settings = _settings.copyWith(
      householdId: () => null,
      accountUid: () => null,
      role: () => null,
      state: state,
      inviteId: () => null,
      nextSeq: 1,
    );
  }
}
