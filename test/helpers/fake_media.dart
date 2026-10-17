import 'dart:typed_data';

import 'package:mydr/data/media/media_file_validator.dart';
import 'package:mydr/data/media/media_picker.dart';
import 'package:mydr/data/media/visit_media_file_store.dart';

/// Smallest headers the validator accepts. Test files are not real images.
Uint8List fakeJpeg([int extra = 32]) =>
    Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0, ...List.filled(extra, 1)]);

Uint8List fakeMp4([int extra = 32]) => Uint8List.fromList([
  0, 0, 0, 0x18, // box size
  ...'ftypisom'.codeUnits,
  ...List.filled(extra, 2),
]);

Uint8List fakeText() => Uint8List.fromList('just some text'.codeUnits);

/// A picker that returns what the test prepared, or throws [error].
class FakeMediaPicker implements MediaPicker {
  List<PickedMedia> next = const [];
  MediaPickException? error;
  final List<MediaSource> requests = [];
  final List<String> discarded = [];

  @override
  Future<List<PickedMedia>> pick(MediaSource source) async {
    requests.add(source);
    if (error case final e?) throw e;
    return next;
  }

  @override
  Future<void> discard(PickedMedia media) async => discarded.add(media.path);
}

/// An in-memory store whose "source files" are registered by the test, so
/// widget tests never touch the disk.
class FakeVisitMediaFileStore extends InMemoryVisitMediaFileStore {
  final Map<String, Uint8List> sources = {};
  bool failImport = false;
  bool failDelete = false;
  int cleanUps = 0;

  @override
  Future<StoredMediaFile> import(String sourcePath) async {
    if (failImport) {
      throw const MediaFileException(MediaFileError.storageFailed);
    }
    final bytes = sources[sourcePath];
    if (bytes == null) {
      throw const MediaFileException(MediaFileError.unreadable);
    }
    return store(sourcePath, bytes);
  }

  @override
  Future<bool> delete(String fileName) async {
    if (failDelete) return false;
    return super.delete(fileName);
  }

  @override
  Future<void> deleteUnreferenced(Set<String> referenced) async {
    cleanUps++;
    await super.deleteUnreferenced(referenced);
  }
}
