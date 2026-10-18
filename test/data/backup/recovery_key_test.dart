import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/backup/recovery_key.dart';

void main() {
  test('round-trips through its written form', () {
    final random = Random(1);
    for (var i = 0; i < 200; i++) {
      final key = RecoveryKey.generate(random);
      final text = key.format();
      expect(
        text,
        matches(RegExp(r'^([0-9A-HJKMNP-TV-Z]{4}-){6}[0-9A-HJKMNP-TV-Z]{4}$')),
      );
      expect(RecoveryKey.parse(text), key);
    }
  });

  test('accepts spaces, lower case and look-alike letters', () {
    final key = RecoveryKey.generate(Random(2));
    final text = key.format();
    expect(RecoveryKey.parse(text.toLowerCase()), key);
    expect(RecoveryKey.parse(text.replaceAll('-', ' ')), key);
    expect(RecoveryKey.parse(text.replaceAll('-', '')), key);
    expect(
      RecoveryKey.parse(text.replaceAll('1', 'I').replaceAll('0', 'O')),
      key,
    );
  });

  test('catches a mistyped character', () {
    final key = RecoveryKey.generate(Random(3));
    final text = key.format().replaceAll('-', '');
    var caught = 0;
    for (var i = 0; i < text.length; i++) {
      final replacement = text[i] == 'A' ? 'B' : 'A';
      final typo = text.replaceRange(i, i + 1, replacement);
      try {
        if (RecoveryKey.parse(typo) != key) caught++;
      } on FormatException {
        caught++;
      }
    }
    expect(caught, text.length);
  });

  test('refuses anything that is not a key', () {
    for (final text in ['', 'abcd', 'U' * 28, '${'0' * 27}!', '0' * 29]) {
      expect(
        () => RecoveryKey.parse(text),
        throwsFormatException,
        reason: text,
      );
    }
  });

  test('is 128 random bits and never shows itself in logs', () {
    final a = RecoveryKey.generate();
    final b = RecoveryKey.generate();
    expect(a.bytes, hasLength(16));
    expect(a, isNot(b));
    expect(a.toString(), isNot(contains(a.format())));
  });
}
