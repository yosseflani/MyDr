/// A medical appointment that belongs to one family member.
class Appointment {
  const Appointment({
    required this.id,
    required this.memberId,
    required this.doctorName,
    required this.dateTime,
    this.specialty,
    this.location,
    this.notes,
  });

  final String id;

  /// Id of the [FamilyMember] this appointment belongs to.
  final String memberId;
  final String doctorName;
  final DateTime dateTime;
  final String? specialty;
  final String? location;
  final String? notes;

  /// Whether the appointment is at or after [now].
  bool isUpcoming(DateTime now) => !dateTime.isBefore(now);

  /// Nullable fields take a function so they can be cleared:
  /// `copyWith(location: () => null)`.
  Appointment copyWith({
    String? memberId,
    String? doctorName,
    DateTime? dateTime,
    String? Function()? specialty,
    String? Function()? location,
    String? Function()? notes,
  }) {
    return Appointment(
      id: id,
      memberId: memberId ?? this.memberId,
      doctorName: doctorName ?? this.doctorName,
      dateTime: dateTime ?? this.dateTime,
      specialty: specialty != null ? specialty() : this.specialty,
      location: location != null ? location() : this.location,
      notes: notes != null ? notes() : this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Appointment &&
      other.id == id &&
      other.memberId == memberId &&
      other.doctorName == doctorName &&
      other.dateTime == dateTime &&
      other.specialty == specialty &&
      other.location == location &&
      other.notes == notes;

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    doctorName,
    dateTime,
    specialty,
    location,
    notes,
  );

  /// Shows only the id so medical details never end up in logs.
  @override
  String toString() => 'Appointment(id: $id)';
}
