import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_appointment_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_doctor_question_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_symptom_repository.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/family_screen.dart';
import 'package:mydr/features/family/member_detail_screen.dart';
import 'package:mydr/features/family/member_form_screen.dart';
import 'package:mydr/features/family/widgets/birth_date_field.dart';
import 'package:mydr/features/family/widgets/member_card.dart';
import 'package:mydr/features/family/widgets/string_list_field.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  final selfMember = FamilyMember(
    id: 'm-self',
    name: 'דנה',
    relation: FamilyRelation.self,
  );
  final childMember = FamilyMember(
    id: 'm-child',
    name: 'נועה',
    relation: FamilyRelation.child,
    allergies: const ['אבקני פרחים'],
  );

  late FlakyFamilyRepository repository;
  late FamilyController controller;

  Future<void> setUpWith(List<FamilyMember> members) async {
    repository = FlakyFamilyRepository(members);
    controller = FamilyController(
      AppDependencies(
        familyRepository: repository,
        appointmentRepository: InMemoryAppointmentRepository(),
        doctorQuestionRepository: InMemoryDoctorQuestionRepository(),
        symptomRepository: InMemorySymptomRepository(),
      ),
    );
    addTearDown(controller.dispose);
    await controller.load();
  }

  // Finders
  final nameField = find.widgetWithText(TextFormField, AppStrings.nameLabel);
  final notesField = find.widgetWithText(
    TextFormField,
    AppStrings.notesOptionalLabel,
  );
  final saveButton = find.widgetWithText(FilledButton, AppStrings.save);
  Finder listField(String title) =>
      find.byWidgetPredicate((w) => w is StringListField && w.title == title);
  Finder listInput(String title) =>
      find.descendant(of: listField(title), matching: find.byType(TextField));
  Finder listAddButton(String title) => find.descendant(
    of: listField(title),
    matching: find.byTooltip(AppStrings.addItem),
  );

  /// Opens the add form from the family list, on a screen tall enough to
  /// show the whole form.
  Future<void> openAddForm(WidgetTester tester) async {
    tester.setScreenSize(const Size(400, 1600));
    await tester.pumpApp(const FamilyScreen(), familyController: controller);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Future<void> selectRelation(WidgetTester tester, String label) async {
    await tester.tap(find.byType(DropdownButtonFormField<FamilyRelation>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(label).last);
    await tester.pumpAndSettle();
  }

  Future<void> addListItem(
    WidgetTester tester,
    String title,
    String text,
  ) async {
    await tester.enterText(listInput(title), text);
    await tester.tap(listAddButton(title));
    await tester.pump();
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  }

  group('add', () {
    testWidgets('saves a new member and shows it in the list', (tester) async {
      await setUpWith([selfMember]);
      await openAddForm(tester);

      expect(find.text(AppStrings.addFamilyMember), findsWidgets);
      await tester.enterText(nameField, '  אבי  ');
      await selectRelation(tester, AppStrings.relationSpouse);
      await addListItem(tester, AppStrings.allergiesSection, 'אבקני פרחים');
      await addListItem(tester, AppStrings.chronicConditionsSection, 'מצב א');
      await tester.enterText(notesField, 'הערה');
      await tapSave(tester);

      expect(find.byType(MemberFormScreen), findsNothing);
      expect(find.widgetWithText(MemberCard, 'אבי'), findsOneWidget);
      expect(find.text(AppStrings.saveSucceeded), findsOneWidget);

      final saved = controller.members.singleWhere((m) => m.name == 'אבי');
      expect(saved.relation, FamilyRelation.spouse);
      expect(saved.allergies, ['אבקני פרחים']);
      expect(saved.chronicConditions, ['מצב א']);
      expect(saved.notes, 'הערה');
      expect(saved.birthDate, isNull);
    });
  });

  group('edit', () {
    testWidgets('the profile edit button opens a pre-filled form', (
      tester,
    ) async {
      await setUpWith([selfMember, childMember]);
      tester.setScreenSize(const Size(400, 1600));
      await tester.pumpApp(const FamilyScreen(), familyController: controller);
      await tester.tap(find.widgetWithText(MemberCard, 'נועה'));
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip(AppStrings.edit));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.editMemberTitle), findsOneWidget);
      expect(tester.widget<TextFormField>(nameField).controller!.text, 'נועה');
      expect(find.text(AppStrings.relationChild), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'אבקני פרחים'), findsOneWidget);
    });

    testWidgets('saving returns to the profile, which shows the change', (
      tester,
    ) async {
      await setUpWith([selfMember, childMember]);
      tester.setScreenSize(const Size(400, 1600));
      await tester.pumpApp(const FamilyScreen(), familyController: controller);
      await tester.tap(find.widgetWithText(MemberCard, 'נועה'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip(AppStrings.edit));
      await tester.pumpAndSettle();

      await tester.enterText(nameField, 'נועה ל.');
      await tapSave(tester);

      expect(find.byType(MemberFormScreen), findsNothing);
      expect(find.byType(MemberDetailScreen), findsOneWidget);
      // App bar and header.
      expect(find.text('נועה ל.'), findsNWidgets(2));
      expect(controller.memberById('m-child')!.allergies, ['אבקני פרחים']);
    });

    testWidgets('the existing "self" profile can keep its relation', (
      tester,
    ) async {
      await setUpWith([selfMember]);
      tester.setScreenSize(const Size(400, 1600));
      await tester.pumpApp(
        const MemberFormScreen(memberId: 'm-self'),
        familyController: controller,
      );

      await tester.enterText(nameField, 'דנה כ.');
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.selfAlreadyExists), findsNothing);
      expect(controller.memberById('m-self')!.name, 'דנה כ.');
    });

    testWidgets('an unknown member id shows the not-found state', (
      tester,
    ) async {
      await setUpWith([selfMember]);
      await tester.pumpApp(
        const MemberFormScreen(memberId: 'missing'),
        familyController: controller,
      );

      expect(find.text(AppStrings.memberNotFoundTitle), findsOneWidget);
      expect(saveButton, findsNothing);
    });
  });

  group('validation', () {
    testWidgets('name and relation are required', (tester) async {
      await setUpWith([]);
      await openAddForm(tester);

      await tester.enterText(nameField, '   ');
      await tapSave(tester);

      expect(find.text(AppStrings.nameRequired), findsOneWidget);
      expect(find.text(AppStrings.relationRequired), findsOneWidget);
      expect(repository.addCalls, 0);
      expect(find.byType(MemberFormScreen), findsOneWidget);
    });

    testWidgets('name is limited to 50 characters', (tester) async {
      await setUpWith([]);
      await openAddForm(tester);

      await tester.enterText(nameField, 'א' * 60);

      expect(
        tester.widget<TextFormField>(nameField).controller!.text,
        hasLength(MemberFormScreen.maxNameLength),
      );
    });

    testWidgets('notes are limited to 500 characters', (tester) async {
      await setUpWith([]);
      await openAddForm(tester);

      await tester.enterText(notesField, 'א' * 600);

      expect(
        tester.widget<TextFormField>(notesField).controller!.text,
        hasLength(MemberFormScreen.maxNotesLength),
      );
    });

    testWidgets('a second "self" profile is rejected with a clear message', (
      tester,
    ) async {
      await setUpWith([selfMember]);
      await openAddForm(tester);

      await tester.enterText(nameField, 'עוד אני');
      await selectRelation(tester, AppStrings.relationSelf);

      // Shown as soon as it is selected, and blocks saving.
      expect(find.text(AppStrings.selfAlreadyExists), findsOneWidget);
      await tapSave(tester);
      expect(repository.addCalls, 0);
      expect(find.byType(MemberFormScreen), findsOneWidget);
    });

    testWidgets('a "self" conflict detected by the controller is reported', (
      tester,
    ) async {
      await setUpWith([childMember]);
      await openAddForm(tester);
      // Added behind the form's back, so its local check still allows "self".
      await repository.add(selfMember);

      await tester.enterText(nameField, 'עוד אני');
      await selectRelation(tester, AppStrings.relationSelf);
      await tapSave(tester);

      expect(find.text(AppStrings.selfAlreadyExists), findsOneWidget);
      expect(find.byType(MemberFormScreen), findsOneWidget);
    });
  });

  group('item lists', () {
    const allergies = AppStrings.allergiesSection;

    testWidgets('items can be added and removed', (tester) async {
      await setUpWith([]);
      await openAddForm(tester);

      await addListItem(tester, allergies, '  אגוזים ');
      await addListItem(tester, allergies, 'חלב');

      expect(find.widgetWithText(InputChip, 'אגוזים'), findsOneWidget);
      expect(find.widgetWithText(InputChip, 'חלב'), findsOneWidget);
      expect(
        tester.widget<TextField>(listInput(allergies)).controller!.text,
        isEmpty,
      );

      await tester.tap(find.byTooltip(AppStrings.removeItem('אגוזים')));
      await tester.pump();

      expect(find.widgetWithText(InputChip, 'אגוזים'), findsNothing);
      expect(find.widgetWithText(InputChip, 'חלב'), findsOneWidget);
    });

    testWidgets('empty items are rejected', (tester) async {
      await setUpWith([]);
      await openAddForm(tester);

      await addListItem(tester, allergies, '   ');

      expect(find.text(AppStrings.listItemEmpty), findsOneWidget);
      expect(find.byType(InputChip), findsNothing);
    });

    testWidgets('duplicate items are rejected, ignoring case and spaces', (
      tester,
    ) async {
      await setUpWith([]);
      await openAddForm(tester);

      await addListItem(tester, allergies, 'Latex');
      await addListItem(tester, allergies, ' latex ');

      expect(find.text(AppStrings.listItemDuplicate), findsOneWidget);
      expect(find.byType(InputChip), findsOneWidget);
    });

    testWidgets('text typed but not added blocks saving', (tester) async {
      await setUpWith([]);
      await openAddForm(tester);

      await tester.enterText(nameField, 'אבי');
      await selectRelation(tester, AppStrings.relationSpouse);
      await tester.enterText(listInput(allergies), 'אגוזים');
      await tapSave(tester);

      expect(find.text(AppStrings.listItemPending), findsOneWidget);
      expect(repository.addCalls, 0);
    });
  });

  group('birth date', () {
    testWidgets('can be picked from past dates only, and cleared', (
      tester,
    ) async {
      await setUpWith([]);
      await openAddForm(tester);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      await tester.tap(find.byType(BirthDateField));
      await tester.pumpAndSettle();

      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.lastDate, today);

      final localizations = MaterialLocalizations.of(
        tester.element(find.byType(DatePickerDialog)),
      );
      await tester.tap(
        find
            .descendant(
              of: find.byType(DatePickerDialog),
              matching: find.text('1'),
            )
            .first,
      );
      await tester.tap(find.text(localizations.okButtonLabel));
      await tester.pumpAndSettle();

      final picked = DateTime(today.year, today.month, 1);
      expect(
        find.text(localizations.formatCompactDate(picked)),
        findsOneWidget,
      );

      await tester.tap(find.byTooltip(AppStrings.clearBirthDate));
      await tester.pump();

      expect(find.text(localizations.formatCompactDate(picked)), findsNothing);
      expect(find.byTooltip(AppStrings.clearBirthDate), findsNothing);
    });
  });

  group('saving', () {
    testWidgets('shows progress and ignores repeated taps', (tester) async {
      await setUpWith([]);
      await openAddForm(tester);
      repository.addGate = Completer<void>();

      await tester.enterText(nameField, 'אבי');
      await selectRelation(tester, AppStrings.relationSpouse);
      await tester.tap(saveButton);
      await tester.pump();

      expect(
        find.descendant(
          of: find.byType(FilledButton),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(find.byType(FilledButton), warnIfMissed: false);
      await tester.pump();
      expect(repository.addCalls, 1);

      repository.addGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(MemberFormScreen), findsNothing);
      expect(controller.members, hasLength(1));
    });

    testWidgets('a failed save keeps the form open with its data', (
      tester,
    ) async {
      await setUpWith([]);
      await openAddForm(tester);
      repository.failAdd = true;

      await tester.enterText(nameField, 'אבי');
      await selectRelation(tester, AppStrings.relationSpouse);
      await addListItem(tester, AppStrings.allergiesSection, 'אגוזים');
      await tapSave(tester);

      expect(find.text(AppStrings.saveFailed), findsOneWidget);
      expect(find.byType(MemberFormScreen), findsOneWidget);
      expect(tester.widget<TextFormField>(nameField).controller!.text, 'אבי');
      expect(find.widgetWithText(InputChip, 'אגוזים'), findsOneWidget);

      // Retrying once the problem is gone succeeds.
      repository.failAdd = false;
      await tapSave(tester);
      expect(find.byType(MemberFormScreen), findsNothing);
      expect(controller.members.single.allergies, ['אגוזים']);
    });
  });

  group('leaving with unsaved changes', () {
    testWidgets('leaves immediately when nothing changed', (tester) async {
      await setUpWith([]);
      await openAddForm(tester);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.discardChangesTitle), findsNothing);
      expect(find.byType(MemberFormScreen), findsNothing);
    });

    testWidgets('asks first, and "keep editing" keeps the data', (
      tester,
    ) async {
      await setUpWith([]);
      await openAddForm(tester);
      await tester.enterText(nameField, 'אבי');
      await tester.pump();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.discardChangesTitle), findsOneWidget);
      await tester.tap(find.text(AppStrings.keepEditing));
      await tester.pumpAndSettle();

      expect(find.byType(MemberFormScreen), findsOneWidget);
      expect(tester.widget<TextFormField>(nameField).controller!.text, 'אבי');
    });

    testWidgets('"leave without saving" discards and goes back', (
      tester,
    ) async {
      await setUpWith([]);
      await openAddForm(tester);
      await addListItem(tester, AppStrings.allergiesSection, 'אגוזים');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.discardChanges));
      await tester.pumpAndSettle();

      expect(find.byType(MemberFormScreen), findsNothing);
      expect(controller.members, isEmpty);
    });
  });

  testWidgets('lays out without overflow on a narrow screen with large text '
      'and the keyboard open', (tester) async {
    await setUpWith([childMember]);
    await tester.pumpApp(
      const MemberFormScreen(memberId: 'm-child'),
      familyController: controller,
    );
    // Show validation errors too, so their layout is covered.
    await tester.enterText(nameField, '');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    tester.setScreenSize(const Size(320, 568));
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetViewInsets);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // The save button stays reachable above the keyboard.
    expect(saveButton.hitTestable(), findsOneWidget);
  });
}
