import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart' as hash;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mydr/data/backup/backup_cipher.dart';
import 'package:mydr/data/backup/backup_data_store.dart';
import 'package:mydr/data/backup/backup_snapshot.dart';
import 'package:mydr/data/backup/recovery_key.dart';
import 'package:mydr/data/cloud/backup_storage.dart';
import 'package:mydr/data/media/media_file_validator.dart';
import 'package:mydr/data/media/visit_media_file_store.dart';
import 'package:path/path.dart' as p;

/// Why a backup or restore failed. Never carries data.
enum BackupFailure {
  network,

  /// Not signed in, or refused by the storage rules.
  unauthorized,
  quotaExceeded,

  /// The backup was made with a different recovery key.
  wrongKey,

  /// The backup was changed or damaged.
  damaged,

  /// Made by a newer version of the app.
  unsupported,
  notFound,

  /// The data on this device could not be read.
  localReadFailed,

  /// The restored data could not be saved; the device is unchanged.
  localWriteFailed,
  unknown,
}

class BackupException implements Exception {
  const BackupException(this.failure);

  final BackupFailure failure;

  @override
  String toString() => 'BackupException(${failure.name})';
}

/// A complete backup in the cloud, as listed without the recovery key.
class RemoteBackup {
  const RemoteBackup({
    required this.id,
    required this.createdAt,
    required this.totalBytes,
  });

  final String id;
  final DateTime createdAt;

  /// Size of the encrypted objects.
  final int totalBytes;

  @override
  bool operator ==(Object other) =>
      other is RemoteBackup &&
      other.id == id &&
      other.createdAt == createdAt &&
      other.totalBytes == totalBytes;

  @override
  int get hashCode => Object.hash(id, createdAt, totalBytes);

  @override
  String toString() => 'RemoteBackup($id)';
}

/// A backup downloaded, decrypted and checked, waiting for the user to
/// confirm the restore. Nothing on the device has changed yet.
class PreparedRestore {
  PreparedRestore._({
    required this.backup,
    required this.snapshot,
    required this.missingFiles,
    required Directory staging,
    required Map<String, File> files,
  }) : _staging = staging,
       _files = files;

  final RemoteBackup backup;
  final BackupSnapshot snapshot;

  /// Photos and videos whose files were already missing when the backup
  /// was made; their records are restored without them.
  final int missingFiles;
  final Directory _staging;

  /// Decrypted, verified files by their name in the backup.
  final Map<String, File> _files;

  BackupCounts get counts => snapshot.counts;
}

/// Creates, lists and restores encrypted backups.
///
/// * **Encrypted on the device.** Every object is encrypted with
///   [BackupCipher] before upload; the storage only ever receives
///   ciphertext, and the recovery key never leaves the device.
/// * **A backup is complete only once its manifest is uploaded,** after
///   all other objects. Older backups are deleted only after that, so a
///   failed or interrupted backup never costs the previous one.
/// * **Restoring never changes the device until it is confirmed:**
///   [prepareRestore] downloads, decrypts and checks everything into a
///   private staging folder first. [applyRestore] then replaces the data
///   in one database transaction; if anything fails, the device keeps its
///   data exactly as it was.
///
/// Cloud layout: `users/{uid}/backups/{backupId}/` holding `manifest.bin`,
/// `data.bin` and `media/{n}.bin`.
class BackupService {
  BackupService({
    required BackupStorage storage,
    required BackupDataStore data,
    required VisitMediaFileStore mediaFiles,
    required Future<Directory> Function() workDirectory,
    DateTime Function() clock = DateTime.now,
    Random? random,
    this.keepBackups = 2,
  }) : _storage = storage,
       _data = data,
       _mediaFiles = mediaFiles,
       _workDirectory = workDirectory,
       _clock = clock,
       _random = random ?? Random.secure();

  /// How many complete backups to keep in the cloud.
  final int keepBackups;

  static const int manifestVersion = 1;
  static const int _maxManifestBytes = 4 << 20;
  static const int _maxDataBytes = 256 << 20;

