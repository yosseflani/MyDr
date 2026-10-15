import 'package:drift/drift.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/repositories/local_repository_support.dart';
import 'package:mydr/data/local/storage_codecs.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/data/repositories/symptom_repository.dart';

class LocalSymptomRepository extends LocalRepository
    implements SymptomRepository {
  LocalSymptomRepository(super.db);

  @override
  Future<List<SymptomEntry>> getAll({String? memberId}) => guard(() async {
    final query = db.select(db.symptomEntries)
      ..orderBy([
        // Newest first; stored times sort as text in time order.
        (t) => OrderingTerm.desc(t.startedAt),
        (t) => OrderingTerm.asc(t.id),
      ]);
    if (memberId != null) query.where((t) => t.memberId.equals(memberId));
    return List.unmodifiable((await query.get()).map(_toModel));
  });

  @override
  Future<SymptomEntry?> getById(String id) => guard(() async {
    final row = await (db.select(
      db.symptomEntries,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  });

  /// Refused (a [LocalDataException]) if the family member does not exist.
  @override
  Future<void> add(SymptomEntry item) =>
      insertNew(db.symptomEntries, item.id, _toRow(item));

  @override
  Future<void> update(SymptomEntry item) => guard(() async {
    final rows = await (db.update(
      db.symptomEntries,
    )..where((t) => t.id.equals(item.id))).write(_toRow(item));
    expectUpdated(rows, item.id);
  });

  @override
  Future<void> delete(String id) => guard(() async {
    await (db.delete(db.symptomEntries)..where((t) => t.id.equals(id))).go();
  });

  @override
  Future<void> deleteByMember(String memberId) => guard(() async {
    await (db.delete(
      db.symptomEntries,
    )..where((t) => t.memberId.equals(memberId))).go();
  });

  static SymptomEntriesCompanion _toRow(SymptomEntry entry) =>
      SymptomEntriesCompanion.insert(
        id: entry.id,
        memberId: entry.memberId,
        name: entry.name,
        nameKey: SymptomEntry.nameKey(entry.name),
        startedAt: StorageCodecs.encodeLocalDateTime(entry.startedAt),
        severity: entry.severity,
        status: Value(entry.status.name),
        durationMicros: Value(entry.duration?.inMicroseconds),
        notes: Value(entry.notes),
      );

  static SymptomEntry _toModel(SymptomEntryRow row) {
    final duration = row.durationMicros;
    return SymptomEntry(
      id: row.id,
      memberId: row.memberId,
      name: row.name,
      startedAt: StorageCodecs.decodeLocalDateTime(row.startedAt),
      severity: row.severity,
      status: SymptomStatus.values.byName(row.status),
      duration: duration == null ? null : Duration(microseconds: duration),
      notes: row.notes,
    );
  }
}
