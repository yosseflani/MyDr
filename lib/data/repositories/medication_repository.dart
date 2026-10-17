import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/repositories/crud_repository.dart';

abstract interface class MedicationRepository
    implements CrudRepository<Medication> {
  /// Medications ordered by name, optionally filtered to one family member.
  Future<List<Medication>> getAll({String? memberId});

  /// Saves everything except the family member, which never changes once
  /// a medication is added. Throws [StateError] if it does not exist.
  @override
  Future<void> update(Medication item);

  /// Deletes only the medication itself; callers delete its dose records
  /// first (see [DoseRecordRepository.deleteByMedication]).
  @override
  Future<void> delete(String id);

  /// Deletes all medications of a family member. Part of deleting a member,
  /// which requires explicit user confirmation.
  Future<void> deleteByMember(String memberId);
}
