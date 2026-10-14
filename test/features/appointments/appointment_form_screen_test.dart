import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_symptom_repository.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/appointments/appointment_detail_screen.dart';
import 'package:mydr/features/appointments/appointment_form_screen.dart';
import 'package:mydr/features/appointments/appointments_screen.dart';
import 'package:mydr/features/appointments/widgets/appointment_card.dart';
import 'package:mydr/features/appointments/widgets/date_time_fields.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/member_form_screen.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);
  DateTime clock() => now;

  final defaultMembers = [
    FamilyMember(id: 'm1', name: 'דנה', relation: FamilyRelation.self),
    FamilyMember(id: 'm2', name: 'נועה', relation: FamilyRelation.child),
  ];

  // Has two linked questions; "plain" has none.
  final linked = Appointment(
    id: 'linked',
    memberId: 'm1',
    doctorName: 'ד״ר לוי',
    dateTime: DateTime(2026, 10, 15, 9, 30),
    specialty: 'רפואת משפחה',
    location: 'מרפאה שכונתית',
    notes: 'הערה קיימת',
  );
  final plain = Appointment(
    id: 'plain',
    memberId: 'm1',
    doctorName: 'ד״ר כהן',
    dateTime: DateTime(2026, 10, 20, 8),
  );

  DoctorQuestion question(String id) => DoctorQuestion(
    id: id,
    memberId: 'm1',
    appointmentId: 'linked',
    text: 'שאלה $id',
    createdAt: now,
  );

  late FlakyFamilyRepository familyRepository;
  late FlakyAppointmentRepository appointmentRepository;
  late FlakyDoctorQuestionRepository questionRepository;
  late FamilyController familyController;
  late AppointmentController appointmentController;
  late AppDependencies dependencies;

  Future<void> setUpWith({List<FamilyMember>? members}) async {
    familyRepository = FlakyFamilyRepository(members ?? defaultMembers);
    appointmentRepository = FlakyAppointmentRepository([linked, plain]);
    questionRepository = FlakyDoctorQuestionRepository([
      question('q1'),
      question('q2'),
    ]);
    dependencies = AppDependencies(
      familyRepository: familyRepository,
      appointmentRepository: appointmentRepository,
      doctorQuestionRepository: questionRepository,
      symptomRepository: InMemorySymptomRepository(),
    );
    familyController = FamilyController(dependencies);
    appointmentController = AppointmentController(
      dependencies: dependencies,
      familyController: familyController,
    );
    addTearDown(() {
      appointmentController.dispose();
      familyController.dispose();
    });
    await familyController.load();
    await appointmentController.load();
  }

  // Finders
  Finder textField(String label) => find.widgetWithText(TextFormField, label);
  final doctorField = textField(AppStrings.doctorNameLabel);
  final specialtyField = textField(AppStrings.specialtyOptionalLabel);
  final locationField = textField(AppStrings.locationOptionalLabel);
  final notesField = textField(AppStrings.notesOptionalLabel);
  final memberDropdown = find.byType(DropdownButtonFormField<String>);
  final saveButton = find.widgetWithText(FilledButton, AppStrings.save);

  String textOf(WidgetTester tester, Finder field) =>
      tester.widget<TextFormField>(field).controller!.text;

  Future<void> pumpList(WidgetTester tester) {
    tester.setScreenSize(const Size(400, 1800));
    return tester.pumpApp(
      AppointmentsScreen(clock: clock),
      dependencies: dependencies,
      familyController: familyController,
      appointmentController: appointmentController,
    );
  }

  Future<void> openAddForm(WidgetTester tester) async {
    await pumpList(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  /// List → details → edit form, as a user would get there.
  Future<void> openEditForm(WidgetTester tester, String appointmentId) async {
    await pumpList(tester);
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(AppointmentDetailScreen.route(appointmentId, clock: clock));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip(AppStrings.editAppointment));
    await tester.pumpAndSettle();
  }

  Future<void> selectMember(WidgetTester tester, String name) async {
    await tester.tap(memberDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  Future<void> tapOk(WidgetTester tester, Type dialogType) async {
    final localizations = MaterialLocalizations.of(
      tester.element(find.byType(dialogType)),
    );
    await tester.tap(find.text(localizations.okButtonLabel));
    await tester.pumpAndSettle();
  }

  /// Picks [day] of the month the picker opens on.
  Future<void> pickDay(WidgetTester tester, int day) async {
    await tester.tap(find.byType(AppointmentDateField));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(DatePickerDialog),
            matching: find.text('$day'),
          )
          .first,
    );
    await tester.tap(
      find.text(
        MaterialLocalizations.of(
          tester.element(find.byType(DatePickerDialog)),
        ).okButtonLabel,
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Accepts the time picker's initial time (9:00 for a new appointment).
  Future<void> pickDefaultTime(WidgetTester tester) async {
    await tester.tap(find.byType(AppointmentTimeField));
    await tester.pumpAndSettle();
    await tapOk(tester, TimePickerDialog);
  }

  Future<void> fillRequired(WidgetTester tester) async {
    await selectMember(tester, 'נועה');
    await tester.enterText(doctorField, 'ד״ר חדש');
    await pickDay(tester, 20);
    await pickDefaultTime(tester);
  }

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  }

  group('add', () {
    testWidgets('saves a new appointment and returns to the list', (
      tester,
    ) async {
      await setUpWith();
      await openAddForm(tester);

      expect(find.text(AppStrings.newAppointment), findsWidgets);
      await fillRequired(tester);
      await tester.enterText(specialtyField, '  עור  ');
      await tester.enterText(locationField, 'מרפאה');
      await tester.enterText(notesField, 'להביא הפניה');
      await tapSave(tester);

      expect(find.byType(AppointmentFormScreen), findsNothing);
      expect(find.byType(AppointmentsScreen), findsOneWidget);
      expect(find.text(AppStrings.saveSucceeded), findsOneWidget);
      expect(find.widgetWithText(AppointmentCard, 'ד״ר חדש'), findsOneWidget);

      final saved = appointmentController.appointments.singleWhere(
        (a) => a.doctorName == 'ד״ר חדש',
      );
      expect(saved.memberId, 'm2');
      expect(saved.dateTime, DateTime(2026, 10, 20, 9));
      expect(saved.specialty, 'עור');
      expect(saved.location, 'מרפאה');
      expect(saved.notes, 'להביא הפניה');
    });

    testWidgets('leaves optional fields empty when not filled', (tester) async {
      await setUpWith();
      await openAddForm(tester);

      await fillRequired(tester);
      await tapSave(tester);

      final saved = appointmentController.appointments.singleWhere(
        (a) => a.doctorName == 'ד״ר חדש',
      );
      expect(saved.specialty, isNull);
      expect(saved.location, isNull);
      expect(saved.notes, isNull);
    });

    testWidgets('preselects the requested member', (tester) async {
      await setUpWith();
      tester.setScreenSize(const Size(400, 1800));
      await tester.pumpApp(
        AppointmentFormScreen(initialMemberId: 'm2', clock: clock),
        dependencies: dependencies,
        familyController: familyController,
        appointmentController: appointmentController,
      );

      expect(
        find.descendant(of: memberDropdown, matching: find.text('נועה')),
        findsOneWidget,
      );
    });

    testWidgets('preselects the only family member', (tester) async {
      await setUpWith(members: [defaultMembers.first]);
      await openAddForm(tester);

      expect(
        find.descendant(of: memberDropdown, matching: find.text('דנה')),
        findsOneWidget,
      );
    });
  });

  group('without family members', () {
    testWidgets('explains why and offers to add a member', (tester) async {
      await setUpWith(members: []);
      await openAddForm(tester);

      expect(find.text(AppStrings.noFamilyForAppointmentTitle), findsOneWidget);
      expect(doctorField, findsNothing);
      expect(saveButton, findsNothing);
    });

    testWidgets('after adding a member, the form opens with them selected', (
      tester,
    ) async {
      await setUpWith(members: []);
      await openAddForm(tester);

      await tester.tap(find.text(AppStrings.addFamilyMember).last);
      await tester.pumpAndSettle();
      expect(find.byType(MemberFormScreen), findsOneWidget);

      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.nameLabel),
        'יעל',
      );
      await tester.tap(find.byType(DropdownButtonFormField<FamilyRelation>));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.relationSibling).last);
      await tester.pumpAndSettle();
      await tester.tap(saveButton);
      await tester.pumpAndSettle();

      expect(find.byType(MemberFormScreen), findsNothing);
      expect(doctorField, findsOneWidget);
      expect(
        find.descendant(of: memberDropdown, matching: find.text('יעל')),
        findsOneWidget,
      );
    });
  });

  group('validation', () {
    testWidgets('member, doctor, date and time are required', (tester) async {
      await setUpWith();
      await openAddForm(tester);

      await tester.enterText(doctorField, '   ');
      await tapSave(tester);

      expect(find.text(AppStrings.memberRequired), findsOneWidget);
      expect(find.text(AppStrings.doctorNameRequired), findsOneWidget);
      expect(find.text(AppStrings.dateRequired), findsOneWidget);
      expect(find.text(AppStrings.timeRequired), findsOneWidget);
      expect(appointmentRepository.addCalls, 0);
    });

    testWidgets('text fields are limited in length', (tester) async {
      await setUpWith();
      await openAddForm(tester);

      await tester.enterText(doctorField, 'א' * 100);
      await tester.enterText(specialtyField, 'א' * 100);
      await tester.enterText(locationField, 'א' * 200);
      await tester.enterText(notesField, 'א' * 600);

      expect(textOf(tester, doctorField), hasLength(60));
      expect(textOf(tester, specialtyField), hasLength(50));
      expect(textOf(tester, locationField), hasLength(100));
      expect(textOf(tester, notesField), hasLength(500));
    });
  });

  group('date and time', () {
    testWidgets('dates range from five years back to five years ahead', (
      tester,
    ) async {
      await setUpWith();
      await openAddForm(tester);

      await tester.tap(find.byType(AppointmentDateField));
      await tester.pumpAndSettle();

      final picker = tester.widget<DatePickerDialog>(
        find.byType(DatePickerDialog),
      );
      expect(picker.firstDate, DateTime(2021, 10, 14));
      expect(picker.lastDate, DateTime(2031, 10, 14));
      expect(picker.initialDate, DateTime(2026, 10, 14));
    });

    testWidgets('a picked date and time are shown in the form', (tester) async {
      await setUpWith();
      await openAddForm(tester);

      await pickDay(tester, 20);
      await pickDefaultTime(tester);

      final localizations = MaterialLocalizations.of(
        tester.element(find.byType(AppointmentFormScreen)),
      );
      expect(
        find.text(localizations.formatFullDate(DateTime(2026, 10, 20))),
        findsOneWidget,
      );
      expect(find.text('9:00'), findsOneWidget);
    });

    testWidgets('the time picker uses the 24-hour clock', (tester) async {
      await setUpWith();
      await openAddForm(tester);

      await tester.tap(find.byType(AppointmentTimeField));
      await tester.pumpAndSettle();

      final pickerContext = tester.element(find.byType(TimePickerDialog));
      expect(MediaQuery.of(pickerContext).alwaysUse24HourFormat, isTrue);
    });
  });

  group('edit', () {
    testWidgets('the details edit button opens a pre-filled form', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'linked');

      expect(find.text(AppStrings.editAppointmentTitle), findsOneWidget);
      expect(textOf(tester, doctorField), 'ד״ר לוי');
      expect(textOf(tester, specialtyField), 'רפואת משפחה');
      expect(textOf(tester, locationField), 'מרפאה שכונתית');
      expect(textOf(tester, notesField), 'הערה קיימת');
      expect(
        find.descendant(of: memberDropdown, matching: find.text('דנה')),
        findsOneWidget,
      );
      final localizations = MaterialLocalizations.of(
        tester.element(find.byType(AppointmentFormScreen)),
      );
      expect(
        find.text(localizations.formatFullDate(linked.dateTime)),
        findsOneWidget,
      );
      expect(find.text('9:30'), findsOneWidget);
    });

    testWidgets('saving returns to the details, which show the change', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'linked');

      await tester.enterText(doctorField, 'ד״ר לוי-כהן');
      await tapSave(tester);

      expect(find.byType(AppointmentFormScreen), findsNothing);
      // Back on the one details screen, not a new copy of it.
      expect(find.byType(AppointmentDetailScreen), findsOneWidget);
      expect(find.text('ד״ר לוי-כהן'), findsWidgets);
      final navigator = tester.state<NavigatorState>(find.byType(Navigator));
      navigator.pop();
      await tester.pumpAndSettle();
      expect(find.byType(AppointmentsScreen), findsOneWidget);
      expect(navigator.canPop(), isFalse);
    });

    testWidgets('an unknown appointment id shows the not-found state', (
      tester,
    ) async {
      await setUpWith();
      await tester.pumpApp(
        AppointmentFormScreen(appointmentId: 'missing', clock: clock),
        dependencies: dependencies,
        familyController: familyController,
        appointmentController: appointmentController,
      );

      expect(find.text(AppStrings.appointmentNotFoundTitle), findsOneWidget);
      expect(saveButton, findsNothing);
    });
  });

  group('changing the family member', () {
    testWidgets('with linked questions, asks first; cancel changes nothing', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'linked');

      await selectMember(tester, 'נועה');
      await tapSave(tester);

      expect(find.text(AppStrings.moveAppointmentTitle('נועה')), findsOne);
      expect(
        find.text(AppStrings.moveAppointmentMessage(2, 'דנה')),
        findsOneWidget,
      );

      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(find.byType(AppointmentFormScreen), findsOneWidget);
      expect(appointmentController.appointmentById('linked')!.memberId, 'm1');
      expect((await questionRepository.getById('q1'))!.appointmentId, 'linked');
    });

    testWidgets('confirming moves it and keeps the questions with the '
        'original member', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'linked');

      await selectMember(tester, 'נועה');
      await tapSave(tester);
      await tester.tap(find.text(AppStrings.moveAndSave));
      await tester.pumpAndSettle();

      expect(find.byType(AppointmentFormScreen), findsNothing);
      expect(appointmentController.appointmentById('linked')!.memberId, 'm2');
      for (final id in ['q1', 'q2']) {
        final stored = (await questionRepository.getById(id))!;
        expect(stored.appointmentId, isNull);
        expect(stored.memberId, 'm1');
      }
    });

    testWidgets('without linked questions, saves without asking', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'plain');

      await selectMember(tester, 'נועה');
      await tapSave(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(AppointmentFormScreen), findsNothing);
      expect(appointmentController.appointmentById('plain')!.memberId, 'm2');
    });

    testWidgets('if the questions cannot be checked, nothing is saved', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'linked');
      questionRepository.failGetAll = true;

      await selectMember(tester, 'נועה');
      await tapSave(tester);

      expect(find.text(AppStrings.linkedQuestionsCheckFailed), findsOneWidget);
      expect(find.byType(AlertDialog), findsNothing);
      expect(appointmentController.appointmentById('linked')!.memberId, 'm1');
    });

    testWidgets('a failure after unlinking is explained, and a retry works', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'linked');
      appointmentRepository.failUpdate = true;

      await selectMember(tester, 'נועה');
      await tapSave(tester);
      await tester.tap(find.text(AppStrings.moveAndSave));
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.saveFailedAfterDetaching('דנה')),
        findsOneWidget,
      );
      expect(find.byType(AppointmentFormScreen), findsOneWidget);

      appointmentRepository.failUpdate = false;
      await tapSave(tester);

      // The questions are already unlinked, so there is nothing to confirm.
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(AppointmentFormScreen), findsNothing);
      expect(appointmentController.appointmentById('linked')!.memberId, 'm2');
    });
  });

  group('saving', () {
    testWidgets('shows progress and ignores repeated taps', (tester) async {
      await setUpWith();
      await openAddForm(tester);
      await fillRequired(tester);
      appointmentRepository.addGate = Completer<void>();

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
      expect(appointmentRepository.addCalls, 1);

      appointmentRepository.addGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(AppointmentFormScreen), findsNothing);
    });

    testWidgets('a failed save keeps the form and its data', (tester) async {
      await setUpWith();
      await openAddForm(tester);
      await fillRequired(tester);
      await tester.enterText(notesField, 'הערה');
      appointmentRepository.failAdd = true;

      await tapSave(tester);

      expect(find.text(AppStrings.saveFailed), findsOneWidget);
      expect(find.byType(AppointmentFormScreen), findsOneWidget);
      expect(textOf(tester, doctorField), 'ד״ר חדש');
      expect(textOf(tester, notesField), 'הערה');

      appointmentRepository.failAdd = false;
      await tapSave(tester);
      expect(find.byType(AppointmentFormScreen), findsNothing);
      expect(
        appointmentController.appointments.where(
          (a) => a.doctorName == 'ד״ר חדש',
        ),
        hasLength(1),
      );
    });

    testWidgets('a member deleted while the form is open is handled', (
      tester,
    ) async {
      await setUpWith();
      await openAddForm(tester);
      await fillRequired(tester);

      await familyController.delete('m2', userConfirmed: true);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tapSave(tester);
      expect(find.text(AppStrings.memberRequired), findsOneWidget);
      expect(appointmentRepository.addCalls, 0);
    });
  });

  group('leaving with unsaved changes', () {
    testWidgets('leaves immediately when nothing changed', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'linked');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.discardChangesTitle), findsNothing);
      expect(find.byType(AppointmentFormScreen), findsNothing);
    });

    testWidgets('asks first; "keep editing" keeps the data', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'linked');
      await tester.enterText(doctorField, 'ד״ר אחר');
      await tester.pump();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.discardChangesTitle), findsOneWidget);

      await tester.tap(find.text(AppStrings.keepEditing));
      await tester.pumpAndSettle();
      expect(textOf(tester, doctorField), 'ד״ר אחר');
    });

    testWidgets('"leave without saving" discards the changes', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'linked');
      await pickDay(tester, 25);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.discardChanges));
      await tester.pumpAndSettle();

      expect(find.byType(AppointmentFormScreen), findsNothing);
      expect(
        appointmentController.appointmentById('linked')!.dateTime,
        linked.dateTime,
      );
    });
  });

  testWidgets('lays out without overflow on a narrow screen with large text '
      'and the keyboard open', (tester) async {
    await setUpWith();
    await openEditForm(tester, 'linked');
    await tester.enterText(doctorField, '');
    await tapSave(tester);

    tester.setScreenSize(const Size(320, 568));
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetViewInsets);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    await tester.drag(
      find.descendant(
        of: find.byType(AppointmentFormScreen),
        matching: find.byType(ListView),
      ),
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(saveButton.hitTestable(), findsOneWidget);
  });
}
