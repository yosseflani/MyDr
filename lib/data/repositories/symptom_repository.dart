import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/data/repositories/crud_repository.dart';

abstract interface class SymptomRepository
    implements CrudRepository<SymptomEntry> {
  /// Entries ordered by start time, newest first, optionally filtered to
  /// one family member.
  Future<List<SymptomEntry>> getAll({String? memberId});

  /// Deletes all entries of a family member. Part of deleting a member,
  /// which requires explicit user confirmation.
  Future<void> deleteByMember(String memberId);
}
