import 'package:drift/drift.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/repositories/local_repository_support.dart';
import 'package:mydr/data/local/storage_codecs.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/family_repository.dart';

class LocalFamilyRepository extends LocalRepository
    implements FamilyRepository {
  LocalFamilyRepository(super.db);

  @override
  Future<List<FamilyMember>> getAll() => guard(() async {
    final rows = await db.select(db.familyMembers).get();
    final members = rows.map(_toModel).toList()
      // The same order as the in-memory repository: relation, then name.
      ..sort((a, b) {
        final byRelation = a.relation.index.compareTo(b.relation.index);
        if (byRelation != 0) return byRelation;
        final byName = a.name.compareTo(b.name);
        return byName != 0 ? byName : a.id.compareTo(b.id);
      });
    return List.unmodifiable(members);
  });

  @override
  Future<FamilyMember?> getById(String id) => guard(() async {
    final row = await (db.select(
      db.familyMembers,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  });

  @override
  Future<void> add(FamilyMember item) =>
      insertNew(db.familyMembers, item.id, _toRow(item));

  @override
  Future<void> update(FamilyMember item) => guard(() async {
    final rows = await (db.update(
      db.familyMembers,
    )..where((t) => t.id.equals(item.id))).write(_toRow(item));
    expectUpdated(rows, item.id);
  });

  /// Refused (a [LocalDataException]) while the member still has
  /// appointments, questions or symptom records: delete those first.
  @override
  Future<void> delete(String id) => guard(() async {
    await (db.delete(db.familyMembers)..where((t) => t.id.equals(id))).go();
  });

  static FamilyMembersCompanion _toRow(FamilyMember member) {
    final birthDate = member.birthDate;
    return FamilyMembersCompanion.insert(
      id: member.id,
      name: member.name,
      relation: member.relation.name,
      birthDate: Value(
        birthDate == null ? null : StorageCodecs.encodeDate(birthDate),
      ),
      allergies: Value(StorageCodecs.encodeStringList(member.allergies)),
      chronicConditions: Value(
        StorageCodecs.encodeStringList(member.chronicConditions),
      ),
      notes: Value(member.notes),
    );
  }

  static FamilyMember _toModel(FamilyMemberRow row) {
    final birthDate = row.birthDate;
    return FamilyMember(
      id: row.id,
      name: row.name,
      relation: FamilyRelation.values.byName(row.relation),
      birthDate: birthDate == null ? null : StorageCodecs.decodeDate(birthDate),
      allergies: StorageCodecs.decodeStringList(row.allergies),
      chronicConditions: StorageCodecs.decodeStringList(row.chronicConditions),
      notes: row.notes,
    );
  }
}
