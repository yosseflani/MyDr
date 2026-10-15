import 'dart:math';

/// Ids for records stored in the local database: random (version 4) UUIDs,
/// unique across restarts and devices, and revealing nothing about the
/// record or when it was made.
abstract final class LocalIds {
  static final Random _random = Random.secure();

  static String generate() {
    final bytes = [for (var i = 0; i < 16; i++) _random.nextInt(256)];
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4.
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant.
    final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
    return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
        '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
        '${hex.sublist(10).join()}';
  }
}
