import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/features/dashboard/greeting.dart';

void main() {
  DateTime at(int hour) => DateTime(2026, 1, 1, hour);

  test('returns the greeting matching the time of day', () {
    expect(greetingFor(at(5)), AppStrings.greetingMorning);
    expect(greetingFor(at(11)), AppStrings.greetingMorning);
    expect(greetingFor(at(12)), AppStrings.greetingNoon);
    expect(greetingFor(at(16)), AppStrings.greetingNoon);
    expect(greetingFor(at(17)), AppStrings.greetingEvening);
    expect(greetingFor(at(21)), AppStrings.greetingEvening);
    expect(greetingFor(at(22)), AppStrings.greetingNight);
    expect(greetingFor(at(0)), AppStrings.greetingNight);
    expect(greetingFor(at(4)), AppStrings.greetingNight);
  });
}
