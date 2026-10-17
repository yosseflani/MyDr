import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/app.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/mock/mock_data.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/features/family/member_detail_screen.dart';
import 'package:mydr/features/family/widgets/delete_member_dialog.dart';
import 'package:mydr/features/medications/medication_form_screen.dart';
import 'package:mydr/features/medications/medications_screen.dart';
import 'package:mydr/features/medications/widgets/dose_tile.dart';
import 'package:mydr/features/medications/widgets/medication_card.dart';

import 'helpers/fake_reminder_scheduler.dart';
import 'helpers/pump_app.dart';

/// Medications in the real app widget, reached through the bottom
/// navigation, on the real clock.
void main() {
  final self = FamilyMember(
    id: 'mA',
    name: 'דנה',
    relation: FamilyRelation.self,
  );
  final child = FamilyMember(
    id: 'mB',
    name: 'נועה',
    relation: FamilyRelation.child,
  );

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('add a medication, record a dose, restart, and delete the '
      'member', (tester) async {
    // A tap that lands on something covering the target fails the test.
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    tester.setScreenSize(const Size(400, 2400));

    final scheduler = FakeReminderScheduler();
    final dependencies = AppDependencies.empty(reminderScheduler: scheduler);
    await dependencies.familyRepository.add(self);
    await dependencies.familyRepository.add(child);

    await tester.pumpWidget(MyDrApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await openTab(tester, AppStrings.tabMedications);
    expect(find.byType(MedicationsScreen), findsOneWidget);
    expect(
      find.text(AppStrings.medicationsEmptyForMember(self.name)),
      findsOneWidget,
    );

    // Add a medication for the selected member, starting today at 08:00.
    await tester.tap(find.text(AppStrings.actionAddMedication));
    await tester.pumpAndSettle();
    expect(find.byType(MedicationFormScreen), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.medicationNameLabel),
      'תרופת בדיקה',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.doseLabel),
      '1 tablet',
    );
    await tester.tap(find.text(AppStrings.addReminderTime));
    await tester.pumpAndSettle();
    final ok = MaterialLocalizations.of(
      tester.element(find.byType(MedicationFormScreen)),
    ).okButtonLabel;
    await tester.tap(find.text(ok));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.save));
    await tester.pumpAndSettle();

    expect(find.byType(MedicationFormScreen), findsNothing);
    expect(find.byType(MedicationCard), findsOneWidget);
    expect(find.byType(DoseTile), findsWidgets);
    expect(scheduler.replacements, isNotEmpty);

    // Today's 08:00 dose, marked as taken.
    final todayTile = find.byType(DoseTile).first;
    await tester.tap(
      find.descendant(
        of: todayTile,
        matching: find.text(AppStrings.markDoseTaken),
      ),
    );
    await tester.pumpAndSettle();
    expect(await dependencies.doseRecordRepository.getAll(), hasLength(1));

    // The other member sees none of it.
    await tester.tap(find.widgetWithText(ChoiceChip, child.name));
    await tester.pumpAndSettle();
    expect(find.byType(MedicationCard), findsNothing);
    expect(find.byType(DoseTile), findsNothing);

    // Returning to the foreground reschedules from the saved data.
    final before = scheduler.replacements.length;
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.inactive);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
    expect(scheduler.replacements.length, greaterThan(before));

    // A restart reads everything back; the dose is still recorded, once
    // (example D).
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(MyDrApp(dependencies: dependencies));
    await tester.pumpAndSettle();
    await openTab(tester, AppStrings.tabMedications);
    expect(
      find.descendant(
        of: find.byType(DoseTile).first,
        matching: find.text(AppStrings.doseTaken),
      ),
      findsOneWidget,
    );
    expect(await dependencies.doseRecordRepository.getAll(), hasLength(1));

    // Deleting the member removes their medication, records and reminders
    // (example B).
    await openTab(tester, AppStrings.tabFamily);
    await tester.tap(find.text(self.name).first);
    await tester.pumpAndSettle();
    expect(find.byType(MemberDetailScreen), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text(AppStrings.deleteProfile),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(AppStrings.deleteProfile));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.deleteItemMedications), findsOneWidget);
    expect(find.text(AppStrings.deleteItemDoseRecords), findsOneWidget);
    await tester.tap(
      find.descendant(
        of: find.byType(DeleteMemberDialog),
        matching: find.text(AppStrings.delete),
      ),
    );
    await tester.pumpAndSettle();

    expect(await dependencies.medicationRepository.getAll(), isEmpty);
    expect(await dependencies.doseRecordRepository.getAll(), isEmpty);
    expect(scheduler.scheduled, isEmpty);
    expect(await dependencies.familyRepository.getById(child.id), child);
  });

  testWidgets('the demo data shows each member their own medications', (
    tester,
  ) async {
    tester.setScreenSize(const Size(400, 2400));
    await tester.pumpWidget(
      MyDrApp(dependencies: AppDependencies.withMockData(DateTime.now())),
    );
    await tester.pumpAndSettle();
    await openTab(tester, AppStrings.tabMedications);

    final names = {
      for (final m in MockData.medications(DateTime.now())) m.memberId: m.name,
    };
    // Starts on the "self" profile.
    expect(find.text(names[MockData.selfId]!), findsOneWidget);
    expect(find.textContaining(names[MockData.sonId]!), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, 'איתי'));
    await tester.pumpAndSettle();
    expect(find.textContaining(names[MockData.sonId]!), findsWidgets);
    expect(find.textContaining(names[MockData.selfId]!), findsNothing);
  });
}
