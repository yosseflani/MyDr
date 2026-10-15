import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';

/// Heading for one day of the journal, relative to [now]:
/// "היום · יום ה׳, 15 באוק׳", "אתמול · יום ד׳, 14 באוק׳", or the full date
/// ("יום שני, 12 באוקטובר 2026") for older days. The date is always shown.
String formatSymptomDay(
  DateTime day,
  DateTime now,
  MaterialLocalizations localizations,
) {
  final date = DateUtils.dateOnly(day);
  final today = DateUtils.dateOnly(now);
  // Calendar days, so a daylight-saving change cannot skew the count.
  final dayDifference = DateTime.utc(
    date.year,
    date.month,
    date.day,
  ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;

  return switch (dayDifference) {
    0 => '${AppStrings.today} · ${localizations.formatMediumDate(date)}',
    -1 => '${AppStrings.yesterday} · ${localizations.formatMediumDate(date)}',
    _ => localizations.formatFullDate(date),
  };
}

/// Date and time of a record: "15 באוק׳ 2026 · 9:30", on the 24-hour
/// clock.
String formatSymptomDateTime(
  DateTime dateTime,
  MaterialLocalizations localizations,
) {
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(dateTime),
    alwaysUse24HourFormat: true,
  );
  return '${localizations.formatShortDate(dateTime)} · $time';
}
