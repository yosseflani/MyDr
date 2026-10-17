import 'package:drift/drift.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/repositories/local_repository_support.dart';
import 'package:mydr/data/local/storage_codecs.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/repositories/medication_repository.dart';

class LocalMedicationRepository extends LocalRepository
    implements MedicationRepository {
  LocalMedicationRepository(super.db);

  @override
  Future<List<Medication>> getAll({String? memberId}) => guard(() async {
    final query = db.select(db.medications)
      ..orderBy([
        (t) => OrderingTerm.asc(t.name),
        (t) => OrderingTerm.asc(t.id),
      ]);
    if (memberId != null) query.where((t) => t.memberId.equals(memberId));
    return List.unmodifiable((await query.get()).map(_toModel));
  });

  @override
  Future<Medication?> getById(String id) => guard(() async {
    final row = await (db.select(
      db.medications,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  });

  /// Refused (a [LocalDataException]) if the family member does not exist,
  /// or the end date is before the start date.
  @override
  Future<void> add(Medication item) =>
      insertNew(db.medications, item.id, _toRow(item));

  @override
  Future<void> update(Medication item) => guard(() async {
    final row = _toRow(item);
    final rows =
        await (db.update(
          db.medications,
        )..where((t) => t.id.equals(item.id))).write(
          MedicationsCompanion(
            name: row.name,
            dose: row.dose,
            instructions: row.instructions,
            reminderTimes: row.reminderTimes,
            startDate: row.startDate,
            endDate: row.endDate,
          ),
        );
    expectUpdated(rows, item.id);
  });

  /// Refused (a [LocalDataException]) while the medication still has dose
  /// records: delete those first.
  @override
  Future<void> delete(String id) => guard(() async {
    await (db.delete(db.medications)..where((t) => t.id.equals(id))).go();
  });

  @override
  Future<void> deleteByMember(String memberId) => guard(() async {
    await (db.delete(
      db.medications,
    )..where((t) => t.memberId.equals(memberId))).go();
  });

  static MedicationsCompanion _toRow(Medication medication) {
    final endDate = medication.endDate;
    return MedicationsCompanion.insert(
      id: medication.id,
      memberId: medication.memberId,
      name: medication.name,
      dose: medication.dose,
      instructions: Value(medication.instructions),
      reminderTimes: StorageCodecs.encodeStringList([
        for (final time in medication.reminderTimes) time.format(),
      ]),
      startDate: StorageCodecs.encodeDate(medication.startDate),
      endDate: Value(
        endDate == null ? null : StorageCodecs.encodeDate(endDate),
      ),
    );
  }

  static Medication _toModel(MedicationRow row) {
    final endDate = row.endDate;
    return Medication(
      id: row.id,
      memberId: row.memberId,
      name: row.name,
      dose: row.dose,
      instructions: row.instructions,
      reminderTimes: [
        for (final text in StorageCodecs.decodeStringList(row.reminderTimes))
          DoseTime.parse(text),
      ],
      startDate: StorageCodecs.decodeDate(row.startDate),
      endDate: endDate == null ? null : StorageCodecs.decodeDate(endDate),
    );
  }
}
