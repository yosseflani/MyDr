import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/family_member.dart';

/// Hebrew display labels for [FamilyRelation], kept out of the model.
extension FamilyRelationLabel on FamilyRelation {
  String get label => switch (this) {
    FamilyRelation.self => AppStrings.relationSelf,
    FamilyRelation.spouse => AppStrings.relationSpouse,
    FamilyRelation.child => AppStrings.relationChild,
    FamilyRelation.parent => AppStrings.relationParent,
    FamilyRelation.sibling => AppStrings.relationSibling,
    FamilyRelation.grandparent => AppStrings.relationGrandparent,
    FamilyRelation.other => AppStrings.relationOther,
  };
}
