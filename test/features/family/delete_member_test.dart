import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/mock/mock_data.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_symptom_repository.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/family_screen.dart';
import 'package:mydr/features/family/member_detail_screen.dart';
import 'package:mydr/features/family/widgets/delete_member_dialog.dart';
import 'package:mydr/features/family/widgets/member_card.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);

  late FlakyFamilyRepository familyRepository;
  late FlakyAppointmentRepository appointmentRepository;
  late FlakyDoctorQuestionRepository questionRepository;
  late InMemorySymptomRepository symptomRepository;
  late FamilyController controller;

  setUp(() async {
    familyRepository = FlakyFamilyRepository(MockData.members());
    appointmentRepository = FlakyAppointmentRepository(
      MockData.appointments(now),
    );
    questionRepository = FlakyDoctorQuestionRepository(MockData.questions(now));
    symptomRepository = InMemorySymptomRepository(MockData.symptoms(now));
    controller = FamilyController(
      AppDependencies(
        familyRepository: familyRepository,
        appointmentRepository: appointmentRepository,
        doctorQuestionRepository: questionRepository,
        symptomRepository: symptomRepository,
      ),
    );
    await controller.load();
  });

  tearDown(() => controller.dispose());

  // Grandmother: 1 appointment, 2 questions, 0 symptoms.
  const grandmotherName = 'סבתא רחל';
  // Daughter: 1 appointment, 1 question, 1 symptom.
  const daughterName = 'נועה';

  final dialog = find.byType(DeleteMemberDialog);
  final confirmButton = find.descendant(
    of: dialog,
    matching: find.byType(FilledButton),
  );
  final cancelButton = find.widgetWithText(TextButton, AppStrings.cancel);

  /// Opens [memberName]'s profile from the family list and taps delete.
  Future<void> openDeleteDialog(WidgetTester tester, String memberName) async {
    tester.setScreenSize(const Size(400, 1600));
    await tester.pumpApp(const FamilyScreen(), familyController: controller);
    await tester.tap(find.widgetWithText(MemberCard, memberName));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.deleteProfile));
    await tester.pumpAndSettle();
  }

  /// The count shown next to [label] in the dialog, or null if not shown.
  String? countShownFor(WidgetTester tester, String label) {
    final labelFinder = find.descendant(of: dialog, matching: find.text(label));
    if (labelFinder.evaluate().isEmpty) return null;
    final row = find.ancestor(of: labelFinder, matching: find.byType(Row));
    final values = tester
        .widgetList<Text>(
          find.descendant(of: row.first, matching: find.byType(Text)),
        )
        .map((text) => text.data)
        .where((data) => data != label);
    return values.isEmpty ? null : values.single;
  }

  Future<RelatedDataSummary> storedSummary(String memberId) async =>
      (await controller.relatedDataSummary(memberId))!;

  bool isEnabled(WidgetTester tester, Finder button) =>
      tester.widget<ButtonStyleButton>(button).onPressed != null;

  testWidgets('the profile has a delete button that opens a dialog first', (
    tester,
  ) async {
    await openDeleteDialog(tester, grandmotherName);

    expect(dialog, findsOneWidget);
    expect(find.text(AppStrings.deleteDialogTitle(grandmotherName)), findsOne);
    expect(find.text(AppStrings.deleteIrreversible), findsOneWidget);
    // Nothing has been deleted yet.
    expect(controller.memberById(MockData.grandmotherId), isNotNull);
    expect(familyRepository.deleteCalls, 0);
  });

  testWidgets('shows how many records of each kind will be deleted', (
    tester,
  ) async {
    await openDeleteDialog(tester, grandmotherName);

    expect(countShownFor(tester, AppStrings.deleteItemAppointments), '1');
    expect(countShownFor(tester, AppStrings.deleteItemQuestions), '2');
    expect(countShownFor(tester, AppStrings.deleteItemSymptoms), '0');
    expect(
      find.descendant(
        of: dialog,
        matching: find.text(AppStrings.deleteItemProfile),
      ),
      findsOneWidget,
    );
  });

  testWidgets('cancel closes the dialog without changing anything', (
    tester,
  ) async {
    await openDeleteDialog(tester, grandmotherName);
    final before = await storedSummary(MockData.grandmotherId);

    await tester.tap(cancelButton);
    await tester.pumpAndSettle();

    expect(dialog, findsNothing);
    expect(find.byType(MemberDetailScreen), findsOneWidget);
    expect(controller.memberById(MockData.grandmotherId), isNotNull);
    final after = await storedSummary(MockData.grandmotherId);
    expect(after.appointments, before.appointments);
    expect(after.doctorQuestions, before.doctorQuestions);
    expect(familyRepository.deleteCalls, 0);
  });

  testWidgets('tapping outside the dialog does not close it', (tester) async {
    await openDeleteDialog(tester, grandmotherName);

    await tester.tapAt(const Offset(5, 5));
    await tester.pumpAndSettle();

    expect(dialog, findsOneWidget);
  });

  testWidgets('confirming deletes everything and returns to the list', (
    tester,
  ) async {
    await openDeleteDialog(tester, grandmotherName);

    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(dialog, findsNothing);
    expect(find.byType(MemberDetailScreen), findsNothing);
    expect(find.widgetWithText(MemberCard, grandmotherName), findsNothing);
    expect(find.text(AppStrings.deleteSucceeded(grandmotherName)), findsOne);
    expect(controller.memberById(MockData.grandmotherId), isNull);
    expect((await storedSummary(MockData.grandmotherId)).isEmpty, isTrue);
  });

  group('summary loading failure', () {
    testWidgets('shows no numbers and does not allow deleting', (tester) async {
      questionRepository.failGetAll = true;
      await openDeleteDialog(tester, grandmotherName);

      expect(find.text(AppStrings.deleteSummaryFailed), findsOneWidget);
      expect(countShownFor(tester, AppStrings.deleteItemAppointments), isNull);
      expect(isEnabled(tester, confirmButton), isFalse);

      await tester.tap(confirmButton, warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(familyRepository.deleteCalls, 0);
    });

    testWidgets('retrying the summary enables deleting', (tester) async {
      questionRepository.failGetAll = true;
      await openDeleteDialog(tester, grandmotherName);

      questionRepository.failGetAll = false;
      await tester.tap(find.text(AppStrings.retry));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.deleteSummaryFailed), findsNothing);
      expect(countShownFor(tester, AppStrings.deleteItemQuestions), '2');
      expect(isEnabled(tester, confirmButton), isTrue);
    });
  });

  group('deletion failure', () {
    testWidgets('explains the partial deletion and shows no success', (
      tester,
    ) async {
      questionRepository.failDeleteByMember = true;
      await openDeleteDialog(tester, daughterName);
      expect(countShownFor(tester, AppStrings.deleteItemSymptoms), '1');

      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(dialog, findsOneWidget);
      expect(find.text(AppStrings.deleteIncomplete), findsOneWidget);
      expect(find.text(AppStrings.deleteSucceeded(daughterName)), findsNothing);
      expect(controller.memberById(MockData.daughterId), isNotNull);
      // The counts show what is left: symptoms were already removed.
      expect(countShownFor(tester, AppStrings.deleteItemSymptoms), '0');
      expect(countShownFor(tester, AppStrings.deleteItemQuestions), '1');
      expect(
        find.descendant(
          of: confirmButton,
          matching: find.text(AppStrings.retryDelete),
        ),
        findsOneWidget,
      );
    });

    testWidgets('retrying completes the deletion', (tester) async {
      questionRepository.failDeleteByMember = true;
      await openDeleteDialog(tester, daughterName);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      questionRepository.failDeleteByMember = false;
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      expect(dialog, findsNothing);
      expect(find.byType(MemberDetailScreen), findsNothing);
      expect(find.text(AppStrings.deleteSucceeded(daughterName)), findsOne);
      expect(controller.memberById(MockData.daughterId), isNull);
      expect((await storedSummary(MockData.daughterId)).isEmpty, isTrue);
    });

    testWidgets('after cancelling, the profile warns the deletion is '
        'incomplete', (tester) async {
      questionRepository.failDeleteByMember = true;
      await openDeleteDialog(tester, daughterName);
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      expect(find.byType(MemberDetailScreen), findsOneWidget);
      expect(find.text(AppStrings.deletionIncompleteBanner), findsOneWidget);
    });
  });

  testWidgets('while deleting: shows progress, ignores repeated taps and '
      'cannot be closed', (tester) async {
    await openDeleteDialog(tester, grandmotherName);
    familyRepository.deleteGate = Completer<void>();

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
    expect(familyRepository.deleteCalls, 1);

    familyRepository.deleteGate!.complete();
    await tester.pumpAndSettle();

    expect(dialog, findsNothing);
    expect(find.byType(MemberDetailScreen), findsNothing);
    expect(familyRepository.deleteCalls, 1);
  });

  testWidgets('the dialog lays out without overflow on a narrow screen with '
      'large text', (tester) async {
    questionRepository.failDeleteByMember = true;
    await openDeleteDialog(tester, grandmotherName);
    tester.setScreenSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    // Show the failure message too, the dialog's tallest state.
    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text(AppStrings.deleteIncomplete), findsOneWidget);
  });
}
