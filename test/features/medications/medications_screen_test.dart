import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/reminders/reminder_scheduler.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_dose_record_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_family_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_medication_repository.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/member_detail_screen.dart';
import 'package:mydr/features/family/widgets/no_family_members_view.dart';
import 'package:mydr/features/medications/medication_controller.dart';
import 'package:mydr/features/medications/medication_detail_screen.dart';
import 'package:mydr/features/medications/medications_screen.dart';
import 'package:mydr/features/medications/widgets/delete_medication_dialog.dart';
import 'package:mydr/features/medications/widgets/dose_tile.dart';

import '../../helpers/fake_reminder_scheduler.dart';
import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  late DateTime now;

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

  // Example A of the brief, for member A; a different one for member B.
  final medA = Medication(
    id: 'medA',
    memberId: 'mA',
    name: 'תרופה של דנה',
    dose: '1 tablet',
    reminderTimes: [DoseTime(8, 0)],
    startDate: DateTime(2026, 10, 20),
    endDate: DateTime(2026, 10, 27),
  );
  final medB = Medication(
    id: 'medB',
    memberId: 'mB',
    name: 'סירופ של נועה',
    dose: '5 מ״ל',
    reminderTimes: [DoseTime(9, 0), DoseTime(19, 0)],
    startDate: DateTime(2026, 10, 1),
  );

  late FakeReminderScheduler scheduler;
  late InMemoryDoseRecordRepository doseRecords;
  late AppDependencies dependencies;
  late FamilyController family;
  late MedicationController medications;

  Future<void> setUpWith({
    List<FamilyMember>? members,
    List<Medication>? meds,
    List<DoseRecord> records = const [],
    ReminderAvailability permission = ReminderAvailability.enabled,
  }) async {
    now = DateTime(2026, 10, 22, 10);
    scheduler = FakeReminderScheduler(permission: permission);
    doseRecords = InMemoryDoseRecordRepository(records);
    dependencies = AppDependencies(
      familyRepository: InMemoryFamilyRepository(members ?? [memberA, memberB]),
      appointmentRepository: FlakyAppointmentRepository(),
      doctorQuestionRepository: FlakyDoctorQuestionRepository(),
      symptomRepository: FlakySymptomRepository(),
      medicationRepository: InMemoryMedicationRepository(meds ?? [medA, medB]),
      doseRecordRepository: doseRecords,
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

  Future<void> pumpScreen(WidgetTester tester, {String? memberId}) async {
    await tester.pumpApp(
      MedicationsScreen(initialMemberId: memberId),
      dependencies: dependencies,
      familyController: family,
      medicationController: medications,
    );
    await tester.pumpAndSettle();
  }

  /// Scrolls until [finder] is fully on screen, so it can be tapped.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
  }

  testWidgets("shows the selected member's data only (example B)", (
    tester,
  ) async {
    await setUpWith();
    await pumpScreen(tester);

    // Starts on the "self" profile.
    expect(find.textContaining(medA.name), findsWidgets);
    expect(find.textContaining(medB.name), findsNothing);

    await tester.tap(find.widgetWithText(ChoiceChip, memberB.name));
    await tester.pumpAndSettle();

    expect(find.textContaining(medB.name), findsWidgets);
    expect(find.textContaining(medA.name), findsNothing);
  });

  testWidgets('shows today and upcoming doses within the dates (example A)', (
    tester,
  ) async {
    await setUpWith();
    now = DateTime(2026, 10, 27, 7);
    await pumpScreen(tester);

    expect(find.text(AppStrings.todayDosesTitle), findsOneWidget);
    expect(find.byType(DoseTile), findsOneWidget);
    // October 27 is the last day: nothing upcoming, never October 28.
    await scrollTo(tester, find.text(AppStrings.upcomingDosesEmpty));
    expect(find.text(AppStrings.upcomingDosesEmpty), findsOneWidget);
  });

  testWidgets('recording a dose shows it and never duplicates it '
      '(example D)', (tester) async {
    await setUpWith();
    await pumpScreen(tester);

    final tile = find.byType(DoseTile);
    await tester.tap(
      find.descendant(of: tile, matching: find.text(AppStrings.markDoseTaken)),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.doseRecordedTaken), findsOneWidget);
    expect(
      find.descendant(of: tile, matching: find.byType(Chip)),
      findsOneWidget,
    );
    // The buttons are gone, so the dose cannot be marked twice.
    expect(
      find.descendant(of: tile, matching: find.byType(FilledButton)),
      findsNothing,
    );
    expect(await doseRecords.getAll(), hasLength(1));

    // Changing it keeps a single record.
    await tester.tap(find.byTooltip(AppStrings.doseActions));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.changeToSkipped));
    await tester.pumpAndSettle();

    final stored = await doseRecords.getAll();
    expect(stored, hasLength(1));
    expect(stored.single.status, DoseStatus.skipped);
  });

  testWidgets('with notifications off, explains it without blocking anything '
      '(example C)', (tester) async {
    await setUpWith(permission: ReminderAvailability.disabled);
    await pumpScreen(tester);

    expect(find.text(AppStrings.remindersDisabled), findsOneWidget);
    expect(find.text(AppStrings.actionAddMedication), findsOneWidget);

    // Recording still works.
    await scrollTo(tester, find.text(AppStrings.markDoseTaken));
    await tester.tap(find.text(AppStrings.markDoseTaken));
    await tester.pumpAndSettle();
    expect(await doseRecords.getAll(), hasLength(1));

    // Asking and being refused again points to the system settings.
    await tester.drag(find.byType(ListView).first, const Offset(0, 2000));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.enableReminders));
    await tester.pumpAndSettle();
    expect(scheduler.permissionRequests, 1);
    expect(
      find.textContaining(AppStrings.openNotificationSettingsHint),
      findsOneWidget,
    );
  });

  testWidgets('granting permission from the banner hides it', (tester) async {
    await setUpWith(permission: ReminderAvailability.disabled);
    scheduler.grantOnRequest = true;
    await pumpScreen(tester);

    await tester.tap(find.text(AppStrings.enableReminders));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.remindersDisabled), findsNothing);
    expect(find.textContaining(AppStrings.remindersPrivacy), findsOneWidget);
  });

  testWidgets('says how far ahead reminders are scheduled', (tester) async {
    await setUpWith();
    await pumpScreen(tester);

    expect(find.textContaining('התזכורות מתוזמנות עד'), findsOneWidget);
    expect(find.textContaining(AppStrings.remindersPrivacy), findsOneWidget);
    expect(find.text(AppStrings.remindersAreAnAid), findsOneWidget);
    expect(find.text(AppStrings.medicationsNoAdvice), findsOneWidget);
  });

  testWidgets('warns that reminders may be late, and asks for exact timing '
      'only on a tap', (tester) async {
    await setUpWith();
    scheduler.exactTiming = false;
    await medications.refreshReminders();
    await pumpScreen(tester);

    expect(find.textContaining(AppStrings.remindersMayBeLate), findsOneWidget);
    expect(find.textContaining(AppStrings.remindersPrivacy), findsOneWidget);
    expect(scheduler.exactTimingRequests, 0);

    // Back without allowing it: the warning stays and points to the
    // system settings.
    await tester.tap(find.text(AppStrings.allowExactReminders));
    await tester.pumpAndSettle();
    expect(scheduler.exactTimingRequests, 1);
    expect(
      find.textContaining(AppStrings.exactRemindersSettingsHint),
      findsOneWidget,
    );

    scheduler.grantExactOnRequest = true;
    await tester.tap(find.text(AppStrings.allowExactReminders));
    await tester.pumpAndSettle();
    expect(find.textContaining(AppStrings.remindersMayBeLate), findsNothing);
    expect(find.textContaining(AppStrings.remindersPrivacy), findsOneWidget);
  });

  testWidgets('no timing warning while no reminders are scheduled', (
    tester,
  ) async {
    await setUpWith(meds: const []);
    scheduler.exactTiming = false;
    await medications.refreshReminders();
    await pumpScreen(tester);

    expect(
      find.textContaining(AppStrings.remindersNoneScheduled),
      findsOneWidget,
    );
    expect(find.textContaining(AppStrings.remindersMayBeLate), findsNothing);
    expect(find.text(AppStrings.allowExactReminders), findsNothing);
  });

  testWidgets("the timing warning covers every member's reminders on the "
      'device', (tester) async {
    // Only member B has a medication; member A's page still warns, since
    // the setting delays every reminder on the device.
    await setUpWith(meds: [medB]);
    scheduler.exactTiming = false;
    await medications.refreshReminders();
    await pumpScreen(tester, memberId: 'mA');

    expect(find.textContaining(AppStrings.remindersMayBeLate), findsOneWidget);
    expect(find.textContaining(medB.name), findsNothing);
  });

  testWidgets('no timing warning while notifications are off', (tester) async {
    await setUpWith(permission: ReminderAvailability.disabled);
    scheduler.exactTiming = false;
    await medications.refreshReminders();
    await pumpScreen(tester);

    expect(find.text(AppStrings.remindersDisabled), findsOneWidget);
    expect(find.textContaining(AppStrings.remindersMayBeLate), findsNothing);
  });

  testWidgets('a scheduling failure is shown and can be retried', (
    tester,
  ) async {
    await setUpWith();
    scheduler.failReplace = true;
    await medications.refreshReminders();
    await pumpScreen(tester);

    expect(find.text(AppStrings.remindersFailed), findsOneWidget);
    scheduler.failReplace = false;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.remindersFailed), findsNothing);
  });

  testWidgets('on an unsupported platform says reminders are not shown', (
    tester,
  ) async {
    await setUpWith(permission: ReminderAvailability.unsupported);
    await pumpScreen(tester);
    expect(find.text(AppStrings.remindersUnsupported), findsOneWidget);
  });

  testWidgets('a member without medications sees an empty state', (
    tester,
  ) async {
    await setUpWith(meds: [medB]);
    await pumpScreen(tester, memberId: 'mA');
    expect(
      find.text(AppStrings.medicationsEmptyForMember(memberA.name)),
      findsOneWidget,
    );
  });

  testWidgets('without family members offers to add one', (tester) async {
    await setUpWith(members: const [], meds: const []);
    await pumpScreen(tester);
    expect(find.byType(NoFamilyMembersView), findsOneWidget);
  });

  testWidgets('details show the history; deleting asks first', (tester) async {
    await setUpWith(
      records: [
        DoseRecord(
          id: 'r1',
          memberId: 'mA',
          medicationId: 'medA',
          scheduledAt: DateTime(2026, 10, 21, 8),
          status: DoseStatus.taken,
          recordedAt: DateTime(2026, 10, 21, 8, 2),
        ),
      ],
    );
    await tester.pumpApp(
      const MedicationDetailScreen(medicationId: 'medA'),
      dependencies: dependencies,
      familyController: family,
      medicationController: medications,
    );
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text(AppStrings.doseCountSummary(1, 0)));
    expect(find.text(AppStrings.doseCountSummary(1, 0)), findsOneWidget);

    await scrollTo(tester, find.text(AppStrings.deleteMedication));
    await tester.tap(find.text(AppStrings.deleteMedication));
    await tester.pumpAndSettle();
    expect(find.byType(DeleteMedicationDialog), findsOneWidget);
    expect(find.text(AppStrings.deleteMedicationRecords(1)), findsOneWidget);

    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(medications.medicationById('medA'), isNotNull);

    await tester.tap(find.text(AppStrings.deleteMedication));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(DeleteMedicationDialog),
        matching: find.text(AppStrings.deleteMedication),
      ),
    );
    await tester.pumpAndSettle();

    expect(medications.medicationById('medA'), isNull);
    expect(await doseRecords.getAll(), isEmpty);
    expect(medications.medicationById('medB'), isNotNull);
  });

  testWidgets("a profile lists that member's active medications only", (
    tester,
  ) async {
    await setUpWith();
    await tester.pumpApp(
      const MemberDetailScreen(memberId: 'mB'),
      dependencies: dependencies,
      familyController: family,
      medicationController: medications,
    );
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text(AppStrings.memberMedicationsTitle));
    await scrollTo(tester, find.text(medB.name));
    expect(find.text(medB.name), findsOneWidget);
    expect(find.text(medA.name), findsNothing);
  });

  testWidgets('lays out without overflow on a narrow screen with large text', (
    tester,
  ) async {
    await setUpWith(permission: ReminderAvailability.disabled);
    tester.setScreenSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpScreen(tester, memberId: 'mB');

    for (var i = 0; i < 8; i++) {
      await tester.drag(find.byType(ListView).first, const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
