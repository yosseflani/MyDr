import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/repositories/appointment_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_repository.dart';

class InMemoryAppointmentRepository extends InMemoryRepository<Appointment>
    implements AppointmentRepository {
  InMemoryAppointmentRepository([
    Iterable<Appointment> initialAppointments = const [],
  ]) : super(
         idPrefix: 'appointment',
         idOf: (appointment) => appointment.id,
         initialItems: initialAppointments,
       );

  @override
  Future<List<Appointment>> getAll({String? memberId}) async {
    final appointments =
        storedItems
            .where((a) => memberId == null || a.memberId == memberId)
            .toList()
          ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
    return List.unmodifiable(appointments);
  }

  @override
  Future<void> deleteByMember(String memberId) async {
    removeWhere((a) => a.memberId == memberId);
  }
}
