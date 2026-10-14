import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/features/appointments/appointment_formatting.dart';

void main() {
  late MaterialLocalizations localizations;
  final now = DateTime(2026, 10, 14, 12);

  setUpAll(() async {
    localizations = await GlobalMaterialLocalizations.delegate.load(
      const Locale('he'),
    );
  });

  String format(DateTime dateTime) =>
      formatAppointmentDateTime(dateTime, now, localizations);

  test('uses today, tomorrow and yesterday for nearby days', () {
    expect(format(DateTime(2026, 10, 14, 9, 5)), '${AppStrings.today} · 9:05');
    expect(
      format(DateTime(2026, 10, 15, 16, 30)),
      startsWith(AppStrings.tomorrow),
    );
    expect(format(DateTime(2026, 10, 13, 8)), startsWith(AppStrings.yesterday));
  });

  test('uses the 24-hour clock', () {
    expect(format(DateTime(2026, 10, 14, 18, 45)), endsWith('18:45'));
  });

  test('shows the date without the year in the current year', () {
    final date = DateTime(2026, 10, 22, 10);
    expect(format(date), '${localizations.formatMediumDate(date)} · 10:00');
  });

  test('includes the year for other years', () {
    final date = DateTime(2025, 3, 2, 10);
    expect(format(date), '${localizations.formatFullDate(date)} · 10:00');
    expect(format(date), contains('2025'));
  });
}
