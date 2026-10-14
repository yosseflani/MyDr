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
import 'package:mydr/features/appointments/appointments_screen.dart';
import 'package:mydr/features/appointments/widgets/appointment_card.dart';
import 'package:mydr/features/appointments/widgets/delete_appointment_dialog.dart';
import 'package:mydr/features/family/family_controller.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);
  DateTime clock() => now;

  final members = [
    FamilyMember(id: 'm1', name: 'דנה', relation: FamilyRelation.self),
  ];

  // "linked" has two questions; "plain" has none.
  final linked = Appointment(
    id: 'linked',
    memberId: 'm1',
    doctorName: 'ד״ר לוי',
    dateTime: DateTime(2026, 10, 15, 9, 30),
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

  late FlakyAppointmentRepository appointmentRepository;
  late FlakyDoctorQuestionRepository questionRepository;
  late FamilyController familyController;
  late AppointmentController appointmentController;
  late AppDependencies dependencies;

  setUp(() async {
    appointmentRepository = FlakyAppointmentRepository([linked, plain]);
    questionRepository = FlakyDoctorQuestionRepository([
      question('q1'),
      question('q2'),
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
    await familyController.load();
    await appointmentController.load();
  });

  tearDown(() {
    appointmentController.dispose();
    familyController.dispose();
  });

  final dialog = find.byType(DeleteAppointmentDialog);
  final confirmButton = find.descendant(
    of: dialog,
    matching: find.byType(FilledButton),
  );
  final cancelButton = find.widgetWithText(TextButton, AppStrings.cancel);

  /// List → details → delete, as a user would get there.
  Future<void> openDeleteDialog(
    WidgetTester tester,
    String appointmentId,
  ) async {
    tester.setScreenSize(const Size(400, 1800));
    await tester.pumpApp(
      AppointmentsScreen(clock: clock),
      dependencies: dependencies,
      familyController: familyController,
      appointmentController: appointmentController,
    );
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(AppointmentDetailScreen.route(appointmentId, clock: clock));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.deleteAppointment));
    await tester.pumpAndSettle();
  }

  bool isEnabled(WidgetTester tester, Finder button) =>
      tester.widget<ButtonStyleButton>(button).onPressed != null;

  Future<DoctorQuestion> storedQuestion(String id) async =>
      (await questionRepository.getById(id))!;

  Finder inDialog(String text) =>
      find.descendant(of: dialog, matching: find.text(text));

  testWidgets('the details screen opens a confirmation dialog first', (
    tester,
  ) async {
    await openDeleteDialog(tester, 'linked');

    expect(dialog, findsOneWidget);
    expect(inDialog(AppStrings.deleteAppointmentTitle), findsOneWidget);
    expect(inDialog('ד״ר לוי'), findsOneWidget);
    expect(inDialog('${AppStrings.tomorrow} · 9:30'), findsOneWidget);
    expect(inDialog('דנה'), findsOneWidget);
    expect(inDialog(AppStrings.deleteIrreversible), findsOneWidget);
    expect(appointmentRepository.deleteCalls, 0);
  });

  group('linked questions', () {
    testWidgets('shows how many there are and that they are kept', (
      tester,
    ) async {
      await openDeleteDialog(tester, 'linked');

      expect(
        inDialog(AppStrings.deleteAppointmentQuestions(2, 'דנה')),
        findsOneWidget,
      );
    });

    testWidgets('says so when there are none', (tester) async {
      await openDeleteDialog(tester, 'plain');

      expect(inDialog(AppStrings.deleteAppointmentNoQuestions), findsOne);
    });

    testWidgets('while counting, shows progress and blocks deleting', (
      tester,
    ) async {
      questionRepository.getAllGate = Completer<void>();
      tester.setScreenSize(const Size(400, 1800));
      await tester.pumpApp(
        AppointmentsScreen(clock: clock),
        dependencies: dependencies,
        familyController: familyController,
        appointmentController: appointmentController,
      );
      tester
          .state<NavigatorState>(find.byType(Navigator))
          .push(AppointmentDetailScreen.route('linked', clock: clock));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.deleteAppointment));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(inDialog(AppStrings.deleteAppointmentQuestionsLoading), findsOne);
      expect(isEnabled(tester, confirmButton), isFalse);

      questionRepository.getAllGate!.complete();
      await tester.pumpAndSettle();

      expect(isEnabled(tester, confirmButton), isTrue);
    });

    testWidgets('if counting fails, shows no number and blocks deleting', (
      tester,
    ) async {
      questionRepository.failGetAll = true;
      await openDeleteDialog(tester, 'linked');

      expect(
        inDialog(AppStrings.deleteAppointmentQuestionsFailed),
        findsOneWidget,
      );
      expect(isEnabled(tester, confirmButton), isFalse);

      questionRepository.failGetAll = false;
      await tester.tap(find.text(AppStrings.retry));
      await tester.pumpAndSettle();

      expect(
        inDialog(AppStrings.deleteAppointmentQuestions(2, 'דנה')),
        findsOneWidget,
      );
      expect(isEnabled(tester, confirmButton), isTrue);
    });
  });

  group('cancel', () {
    testWidgets('closes the dialog without changing anything', (tester) async {
      await openDeleteDialog(tester, 'linked');

      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(dialog, findsNothing);
      expect(find.byType(AppointmentDetailScreen), findsOneWidget);
      expect(appointmentController.appointmentById('linked'), isNotNull);
      expect((await storedQuestion('q1')).appointmentId, 'linked');
      expect(appointmentRepository.deleteCalls, 0);
      expect(questionRepository.detachCalls, 0);
    });

    testWidgets('tapping outside does not close the dialog', (tester) async {
      await openDeleteDialog(tester, 'linked');

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(dialog, findsOneWidget);
    });
  });

  testWidgets('confirming deletes it, keeps the questions and returns to '
      'the list', (tester) async {
    await openDeleteDialog(tester, 'linked');

    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(dialog, findsNothing);
    expect(find.byType(AppointmentDetailScreen), findsNothing);
    expect(find.byType(AppointmentsScreen), findsOneWidget);
    expect(find.text(AppStrings.appointmentDeleted), findsOneWidget);
    expect(find.widgetWithText(AppointmentCard, 'ד״ר לוי'), findsNothing);
    expect(appointmentController.appointmentById('linked'), isNull);

    // The questions still exist, unlinked, with their original member.
    expect(await questionRepository.getAll(), hasLength(2));
    for (final id in ['q1', 'q2']) {
      final stored = await storedQuestion(id);
      expect(stored.appointmentId, isNull);
      expect(stored.memberId, 'm1');
    }
  });

  group('failures', () {
    testWidgets('if unlinking fails, nothing changed and a retry works', (
      tester,
    ) async {
      await openDeleteDialog(tester, 'linked');
      questionRepository.failDetach = true;

      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(dialog, findsOneWidget);
      expect(inDialog(AppStrings.deleteAppointmentFailed), findsOneWidget);
      expect(find.text(AppStrings.appointmentDeleted), findsNothing);
      expect(appointmentController.appointmentById('linked'), isNotNull);
      expect((await storedQuestion('q1')).appointmentId, 'linked');
      expect(
        find.descendant(
          of: confirmButton,
          matching: find.text(AppStrings.retryDelete),
        ),
        findsOneWidget,
      );

      questionRepository.failDetach = false;
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(dialog, findsNothing);
      expect(appointmentController.appointmentById('linked'), isNull);
    });

    testWidgets('a partial failure explains the questions were unlinked, not '
        'deleted, and a retry completes it', (tester) async {
      await openDeleteDialog(tester, 'linked');
      appointmentRepository.failDelete = true;

      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(dialog, findsOneWidget);
      expect(
        inDialog(AppStrings.deleteAppointmentPartiallyFailed('דנה')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.appointmentDeleted), findsNothing);
      // The appointment still exists; its questions were unlinked, not
      // deleted, and the count now reflects that.
      expect(appointmentController.appointmentById('linked'), isNotNull);
      expect(await questionRepository.getAll(), hasLength(2));
      expect((await storedQuestion('q1')).appointmentId, isNull);
      expect(inDialog(AppStrings.deleteAppointmentNoQuestions), findsOne);

      appointmentRepository.failDelete = false;
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(dialog, findsNothing);
      expect(find.byType(AppointmentDetailScreen), findsNothing);
      expect(appointmentController.appointmentById('linked'), isNull);
      expect(await questionRepository.getAll(), hasLength(2));
    });
  });

  testWidgets('while deleting: shows progress, ignores repeated taps and '
      'cannot be closed', (tester) async {
    await openDeleteDialog(tester, 'linked');
    appointmentRepository.deleteGate = Completer<void>();

    await tester.tap(confirmButton);
    await tester.pump();

    expect(
      find.descendant(
        of: confirmButton,
        matching: find.byType(CircularProgressIndicator),
      ),
      findsOneWidget,
    );
    expect(isEnabled(tester, confirmButton), isFalse);
    expect(isEnabled(tester, cancelButton), isFalse);

    await tester.tap(confirmButton, warnIfMissed: false);
    await tester.tapAt(const Offset(5, 5));
    await tester.binding.handlePopRoute(); // System back button.
    await tester.pump();

    expect(dialog, findsOneWidget);
    expect(appointmentRepository.deleteCalls, 1);

    appointmentRepository.deleteGate!.complete();
    await tester.pumpAndSettle();

    expect(dialog, findsNothing);
    expect(appointmentRepository.deleteCalls, 1);
    expect(appointmentController.appointmentById('linked'), isNull);
  });

  testWidgets('an appointment already deleted elsewhere is handled', (
    tester,
  ) async {
    await openDeleteDialog(tester, 'plain');

    await appointmentController.delete('plain', userConfirmed: true);
    await tester.pump();
    expect(tester.takeException(), isNull);

    // The details screen behind now shows "not found"; deleting again from
    // the open dialog is harmless.
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(dialog, findsNothing);
    expect(find.byType(AppointmentsScreen), findsOneWidget);
  });

  testWidgets('the delete button stays clear of the system navigation bar', (
    tester,
  ) async {
    const systemBarHeight = 48.0;
    tester.setScreenSize(const Size(400, 800));
    tester.view.padding = const FakeViewPadding(bottom: systemBarHeight);
    addTearDown(tester.view.resetPadding);
    await tester.pumpApp(
      AppointmentDetailScreen(appointmentId: 'linked', clock: clock),
      dependencies: dependencies,
      familyController: familyController,
      appointmentController: appointmentController,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    final buttonBottom = tester
        .getBottomLeft(find.text(AppStrings.deleteAppointment))
        .dy;
    expect(buttonBottom, lessThan(800 - systemBarHeight));
  });

  testWidgets('the dialog lays out without overflow on a narrow screen with '
      'large text', (tester) async {
    await openDeleteDialog(tester, 'linked');
    appointmentRepository.failDelete = true;
    tester.setScreenSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    // The partial-failure message is the dialog's tallest state.
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      inDialog(AppStrings.deleteAppointmentPartiallyFailed('דנה')),
      findsOneWidget,
    );
  });
}
