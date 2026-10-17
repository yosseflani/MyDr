import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_repository.dart';
import 'package:mydr/data/repositories/medication_repository.dart';

class InMemoryMedicationRepository extends InMemoryRepository<Medication>
    implements MedicationRepository {
  InMemoryMedicationRepository([Iterable<Medication> initialItems = const []])
    : super(
        idPrefix: 'medication',
        idOf: (medication) => medication.id,
        initialItems: initialItems,
      );

  @override
  Future<List<Medication>> getAll({String? memberId}) async {
    final items =
        storedItems
            .where((m) => memberId == null || m.memberId == memberId)
            .toList()
          ..sort((a, b) {
            final byName = a.name.compareTo(b.name);
            return byName != 0 ? byName : a.id.compareTo(b.id);
          });
    return List.unmodifiable(items);
  }

  @override
  Future<void> update(Medication item) async {
    final stored = await getById(item.id);
    if (stored == null) {
      throw StateError('Item with id "${item.id}" does not exist');
    }
    await super.update(
      stored.copyWith(
        name: item.name,
        dose: item.dose,
        instructions: () => item.instructions,
        reminderTimes: item.reminderTimes,
        startDate: item.startDate,
        endDate: () => item.endDate,
      ),
    );
  }

  @override
  Future<void> deleteByMember(String memberId) async {
    removeWhere((m) => m.memberId == memberId);
  }
}
