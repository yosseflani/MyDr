import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_symptom_repository.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';
import 'package:mydr/features/questions/doctor_question_form_screen.dart';
import 'package:mydr/features/questions/doctor_questions_screen.dart';
import 'package:mydr/features/questions/widgets/question_card.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';
import '../../helpers/question_finders.dart';

void main() {
  final now = DateTime(2026, 10, 15, 12);
  DateTime clock() => now;

  final members = [
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
  ];

  DoctorQuestion question(
    String text,
    String memberId,
    String? appointmentId,
    int minute, {
    bool resolved = false,
    String? answer,
  }) => DoctorQuestion(
    id: text,
    memberId: memberId,
    appointmentId: appointmentId,
    text: text,
    createdAt: now.add(Duration(minutes: minute)),
    isResolved: resolved,
    doctorAnswer: answer,
  );

  // m3 has no questions.
  final sampleQuestions = [
    question('שאלה ד', 'm1', 'a1', 4, resolved: true),
    question('שאלה ב', 'm1', null, 2),
    question('שאלה ג', 'm2', null, 3, resolved: true, answer: 'לחזור בעוד שנה'),
    question('שאלה א', 'm1', 'a1', 1),
  ];

  late FlakyFamilyRepository familyRepository;
  late FlakyDoctorQuestionRepository questionRepository;
  late AppDependencies dependencies;
  late FamilyController familyController;
  late AppointmentController appointmentController;
  late DoctorQuestionController questionController;

  Future<void> setUpWith(
    List<DoctorQuestion> questions, {
    bool loadQuestions = true,
  }) async {
    familyRepository = FlakyFamilyRepository(members);
    questionRepository = FlakyDoctorQuestionRepository(questions);
    dependencies = AppDependencies(
      familyRepository: familyRepository,
      appointmentRepository: FlakyAppointmentRepository(appointments),
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
    if (loadQuestions) await questionController.load();
  }

  Future<void> pumpScreen(WidgetTester tester, {String? initialMemberId}) {
    tester.setScreenSize(const Size(400, 2000));
    return tester.pumpApp(
      DoctorQuestionsScreen(initialMemberId: initialMemberId, clock: clock),
      dependencies: dependencies,
      familyController: familyController,
      appointmentController: appointmentController,
      doctorQuestionController: questionController,
    );
  }

  Finder card(String text) => find.widgetWithText(QuestionCard, text);

  Finder inCard(String cardText, String text) =>
      find.descendant(of: card(cardText), matching: find.text(text));

  /// Texts of the shown cards, top to bottom.
  List<String> shownQuestions(WidgetTester tester) {
    final cards = tester.widgetList<QuestionCard>(find.byType(QuestionCard));
    final byPosition = [
      for (final c in cards)
        (c.question.text, tester.getTopLeft(find.byWidget(c)).dy),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final (text, _) in byPosition) text];
  }

  double topOf(WidgetTester tester, String text) =>
      tester.getTopLeft(find.text(text)).dy;

  Future<void> tapChip(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(ChoiceChip, label));
    await tester.pumpAndSettle();
  }

  Future<void> tapStatus(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(SegmentedButton<QuestionStatusFilter>),
        matching: find.text(label),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapToggle(WidgetTester tester, String cardText) async {
    await tester.tap(
      find.descendant(of: card(cardText), matching: questionStatusToggle),
    );
  }

  group('display', () {
    testWidgets('shows the title, the demo notice and both groups in order', (
      tester,
    ) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester);

      expect(find.text(AppStrings.doctorQuestionsTitle), findsOneWidget);
      expect(find.byType(DemoDataBanner), findsOneWidget);
      expect(shownQuestions(tester), ['שאלה א', 'שאלה ב', 'שאלה ג', 'שאלה ד']);

      final unresolvedHeader = find.descendant(
        of: find.byType(ListView),
        matching: find.text(AppStrings.unresolvedQuestionsSection),
      );
      final resolvedHeader = find.descendant(
        of: find.byType(ListView),
        matching: find.text(AppStrings.resolvedQuestionsSection),
      );
      // Last match of each is the section header (the first is the filter).
      expect(
        tester.getTopLeft(unresolvedHeader.last).dy,
        lessThan(topOf(tester, 'שאלה א')),
      );
      expect(
        tester.getTopLeft(resolvedHeader.last).dy,
        greaterThan(topOf(tester, 'שאלה ב')),
      );
      expect(
        tester.getTopLeft(resolvedHeader.last).dy,
        lessThan(topOf(tester, 'שאלה ג')),
      );
    });

    testWidgets('a card shows member, status and linked appointment', (
      tester,
    ) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester);

      expect(inCard('שאלה א', 'דנה'), findsOneWidget);
      expect(
        inCard('שאלה א', AppStrings.questionStatusUnresolved),
        findsOneWidget,
      );
      expect(
        inCard('שאלה א', 'ד״ר לוי · ${AppStrings.tomorrow} · 9:30'),
        findsOneWidget,
      );
      expect(inCard('שאלה ב', AppStrings.generalQuestion), findsOneWidget);
      expect(
        inCard('שאלה ד', AppStrings.questionStatusResolved),
        findsOneWidget,
      );
    });

    testWidgets('a recorded answer is shown clearly', (tester) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester);

      expect(inCard('שאלה ג', AppStrings.recordedAnswerLabel), findsOneWidget);
      expect(inCard('שאלה ג', 'לחזור בעוד שנה'), findsOneWidget);
      expect(inCard('שאלה א', AppStrings.recordedAnswerLabel), findsNothing);
    });

    testWidgets('a question of a deleted appointment shows as general', (
      tester,
    ) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester);

      await appointmentController.delete('a1', userConfirmed: true);
      await tester.pumpAndSettle();

      expect(inCard('שאלה א', AppStrings.generalQuestion), findsOneWidget);
      expect(find.textContaining('ד״ר לוי'), findsNothing);
    });
  });

  group('filters', () {
    testWidgets('by family member, and back to everyone', (tester) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester);

      await tapChip(tester, 'נועה');
      expect(shownQuestions(tester), ['שאלה ג']);
      expect(find.text(AppStrings.noUnresolvedQuestions), findsOneWidget);

      await tapChip(tester, AppStrings.filterAllFamily);
      expect(shownQuestions(tester), hasLength(4));
    });

    testWidgets('opens filtered on the requested member', (tester) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester, initialMemberId: 'm2');

      expect(shownQuestions(tester), ['שאלה ג']);
    });

    testWidgets('by status', (tester) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester);

      await tapStatus(tester, AppStrings.unresolvedQuestionsSection);
      expect(shownQuestions(tester), ['שאלה א', 'שאלה ב']);

      await tapStatus(tester, AppStrings.resolvedQuestionsSection);
      expect(shownQuestions(tester), ['שאלה ג', 'שאלה ד']);

      await tapStatus(tester, AppStrings.questionsFilterAll);
      expect(shownQuestions(tester), hasLength(4));
    });

    testWidgets('member and status together', (tester) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester);

      await tapChip(tester, 'דנה');
      await tapStatus(tester, AppStrings.resolvedQuestionsSection);

      expect(shownQuestions(tester), ['שאלה ד']);
    });

    testWidgets('a member without questions gets a clear empty state', (
      tester,
    ) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester);

      await tapChip(tester, 'אבי');
      expect(find.text(AppStrings.questionsEmptyForMember('אבי')), findsOne);
      expect(find.byType(QuestionCard), findsNothing);

      await tester.tap(find.text(AppStrings.showAllFamily));
      await tester.pumpAndSettle();
      expect(shownQuestions(tester), hasLength(4));
    });

    testWidgets('resets safely when the chosen member is deleted', (
      tester,
    ) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester);
      await tapChip(tester, 'נועה');

      await familyController.delete('m2', userConfirmed: true);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(ChoiceChip, 'נועה'), findsNothing);
      expect(shownQuestions(tester), ['שאלה א', 'שאלה ב', 'שאלה ד']);
    });
  });

  group('copying', () {
    /// Captures what the app puts on the clipboard; [fail] makes the
    /// platform refuse instead.
    List<String> mockClipboard(WidgetTester tester, {bool fail = false}) {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method != 'Clipboard.setData') return null;
          if (fail) throw PlatformException(code: 'unavailable');
          copied.add((call.arguments as Map)['text'] as String);
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      return copied;
    }

    Future<void> tapCopy(WidgetTester tester, String cardText) async {
      await tester.tap(
        find.descendant(
          of: card(cardText),
          matching: find.byTooltip(AppStrings.copyQuestion),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('copies only the question text and confirms', (tester) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester);
      final copied = mockClipboard(tester);
      final before = await questionRepository.getById('שאלה ג');

      // Has a recorded answer and a member, neither of which is copied.
      await tapCopy(tester, 'שאלה ג');

      expect(copied, ['שאלה ג']);
      expect(find.text(AppStrings.questionCopied), findsOneWidget);
      // Neither opens the form nor changes the stored question.
      expect(find.byType(DoctorQuestionFormScreen), findsNothing);
      expect(questionRepository.updateCalls, 0);
      expect(await questionRepository.getById('שאלה ג'), before);
    });

    testWidgets('a clipboard failure explains and copies nothing', (
      tester,
    ) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester);
      final copied = mockClipboard(tester, fail: true);

      await tapCopy(tester, 'שאלה א');

      expect(copied, isEmpty);
      expect(find.text(AppStrings.questionCopyFailed), findsOneWidget);
      expect(find.text(AppStrings.questionCopied), findsNothing);
    });
  });

  group('changing the status', () {
    testWidgets('moves a question between the groups, both ways', (
      tester,
    ) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester);

      await tapToggle(tester, 'שאלה א');
      await tester.pumpAndSettle();

      expect(
        inCard('שאלה א', AppStrings.questionStatusResolved),
        findsOneWidget,
      );
      expect(shownQuestions(tester), ['שאלה ב', 'שאלה א', 'שאלה ג', 'שאלה ד']);
      expect((await questionRepository.getById('שאלה א'))!.isResolved, isTrue);

      await tapToggle(tester, 'שאלה א');
      await tester.pumpAndSettle();
      expect((await questionRepository.getById('שאלה א'))!.isResolved, isFalse);
    });

    testWidgets('keeps the recorded answer', (tester) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester);

      await tapToggle(tester, 'שאלה ג');
      await tester.pumpAndSettle();

      final stored = (await questionRepository.getById('שאלה ג'))!;
      expect(stored.isResolved, isFalse);
      expect(stored.doctorAnswer, 'לחזור בעוד שנה');
    });

    testWidgets('shows progress and ignores repeated taps while saving', (
      tester,
    ) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester);
      questionRepository.updateGate = Completer<void>();

      await tapToggle(tester, 'שאלה א');
      await tester.pump();

      expect(
        find.descendant(
          of: card('שאלה א'),
          matching: find.byType(CircularProgressIndicator),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card('שאלה א'), matching: questionStatusToggle),
        findsNothing,
      );
      // Still shown as not handled until the save completes.
      expect(
        inCard('שאלה א', AppStrings.questionStatusUnresolved),
        findsOneWidget,
      );

      questionRepository.updateGate!.complete();
      await tester.pumpAndSettle();

      expect(questionRepository.updateCalls, 1);
      expect(
        inCard('שאלה א', AppStrings.questionStatusResolved),
        findsOneWidget,
      );
    });

    testWidgets('a failure keeps the real status and explains', (tester) async {
      await setUpWith(sampleQuestions);
      await pumpScreen(tester);
      questionRepository.failUpdate = true;

      await tapToggle(tester, 'שאלה א');
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.questionUpdateFailed), findsOneWidget);
      expect(
        inCard('שאלה א', AppStrings.questionStatusUnresolved),
        findsOneWidget,
      );
      expect(shownQuestions(tester).first, 'שאלה א');
      expect(
        find.descendant(of: card('שאלה א'), matching: questionStatusToggle),
        findsOneWidget,
      );
    });
  });

  group('states', () {
    testWidgets('shows progress while loading', (tester) async {
      await setUpWith(sampleQuestions, loadQuestions: false);
      questionRepository.getAllGate = Completer<void>();
      unawaited(questionController.load());
      await pumpScreen(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(QuestionCard), findsNothing);

      questionRepository.getAllGate!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(QuestionCard), findsNWidgets(4));
    });

    testWidgets('shows an error with a working retry', (tester) async {
      await setUpWith(sampleQuestions, loadQuestions: false);
      questionRepository.failGetAll = true;
      await questionController.load();
      await pumpScreen(tester);

      expect(find.text(AppStrings.questionsLoadErrorTitle), findsOneWidget);

      questionRepository.failGetAll = false;
      await tester.tap(find.text(AppStrings.retry));
      await tester.pumpAndSettle();
      expect(find.byType(QuestionCard), findsNWidgets(4));
    });

    testWidgets('keeps the list and warns when a refresh fails', (
      tester,
    ) async {
      await setUpWith(sampleQuestions);
      questionRepository.failGetAll = true;
      await questionController.load();
      await pumpScreen(tester);

      expect(find.text(AppStrings.questionsRefreshError), findsOneWidget);
      expect(find.byType(QuestionCard), findsNWidgets(4));
    });

    testWidgets('shows the empty state when there are no questions', (
      tester,
    ) async {
      await setUpWith([]);
      await pumpScreen(tester);

      expect(find.text(AppStrings.questionsEmptyTitle), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
    });
  });

  testWidgets('updates when the controller changes', (tester) async {
    await setUpWith(sampleQuestions);
    await pumpScreen(tester);

    await questionController.add(question('שאלה חדשה', 'm3', null, 9));
    await tester.pump();

    expect(card('שאלה חדשה'), findsOneWidget);
  });

  testWidgets('the new question button opens the add form for the '
      'filtered member', (tester) async {
    await setUpWith(sampleQuestions);
    await pumpScreen(tester);
    await tapChip(tester, 'נועה');

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final form = tester.widget<DoctorQuestionFormScreen>(
      find.byType(DoctorQuestionFormScreen),
    );
    expect(form.questionId, isNull);
    expect(form.initialMemberId, 'm2');
  });

  testWidgets('tapping a card opens its edit form', (tester) async {
    await setUpWith(sampleQuestions);
    await pumpScreen(tester);

    await tester.tap(find.text('שאלה ב'));
    await tester.pumpAndSettle();

    final form = tester.widget<DoctorQuestionFormScreen>(
      find.byType(DoctorQuestionFormScreen),
    );
    expect(form.questionId, 'שאלה ב');
  });

  testWidgets('lays out without overflow on a narrow screen with large text', (
    tester,
  ) async {
    await setUpWith([
      ...sampleQuestions,
      question(
        'שאלה ארוכה מאוד ' * 8,
        'm2',
        null,
        5,
        resolved: true,
        answer: 'תשובה ארוכה מאוד ' * 8,
      ),
    ]);
    questionRepository.failGetAll = true;
    await questionController.load(); // Also shows the refresh warning.
    await pumpScreen(tester);
    tester.setScreenSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -4000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
