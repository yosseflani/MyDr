import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/repositories/doctor_question_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_repository.dart';

class InMemoryDoctorQuestionRepository
    extends InMemoryRepository<DoctorQuestion>
    implements DoctorQuestionRepository {
  InMemoryDoctorQuestionRepository([
    Iterable<DoctorQuestion> initialQuestions = const [],
  ]) : super(
         idPrefix: 'question',
         idOf: (question) => question.id,
         initialItems: initialQuestions,
       );

  @override
  Future<List<DoctorQuestion>> getAll({
    String? memberId,
    String? appointmentId,
  }) async {
    final questions =
        storedItems
            .where((q) => memberId == null || q.memberId == memberId)
            .where(
              (q) => appointmentId == null || q.appointmentId == appointmentId,
            )
            .toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return List.unmodifiable(questions);
  }

  @override
  Future<void> detachFromAppointment(String appointmentId) async {
    replaceWhere(
      (q) => q.appointmentId == appointmentId,
      (q) => q.copyWith(appointmentId: () => null),
    );
  }

  @override
  Future<void> deleteByMember(String memberId) async {
    removeWhere((q) => q.memberId == memberId);
  }
}