  final BackupStorage _storage;
  final BackupDataStore _data;
  final VisitMediaFileStore _mediaFiles;
  final Future<Directory> Function() _workDirectory;
  final DateTime Function() _clock;
  final Random _random;

  static String _root(String uid) => 'users/$uid/backups';

  static String _folder(String uid, String id) => '${_root(uid)}/$id';

  /// Complete backups, newest first.
  Future<List<RemoteBackup>> listBackups(String uid) => _guard(() async {
    final backups = <RemoteBackup>[];
    for (final id in await _storage.listFolders(_root(uid))) {
      final metadata = await _storage.metadata(
        '${_folder(uid, id)}/manifest.bin',
      );
      if (metadata == null) continue;
      final createdAt = DateTime.tryParse(metadata['createdAt'] ?? '');
      if (createdAt == null) continue;
      backups.add(
        RemoteBackup(
          id: id,
          createdAt: createdAt.toLocal(),
          totalBytes: int.tryParse(metadata['totalBytes'] ?? '') ?? 0,
        ),
      );
    }
    backups.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return backups;
  });

  /// Backs up everything on the device. [onProgress] receives 0–1.
  Future<RemoteBackup> createBackup({
    required String uid,
    required RecoveryKey key,
    void Function(double)? onProgress,
  }) => _guard(() => _createBackup(uid: uid, key: key, onProgress: onProgress));

  Future<RemoteBackup> _createBackup({
    required String uid,
    required RecoveryKey key,
    void Function(double)? onProgress,
  }) async {
    final cipher = BackupCipher(key, random: _random);
    final createdAt = _clock().toUtc();
    final id = _newId(createdAt);
    final folder = _folder(uid, id);
    final work = await _freshWorkFolder('backup');
    final uploaded = <String>[];
    var completed = false;

    try {
      final BackupSnapshot snapshot;
      try {
        snapshot = await _data.export();
      } catch (_) {
        throw const BackupException(BackupFailure.localReadFailed);
      }

      // Encrypt everything locally first.
      final media = <Map<String, Object>>[];
      final mediaFiles = <File>[];
      for (final item in snapshot.visitMedia) {
        final index = media.length;
        final object = 'media/$index.bin';
        final encrypted = File(p.join(work.path, 'media-$index.bin'));
        final context = '$id/$object';
        final EncryptedFileInfo info;
        final local = await _mediaFiles.localFile(item.fileName);
        if (local != null && await local.exists()) {
          info = await cipher.encryptFile(local, encrypted, context: context);
        } else {
          final bytes = await _mediaFiles.readBytes(item.fileName);
          if (bytes == null) continue; // Already missing on this device.
          await encrypted.writeAsBytes(
            await cipher.encryptBytes(bytes, context: context),
          );
          info = EncryptedFileInfo(
            plainSize: bytes.length,
            sha256: hash.sha256.convert(bytes).toString(),
          );
        }
        media.add({
          'object': object,
          'fileName': item.fileName,
          'size': info.plainSize,
          'sha256': info.sha256,
        });
        mediaFiles.add(encrypted);
      }
      final plainData = snapshot.encode();
      final data = await cipher.encryptBytes(
        plainData,
        context: '$id/data.bin',
      );

      var totalBytes = data.length;
      for (final file in mediaFiles) {
        totalBytes += await file.length();
      }
      var sentBytes = 0;
      void sent(int bytes) {
        sentBytes += bytes;
        onProgress?.call(totalBytes == 0 ? 1 : sentBytes / totalBytes);
      }

      onProgress?.call(0);
      await _upload(() => _storage.uploadBytes('$folder/data.bin', data));
      uploaded.add('$folder/data.bin');
      sent(data.length);
      for (var i = 0; i < mediaFiles.length; i++) {
        final path = '$folder/${media[i]['object']}';
        await _upload(() => _storage.uploadFile(path, mediaFiles[i]));
        uploaded.add(path);
        sent(await mediaFiles[i].length());
      }

      final manifest = await cipher.encryptBytes(
        utf8.encode(
          jsonEncode({
            'formatVersion': manifestVersion,
            'backupId': id,
            'createdAt': createdAt.toIso8601String(),
            'counts': snapshot.counts.toJson(),
            'data': {
              'object': 'data.bin',
              'size': plainData.length,
              'sha256': hash.sha256.convert(plainData).toString(),
            },
            'media': media,
          }),
        ),
        context: '$id/manifest.bin',
      );
      totalBytes += manifest.length;
      // Last: its presence is what makes the backup complete.
      await _upload(
        () => _storage.uploadBytes(
          '$folder/manifest.bin',
          manifest,
          metadata: {
            'createdAt': createdAt.toIso8601String(),
            'totalBytes': '$totalBytes',
            'formatVersion': '$manifestVersion',
          },
        ),
      );
      completed = true;
      onProgress?.call(1);

      await _prune(uid, keep: id);
      return RemoteBackup(
        id: id,
        createdAt: createdAt.toLocal(),
        totalBytes: totalBytes,
      );
    } finally {
      if (!completed) {
        // Best effort: an incomplete folder is never listed, and the next
        // successful backup removes it anyway.
        for (final path in uploaded) {
          try {
            await _storage.delete(path);
          } catch (_) {}
        }
      }
      await _deleteFolder(work);
    }
  }

