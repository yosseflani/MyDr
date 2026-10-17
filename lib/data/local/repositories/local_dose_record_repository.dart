import 'package:drift/drift.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/repositories/local_repository_support.dart';
import 'package:mydr/data/local/storage_codecs.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/repositories/dose_record_repository.dart';

class LocalDoseRecordRepository extends LocalRepository
    implements DoseRecordRepository {
  LocalDoseRecordRepository(super.db);

  @override
  Future<List<DoseRecord>> getAll({String? memberId, String? medicationId}) =>
      guard(() async {
        final query = db.select(db.doseRecords)
          ..orderBy([
            // Newest first; stored times sort as text in time order.
            (t) => OrderingTerm.desc(t.scheduledAt),
            (t) => OrderingTerm.asc(t.id),
          ]);
        if (memberId != null) query.where((t) => t.memberId.equals(memberId));
        if (medicationId != null) {
          query.where((t) => t.medicationId.equals(medicationId));
        }
        return List.unmodifiable((await query.get()).map(_toModel));
      });

  /// One statement, so two saves of the same scheduled dose can never both
  /// insert: the second updates the first. Refused (a [LocalDataException])
  /// if the medication does not exist or belongs to another family member.
  @override
  Future<DoseRecord> save(DoseRecord record) => guard(() async {
    final row = _toRow(record);
    final clash = await db
        .customSelect(
          'SELECT 1 FROM dose_records WHERE id = ? '
          'AND NOT (medication_id = ? AND scheduled_at = ?)',
          variables: [
            Variable.withString(record.id),
            Variable.withString(record.medicationId),
            Variable.withString(row.scheduledAt.value),
          ],
        )
        .getSingleOrNull();
    if (clash != null) {
      throw StateError('Item with id "${record.id}" already exists');
    }
    await db
        .into(db.doseRecords)
        .insert(
          row,
          onConflict: DoUpdate(
            (_) => DoseRecordsCompanion(
              status: row.status,
              recordedAt: row.recordedAt,
            ),
            target: [db.doseRecords.medicationId, db.doseRecords.scheduledAt],
          ),
        );
    final stored =
        await (db.select(db.doseRecords)..where(
              (t) =>
                  t.medicationId.equals(record.medicationId) &
                  t.scheduledAt.equals(row.scheduledAt.value),
            ))
            .getSingle();
    return _toModel(stored);
  });

  @override
  Future<void> deleteOccurrence(String medicationId, DateTime scheduledAt) =>
      guard(() async {
        final stored = StorageCodecs.encodeLocalDateTime(
          DateTime(
            scheduledAt.year,
            scheduledAt.month,
            scheduledAt.day,
            scheduledAt.hour,
            scheduledAt.minute,
          ),
        );
        await (db.delete(db.doseRecords)..where(
              (t) =>
                  t.medicationId.equals(medicationId) &
                  t.scheduledAt.equals(stored),
            ))
            .go();
      });

  @override
  Future<void> deleteByMedication(String medicationId) => guard(() async {
    await (db.delete(
      db.doseRecords,
    )..where((t) => t.medicationId.equals(medicationId))).go();
  });

  @override
  Future<void> deleteByMember(String memberId) => guard(() async {
    await (db.delete(
      db.doseRecords,
    )..where((t) => t.memberId.equals(memberId))).go();
  });

  static DoseRecordsCompanion _toRow(DoseRecord record) =>
      DoseRecordsCompanion.insert(
        id: record.id,
        memberId: record.memberId,
        medicationId: record.medicationId,
        scheduledAt: StorageCodecs.encodeLocalDateTime(record.scheduledAt),
        status: record.status.name,
        recordedAt: StorageCodecs.encodeInstant(record.recordedAt),
      );

  static DoseRecord _toModel(DoseRecordRow row) => DoseRecord(
    id: row.id,
    memberId: row.memberId,
    medicationId: row.medicationId,
    scheduledAt: StorageCodecs.decodeLocalDateTime(row.scheduledAt),
    status: DoseStatus.values.byName(row.status),
    recordedAt: StorageCodecs.decodeInstant(row.recordedAt),
  );
}
