/// A question or topic the user wants to raise with a doctor.
///
/// It always belongs to a family member, and may optionally be linked to a
/// specific appointment.
class DoctorQuestion {
  const DoctorQuestion({
    required this.id,
    required this.memberId,
    required this.text,
    required this.createdAt,
    this.appointmentId,
    this.isResolved = false,
    this.doctorAnswer,
  });

  final String id;

  /// Id of the [FamilyMember] this question is about.
  final String memberId;

  /// Id of the [Appointment] it is planned for, or null if not assigned yet.
  final String? appointmentId;
  final String text;
  final DateTime createdAt;
  final bool isResolved;

  /// The doctor's answer as recorded by the user.
  final String? doctorAnswer;

  /// Nullable fields take a function so they can be cleared:
  /// `copyWith(appointmentId: () => null)`.
  DoctorQuestion copyWith({
    String? memberId,
    String? Function()? appointmentId,
    String? text,
    bool? isResolved,
    String? Function()? doctorAnswer,
  }) {
    return DoctorQuestion(
      id: id,
      memberId: memberId ?? this.memberId,
      appointmentId: appointmentId != null
          ? appointmentId()
          : this.appointmentId,
      text: text ?? this.text,
      createdAt: createdAt,
      isResolved: isResolved ?? this.isResolved,
      doctorAnswer: doctorAnswer != null ? doctorAnswer() : this.doctorAnswer,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DoctorQuestion &&
      other.id == id &&
      other.memberId == memberId &&
      other.appointmentId == appointmentId &&
      other.text == text &&
      other.createdAt == createdAt &&
      other.isResolved == isResolved &&
      other.doctorAnswer == doctorAnswer;

  @override
  int get hashCode => Object.hash(
    id,
    memberId,
    appointmentId,
    text,
    createdAt,
    isResolved,
    doctorAnswer,
  );

  /// Shows only the id so medical details never end up in logs.
  @override
  String toString() => 'DoctorQuestion(id: $id)';
}
