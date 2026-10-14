import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/repositories/crud_repository.dart';

abstract interface class AppointmentRepository
    implements CrudRepository<Appointment> {
  /// Appointments ordered by date, earliest first, optionally filtered to
  /// one family member.
  Future<List<Appointment>> getAll({String? memberId});

  /// Deletes all appointments of a family member. Part of deleting a member,
  /// which requires explicit user confirmation.
  Future<void> deleteByMember(String memberId);
}
