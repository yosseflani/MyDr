import 'package:drift/drift.dart';
import 'package:mydr/data/local/local_database.dart' hide SyncSettings;
import 'package:mydr/data/local/local_ids.dart';
import 'package:mydr/data/local/repositories/local_repository_support.dart';
import 'package:mydr/data/local/storage_codecs.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/sync_state.dart';
import 'package:mydr/data/repositories/sync_state_repository.dart';

class LocalSyncStateRepository extends LocalRepository
    implements SyncStateRepository {
  LocalSyncStateRepository(super.db);

  @override
  Future<SyncSettings> settings() => guard(() async {
    final row = await db.select(db.syncSettings).getSingleOrNull();
    if (row != null) return _settingsFromRow(row);
    final created = SyncSettings(deviceId: LocalIds.generate());
    await db.into(db.syncSettings).insert(_settingsRow(created));
    return created;
  });

  @override
  Future<void> saveSettings(SyncSettings settings) => guard(() async {
    await db
        .into(db.syncSettings)
        .insertOnConflictUpdate(_settingsRow(settings));
  });

  @override
  Future<Set<String>> sharedMemberIds() => guard(() async {
    final rows = await db.select(db.syncSharedMembers).get();
    return Set.unmodifiable({for (final r in rows) r.memberId});
  });

  @override
  Future<void> setShared(
    String memberId, {
    required bool shared,
    DateTime? at,
  }) => guard(() async {
    if (!shared) {
      await (db.delete(
        db.syncSharedMembers,
      )..where((t) => t.memberId.equals(memberId))).go();
      return;
    }
    final member = await (db.select(
      db.familyMembers,
    )..where((t) => t.id.equals(memberId))).getSingleOrNull();
    if (member == null || member.relation != FamilyRelation.child.name) {
      throw StateError('Only an existing child profile can be shared');
    }
    await db
        .into(db.syncSharedMembers)
        .insert(
          SyncSharedMembersCompanion.insert(
            memberId: memberId,
            sharedAt: StorageCodecs.encodeInstant(
              at ?? (throw ArgumentError.notNull('at')),
            ),
          ),
          mode: InsertMode.insertOrIgnore,
        );
  });

  @override
  Future<List<PendingChange>> pendingChanges() => guard(() async {
    final rows =
        await (db.select(db.syncPending)..orderBy([
              (t) => OrderingTerm.asc(t.kind),
              (t) => OrderingTerm.asc(t.syncId),
            ]))
            .get();
    return List.unmodifiable([
      for (final r in rows)
        PendingChange(
          kind: SyncKind.values.byName(r.kind),
          syncId: r.syncId,
          localId: r.localId,
          changeCount: r.changeCount,
        ),
    ]);
  });

  @override
  Future<void> markPending(SyncKind kind, String syncId, String localId) =>
      guard(() async {
        await db.customStatement(
          'INSERT INTO sync_pending (kind, sync_id, local_id, change_count) '
          'VALUES (?, ?, ?, 1) ON CONFLICT (kind, sync_id) DO UPDATE SET '
          'change_count = change_count + 1, local_id = excluded.local_id',
          [kind.name, syncId, localId],
        );
      });

  @override
  Future<void> clearPending(PendingChange change) => guard(() async {
    await (db.delete(db.syncPending)..where(
          (t) =>
              t.kind.equals(change.kind.name) &
              t.syncId.equals(change.syncId) &
              t.changeCount.isSmallerOrEqualValue(change.changeCount),
        ))
        .go();
  });

  @override
  Future<SyncRecordState?> record(SyncKind kind, String syncId) =>
      guard(() async {
        final row =
            await (db.select(db.syncRecords)..where(
                  (t) => t.kind.equals(kind.name) & t.syncId.equals(syncId),
                ))
                .getSingleOrNull();
        return row == null ? null : _recordFromRow(row);
      });

  @override
  Future<SyncRecordState?> recordByLocalId(SyncKind kind, String localId) =>
      guard(() async {
        final rows =
            await (db.select(db.syncRecords)
                  ..where(
                    (t) => t.kind.equals(kind.name) & t.localId.equals(localId),
                  )
                  ..limit(1))
                .get();
        return rows.isEmpty ? null : _recordFromRow(rows.first);
      });

  @override
  Future<List<SyncRecordState>> records({String? memberId, bool? parked}) =>
      guard(() async {
        final query = db.select(db.syncRecords)
          ..orderBy([
            (t) => OrderingTerm.asc(t.kind),
            (t) => OrderingTerm.asc(t.syncId),
          ]);
        if (memberId != null) query.where((t) => t.memberId.equals(memberId));
        if (parked != null) query.where((t) => t.parked.equals(parked ? 1 : 0));
        return List.unmodifiable((await query.get()).map(_recordFromRow));
      });

  @override
  Future<void> saveRecord(SyncRecordState record) => guard(() async {
    final base = record.base;
    await db
        .into(db.syncRecords)
        .insertOnConflictUpdate(
          SyncRecordsCompanion.insert(
            kind: record.kind.name,
            syncId: record.syncId,
            localId: record.localId,
            memberId: record.memberId,
            versionVector: StorageCodecs.encodeCounters(record.vector.counters),
            updatedAt: StorageCodecs.encodeInstant(record.updatedAt),
            updatedBy: record.updatedBy,
            deleted: record.deleted ? 1 : 0,
            base: Value(
              base == null ? null : StorageCodecs.encodeJsonObject(base),
            ),
            parked: Value(record.parked ? 1 : 0),
          ),
        );
  });

  @override
  Future<List<SyncConflict>> conflicts() => guard(() async {
    final rows =
        await (db.select(db.syncConflicts)..orderBy([
              (t) => OrderingTerm.asc(t.detectedAt),
              (t) => OrderingTerm.asc(t.kind),
              (t) => OrderingTerm.asc(t.syncId),
            ]))
            .get();
    return List.unmodifiable(rows.map(_conflictFromRow));
  });

  @override
  Future<SyncConflict?> conflict(SyncKind kind, String syncId) =>
      guard(() async {
        final row =
            await (db.select(db.syncConflicts)..where(
                  (t) => t.kind.equals(kind.name) & t.syncId.equals(syncId),
                ))
                .getSingleOrNull();
        return row == null ? null : _conflictFromRow(row);
      });

  @override
  Future<void> saveConflict(SyncConflict conflict) => guard(() async {
    final local = conflict.local;
    final remote = conflict.remote;
    await db
        .into(db.syncConflicts)
        .insertOnConflictUpdate(
          SyncConflictsCompanion.insert(
            kind: conflict.kind.name,
            syncId: conflict.syncId,
            localId: conflict.localId,
            memberId: conflict.memberId,
            reason: conflict.reason.name,
            local: Value(
              local == null ? null : StorageCodecs.encodeJsonObject(local),
            ),
            remote: Value(
              remote == null ? null : StorageCodecs.encodeJsonObject(remote),
            ),
            remoteVector: StorageCodecs.encodeCounters(
              conflict.remoteVector.counters,
            ),
            remoteUpdatedAt: StorageCodecs.encodeInstant(
              conflict.remoteUpdatedAt,
            ),
            remoteUpdatedBy: conflict.remoteUpdatedBy,
            fields: Value(StorageCodecs.encodeStringList(conflict.fields)),
            detectedAt: StorageCodecs.encodeInstant(conflict.detectedAt),
          ),
        );
  });

  @override
  Future<void> deleteConflict(SyncKind kind, String syncId) => guard(() async {
    await (db.delete(
      db.syncConflicts,
    )..where((t) => t.kind.equals(kind.name) & t.syncId.equals(syncId))).go();
  });

  @override
  Future<Map<String, int>> cursors() => guard(() async {
    final rows = await db.select(db.syncCursors).get();
    return Map.unmodifiable({for (final r in rows) r.deviceId: r.lastSeq});
  });

  @override
  Future<void> saveCursor(String deviceId, int lastSeq) => guard(() async {
    await db
        .into(db.syncCursors)
        .insertOnConflictUpdate(
          SyncCursorsCompanion.insert(deviceId: deviceId, lastSeq: lastSeq),
        );
  });

  @override
  Future<List<KnownMember>> knownMembers() => guard(() async {
    final rows = await (db.select(
      db.syncKnownMembers,
    )..orderBy([(t) => OrderingTerm.asc(t.uid)])).get();
    return List.unmodifiable([
      for (final r in rows)
        KnownMember(
          uid: r.uid,
          publicKey: r.publicKey,
          role: HouseholdRole.values.byName(r.role),
          label: r.label,
        ),
    ]);
  });

  @override
  Future<void> saveKnownMember(KnownMember member) => guard(() async {
    await db
        .into(db.syncKnownMembers)
        .insertOnConflictUpdate(
          SyncKnownMembersCompanion.insert(
            uid: member.uid,
            publicKey: member.publicKey,
            role: member.role.name,
            label: Value(member.label),
          ),
        );
  });

  @override
  Future<void> deleteKnownMember(String uid) => guard(() async {
    await (db.delete(
      db.syncKnownMembers,
    )..where((t) => t.uid.equals(uid))).go();
  });

  @override
  Future<T> applyingRemote<T>(Future<T> Function() action) async {
    await settings();
    await guard(
      () => db.customStatement('UPDATE sync_settings SET applying = 1'),
    );
    try {
      return await action();
    } finally {
      await guard(
        () => db.customStatement('UPDATE sync_settings SET applying = 0'),
      );
    }
  }

  @override
  Future<void> resetHistory() => guard(() async {
    await db.delete(db.syncPending).go();
    await db.delete(db.syncConflicts).go();
    await db.delete(db.syncRecords).go();
    await db.delete(db.syncCursors).go();
    await db.delete(db.syncSharedMembers).go();
  });

  @override
  Future<void> clearHousehold({SyncState state = SyncState.off}) =>
      guard(() async {
        await resetHistory();
        await db.delete(db.syncKnownMembers).go();
        final current = await settings();
        await saveSettings(
          current.copyWith(
            householdId: () => null,
            accountUid: () => null,
            role: () => null,
            state: state,
            inviteId: () => null,
            nextSeq: 1,
          ),
        );
      });

  static SyncSettingsCompanion _settingsRow(SyncSettings s) {
    final lastSyncAt = s.lastSyncAt;
    return SyncSettingsCompanion.insert(
      id: const Value(1),
      deviceId: s.deviceId,
      householdId: Value(s.householdId),
      accountUid: Value(s.accountUid),
      role: Value(s.role?.name),
      state: Value(s.state.name),
      inviteId: Value(s.inviteId),
      lastSyncAt: Value(
        lastSyncAt == null ? null : StorageCodecs.encodeInstant(lastSyncAt),
      ),
      nextSeq: Value(s.nextSeq),
    );
  }

  static SyncSettings _settingsFromRow(SyncSettingsRow row) {
    final role = row.role;
    final lastSyncAt = row.lastSyncAt;
    return SyncSettings(
      deviceId: row.deviceId,
      householdId: row.householdId,
      accountUid: row.accountUid,
      role: role == null ? null : HouseholdRole.values.byName(role),
      state: SyncState.values.byName(row.state),
      inviteId: row.inviteId,
      lastSyncAt: lastSyncAt == null
          ? null
          : StorageCodecs.decodeInstant(lastSyncAt),
      nextSeq: row.nextSeq,
    );
  }

  static SyncRecordState _recordFromRow(SyncRecordRow row) {
    final base = row.base;
    return SyncRecordState(
      kind: SyncKind.values.byName(row.kind),
      syncId: row.syncId,
      localId: row.localId,
      memberId: row.memberId,
      vector: VersionVector(StorageCodecs.decodeCounters(row.versionVector)),
      updatedAt: StorageCodecs.decodeInstant(row.updatedAt),
      updatedBy: row.updatedBy,
      deleted: row.deleted == 1,
      base: base == null ? null : StorageCodecs.decodeJsonObject(base),
      parked: row.parked == 1,
    );
  }

  static SyncConflict _conflictFromRow(SyncConflictRow row) {
    final local = row.local;
    final remote = row.remote;
    return SyncConflict(
      kind: SyncKind.values.byName(row.kind),
      syncId: row.syncId,
      localId: row.localId,
      memberId: row.memberId,
      reason: ConflictReason.values.byName(row.reason),
      local: local == null ? null : StorageCodecs.decodeJsonObject(local),
      remote: remote == null ? null : StorageCodecs.decodeJsonObject(remote),
      remoteVector: VersionVector(
        StorageCodecs.decodeCounters(row.remoteVector),
      ),
      remoteUpdatedAt: StorageCodecs.decodeInstant(row.remoteUpdatedAt),
      remoteUpdatedBy: row.remoteUpdatedBy,
      fields: StorageCodecs.decodeStringList(row.fields),
      detectedAt: StorageCodecs.decodeInstant(row.detectedAt),
    );
  }
}
