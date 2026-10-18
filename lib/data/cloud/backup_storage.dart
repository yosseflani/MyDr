import 'dart:io';
import 'dart:typed_data';

/// Why a cloud storage action failed.
enum BackupStorageError {
  notFound,

  /// Refused by the storage rules, or not signed in.
  unauthorized,
  network,

  /// The account's storage is full.
  quotaExceeded,
  unknown,
}

class BackupStorageException implements Exception {
  const BackupStorageException(this.error);

  final BackupStorageError error;

  @override
  String toString() => 'BackupStorageException(${error.name})';
}

/// Cloud object storage for backups. Paths are '/'-separated and relative
/// to the bucket. Only ever receives encrypted bytes. Every method may
/// throw a [BackupStorageException].
abstract interface class BackupStorage {
  Future<void> uploadFile(
    String path,
    File file, {
    Map<String, String> metadata = const {},
  });

  Future<void> uploadBytes(
    String path,
    Uint8List bytes, {
    Map<String, String> metadata = const {},
  });

  Future<void> downloadFile(String path, File target);

  /// The whole object; throws if it is larger than [maxBytes].
  Future<Uint8List> downloadBytes(String path, {required int maxBytes});

  /// The names of the folders directly inside [path].
  Future<List<String>> listFolders(String path);

  /// The names of the objects directly inside [path].
  Future<List<String>> listObjects(String path);

  /// The custom metadata of an object, or null if it does not exist.
  Future<Map<String, String>?> metadata(String path);

  /// Does nothing if the object does not exist.
  Future<void> delete(String path);
}
