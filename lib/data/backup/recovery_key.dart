import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// The secret that encrypts a user's cloud backups.
///
/// Created on the device and shown to the user once, to keep somewhere
/// safe. It never leaves the device in any other form: the cloud only ever
/// receives data already encrypted with keys derived from it, so neither
/// the server nor anyone with access to it can read a backup. Without it, a
/// backup cannot be restored.
///
/// 128 random bits, written as 28 characters in seven groups of four:
/// 26 characters of Crockford base32 and 2 check characters that catch
/// typing mistakes.
class RecoveryKey {
  RecoveryKey._(Uint8List bytes) : bytes = Uint8List.fromList(bytes);

  static const int byteLength = 16;
  static const int _dataChars = 26;
  static const int _checkChars = 2;
  static const int length = _dataChars + _checkChars;

  /// Crockford's base32: no I, L, O or U, so it is easy to read back.
  static const String _alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';

  final Uint8List bytes;

  static RecoveryKey generate([Random? random]) {
    final source = random ?? Random.secure();
    return RecoveryKey._(
      Uint8List.fromList([
        for (var i = 0; i < byteLength; i++) source.nextInt(256),
      ]),
    );
  }

  /// A key from its [byteLength] bytes, e.g. read back from storage.
  static RecoveryKey fromBytes(List<int> bytes) {
    if (bytes.length != byteLength) {
      throw const FormatException('A recovery key has 16 bytes');
    }
    return RecoveryKey._(Uint8List.fromList(bytes));
  }

  /// Reads a key typed by the user. Spaces, dashes and case are ignored,
  /// and the letters I and L are read as 1 and O as 0. Throws a
  /// [FormatException] for anything else, including a wrong check.
  static RecoveryKey parse(String text) {
    final cleaned = text
        .toUpperCase()
        .replaceAll(RegExp(r'[\s\-]'), '')
        .replaceAll(RegExp('[IL]'), '1')
        .replaceAll('O', '0');
    if (cleaned.length != length) {
      throw const FormatException('A recovery key has 28 characters');
    }
    final values = <int>[];
    for (final char in cleaned.split('')) {
      final value = _alphabet.indexOf(char);
      if (value < 0) throw const FormatException('Not a recovery key');
      values.add(value);
    }

    // 26 characters hold 130 bits; the 2 highest must be zero.
    var bits = BigInt.zero;
    for (final value in values.take(_dataChars)) {
      bits = (bits << 5) | BigInt.from(value);
    }
    if (bits >> (byteLength * 8) != BigInt.zero) {
      throw const FormatException('Not a recovery key');
    }
    final bytes = Uint8List(byteLength);
    for (var i = byteLength - 1; i >= 0; i--) {
      bytes[i] = (bits & BigInt.from(0xff)).toInt();
      bits >>= 8;
    }
    final key = RecoveryKey._(bytes);
    if (cleaned.substring(_dataChars) != key._check()) {
      throw const FormatException('The recovery key has a typing mistake');
    }
    return key;
  }

  /// 'ABCD-EFGH-…', as shown to the user.
  String format() {
    final text = _encode();
    return [
      for (var i = 0; i < text.length; i += 4) text.substring(i, i + 4),
    ].join('-');
  }

  String _encode() {
    var bits = BigInt.zero;
    for (final byte in bytes) {
      bits = (bits << 8) | BigInt.from(byte);
    }
    final chars = List.filled(_dataChars, '');
    for (var i = _dataChars - 1; i >= 0; i--) {
      chars[i] = _alphabet[(bits & BigInt.from(31)).toInt()];
      bits >>= 5;
    }
    return chars.join() + _check();
  }

  /// The first 10 bits of the key's SHA-256, as two characters.
  String _check() {
    final digest = sha256.convert(bytes).bytes;
    final value = (digest[0] << 2) | (digest[1] >> 6);
    return _alphabet[value >> 5] + _alphabet[value & 31];
  }

  @override
  bool operator ==(Object other) =>
      other is RecoveryKey &&
      other.bytes.length == bytes.length &&
      Iterable.generate(bytes.length).every((i) => other.bytes[i] == bytes[i]);

  @override
  int get hashCode => Object.hashAll(bytes);

  /// Never shows the key itself.
  @override
  String toString() => 'RecoveryKey(…)';
}
