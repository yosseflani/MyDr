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
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/member_detail_screen.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';
import 'package:mydr/features/questions/doctor_question_form_screen.dart';
import 'package:mydr/features/questions/doctor_questions_screen.dart';
import 'package:mydr/features/questions/widgets/delete_question_dialog.dart';
import 'package:mydr/features/questions/widgets/member_questions_section.dart';
import 'package:mydr/features/questions/widgets/question_card.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 10, 15, 12);
  DateTime clock() => now;

  final members = [
    FamilyMember(id: 'm1', name: 'דנה', relation: FamilyRelation.self),
    FamilyMember(id: 'm2', name: 'נועה', relation: FamilyRelation.child),
  ];

  final appointments = [
    Appointment(
      id: 'a1',
      memberId: 'm1',
      doctorName: 'ד״ר לוי',
      dateTime: DateTime(2026, 10, 16, 9, 30),
    ),
    Appointment(
      id: 'a2',
      memberId: 'm1',
      doctorName: 'ד״ר כהן',
      dateTime: DateTime(2026, 10, 20, 8),
    ),
  ];

  DoctorQuestion question(
    String text,
    String memberId,
    String? appointmentId,
    int minute, {
    bool resolved = false,
  }) => DoctorQuestion(
    id: text,
    memberId: memberId,
    appointmentId: appointmentId,
    text: text,
    createdAt: now.add(Duration(minutes: minute)),
    isResolved: resolved,
  );

  // Dana has four open questions (two linked to a1) and one handled one.
  final sampleQuestions = [
    question('פתוחה 1', 'm1', 'a1', 1),
    question('פתוחה 2', 'm1', null, 2),
    question('פתוחה 3', 'm1', 'a1', 3),
    question('פתוחה 4', 'm1', null, 4),
    question('שאלה שטופלה', 'm1', 'a1', 5, resolved: true),
    question('של נועה', 'm2', null, 6),
  ];

  late FlakyAppointmentRepository appointmentRepository;
  late FlakyDoctorQuestionRepository questionRepository;
  late AppDependencies dependencies;
  late FamilyController familyController;
  late AppointmentController appointmentController;
  late DoctorQuestionController questionController;

  setUp(() async {
    appointmentRepository = FlakyAppointmentRepository(appointments);
    questionRepository = FlakyDoctorQuestionRepository(sampleQuestions);
    dependencies = AppDependencies(
      familyRepository: FlakyFamilyRepository(members),
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
    await familyController.load();
    await appointmentController.load();
    await questionController.load();
  });

  tearDown(() {
    questionController.dispose();
    appointmentController.dispose();
    familyController.dispose();
  });

  Future<void> pump(WidgetTester tester, Widget screen) {
    tester.setScreenSize(const Size(400, 2400));
    return tester.pumpApp(
      screen,
      dependencies: dependencies,
      familyController: familyController,
      appointmentController: appointmentController,
      doctorQuestionController: questionController,
    );
  }

  Finder card(String text) => find.widgetWithText(QuestionCard, text);

  group('family member profile', () {
    final section = find.byType(MemberQuestionsSection);
    Finder inSection(String text) =>
        find.descendant(of: section, matching: find.text(text));

    testWidgets('shows the open count and up to three of them', (tester) async {
      await pump(tester, const MemberDetailScreen(memberId: 'm1'));

      expect(inSection(AppStrings.unresolvedQuestionsCount(4)), findsOne);
      for (final text in ['פתוחה 1', 'פתוחה 2', 'פתוחה 3']) {
        expect(inSection(text), findsOneWidget);
      }
      expect(inSection('פתוחה 4'), findsNothing);
      expect(inSection('שאלה שטופלה'), findsNothing);
      expect(inSection('של נועה'), findsNothing);
    });

    testWidgets('says so when nothing is open', (tester) async {
      await questionController.setResolved('של נועה', resolved: true);
      await pump(tester, const MemberDetailScreen(memberId: 'm2'));

      expect(inSection(AppStrings.unresolvedQuestionsCount(0)), findsOne);
    });

    testWidgets('"all questions" opens the list filtered to the member', (
      tester,
    ) async {
      await pump(tester, const MemberDetailScreen(memberId: 'm2'));

      await tester.tap(inSection(AppStrings.allQuestions));
      await tester.pumpAndSettle();

      final screen = tester.widget<DoctorQuestionsScreen>(
        find.byType(DoctorQuestionsScreen),
      );
      expect(screen.initialMemberId, 'm2');
      expect(card('של נועה'), findsOneWidget);
      expect(card('פתוחה 1'), findsNothing);
    });

    testWidgets('"new question" opens the form for the member', (tester) async {
      await pump(tester, const MemberDetailScreen(memberId: 'm2'));

      await tester.tap(inSection(AppStrings.newQuestion));
      await tester.pumpAndSettle();

      final form = tester.widget<DoctorQuestionFormScreen>(
        find.byType(DoctorQuestionFormScreen),
      );
      expect(form.initialMemberId, 'm2');
      expect(
        find.descendant(
          of: find.byType(DropdownButtonFormField<String>),
          matching: find.text('נועה'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('updates when a question is handled elsewhere', (tester) async {
      await pump(tester, const MemberDetailScreen(memberId: 'm1'));

      await questionController.setResolved('פתוחה 1', resolved: true);
      await tester.pump();

      expect(inSection(AppStrings.unresolvedQuestionsCount(3)), findsOne);
      expect(inSection('פתוחה 1'), findsNothing);
      expect(inSection('פתוחה 4'), findsOneWidget);
    });
  });

  group('appointment details', () {
    Future<void> openDetails(WidgetTester tester, String id) =>
        pump(tester, AppointmentDetailScreen(appointmentId: id, clock: clock));

    testWidgets('lists only the linked questions, with their status', (
      tester,
    ) async {
      await openDetails(tester, 'a1');

      expect(card('פתוחה 1'), findsOneWidget);
      expect(card('פתוחה 3'), findsOneWidget);
      expect(card('שאלה שטופלה'), findsOneWidget);
      expect(card('פתוחה 2'), findsNothing);
      expect(
        find.descendant(
          of: card('שאלה שטופלה'),
          matching: find.text(AppStrings.questionStatusResolved),
        ),
        findsOneWidget,
      );
    });

    testWidgets('says so when none are linked', (tester) async {
      await openDetails(tester, 'a2');

      expect(find.text(AppStrings.noQuestionsForAppointment), findsOneWidget);
      expect(find.byType(QuestionCard), findsNothing);
    });

    testWidgets('a question can be marked as handled there', (tester) async {
      await openDetails(tester, 'a1');

      await tester.tap(
        find.descendant(of: card('פתוחה 1'), matching: find.byType(IconButton)),
      );
      await tester.pumpAndSettle();

      expect(questionController.questionById('פתוחה 1')!.isResolved, isTrue);
      expect(
        find.descendant(
          of: card('פתוחה 1'),
          matching: find.text(AppStrings.questionStatusResolved),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a status change that fails keeps the real status', (
      tester,
    ) async {
      await openDetails(tester, 'a1');
      questionRepository.failUpdate = true;

      await tester.tap(
        find.descendant(of: card('פתוחה 1'), matching: find.byType(IconButton)),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.questionUpdateFailed), findsOneWidget);
      expect(
        find.descendant(
          of: card('פתוחה 1'),
          matching: find.text(AppStrings.questionStatusUnresolved),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a question opens for editing', (tester) async {
      await openDetails(tester, 'a1');

      await tester.tap(find.text('פתוחה 3'));
      await tester.pumpAndSettle();

      final form = tester.widget<DoctorQuestionFormScreen>(
        find.byType(DoctorQuestionFormScreen),
      );
      expect(form.questionId, 'פתוחה 3');
    });

    testWidgets('"add question" preselects the member and appointment, and '
        'the new question shows up', (tester) async {
      await openDetails(tester, 'a2');

      await tester.tap(find.text(AppStrings.addQuestionToAppointment));
      await tester.pumpAndSettle();

      final form = tester.widget<DoctorQuestionFormScreen>(
        find.byType(DoctorQuestionFormScreen),
      );
      expect(form.initialMemberId, 'm1');
      expect(form.initialAppointmentId, 'a2');

      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.questionTextLabel),
        'שאלה לתור של ד״ר כהן',
      );
      await tester.tap(find.widgetWithText(FilledButton, AppStrings.save));
      await tester.pumpAndSettle();

      expect(find.byType(AppointmentDetailScreen), findsOneWidget);
      expect(card('שאלה לתור של ד״ר כהן'), findsOneWidget);
      final added = questionController.questions.singleWhere(
        (q) => q.text == 'שאלה לתור של ד״ר כהן',
      );
      expect(added.appointmentId, 'a2');
      expect(added.memberId, 'm1');
    });

    testWidgets('deleting the appointment keeps its questions, as general', (
      tester,
    ) async {
      await openDetails(tester, 'a1');

      await appointmentController.delete('a1', userConfirmed: true);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text(AppStrings.appointmentNotFoundTitle), findsOneWidget);
      for (final id in ['פתוחה 1', 'פתוחה 3', 'שאלה שטופלה']) {
        final q = questionController.questionById(id)!;
        expect(q.appointmentId, isNull);
        expect(q.memberId, 'm1');
      }
    });
  });

  group('deleting a question', () {
    final dialog = find.byType(DeleteQuestionDialog);
    final confirmButton = find.descendant(
      of: dialog,
      matching: find.byType(FilledButton),
    );

    /// List → question → delete, as a user would get there.
    Future<void> openDeleteDialog(WidgetTester tester, String text) async {
      await pump(tester, DoctorQuestionsScreen(clock: clock));
      await tester.tap(find.text(text));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.deleteQuestion));
      await tester.pumpAndSettle();
    }

    testWidgets('only editing offers it', (tester) async {
      await pump(tester, DoctorQuestionFormScreen(clock: clock));
      expect(find.text(AppStrings.deleteQuestion), findsNothing);
    });

    testWidgets('asks first, showing the text and that it is permanent', (
      tester,
    ) async {
      await openDeleteDialog(tester, 'פתוחה 1');

      expect(
        find.descendant(of: dialog, matching: find.text('פתוחה 1')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.text(AppStrings.deleteIrreversible),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: dialog,
          matching: find.text(AppStrings.deleteQuestionKeepsOthers),
        ),
        findsOneWidget,
      );
      expect(questionRepository.deleteCalls, 0);
    });

    testWidgets('cancel keeps the question', (tester) async {
      await openDeleteDialog(tester, 'פתוחה 1');

      await tester.tap(find.widgetWithText(TextButton, AppStrings.cancel));
      await tester.pumpAndSettle();

      expect(dialog, findsNothing);
      expect(find.byType(DoctorQuestionFormScreen), findsOneWidget);
      expect(questionController.questionById('פתוחה 1'), isNotNull);
    });

    testWidgets('confirming deletes only the question and returns to the '
        'list', (tester) async {
      await openDeleteDialog(tester, 'פתוחה 1');

      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(find.byType(DoctorQuestionFormScreen), findsNothing);
      expect(find.byType(DoctorQuestionsScreen), findsOneWidget);
      expect(find.text(AppStrings.questionDeleted), findsOneWidget);
      expect(card('פתוחה 1'), findsNothing);
      expect(questionController.questionById('פתוחה 1'), isNull);
      // Its appointment and member are untouched.
      expect(await appointmentRepository.getById('a1'), isNotNull);
      expect(familyController.memberById('m1'), isNotNull);
      expect(questionController.forAppointment('a1'), hasLength(2));
    });

    testWidgets('a failure keeps the question, and a retry works', (
      tester,
    ) async {
      await openDeleteDialog(tester, 'פתוחה 1');
      questionRepository.failDelete = true;

      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(dialog, findsOneWidget);
      expect(
        find.descendant(
          of: dialog,
          matching: find.text(AppStrings.deleteQuestionFailed),
        ),
        findsOneWidget,
      );
      expect(questionController.questionById('פתוחה 1'), isNotNull);
      expect(find.text(AppStrings.questionDeleted), findsNothing);

      questionRepository.failDelete = false;
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(questionController.questionById('פתוחה 1'), isNull);
    });

    testWidgets('shows progress, ignores repeated taps and cannot be closed', (
      tester,
    ) async {
      await openDeleteDialog(tester, 'פתוחה 1');
      questionRepository.deleteGate = Completer<void>();

      await tester.tap(confirmButton);
      await tester.pump();

      expect(
        find.descendant(
          of: confirmButton,
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      await tester.tap(confirmButton, warnIfMissed: false);
      await tester.tapAt(const Offset(5, 5));
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(dialog, findsOneWidget);
      expect(questionRepository.deleteCalls, 1);

      questionRepository.deleteGate!.complete();
      await tester.pumpAndSettle();
      expect(dialog, findsNothing);
      expect(questionRepository.deleteCalls, 1);
    });
  });

  testWidgets('deleting a family member while the list is open removes '
      'their questions without errors', (tester) async {
    await pump(tester, DoctorQuestionsScreen(clock: clock));

    await familyController.delete('m2', userConfirmed: true);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(card('של נועה'), findsNothing);
    expect(card('פתוחה 1'), findsOneWidget);
  });
}