  /// Whether [key] opens [backup], from its manifest's header alone.
  Future<bool> keyMatches({
    required String uid,
    required RemoteBackup backup,
    required RecoveryKey key,
  }) => _guard(() async {
    final manifest = await _storage.downloadBytes(
      '${_folder(uid, backup.id)}/manifest.bin',
      maxBytes: _maxManifestBytes,
    );
    return BackupCipher(key).matchesHeader(manifest);
  });

  /// Downloads, decrypts and checks [backup] without changing anything on
  /// the device. [onProgress] receives 0–1.
  Future<PreparedRestore> prepareRestore({
    required String uid,
    required RemoteBackup backup,
    required RecoveryKey key,
    void Function(double)? onProgress,
  }) async {
    final cipher = BackupCipher(key);
    final folder = _folder(uid, backup.id);
    final staging = await _freshWorkFolder('restore');
    try {
      return await _guard(() async {
        onProgress?.call(0);
        final manifest = _Manifest.parse(
          await cipher.decryptBytes(
            await _storage.downloadBytes(
              '$folder/manifest.bin',
              maxBytes: _maxManifestBytes,
            ),
            context: '${backup.id}/manifest.bin',
          ),
          backupId: backup.id,
        );

        final plainData = await cipher.decryptBytes(
          await _storage.downloadBytes(
            '$folder/${manifest.data.object}',
            maxBytes: _maxDataBytes,
          ),
          context: '${backup.id}/${manifest.data.object}',
        );
        manifest.data.check(
          plainData.length,
          hash.sha256.convert(plainData).toString(),
        );
        final snapshot = BackupSnapshot.decode(plainData);
        final names = {for (final m in snapshot.visitMedia) m.fileName};

        final files = <String, File>{};
        final total = manifest.media.length + 1;
        onProgress?.call(1 / total);
        for (final entry in manifest.media) {
          if (!names.contains(entry.fileName) ||
              files.containsKey(entry.fileName)) {
            throw const BackupException(BackupFailure.damaged);
          }
          final encrypted = File(p.join(staging.path, 'download.bin'));
          await _storage.downloadFile('$folder/${entry.object}', encrypted);
          // Keeps the original name, so the file is checked by its type
          // when imported.
          final plain = File(p.join(staging.path, entry.fileName));
          final info = await cipher.decryptFile(
            encrypted,
            plain,
            context: '${backup.id}/${entry.object}',
          );
          await encrypted.delete();
          entry.check(info.plainSize, info.sha256);
          files[entry.fileName] = plain;
          onProgress?.call((files.length + 1) / total);
        }

        return PreparedRestore._(
          backup: backup,
          snapshot: snapshot,
          missingFiles: names.length - files.length,
          staging: staging,
          files: files,
        );
      });
    } catch (_) {
      await _deleteFolder(staging);
      rethrow;
    }
  }

