import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/reminders/reminder_planner.dart';

void main() {
  Medication medication(
    String id, {
    String memberId = 'm1',
    required List<DoseTime> times,
    required DateTime start,
    DateTime? end,
  }) => Medication(
    id: id,
    memberId: memberId,
    name: 'שם $id',
    dose: 'מנה',
    reminderTimes: times,
    startDate: start,
    endDate: end,
  );

  // Example A of the brief.
  final exampleA = medication(
    'a',
    times: [DoseTime(8, 0)],
    start: DateTime(2026, 10, 20),
    end: DateTime(2026, 10, 27),
  );

  List<DateTime> times(ReminderPlan plan) => [
    for (final r in plan.reminders) r.at,
  ];

  test('plans one reminder per dose, only within the treatment dates '
      '(example A)', () {
    final plan = ReminderPlanner.plan(
      medications: [exampleA],
      records: const [],
      now: DateTime(2026, 10, 18, 12),
    );

    expect(times(plan), [
      for (var day = 20; day <= 27; day++) DateTime(2026, 10, day, 8),
    ]);
    expect(times(plan), isNot(contains(DateTime(2026, 10, 28, 8))));
    expect(plan.isTruncated, isFalse);
    expect(plan.lastReminderAt, DateTime(2026, 10, 27, 8));
  });

  test('never plans a dose that is already due', () {
    final plan = ReminderPlanner.plan(
      medications: [exampleA],
      records: const [],
      now: DateTime(2026, 10, 27, 8),
    );
    expect(plan.reminders, isEmpty);
    expect(plan.lastReminderAt, isNull);
  });

  test('skips doses already recorded, e.g. taken early', () {
    final plan = ReminderPlanner.plan(
      medications: [exampleA],
      records: [
        DoseRecord(
          id: 'r1',
          memberId: 'm1',
          medicationId: 'a',
          scheduledAt: DateTime(2026, 10, 21, 8),
          status: DoseStatus.taken,
          recordedAt: DateTime(2026, 10, 21, 7, 40),
        ),
      ],
      now: DateTime(2026, 10, 21, 7, 45),
    );
    expect(times(plan).first, DateTime(2026, 10, 22, 8));
  });

  test('a record of another medication at the same time does not skip it', () {
    final other = medication(
      'b',
      memberId: 'm2',
      times: [DoseTime(8, 0)],
      start: DateTime(2026, 10, 20),
    );
    final plan = ReminderPlanner.plan(
      medications: [exampleA, other],
      records: [
        DoseRecord(
          id: 'r1',
          memberId: 'm2',
          medicationId: 'b',
          scheduledAt: DateTime(2026, 10, 21, 8),
          status: DoseStatus.taken,
          recordedAt: DateTime(2026, 10, 21, 7, 40),
        ),
      ],
      now: DateTime(2026, 10, 21, 7, 45),
    );
    expect(times(plan).first, DateTime(2026, 10, 21, 8));
  });

  test('doses due in the same minute share one reminder', () {
    final b = medication(
      'b',
      memberId: 'm2',
      times: [DoseTime(8, 0), DoseTime(20, 0)],
      start: DateTime(2026, 10, 20),
      end: DateTime(2026, 10, 20),
    );
    final plan = ReminderPlanner.plan(
      medications: [exampleA, b],
      records: const [],
      now: DateTime(2026, 10, 19, 12),
      horizon: const Duration(days: 1, hours: 12),
    );
    expect(times(plan), [
      DateTime(2026, 10, 20, 8),
      DateTime(2026, 10, 20, 20),
    ]);
    expect(
      plan.reminders.map((r) => r.id).toSet(),
      hasLength(plan.reminders.length),
    );
  });

  test('is bounded by count, earliest first, and says so', () {
    final busy = medication(
      'busy',
      times: [for (var h = 6; h < 14; h++) DoseTime(h, 0)],
      start: DateTime(2026, 10, 1),
    );
    final plan = ReminderPlanner.plan(
      medications: [busy],
      records: const [],
      now: DateTime(2026, 10, 18, 0, 30),
      maxReminders: 10,
    );
    expect(plan.reminders, hasLength(10));
    expect(plan.isTruncated, isTrue);
    expect(plan.reminders.first.at, DateTime(2026, 10, 18, 6));
    expect(plan.reminders.last.at, DateTime(2026, 10, 19, 7));
  });

  test('never goes beyond the horizon', () {
    final ongoing = medication(
      'o',
      times: [DoseTime(9, 0)],
      start: DateTime(2026, 1, 1),
    );
    final now = DateTime(2026, 10, 18, 12);
    final plan = ReminderPlanner.plan(
      medications: [ongoing],
      records: const [],
      now: now,
    );
    expect(plan.reminders, hasLength(14));
    expect(
      plan.reminders.every(
        (r) =>
            r.at.isAfter(now) &&
            !r.at.isAfter(now.add(ReminderPlanner.horizon)),
      ),
      isTrue,
    );
    expect(
      plan.reminders.length,
      lessThanOrEqualTo(ReminderPlanner.maxReminders),
    );
  });

  test('defaults stay within the iOS limit of 64 pending notifications', () {
    expect(ReminderPlanner.maxReminders, lessThan(64));
  });

  test('a treatment that starts later is planned from its first day', () {
    final later = medication(
      'l',
      times: [DoseTime(10, 0)],
      start: DateTime(2026, 10, 25),
    );
    final plan = ReminderPlanner.plan(
      medications: [later],
      records: const [],
      now: DateTime(2026, 10, 18, 12),
    );
    expect(times(plan).first, DateTime(2026, 10, 25, 10));
  });

  test('ids are stable for the same minute and differ between minutes', () {
    final a = ReminderPlanner.reminderIdFor(DateTime(2026, 10, 20, 8));
    expect(ReminderPlanner.reminderIdFor(DateTime(2026, 10, 20, 8)), a);
    expect(
      ReminderPlanner.reminderIdFor(DateTime(2026, 10, 20, 8, 1)),
      isNot(a),
    );
    expect(a, greaterThan(0));
    expect(a, lessThan(0x7fffffff));
  });

  test('with no medications there is nothing to schedule', () {
    final plan = ReminderPlanner.plan(
      medications: const [],
      records: const [],
      now: DateTime(2026, 10, 18),
    );
    expect(plan.reminders, isEmpty);
    expect(plan.isTruncated, isFalse);
  });
}
