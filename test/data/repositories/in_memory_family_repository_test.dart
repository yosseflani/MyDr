import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_family_repository.dart';

void main() {
  FamilyMember member(String id, String name, FamilyRelation relation) =>
      FamilyMember(id: id, name: name, relation: relation);

  late InMemoryFamilyRepository repository;

  setUp(() {
    repository = InMemoryFamilyRepository([
      member('member-1', 'נועה', FamilyRelation.child),
      member('member-2', 'דנה', FamilyRelation.self),
    ]);
  });

  test('getAll orders by relation, then by name', () async {
    await repository.add(member('member-9', 'איתי', FamilyRelation.child));

    final names = (await repository.getAll()).map((m) => m.name);
    expect(names, ['דנה', 'איתי', 'נועה']);
  });

  test('getAll returns an unmodifiable list', () async {
    final members = await repository.getAll();
    expect(() => members.clear(), throwsUnsupportedError);
  });

  test('createId returns ids that are not taken', () {
    final first = repository.createId();
    final second = repository.createId();
    expect(first, isNot(anyOf('member-1', 'member-2')));
    expect(second, isNot(first));
  });

  test('add then getById returns the member', () async {
    final id = repository.createId();
    final added = member(id, 'אבי', FamilyRelation.spouse);

    await repository.add(added);
    expect(await repository.getById(id), added);
  });

  test('add rejects a duplicate id', () async {
    expect(
      () => repository.add(member('member-1', 'כפול', FamilyRelation.other)),
      throwsStateError,
    );
  });

  test('update replaces an existing member', () async {
    final original = await repository.getById('member-1');
    await repository.update(original!.copyWith(name: 'נועה ל.'));

    expect((await repository.getById('member-1'))!.name, 'נועה ל.');
  });

  test('update rejects an unknown member', () async {
    expect(
      () => repository.update(member('missing', 'x', FamilyRelation.other)),
      throwsStateError,
    );
  });

  test('delete removes the member and ignores unknown ids', () async {
    await repository.delete('member-1');
    await repository.delete('missing');

    expect(await repository.getById('member-1'), isNull);
    expect(await repository.getAll(), hasLength(1));
  });
}
