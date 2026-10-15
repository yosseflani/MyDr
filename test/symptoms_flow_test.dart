import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/app.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/mock/mock_data.dart';
import 'package:mydr/features/dashboard/widgets/emergency_card.dart';
import 'package:mydr/features/dashboard/widgets/quick_actions_row.dart';
import 'package:mydr/features/dashboard/widgets/recent_symptoms_card.dart';
import 'package:mydr/features/family/member_detail_screen.dart';
import 'package:mydr/features/family/widgets/member_card.dart';
import 'package:mydr/features/symptoms/widgets/member_symptoms_section.dart';
import 'package:mydr/features/symptoms/symptom_form_screen.dart';
import 'package:mydr/features/symptoms/symptom_track_screen.dart';
import 'package:mydr/features/symptoms/symptoms_screen.dart';
import 'package:mydr/features/symptoms/widgets/delete_symptom_dialog.dart';
import 'package:mydr/features/symptoms/widgets/symptom_card.dart';

import 'helpers/pump_app.dart';

/// The symptom journal in the real app widget, with the demo data the app
/// starts with, reached and left through the bottom navigation.
void main() {
  testWidgets('open the journal, filter it, and move between tabs', (
    tester,
  ) async {
    // A tap that lands on something covering the target fails the test.
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    tester.setScreenSize(const Size(400, 2400));
    await tester.pumpWidget(
      MyDrApp(dependencies: AppDependencies.withMockData(DateTime.now())),
    );
    await tester.pumpAndSettle();

    Future<void> openTab(String label) async {
      await tester.tap(
        find.descendant(
          of: find.byType(NavigationBar),
          matching: find.text(label),
        ),
      );
      await tester.pumpAndSettle();
    }

    Future<void> selectFilter(String label) async {
      await tester.tap(find.widgetWithText(ChoiceChip, label));
      await tester.pumpAndSettle();
    }

    bool isSelected(String label) => tester
        .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
        .selected;

    await openTab(AppStrings.tabSymptoms);
    expect(find.byType(SymptomsScreen), findsOneWidget);
    expect(find.text(AppStrings.symptomsTitle), findsOneWidget);
    // The demo data: three cough records for one child, two other records.
    expect(find.byType(SymptomCard), findsNWidgets(5));
    expect(find.text('שיעול'), findsNWidgets(3));

    await selectFilter('איתי');
    expect(find.byType(SymptomCard), findsNWidgets(3));

    // Home and another tab, then back: the filter is kept.
    await openTab(AppStrings.tabHome);
    expect(find.byType(EmergencyCard), findsOneWidget);
    expect(find.byType(SymptomCard), findsNothing);

    await openTab(AppStrings.tabAppointments);
    expect(find.text(AppStrings.appointmentsTitle), findsOneWidget);

    await openTab(AppStrings.tabSymptoms);
    expect(isSelected('איתי'), isTrue);
    expect(find.byType(SymptomCard), findsNWidgets(3));

    await selectFilter(AppStrings.filterAllFamily);
    expect(find.byType(SymptomCard), findsNWidgets(5));

    // The other tabs still work as before.
    await openTab(AppStrings.tabFamily);
    expect(find.text(AppStrings.familyTitle), findsOneWidget);
    await openTab(AppStrings.tabHome);
    expect(find.byType(EmergencyCard), findsOneWidget);
  });

  testWidgets('add a record, see it in the journal, edit it and delete it', (
    tester,
  ) async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    tester.setScreenSize(const Size(400, 2400));
    await tester.pumpWidget(
      MyDrApp(dependencies: AppDependencies.withMockData(DateTime.now())),
    );
    await tester.pumpAndSettle();

    final nameField = find.widgetWithText(
      TextFormField,
      AppStrings.symptomNameLabel,
    );
    final notesField = find.widgetWithText(
      TextFormField,
      AppStrings.symptomNotesLabel,
    );
    Finder severity(int level) => find.descendant(
      of: find.byType(SegmentedButton<int>),
      matching: find.text('$level'),
    );
    Future<void> tapAndSettle(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    // Into the journal, filtered on one child.
    await tapAndSettle(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(AppStrings.tabSymptoms),
      ),
    );
    await tapAndSettle(find.widgetWithText(ChoiceChip, 'נועה'));
    expect(find.byType(SymptomCard), findsOneWidget);

    // Add: the filtered child is already chosen.
    await tapAndSettle(find.text(AppStrings.actionLogSymptom));
    expect(find.byType(SymptomFormScreen), findsOneWidget);
    await tapAndSettle(find.widgetWithText(ChoiceChip, 'כאב גרון'));
    await tapAndSettle(severity(2));
    await tester.enterText(notesField, 'בעיקר בבוקר');
    await tapAndSettle(find.widgetWithText(FilledButton, AppStrings.save));

    // Back in the journal, still filtered, with the new record on top.
    expect(find.byType(SymptomFormScreen), findsNothing);
    expect(find.byType(SymptomCard), findsNWidgets(2));
    final card = find.widgetWithText(SymptomCard, 'כאב גרון');
    expect(
      find.descendant(of: card, matching: find.text('בעיקר בבוקר')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text(AppStrings.symptomSeverity(2, 5)),
      ),
      findsOneWidget,
    );

    // Edit the rating and notes.
    await tapAndSettle(card);
    expect(find.text(AppStrings.editSymptomTitle), findsOneWidget);
    expect(
      tester.widget<TextFormField>(nameField).controller!.text,
      'כאב גרון',
    );
    await tapAndSettle(severity(4));
    await tester.enterText(notesField, 'החמיר בערב');
    await tapAndSettle(find.widgetWithText(FilledButton, AppStrings.save));

    expect(
      find.descendant(of: card, matching: find.text('החמיר בערב')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: card,
        matching: find.text(AppStrings.symptomSeverity(4, 5)),
      ),
      findsOneWidget,
    );

    // Delete, after confirming.
    await tapAndSettle(card);
    await tapAndSettle(
      find.widgetWithText(OutlinedButton, AppStrings.deleteSymptom),
    );
    expect(find.byType(DeleteSymptomDialog), findsOneWidget);
    await tapAndSettle(
      find.descendant(
        of: find.byType(DeleteSymptomDialog),
        matching: find.text(AppStrings.deleteSymptom),
      ),
    );

    expect(find.byType(SymptomFormScreen), findsNothing);
    expect(find.widgetWithText(SymptomCard, 'כאב גרון'), findsNothing);
    expect(find.byType(SymptomCard), findsOneWidget);

    // The whole family again, and home.
    await tapAndSettle(
      find.widgetWithText(ChoiceChip, AppStrings.filterAllFamily),
    );
    expect(find.byType(SymptomCard), findsNWidgets(5));
    await tapAndSettle(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(AppStrings.tabHome),
      ),
    );
    expect(find.byType(EmergencyCard), findsOneWidget);
  });

  testWidgets('journal, track, follow-up record, back to the track, edit a '
      'record, back to the journal', (tester) async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    tester.setScreenSize(const Size(400, 2400));
    await tester.pumpWidget(
      MyDrApp(dependencies: AppDependencies.withMockData(DateTime.now())),
    );
    await tester.pumpAndSettle();

    Future<void> tapAndSettle(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Finder severity(int level) => find.descendant(
      of: find.byType(SegmentedButton<int>),
      matching: find.text('$level'),
    );
    final saveButton = find.widgetWithText(FilledButton, AppStrings.save);

    await tapAndSettle(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(AppStrings.tabSymptoms),
      ),
    );

    // The demo cough has three records; each of its cards links to them.
    final coughLinks = find.text(AppStrings.openSymptomTrack(3));
    expect(coughLinks, findsNWidgets(3));
    await tapAndSettle(coughLinks.first);

    expect(find.byType(SymptomTrackScreen), findsOneWidget);
    expect(find.text(AppStrings.symptomRecordCount(3)), findsOneWidget);
    expect(find.text('איתי'), findsOneWidget);

    // A follow-up record: member and name are already filled in.
    await tapAndSettle(find.text(AppStrings.addFollowUpRecord));
    expect(find.byType(SymptomFormScreen), findsOneWidget);
    await tapAndSettle(severity(1));
    await tapAndSettle(saveButton);

    expect(find.byType(SymptomTrackScreen), findsOneWidget);
    expect(find.text(AppStrings.symptomRecordCount(4)), findsOneWidget);

    // Edit the oldest record from the track, and come back to it.
    await tapAndSettle(find.text('בעיקר בלילה'));
    expect(find.text(AppStrings.editSymptomTitle), findsOneWidget);
    await tapAndSettle(severity(5));
    await tapAndSettle(saveButton);

    expect(find.byType(SymptomTrackScreen), findsOneWidget);
    final oldest = find.ancestor(
      of: find.text('בעיקר בלילה'),
      matching: find.byType(InkWell),
    );
    expect(
      find.descendant(
        of: oldest.first,
        matching: find.text(AppStrings.symptomSeverity(5, 5)),
      ),
      findsOneWidget,
    );

    // Back to the journal, which shows the same four records.
    await tapAndSettle(find.byType(BackButton));
    expect(find.byType(SymptomTrackScreen), findsNothing);
    expect(find.byType(SymptomsScreen), findsOneWidget);
    expect(find.text(AppStrings.openSymptomTrack(4)), findsNWidgets(4));
    expect(find.byType(SymptomCard), findsNWidgets(6));
  });

  testWidgets('home, family profile and journal stay in sync: log from home, '
      'log from a profile, then delete that family member', (tester) async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    tester.setScreenSize(const Size(400, 2400));
    await tester.pumpWidget(
      MyDrApp(dependencies: AppDependencies.withMockData(DateTime.now())),
    );
    await tester.pumpAndSettle();

    Future<void> tapAndSettle(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    Future<void> openTab(String label) => tapAndSettle(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );

    Future<void> fillAndSave(String suggestion, int severity) async {
      await tapAndSettle(find.widgetWithText(ChoiceChip, suggestion));
      await tapAndSettle(
        find.descendant(
          of: find.byType(SegmentedButton<int>),
          matching: find.text('$severity'),
        ),
      );
      await tapAndSettle(find.widgetWithText(FilledButton, AppStrings.save));
    }

    final homeCard = find.byType(RecentSymptomsCard);

    // Log from the home screen shortcut.
    await tapAndSettle(
      find.widgetWithText(QuickActionTile, AppStrings.actionLogSymptom),
    );
    expect(find.byType(SymptomFormScreen), findsOneWidget);
    await tapAndSettle(find.byType(DropdownButtonFormField<String>));
    await tapAndSettle(find.text('נועה').last);
    await fillAndSave('כאב גרון', 2);

    // Back home, the new record is the latest one.
    expect(find.byType(SymptomFormScreen), findsNothing);
    expect(
      find.descendant(of: homeCard, matching: find.text('כאב גרון')),
      findsOneWidget,
    );

    // "Show all" switches to the Symptoms tab.
    await tapAndSettle(find.text(AppStrings.showAllSymptoms));
    expect(
      tester.widget<NavigationBar>(find.byType(NavigationBar)).selectedIndex,
      3,
    );
    expect(find.widgetWithText(SymptomCard, 'כאב גרון'), findsOneWidget);

    // The profile shows it too, and logs for that member.
    await openTab(AppStrings.tabFamily);
    await tapAndSettle(find.widgetWithText(MemberCard, 'נועה'));
    expect(find.byType(MemberDetailScreen), findsOneWidget);
    final section = find.byType(MemberSymptomsSection);
    expect(
      find.descendant(
        of: section,
        matching: find.text(AppStrings.symptomRecordCount(2)),
      ),
      findsOneWidget,
    );

    await tapAndSettle(
      find.descendant(
        of: section,
        matching: find.text(AppStrings.actionLogSymptom),
      ),
    );
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .initialValue,
      MockData.daughterId,
    );
    await fillAndSave('בחילה', 1);

    expect(find.byType(MemberDetailScreen), findsOneWidget);
    expect(
      find.descendant(
        of: section,
        matching: find.text(AppStrings.symptomRecordCount(3)),
      ),
      findsOneWidget,
    );

    // Delete her profile: her records disappear everywhere.
    await tapAndSettle(find.text(AppStrings.deleteProfile));
    await tapAndSettle(find.widgetWithText(FilledButton, AppStrings.delete));
    expect(find.byType(MemberDetailScreen), findsNothing);

    await openTab(AppStrings.tabHome);
    expect(
      find.descendant(of: homeCard, matching: find.text('כאב גרון')),
      findsNothing,
    );
    expect(
      find.descendant(of: homeCard, matching: find.text('בחילה')),
      findsNothing,
    );
    expect(
      find.descendant(of: homeCard, matching: find.textContaining('נועה')),
      findsNothing,
    );

    await openTab(AppStrings.tabSymptoms);
    expect(find.widgetWithText(ChoiceChip, 'נועה'), findsNothing);
    expect(find.text('כאב גרון'), findsNothing);
    expect(find.text('חום'), findsNothing);
    expect(find.byType(SymptomCard), findsNWidgets(4));
  });
}
