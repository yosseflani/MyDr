import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as hash;
import 'package:cryptography/cryptography.dart';
import 'package:cryptography/dart.dart';
import 'package:mydr/data/backup/recovery_key.dart';

/// Why an encrypted backup object could not be read.
enum BackupDecryptionError {
  /// It was encrypted with a different recovery key.
  wrongKey,

  /// It was changed, cut short, swapped with another object, or damaged.
  damaged,

  /// Not a MyDr backup object, or one of a newer format.
  unsupported,
}

class BackupDecryptionException implements Exception {
  const BackupDecryptionException(this.error);

  final BackupDecryptionError error;

  @override
  String toString() => 'BackupDecryptionException(${error.name})';
}

/// The result of encrypting a file: the plain content's size and SHA-256,
/// for the backup manifest.
class EncryptedFileInfo {
  const EncryptedFileInfo({required this.plainSize, required this.sha256});

  final int plainSize;
  final String sha256;
}

/// Encrypts and decrypts backup objects with keys derived from a
/// [RecoveryKey]. Everything happens on the device.
///
/// Format of an object, version 1:
///
///     magic        8 bytes   'MYDRBAK1'
///     salt        32 bytes   random, new for every object
///     key check   16 bytes   HKDF(recovery key, info 'key check'); tells a
///                            wrong recovery key apart from damage
///     chunks                 each: 4-byte big-endian length, then
///                            ciphertext and 16-byte GCM tag
///
/// * Each object has its own AES-256-GCM key:
///   HKDF-SHA256(recovery key, salt, info 'mydr-backup-v1|' + context).
/// * Content is encrypted in chunks of [chunkSize], so a large video never
///   has to fit in memory. Chunk nonces are an 11-byte counter and a
///   1-byte "last chunk" flag, so chunks cannot be reordered, dropped or
///   cut off at the end without detection.
/// * The header and the [context] (the backup and the object's name) are
///   authenticated with every chunk, so an object cannot be swapped with
///   another one, from this backup or another.
class BackupCipher {
  BackupCipher(RecoveryKey key, {Random? random})
    : _secret = SecretKey(List.unmodifiable(key.bytes)),
      _random = random ?? Random.secure();

  static const List<int> magic = [
    0x4d,
    0x59,
    0x44,
    0x52,
    0x42,
    0x41,
    0x4b,
    0x31,
  ];
  static const int saltLength = 32;
  static const int keyCheckLength = 16;
  static const int headerLength = 8 + saltLength + keyCheckLength;
  static const int chunkSize = 1 << 20;
  static const int _tagLength = 16;

  // The pure Dart implementations, explicitly: the same code runs in the
  // tests and on every device, with no platform channel in between.
  static final AesGcm _aes = DartAesGcm.with256bits();
  static final Hkdf _objectKdf = DartHkdf(
    hmac: DartHmac.sha256(),
    outputLength: 32,
  );
  static final Hkdf _checkKdf = DartHkdf(
    hmac: DartHmac.sha256(),
    outputLength: keyCheckLength,
  );

  final SecretKey _secret;
  final Random _random;
  List<int>? _keyCheck;

  /// The key check stored in every object's header.
  Future<List<int>> keyCheck() async =>
      _keyCheck ??= await (await _checkKdf.deriveKey(
        secretKey: _secret,
        info: utf8.encode('mydr-backup-v1 key check'),
      )).extractBytes();

  /// Whether [header] (at least [headerLength] bytes of an object) was
  /// written with this recovery key. Throws for something that is not a
  /// backup object.
  Future<bool> matchesHeader(List<int> header) async {
    _checkMagic(header);
    final stored = header.sublist(8 + saltLength, headerLength);
    return _constantTimeEquals(stored, await keyCheck());
  }

  Future<Uint8List> encryptBytes(List<int> plain, {required String context}) {
    final output = BytesBuilder(copy: false);
    return _encrypt(
      _chunksOf(plain),
      (part) async => output.add(part),
      context: context,
    ).then((_) => output.takeBytes());
  }

