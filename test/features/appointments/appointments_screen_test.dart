import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_symptom_repository.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/appointments/appointment_form_screen.dart';
import 'package:mydr/features/appointments/appointments_screen.dart';
import 'package:mydr/features/appointments/widgets/appointment_card.dart';
import 'package:mydr/features/family/family_controller.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);

  final members = [
    FamilyMember(id: 'm1', name: 'דנה', relation: FamilyRelation.self),
    FamilyMember(id: 'm2', name: 'נועה', relation: FamilyRelation.child),
    FamilyMember(id: 'm3', name: 'אבי', relation: FamilyRelation.spouse),
  ];

  Appointment appointment(
    String doctor,
    String memberId,
    Duration fromNow, {
    String? specialty,
    String? location,
  }) => Appointment(
    id: doctor,
    memberId: memberId,
    doctorName: doctor,
    dateTime: now.add(fromNow),
    specialty: specialty,
    location: location,
  );

  // m3 has no appointments.
  final sampleAppointments = [
    appointment('ד״ר ישן', 'm1', const Duration(days: -30)),
    appointment('ד״ר אתמול', 'm2', const Duration(days: -1)),
    appointment(
      'ד״ר היום',
      'm1',
      const Duration(minutes: 30),
      specialty: 'רפואת משפחה',
      location: 'מרפאה שכונתית',
    ),
    appointment('ד״ר מחר', 'm2', const Duration(days: 1)),
    appointment('ד״ר רחוק', 'm1', const Duration(days: 20)),
  ];

  late FlakyFamilyRepository familyRepository;
  late FlakyAppointmentRepository appointmentRepository;
  late FamilyController familyController;
  late AppointmentController appointmentController;
  late AppDependencies dependencies;

  void setUpWith(List<Appointment> appointments) {
    familyRepository = FlakyFamilyRepository(members);
    appointmentRepository = FlakyAppointmentRepository(appointments);
    dependencies = AppDependencies(
      familyRepository: familyRepository,
      appointmentRepository: appointmentRepository,
      doctorQuestionRepository: FlakyDoctorQuestionRepository(),
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
  }

  Future<void> loadAll() async {
    await familyController.load();
    await appointmentController.load();
  }

  Future<void> pumpScreen(WidgetTester tester) => tester.pumpApp(
    AppointmentsScreen(clock: () => now),
    dependencies: dependencies,
    familyController: familyController,
    appointmentController: appointmentController,
  );

  /// Doctor names of the shown cards, top to bottom.
  List<String> shownDoctors(WidgetTester tester) {
    final cards = tester.widgetList<AppointmentCard>(
      find.byType(AppointmentCard),
    );
    final byPosition = [
      for (final card in cards)
        (
          card.appointment.doctorName,
          tester.getTopLeft(find.byWidget(card)).dy,
        ),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final (name, _) in byPosition) name];
  }

  Future<void> selectFilter(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(ChoiceChip, label));
    await tester.pumpAndSettle();
  }

  group('sections and order', () {
    testWidgets('upcoming nearest first, then past most recent first', (
      tester,
    ) async {
      tester.setScreenSize(const Size(400, 2000));
      setUpWith(sampleAppointments);
      await loadAll();
      await pumpScreen(tester);

      expect(shownDoctors(tester), [
        'ד״ר היום',
        'ד״ר מחר',
        'ד״ר רחוק',
        'ד״ר אתמול',
        'ד״ר ישן',
      ]);

      final upcomingHeader = tester.getTopLeft(
        find.text(AppStrings.upcomingAppointmentsSection),
      );
      final pastHeader = tester.getTopLeft(
        find.text(AppStrings.pastAppointmentsSection),
      );
      final lastUpcoming = tester.getTopLeft(find.text('ד״ר רחוק'));
      final firstPast = tester.getTopLeft(find.text('ד״ר אתמול'));
      expect(upcomingHeader.dy, lessThan(lastUpcoming.dy));
      expect(pastHeader.dy, greaterThan(lastUpcoming.dy));
      expect(pastHeader.dy, lessThan(firstPast.dy));
    });

    testWidgets('a card shows doctor, specialty, member, date and location', (
      tester,
    ) async {
      setUpWith(sampleAppointments);
      await loadAll();
      await pumpScreen(tester);

      final card = find.widgetWithText(AppointmentCard, 'ד״ר היום');
      Finder inCard(String text) =>
          find.descendant(of: card, matching: find.text(text));

      expect(inCard('רפואת משפחה'), findsOneWidget);
      expect(inCard('דנה'), findsOneWidget);
      expect(inCard('${AppStrings.today} · 12:30'), findsOneWidget);
      expect(inCard('מרפאה שכונתית'), findsOneWidget);
    });

    testWidgets('missing specialty and location are left out', (tester) async {
      setUpWith([appointment('ד״ר מחר', 'm2', const Duration(days: 1))]);
      await loadAll();
      await pumpScreen(tester);

      final card = find.byType(AppointmentCard);
      final texts = tester
          .widgetList<Text>(
            find.descendant(of: card, matching: find.byType(Text)),
          )
          .map((t) => t.data);
      expect(texts, ['${AppStrings.tomorrow} · 12:00', 'ד״ר מחר', 'נועה']);
    });

    testWidgets('an appointment of an unknown member does not break', (
      tester,
    ) async {
      setUpWith([appointment('ד״ר מחר', 'gone', const Duration(days: 1))]);
      await loadAll();
      await pumpScreen(tester);

      expect(find.text(AppStrings.unknownMember), findsOneWidget);
    });

    testWidgets('shows a note when one section is empty', (tester) async {
      setUpWith([appointment('ד״ר ישן', 'm1', const Duration(days: -30))]);
      await loadAll();
      await pumpScreen(tester);

      expect(find.text(AppStrings.noUpcomingAppointments), findsOneWidget);
      expect(find.text(AppStrings.noPastAppointments), findsNothing);
      expect(find.byType(AppointmentCard), findsOneWidget);
    });

    testWidgets('shows the demo data notice', (tester) async {
      setUpWith(sampleAppointments);
      await loadAll();
      await pumpScreen(tester);

      expect(find.byType(DemoDataBanner), findsOneWidget);
    });
  });

  group('filter by family member', () {
    testWidgets('offers the whole family and every member', (tester) async {
      setUpWith(sampleAppointments);
      await loadAll();
      await pumpScreen(tester);

      expect(find.byType(ChoiceChip), findsNWidgets(4));
      final allChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, AppStrings.filterAllFamily),
      );
      expect(allChip.selected, isTrue);
    });

    testWidgets('shows only the chosen member, and back to everyone', (
      tester,
    ) async {
      tester.setScreenSize(const Size(400, 2000));
      setUpWith(sampleAppointments);
      await loadAll();
      await pumpScreen(tester);

      await selectFilter(tester, 'נועה');
      expect(shownDoctors(tester), ['ד״ר מחר', 'ד״ר אתמול']);

      await selectFilter(tester, AppStrings.filterAllFamily);
      expect(shownDoctors(tester), hasLength(5));
    });

    testWidgets('a member without appointments gets a clear empty state', (
      tester,
    ) async {
      setUpWith(sampleAppointments);
      await loadAll();
      await pumpScreen(tester);

      await selectFilter(tester, 'אבי');

      expect(find.text(AppStrings.appointmentsEmptyForMember('אבי')), findsOne);
      expect(find.byType(AppointmentCard), findsNothing);

      await tester.tap(find.text(AppStrings.showAllFamily));
      await tester.pumpAndSettle();
      expect(find.byType(AppointmentCard), findsWidgets);
    });

    testWidgets('resets safely when the chosen member is deleted', (
      tester,
    ) async {
      tester.setScreenSize(const Size(400, 2000));
      setUpWith(sampleAppointments);
      await loadAll();
      await pumpScreen(tester);
      await selectFilter(tester, 'נועה');

      await familyController.delete('m2', userConfirmed: true);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.widgetWithText(ChoiceChip, 'נועה'), findsNothing);
      final allChip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, AppStrings.filterAllFamily),
      );
      expect(allChip.selected, isTrue);
      // Noa's appointments were deleted with her; the rest are shown.
      expect(shownDoctors(tester), ['ד״ר היום', 'ד״ר רחוק', 'ד״ר ישן']);
    });
  });

  group('states', () {
    testWidgets('shows a progress indicator while loading', (tester) async {
      setUpWith(sampleAppointments);
      await familyController.load();
      appointmentRepository.getAllGate = Completer<void>();
      unawaited(appointmentController.load());
      await pumpScreen(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(AppointmentCard), findsNothing);

      appointmentRepository.getAllGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(AppointmentCard), findsWidgets);
    });

    testWidgets('shows the empty state when there are no appointments', (
      tester,
    ) async {
      setUpWith([]);
      await loadAll();
      await pumpScreen(tester);

      expect(find.text(AppStrings.appointmentsEmptyTitle), findsOneWidget);
      expect(find.text(AppStrings.upcomingAppointmentsSection), findsNothing);
    });

    testWidgets('shows an error with a working retry button', (tester) async {
      setUpWith(sampleAppointments);
      await familyController.load();
      appointmentRepository.failGetAll = true;
      await appointmentController.load();
      await pumpScreen(tester);

      expect(find.text(AppStrings.appointmentsLoadErrorTitle), findsOneWidget);

      appointmentRepository.failGetAll = false;
      await tester.tap(find.text(AppStrings.retry));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.appointmentsLoadErrorTitle), findsNothing);
      expect(find.byType(AppointmentCard), findsWidgets);
    });

    testWidgets('keeps the list and warns when a refresh fails', (
      tester,
    ) async {
      setUpWith(sampleAppointments);
      await loadAll();
      appointmentRepository.failGetAll = true;
      await appointmentController.load();
      await pumpScreen(tester);

      expect(find.text(AppStrings.appointmentsRefreshError), findsOneWidget);
      expect(find.byType(AppointmentCard), findsWidgets);
    });
  });

  testWidgets('updates when the controller changes', (tester) async {
    tester.setScreenSize(const Size(400, 2000));
    setUpWith(sampleAppointments);
    await loadAll();
    await pumpScreen(tester);

    await appointmentController.add(
      appointment('ד״ר חדש', 'm3', const Duration(days: 3)),
    );
    await tester.pump();
    expect(shownDoctors(tester), contains('ד״ר חדש'));

    await appointmentController.delete('ד״ר ישן', userConfirmed: true);
    await tester.pump();
    expect(shownDoctors(tester), isNot(contains('ד״ר ישן')));
  });

  group('new appointment button', () {
    testWidgets('opens the form in add mode', (tester) async {
      setUpWith(sampleAppointments);
      await loadAll();
      await pumpScreen(tester);

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final form = tester.widget<AppointmentFormScreen>(
        find.byType(AppointmentFormScreen),
      );
      expect(form.appointmentId, isNull);
      expect(form.initialMemberId, isNull);
    });

    testWidgets('preselects the member currently filtered on', (tester) async {
      setUpWith(sampleAppointments);
      await loadAll();
      await pumpScreen(tester);
      await selectFilter(tester, 'נועה');

      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      final form = tester.widget<AppointmentFormScreen>(
        find.byType(AppointmentFormScreen),
      );
      expect(form.initialMemberId, 'm2');
    });
  });

  testWidgets('lays out without overflow on a narrow screen with large text', (
    tester,
  ) async {
    tester.setScreenSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    setUpWith([
      ...sampleAppointments,
      appointment(
        'ד״ר עם שם ארוך מאוד לבדיקת פריסה',
        'm3',
        const Duration(days: 400),
        specialty: 'התמחות עם שם ארוך במיוחד',
        location: 'כתובת ארוכה מאוד של מרפאה לבדיקת שבירת שורות',
      ),
    ]);
    await loadAll();
    appointmentRepository.failGetAll = true;
    await appointmentController.load(); // Also shows the refresh warning.
    await pumpScreen(tester);

    await tester.drag(find.byType(ListView).first, const Offset(0, -3000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
