import 'dart:io';

import 'package:drift/native.dart';
import 'package:mydr/data/local/database_key_store.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/local_database_exception.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

/// Opens the encrypted local database, creating it (and its key) on first
/// use.
///
/// Safety rules, whatever goes wrong:
/// * No unencrypted database is ever created: if the SQLite library cannot
///   encrypt, nothing is opened.
/// * A new key is only created when there is no database file yet; an
///   existing file whose key is missing is reported, never overwritten.
/// * Nothing is ever deleted or reset: on any failure the file is left
///   exactly as it was, and the error is reported as a
///   [LocalDatabaseException], which never contains the key or any data.
class LocalDatabaseOpener {
  const LocalDatabaseOpener({
    this.keyStore = const SecureDatabaseKeyStore(),
    this.locateFile = defaultLocation,
  });

  static const String fileName = 'mydr.sqlite';

  final DatabaseKeyStore keyStore;
  final Future<File> Function() locateFile;

  /// The app's private support directory (on Android, the app's internal
  /// files directory, which other apps cannot read).
  static Future<File> defaultLocation() async =>
      File(p.join((await getApplicationSupportDirectory()).path, fileName));

  Future<LocalDatabase> open() async {
    final File file;
    try {
      file = await locateFile();
      await file.parent.create(recursive: true);
    } catch (_) {
      throw const LocalDatabaseException(LocalDatabaseError.openFailed);
    }
    final key = await _obtainKey(file);

    final database = LocalDatabase(
      NativeDatabase(file, setup: (raw) => _prepare(raw, key)),
    );
    try {
      // Opens the file: runs [_prepare], then creates the tables if new.
      await database.customSelect('SELECT count(*) FROM sqlite_master').get();
      final foreignKeys = await database
          .customSelect('PRAGMA foreign_keys')
          .getSingle();
      if (foreignKeys.data.values.first != 1) {
        throw const LocalDatabaseException(LocalDatabaseError.openFailed);
      }
      return database;
    } catch (error) {
      try {
        await database.close();
      } catch (_) {
        // Already failed; the original error is what matters.
      }
      throw _describe(error);
    }
  }

  Future<String> _obtainKey(File file) async {
    String? key;
    try {
      key = await keyStore.read();
    } catch (_) {
      throw const LocalDatabaseException(
        LocalDatabaseError.keyStoreUnavailable,
      );
    }

    if (key == null) {
      if (await file.exists()) {
        // Data without its key: report it, never replace the key.
        throw const LocalDatabaseException(LocalDatabaseError.keyMissing);
      }
      final created = DatabaseKeys.generate();
      try {
        await keyStore.write(created);
        if (await keyStore.read() != created) throw StateError('not stored');
      } catch (_) {
        throw const LocalDatabaseException(
          LocalDatabaseError.keyStoreUnavailable,
        );
      }
      key = created;
    }

    if (!DatabaseKeys.isValid(key)) {
      throw const LocalDatabaseException(LocalDatabaseError.keyInvalid);
    }
    return key;
  }

  /// Runs on the raw connection before anything else touches the file.
  static void _prepare(Database raw, String key) {
    final cipher = raw.select('PRAGMA cipher_version');
    if (cipher.isEmpty || '${cipher.first.values.first}'.isEmpty) {
      throw const LocalDatabaseException(
        LocalDatabaseError.encryptionUnavailable,
      );
    }
    // SQLCipher's own diagnostics stay off; they never hold data, but the
    // app keeps its logs free of database details altogether.
    raw.execute('PRAGMA cipher_log_level = NONE');
    // A raw 256-bit key ("x'…'"), so no passphrase derivation is needed.
    raw.execute("PRAGMA key = \"x'$key'\"");

    // Reading the header proves the key works before anything is written.
    final version = raw.select('PRAGMA user_version').first.values.first;
    if (version is! int || version > LocalDatabase.currentSchemaVersion) {
      throw const LocalDatabaseException(LocalDatabaseError.unsupportedSchema);
    }
    raw.execute('PRAGMA foreign_keys = ON');
  }

  /// Turns any failure into a [LocalDatabaseException], dropping the original
  /// message: SQLite errors can quote the statement that failed, which here
  /// could include the key.
  static LocalDatabaseException _describe(Object error) {
    if (error is LocalDatabaseException) return error;
    if (error is SqliteException) {
      final primary = error.extendedResultCode & 0xff;
      // SQLITE_NOTADB (26) or SQLITE_CORRUPT (11).
      if (primary == 26 || primary == 11) {
        return const LocalDatabaseException(
          LocalDatabaseError.wrongKeyOrDamaged,
        );
      }
    }
    return const LocalDatabaseException(LocalDatabaseError.openFailed);
  }
}
