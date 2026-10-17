import 'package:drift/drift.dart';
import 'package:mydr/data/local/local_database_exception.dart';

part 'local_database.g.dart';

/// The app's encrypted local database. Tables and constraints are defined
/// in schema.drift.
///
/// Open it only through `LocalDatabaseOpener`, which sets the encryption
/// key, turns on foreign keys and refuses unsupported schema versions
/// before anything is read or written.
@DriftDatabase(include: {'schema.drift'})
class LocalDatabase extends _$LocalDatabase {
  LocalDatabase(super.executor);

  /// 1: family members, appointments, questions and symptoms.
  /// 2: adds visit_media (photos and videos prepared for a doctor visit).
  /// 3: adds medications and dose_records (medication reminders).
  static const int currentSchemaVersion = 3;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    // One step per version, run in order. A step only adds; it never
    // deletes or rewrites existing data.
    onUpgrade: (migrator, from, to) async {
      if (from < 1 || to > currentSchemaVersion) {
        throw const LocalDatabaseException(
          LocalDatabaseError.unsupportedSchema,
        );
      }
      if (from < 2) {
        await migrator.createTable(visitMedia);
        await migrator.createIndex(visitMediaByAppointment);
        await migrator.createIndex(visitMediaByMember);
      }
      if (from < 3) {
        await migrator.createTable(medications);
        await migrator.createIndex(medicationsByMember);
        await migrator.createTable(doseRecords);
        await migrator.createIndex(doseRecordsByMember);
      }
    },
  );
}
