import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/reminders/reminder_scheduler.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_family_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_medication_repository.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/medications/medication_controller.dart';

import '../../helpers/fake_reminder_scheduler.dart';
import '../../helpers/flaky_repositories.dart';

class _FlakyMedicationRepository extends InMemoryMedicationRepository {
  bool failGetAll = false;

  @override
  Future<List<Medication>> getAll({String? memberId}) async {
    if (failGetAll) throw const SimulatedFailure();
    return super.getAll(memberId: memberId);
  }
}

void main() {
  // Monday, October 19, 2026, 12:00.
  var now = DateTime(2026, 10, 19, 12);

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

  // Example A of the brief.
  Medication exampleA({String id = 'med1', String memberId = 'mA'}) =>
      Medication(
        id: id,
        memberId: memberId,
        name: 'תרופה $id',
        dose: '1 tablet',
        reminderTimes: [DoseTime(8, 0)],
        startDate: DateTime(2026, 10, 20),
        endDate: DateTime(2026, 10, 27),
      );

  late FakeReminderScheduler scheduler;
  late _FlakyMedicationRepository medicationRepository;
  late AppDependencies dependencies;
  late FamilyController family;
  late MedicationController controller;

  setUp(() async {
    now = DateTime(2026, 10, 19, 12);
    scheduler = FakeReminderScheduler();
    medicationRepository = _FlakyMedicationRepository();
    dependencies = AppDependencies(
      familyRepository: InMemoryFamilyRepository([memberA, memberB]),
      appointmentRepository: FlakyAppointmentRepository(),
      doctorQuestionRepository: FlakyDoctorQuestionRepository(),
      symptomRepository: FlakySymptomRepository(),
      medicationRepository: medicationRepository,
      reminderScheduler: scheduler,
    );
    family = FamilyController(dependencies);
    await family.load();
    controller = MedicationController(
      dependencies: dependencies,
      familyController: family,
      clock: () => now,
    );
    await controller.load();
  });

  tearDown(() {
    controller.dispose();
    family.dispose();
  });

  group('saving', () {
    test('adds a medication with tidied text', () async {
      final result = await controller.add(
        Medication(
          id: controller.createId(),
          memberId: 'mA',
          name: '  ויטמין   לדוגמה ',
          dose: ' 1 tablet ',
          instructions: '   ',
          reminderTimes: [DoseTime(8, 0)],
          startDate: DateTime(2026, 10, 20),
        ),
      );

      expect(result, MedicationSaveResult.success);
      final saved = controller.medications.single;
      expect(saved.name, 'ויטמין לדוגמה');
      expect(saved.dose, '1 tablet');
      expect(saved.instructions, isNull);
    });

    test(
      'refuses missing fields, no times and an end before the start',
      () async {
        final base = exampleA();
        expect(
          await controller.add(base.copyWith(name: ' ')),
          MedicationSaveResult.nameRequired,
        );
        expect(
          await controller.add(base.copyWith(dose: '')),
          MedicationSaveResult.doseRequired,
        );
        expect(
          await controller.add(base.copyWith(reminderTimes: [])),
          MedicationSaveResult.reminderTimeRequired,
        );
        expect(
          await controller.add(
            base.copyWith(
              reminderTimes: [for (var h = 0; h < 9; h++) DoseTime(h, 0)],
            ),
          ),
          MedicationSaveResult.tooManyReminderTimes,
        );
        expect(
          await controller.add(
            base.copyWith(endDate: () => DateTime(2026, 10, 19)),
          ),
          MedicationSaveResult.endBeforeStart,
        );
        expect(controller.medications, isEmpty);
      },
    );

    test(
      'an end date equal to the start date is a one-day treatment',
      () async {
        final result = await controller.add(
          exampleA().copyWith(endDate: () => DateTime(2026, 10, 20)),
        );
        expect(result, MedicationSaveResult.success);
      },
    );

    test('refuses a member that no longer exists', () async {
      expect(
        await controller.add(exampleA(memberId: 'gone')),
        MedicationSaveResult.memberNotFound,
      );
    });

    test('update edits the details and keeps the member', () async {
      await controller.add(exampleA());

      final result = await controller.update(
        'med1',
        name: 'שם חדש',
        dose: '2',
        instructions: 'בבוקר',
        reminderTimes: [DoseTime(9, 0), DoseTime(21, 0)],
        startDate: DateTime(2026, 10, 21),
        endDate: null,
      );

      expect(result, MedicationSaveResult.success);
      final saved = controller.medicationById('med1')!;
      expect(saved.memberId, 'mA');
      expect(saved.reminderTimes, [DoseTime(9, 0), DoseTime(21, 0)]);
      expect(saved.endDate, isNull);
      expect(
        await controller.update(
          'missing',
          name: 'n',
          dose: 'd',
          instructions: null,
          reminderTimes: [DoseTime(9, 0)],
          startDate: DateTime(2026, 10, 21),
          endDate: null,
        ),
        MedicationSaveResult.medicationNotFound,
      );
    });

    test('delete requires confirmation and removes its records', () async {
      await controller.add(exampleA());
      now = DateTime(2026, 10, 20, 9);
      await controller.recordDose(
        'med1',
        DateTime(2026, 10, 20, 8),
        DoseStatus.taken,
      );

      expect(
        () => controller.delete('med1', userConfirmed: false),
        throwsArgumentError,
      );
      expect(await controller.delete('med1', userConfirmed: true), isTrue);
      expect(controller.medications, isEmpty);
      expect(controller.records(), isEmpty);
      expect(await dependencies.doseRecordRepository.getAll(), isEmpty);
    });
  });

  group('doses', () {
    setUp(() async {
      await controller.add(exampleA());
      await controller.add(exampleA(id: 'medB', memberId: 'mB'));
      now = DateTime(2026, 10, 20, 9);
    });

    test('lists a member\'s doses within the treatment dates (example A)', () {
      expect(controller.dosesOn('mA', DateTime(2026, 10, 19)), isEmpty);
      expect(
        controller.dosesOn('mA', DateTime(2026, 10, 20)).map((d) => d.at),
        [DateTime(2026, 10, 20, 8)],
      );
      expect(controller.dosesOn('mA', DateTime(2026, 10, 28)), isEmpty);

      now = DateTime(2026, 10, 25, 9);
      expect(controller.upcomingDoses('mA').map((d) => d.at), [
        DateTime(2026, 10, 26, 8),
        DateTime(2026, 10, 27, 8),
      ]);
    });

    test("never mixes members' doses or records (example B)", () async {
      await controller.recordDose(
        'med1',
        DateTime(2026, 10, 20, 8),
        DoseStatus.taken,
      );

      expect(
        controller.dosesOn('mB', DateTime(2026, 10, 20)).single.medication.id,
        'medB',
      );
      expect(
        controller.dosesOn('mB', DateTime(2026, 10, 20)).single.record,
        isNull,
      );
      expect(controller.records(memberId: 'mB'), isEmpty);
      expect(controller.medicationsFor('mB').map((m) => m.id), ['medB']);
    });

    test(
      'marking the same dose again never duplicates it (example D)',
      () async {
        final at = DateTime(2026, 10, 20, 8);
        expect(
          await controller.recordDose('med1', at, DoseStatus.taken),
          DoseRecordResult.success,
        );
        expect(
          await controller.recordDose('med1', at, DoseStatus.taken),
          DoseRecordResult.success,
        );
        expect(controller.records(medicationId: 'med1'), hasLength(1));

        await controller.recordDose('med1', at, DoseStatus.skipped);
        expect(controller.records(medicationId: 'med1'), hasLength(1));
        expect(controller.recordFor('med1', at)!.status, DoseStatus.skipped);

        expect(await controller.clearDose('med1', at), isTrue);
        expect(controller.recordFor('med1', at), isNull);
      },
    );

    test('refuses doses that are not scheduled or on a later day', () async {
      expect(
        await controller.recordDose(
          'med1',
          DateTime(2026, 10, 20, 9),
          DoseStatus.taken,
        ),
        DoseRecordResult.notScheduled,
      );
      expect(
        await controller.recordDose(
          'med1',
          DateTime(2026, 10, 28, 8),
          DoseStatus.taken,
        ),
        DoseRecordResult.notScheduled,
      );
      expect(
        await controller.recordDose(
          'med1',
          DateTime(2026, 10, 21, 8),
          DoseStatus.taken,
        ),
        DoseRecordResult.inFuture,
      );
      expect(
        await controller.recordDose(
          'missing',
          DateTime(2026, 10, 20, 8),
          DoseStatus.taken,
        ),
        DoseRecordResult.medicationNotFound,
      );
      expect(controller.records(), isEmpty);
    });

    test("today's later dose may be recorded early", () async {
      final medication = exampleA(
        id: 'evening',
      ).copyWith(reminderTimes: [DoseTime(20, 0)]);
      await controller.add(medication);
      expect(
        await controller.recordDose(
          'evening',
          DateTime(2026, 10, 20, 20),
          DoseStatus.taken,
        ),
        DoseRecordResult.success,
      );
    });

    test('recent doses reach back a week, newest first', () async {
      now = DateTime(2026, 10, 23, 9);
      expect(controller.recentDoses('med1').map((d) => d.at), [
        DateTime(2026, 10, 23, 8),
        DateTime(2026, 10, 22, 8),
        DateTime(2026, 10, 21, 8),
        DateTime(2026, 10, 20, 8),
      ]);
    });

    test('editing keeps records of doses no longer scheduled', () async {
      final at = DateTime(2026, 10, 20, 8);
      await controller.recordDose('med1', at, DoseStatus.taken);

      await controller.update(
        'med1',
        name: 'תרופה med1',
        dose: '1 tablet',
        instructions: null,
        reminderTimes: [DoseTime(9, 0)],
        startDate: DateTime(2026, 10, 20),
        endDate: DateTime(2026, 10, 27),
      );

      expect(controller.records(medicationId: 'med1').single.scheduledAt, at);
    });
  });

  group('reminders', () {
    test('are rescheduled after every change, within the dates only '
        '(example A)', () async {
      await controller.add(exampleA());

      final scheduled = scheduler.scheduled.map((r) => r.at).toList();
      expect(scheduled, [
        for (var day = 20; day <= 27; day++) DateTime(2026, 10, day, 8),
      ]);
      expect(scheduled, isNot(contains(DateTime(2026, 10, 28, 8))));
      expect(
        controller.reminderStatus.plan!.lastReminderAt,
        DateTime(2026, 10, 27, 8),
      );
    });

    test('a recorded dose loses its reminder; clearing restores it', () async {
      await controller.add(exampleA());
      now = DateTime(2026, 10, 20, 7);
      final at = DateTime(2026, 10, 20, 8);

      await controller.recordDose('med1', at, DoseStatus.taken);
      expect(scheduler.scheduled.map((r) => r.at), isNot(contains(at)));

      await controller.clearDose('med1', at);
      expect(scheduler.scheduled.map((r) => r.at), contains(at));
    });

    test('editing and deleting reschedule', () async {
      await controller.add(exampleA());
      await controller.update(
        'med1',
        name: 'n',
        dose: 'd',
        instructions: null,
        reminderTimes: [DoseTime(9, 30)],
        startDate: DateTime(2026, 10, 20),
        endDate: DateTime(2026, 10, 21),
      );
      expect(scheduler.scheduled.map((r) => r.at), [
        DateTime(2026, 10, 20, 9, 30),
        DateTime(2026, 10, 21, 9, 30),
      ]);

      await controller.delete('med1', userConfirmed: true);
      expect(scheduler.scheduled, isEmpty);
    });

    test("deleting a member removes their reminders and data only "
        '(example B)', () async {
      await controller.add(exampleA());
      await controller.add(
        exampleA(
          id: 'medB',
          memberId: 'mB',
        ).copyWith(reminderTimes: [DoseTime(10, 0)]),
      );
      now = DateTime(2026, 10, 20, 12);
      await controller.recordDose(
        'med1',
        DateTime(2026, 10, 20, 8),
        DoseStatus.taken,
      );
      await controller.recordDose(
        'medB',
        DateTime(2026, 10, 20, 10),
        DoseStatus.skipped,
      );
      final summary = await family.relatedDataSummary('mA');
      expect(summary!.medications, 1);
      expect(summary.doseRecords, 1);

      final result = await family.delete('mA', userConfirmed: true);
      // The controller reloads on the family revision.
      await pumpEventQueue();

      expect(result.isSuccess, isTrue);
      expect(controller.medications.map((m) => m.id), ['medB']);
      expect(controller.records().map((r) => r.medicationId), ['medB']);
      expect(
        scheduler.scheduled.every((r) => r.at.hour == 10),
        isTrue,
        reason: "only B's 10:00 reminders remain",
      );
      expect(scheduler.scheduled, isNotEmpty);
    });

    test(
      'permission denied: everything else still works (example C)',
      () async {
        scheduler.permission = ReminderAvailability.disabled;
        await controller.refreshReminders();
        expect(
          controller.reminderStatus.availability,
          ReminderAvailability.disabled,
        );

        expect(await controller.add(exampleA()), MedicationSaveResult.success);
        now = DateTime(2026, 10, 20, 9);
        expect(
          await controller.recordDose(
            'med1',
            DateTime(2026, 10, 20, 8),
            DoseStatus.taken,
          ),
          DoseRecordResult.success,
        );
        expect(controller.reminderStatus.hasFailed, isFalse);
      },
    );

    test('asks for permission once, only when notifications are off', () async {
      await controller.askForPermissionOnce();
      expect(scheduler.permissionRequests, 0);

      scheduler
        ..permission = ReminderAvailability.disabled
        ..grantOnRequest = true;
      await controller.refreshReminders();
      await controller.askForPermissionOnce();
      await controller.askForPermissionOnce();

      expect(scheduler.permissionRequests, 1);
      expect(
        controller.reminderStatus.availability,
        ReminderAvailability.enabled,
      );
    });

    test('a scheduling failure is reported and never breaks saving', () async {
      scheduler.failReplace = true;

      expect(await controller.add(exampleA()), MedicationSaveResult.success);
      expect(controller.reminderStatus.hasFailed, isTrue);
      expect(controller.medications, hasLength(1));

      scheduler.failReplace = false;
      await controller.refreshReminders();
      expect(controller.reminderStatus.hasFailed, isFalse);
      expect(scheduler.scheduled, isNotEmpty);
    });

    test('a failing permission check is reported, not thrown', () async {
      scheduler.failAvailability = true;
      await controller.refreshReminders();
      expect(controller.reminderStatus.hasFailed, isTrue);
      expect(
        await controller.requestReminderPermission(),
        ReminderAvailability.unsupported,
      );
    });

    test('data that failed to load never replaces the reminders', () async {
      await controller.add(exampleA());
      final before = scheduler.replacements.length;

      medicationRepository.failGetAll = true;
      await controller.load();

      expect(controller.hasLoadError, isTrue);
      expect(scheduler.replacements, hasLength(before));
      expect(scheduler.scheduled, isNotEmpty);
    });

    test('refreshing reflects the passing of time', () async {
      await controller.add(exampleA());
      now = DateTime(2026, 10, 26, 9);
      await controller.refreshReminders();
      expect(scheduler.scheduled.map((r) => r.at), [DateTime(2026, 10, 27, 8)]);

      now = DateTime(2026, 10, 27, 9);
      await controller.refreshReminders();
      expect(scheduler.scheduled, isEmpty);
    });
  });
}
