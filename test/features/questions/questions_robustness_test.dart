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
import 'package:mydr/features/appointments/widgets/delete_appointment_dialog.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/member_detail_screen.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';
import 'package:mydr/features/questions/doctor_question_form_screen.dart';
import 'package:mydr/features/questions/doctor_questions_screen.dart';
import 'package:mydr/features/questions/widgets/member_questions_section.dart';
import 'package:mydr/features/questions/widgets/question_card.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

/// Edge cases across the questions feature: the same question changed from
/// several screens, navigating back mid-action, overlapping operations and
/// partial failures as seen in the UI, and long texts.
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
  ];

  DoctorQuestion question(String text, String? appointmentId, int minute) =>
      DoctorQuestion(
        id: text,
        memberId: 'm1',
        appointmentId: appointmentId,
        text: text,
        createdAt: now.add(Duration(minutes: minute)),
      );

  late FlakyAppointmentRepository appointmentRepository;
  late FlakyDoctorQuestionRepository questionRepository;
  late AppDependencies dependencies;
  late FamilyController familyController;
  late AppointmentController appointmentController;
  late DoctorQuestionController questionController;

  setUp(() async {
    appointmentRepository = FlakyAppointmentRepository(appointments);
    questionRepository = FlakyDoctorQuestionRepository([
      question('שאלה לתור', 'a1', 1),
      question('שאלה בלי תור', null, 2),
    ]);
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

  NavigatorState navigator(WidgetTester tester) =>
      tester.state<NavigatorState>(find.byType(Navigator));

  Finder card(String text) => find.widgetWithText(QuestionCard, text);
  Finder inCard(String cardText, String text) =>
      find.descendant(of: card(cardText), matching: find.text(text));
  Finder toggleOf(String text) =>
      find.descendant(of: card(text), matching: find.byType(IconButton));

  group('appointment line', () {
    const appointmentLine = 'ד״ר לוי · ${AppStrings.tomorrow} · 9:30';

    testWidgets('is shown in the questions list', (tester) async {
      await pump(tester, DoctorQuestionsScreen(clock: clock));

      expect(inCard('שאלה לתור', appointmentLine), findsOneWidget);
      expect(
        inCard('שאלה בלי תור', AppStrings.generalQuestion),
        findsOneWidget,
      );
    });

    testWidgets('is not repeated inside the appointment screen', (
      tester,
    ) async {
      await pump(
        tester,
        AppointmentDetailScreen(appointmentId: 'a1', clock: clock),
      );

      expect(card('שאלה לתור'), findsOneWidget);
      expect(inCard('שאלה לתור', appointmentLine), findsNothing);
      // Still shows who it is about and its status.
      expect(inCard('שאלה לתור', 'דנה'), findsOneWidget);
      expect(
        inCard('שאלה לתור', AppStrings.questionStatusUnresolved),
        findsOneWidget,
      );
    });
  });

  testWidgets('a status changed on the appointment screen shows on the list '
      'and the profile', (tester) async {
    await pump(tester, DoctorQuestionsScreen(clock: clock));
    navigator(tester).push(AppointmentDetailScreen.route('a1', clock: clock));
    await tester.pumpAndSettle();

    await tester.tap(toggleOf('שאלה לתור'));
    await tester.pumpAndSettle();
    navigator(tester).pop();
    await tester.pumpAndSettle();

    expect(
      inCard('שאלה לתור', AppStrings.questionStatusResolved),
      findsOneWidget,
    );

    navigator(tester).push(
      MaterialPageRoute<void>(
        builder: (_) => const MemberDetailScreen(memberId: 'm1'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(
        of: find.byType(MemberQuestionsSection),
        matching: find.text(AppStrings.unresolvedQuestionsCount(1)),
      ),
      findsOneWidget,
    );
  });

  group('navigating back mid-action', () {
    testWidgets('leaving while a status change is saving is safe', (
      tester,
    ) async {
      await pump(tester, DoctorQuestionsScreen(clock: clock));
      navigator(tester).push(AppointmentDetailScreen.route('a1', clock: clock));
      await tester.pumpAndSettle();
      questionRepository.updateGate = Completer<void>();

      await tester.tap(toggleOf('שאלה לתור'));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(find.byType(AppointmentDetailScreen), findsNothing);

      questionRepository.updateGate!.complete();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(questionController.questionById('שאלה לתור')!.isResolved, isTrue);
      expect(
        inCard('שאלה לתור', AppStrings.questionStatusResolved),
        findsOneWidget,
      );
    });

    testWidgets('a question form cannot be left while saving, and closes '
        'once when done', (tester) async {
      await pump(tester, DoctorQuestionsScreen(clock: clock));
      await tester.tap(find.text('שאלה בלי תור'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.questionTextLabel),
        'נוסח חדש',
      );
      questionRepository.updateGate = Completer<void>();

      await tester.tap(find.widgetWithText(FilledButton, AppStrings.save));
      await tester.pump();
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(DoctorQuestionFormScreen), findsOneWidget);
      expect(find.text(AppStrings.discardChangesTitle), findsNothing);

      questionRepository.updateGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(DoctorQuestionFormScreen), findsNothing);
      expect(find.byType(DoctorQuestionsScreen), findsOneWidget);
      expect(navigator(tester).canPop(), isFalse);
      expect(card('נוסח חדש'), findsOneWidget);
    });
  });

  testWidgets('an appointment deleted while a question is being added keeps '
      'everything consistent', (tester) async {
    await pump(tester, DoctorQuestionsScreen(clock: clock));
    questionRepository.addGate = Completer<void>();
    final adding = questionController.add(
      DoctorQuestion(
        id: 'new',
        memberId: 'm1',
        text: 'שאלה חדשה',
        createdAt: now.add(const Duration(minutes: 9)),
      ),
    );
    await tester.pump();

    // Meanwhile the appointment is deleted, which reloads the questions.
    await appointmentController.delete('a1', userConfirmed: true);
    await tester.pumpAndSettle();
    questionRepository.addGate!.complete();
    await adding;
    await tester.pumpAndSettle();

    expect(card('שאלה חדשה'), findsOneWidget);
    expect(inCard('שאלה לתור', AppStrings.generalQuestion), findsOneWidget);
    expect(questionController.questions, hasLength(3));
  });

  testWidgets('a partly failed appointment deletion is shown accurately on '
      'every screen', (tester) async {
    await pump(tester, DoctorQuestionsScreen(clock: clock));
    navigator(tester).push(AppointmentDetailScreen.route('a1', clock: clock));
    await tester.pumpAndSettle();
    appointmentRepository.failDelete = true;

    await tester.tap(find.text(AppStrings.deleteAppointment));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(DeleteAppointmentDialog),
        matching: find.byType(FilledButton),
      ),
    );
    await tester.pumpAndSettle();

    // The dialog explains it; the appointment remains, its question is
    // already unlinked, so it no longer appears under it.
    expect(
      find.text(AppStrings.deleteAppointmentPartiallyFailed('דנה')),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(TextButton, AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(AppointmentDetailScreen), findsOneWidget);
    expect(card('שאלה לתור'), findsNothing);
    expect(find.text(AppStrings.noQuestionsForAppointment), findsOneWidget);

    // On the list the question is kept, as a general question.
    navigator(tester).pop();
    await tester.pumpAndSettle();
    expect(inCard('שאלה לתור', AppStrings.generalQuestion), findsOneWidget);
  });

  testWidgets('the profile section offers a retry when questions failed to '
      'load', (tester) async {
    final failing = DoctorQuestionController(
      dependencies: dependencies,
      familyController: familyController,
      appointmentController: appointmentController,
    );
    addTearDown(failing.dispose);
    questionRepository.failGetAll = true;
    await failing.load();

    tester.setScreenSize(const Size(400, 2400));
    await tester.pumpApp(
      const MemberDetailScreen(memberId: 'm1'),
      dependencies: dependencies,
      familyController: familyController,
      appointmentController: appointmentController,
      doctorQuestionController: failing,
    );
    final section = find.byType(MemberQuestionsSection);
    expect(
      find.descendant(
        of: section,
        matching: find.text(AppStrings.questionsLoadErrorTitle),
      ),
      findsOneWidget,
    );

    questionRepository.failGetAll = false;
    await tester.tap(
      find.descendant(of: section, matching: find.text(AppStrings.retry)),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: section,
        matching: find.text(AppStrings.unresolvedQuestionsCount(2)),
      ),
      findsOneWidget,
    );
  });

  group('long texts on a narrow screen with large text', () {
    setUp(() async {
      final long = 'שאלה ארוכה מאוד על נושא שחשוב לשאול את הרופא ' * 4;
      await questionController.update(
        questionController
            .questionById('שאלה לתור')!
            .copyWith(text: long, doctorAnswer: () => 'תשובה ארוכה מאוד ' * 15),
      );
      await questionController.update(
        questionController.questionById('שאלה בלי תור')!.copyWith(text: long),
      );
    });

    Future<void> checkNoOverflow(WidgetTester tester, Widget screen) async {
      await pump(tester, screen);
      tester.setScreenSize(const Size(320, 568));
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();

      await tester.drag(find.byType(ListView).first, const Offset(0, -5000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    testWidgets('appointment screen with its questions', (tester) async {
      await checkNoOverflow(
        tester,
        AppointmentDetailScreen(appointmentId: 'a1', clock: clock),
      );
    });

    testWidgets('profile with its questions section', (tester) async {
      await checkNoOverflow(tester, const MemberDetailScreen(memberId: 'm1'));
    });
  });
}
