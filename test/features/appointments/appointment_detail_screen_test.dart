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
import 'package:mydr/features/appointments/appointment_detail_screen.dart';
import 'package:mydr/features/appointments/appointments_screen.dart';
import 'package:mydr/features/appointments/widgets/appointment_card.dart';
import 'package:mydr/features/family/family_controller.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);
  DateTime clock() => now;

  final members = [
    FamilyMember(id: 'm1', name: 'דנה', relation: FamilyRelation.self),
  ];

  final fullAppointment = Appointment(
    id: 'full',
    memberId: 'm1',
    doctorName: 'ד״ר לוי',
    dateTime: DateTime(2026, 10, 15, 9, 30),
    specialty: 'רפואת משפחה',
    location: 'מרפאה שכונתית',
    notes: 'להביא סיכום ביקור קודם',
  );
  final sparseAppointment = Appointment(
    id: 'sparse',
    memberId: 'm1',
    doctorName: 'ד״ר כהן',
    dateTime: DateTime(2026, 9, 1, 8),
  );

  late FlakyAppointmentRepository appointmentRepository;
  late FamilyController familyController;
  late AppointmentController appointmentController;
  late AppDependencies dependencies;

  setUp(() async {
    appointmentRepository = FlakyAppointmentRepository([
      fullAppointment,
      sparseAppointment,
    ]);
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
    await familyController.load();
    await appointmentController.load();
  });

  tearDown(() {
    appointmentController.dispose();
    familyController.dispose();
  });

  Future<void> pumpList(WidgetTester tester) => tester.pumpApp(
    AppointmentsScreen(clock: clock),
    dependencies: dependencies,
    familyController: familyController,
    appointmentController: appointmentController,
  );

  /// Starts on the appointments list and pushes [appointmentId]'s details,
  /// so going back can be tested too.
  Future<void> openDetails(WidgetTester tester, String appointmentId) async {
    tester.setScreenSize(const Size(400, 1600));
    await pumpList(tester);
    tester
        .state<NavigatorState>(find.byType(Navigator))
        .push(AppointmentDetailScreen.route(appointmentId, clock: clock));
    await tester.pumpAndSettle();
  }

  MaterialLocalizations localizationsOf(WidgetTester tester) =>
      MaterialLocalizations.of(
        tester.element(find.byType(AppointmentDetailScreen)),
      );

  group('navigation', () {
    testWidgets('tapping a card opens that appointment', (tester) async {
      tester.setScreenSize(const Size(400, 1600));
      await pumpList(tester);

      await tester.tap(find.widgetWithText(AppointmentCard, 'ד״ר כהן'));
      await tester.pumpAndSettle();

      final screen = tester.widget<AppointmentDetailScreen>(
        find.byType(AppointmentDetailScreen),
      );
      expect(screen.appointmentId, 'sparse');
    });

    testWidgets('the back button returns to the list', (tester) async {
      await openDetails(tester, 'full');

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.byType(AppointmentDetailScreen), findsNothing);
      expect(find.byType(AppointmentCard), findsNWidgets(2));
    });
  });

  testWidgets('shows every detail of a complete appointment', (tester) async {
    await openDetails(tester, 'full');
    final localizations = localizationsOf(tester);

    // Doctor name: app bar, header and the details section.
    expect(find.text('ד״ר לוי'), findsNWidgets(3));
    expect(find.text('רפואת משפחה'), findsOneWidget);
    expect(find.text('דנה'), findsOneWidget);
    expect(
      find.text(localizations.formatFullDate(fullAppointment.dateTime)),
      findsOneWidget,
    );
    expect(find.text('9:30'), findsOneWidget);
    expect(find.text('${AppStrings.tomorrow} · 9:30'), findsOneWidget);
    expect(find.text('מרפאה שכונתית'), findsOneWidget);
    expect(find.text('להביא סיכום ביקור קודם'), findsOneWidget);
    expect(find.text(AppStrings.notSpecified), findsNothing);
    expect(find.byType(DemoDataBanner), findsOneWidget);
  });

  testWidgets('shows "not specified" for each missing optional field', (
    tester,
  ) async {
    await openDetails(tester, 'sparse');

    // Specialty, location and notes.
    expect(find.text(AppStrings.notSpecified), findsNWidgets(3));
  });

  group('upcoming or past', () {
    testWidgets('an upcoming appointment is marked as upcoming', (
      tester,
    ) async {
      await openDetails(tester, 'full');

      expect(find.text(AppStrings.appointmentStatusUpcoming), findsOneWidget);
      expect(find.text(AppStrings.appointmentStatusPast), findsNothing);
    });

    testWidgets('a past appointment is marked as past', (tester) async {
      await openDetails(tester, 'sparse');

      expect(find.text(AppStrings.appointmentStatusPast), findsOneWidget);
      expect(find.text(AppStrings.appointmentStatusUpcoming), findsNothing);
    });
  });

  testWidgets('an unknown family member does not break the screen', (
    tester,
  ) async {
    await appointmentRepository.add(
      Appointment(
        id: 'orphan',
        memberId: 'gone',
        doctorName: 'ד״ר יתום',
        dateTime: DateTime(2026, 11, 1, 10),
      ),
    );
    await appointmentController.load();
    await openDetails(tester, 'orphan');

    expect(find.text(AppStrings.unknownMember), findsOneWidget);
  });

  group('live updates', () {
    testWidgets('reflects changes to the appointment', (tester) async {
      await openDetails(tester, 'full');

      await appointmentController.update(
        fullAppointment.copyWith(
          doctorName: 'ד״ר לוי-כהן',
          location: () => null,
        ),
      );
      await tester.pump();

      expect(find.text('ד״ר לוי-כהן'), findsNWidgets(3));
      expect(find.text('מרפאה שכונתית'), findsNothing);
      expect(find.text(AppStrings.notSpecified), findsOneWidget);
    });

    testWidgets('reflects a renamed family member', (tester) async {
      await openDetails(tester, 'full');

      await familyController.update(members.first.copyWith(name: 'דנה כ.'));
      await tester.pump();

      expect(find.text('דנה כ.'), findsOneWidget);
    });
  });

  group('missing appointment', () {
    testWidgets('an unknown id shows a not-found state', (tester) async {
      await openDetails(tester, 'missing');

      expect(find.text(AppStrings.appointmentNotFoundTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('an appointment deleted while open shows not-found', (
      tester,
    ) async {
      await openDetails(tester, 'full');

      await appointmentController.delete('full', userConfirmed: true);
      await tester.pump();

      expect(find.text(AppStrings.appointmentNotFoundTitle), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the not-found state leads back to the list', (tester) async {
      await openDetails(tester, 'missing');

      await tester.tap(find.text(AppStrings.backToAppointments));
      await tester.pumpAndSettle();

      expect(find.byType(AppointmentDetailScreen), findsNothing);
      expect(find.byType(AppointmentsScreen), findsOneWidget);
    });

    testWidgets('shows progress instead of not-found while loading', (
      tester,
    ) async {
      tester.setScreenSize(const Size(400, 1600));
      final loadingController = AppointmentController(
        dependencies: dependencies,
        familyController: familyController,
      );
      addTearDown(loadingController.dispose);
      appointmentRepository.getAllGate = Completer<void>();
      unawaited(loadingController.load());

      await tester.pumpApp(
        AppointmentDetailScreen(appointmentId: 'full', clock: clock),
        dependencies: dependencies,
        familyController: familyController,
        appointmentController: loadingController,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(AppStrings.appointmentNotFoundTitle), findsNothing);

      appointmentRepository.getAllGate!.complete();
      await tester.pumpAndSettle();

      expect(find.text('להביא סיכום ביקור קודם'), findsOneWidget);
    });
  });

  testWidgets('section titles are marked as headers for screen readers', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await openDetails(tester, 'full');

    expect(
      tester.getSemantics(find.text(AppStrings.appointmentInfoSection)),
      matchesSemantics(
        label: AppStrings.appointmentInfoSection,
        isHeader: true,
      ),
    );
    semantics.dispose();
  });

  testWidgets('lays out without overflow on a narrow screen with large text', (
    tester,
  ) async {
    await appointmentController.update(
      fullAppointment.copyWith(
        doctorName: 'ד״ר עם שם ארוך מאוד לבדיקת פריסה',
        specialty: () => 'התמחות עם שם ארוך במיוחד',
        location: () => 'כתובת ארוכה מאוד של מרפאה לבדיקת שבירת שורות',
        notes: () => 'הערה ארוכה ' * 20,
      ),
    );
    await openDetails(tester, 'full');
    tester.setScreenSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await tester.pumpAndSettle();

    await tester.drag(
      find.descendant(
        of: find.byType(AppointmentDetailScreen),
        matching: find.byType(ListView),
      ),
      const Offset(0, -3000),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