  /// Replaces everything on the device with [restore]. Must only be called
  /// after the user explicitly confirmed it; false throws.
  ///
  /// The restored files are imported first (through the same checks as a
  /// new photo or video), then all records are replaced in one
  /// transaction. On any failure the imported files are removed and the
  /// device keeps its previous data.
  Future<void> applyRestore(
    PreparedRestore restore, {
    required bool userConfirmed,
  }) async {
    if (!userConfirmed) {
      throw ArgumentError.value(
        userConfirmed,
        'userConfirmed',
        'Restoring replaces the data on the device; it needs confirmation',
      );
    }
    final imported = <String>[];
    try {
      final names = <String, String>{};
      for (final MapEntry(key: name, value: file) in restore._files.entries) {
        final stored = await _mediaFiles.import(file.path);
        imported.add(stored.fileName);
        names[name] = stored.fileName;
      }
      final restored = restore.snapshot.withMediaFileNames(names);
      await _data.replaceAll(restored);
      imported.clear();

      // The previous data's files now belong to nothing.
      try {
        await _mediaFiles.deleteUnreferenced({
          for (final m in restored.visitMedia) m.fileName,
        });
      } catch (_) {
        // Cleared on a later start (VisitMediaController).
      }
    } catch (_) {
      for (final name in imported) {
        await _mediaFiles.delete(name);
      }
      throw const BackupException(BackupFailure.localWriteFailed);
    } finally {
      await _deleteFolder(restore._staging);
    }
  }

  /// Drops a prepared restore that the user cancelled.
  Future<void> discard(PreparedRestore restore) =>
      _deleteFolder(restore._staging);

  /// Deletes everything but the newest [keepBackups] complete backups
  /// (always keeping [keep]), and every incomplete one. Failures are
  /// ignored: the backup itself already succeeded.
  Future<void> _prune(String uid, {required String keep}) async {
    try {
      final complete = await listBackups(uid);
      final kept = {keep, for (final b in complete.take(keepBackups)) b.id};
      for (final id in await _storage.listFolders(_root(uid))) {
        if (kept.contains(id)) continue;
        final folder = _folder(uid, id);
        // The manifest first, so a half-deleted backup is never listed.
        await _storage.delete('$folder/manifest.bin');
        for (final name in await _storage.listObjects('$folder/media')) {
          await _storage.delete('$folder/media/$name');
        }
        for (final name in await _storage.listObjects(folder)) {
          await _storage.delete('$folder/$name');
        }
      }
    } catch (_) {}
  }

  String _newId(DateTime createdAt) {
    final time = createdAt
        .toIso8601String()
        .replaceAll(RegExp(r'[-:]'), '')
        .split('.')
        .first;
    final suffix = [
      for (var i = 0; i < 4; i++)
        _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
    return '${time}Z-$suffix';
  }

  /// A private, empty folder for one operation. Folders left by an earlier
  /// operation that was interrupted are removed first.
  Future<Directory> _freshWorkFolder(String purpose) async {
    final root = await _workDirectory();
    if (await root.exists()) {
      await for (final entry in root.list()) {
        try {
          await entry.delete(recursive: true);
        } catch (_) {}
      }
    }
    return Directory(p.join(root.path, purpose)).create(recursive: true);
  }

  static Future<void> _deleteFolder(Directory folder) async {
    try {
      if (await folder.exists()) await folder.delete(recursive: true);
    } catch (_) {
      // Removed before the next operation.
    }
  }

  static Future<void> _upload(Future<void> Function() upload) => upload();

  /// Turns any failure into a [BackupException].
  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on BackupException {
      rethrow;
    } on BackupStorageException catch (e) {
      throw BackupException(switch (e.error) {
        BackupStorageError.notFound => BackupFailure.notFound,
        BackupStorageError.unauthorized => BackupFailure.unauthorized,
        BackupStorageError.network => BackupFailure.network,
        BackupStorageError.quotaExceeded => BackupFailure.quotaExceeded,
        BackupStorageError.unknown => BackupFailure.unknown,
      });
    } on BackupDecryptionException catch (e) {
      throw BackupException(switch (e.error) {
        BackupDecryptionError.wrongKey => BackupFailure.wrongKey,
        BackupDecryptionError.damaged => BackupFailure.damaged,
        BackupDecryptionError.unsupported => BackupFailure.unsupported,
      });
    } on BackupFormatException catch (e) {
      throw BackupException(
        e.reason == 'unsupported version'
            ? BackupFailure.unsupported
            : BackupFailure.damaged,
      );
    } on FileSystemException {
      throw const BackupException(BackupFailure.localWriteFailed);
    } catch (error) {
      // The type only: messages can hold paths or data.
      if (kDebugMode) {
        debugPrint(
          'Backup failed: ${error.runtimeType}'
          '${error is PlatformException ? ' ${error.code}: ${error.message}' : ''}',
        );
      }
      throw const BackupException(BackupFailure.unknown);
    }
  }
}

