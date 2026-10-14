import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/models/family_member.dart';

void main() {
  FamilyMember buildMember({
    DateTime? birthDate,
    List<String> allergies = const ['א'],
    String? notes = 'הערה',
  }) {
    return FamilyMember(
      id: 'm1',
      name: 'דנה',
      relation: FamilyRelation.self,
      birthDate: birthDate ?? DateTime(1990, 5, 15),
      allergies: allergies,
      notes: notes,
    );
  }

  test('stores birth date without a time component', () {
    final member = buildMember(birthDate: DateTime(1990, 5, 15, 13, 45));
    expect(member.birthDate, DateTime(1990, 5, 15));
  });

  test('lists cannot be modified, even through the source list', () {
    final source = ['א'];
    final member = buildMember(allergies: source);

    source.add('ב');
    expect(member.allergies, ['א']);
    expect(() => member.allergies.add('ג'), throwsUnsupportedError);
    expect(() => member.chronicConditions.add('ג'), throwsUnsupportedError);
  });

  group('ageOn', () {
    final member = buildMember(birthDate: DateTime(1990, 5, 15));

    test('counts full years only', () {
      expect(member.ageOn(DateTime(2020, 5, 14)), 29);
      expect(member.ageOn(DateTime(2020, 5, 15)), 30);
      expect(member.ageOn(DateTime(2020, 12, 1)), 30);
    });

    test('returns null when the birth date is unknown', () {
      final noBirthDate = member.copyWith(birthDate: () => null);
      expect(noBirthDate.ageOn(DateTime(2020)), isNull);
    });
  });

  group('copyWith', () {
    final member = buildMember();

    test('changes only the given fields', () {
      final updated = member.copyWith(name: 'אבי');
      expect(updated.name, 'אבי');
      expect(updated.id, member.id);
      expect(updated.relation, member.relation);
      expect(updated.birthDate, member.birthDate);
      expect(updated.allergies, member.allergies);
      expect(updated.notes, member.notes);
    });

    test('keeps nullable fields when omitted and clears them on request', () {
      expect(member.copyWith().notes, 'הערה');
      expect(member.copyWith(notes: () => null).notes, isNull);
    });
  });

  test('uses value equality, including list contents', () {
    expect(buildMember(), buildMember());
    expect(buildMember().hashCode, buildMember().hashCode);
    expect(buildMember(), isNot(buildMember(allergies: ['ב'])));
  });

  test('toString does not expose personal details', () {
    final text = buildMember().toString();
    expect(text, 'FamilyMember(id: m1)');
  });
}
