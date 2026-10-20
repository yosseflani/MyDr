import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/local/database_key_store.dart';
import 'package:mydr/data/local/storage_codecs.dart';

void main() {
  group('local date and time', () {
    test('round-trips exactly, down to the microsecond', () {
      for (final value in [
        DateTime(2026, 10, 15, 9, 30),
        DateTime(2026, 3, 27, 2, 30, 15, 123, 456),
        DateTime(1999, 12, 31, 23, 59, 59, 999, 999),
      ]) {
        final text = StorageCodecs.encodeLocalDateTime(value);
        expect(text, hasLength(26));
        expect(StorageCodecs.decodeLocalDateTime(text), value);
      }
    });

    test('keeps the wall-clock time', () {
      expect(
        StorageCodecs.encodeLocalDateTime(DateTime(2026, 10, 15, 9, 5)),
        '2026-10-15T09:05:00.000000',
      );
    });

    test('text order is time order', () {
      final times = [
        DateTime(2026, 10, 15, 9, 0, 0, 0, 1),
        DateTime(2026, 10, 15, 9),
        DateTime(2025, 12, 31, 23, 59),
        DateTime(2026, 10, 15, 10),
        DateTime(2026, 10, 15, 9, 0, 0, 100),
      ];
      final byText = [...times]
        ..sort(
          (a, b) => StorageCodecs.encodeLocalDateTime(
            a,
          ).compareTo(StorageCodecs.encodeLocalDateTime(b)),
        );
      expect(byText, [...times]..sort());
    });

    test('rejects text in another format', () {
      expect(
        () => StorageCodecs.decodeLocalDateTime('2026-10-15 09:00'),
        throwsFormatException,
      );
    });
  });

  group('date', () {
    test('round-trips', () {
      final date = DateTime(2016, 1, 20);
      expect(StorageCodecs.encodeDate(date), '2016-01-20');
      expect(StorageCodecs.decodeDate('2016-01-20'), date);
      expect(
        () => StorageCodecs.decodeDate('20/01/2016'),
        throwsFormatException,
      );
    });
  });

  group('instant', () {
    test('round-trips to an equal local time', () {
      final now = DateTime(2026, 10, 15, 12, 0, 0, 1, 2);
      final stored = StorageCodecs.encodeInstant(now);
      expect(StorageCodecs.decodeInstant(stored), now);
    });
  });

  group('list of text', () {
    test('round-trips, including an empty list and Hebrew', () {
      for (final values in [
        <String>[],
        ['אבקני פרחים', 'with "quotes"', ''],
      ]) {
        final json = StorageCodecs.encodeStringList(values);
        expect(StorageCodecs.decodeStringList(json), values);
      }
    });

    test('rejects anything but a list of text', () {
      expect(
        () => StorageCodecs.decodeStringList('[1, 2]'),
        throwsFormatException,
      );
      expect(
        () => StorageCodecs.decodeStringList('{"a": "b"}'),
        throwsFormatException,
      );
    });
  });

  group('database keys', () {
    test('are 32 random bytes as 64 hex digits', () {
      final key = DatabaseKeys.generate();
      expect(key, hasLength(64));
      expect(DatabaseKeys.isValid(key), isTrue);
    });

    test('are different every time', () {
      final keys = {for (var i = 0; i < 50; i++) DatabaseKeys.generate()};
      expect(keys, hasLength(50));
    });

    test('come from the given generator', () {
      expect(
        DatabaseKeys.generate(Random(1)),
        DatabaseKeys.generate(Random(1)),
      );
    });

    test('reject anything else as a key', () {
      for (final key in ['', 'abc', 'G' * 64, 'A' * 64, '0' * 63]) {
        expect(DatabaseKeys.isValid(key), isFalse, reason: key);
      }
    });
  });

  group('sync values', () {
    test('a JSON object round-trips exactly', () {
      final value = {
        'id': 'x',
        'n': null,
        'list': ['a', 'ב'],
        'nested': {'k': 1},
        'flag': true,
      };
      expect(
        StorageCodecs.decodeJsonObject(StorageCodecs.encodeJsonObject(value)),
        value,
      );
      expect(
        () => StorageCodecs.decodeJsonObject('[1]'),
        throwsFormatException,
      );
    });

    test('a version vector round-trips, sorted, and refuses bad counts', () {
      final counters = {'b': 2, 'a': 7};
      final text = StorageCodecs.encodeCounters(counters);
      expect(text, '{"a":7,"b":2}');
      expect(StorageCodecs.decodeCounters(text), counters);
      for (final bad in ['{"a":0}', '{"a":"1"}', '{"":1}', '[]']) {
        expect(
          () => StorageCodecs.decodeCounters(bad),
          throwsFormatException,
          reason: bad,
        );
      }
    });
  });
}
