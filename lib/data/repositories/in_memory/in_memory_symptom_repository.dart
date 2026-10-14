import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_repository.dart';
import 'package:mydr/data/repositories/symptom_repository.dart';

class InMemorySymptomRepository extends InMemoryRepository<SymptomEntry>
    implements SymptomRepository {
  InMemorySymptomRepository([Iterable<SymptomEntry> initialEntries = const []])
    : super(
        idPrefix: 'symptom',
        idOf: (entry) => entry.id,
        initialItems: initialEntries,
      );

  @override
  Future<List<SymptomEntry>> getAll({String? memberId}) async {
    final entries =
        storedItems
            .where((e) => memberId == null || e.memberId == memberId)
            .toList()
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return List.unmodifiable(entries);
  }

  @override
  Future<void> deleteByMember(String memberId) async {
    removeWhere((e) => e.memberId == memberId);
  }
}
