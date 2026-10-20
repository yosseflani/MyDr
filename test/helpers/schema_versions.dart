import 'package:sqlite3/sqlite3.dart';

/// Turns a current database file back into the schema of version 3, to test
/// upgrades from older files: drops everything version 4 added (the sync_*
/// tables and their triggers). Version 4 changed no older table.
void dropVersion4Objects(Database raw) {
  final triggers = raw.select(
    "SELECT name FROM sqlite_master WHERE type = 'trigger' "
    "AND name LIKE 'sync!_%' ESCAPE '!'",
  );
  for (final row in triggers) {
    raw.execute('DROP TRIGGER "${row['name']}"');
  }
  for (final table in const [
    'sync_known_members',
    'sync_cursors',
    'sync_conflicts',
    'sync_pending',
    'sync_records',
    'sync_shared_members',
    'sync_settings',
  ]) {
    raw.execute('DROP TABLE $table');
  }
}
