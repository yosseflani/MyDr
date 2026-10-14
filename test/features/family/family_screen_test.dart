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
import 'package:mydr/features/family/member_form_screen.dart';
import 'package:mydr/features/family/widgets/member_card.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FlakyFamilyRepository repository;
  late FamilyController controller;

  /// Born exactly [years] years before today, so the age is unambiguous.
  DateTime bornYearsAgo(int years) {
    final now = DateTime.now();
    return DateTime(now.year - years, now.month, now.day);
  }

  void setUpWith(List<FamilyMember> members) {
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
  }

  Future<void> pumpScreen(WidgetTester tester) =>
      tester.pumpApp(const FamilyScreen(), familyController: controller);

  final sampleMembers = [
    FamilyMember(
      id: 'm1',
      name: 'דנה',
      relation: FamilyRelation.self,
      birthDate: bornYearsAgo(38),
    ),
    FamilyMember(
      id: 'm2',
      name: 'איתי',
      relation: FamilyRelation.child,
      birthDate: bornYearsAgo(0),
    ),
    FamilyMember(id: 'm3', name: 'רחל', relation: FamilyRelation.grandparent),
  ];

  testWidgets('shows a card per member with relation and age', (tester) async {
    setUpWith(sampleMembers);
    await controller.load();
    await pumpScreen(tester);

    expect(find.text(AppStrings.familyTitle), findsOneWidget);
    expect(find.byType(MemberCard), findsNWidgets(3));
    expect(find.text('דנה'), findsOneWidget);
    expect(find.text('אני · גיל 38'), findsOneWidget);
    expect(find.text('ילד/ה · פחות משנה'), findsOneWidget);
    // No birth date: relation only, no age.
    expect(find.text('סבא/סבתא'), findsOneWidget);
  });

  testWidgets('shows the demo data notice', (tester) async {
    setUpWith(sampleMembers);
    await controller.load();
    await pumpScreen(tester);

    expect(find.byType(DemoDataBanner), findsOneWidget);
    expect(find.text(AppStrings.demoDataBanner), findsOneWidget);
  });

  testWidgets('updates when the controller changes', (tester) async {
    setUpWith(sampleMembers);
    await controller.load();
    await pumpScreen(tester);

    await controller.add(
      FamilyMember(id: 'm4', name: 'אבי', relation: FamilyRelation.spouse),
    );
    await tester.pump();

    expect(find.byType(MemberCard), findsNWidgets(4));
    expect(find.text('אבי'), findsOneWidget);
  });

  testWidgets('shows a progress indicator while loading', (tester) async {
    setUpWith(sampleMembers);
    repository.getAllGate = Completer<void>();
    unawaited(controller.load());
    await pumpScreen(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(MemberCard), findsNothing);

    repository.getAllGate!.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.byType(MemberCard), findsNWidgets(3));
  });

  testWidgets('shows the empty state when there are no members', (
    tester,
  ) async {
    setUpWith([]);
    await controller.load();
    await pumpScreen(tester);

    expect(find.text(AppStrings.familyEmptyTitle), findsOneWidget);
    expect(find.byType(MemberCard), findsNothing);
    expect(find.byType(DemoDataBanner), findsOneWidget);
  });

  testWidgets('shows an error with a working retry button', (tester) async {
    setUpWith(sampleMembers);
    repository.failGetAll = true;
    await controller.load();
    await pumpScreen(tester);

    expect(find.text(AppStrings.familyLoadErrorTitle), findsOneWidget);
    expect(find.byType(MemberCard), findsNothing);

    repository.failGetAll = false;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.familyLoadErrorTitle), findsNothing);
    expect(find.byType(MemberCard), findsNWidgets(3));
  });

  testWidgets('keeps the list and warns when a refresh fails', (tester) async {
    setUpWith(sampleMembers);
    await controller.load();
    repository.failGetAll = true;
    await controller.load();
    await pumpScreen(tester);

    expect(find.byType(MemberCard), findsNWidgets(3));
    expect(find.text(AppStrings.familyRefreshError), findsOneWidget);

    repository.failGetAll = false;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.familyRefreshError), findsNothing);
  });

  testWidgets('add button opens the form in add mode', (tester) async {
    setUpWith(sampleMembers);
    await controller.load();
    await pumpScreen(tester);

    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();

    final form = tester.widget<MemberFormScreen>(find.byType(MemberFormScreen));
    expect(form.memberId, isNull);
  });

  testWidgets('lays out without overflow on a narrow screen with large text', (
    tester,
  ) async {
    tester.setScreenSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    setUpWith([
      ...sampleMembers,
      FamilyMember(
        id: 'm5',
        name: 'שם ארוך מאוד של בן משפחה לבדיקה',
        relation: FamilyRelation.grandparent,
        birthDate: bornYearsAgo(75),
      ),
    ]);
    await controller.load();
    repository.failGetAll = true;
    await controller.load(); // Also shows the inline refresh warning.
    await pumpScreen(tester);

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
