import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/mock/mock_data.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);
  final members = MockData.members();
  final appointments = MockData.appointments(now);
  final questions = MockData.questions(now);
  final symptoms = MockData.symptoms(now);

  test('ids are unique within each collection', () {
    for (final ids in [
      members.map((m) => m.id),
      appointments.map((a) => a.id),
      questions.map((q) => q.id),
      symptoms.map((s) => s.id),
    ]) {
      expect(ids.toSet(), hasLength(ids.length));
    }
  });

  test('every reference points to an existing item', () {
    final memberIds = members.map((m) => m.id).toSet();
    final appointmentsById = {for (final a in appointments) a.id: a};

    for (final a in appointments) {
      expect(memberIds, contains(a.memberId));
    }
    for (final s in symptoms) {
      expect(memberIds, contains(s.memberId));
    }
    for (final q in questions) {
      expect(memberIds, contains(q.memberId));
      final appointmentId = q.appointmentId;
      if (appointmentId != null) {
        // A linked question must belong to the same member as its appointment.
        expect(appointmentsById[appointmentId]?.memberId, q.memberId);
      }
    }
  });

  test('includes both upcoming and past appointments', () {
    expect(appointments.where((a) => a.isUpcoming(now)), isNotEmpty);
    expect(appointments.where((a) => !a.isUpcoming(now)), isNotEmpty);
  });

  test('includes both ongoing and resolved symptoms', () {
    expect(symptoms.where((s) => s.isOngoing), isNotEmpty);
    expect(symptoms.where((s) => !s.isOngoing), isNotEmpty);
  });
}
