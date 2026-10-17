import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Where a new photo or video comes from.
enum MediaSource { cameraPhoto, cameraVideo, gallery }

/// Why picking failed.
enum MediaPickError {
  /// The user refused access to the camera or the photo library.
  permissionDenied,

  /// The device has no usable camera.
  cameraUnavailable,

  /// Any other failure.
  failed,
}

/// A failed pick. Never carries a path or the platform's message.
class MediaPickException implements Exception {
  const MediaPickException(this.error);

  final MediaPickError error;

  @override
  String toString() => 'MediaPickException(${error.name})';
}

/// A file the user captured or chose, not yet in private storage.
class PickedMedia {
  const PickedMedia(this.path);

  final String path;

  @override
  String toString() => 'PickedMedia()';
}

/// Captures or chooses photos and videos. Replaceable in tests.
abstract interface class MediaPicker {
  /// The files the user picked; empty if they cancelled. Throws a
  /// [MediaPickException] on failure, including refused permissions.
  Future<List<PickedMedia>> pick(MediaSource source);

  /// Removes the picker's temporary copy once it has been stored privately
  /// (or rejected), so no medical photo lingers in the app's cache. Never
  /// touches the user's original in the gallery.
  Future<void> discard(PickedMedia media);
}

/// [MediaPicker] backed by the platform camera and photo picker
/// (image_picker). Photos and videos taken with the camera are not saved
/// to the gallery.
class ImagePickerMediaPicker implements MediaPicker {
  ImagePickerMediaPicker({ImagePicker? picker})
    : _picker = picker ?? ImagePicker();

  final ImagePicker _picker;

  /// Long enough for a cough or a tremor, short enough to stay small.
  static const Duration maxVideoDuration = Duration(seconds: 60);

  /// Most files added from the gallery at once.
  static const int maxGalleryItems = 10;

  @override
  Future<List<PickedMedia>> pick(MediaSource source) async {
    try {
      final List<XFile> files = switch (source) {
        MediaSource.cameraPhoto => [
          ?await _picker.pickImage(
            source: ImageSource.camera,
            requestFullMetadata: false,
          ),
        ],
        MediaSource.cameraVideo => [
          ?await _picker.pickVideo(
            source: ImageSource.camera,
            maxDuration: maxVideoDuration,
          ),
        ],
        MediaSource.gallery => await _picker.pickMultipleMedia(
          limit: maxGalleryItems,
          requestFullMetadata: false,
        ),
      };
      return [for (final file in files) PickedMedia(file.path)];
    } on PlatformException catch (error) {
      throw MediaPickException(_errorFor(error.code));
    } catch (_) {
      throw const MediaPickException(MediaPickError.failed);
    }
  }

  static MediaPickError _errorFor(String code) {
    if (code.contains('access_denied') || code.contains('permission')) {
      return MediaPickError.permissionDenied;
    }
    if (code == 'no_available_camera') return MediaPickError.cameraUnavailable;
    return MediaPickError.failed;
  }

  @override
  Future<void> discard(PickedMedia media) async {
    try {
      // Only the picker's own copies, which it always places in the app's
      // temporary directory.
      final temporary = (await getTemporaryDirectory()).path;
      if (!p.isWithin(temporary, media.path)) return;
      final file = File(media.path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // The OS clears the temporary directory eventually.
    }
  }
}
