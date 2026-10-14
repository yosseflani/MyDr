import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/features/dashboard/widgets/family_card.dart';
import 'package:mydr/features/family/family_controller.dart';

import '../../helpers/pump_app.dart';

void main() {
  late AppDependencies dependencies;
  late FamilyController controller;

  setUp(() {
    dependencies = AppDependencies.empty();
    controller = FamilyController(dependencies);
  });

  tearDown(() => controller.dispose());

  testWidgets('shows the empty state when there are no members', (
    tester,
  ) async {
    await controller.load();
    await tester.pumpApp(
      const FamilyCard(),
      dependencies: dependencies,
      familyController: controller,
    );

    expect(find.text(AppStrings.familyCardEmpty), findsOneWidget);
    expect(find.text(AppStrings.familyCardEmptyHint), findsOneWidget);
    expect(find.text(AppStrings.comingSoonBadge), findsNothing);
  });

  testWidgets('shows the member count and names, and updates live', (
    tester,
  ) async {
    await controller.add(
      FamilyMember(id: 'm1', name: 'דנה', relation: FamilyRelation.self),
    );
    await tester.pumpApp(
      const FamilyCard(),
      dependencies: dependencies,
      familyController: controller,
    );

    expect(find.text(AppStrings.familyCardCount(1)), findsOneWidget);
    expect(find.text('דנה'), findsOneWidget);
    expect(find.text(AppStrings.familyCardManageHint), findsOneWidget);

    await controller.add(
      FamilyMember(id: 'm2', name: 'אבי', relation: FamilyRelation.spouse),
    );
    await tester.pump();

    expect(find.text(AppStrings.familyCardCount(2)), findsOneWidget);
    expect(find.text('דנה, אבי'), findsOneWidget);
  });
}
