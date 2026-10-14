import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/models/appointment.dart';

void main() {
  final appointment = Appointment(
    id: 'a1',
    memberId: 'm1',
    doctorName: 'ד״ר לוי',
    dateTime: DateTime(2026, 10, 20, 10),
    specialty: 'רפואת משפחה',
    location: 'מרפאה',
  );

  test('isUpcoming compares against the given time', () {
    expect(appointment.isUpcoming(DateTime(2026, 10, 19)), isTrue);
    expect(appointment.isUpcoming(DateTime(2026, 10, 20, 10)), isTrue);
    expect(appointment.isUpcoming(DateTime(2026, 10, 20, 11)), isFalse);
  });

  group('copyWith', () {
    test('changes only the given fields', () {
      final moved = appointment.copyWith(dateTime: DateTime(2026, 11, 1, 9));
      expect(moved.dateTime, DateTime(2026, 11, 1, 9));
      expect(moved.id, appointment.id);
      expect(moved.memberId, appointment.memberId);
      expect(moved.doctorName, appointment.doctorName);
      expect(moved.location, appointment.location);
    });

    test('can clear nullable fields', () {
      final cleared = appointment.copyWith(location: () => null);
      expect(cleared.location, isNull);
      expect(cleared.specialty, appointment.specialty);
    });
  });

  test('uses value equality', () {
    expect(appointment.copyWith(), appointment);
    expect(appointment.copyWith().hashCode, appointment.hashCode);
    expect(appointment.copyWith(doctorName: 'אחר'), isNot(appointment));
  });

  test('toString does not expose medical details', () {
    expect(appointment.toString(), 'Appointment(id: a1)');
  });
}
