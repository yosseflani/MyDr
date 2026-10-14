import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/app.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/features/family/member_detail_screen.dart';
import 'package:mydr/features/family/member_form_screen.dart';
import 'package:mydr/features/family/widgets/member_card.dart';

import 'helpers/pump_app.dart';

/// End-to-end walk through family management in the real app widget, with
/// the same demo data the app starts with.
void main() {
  testWidgets('add, view, edit and delete a family member', (tester) async {
    // A tap that lands on something covering the target (e.g. a snack bar
    // over a button) fails the test instead of only printing a warning.
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    tester.setScreenSize(const Size(400, 1600));
    await tester.pumpWidget(
      MyDrApp(dependencies: AppDependencies.withMockData(DateTime.now())),
    );
    await tester.pumpAndSettle();

    final nameField = find.widgetWithText(TextFormField, AppStrings.nameLabel);
    final saveButton = find.widgetWithText(FilledButton, AppStrings.save);

    // Home shows the demo family.
    expect(find.text(AppStrings.familyCardCount(5)), findsOneWidget);

    // Family tab lists the members, marked as demo data.
    await tester.tap(find.text(AppStrings.tabFamily));
    await tester.pumpAndSettle();
    expect(find.byType(MemberCard), findsNWidgets(5));
    expect(find.byType(DemoDataBanner), findsOneWidget);

    // Add.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.enterText(nameField, 'יעל');
    await tester.tap(find.byType(DropdownButtonFormField<FamilyRelation>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.relationSibling).last);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.byType(MemberFormScreen), findsNothing);
    expect(find.byType(MemberCard), findsNWidgets(6));

    // View.
    await tester.tap(find.widgetWithText(MemberCard, 'יעל'));
    await tester.pumpAndSettle();
    expect(find.byType(MemberDetailScreen), findsOneWidget);
    expect(find.text(AppStrings.relationSibling), findsOneWidget);

    // Edit.
    await tester.tap(find.byTooltip(AppStrings.edit));
    await tester.pumpAndSettle();
    await tester.enterText(nameField, 'יעל כ.');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.byType(MemberDetailScreen), findsOneWidget);
    expect(find.text('יעל כ.'), findsNWidgets(2));

    // Delete.
    await tester.tap(find.text(AppStrings.deleteProfile));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.delete));
    await tester.pumpAndSettle();
    expect(find.byType(MemberDetailScreen), findsNothing);
    expect(find.byType(MemberCard), findsNWidgets(5));
    expect(find.text(AppStrings.deleteSucceeded('יעל כ.')), findsOneWidget);

    // Home reflects the same shared data.
    await tester.tap(find.text(AppStrings.tabHome));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.familyCardCount(5)), findsOneWidget);
  });
}
