/// A time of day at which a dose is due, on the local wall clock.
///
/// Stored without a time zone, like every other time in the app, so a dose
/// at 08:00 stays at 08:00 after a daylight-saving or time zone change.
class DoseTime implements Comparable<DoseTime> {
  DoseTime(this.hour, this.minute) {
    RangeError.checkValueInInterval(hour, 0, 23, 'hour');
    RangeError.checkValueInInterval(minute, 0, 59, 'minute');
  }

  /// Reads the stored form, 'HH:MM'. Throws a [FormatException] otherwise.
  factory DoseTime.parse(String text) {
    final match = _pattern.firstMatch(text);
    if (match == null) throw FormatException('Not a stored dose time');
    final hour = int.parse(match[1]!);
    final minute = int.parse(match[2]!);
    if (hour > 23 || minute > 59) {
      throw FormatException('Not a stored dose time');
    }
    return DoseTime(hour, minute);
  }

  static final RegExp _pattern = RegExp(r'^(\d{2}):(\d{2})$');

  final int hour;
  final int minute;

  int get minutesOfDay => hour * 60 + minute;

  /// This time on [day]'s date, in local time.
  DateTime on(DateTime day) =>
      DateTime(day.year, day.month, day.day, hour, minute);

  /// The stored form, 'HH:MM'.
  String format() =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  @override
  int compareTo(DoseTime other) => minutesOfDay.compareTo(other.minutesOfDay);

  @override
  bool operator ==(Object other) =>
      other is DoseTime && other.hour == hour && other.minute == minute;

  @override
  int get hashCode => minutesOfDay;

  @override
  String toString() => 'DoseTime(${format()})';
}

/// A medication a family member takes, as entered by the user, with the
/// daily times they want to be reminded at.
///
/// The app stores exactly what the user entered. It never suggests a
/// medication or a dose and never changes a treatment.
class Medication {
  Medication({
    required this.id,
    required this.memberId,
    required this.name,
    required this.dose,
    this.instructions,
    required List<DoseTime> reminderTimes,
    required DateTime startDate,
    DateTime? endDate,
  }) : reminderTimes = List.unmodifiable(({...reminderTimes}.toList())..sort()),
       startDate = _dateOnly(startDate),
       endDate = endDate == null ? null : _dateOnly(endDate);

  /// More times than this a day are refused.
  static const int maxReminderTimes = 8;

  final String id;

  /// Id of the [FamilyMember] who takes it. Fixed once added.
  final String memberId;
  final String name;

  /// The dose as the user wrote it, e.g. "1 tablet". Never interpreted.
  final String dose;

  /// Optional, as the user wrote it, e.g. "after a meal".
  final String? instructions;

  /// Daily times, ascending and each once.
  final List<DoseTime> reminderTimes;

  /// First day of the treatment; date only.
  final DateTime startDate;

  /// Last day of the treatment (inclusive), or null when it has no planned
  /// end; date only.
  final DateTime? endDate;

  /// Whether [day] (any time on it) is within the treatment dates.
  bool isActiveOn(DateTime day) {
    final date = _dateOnly(day);
    final end = endDate;
    return !date.isBefore(startDate) && (end == null || !date.isAfter(end));
  }

  /// Whether the treatment ended before [day].
  bool hasEndedBefore(DateTime day) {
    final end = endDate;
    return end != null && _dateOnly(day).isAfter(end);
  }

  /// Whether the treatment starts after [day].
  bool startsAfter(DateTime day) => startDate.isAfter(_dateOnly(day));

  /// The scheduled doses on [day], earliest first; none outside the
  /// treatment dates.
  List<DateTime> doseTimesOn(DateTime day) => isActiveOn(day)
      ? [for (final time in reminderTimes) time.on(day)]
      : const [];

  /// Whether a dose is scheduled at exactly [moment].
  bool isScheduledAt(DateTime moment) =>
      moment.second == 0 &&
      moment.millisecond == 0 &&
      moment.microsecond == 0 &&
      isActiveOn(moment) &&
      reminderTimes.contains(DoseTime(moment.hour, moment.minute));

  /// The family member never changes. Nullable fields take a function so
  /// they can be cleared: `copyWith(endDate: () => null)`.
  Medication copyWith({
    String? name,
    String? dose,
    String? Function()? instructions,
    List<DoseTime>? reminderTimes,
    DateTime? startDate,
    DateTime? Function()? endDate,
  }) {
    return Medication(
      id: id,
      memberId: memberId,
      name: name ?? this.name,
      dose: dose ?? this.dose,
      instructions: instructions != null ? instructions() : this.instructions,
      reminderTimes: reminderTimes ?? this.reminderTimes,
      startDate: startDate ?? this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Medication &&
      other.id == id &&
      other.memberId == memberId &&
      other.name == name &&
      other.dose == dose &&
      other.instructions == instructions &&
      _listEquals(other.reminderTimes, reminderTimes) &&
      other.startDate == startDate &&
      other.endDate == endDate;

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    name,
    dose,
    instructions,
    Object.hashAll(reminderTimes),
    startDate,
    endDate,
  );

  /// Shows only the id so medical details never end up in logs.
  @override
  String toString() => 'Medication(id: $id)';
}

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
