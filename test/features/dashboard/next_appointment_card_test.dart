import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_symptom_repository.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/appointments/appointment_detail_screen.dart';
import 'package:mydr/features/dashboard/widgets/next_appointment_card.dart';
import 'package:mydr/features/family/family_controller.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);
  DateTime clock() => now;

  final members = [
    FamilyMember(id: 'm1', name: 'דנה', relation: FamilyRelation.self),
    FamilyMember(id: 'm2', name: 'נועה', relation: FamilyRelation.child),
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

  late FlakyAppointmentRepository appointmentRepository;
  late FamilyController familyController;
  late AppointmentController appointmentController;
  late AppDependencies dependencies;

  Future<void> setUpWith(List<Appointment> appointments) async {
    appointmentRepository = FlakyAppointmentRepository(appointments);
    dependencies = AppDependencies(
      familyRepository: FlakyFamilyRepository(members),
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
    await familyController.load();
    await appointmentController.load();
  }

  Future<void> pumpCard(WidgetTester tester) {
    tester.setScreenSize(const Size(400, 1200));
    return tester.pumpApp(
      Scaffold(
        body: ListView(children: [NextAppointmentCard(clock: clock)]),
      ),
      dependencies: dependencies,
      familyController: familyController,
      appointmentController: appointmentController,
    );
  }

  /// Doctor names shown in the card, top to bottom.
  List<String> shownDoctors(WidgetTester tester, List<String> candidates) {
    final shown = [
      for (final name in candidates)
        if (find.text(name).evaluate().isNotEmpty)
          (name, tester.getTopLeft(find.text(name)).dy),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final (name, _) in shown) name];
  }

  final fiveAppointments = [
    appointment('ד״ר עבר', 'm1', const Duration(days: -1)),
    appointment('ד״ר 4', 'm1', const Duration(days: 9)),
    appointment('ד״ר 1', 'm1', const Duration(hours: 2)),
    appointment('ד״ר 3', 'm2', const Duration(days: 5)),
    appointment('ד״ר 2', 'm2', const Duration(days: 1)),
    appointment('ד״ר 5', 'm2', const Duration(days: 30)),
  ];
  const allDoctors = ['ד״ר עבר', 'ד״ר 1', 'ד״ר 2', 'ד״ר 3', 'ד״ר 4', 'ד״ר 5'];

  testWidgets('shows the three nearest upcoming appointments in order', (
    tester,
  ) async {
    await setUpWith(fiveAppointments);
    await pumpCard(tester);

    expect(shownDoctors(tester, allDoctors), ['ד״ר 1', 'ד״ר 2', 'ד״ר 3']);
    expect(find.text(AppStrings.moreUpcomingAppointments(2)), findsOneWidget);
  });

  testWidgets('each row shows when, the doctor and the member', (tester) async {
    await setUpWith([
      appointment(
        'ד״ר לוי',
        'm2',
        const Duration(days: 1),
        specialty: 'רפואת ילדים',
        location: 'מרפאה',
      ),
      appointment(
        'ד״ר כהן',
        'm1',
        const Duration(days: 2),
        location: 'מרפאה שכונתית',
      ),
    ]);
    await pumpCard(tester);

    expect(find.text('${AppStrings.tomorrow} · 12:00'), findsOneWidget);
    expect(find.text('ד״ר לוי'), findsOneWidget);
    // Specialty is preferred; otherwise the location.
    expect(find.text('נועה · רפואת ילדים'), findsOneWidget);
    expect(find.text('דנה · מרפאה שכונתית'), findsOneWidget);
    expect(find.textContaining('ועוד'), findsNothing);
  });

  testWidgets('shows a friendly empty state with only past appointments', (
    tester,
  ) async {
    await setUpWith([appointment('ד״ר עבר', 'm1', const Duration(days: -1))]);
    await pumpCard(tester);

    expect(find.text(AppStrings.nextAppointmentEmptyTitle), findsOneWidget);
    expect(find.text('ד״ר עבר'), findsNothing);
  });

  testWidgets('tapping an appointment opens its details', (tester) async {
    await setUpWith(fiveAppointments);
    await pumpCard(tester);

    await tester.tap(find.text('ד״ר 2'));
    await tester.pumpAndSettle();

    final screen = tester.widget<AppointmentDetailScreen>(
      find.byType(AppointmentDetailScreen),
    );
    expect(screen.appointmentId, 'ד״ר 2');
  });

  group('live updates', () {
    testWidgets('after adding, editing and deleting appointments', (
      tester,
    ) async {
      await setUpWith(fiveAppointments);
      await pumpCard(tester);

      await appointmentController.add(
        appointment('ד״ר חדש', 'm1', const Duration(minutes: 30)),
      );
      await tester.pump();
      expect(shownDoctors(tester, [...allDoctors, 'ד״ר חדש']), [
        'ד״ר חדש',
        'ד״ר 1',
        'ד״ר 2',
      ]);

      await appointmentController.update(
        appointmentController
            .appointmentById('ד״ר 1')!
            .copyWith(doctorName: 'ד״ר 1 מעודכן'),
      );
      await tester.pump();
      expect(find.text('ד״ר 1 מעודכן'), findsOneWidget);

      await appointmentController.delete('ד״ר חדש', userConfirmed: true);
      await tester.pump();
      expect(find.text('ד״ר חדש'), findsNothing);
      expect(find.text('ד״ר 3'), findsOneWidget);
    });

    testWidgets('after a family member is deleted', (tester) async {
      await setUpWith(fiveAppointments);
      await pumpCard(tester);

      await familyController.delete('m2', userConfirmed: true);
      await tester.pumpAndSettle();

      // Noa's appointments are gone; Dana's take their places.
      expect(shownDoctors(tester, allDoctors), ['ד״ר 1', 'ד״ר 4']);
      expect(find.textContaining('ועוד'), findsNothing);
    });
  });

  group('loading and errors', () {
    testWidgets('shows progress while loading', (tester) async {
      await setUpWith(fiveAppointments);
      final loading = AppointmentController(
        dependencies: dependencies,
        familyController: familyController,
      );
      addTearDown(loading.dispose);
      appointmentRepository.getAllGate = Completer<void>();
      unawaited(loading.load());

      tester.setScreenSize(const Size(400, 1200));
      await tester.pumpApp(
        Scaffold(
          body: ListView(children: [NextAppointmentCard(clock: clock)]),
        ),
        dependencies: dependencies,
        familyController: familyController,
        appointmentController: loading,
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      appointmentRepository.getAllGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text('ד״ר 1'), findsOneWidget);
    });

    testWidgets('shows an error with a working retry', (tester) async {
      await setUpWith(fiveAppointments);
      final failing = AppointmentController(
        dependencies: dependencies,
        familyController: familyController,
      );
      addTearDown(failing.dispose);
      appointmentRepository.failGetAll = true;
      await failing.load();

      tester.setScreenSize(const Size(400, 1200));
      await tester.pumpApp(
        Scaffold(
          body: ListView(children: [NextAppointmentCard(clock: clock)]),
        ),
        dependencies: dependencies,
        familyController: familyController,
        appointmentController: failing,
      );
      expect(find.text(AppStrings.appointmentsLoadErrorTitle), findsOneWidget);

      appointmentRepository.failGetAll = false;
      await tester.tap(find.text(AppStrings.retry));
      await tester.pumpAndSettle();
      expect(find.text('ד״ר 1'), findsOneWidget);
    });
  });

  testWidgets('lays out without overflow on a narrow screen with large text', (
    tester,
  ) async {
    await setUpWith([
      appointment(
        'ד״ר עם שם ארוך מאוד לבדיקת פריסה',
        'm2',
        const Duration(minutes: 30),
        specialty: 'התמחות עם שם ארוך במיוחד לבדיקה',
      ),
      ...fiveAppointments,
    ]);
    await pumpCard(tester);
    tester.setScreenSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -2000));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
