import 'package:drift/drift.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/local_ids.dart';
import 'package:sqlite3/sqlite3.dart';

/// Why a local database operation failed.
enum LocalDataError {
  /// The database refused the change, e.g. a record that still has related
  /// records, or a link to a missing or foreign record.
  rejected,

  /// A stored value could not be read back into a model.
  unreadable,

  /// Any other failure (disk full, database closed, …).
  failed,
}

/// A failed local database operation.
///
/// Never carries SQL, parameters or stored values (SQLite errors can
/// include all three), so it is safe to log.
class LocalDataException implements Exception {
  const LocalDataException(this.error);

  final LocalDataError error;

  @override
  String toString() => 'LocalDataException(${error.name})';
}

/// Shared behavior of the repositories backed by [LocalDatabase].
abstract class LocalRepository {
  LocalRepository(this.db);

  final LocalDatabase db;

  String createId() => LocalIds.generate();

  /// Runs [operation], replacing any database error with a
  /// [LocalDataException]. [StateError]s (the repository contract's
  /// "already exists" / "does not exist") pass through unchanged.
  Future<T> guard<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on StateError {
      rethrow;
    } on LocalDataException {
      rethrow;
    } on FormatException {
      throw const LocalDataException(LocalDataError.unreadable);
    } on ArgumentError {
      throw const LocalDataException(LocalDataError.unreadable);
    } catch (error) {
      throw LocalDataException(
        _sqliteError(error) == null
            ? LocalDataError.failed
            : LocalDataError.rejected,
      );
    }
  }

  /// Inserts [row], or throws a [StateError] if [id] is already taken.
  ///
  /// Checked up front rather than read from the insert's error: a record
  /// can break several constraints at once (e.g. a second "self" profile
  /// with a taken id), and SQLite reports only one of them.
  Future<void> insertNew<T extends Table, R>(
    TableInfo<T, R> table,
    String id,
    Insertable<R> row,
  ) => guard(() async {
    final existing = await db
        .customSelect(
          'SELECT 1 FROM ${table.actualTableName} WHERE id = ?',
          variables: [Variable.withString(id)],
        )
        .getSingleOrNull();
    if (existing != null) {
      throw StateError('Item with id "$id" already exists');
    }
    await db.into(table).insert(row);
  });

  /// Throws a [StateError] unless exactly one row was changed.
  void expectUpdated(int rows, String id) {
    if (rows == 0) throw StateError('Item with id "$id" does not exist');
  }

  static SqliteException? _sqliteError(Object error) => switch (error) {
    SqliteException() => error,
    DriftWrappedException(:final cause) when cause is SqliteException => cause,
    _ => null,
  };
}