  Future<Uint8List> decryptBytes(
    List<int> encrypted, {
    required String context,
  }) {
    final output = BytesBuilder(copy: false);
    return _decrypt(
      _BytesReader(encrypted),
      (part) async => output.add(part),
      context: context,
    ).then((_) => output.takeBytes());
  }

  /// Encrypts [input] into [output], reading one chunk at a time.
  Future<EncryptedFileInfo> encryptFile(
    File input,
    File output, {
    required String context,
  }) async {
    final reader = await input.open();
    final sink = await output.open(mode: FileMode.write);
    final digest = _DigestSink();
    final hashing = hash.sha256.startChunkedConversion(digest);
    var size = 0;
    try {
      Stream<List<int>> chunks() async* {
        while (true) {
          final chunk = await reader.read(chunkSize);
          hashing.add(chunk);
          size += chunk.length;
          yield chunk;
          if (chunk.length < chunkSize) return;
        }
      }

      await _encrypt(chunks(), sink.writeFrom, context: context);
    } finally {
      await reader.close();
      await sink.close();
    }
    hashing.close();
    return EncryptedFileInfo(plainSize: size, sha256: digest.value.toString());
  }

  /// Decrypts [input] into [output]. On any failure [output] is deleted,
  /// so nothing unverified is ever left behind.
  Future<EncryptedFileInfo> decryptFile(
    File input,
    File output, {
    required String context,
  }) async {
    final reader = await input.open();
    final sink = await output.open(mode: FileMode.write);
    final digest = _DigestSink();
    final hashing = hash.sha256.startChunkedConversion(digest);
    var size = 0;
    var completed = false;
    try {
      // Each chunk is written only after its tag was verified.
      await _decrypt(_FileReader(reader), (part) async {
        hashing.add(part);
        size += part.length;
        await sink.writeFrom(part);
      }, context: context);
      completed = true;
    } finally {
      await reader.close();
      await sink.close();
      if (!completed && await output.exists()) await output.delete();
    }
    hashing.close();
    return EncryptedFileInfo(plainSize: size, sha256: digest.value.toString());
  }

  Future<void> _encrypt(
    Stream<List<int>> chunks,
    Future<void> Function(List<int>) write, {
    required String context,
  }) async {
    final salt = [for (var i = 0; i < saltLength; i++) _random.nextInt(256)];
    final header = [...magic, ...salt, ...await keyCheck()];
    await write(header);
    final key = await _objectKey(salt, context);
    final aad = [...header, ...utf8.encode(context)];

    // Each chunk is written once the next one is known, so the last can be
    // marked as last.
    List<int>? previous;
    var counter = 0;
    await for (final chunk in chunks) {
      if (previous != null) {
        await _writeChunk(previous, counter++, false, key, aad, write);
      }
      previous = chunk;
    }
    await _writeChunk(previous ?? const [], counter, true, key, aad, write);
  }

  Future<void> _writeChunk(
    List<int> plain,
    int counter,
    bool isLast,
    SecretKey key,
    List<int> aad,
    Future<void> Function(List<int>) write,
  ) async {
    final box = await _aes.encrypt(
      plain,
      secretKey: key,
      nonce: _nonce(counter, isLast),
      aad: aad,
    );
    final length = box.cipherText.length + _tagLength;
    await write([
      (length >> 24) & 0xff,
      (length >> 16) & 0xff,
      (length >> 8) & 0xff,
      length & 0xff,
      ...box.cipherText,
      ...box.mac.bytes,
    ]);
  }

