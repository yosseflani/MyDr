import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/repositories/crud_repository.dart';

abstract interface class DoctorQuestionRepository
    implements CrudRepository<DoctorQuestion> {
  /// Questions ordered by creation time, oldest first, optionally filtered
  /// by family member and/or appointment.
  Future<List<DoctorQuestion>> getAll({
    String? memberId,
    String? appointmentId,
  });

  /// Unlinks all questions from a deleted appointment, keeping them as
  /// general questions for the same family member.
  Future<void> detachFromAppointment(String appointmentId);

  /// Deletes all questions of a family member. Part of deleting a member,
  /// which requires explicit user confirmation.
  Future<void> deleteByMember(String memberId);
}
