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
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/member_form_screen.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';
import 'package:mydr/features/questions/doctor_question_form_screen.dart';
import 'package:mydr/features/questions/doctor_questions_screen.dart';
import 'package:mydr/features/questions/widgets/question_card.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 10, 15, 12);
  DateTime clock() => now;

  // m3 has no appointments.
  final defaultMembers = [
    FamilyMember(id: 'm1', name: 'דנה', relation: FamilyRelation.self),
    FamilyMember(id: 'm2', name: 'נועה', relation: FamilyRelation.child),
    FamilyMember(id: 'm3', name: 'אבי', relation: FamilyRelation.spouse),
  ];

  final appointments = [
    Appointment(
      id: 'a1',
      memberId: 'm1',
      doctorName: 'ד״ר לוי',
      dateTime: DateTime(2026, 10, 16, 9, 30),
    ),
    Appointment(
      id: 'past',
      memberId: 'm1',
      doctorName: 'ד״ר אברהם',
      dateTime: DateTime(2026, 10, 5, 8),
    ),
    Appointment(
      id: 'a2',
      memberId: 'm2',
      doctorName: 'ד״ר מזרחי',
      dateTime: DateTime(2026, 10, 18, 16),
    ),
  ];

  final linkedQuestion = DoctorQuestion(
    id: 'q1',
    memberId: 'm1',
    appointmentId: 'a1',
    text: 'שאלה משויכת',
    createdAt: DateTime(2026, 10, 1),
  );
  final generalQuestion = DoctorQuestion(
    id: 'q2',
    memberId: 'm1',
    text: 'שאלה כללית קיימת',
    createdAt: DateTime(2026, 10, 2),
    isResolved: true,
    doctorAnswer: 'תשובה קיימת',
  );

  late FlakyFamilyRepository familyRepository;
  late FlakyAppointmentRepository appointmentRepository;
  late FlakyDoctorQuestionRepository questionRepository;
  late AppDependencies dependencies;
  late FamilyController familyController;
  late AppointmentController appointmentController;
  late DoctorQuestionController questionController;

  Future<void> setUpWith({List<FamilyMember>? members}) async {
    familyRepository = FlakyFamilyRepository(members ?? defaultMembers);
    appointmentRepository = FlakyAppointmentRepository(appointments);
    questionRepository = FlakyDoctorQuestionRepository([
      linkedQuestion,
      generalQuestion,
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
    questionController = DoctorQuestionController(
      dependencies: dependencies,
      familyController: familyController,
      appointmentController: appointmentController,
    );
    addTearDown(() {
      questionController.dispose();
      appointmentController.dispose();
      familyController.dispose();
    });
    await familyController.load();
    await appointmentController.load();
    await questionController.load();
  }

  // Finders
  final memberDropdown = find.byType(DropdownButtonFormField<String>);
  final appointmentDropdown = find.byType(DropdownButtonFormField<String?>);
  final textField = find.widgetWithText(
    TextFormField,
    AppStrings.questionTextLabel,
  );
  final answerField = find.widgetWithText(
    TextFormField,
    AppStrings.doctorAnswerLabel,
  );
  final saveButton = find.widgetWithText(FilledButton, AppStrings.save);
  final resolvedSwitch = find.byType(SwitchListTile);

  String textOf(WidgetTester tester, Finder field) =>
      tester.widget<TextFormField>(field).controller!.text;

  Future<void> pumpList(WidgetTester tester) {
    tester.setScreenSize(const Size(400, 1800));
    return tester.pumpApp(
      DoctorQuestionsScreen(clock: clock),
      dependencies: dependencies,
      familyController: familyController,
      appointmentController: appointmentController,
      doctorQuestionController: questionController,
    );
  }

  Future<void> openAddForm(WidgetTester tester) async {
    await pumpList(tester);
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
  }

  Future<void> openEditForm(WidgetTester tester, String questionText) async {
    await pumpList(tester);
    await tester.tap(find.text(questionText));
    await tester.pumpAndSettle();
  }

  Future<void> selectMember(WidgetTester tester, String name) async {
    await tester.tap(memberDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.text(name).last);
    await tester.pumpAndSettle();
  }

  /// Labels of the last [count] dropdown items, which belong to the open
  /// menu (the button itself also builds its items).
  Future<List<String>> openAppointmentMenu(
    WidgetTester tester, {
    required int count,
  }) async {
    await tester.tap(appointmentDropdown);
    await tester.pumpAndSettle();
    final labels = [
      for (final item in tester.widgetList<DropdownMenuItem<String?>>(
        find.byType(DropdownMenuItem<String?>),
      ))
        (item.child as Text).data ?? '',
    ];
    return labels.sublist(labels.length - count);
  }

  Future<void> selectAppointment(WidgetTester tester, String doctor) async {
    await tester.tap(appointmentDropdown);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining(doctor).last);
    await tester.pumpAndSettle();
  }

  Finder selectedAppointmentText(String text) =>
      find.descendant(of: appointmentDropdown, matching: find.text(text));

  Future<void> tapSave(WidgetTester tester) async {
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
  }

  DoctorQuestion savedWithText(String text) =>
      questionController.questions.singleWhere((q) => q.text == text);

  group('add', () {
    testWidgets('a general question, back to the list', (tester) async {
      await setUpWith();
      await openAddForm(tester);

      expect(find.text(AppStrings.newQuestion), findsWidgets);
      await selectMember(tester, 'נועה');
      await tester.enterText(textField, '  מה לגבי חיסונים?  ');
      await tapSave(tester);

      expect(find.byType(DoctorQuestionFormScreen), findsNothing);
      expect(find.byType(DoctorQuestionsScreen), findsOneWidget);
      expect(find.text(AppStrings.saveSucceeded), findsOneWidget);
      expect(
        find.widgetWithText(QuestionCard, 'מה לגבי חיסונים?'),
        findsOneWidget,
      );
      final saved = savedWithText('מה לגבי חיסונים?');
      expect(saved.memberId, 'm2');
      expect(saved.appointmentId, isNull);
      expect(saved.isResolved, isFalse);
      expect(saved.doctorAnswer, isNull);
      expect(saved.createdAt, now);
    });

    testWidgets('linked to an appointment, handled, with an answer', (
      tester,
    ) async {
      await setUpWith();
      await openAddForm(tester);

      await selectMember(tester, 'דנה');
      await tester.enterText(textField, 'שאלה לתור');
      await selectAppointment(tester, 'ד״ר לוי');
      await tester.tap(resolvedSwitch);
      await tester.pump();
      await tester.enterText(answerField, 'לחזור בעוד חודש');
      await tapSave(tester);

      final saved = savedWithText('שאלה לתור');
      expect(saved.appointmentId, 'a1');
      expect(saved.isResolved, isTrue);
      expect(saved.doctorAnswer, 'לחזור בעוד חודש');
    });

    testWidgets('can be linked to a past appointment', (tester) async {
      await setUpWith();
      await openAddForm(tester);

      await selectMember(tester, 'דנה');
      await tester.enterText(textField, 'שאלה על ביקור קודם');
      await selectAppointment(tester, 'ד״ר אברהם');
      await tapSave(tester);

      expect(savedWithText('שאלה על ביקור קודם').appointmentId, 'past');
    });

    testWidgets('preselects the member and appointment it was opened for', (
      tester,
    ) async {
      await setUpWith();
      tester.setScreenSize(const Size(400, 1800));
      await tester.pumpApp(
        DoctorQuestionFormScreen(
          initialMemberId: 'm1',
          initialAppointmentId: 'a1',
          clock: clock,
        ),
        dependencies: dependencies,
        familyController: familyController,
        appointmentController: appointmentController,
        doctorQuestionController: questionController,
      );

      expect(
        find.descendant(of: memberDropdown, matching: find.text('דנה')),
        findsOneWidget,
      );
      expect(
        selectedAppointmentText('ד״ר לוי · ${AppStrings.tomorrow} · 9:30'),
        findsOneWidget,
      );
    });
  });

  group('appointment choices', () {
    testWidgets("only the chosen member's, nearest upcoming first, then past", (
      tester,
    ) async {
      await setUpWith();
      await openAddForm(tester);
      await selectMember(tester, 'דנה');

      // "General" plus Dana's two appointments.
      final labels = await openAppointmentMenu(tester, count: 3);

      expect(labels, [
        AppStrings.noAppointmentOption,
        'ד״ר לוי · ${AppStrings.tomorrow} · 9:30',
        startsWith('ד״ר אברהם'),
      ]);
      expect(labels.last, endsWith('(${AppStrings.pastAppointmentSuffix})'));
      expect(labels.where((l) => l.contains('ד״ר מזרחי')), isEmpty);
    });

    testWidgets('asks for a member first, and explains when there are none', (
      tester,
    ) async {
      await setUpWith();
      await openAddForm(tester);

      expect(find.text(AppStrings.selectMemberFirst), findsOneWidget);
      expect(
        tester
            .widget<DropdownButtonFormField<String?>>(appointmentDropdown)
            .onChanged,
        isNull,
      );

      await selectMember(tester, 'אבי');
      expect(find.text(AppStrings.noAppointmentsForMember), findsOneWidget);
    });

    testWidgets('changing the member clears the appointment, with a note', (
      tester,
    ) async {
      await setUpWith();
      await openAddForm(tester);
      await selectMember(tester, 'דנה');
      await selectAppointment(tester, 'ד״ר לוי');

      await selectMember(tester, 'נועה');

      expect(selectedAppointmentText(AppStrings.noAppointmentOption), findsOne);
      expect(
        find.text(AppStrings.appointmentLinkClearedOnMemberChange),
        findsOneWidget,
      );
    });
  });

  group('validation', () {
    testWidgets('member and question text are required', (tester) async {
      await setUpWith();
      await openAddForm(tester);

      await tester.enterText(textField, '   ');
      await tapSave(tester);

      expect(find.text(AppStrings.memberRequired), findsOneWidget);
      expect(find.text(AppStrings.questionTextRequired), findsOneWidget);
      expect(questionRepository.addCalls, 0);
    });

    testWidgets('text and answer are limited in length', (tester) async {
      await setUpWith();
      await openAddForm(tester);

      await tester.enterText(textField, 'א' * 400);
      await tester.enterText(answerField, 'א' * 1200);

      expect(textOf(tester, textField), hasLength(300));
      expect(textOf(tester, answerField), hasLength(1000));
    });
  });

  group('edit', () {
    testWidgets('a card opens a pre-filled form', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'שאלה כללית קיימת');

      expect(find.text(AppStrings.editQuestionTitle), findsOneWidget);
      expect(textOf(tester, textField), 'שאלה כללית קיימת');
      expect(textOf(tester, answerField), 'תשובה קיימת');
      expect(tester.widget<SwitchListTile>(resolvedSwitch).value, isTrue);
      expect(
        find.descendant(of: memberDropdown, matching: find.text('דנה')),
        findsOneWidget,
      );
      expect(selectedAppointmentText(AppStrings.noAppointmentOption), findsOne);
    });

    testWidgets('a linked question shows its appointment', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'שאלה משויכת');

      expect(
        selectedAppointmentText('ד״ר לוי · ${AppStrings.tomorrow} · 9:30'),
        findsOneWidget,
      );
    });

    testWidgets('saving returns to the list, which shows the change', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'שאלה כללית קיימת');

      await tester.enterText(textField, 'נוסח מעודכן');
      await tapSave(tester);

      expect(find.byType(DoctorQuestionFormScreen), findsNothing);
      expect(find.widgetWithText(QuestionCard, 'נוסח מעודכן'), findsOneWidget);
      expect(
        tester.state<NavigatorState>(find.byType(Navigator)).canPop(),
        isFalse,
      );
      final saved = questionController.questionById('q2')!;
      expect(saved.createdAt, generalQuestion.createdAt);
      expect(saved.doctorAnswer, 'תשובה קיימת');
    });
  });

  group('moving a question to another member', () {
    testWidgets('a linked question asks first; cancel changes nothing', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'שאלה משויכת');

      await selectMember(tester, 'נועה');
      await tapSave(tester);

      expect(find.text(AppStrings.moveQuestionTitle('נועה')), findsOneWidget);
      expect(
        find.text(AppStrings.moveQuestionMessage('ד״ר לוי', 'דנה')),
        findsOneWidget,
      );

      await tester.tap(find.text(AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(find.byType(DoctorQuestionFormScreen), findsOneWidget);
      final stored = (await questionRepository.getById('q1'))!;
      expect(stored.memberId, 'm1');
      expect(stored.appointmentId, 'a1');
    });

    testWidgets('confirming moves it without the old appointment', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'שאלה משויכת');

      await selectMember(tester, 'נועה');
      await tapSave(tester);
      await tester.tap(find.text(AppStrings.moveAndSave));
      await tester.pumpAndSettle();

      expect(find.byType(DoctorQuestionFormScreen), findsNothing);
      final stored = (await questionRepository.getById('q1'))!;
      expect(stored.memberId, 'm2');
      expect(stored.appointmentId, isNull);
    });

    testWidgets('can be linked to an appointment of the new member', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'שאלה משויכת');

      await selectMember(tester, 'נועה');
      await selectAppointment(tester, 'ד״ר מזרחי');
      await tapSave(tester);
      await tester.tap(find.text(AppStrings.moveAndSave));
      await tester.pumpAndSettle();

      final stored = (await questionRepository.getById('q1'))!;
      expect(stored.memberId, 'm2');
      expect(stored.appointmentId, 'a2');
    });

    testWidgets('a general question moves without asking', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'שאלה כללית קיימת');

      await selectMember(tester, 'אבי');
      await tapSave(tester);

      expect(find.byType(AlertDialog), findsNothing);
      expect((await questionRepository.getById('q2'))!.memberId, 'm3');
    });
  });

  group('changes while the form is open', () {
    testWidgets('a deleted appointment is unlinked and explained', (
      tester,
    ) async {
      await setUpWith();
      await openEditForm(tester, 'שאלה משויכת');

      await appointmentController.delete('a1', userConfirmed: true);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text(AppStrings.linkedAppointmentDeletedWhileEditing),
        findsOneWidget,
      );
      expect(selectedAppointmentText(AppStrings.noAppointmentOption), findsOne);

      await tapSave(tester);
      expect(find.byType(DoctorQuestionFormScreen), findsNothing);
      final stored = (await questionRepository.getById('q1'))!;
      expect(stored.appointmentId, isNull);
      expect(stored.memberId, 'm1');
    });

    testWidgets('a deleted member is cleared, never replaced', (tester) async {
      await setUpWith();
      await openAddForm(tester);
      await selectMember(tester, 'נועה');
      await tester.enterText(textField, 'שאלה');

      await familyController.delete('m2', userConfirmed: true);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      await tapSave(tester);
      expect(find.text(AppStrings.memberRequired), findsOneWidget);
      expect(questionRepository.addCalls, 0);
    });

    testWidgets('a deleted question cannot be saved', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'שאלה כללית קיימת');
      await tester.enterText(textField, 'שינוי');

      await questionController.delete('q2', userConfirmed: true);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.questionDeletedWhileEditing), findsOneWidget);
      expect(tester.widget<FilledButton>(saveButton).onPressed, isNull);
      expect(questionRepository.updateCalls, 0);
    });

    testWidgets('an unknown question id shows the not-found state', (
      tester,
    ) async {
      await setUpWith();
      await tester.pumpApp(
        DoctorQuestionFormScreen(questionId: 'missing', clock: clock),
        dependencies: dependencies,
        familyController: familyController,
        appointmentController: appointmentController,
        doctorQuestionController: questionController,
      );

      expect(find.text(AppStrings.questionNotFoundTitle), findsOneWidget);
      expect(saveButton, findsNothing);
    });
  });

  group('saving', () {
    testWidgets('shows progress and ignores repeated taps', (tester) async {
      await setUpWith();
      await openAddForm(tester);
      await selectMember(tester, 'נועה');
      await tester.enterText(textField, 'שאלה');
      questionRepository.addGate = Completer<void>();

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
      expect(questionRepository.addCalls, 1);

      questionRepository.addGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(DoctorQuestionFormScreen), findsNothing);
    });

    testWidgets('a failed save keeps the draft, and a retry works', (
      tester,
    ) async {
      await setUpWith();
      await openAddForm(tester);
      await selectMember(tester, 'דנה');
      await tester.enterText(textField, 'טיוטה');
      await selectAppointment(tester, 'ד״ר לוי');
      await tester.enterText(answerField, 'הערה');
      questionRepository.failAdd = true;

      await tapSave(tester);

      expect(find.text(AppStrings.saveFailed), findsOneWidget);
      expect(textOf(tester, textField), 'טיוטה');
      expect(textOf(tester, answerField), 'הערה');
      expect(
        selectedAppointmentText('ד״ר לוי · ${AppStrings.tomorrow} · 9:30'),
        findsOneWidget,
      );

      questionRepository.failAdd = false;
      await tapSave(tester);
      expect(find.byType(DoctorQuestionFormScreen), findsNothing);
      expect(savedWithText('טיוטה').appointmentId, 'a1');
    });
  });

  group('leaving with unsaved changes', () {
    testWidgets('leaves immediately when nothing changed', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'שאלה משויכת');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.discardChangesTitle), findsNothing);
      expect(find.byType(DoctorQuestionFormScreen), findsNothing);
    });

    testWidgets('asks first; "keep editing" keeps the draft', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'שאלה משויכת');
      await tester.enterText(textField, 'שינוי');
      await tester.pump();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.discardChangesTitle), findsOneWidget);

      await tester.tap(find.text(AppStrings.keepEditing));
      await tester.pumpAndSettle();
      expect(textOf(tester, textField), 'שינוי');
    });

    testWidgets('"leave without saving" discards the changes', (tester) async {
      await setUpWith();
      await openEditForm(tester, 'שאלה משויכת');
      await tester.tap(resolvedSwitch);
      await tester.pump();

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.discardChanges));
      await tester.pumpAndSettle();

      expect(find.byType(DoctorQuestionFormScreen), findsNothing);
      expect((await questionRepository.getById('q1'))!.isResolved, isFalse);
    });
  });

  group('without family members', () {
    testWidgets('explains why and offers to add a member', (tester) async {
      await setUpWith(members: []);
      tester.setScreenSize(const Size(400, 1800));
      await tester.pumpApp(
        DoctorQuestionFormScreen(clock: clock),
        dependencies: dependencies,
        familyController: familyController,
        appointmentController: appointmentController,
        doctorQuestionController: questionController,
      );

      expect(find.text(AppStrings.noFamilyForQuestionTitle), findsOneWidget);
      expect(saveButton, findsNothing);

      await tester.tap(find.text(AppStrings.addFamilyMember));
      await tester.pumpAndSettle();
      expect(find.byType(MemberFormScreen), findsOneWidget);
    });
  });

  testWidgets('lays out without overflow on a narrow screen with large text '
      'and the keyboard open', (tester) async {
    await setUpWith();
    await openEditForm(tester, 'שאלה משויכת');
    await selectMember(tester, 'נועה');
    await tester.enterText(textField, '');
    await tapSave(tester);

    tester.setScreenSize(const Size(320, 568));
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetViewInsets);
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    await tester.drag(
      find.descendant(
        of: find.byType(DoctorQuestionFormScreen),
        matching: find.byType(ListView),
      ),
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(saveButton.hitTestable(), findsOneWidget);
  });
}
