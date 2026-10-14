/// How a family member is related to the app user.
///
/// Hebrew labels belong to the UI layer, not to the model.
enum FamilyRelation { self, spouse, child, parent, sibling, grandparent, other }

/// Profile of a single family member.
class FamilyMember {
  FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    DateTime? birthDate,
    List<String> allergies = const [],
    List<String> chronicConditions = const [],
    this.notes,
  }) : birthDate = birthDate == null
           ? null
           : DateTime(birthDate.year, birthDate.month, birthDate.day),
       allergies = List.unmodifiable(allergies),
       chronicConditions = List.unmodifiable(chronicConditions);

  final String id;
  final String name;
  final FamilyRelation relation;

  /// Date only; any time component is dropped.
  final DateTime? birthDate;
  final List<String> allergies;
  final List<String> chronicConditions;
  final String? notes;

  /// Age in full years on [date], or null if the birth date is unknown.
  int? ageOn(DateTime date) {
    final birth = birthDate;
    if (birth == null) return null;

    var age = date.year - birth.year;
    final hadBirthdayThisYear =
        date.month > birth.month ||
        (date.month == birth.month && date.day >= birth.day);
    if (!hadBirthdayThisYear) age--;
    return age;
  }

  /// Nullable fields take a function so they can be cleared:
  /// `copyWith(notes: () => null)`.
  FamilyMember copyWith({
    String? name,
    FamilyRelation? relation,
    DateTime? Function()? birthDate,
    List<String>? allergies,
    List<String>? chronicConditions,
    String? Function()? notes,
  }) {
    return FamilyMember(
      id: id,
      name: name ?? this.name,
      relation: relation ?? this.relation,
      birthDate: birthDate != null ? birthDate() : this.birthDate,
      allergies: allergies ?? this.allergies,
      chronicConditions: chronicConditions ?? this.chronicConditions,
      notes: notes != null ? notes() : this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is FamilyMember &&
      other.id == id &&
      other.name == name &&
      other.relation == relation &&
      other.birthDate == birthDate &&
      _listEquals(other.allergies, allergies) &&
      _listEquals(other.chronicConditions, chronicConditions) &&
      other.notes == notes;

  @override
  int get hashCode => Object.hash(
    id,
    name,
    relation,
    birthDate,
    Object.hashAll(allergies),
    Object.hashAll(chronicConditions),
    notes,
  );

  /// Shows only the id so medical details never end up in logs.
  @override
  String toString() => 'FamilyMember(id: $id)';
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
