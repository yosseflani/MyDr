/// Why the local database could not be opened.
enum LocalDatabaseError {
  /// The operating system's secure storage could not be read or written.
  keyStoreUnavailable,

  /// The database file exists but its encryption key is gone (e.g. the app
  /// data was restored without it). The file is kept untouched.
  keyMissing,

  /// The stored key is not a valid key.
  keyInvalid,

  /// The key does not open the file, or the file is damaged. The file is
  /// kept untouched.
  wrongKeyOrDamaged,

  /// The file was written by a newer version of the app. It is kept
  /// untouched.
  unsupportedSchema,

  /// The SQLite library in use cannot encrypt. Nothing is written, so no
  /// unencrypted database is ever created.
  encryptionUnavailable,

  /// Any other failure.
  openFailed,
}

/// Never carries the key, SQL or any stored data, so it is safe to log.
class LocalDatabaseException implements Exception {
  const LocalDatabaseException(this.error);

  final LocalDatabaseError error;

  @override
  String toString() => 'LocalDatabaseException(${error.name})';
}
