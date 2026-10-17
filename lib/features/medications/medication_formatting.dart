import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/medication.dart';

/// A reminder time on the 24-hour clock: "8:00".
String formatDoseTime(DoseTime time, MaterialLocalizations localizations) =>
    localizations.formatTimeOfDay(
      TimeOfDay(hour: time.hour, minute: time.minute),
      alwaysUse24HourFormat: true,
    );

/// All of a medication's reminder times: "8:00 · 20:00".
String formatReminderTimes(
  List<DoseTime> times,
  MaterialLocalizations localizations,
) => times.map((t) => formatDoseTime(t, localizations)).join(' · ');

/// The time of day of [at], on the 24-hour clock.
String formatClock(DateTime at, MaterialLocalizations localizations) =>
    localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(at),
      alwaysUse24HourFormat: true,
    );

/// When a scheduled dose is, relative to [now]: "היום · 8:00",
/// "מחר · 8:00", "אתמול · 20:00", or the date and time for other days.
String formatDoseMoment(
  DateTime at,
  DateTime now,
  MaterialLocalizations localizations,
) {
  final day = DateUtils.dateOnly(at);
  final today = DateUtils.dateOnly(now);
  // Calendar days, so a daylight-saving change cannot skew the count.
  final difference = DateTime.utc(
    day.year,
    day.month,
    day.day,
  ).difference(DateTime.utc(today.year, today.month, today.day)).inDays;
  final time = formatClock(at, localizations);
  final date = switch (difference) {
    0 => AppStrings.today,
    1 => AppStrings.tomorrow,
    -1 => AppStrings.yesterday,
    _ => localizations.formatMediumDate(day),
  };
  return '$date · $time';
}

/// The treatment dates: "מ־20 באוק׳ 2026 עד 27 באוק׳ 2026 (כולל)", or
/// "מ־20 באוק׳ 2026, ללא תאריך סיום".
String formatTreatmentDates(
  Medication medication,
  MaterialLocalizations localizations,
) {
  final start = localizations.formatShortDate(medication.startDate);
  final end = medication.endDate;
  return end == null
      ? AppStrings.treatmentFrom(start)
      : AppStrings.treatmentRange(start, localizations.formatShortDate(end));
}

/// Where the treatment stands on [now]'s date.
String formatTreatmentStatus(
  Medication medication,
  DateTime now,
  MaterialLocalizations localizations,
) {
  if (medication.startsAfter(now)) {
    return AppStrings.medicationStartsOn(
      localizations.formatShortDate(medication.startDate),
    );
  }
  return medication.hasEndedBefore(now)
      ? AppStrings.medicationEnded
      : AppStrings.medicationActive;
}
