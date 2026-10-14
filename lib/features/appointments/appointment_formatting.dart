import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';

/// Date and time of an appointment in clear Hebrew, relative to [now]:
/// "היום · 10:30", "מחר · 09:00", "יום ה׳, 22 באוק׳ · 16:30", and with the
/// year when it is not the current one. Times use the 24-hour clock.
String formatAppointmentDateTime(
  DateTime dateTime,
  DateTime now,
  MaterialLocalizations localizations,
) {
  final time = localizations.formatTimeOfDay(
    TimeOfDay.fromDateTime(dateTime),
    alwaysUse24HourFormat: true,
  );
  return '${_dayLabel(dateTime, now, localizations)} · $time';
}

String _dayLabel(
  DateTime dateTime,
  DateTime now,
  MaterialLocalizations localizations,
) {
  final day = DateUtils.dateOnly(dateTime);
  final today = DateUtils.dateOnly(now);
  // Calendar days, so a daylight-saving change cannot skew the count.
  final dayDifference = DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;

  return switch (dayDifference) {
    0 => AppStrings.today,
    1 => AppStrings.tomorrow,
    -1 => AppStrings.yesterday,
    _ when day.year == today.year => localizations.formatMediumDate(day),
    _ => localizations.formatFullDate(day),
  };
}
