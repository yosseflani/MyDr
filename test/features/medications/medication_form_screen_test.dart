import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/not_found_view.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/reminders/reminder_scheduler.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_family_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_medication_repository.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/medications/medication_controller.dart';
import 'package:mydr/features/medications/medication_form_screen.dart';

import '../../helpers/fake_reminder_scheduler.dart';
import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 10, 22, 10);

  final memberA = FamilyMember(
    id: 'mA',
    name: 'דנה',
    relation: FamilyRelation.self,
  );
  final memberB = FamilyMember(
    id: 'mB',
    name: 'נועה',
    relation: FamilyRelation.child,
  );
  final medA = Medication(
    id: 'medA',
    memberId: 'mA',
    name: 'תרופה של דנה',
    dose: '1 tablet',
    reminderTimes: [DoseTime(8, 0)],
    startDate: DateTime(2026, 10, 20),
    endDate: DateTime(2026, 10, 27),
  );

  late FakeReminderScheduler scheduler;
  late AppDependencies dependencies;
  late FamilyController family;
  late MedicationController medications;

  Future<void> setUpWith({
    ReminderAvailability permission = ReminderAvailability.enabled,
  }) async {
    scheduler = FakeReminderScheduler(permission: permission);
    dependencies = AppDependencies(
      familyRepository: InMemoryFamilyRepository([memberA, memberB]),
      appointmentRepository: FlakyAppointmentRepository(),
      doctorQuestionRepository: FlakyDoctorQuestionRepository(),
      symptomRepository: FlakySymptomRepository(),
      medicationRepository: InMemoryMedicationRepository([medA]),
      reminderScheduler: scheduler,
    );
    family = FamilyController(dependencies);
    medications = MedicationController(
      dependencies: dependencies,
      familyController: family,
      clock: () => now,
    );
    addTearDown(medications.dispose);
    addTearDown(family.dispose);
    await family.load();
    await medications.load();
  }

  /// Opens the form from a first screen, so saving can return to it.
  Future<void> pumpForm(WidgetTester tester, Route<void> route) async {
    await tester.pumpApp(
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: TextButton(
              onPressed: () => Navigator.of(context).push(route),
              child: const Text('open'),
            ),
          ),
        ),
      ),
      dependencies: dependencies,
      familyController: family,
      medicationController: medications,
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Finder field(String label) => find.widgetWithText(TextFormField, label);
  final saveButton = find.widgetWithText(FilledButton, AppStrings.save);

  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  String ok(WidgetTester tester) => MaterialLocalizations.of(
    tester.element(find.byType(Scaffold).last),
  ).okButtonLabel;

  /// Adds the time picker's default time, 08:00.
  Future<void> addDefaultTime(WidgetTester tester) async {
    await scrollTo(tester, find.text(AppStrings.addReminderTime));
    await tester.tap(find.text(AppStrings.addReminderTime));
    await tester.pumpAndSettle();
    await tester.tap(find.text(ok(tester)));
    await tester.pumpAndSettle();
  }

  testWidgets('saving empty shows what is required and saves nothing', (
    tester,
  ) async {
    await setUpWith();
    await pumpForm(
      tester,
      MedicationFormScreen.addRoute(initialMemberId: 'mA'),
    );

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.medicationNameRequired), findsOneWidget);
    expect(find.text(AppStrings.doseRequired), findsOneWidget);
    await scrollTo(tester, find.text(AppStrings.reminderTimeRequired));
    expect(find.text(AppStrings.reminderTimeRequired), findsOneWidget);
    expect(medications.medicationsFor('mA'), [medA]);
  });

  testWidgets('adds a medication for the chosen member and asks for '
      'notification permission once', (tester) async {
    await setUpWith(permission: ReminderAvailability.disabled);
    await pumpForm(
      tester,
      MedicationFormScreen.addRoute(initialMemberId: 'mB'),
    );

    expect(find.text(AppStrings.medicationFormNotice), findsOneWidget);
    await tester.enterText(field(AppStrings.medicationNameLabel), ' סירופ ');
    await tester.enterText(field(AppStrings.doseLabel), '5 מ״ל');
    await addDefaultTime(tester);
    expect(find.widgetWithText(InputChip, '8:00'), findsOneWidget);

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final saved = medications.medicationsFor('mB').single;
    expect(saved.name, 'סירופ');
    expect(saved.dose, '5 מ״ל');
    expect(saved.reminderTimes, [DoseTime(8, 0)]);
    expect(saved.startDate, DateTime(2026, 10, 22));
    expect(saved.endDate, isNull);
    expect(find.byType(MedicationFormScreen), findsNothing);
    expect(scheduler.permissionRequests, 1);
    expect(medications.medicationsFor('mA'), [medA]);
  });

  testWidgets('the same time cannot be added twice', (tester) async {
    await setUpWith();
    await pumpForm(
      tester,
      MedicationFormScreen.addRoute(initialMemberId: 'mA'),
    );

    await addDefaultTime(tester);
    await addDefaultTime(tester);

    expect(find.text(AppStrings.reminderTimeDuplicate), findsOneWidget);
    expect(find.widgetWithText(InputChip, '8:00'), findsOneWidget);
  });

  testWidgets('an end date before the start date is refused', (tester) async {
    await setUpWith();
    await pumpForm(tester, MedicationFormScreen.editRoute('medA'));

    // Moves the start to October 28, after the end (October 27).
    final startField = find.byIcon(Icons.calendar_today_outlined);
    await scrollTo(tester, startField);
    await tester.tap(startField);
    await tester.pumpAndSettle();
    await tester.tap(find.text('28'));
    await tester.tap(find.text(ok(tester)));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text(AppStrings.endBeforeStart));
    expect(find.text(AppStrings.endBeforeStart), findsOneWidget);

    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(medications.medicationById('medA'), medA);
    expect(find.byType(MedicationFormScreen), findsOneWidget);
  });

  testWidgets('editing keeps the member fixed and can clear the end date', (
    tester,
  ) async {
    await setUpWith();
    await pumpForm(tester, MedicationFormScreen.editRoute('medA'));

    expect(find.text(AppStrings.medicationMemberFixed), findsOneWidget);
    expect(find.byType(DropdownButtonFormField<String>), findsNothing);

    await scrollTo(tester, find.byTooltip(AppStrings.clearEndDate));
    await tester.tap(find.byTooltip(AppStrings.clearEndDate));
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    final saved = medications.medicationById('medA')!;
    expect(saved.endDate, isNull);
    expect(saved.memberId, 'mA');
    // Editing never asks for permission.
    expect(scheduler.permissionRequests, 0);
  });

  testWidgets('a medication that no longer exists is reported', (tester) async {
    await setUpWith();
    await pumpForm(tester, MedicationFormScreen.editRoute('missing'));

    expect(find.byType(NotFoundView), findsOneWidget);
    expect(find.text(AppStrings.medicationNotFoundTitle), findsOneWidget);
  });

  testWidgets('lays out without overflow on a narrow screen with large text', (
    tester,
  ) async {
    await setUpWith();
    tester.setScreenSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpForm(tester, MedicationFormScreen.editRoute('medA'));

    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
