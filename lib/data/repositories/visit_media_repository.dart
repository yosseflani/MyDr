import 'package:mydr/data/models/visit_media.dart';
import 'package:mydr/data/repositories/crud_repository.dart';

abstract interface class VisitMediaRepository
    implements CrudRepository<VisitMedia> {
  /// Items ordered by when they were added, oldest first, optionally
  /// filtered by family member and/or appointment.
  Future<List<VisitMedia>> getAll({String? memberId, String? appointmentId});

  /// Saves the description only: the file, kind, appointment and member of
  /// an item never change once it is added. Throws [StateError] if the item
  /// does not exist.
  @override
  Future<void> update(VisitMedia item);

  /// Deletes the records (not the files) of an appointment. Part of
  /// deleting the appointment, which requires explicit user confirmation.
  Future<void> deleteByAppointment(String appointmentId);

  /// Deletes the records (not the files) of a family member. Part of
  /// deleting the member, which requires explicit user confirmation.
  Future<void> deleteByMember(String memberId);
}
