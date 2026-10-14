import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/features/family/family_relation_label.dart';

/// "Relation · age" line shared by the member card and the profile header.
/// The age is left out when the birth date is unknown.
String memberSummaryLine(FamilyMember member, DateTime today) {
  final age = member.ageOn(today);
  return [
    member.relation.label,
    if (age != null)
      age == 0 ? AppStrings.ageUnderOneYear : AppStrings.ageInYears(age),
  ].join(' · ');
}
