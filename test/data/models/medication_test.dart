import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/medication.dart';

void main() {
  // Example A of the brief: 08:00 from October 20 to October 27.
  final medication = Medication(
    id: 'med1',
    memberId: 'm1',
    name: 'תרופת בדיקה',
    dose: '1 tablet',
    reminderTimes: [DoseTime(8, 0)],
    startDate: DateTime(2026, 10, 20, 15, 30),
    endDate: DateTime(2026, 10, 27),
  );

  group('DoseTime', () {
    test('parses and formats the stored form', () {
      expect(DoseTime.parse('08:05'), DoseTime(8, 5));
      expect(DoseTime(8, 5).format(), '08:05');
      expect(DoseTime(23, 59).format(), '23:59');
    });

    test('rejects invalid stored values', () {
      for (final text in ['8:05', '24:00', '12:60', 'ab:cd', '', '08:05:00']) {
        expect(() => DoseTime.parse(text), throwsFormatException, reason: text);
      }
    });

    test('rejects out-of-range values', () {
      expect(() => DoseTime(24, 0), throwsRangeError);
      expect(() => DoseTime(-1, 0), throwsRangeError);
      expect(() => DoseTime(0, 60), throwsRangeError);
    });

    test('orders by time of day', () {
      expect(DoseTime(8, 0).compareTo(DoseTime(20, 0)), lessThan(0));
      expect(DoseTime(8, 30).compareTo(DoseTime(8, 30)), 0);
    });
  });

  group('Medication', () {
    test('keeps dates only and times sorted, each once', () {
      final m = Medication(
        id: 'x',
        memberId: 'm1',
        name: 'n',
        dose: 'd',
        reminderTimes: [DoseTime(20, 0), DoseTime(8, 0), DoseTime(20, 0)],
        startDate: DateTime(2026, 10, 20, 15, 30),
      );
      expect(m.reminderTimes, [DoseTime(8, 0), DoseTime(20, 0)]);
      expect(m.startDate, DateTime(2026, 10, 20));
      expect(
        () => (m.reminderTimes as List).add(DoseTime(9, 0)),
        throwsA(isA<UnsupportedError>()),
      );
    });

    test('is active within its dates only, both ends included', () {
      expect(medication.isActiveOn(DateTime(2026, 10, 19, 23, 59)), isFalse);
      expect(medication.isActiveOn(DateTime(2026, 10, 20)), isTrue);
      expect(medication.isActiveOn(DateTime(2026, 10, 27, 23, 59)), isTrue);
      expect(medication.isActiveOn(DateTime(2026, 10, 28)), isFalse);
      expect(medication.startsAfter(DateTime(2026, 10, 19)), isTrue);
      expect(medication.hasEndedBefore(DateTime(2026, 10, 28)), isTrue);
      expect(medication.hasEndedBefore(DateTime(2026, 10, 27)), isFalse);
    });

    test('has no doses outside its dates (example A)', () {
      expect(medication.doseTimesOn(DateTime(2026, 10, 19)), isEmpty);
      expect(medication.doseTimesOn(DateTime(2026, 10, 20)), [
        DateTime(2026, 10, 20, 8),
      ]);
      expect(medication.doseTimesOn(DateTime(2026, 10, 27)), [
        DateTime(2026, 10, 27, 8),
      ]);
      expect(medication.doseTimesOn(DateTime(2026, 10, 28)), isEmpty);
    });

    test('without an end date stays active', () {
      final ongoing = medication.copyWith(endDate: () => null);
      expect(ongoing.isActiveOn(DateTime(2030, 1, 1)), isTrue);
      expect(ongoing.hasEndedBefore(DateTime(2030, 1, 1)), isFalse);
    });

    test('knows which moments are scheduled doses', () {
      expect(medication.isScheduledAt(DateTime(2026, 10, 22, 8)), isTrue);
      expect(medication.isScheduledAt(DateTime(2026, 10, 22, 8, 1)), isFalse);
      expect(
        medication.isScheduledAt(DateTime(2026, 10, 22, 8, 0, 1)),
        isFalse,
      );
      expect(medication.isScheduledAt(DateTime(2026, 10, 28, 8)), isFalse);
    });

    test('copyWith keeps the family member', () {
      final edited = medication.copyWith(name: 'אחר', dose: '2');
      expect(edited.memberId, 'm1');
      expect(edited.id, 'med1');
      expect(edited.name, 'אחר');
    });

    test('never shows medical details in logs', () {
      expect(medication.toString(), 'Medication(id: med1)');
      expect(medication.toString(), isNot(contains('תרופת')));
      final record = DoseRecord(
        id: 'r1',
        memberId: 'm1',
        medicationId: 'med1',
        scheduledAt: DateTime(2026, 10, 22, 8),
        status: DoseStatus.taken,
        recordedAt: DateTime(2026, 10, 22, 8, 3),
      );
      expect(record.toString(), 'DoseRecord(id: r1)');
    });
  });

  test('a dose record keeps its scheduled time to the minute', () {
    final record = DoseRecord(
      id: 'r1',
      memberId: 'm1',
      medicationId: 'med1',
      scheduledAt: DateTime(2026, 10, 22, 8, 0, 42, 5),
      status: DoseStatus.skipped,
      recordedAt: DateTime(2026, 10, 22, 9),
    );
    expect(record.scheduledAt, DateTime(2026, 10, 22, 8));
  });
}
