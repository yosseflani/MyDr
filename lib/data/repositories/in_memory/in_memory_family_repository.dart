import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/family_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_repository.dart';

class InMemoryFamilyRepository extends InMemoryRepository<FamilyMember>
    implements FamilyRepository {
  InMemoryFamilyRepository([Iterable<FamilyMember> initialMembers = const []])
    : super(
        idPrefix: 'member',
        idOf: (member) => member.id,
        initialItems: initialMembers,
      );

  @override
  Future<List<FamilyMember>> getAll() async {
    final members = storedItems.toList()
      ..sort((a, b) {
        final byRelation = a.relation.index.compareTo(b.relation.index);
        return byRelation != 0 ? byRelation : a.name.compareTo(b.name);
      });
    return List.unmodifiable(members);
  }
}