class _ManifestObject {
  const _ManifestObject({
    required this.object,
    required this.size,
    required this.sha256,
    this.fileName = '',
  });

  final String object;
  final String fileName;
  final int size;
  final String sha256;

  /// The decrypted content must be exactly what was backed up.
  void check(int actualSize, String actualSha256) {
    if (actualSize != size || actualSha256 != sha256) {
      throw const BackupException(BackupFailure.damaged);
    }
  }

  static final RegExp _objectName = RegExp(r'^(data|media/[0-9]+)\.bin$');

  static bool _supported(String name) {
    final extension = MediaFileValidator.extensionOf(name);
    return MediaFileValidator.photoExtensions.contains(extension) ||
        MediaFileValidator.videoExtensions.contains(extension);
  }

  static _ManifestObject parse(Object? json, {required bool isMedia}) {
    if (json is! Map<String, Object?>) {
      throw const BackupException(BackupFailure.damaged);
    }
    final object = json['object'];
    final size = json['size'];
    final digest = json['sha256'];
    final fileName = json['fileName'];
    if (object is! String ||
        !_objectName.hasMatch(object) ||
        size is! int ||
        size < 0 ||
        digest is! String) {
      throw const BackupException(BackupFailure.damaged);
    }
    if (isMedia) {
      // A bare name of a supported type, never a path.
      if (fileName is! String ||
          fileName.isEmpty ||
          fileName != p.basename(fileName) ||
          fileName.startsWith('.') ||
          fileName.contains(RegExp(r'[/\\]')) ||
          !_supported(fileName)) {
        throw const BackupException(BackupFailure.damaged);
      }
    }
    return _ManifestObject(
      object: object,
      size: size,
      sha256: digest,
      fileName: isMedia ? fileName as String : '',
    );
  }
}

class _Manifest {
  const _Manifest({required this.data, required this.media});

  final _ManifestObject data;
  final List<_ManifestObject> media;

  static _Manifest parse(Uint8List bytes, {required String backupId}) {
    final Object? json;
    try {
      json = jsonDecode(utf8.decode(bytes));
    } catch (_) {
      throw const BackupException(BackupFailure.damaged);
    }
    if (json is! Map<String, Object?>) {
      throw const BackupException(BackupFailure.damaged);
    }
    final version = json['formatVersion'];
    if (version is! int || version < 1) {
      throw const BackupException(BackupFailure.damaged);
    }
    if (version > BackupService.manifestVersion) {
      throw const BackupException(BackupFailure.unsupported);
    }
    // A manifest moved from another backup is refused (it would also fail
    // to decrypt there).
    if (json['backupId'] != backupId) {
      throw const BackupException(BackupFailure.damaged);
    }
    final media = json['media'];
    if (media is! List) throw const BackupException(BackupFailure.damaged);
    return _Manifest(
      data: _ManifestObject.parse(json['data'], isMedia: false),
      media: [
        for (final item in media) _ManifestObject.parse(item, isMedia: true),
      ],
    );
  }
}
