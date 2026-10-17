import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/reminders/reminder_scheduler.dart';

/// The reminders to schedule, and how far ahead they reach.
class ReminderPlan {
  const ReminderPlan({required this.reminders, required this.isTruncated});

  /// Earliest first, each at a different minute.
  final List<PlannedReminder> reminders;

  /// Whether more doses were due within the planning window than could be
  /// scheduled. Planning again later (e.g. when the app opens) schedules
  /// the rest.
  final bool isTruncated;

  /// The last reminder scheduled, or null if there are none.
  DateTime? get lastReminderAt => reminders.isEmpty ? null : reminders.last.at;
}

/// Works out which reminders to schedule, from the stored medications.
///
/// The database is the only source of truth: the plan is rebuilt from it
/// after every change and when the app starts or comes back to the
/// foreground, and replaces whatever was scheduled before. Nothing about
/// reminders is stored.
///
/// Bounded on purpose, since platforms limit pending notifications (iOS
/// keeps only 64 per app): only the next [maxReminders] reminders within
/// [horizon] are planned.
abstract final class ReminderPlanner {
  /// Kept well below iOS's 64, leaving room for the platform's own margin.
  static const int maxReminders = 48;

  static const Duration horizon = Duration(days: 14);

  /// Plans reminders for the doses of [medications] due after [now] and
  /// within [horizon], inside each treatment's dates only. Doses already
  /// recorded in [records] (e.g. taken early) get no reminder.
  ///
  /// Doses due in the same minute share one reminder: the text is generic,
  /// so a second notification would add nothing.
  static ReminderPlan plan({
    required Iterable<Medication> medications,
    required Iterable<DoseRecord> records,
    required DateTime now,
    int maxReminders = ReminderPlanner.maxReminders,
    Duration horizon = ReminderPlanner.horizon,
  }) {
    final recorded = {
      for (final record in records)
        '${record.medicationId}\u0000${record.scheduledAt}',
    };
    final today = DateTime(now.year, now.month, now.day);
    final until = now.add(horizon);
    final due = <DateTime>{};

    for (final medication in medications) {
      // Calendar days, so a daylight-saving change cannot skip or repeat
      // one.
      for (
        var day = today;
        !day.isAfter(until);
        day = DateTime(day.year, day.month, day.day + 1)
      ) {
        for (final at in medication.doseTimesOn(day)) {
          if (!at.isAfter(now) || at.isAfter(until)) continue;
          if (recorded.contains('${medication.id}\u0000$at')) continue;
          due.add(at);
        }
      }
    }

    final sorted = due.toList()..sort();
    final kept = sorted.take(maxReminders);
    return ReminderPlan(
      reminders: List.unmodifiable([
        for (final at in kept) PlannedReminder(id: reminderIdFor(at), at: at),
      ]),
      isTruncated: sorted.length > maxReminders,
    );
  }

  /// A positive 31-bit id that is the same for the same wall-clock minute,
  /// and different for different minutes for thousands of years.
  static int reminderIdFor(DateTime at) {
    final minutes =
        DateTime.utc(
          at.year,
          at.month,
          at.day,
          at.hour,
          at.minute,
        ).millisecondsSinceEpoch ~/
        Duration.millisecondsPerMinute;
    return minutes % 0x7fffffff;
  }
}
