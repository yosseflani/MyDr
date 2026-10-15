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

  static const int currentSchemaVersion = 1;

  @override
  int get schemaVersion => currentSchemaVersion;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    // There is no older version to upgrade from yet. Future versions add
    // their steps here; a step never deletes data.
    onUpgrade: (migrator, from, to) async => throw const LocalDatabaseException(
      LocalDatabaseError.unsupportedSchema,
    ),
  );
}
