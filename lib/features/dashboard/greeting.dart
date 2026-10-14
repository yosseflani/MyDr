import 'package:mydr/core/l10n/strings.dart';

/// Returns a Hebrew greeting that matches the hour of [time].
String greetingFor(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour < 12) return AppStrings.greetingMorning;
  if (hour >= 12 && hour < 17) return AppStrings.greetingNoon;
  if (hour >= 17 && hour < 22) return AppStrings.greetingEvening;
  return AppStrings.greetingNight;
}
