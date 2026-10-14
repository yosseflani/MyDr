import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/crud_repository.dart';

abstract interface class FamilyRepository
    implements CrudRepository<FamilyMember> {
  /// All members, ordered by relation and then by name.
  Future<List<FamilyMember>> getAll();

  /// Deletes only the member itself.
  ///
  /// Callers must get explicit user confirmation first, and are responsible
  /// for also removing the member's appointments, questions and symptoms
  /// via the matching `deleteByMember` methods.
  @override
  Future<void> delete(String id);
}
