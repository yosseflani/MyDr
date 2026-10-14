import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_doctor_question_repository.dart';

void main() {
  DoctorQuestion question(
    String id,
    String memberId,
    String? appointmentId,
    int day,
  ) => DoctorQuestion(
    id: id,
    memberId: memberId,
    appointmentId: appointmentId,
    text: 'שאלה $id',
    createdAt: DateTime(2026, 10, day),
  );

  late InMemoryDoctorQuestionRepository repository;

  setUp(() {
    repository = InMemoryDoctorQuestionRepository([
      question('q1', 'm1', 'a1', 3),
      question('q2', 'm1', null, 1),
      question('q3', 'm2', 'a2', 2),
      question('q4', 'm1', 'a1', 4),
    ]);
  });

  Future<List<String>> ids({String? memberId, String? appointmentId}) async {
    final questions = await repository.getAll(
      memberId: memberId,
      appointmentId: appointmentId,
    );
    return questions.map((q) => q.id).toList();
  }

  test('getAll orders by creation time, oldest first', () async {
    expect(await ids(), ['q2', 'q3', 'q1', 'q4']);
  });

  test('getAll filters by member and by appointment', () async {
    expect(await ids(memberId: 'm1'), ['q2', 'q1', 'q4']);
    expect(await ids(appointmentId: 'a1'), ['q1', 'q4']);
    expect(await ids(memberId: 'm2', appointmentId: 'a1'), isEmpty);
  });

  test('detachFromAppointment keeps the questions without the link', () async {
    await repository.detachFromAppointment('a1');

    expect(await ids(appointmentId: 'a1'), isEmpty);
    expect(await ids(memberId: 'm1'), ['q2', 'q1', 'q4']);
    expect((await repository.getById('q1'))!.appointmentId, isNull);
    expect((await repository.getById('q3'))!.appointmentId, 'a2');
  });

  test('deleteByMember removes only that member\'s questions', () async {
    await repository.deleteByMember('m1');
    expect(await ids(), ['q3']);
  });
}
