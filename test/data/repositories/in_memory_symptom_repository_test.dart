import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_symptom_repository.dart';

void main() {
  SymptomEntry entry(String id, String memberId, int day) => SymptomEntry(
    id: id,
    memberId: memberId,
    name: 'תסמין $id',
    startedAt: DateTime(2026, 10, day),
    severity: 3,
  );

  late InMemorySymptomRepository repository;

  setUp(() {
    repository = InMemorySymptomRepository([
      entry('s1', 'm1', 1),
      entry('s2', 'm2', 5),
      entry('s3', 'm1', 3),
    ]);
  });

  test('getAll orders by start time, newest first', () async {
    final ids = (await repository.getAll()).map((e) => e.id);
    expect(ids, ['s2', 's3', 's1']);
  });

  test('getAll filters by member', () async {
    final ids = (await repository.getAll(memberId: 'm1')).map((e) => e.id);
    expect(ids, ['s3', 's1']);
  });

  test('update can mark an entry as resolved', () async {
    final original = await repository.getById('s1');
    await repository.update(original!.copyWith(status: SymptomStatus.resolved));

    expect((await repository.getById('s1'))!.isOngoing, isFalse);
  });

  test('deleteByMember removes only that member\'s entries', () async {
    await repository.deleteByMember('m1');

    final ids = (await repository.getAll()).map((e) => e.id);
    expect(ids, ['s2']);
  });
}
