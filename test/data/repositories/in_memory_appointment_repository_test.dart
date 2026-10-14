import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_appointment_repository.dart';

void main() {
  Appointment appointment(String id, String memberId, DateTime dateTime) =>
      Appointment(
        id: id,
        memberId: memberId,
        doctorName: 'ד״ר בדיקה',
        dateTime: dateTime,
      );

  late InMemoryAppointmentRepository repository;

  setUp(() {
    repository = InMemoryAppointmentRepository([
      appointment('a1', 'm1', DateTime(2026, 12, 1)),
      appointment('a2', 'm2', DateTime(2026, 10, 1)),
      appointment('a3', 'm1', DateTime(2026, 11, 1)),
    ]);
  });

  test('getAll orders by date, earliest first', () async {
    final ids = (await repository.getAll()).map((a) => a.id);
    expect(ids, ['a2', 'a3', 'a1']);
  });

  test('getAll filters by member', () async {
    final ids = (await repository.getAll(memberId: 'm1')).map((a) => a.id);
    expect(ids, ['a3', 'a1']);
  });

  test('deleteByMember removes only that member\'s appointments', () async {
    await repository.deleteByMember('m1');

    final ids = (await repository.getAll()).map((a) => a.id);
    expect(ids, ['a2']);
  });
}
