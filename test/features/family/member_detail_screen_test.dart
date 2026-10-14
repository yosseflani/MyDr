import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_appointment_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_doctor_question_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_symptom_repository.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/family_screen.dart';
import 'package:mydr/features/family/member_detail_screen.dart';
import 'package:mydr/features/family/widgets/member_card.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FlakyFamilyRepository repository;
  late FamilyController controller;

  final birthDate = () {
    final now = DateTime.now();
    return DateTime(now.year - 10, now.month, now.day);
  }();

  final fullMember = FamilyMember(
    id: 'full',
    name: 'נועה',
    relation: FamilyRelation.child,
    birthDate: birthDate,
    allergies: const ['אבקני פרחים', 'אגוזים'],
    chronicConditions: const ['מצב לדוגמה'],
    notes: 'הערה לדוגמה',
  );
  final sparseMember = FamilyMember(
    id: 'sparse',
    name: 'רחל',
    relation: FamilyRelation.grandparent,
  );

  setUp(() async {
    repository = FlakyFamilyRepository([fullMember, sparseMember]);
    controller = FamilyController(
      AppDependencies(
        familyRepository: repository,
        appointmentRepository: InMemoryAppointmentRepository(),
        doctorQuestionRepository: InMemoryDoctorQuestionRepository(),
        symptomRepository: InMemorySymptomRepository(),
      ),
    );
    await controller.load();
  });

  tearDown(() => controller.dispose());

  /// Starts on the family list and pushes the profile of [memberId], so the
  /// back navigation can be tested too.
  Future<void> openProfile(WidgetTester tester, String memberId) async {
    await tester.pumpApp(const FamilyScreen(), familyController: controller);
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(MemberDetailScreen.route(memberId));
    await tester.pumpAndSettle();
  }

  group('navigation', () {
    testWidgets('tapping a card opens that member\'s profile', (tester) async {
      await tester.pumpApp(const FamilyScreen(), familyController: controller);

      await tester.tap(find.widgetWithText(MemberCard, 'רחל'));
      await tester.pumpAndSettle();

      final screen = tester.widget<MemberDetailScreen>(
        find.byType(MemberDetailScreen),
      );
      expect(screen.memberId, 'sparse');
    });

    testWidgets('the back button returns to the family list', (tester) async {
      await openProfile(tester, 'full');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(MemberDetailScreen), findsNothing);
      expect(find.byType(MemberCard), findsNWidgets(2));
    });
  });

  testWidgets('shows all details of a complete profile', (tester) async {
    tester.setScreenSize(const Size(400, 1400));
    await openProfile(tester, 'full');

    final context = tester.element(find.byType(MemberDetailScreen));
    final formattedBirthDate = MaterialLocalizations.of(
      context,
    ).formatCompactDate(birthDate);

    // Name appears in the app bar and in the header.
    expect(find.text('נועה'), findsNWidgets(2));
    expect(find.text('ילד/ה · גיל 10'), findsOneWidget);
    expect(find.text(formattedBirthDate), findsOneWidget);
    expect(find.text('אבקני פרחים'), findsOneWidget);
    expect(find.text('אגוזים'), findsOneWidget);
    expect(find.text('מצב לדוגמה'), findsOneWidget);
    expect(find.text('הערה לדוגמה'), findsOneWidget);
    expect(find.text(AppStrings.notSpecified), findsNothing);
    expect(find.byType(DemoDataBanner), findsOneWidget);
  });

  testWidgets('shows "not specified" for every missing field', (tester) async {
    tester.setScreenSize(const Size(400, 1200));
    await openProfile(tester, 'sparse');

    // Relation only, since the age is unknown.
    expect(find.text('סבא/סבתא'), findsOneWidget);
    // Birth date, allergies, chronic conditions and notes.
    expect(find.text(AppStrings.notSpecified), findsNWidgets(4));
  });

  testWidgets('section titles are marked as headers for screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openProfile(tester, 'full');

    expect(
      tester.getSemantics(find.text(AppStrings.allergiesSection)),
      matchesSemantics(label: AppStrings.allergiesSection, isHeader: true),
    );
    semantics.dispose();
  });

  testWidgets('reflects edits made through the controller', (tester) async {
    await openProfile(tester, 'full');

    await controller.update(fullMember.copyWith(name: 'נועה ל.'));
    await tester.pump();

    expect(find.text('נועה ל.'), findsNWidgets(2));
  });

  group('missing profile', () {
    testWidgets('an unknown id shows a not-found state', (tester) async {
      await openProfile(tester, 'missing');

      expect(find.text(AppStrings.memberNotFoundTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a profile deleted while open shows the not-found state', (
      tester,
    ) async {
      await openProfile(tester, 'full');

      await controller.delete('full', userConfirmed: true);
      await tester.pump();

      expect(find.text(AppStrings.memberNotFoundTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the not-found state leads back to the family list', (
      tester,
    ) async {
      await openProfile(tester, 'missing');

      await tester.tap(find.text(AppStrings.backToFamily));
      await tester.pumpAndSettle();

      expect(find.byType(MemberDetailScreen), findsNothing);
      expect(find.byType(FamilyScreen), findsOneWidget);
    });

    testWidgets('shows progress instead of not-found while loading', (
      tester,
    ) async {
      tester.setScreenSize(const Size(400, 1400));
      final emptyController = FamilyController(
        AppDependencies(
          familyRepository: repository..getAllGate = Completer<void>(),
          appointmentRepository: InMemoryAppointmentRepository(),
          doctorQuestionRepository: InMemoryDoctorQuestionRepository(),
          symptomRepository: InMemorySymptomRepository(),
        ),
      );
      addTearDown(emptyController.dispose);
      unawaited(emptyController.load());

      await tester.pumpApp(
        const MemberDetailScreen(memberId: 'full'),
        familyController: emptyController,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(AppStrings.memberNotFoundTitle), findsNothing);

      repository.getAllGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('הערה לדוגמה'), findsOneWidget);
    });
  });

  testWidgets('the delete button stays clear of the system navigation bar', (
    tester,
  ) async {
    const systemBarHeight = 48.0;
    tester.setScreenSize(const Size(400, 800));
    tester.view.padding = const FakeViewPadding(bottom: systemBarHeight);
    addTearDown(tester.view.resetPadding);
    await openProfile(tester, 'full');

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    final buttonBottom = tester
        .getBottomLeft(find.text(AppStrings.deleteProfile))
        .dy;
    expect(buttonBottom, lessThan(800 - systemBarHeight));
  });

  testWidgets('lays out without overflow on a narrow screen with large text', (
    tester,
  ) async {
    tester.setScreenSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await controller.update(
      fullMember.copyWith(
        name: 'שם ארוך מאוד של בן משפחה לבדיקת פריסה',
        allergies: [...fullMember.allergies, 'אלרגיה עם שם ארוך במיוחד לבדיקה'],
        notes: () => 'הערה ארוכה ' * 20,
      ),
    );
    await openProfile(tester, 'full');

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
