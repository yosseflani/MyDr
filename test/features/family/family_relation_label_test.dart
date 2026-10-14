import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/features/family/family_relation_label.dart';

void main() {
  test('every relation has its own non-empty label', () {
    final labels = FamilyRelation.values.map((r) => r.label).toList();

    expect(labels, everyElement(isNotEmpty));
    expect(labels.toSet(), hasLength(FamilyRelation.values.length));
  });
}
