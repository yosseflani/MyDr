import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/backup/backup_cipher.dart';
import 'package:mydr/data/backup/recovery_key.dart';

void main() {
  final key = RecoveryKey.generate(Random(10));
  final otherKey = RecoveryKey.generate(Random(11));
  final cipher = BackupCipher(key, random: Random(12));
  const context = 'backup-1/data.bin';

  Matcher fails(BackupDecryptionError error) => throwsA(
    isA<BackupDecryptionException>().having((e) => e.error, 'error', error),
  );

  Uint8List bytesOf(int length) => Uint8List.fromList([
    for (var i = 0; i < length; i++) (i * 31 + 7) & 0xff,
  ]);

  test('round-trips, including empty and chunk-boundary sizes', () async {
    for (final length in [
      0,
      1,
      BackupCipher.chunkSize - 1,
      BackupCipher.chunkSize,
      BackupCipher.chunkSize + 1,
      2 * BackupCipher.chunkSize + 5,
    ]) {
      final plain = bytesOf(length);
      final encrypted = await cipher.encryptBytes(plain, context: context);
      expect(
        await cipher.decryptBytes(encrypted, context: context),
        plain,
        reason: '$length bytes',
      );
    }
  });

  test(
    'the ciphertext reveals nothing readable and differs every time',
    () async {
      final plain = utf8.encode('{"name":"דנה","allergies":["אבקה"]}');
      final a = await cipher.encryptBytes(plain, context: context);
      final b = await cipher.encryptBytes(plain, context: context);
      expect(a, isNot(b));
      expect(
        latin1.decode(a, allowInvalid: true),
        isNot(contains('allergies')),
      );
    },
  );

  test('a different recovery key is reported as such', () async {
    final encrypted = await cipher.encryptBytes(bytesOf(100), context: context);
    await expectLater(
      BackupCipher(otherKey).decryptBytes(encrypted, context: context),
      fails(BackupDecryptionError.wrongKey),
    );
    expect(await BackupCipher(otherKey).matchesHeader(encrypted), isFalse);
    expect(await BackupCipher(key).matchesHeader(encrypted), isTrue);
  });

  test('any changed byte is detected', () async {
    final encrypted = await cipher.encryptBytes(
      bytesOf(3000),
      context: context,
    );
    for (final index in [
      BackupCipher.headerLength - 1 - BackupCipher.keyCheckLength, // salt
      BackupCipher.headerLength + 2, // length
      BackupCipher.headerLength + 10, // ciphertext
      encrypted.length - 1, // tag
    ]) {
      final changed = Uint8List.fromList(encrypted)..[index] ^= 0x01;
      await expectLater(
        cipher.decryptBytes(changed, context: context),
        fails(BackupDecryptionError.damaged),
        reason: 'byte $index',
      );
    }
  });

  test('an object cut short or extended is detected', () async {
    final encrypted = await cipher.encryptBytes(
      bytesOf(2 * BackupCipher.chunkSize + 10),
      context: context,
    );
    // Only the first chunk: a clean cut at a chunk boundary.
    final firstChunk =
        BackupCipher.headerLength + 4 + BackupCipher.chunkSize + 16;
    await expectLater(
      cipher.decryptBytes(encrypted.sublist(0, firstChunk), context: context),
      fails(BackupDecryptionError.damaged),
    );
    await expectLater(
      cipher.decryptBytes([...encrypted, 0], context: context),
      fails(BackupDecryptionError.damaged),
    );
  });

  test('an object moved to another name or backup does not decrypt', () async {
    final encrypted = await cipher.encryptBytes(bytesOf(50), context: context);
    await expectLater(
      cipher.decryptBytes(encrypted, context: 'backup-1/media/0.bin'),
      fails(BackupDecryptionError.damaged),
    );
    await expectLater(
      cipher.decryptBytes(encrypted, context: 'backup-2/data.bin'),
      fails(BackupDecryptionError.damaged),
    );
  });

  test('something that is not a backup object is refused', () async {
    await expectLater(
      cipher.decryptBytes(utf8.encode('hello'), context: context),
      fails(BackupDecryptionError.unsupported),
    );
    await expectLater(
      cipher.decryptBytes(Uint8List(200), context: context),
      fails(BackupDecryptionError.unsupported),
    );
  });

  group('files', () {
    late Directory directory;

    setUp(() => directory = Directory.systemTemp.createTempSync('mydr_cipher'));
    tearDown(() => directory.deleteSync(recursive: true));

    test('stream through and report size and SHA-256', () async {
      final plain = bytesOf(3 * BackupCipher.chunkSize + 123);
      final input = File('${directory.path}/in.mp4')..writeAsBytesSync(plain);
      final encrypted = File('${directory.path}/enc.bin');
      final output = File('${directory.path}/out.mp4');

      final info = await cipher.encryptFile(input, encrypted, context: context);
      expect(info.plainSize, plain.length);
      expect(info.sha256, sha256.convert(plain).toString());

      final back = await cipher.decryptFile(
        encrypted,
        output,
        context: context,
      );
      expect(back.sha256, info.sha256);
      expect(output.readAsBytesSync(), plain);
      // Interoperable with the in-memory form.
      expect(
        await cipher.decryptBytes(
          encrypted.readAsBytesSync(),
          context: context,
        ),
        plain,
      );
    });

    test('a failed decryption leaves no output behind', () async {
      final encrypted = File('${directory.path}/enc.bin')
        ..writeAsBytesSync(
          await BackupCipher(
            otherKey,
          ).encryptBytes(bytesOf(10), context: context),
        );
      final output = File('${directory.path}/out.jpg');
      await expectLater(
        cipher.decryptFile(encrypted, output, context: context),
        fails(BackupDecryptionError.wrongKey),
      );
      expect(output.existsSync(), isFalse);
    });
  });
}
