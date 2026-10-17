import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/mock/mock_data.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);
  final members = MockData.members();
  final appointments = MockData.appointments(now);
  final questions = MockData.questions(now);
  final symptoms = MockData.symptoms(now);
  final medications = MockData.medications(now);
  final doseRecords = MockData.doseRecords(now);

  test('ids are unique within each collection', () {
    for (final ids in [
      members.map((m) => m.id),
      appointments.map((a) => a.id),
      questions.map((q) => q.id),
      symptoms.map((s) => s.id),
      medications.map((m) => m.id),
      doseRecords.map((r) => r.id),
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
    final medicationsById = {for (final m in medications) m.id: m};
    for (final m in medications) {
      expect(memberIds, contains(m.memberId));
    }
    for (final r in doseRecords) {
      // A record belongs to its medication's member, at a scheduled dose.
      final medication = medicationsById[r.medicationId]!;
      expect(r.memberId, medication.memberId);
      expect(medication.isScheduledAt(r.scheduledAt), isTrue);
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

  test('one symptom is recorded several times, to show its progress', () {
    final counts = <String, int>{};
    for (final s in symptoms) {
      final key = '${s.memberId}/${s.name}';
      counts[key] = (counts[key] ?? 0) + 1;
    }
    expect(counts.values.any((count) => count >= 2), isTrue);
  });

  test('symptom dates are in the past', () {
    for (final s in symptoms) {
      expect(s.startedAt.isAfter(now), isFalse);
    }
  });
}
