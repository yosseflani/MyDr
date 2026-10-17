import 'package:mydr/data/models/visit_media.dart';

/// Why a picked file was not accepted.
enum MediaFileError {
  /// Not a supported photo or video, judged by both its extension and its
  /// content.
  unsupportedType,

  /// Larger than the limit for its kind.
  tooLarge,

  /// Empty, missing or could not be read.
  unreadable,

  /// Private storage could not be written.
  storageFailed,
}

/// A rejected or failed media file. Never carries the file's name, path or
/// content, so it is safe to log.
class MediaFileException implements Exception {
  const MediaFileException(this.error);

  final MediaFileError error;

  @override
  String toString() => 'MediaFileException(${error.name})';
}

/// Checks a picked file before it is copied into private storage.
///
/// The extension alone is not trusted: the first bytes must match a known
/// photo or video format of the same kind.
abstract final class MediaFileValidator {
  static const int maxPhotoBytes = 25 * 1024 * 1024;
  static const int maxVideoBytes = 150 * 1024 * 1024;

  /// How many leading bytes [validate] needs.
  static const int headerLength = 16;

  static const Set<String> photoExtensions = {
    'jpg',
    'jpeg',
    'png',
    'webp',
    'heic',
    'heif',
  };
  static const Set<String> videoExtensions = {'mp4', 'm4v', 'mov', '3gp'};

  /// ISO base media file brands used by HEIF/HEIC photos.
  static const Set<String> _heifBrands = {
    'heic',
    'heix',
    'hevc',
    'hevx',
    'heim',
    'heis',
    'mif1',
    'msf1',
  };

  /// Top-level boxes an older QuickTime file may start with.
  static const Set<String> _quickTimeBoxes = {
    'moov',
    'mdat',
    'wide',
    'free',
    'skip',
  };

  /// The lower-case extension of [name], or '' if it has none.
  static String extensionOf(String name) {
    final slash = name.lastIndexOf(RegExp(r'[/\\]'));
    final base = name.substring(slash + 1);
    final dot = base.lastIndexOf('.');
    return dot <= 0 ? '' : base.substring(dot + 1).toLowerCase();
  }

  /// Returns the file's kind, or throws a [MediaFileException].
  ///
  /// [header] holds the file's first bytes (at least [headerLength] unless
  /// the file is shorter) and [length] its total size.
  static VisitMediaKind validate({
    required String name,
    required int length,
    required List<int> header,
  }) {
    if (length <= 0 || header.isEmpty) {
      throw const MediaFileException(MediaFileError.unreadable);
    }
    final extension = extensionOf(name);
    final VisitMediaKind kind;
    if (photoExtensions.contains(extension)) {
      kind = VisitMediaKind.photo;
    } else if (videoExtensions.contains(extension)) {
      kind = VisitMediaKind.video;
    } else {
      throw const MediaFileException(MediaFileError.unsupportedType);
    }

    if (_contentKind(header) != kind) {
      throw const MediaFileException(MediaFileError.unsupportedType);
    }
    final limit = kind == VisitMediaKind.photo ? maxPhotoBytes : maxVideoBytes;
    if (length > limit) throw const MediaFileException(MediaFileError.tooLarge);
    return kind;
  }

  /// The kind the content's signature shows, or null if unknown.
  static VisitMediaKind? _contentKind(List<int> header) {
    bool hasBytes(List<int> bytes) {
      if (header.length < bytes.length) return false;
      for (var i = 0; i < bytes.length; i++) {
        if (header[i] != bytes[i]) return false;
      }
      return true;
    }

    String text(int offset, int count) => header.length < offset + count
        ? ''
        : String.fromCharCodes(header.sublist(offset, offset + count));

    // JPEG, PNG and WebP.
    if (hasBytes(const [0xFF, 0xD8, 0xFF])) return VisitMediaKind.photo;
    if (hasBytes(const [0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A])) {
      return VisitMediaKind.photo;
    }
    if (text(0, 4) == 'RIFF' && text(8, 4) == 'WEBP') {
      return VisitMediaKind.photo;
    }

    // ISO base media (MP4, MOV, 3GP, HEIF): a box type at offset 4.
    final box = text(4, 4);
    if (box == 'ftyp') {
      return _heifBrands.contains(text(8, 4))
          ? VisitMediaKind.photo
          : VisitMediaKind.video;
    }
    if (_quickTimeBoxes.contains(box)) return VisitMediaKind.video;
    return null;
  }
}
