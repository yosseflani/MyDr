import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/date_time_fields.dart';
import 'package:mydr/core/widgets/inline_error_message.dart';
import 'package:mydr/core/widgets/not_found_view.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/widgets/no_family_members_view.dart';
import 'package:mydr/features/symptoms/symptom_controller.dart';
import 'package:mydr/features/symptoms/symptom_form_screen.dart';
import 'package:mydr/features/symptoms/symptoms_screen.dart';
import 'package:mydr/features/symptoms/widgets/delete_symptom_dialog.dart';
import 'package:mydr/features/symptoms/widgets/symptom_card.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  late DateTime now;

  final members = [
    FamilyMember(id: 'm1', name: 'דנה', relation: FamilyRelation.self),
    FamilyMember(id: 'm2', name: 'נועה', relation: FamilyRelation.child),
    FamilyMember(id: 'm3', name: 'אבי', relation: FamilyRelation.spouse),
  ];

  final headache = SymptomEntry(
    id: 'e1',
    memberId: 'm1',
    name: 'כאב ראש',
    startedAt: DateTime(2026, 10, 15, 7, 30),
    severity: 2,
    status: SymptomStatus.resolved,
    duration: const Duration(hours: 3),
    notes: 'אחרי העבודה',
  );
  final fever = SymptomEntry(
    id: 'e2',
    memberId: 'm2',
    name: 'חום',
    startedAt: DateTime(2026, 10, 14, 20),
    severity: 4,
  );
  final oldInjury = SymptomEntry(
    id: 'e3',
    memberId: 'm3',
    name: 'כאב ברך',
    startedAt: DateTime(2019, 5, 1, 10),
    severity: 3,
  );

  late FlakyFamilyRepository familyRepository;
  late FlakySymptomRepository symptomRepository;
  late AppDependencies dependencies;
  late FamilyController familyController;
  late SymptomController symptomController;

  Future<void> setUpWith({
    List<FamilyMember>? familyMembers,
    List<SymptomEntry>? entries,
  }) async {
    now = DateTime(2026, 10, 15, 12);
    familyRepository = FlakyFamilyRepository(familyMembers ?? members);
    symptomRepository = FlakySymptomRepository(
      entries ?? [headache, fever, oldInjury],
    );
    dependencies = AppDependencies(
      familyRepository: familyRepository,
      appointmentRepository: FlakyAppointmentRepository(),
      doctorQuestionRepository: FlakyDoctorQuestionRepository(),
      symptomRepository: symptomRepository,
    );
    familyController = FamilyController(dependencies);
    symptomController = SymptomController(
      dependencies: dependencies,
      familyController: familyController,
      clock: () => now,
    );
    addTearDown(() {
      symptomController.dispose();
      familyController.dispose();
    });
    await familyController.load();
    await symptomController.load();
  }

  // Finders
  final memberDropdown = find.byType(DropdownButtonFormField<String>);
  final nameField = find.widgetWithText(
    TextFormField,
    AppStrings.symptomNameLabel,
  );
  final notesField = find.widgetWithText(
    TextFormField,
    AppStrings.symptomNotesLabel,
  );
  final saveButton = find.widgetWithText(FilledButton, AppStrings.save);
  final deleteButton = find.widgetWithText(
    OutlinedButton,
    AppStrings.deleteSymptom,
  );

  Finder severityButton(int level) => find.descendant(
    of: find.byType(SegmentedButton<int>),
    matching: find.text('$level'),
  );

  String textOf(WidgetTester tester, Finder field) =>
      tester.widget<TextFormField>(field).controller!.text;

  Future<void> pumpList(WidgetTester tester) {
    tester.setScreenSize(const Size(400, 2000));
    return tester.pumpApp(
      SymptomsScreen(clock: () => now),
      dependencies: dependencies,
      familyController: familyController,
      symptomController: symptomController,
    );
  }

  /// Opens the add form from the journal, filtered on [filter] if given.
  Future<void> openAddForm(WidgetTester tester, {String? filter}) async {
    await pumpList(tester);
    if (filter != null) {
      await tester.tap(find.widgetWithText(ChoiceChip, filter));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text(AppStrings.actionLogSymptom));
    await tester.pumpAndSettle();
  }

  Future<void> openEditForm(WidgetTester tester, String entryId) async {
    await pumpList(tester);
    await tester.tap(find.byKey(ValueKey(entryId)));
    await tester.pumpAndSettle();
  }

  Future<void> selectMember(WidgetTester tester, String name) async {
    await tester.tap(memberDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Future<void> selectSeverity(WidgetTester tester, int level) async {
    await tester.ensureVisible(severityButton(level));
    await tester.tap(severityButton(level));
    await tester.pumpAndSettle();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  }

  Future<void> pressBack(WidgetTester tester) async {
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
  }

  group('add', () {
    testWidgets('starts with now, the filtered member and no rating', (
      tester,
    ) async {
      await setUpWith();
      await openAddForm(tester, filter: 'נועה');

      expect(find.text(AppStrings.actionLogSymptom), findsWidgets);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(memberDropdown)
            .initialValue,
        'm2',
      );
      expect(
        tester
            .widget<DatePickerField>(find.byType(DatePickerField))
            .initialValue,
        DateTime(2026, 10, 15),
      );
      expect(
        tester
            .widget<TimePickerField>(find.byType(TimePickerField))
            .initialValue,
        const TimeOfDay(hour: 12, minute: 0),
      );
      final severity = tester.widget<SegmentedButton<int>>(
        find.byType(SegmentedButton<int>),
      );
      expect(severity.selected, isEmpty);
      expect(find.text(AppStrings.severityHint), findsOneWidget);
      expect(deleteButton, findsNothing);
    });

    testWidgets('without a filter, no member is chosen for the user', (
      tester,
    ) async {
      await setUpWith();
      await openAddForm(tester);

      expect(
        tester
            .widget<DropdownButtonFormField<String>>(memberDropdown)
            .initialValue,
        isNull,
      );
    });

    testWidgets('shows what is missing, and saves nothing', (tester) async {
      await setUpWith();
      await openAddForm(tester);

      await tapSave(tester);

      expect(find.text(AppStrings.memberRequired), findsOneWidget);
      expect(find.text(AppStrings.symptomNameRequired), findsOneWidget);
      expect(find.text(AppStrings.severityRequired), findsOneWidget);
      expect(find.byType(SymptomFormScreen), findsOneWidget);
      expect(symptomController.entries, hasLength(3));
    });

    testWidgets('a name of spaces only is not accepted', (tester) async {
      await setUpWith();
      await openAddForm(tester, filter: 'דנה');
      await tester.enterText(nameField, '   ');
      await selectSeverity(tester, 2);

      await tapSave(tester);

      expect(find.text(AppStrings.symptomNameRequired), findsOneWidget);
    });

    testWidgets("suggests the member's own names first, then common ones", (
      tester,
    ) async {
      await setUpWith();
      await openAddForm(tester, filter: 'נועה');

      final chips = tester
          .widgetList<ChoiceChip>(
            find.descendant(
              of: find.byType(SymptomFormScreen),
              matching: find.byType(ChoiceChip),
            ),
          )
          .map((chip) => (chip.label as Text).data)
          .toList();
      expect(chips.first, 'חום');
      expect(chips.where((name) => name == 'חום'), hasLength(1));
      expect(chips, containsAll(['שיעול', 'כאב ראש', 'כאב בטן']));
      expect(chips.length, lessThanOrEqualTo(SymptomFormScreen.maxSuggestions));

      await tester.tap(find.widgetWithText(ChoiceChip, 'שיעול'));
      await tester.pumpAndSettle();
      expect(textOf(tester, nameField), 'שיעול');
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'שיעול'))
            .selected,
        isTrue,
      );
    });

    testWidgets('saves a new record and returns to the journal', (
      tester,
    ) async {
      await setUpWith();
      await openAddForm(tester);

      await selectMember(tester, 'אבי');
      await tester.enterText(nameField, '  כאב   גב ');
      await selectSeverity(tester, 3);
      await tester.enterText(notesField, 'אחרי הרמת משא');
      await tapSave(tester);

      expect(find.byType(SymptomFormScreen), findsNothing);
      expect(find.text(AppStrings.saveSucceeded), findsOneWidget);
      final added = symptomController.entries.firstWhere(
        (e) => e.name == 'כאב גב',
      );
      expect(added.memberId, 'm3');
      expect(added.severity, 3);
      expect(added.startedAt, DateTime(2026, 10, 15, 12));
      expect(added.notes, 'אחרי הרמת משא');
      expect(added.status, SymptomStatus.ongoing);
      expect(find.byKey(ValueKey(added.id)), findsOneWidget);
    });

    testWidgets('a free name and no notes are fine', (tester) async {
      await setUpWith();
      await openAddForm(tester, filter: 'דנה');
      await tester.enterText(nameField, 'עקצוץ באצבעות');
      await selectSeverity(tester, 1);
      await tapSave(tester);

      final added = symptomController.entries.firstWhere(
        (e) => e.name == 'עקצוץ באצבעות',
      );
      expect(added.notes, isNull);
    });

    testWidgets('a time later than now is not accepted', (tester) async {
      await setUpWith();
      await openAddForm(tester, filter: 'דנה');
      await tester.enterText(nameField, 'שיעול');
      await selectSeverity(tester, 2);

      // The form opened at 12:00; by saving time the clock reads earlier.
      now = DateTime(2026, 10, 15, 11);
      await tapSave(tester);

      expect(find.text(AppStrings.symptomDateInFuture), findsOneWidget);
      expect(find.byType(SymptomFormScreen), findsOneWidget);
      expect(symptomController.entries, hasLength(3));
    });

    testWidgets('the date picker allows only the last five years', (
      tester,
    ) async {
      await setUpWith();
      await openAddForm(tester, filter: 'דנה');

      await tester.tap(find.byType(DatePickerField));
      await tester.pumpAndSettle();

      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.firstDate, DateTime(2021, 10, 15));
      expect(picker.lastDate, DateTime(2026, 10, 15));
      expect(find.text(AppStrings.symptomDatePickerHelp), findsOneWidget);
    });

    testWidgets('a failed save keeps the draft; retrying adds it once', (
      tester,
    ) async {
      await setUpWith();
      await openAddForm(tester, filter: 'דנה');
      await tester.enterText(nameField, 'סחרחורת');
      await selectSeverity(tester, 2);
      symptomRepository.failAdd = true;

      await tapSave(tester);

      expect(find.byType(SymptomFormScreen), findsOneWidget);
      expect(
        find.widgetWithText(InlineErrorMessage, AppStrings.saveFailed),
        findsOneWidget,
      );
      expect(textOf(tester, nameField), 'סחרחורת');

      symptomRepository.failAdd = false;
      await tapSave(tester);

      expect(find.byType(SymptomFormScreen), findsNothing);
      expect(
        symptomController.entries.where((e) => e.name == 'סחרחורת'),
        hasLength(1),
      );
    });

    testWidgets('a double tap on save adds only one record', (tester) async {
      await setUpWith();
      await openAddForm(tester, filter: 'דנה');
      await tester.enterText(nameField, 'סחרחורת');
      await selectSeverity(tester, 2);

      await tester.tap(saveButton);
      await tester.tap(saveButton, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(
        symptomController.entries.where((e) => e.name == 'סחרחורת'),
        hasLength(1),
      );
      expect(find.byType(SymptomsScreen), findsOneWidget);
    });

    testWidgets('a filtered member deleted meanwhile is not replaced', (
      tester,
    ) async {
      await setUpWith();
      await familyController.delete('m2', userConfirmed: true);
      tester.setScreenSize(const Size(400, 2000));
      await tester.pumpApp(
        SymptomFormScreen(initialMemberId: 'm2', clock: () => now),
        dependencies: dependencies,
        familyController: familyController,
        symptomController: symptomController,
      );

      expect(
        tester
            .widget<DropdownButtonFormField<String>>(memberDropdown)
            .initialValue,
        isNull,
      );
    });

    testWidgets('a member deleted while the form is open is cleared, '
        'with an explanation', (tester) async {
      await setUpWith();
      await openAddForm(tester, filter: 'נועה');
      await tester.enterText(nameField, 'שיעול');

      await tester.runAsync(
        () => familyController.delete('m2', userConfirmed: true),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.symptomMemberDeletedWhileEditing),
        findsOneWidget,
      );
      expect(find.text('נועה'), findsNothing);
      await selectSeverity(tester, 2);
      await tapSave(tester);
      expect(find.text(AppStrings.memberRequired), findsOneWidget);
      expect(textOf(tester, nameField), 'שיעול');
    });

    testWidgets('without family members, offers to add one', (tester) async {
      await setUpWith(familyMembers: [], entries: []);
      await openAddForm(tester);

      expect(find.byType(NoFamilyMembersView), findsOneWidget);
      expect(find.text(AppStrings.noFamilyForSymptomTitle), findsOneWidget);
      expect(find.text(AppStrings.addFamilyMember), findsOneWidget);
      expect(saveButton, findsNothing);
    });
  });

  group('leaving with unsaved changes', () {
    testWidgets('an untouched form closes right away', (tester) async {
      await setUpWith();
      await openAddForm(tester, filter: 'דנה');

      await pressBack(tester);

      expect(find.byType(SymptomFormScreen), findsNothing);
    });

    testWidgets('asks first; "keep editing" stays, "leave" discards', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'e1');
      await tester.enterText(notesField, 'הערה שלא נשמרה');
      await tester.pump();

      await pressBack(tester);
      expect(find.text(AppStrings.discardChangesTitle), findsOneWidget);
      await tester.tap(find.text(AppStrings.keepEditing));
      await tester.pumpAndSettle();
      expect(find.byType(SymptomFormScreen), findsOneWidget);
      expect(textOf(tester, notesField), 'הערה שלא נשמרה');

      await pressBack(tester);
      await tester.tap(find.text(AppStrings.discardChanges));
      await tester.pumpAndSettle();
      expect(find.byType(SymptomFormScreen), findsNothing);
      expect(symptomController.entryById('e1')!.notes, 'אחרי העבודה');
    });

    testWidgets('a changed rating also counts as a change', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'e1');
      await selectSeverity(tester, 5);

      await pressBack(tester);

      expect(find.text(AppStrings.discardChangesTitle), findsOneWidget);
    });
  });

  group('edit', () {
    testWidgets('shows the stored values', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'e1');

      expect(find.text(AppStrings.editSymptomTitle), findsOneWidget);
      expect(textOf(tester, nameField), 'כאב ראש');
      expect(textOf(tester, notesField), 'אחרי העבודה');
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(memberDropdown)
            .initialValue,
        'm1',
      );
      expect(
        tester
            .widget<TimePickerField>(find.byType(TimePickerField))
            .initialValue,
        const TimeOfDay(hour: 7, minute: 30),
      );
      expect(
        tester
            .widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>))
            .selected,
        {2},
      );
      expect(deleteButton, findsOneWidget);
    });

    testWidgets('saves a new rating and notes, keeping status and duration', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'e1');

      await selectSeverity(tester, 4);
      await tester.enterText(notesField, 'החמיר בערב');
      await tapSave(tester);

      expect(find.byType(SymptomFormScreen), findsNothing);
      final saved = (await symptomRepository.getById('e1'))!;
      expect(saved.severity, 4);
      expect(saved.notes, 'החמיר בערב');
      expect(saved.startedAt, headache.startedAt);
      expect(saved.status, SymptomStatus.resolved);
      expect(saved.duration, const Duration(hours: 3));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('e1')),
          matching: find.text('החמיר בערב'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('clearing the notes removes them', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'e1');

      await tester.enterText(notesField, '');
      await tapSave(tester);

      expect((await symptomRepository.getById('e1'))!.notes, isNull);
    });

    testWidgets('a date older than five years that was already stored can '
        'stay', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'e3');

      await tester.enterText(notesField, 'עדיין מורגש לפעמים');
      await tapSave(tester);

      expect(find.byType(SymptomFormScreen), findsNothing);
      final saved = (await symptomRepository.getById('e3'))!;
      expect(saved.startedAt, oldInjury.startedAt);
      expect(saved.notes, 'עדיין מורגש לפעמים');
    });

    testWidgets('a failed update keeps the draft and can be retried', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'e1');
      await tester.enterText(notesField, 'ניסיון');
      symptomRepository.failUpdate = true;

      await tapSave(tester);

      expect(
        find.widgetWithText(InlineErrorMessage, AppStrings.saveFailed),
        findsOneWidget,
      );
      expect(textOf(tester, notesField), 'ניסיון');

      symptomRepository.failUpdate = false;
      await tapSave(tester);
      expect(find.byType(SymptomFormScreen), findsNothing);
      expect((await symptomRepository.getById('e1'))!.notes, 'ניסיון');
    });

    testWidgets('a record deleted while open can no longer be saved', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'e1');
      await tester.enterText(notesField, 'טיוטה');

      await tester.runAsync(
        () => symptomController.delete('e1', userConfirmed: true),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.symptomDeletedWhileEditing), findsOneWidget);
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
      expect(deleteButton, findsNothing);

      // Nothing left to lose, so leaving does not ask.
      await pressBack(tester);
      expect(find.byType(SymptomFormScreen), findsNothing);
    });

    testWidgets('an unknown id shows "not found"', (tester) async {
      await setUpWith();
      tester.setScreenSize(const Size(400, 2000));
      await tester.pumpApp(
        SymptomFormScreen(entryId: 'missing', clock: () => now),
        dependencies: dependencies,
        familyController: familyController,
        symptomController: symptomController,
      );

      expect(find.byType(NotFoundView), findsOneWidget);
      expect(find.text(AppStrings.symptomNotFoundTitle), findsOneWidget);
    });
  });

  group('moving a record to another member', () {
    testWidgets('asks first; cancel changes nothing and keeps the draft', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'e1');

      await selectMember(tester, 'נועה');
      await tapSave(tester);

      expect(find.text(AppStrings.moveSymptomTitle('נועה')), findsOneWidget);
      expect(
        find.text(AppStrings.moveSymptomMessage('כאב ראש', 'דנה')),
        findsOneWidget,
      );
      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(find.byType(SymptomFormScreen), findsOneWidget);
      expect((await symptomRepository.getById('e1'))!.memberId, 'm1');
    });

    testWidgets('confirming moves it', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'e1');

      await selectMember(tester, 'נועה');
      await tapSave(tester);
      await tester.tap(find.text(AppStrings.moveAndSave));
      await tester.pumpAndSettle();

      expect(find.byType(SymptomFormScreen), findsNothing);
      final saved = (await symptomRepository.getById('e1'))!;
      expect(saved.memberId, 'm2');
      expect(saved.status, SymptomStatus.resolved);
    });

    testWidgets('saving without changing the member does not ask', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'e1');

      await selectSeverity(tester, 3);
      await tapSave(tester);

      expect(find.text(AppStrings.moveSymptomTitle('דנה')), findsNothing);
      expect(find.byType(SymptomFormScreen), findsNothing);
    });
  });

  group('delete', () {
    testWidgets('shows what will be deleted; cancel keeps it', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'e1');

      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();

      final dialog = find.byType(DeleteSymptomDialog);
      expect(dialog, findsOneWidget);
      Finder inDialog(String text) =>
          find.descendant(of: dialog, matching: find.text(text));
      expect(inDialog('כאב ראש'), findsOneWidget);
      expect(inDialog('דנה'), findsOneWidget);
      expect(inDialog(AppStrings.deleteIrreversible), findsOneWidget);

      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(find.byType(SymptomFormScreen), findsOneWidget);
      expect(await symptomRepository.getById('e1'), isNotNull);
    });

    testWidgets('confirming deletes it and returns to the journal', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'e1');

      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(DeleteSymptomDialog),
          matching: find.text(AppStrings.deleteSymptom),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SymptomFormScreen), findsNothing);
      expect(find.text(AppStrings.symptomDeleted), findsOneWidget);
      expect(await symptomRepository.getById('e1'), isNull);
      expect(find.byKey(const ValueKey('e1')), findsNothing);
      expect(find.byType(SymptomCard), findsNWidgets(2));
    });

    testWidgets('a failed deletion says so and can be retried', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'e1');
      symptomRepository.failDelete = true;

      await tester.ensureVisible(deleteButton);
      await tester.tap(deleteButton);
      await tester.pumpAndSettle();
      final confirm = find.descendant(
        of: find.byType(DeleteSymptomDialog),
        matching: find.byType(FilledButton),
      );
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.deleteSymptomFailed), findsOneWidget);
      expect(await symptomRepository.getById('e1'), isNotNull);

      symptomRepository.failDelete = false;
      await tester.tap(confirm);
      await tester.pumpAndSettle();

      expect(find.byType(DeleteSymptomDialog), findsNothing);
      expect(find.byType(SymptomFormScreen), findsNothing);
      expect(await symptomRepository.getById('e1'), isNull);
    });
  });

  testWidgets('lays out without overflow on a narrow screen with large text', (
    tester,
  ) async {
    await setUpWith();
    tester.setScreenSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpApp(
      SymptomFormScreen(entryId: 'e1', clock: () => now),
      dependencies: dependencies,
      familyController: familyController,
      symptomController: symptomController,
    );
    await tester.pumpAndSettle();

    // With a save error shown at the bottom, too.
    symptomRepository.failUpdate = true;
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(deleteButton, findsOneWidget);
  });
}
