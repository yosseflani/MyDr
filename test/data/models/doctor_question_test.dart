import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/models/doctor_question.dart';

void main() {
  final question = DoctorQuestion(
    id: 'q1',
    memberId: 'm1',
    appointmentId: 'a1',
    text: 'מתי הביקורת הבאה?',
    createdAt: DateTime(2026, 10, 1),
  );

  test('is unresolved and has no answer by default', () {
    expect(question.isResolved, isFalse);
    expect(question.doctorAnswer, isNull);
  });

  test('can be marked as resolved with an answer', () {
    final resolved = question.copyWith(
      isResolved: true,
      doctorAnswer: () => 'בעוד חצי שנה',
    );
    expect(resolved.isResolved, isTrue);
    expect(resolved.doctorAnswer, 'בעוד חצי שנה');
    expect(resolved.text, question.text);
    expect(resolved.createdAt, question.createdAt);
  });

  test('can be detached from its appointment', () {
    final detached = question.copyWith(appointmentId: () => null);
    expect(detached.appointmentId, isNull);
    expect(detached.memberId, question.memberId);
  });

  test('uses value equality', () {
    expect(question.copyWith(), question);
    expect(question.copyWith().hashCode, question.hashCode);
    expect(question.copyWith(isResolved: true), isNot(question));
  });

  test('toString does not expose the question text', () {
    expect(question.toString(), 'DoctorQuestion(id: q1)');
  });
}
