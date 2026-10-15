/// Emergency services the app can dial.
enum EmergencyService { medical, police, fire }

/// A national emergency phone number.
class EmergencyNumber {
  const EmergencyNumber({required this.service, required this.number});

  final EmergencyService service;
  final String number;
}

/// Official emergency numbers, per country.
///
/// Kept in code rather than loaded from a file: they are critical and must
/// show instantly, even if anything else fails to load. Only numbers checked
/// against an official source belong here.
abstract final class EmergencyNumbers {
  /// Israel, checked on 2026-10-15 against gov.il ("מוקדי חירום – משטרת
  /// ישראל": police 100, Magen David Adom 101; "טלפונים תחנות כיבוי": fire
  /// and rescue 102).
  static const List<EmergencyNumber> israel = [
    EmergencyNumber(service: EmergencyService.medical, number: '101'),
    EmergencyNumber(service: EmergencyService.police, number: '100'),
    EmergencyNumber(service: EmergencyService.fire, number: '102'),
  ];

  /// Magen David Adom: the main number for medical emergencies.
  static const EmergencyNumber medical = EmergencyNumber(
    service: EmergencyService.medical,
    number: '101',
  );
}