  Future<void> _decrypt(
    _Reader reader,
    Future<void> Function(List<int>) write, {
    required String context,
  }) async {
    final header = await reader.read(headerLength);
    if (header.length < headerLength) {
      throw const BackupDecryptionException(BackupDecryptionError.unsupported);
    }
    if (!await matchesHeader(header)) {
      throw const BackupDecryptionException(BackupDecryptionError.wrongKey);
    }
    final salt = header.sublist(8, 8 + saltLength);
    final key = await _objectKey(salt, context);
    final aad = [...header, ...utf8.encode(context)];

    for (var counter = 0; ; counter++) {
      final lengthBytes = await reader.read(4);
      if (lengthBytes.length < 4) {
        // Ended without a chunk marked as last: cut short.
        throw const BackupDecryptionException(BackupDecryptionError.damaged);
      }
      final length =
          (lengthBytes[0] << 24) |
          (lengthBytes[1] << 16) |
          (lengthBytes[2] << 8) |
          lengthBytes[3];
      if (length < _tagLength || length > chunkSize + _tagLength) {
        throw const BackupDecryptionException(BackupDecryptionError.damaged);
      }
      final body = await reader.read(length);
      if (body.length < length) {
        throw const BackupDecryptionException(BackupDecryptionError.damaged);
      }
      final split = length - _tagLength;
      final cipherText = body.sublist(0, split);
      final tag = Mac(body.sublist(split));

      // The flag is part of the nonce, so a chunk only decrypts as what it
      // was written as.
      for (final isLast in const [false, true]) {
        try {
          final plain = await _aes.decrypt(
            SecretBox(cipherText, nonce: _nonce(counter, isLast), mac: tag),
            secretKey: key,
            aad: aad,
          );
          await write(plain);
          if (isLast) {
            if ((await reader.read(1)).isNotEmpty) {
              throw const BackupDecryptionException(
                BackupDecryptionError.damaged,
              );
            }
            return;
          }
          break;
        } on SecretBoxAuthenticationError {
          if (isLast) {
            throw const BackupDecryptionException(
              BackupDecryptionError.damaged,
            );
          }
        }
      }
    }
  }

  Future<SecretKey> _objectKey(List<int> salt, String context) =>
      _objectKdf.deriveKey(
        secretKey: _secret,
        nonce: salt,
        info: utf8.encode('mydr-backup-v1|$context'),
      );

  static List<int> _nonce(int counter, bool isLast) {
    final nonce = Uint8List(12);
    var value = counter;
    for (var i = 10; i >= 0 && value > 0; i--) {
      nonce[i] = value & 0xff;
      value >>= 8;
    }
    nonce[11] = isLast ? 1 : 0;
    return nonce;
  }

  static void _checkMagic(List<int> header) {
    if (header.length < headerLength ||
        !Iterable.generate(magic.length).every((i) => header[i] == magic[i])) {
      throw const BackupDecryptionException(BackupDecryptionError.unsupported);
    }
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var difference = 0;
    for (var i = 0; i < a.length; i++) {
      difference |= a[i] ^ b[i];
    }
    return difference == 0;
  }

  static Stream<List<int>> _chunksOf(List<int> bytes) async* {
    for (var start = 0; start < bytes.length; start += chunkSize) {
      yield bytes.sublist(start, min(start + chunkSize, bytes.length));
    }
  }
}

abstract interface class _Reader {
  /// Up to [count] bytes; fewer only at the end.
  Future<List<int>> read(int count);
}

class _BytesReader implements _Reader {
  _BytesReader(this._bytes);

  final List<int> _bytes;
  int _position = 0;

  @override
  Future<List<int>> read(int count) async {
    final end = min(_position + count, _bytes.length);
    final part = _bytes.sublist(_position, end);
    _position = end;
    return part;
  }
}

class _FileReader implements _Reader {
  _FileReader(this._file);

  final RandomAccessFile _file;

  @override
  Future<List<int>> read(int count) => _file.read(count);
}

class _DigestSink implements Sink<hash.Digest> {
  late hash.Digest value;

  @override
  void add(hash.Digest data) => value = data;

  @override
  void close() {}
}
