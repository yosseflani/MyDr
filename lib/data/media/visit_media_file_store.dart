import 'dart:io';
import 'dart:typed_data';

import 'package:mydr/data/local/local_ids.dart';
import 'package:mydr/data/media/media_file_validator.dart';
import 'package:mydr/data/models/visit_media.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A file copied into private storage.
class StoredMediaFile {
  const StoredMediaFile({
    required this.fileName,
    required this.kind,
    required this.byteSize,
  });

  final String fileName;
  final VisitMediaKind kind;
  final int byteSize;
}

/// Where the photos and videos of [VisitMedia] are kept.
///
/// Files are only ever addressed by bare names this store created, never by
/// paths, so nothing outside its directory can be read or deleted through
/// it. Errors never include names or paths.
abstract interface class VisitMediaFileStore {
  /// Validates the file at [sourcePath] (see [MediaFileValidator]) and
  /// copies it into storage under a new random name. Throws a
  /// [MediaFileException] if it is rejected or cannot be copied; nothing is
  /// left behind then.
  Future<StoredMediaFile> import(String sourcePath);

  /// The file's content, or null if it is missing or unreadable.
  Future<Uint8List?> readBytes(String fileName);

  /// The file on disk, for players that need one, or null if it is missing
  /// or this store keeps no files on disk.
  Future<File?> localFile(String fileName);

  /// Deletes the file. Does nothing if it is already gone. Returns false if
  /// it could not be deleted.
  Future<bool> delete(String fileName);

  /// Deletes every stored file whose name is not in [referenced], e.g. one
  /// left behind when deleting it failed earlier. Only call this with the
  /// complete, freshly read list of records, and while no import is
  /// running.
  Future<void> deleteUnreferenced(Set<String> referenced);
}

/// Deletes [fileNames] from [store], one by one. A file that cannot be
/// deleted is left for [VisitMediaFileStore.deleteUnreferenced] on a later
/// start; it never fails the operation that removed its record.
Future<void> deleteVisitMediaFiles(
  VisitMediaFileStore store,
  Iterable<String> fileNames,
) async {
  for (final fileName in fileNames) {
    try {
      await store.delete(fileName);
    } catch (_) {
      // See above.
    }
  }
}

/// Keeps the files in a directory private to the app: on Android inside
/// the app's internal storage, which other apps and the gallery cannot see,
/// and which the manifest excludes from backups.
///
/// The files are stored as they are, without encryption; only their
/// metadata and descriptions are in the encrypted database.
class PrivateVisitMediaFileStore implements VisitMediaFileStore {
  PrivateVisitMediaFileStore({
    this.locateDirectory = defaultLocation,
    String Function()? createName,
  }) : _createName = createName ?? LocalIds.generate;

  static const String directoryName = 'visit_media';

  final Future<Directory> Function() locateDirectory;
  final String Function() _createName;

  /// In the app's private support directory, next to the database.
  static Future<Directory> defaultLocation() async => Directory(
    p.join((await getApplicationSupportDirectory()).path, directoryName),
  );

  /// A bare name this store could have created: no separators, no "..".
  static final RegExp _validName = RegExp(r'^[A-Za-z0-9-]+\.[a-z0-9]+$');

  Future<File?> _fileFor(String fileName) async {
    if (!_validName.hasMatch(fileName)) return null;
    try {
      return File(p.join((await locateDirectory()).path, fileName));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<StoredMediaFile> import(String sourcePath) async {
    final source = File(sourcePath);
    final VisitMediaKind kind;
    final int length;
    try {
      length = await source.length();
      final handle = await source.open();
      final Uint8List header;
      try {
        header = await handle.read(MediaFileValidator.headerLength);
      } finally {
        await handle.close();
      }
      kind = MediaFileValidator.validate(
        name: sourcePath,
        length: length,
        header: header,
      );
    } on MediaFileException {
      rethrow;
    } catch (_) {
      throw const MediaFileException(MediaFileError.unreadable);
    }

    final extension = MediaFileValidator.extensionOf(sourcePath);
    final fileName = '${_createName()}.$extension';
    File? partial;
    try {
      final directory = await locateDirectory();
      await directory.create(recursive: true);
      final target = File(p.join(directory.path, fileName));
      partial = File('${target.path}.part');
      await source.copy(partial.path);
      if (await partial.length() != length) throw StateError('incomplete');
      // Renamed only once complete, so a stored name never points at half a
      // file.
      await partial.rename(target.path);
      partial = null;
    } catch (_) {
      try {
        if (partial != null && await partial.exists()) await partial.delete();
      } catch (_) {
        // Removed by deleteUnreferenced on a later start.
      }
      throw const MediaFileException(MediaFileError.storageFailed);
    }
    return StoredMediaFile(fileName: fileName, kind: kind, byteSize: length);
  }

  @override
  Future<Uint8List?> readBytes(String fileName) async {
    final file = await localFile(fileName);
    if (file == null) return null;
    try {
      final bytes = await file.readAsBytes();
      return bytes.isEmpty ? null : bytes;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<File?> localFile(String fileName) async {
    final file = await _fileFor(fileName);
    try {
      if (file == null || !await file.exists()) return null;
      return file;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<bool> delete(String fileName) async {
    final file = await _fileFor(fileName);
    if (file == null) return false;
    try {
      if (await file.exists()) await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> deleteUnreferenced(Set<String> referenced) async {
    try {
      final directory = await locateDirectory();
      if (!await directory.exists()) return;
      await for (final entity in directory.list(followLinks: false)) {
        if (entity is! File) continue;
        if (referenced.contains(p.basename(entity.path))) continue;
        try {
          await entity.delete();
        } catch (_) {
          // Tried again on the next start.
        }
      }
    } catch (_) {
      // Clean-up is best effort; it never blocks the app.
    }
  }
}

/// Keeps the files in memory. For tests and the startup screen; nothing is
/// written to disk, and [localFile] always returns null.
class InMemoryVisitMediaFileStore implements VisitMediaFileStore {
  InMemoryVisitMediaFileStore();

  final Map<String, Uint8List> files = {};
  int _nextName = 1;

  @override
  Future<StoredMediaFile> import(String sourcePath) async {
    final Uint8List bytes;
    try {
      bytes = await File(sourcePath).readAsBytes();
    } catch (_) {
      throw const MediaFileException(MediaFileError.unreadable);
    }
    return store(sourcePath, bytes);
  }

  /// Validates and keeps [bytes] as if they were read from a file named
  /// [name].
  StoredMediaFile store(String name, Uint8List bytes) {
    final kind = MediaFileValidator.validate(
      name: name,
      length: bytes.length,
      header: bytes.length > MediaFileValidator.headerLength
          ? bytes.sublist(0, MediaFileValidator.headerLength)
          : bytes,
    );
    final fileName =
        'media-${_nextName++}.${MediaFileValidator.extensionOf(name)}';
    files[fileName] = bytes;
    return StoredMediaFile(
      fileName: fileName,
      kind: kind,
      byteSize: bytes.length,
    );
  }

  @override
  Future<Uint8List?> readBytes(String fileName) async => files[fileName];

  @override
  Future<File?> localFile(String fileName) async => null;

  @override
  Future<bool> delete(String fileName) async {
    files.remove(fileName);
    return true;
  }

  @override
  Future<void> deleteUnreferenced(Set<String> referenced) async {
    files.removeWhere((name, _) => !referenced.contains(name));
  }
}
