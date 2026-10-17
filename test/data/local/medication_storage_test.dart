import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:mydr/data/local/repositories/local_repository_support.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../helpers/memory_key_store.dart';

/// Medications and dose records against both repository implementations,
/// plus the database-only guarantees: constraints, migration from version 2
/// and keeping everything across a restart. Test data is fictional.
void main() {
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

  Medication medication(
    String id, {
    String memberId = 'mA',
    String name = 'תרופה',
    List<DoseTime>? times,
    DateTime? end,
  }) => Medication(
    id: id,
    memberId: memberId,
    name: name,
    dose: '1 tablet',
    instructions: 'אחרי האוכל',
    reminderTimes: times ?? [DoseTime(8, 0), DoseTime(20, 30)],
    startDate: DateTime(2026, 10, 20),
    endDate: end ?? DateTime(2026, 10, 27),
  );

  DoseRecord record(
    String id, {
    String medicationId = 'med1',
    String memberId = 'mA',
    int day = 21,
    int hour = 8,
    DoseStatus status = DoseStatus.taken,
    int recordedMinute = 3,
  }) => DoseRecord(
    id: id,
    memberId: memberId,
    medicationId: medicationId,
    scheduledAt: DateTime(2026, 10, day, hour),
    status: status,
    recordedAt: DateTime(2026, 10, day, hour, recordedMinute, 0, 0, 123),
  );

  final implementations =
      <String, Future<(AppDependencies, Future<void> Function())> Function()>{
        'in memory': () async => (AppDependencies.empty(), () async {}),
        'local database': () async {
          final directory = Directory.systemTemp.createTempSync(
            'mydr_medication_repo',
          );
          final database = await LocalDatabaseOpener(
            keyStore: MemoryDatabaseKeyStore(),
            locateFile: () async => File('${directory.path}/db.sqlite'),
          ).open();
          return (
            AppDependencies.local(database),
            () async {
              await database.close();
              directory.deleteSync(recursive: true);
            },
          );
        },
      };

  for (final MapEntry(key: name, value: create) in implementations.entries) {
    group('$name:', () {
      late AppDependencies deps;

      setUp(() async {
        final (created, dispose) = await create();
        deps = created;
        addTearDown(dispose);
        await deps.familyRepository.add(memberA);
        await deps.familyRepository.add(memberB);
      });

      test('adds, reads back exactly, and lists by name', () async {
        final repo = deps.medicationRepository;
        await repo.add(medication('med2', name: 'ב תרופה'));
        await repo.add(medication('med1', name: 'א תרופה'));
        await repo.add(
          medication(
            'med3',
            memberId: 'mB',
            name: 'ג',
            end: null,
          ).copyWith(endDate: () => null, instructions: () => null),
        );

        expect(await repo.getById('med1'), medication('med1', name: 'א תרופה'));
        expect((await repo.getById('med3'))!.endDate, isNull);
        expect((await repo.getAll()).map((m) => m.id), [
          'med1',
          'med2',
          'med3',
        ]);
        expect(await repo.getById('missing'), isNull);
        await expectLater(
          repo.add(medication('med1')),
          throwsA(isA<StateError>()),
        );
      });

      test("lists one member's medications only (example B)", () async {
        final repo = deps.medicationRepository;
        await repo.add(medication('med1'));
        await repo.add(medication('med2', memberId: 'mB'));

        expect((await repo.getAll(memberId: 'mA')).map((m) => m.id), ['med1']);
        expect((await repo.getAll(memberId: 'mB')).map((m) => m.id), ['med2']);
      });

      test('update saves the details but never moves the medication', () async {
        final repo = deps.medicationRepository;
        await repo.add(medication('med1'));
        final edited = Medication(
          id: 'med1',
          memberId: 'mB',
          name: 'שם חדש',
          dose: '2',
          reminderTimes: [DoseTime(9, 15)],
          startDate: DateTime(2026, 10, 21),
        );

        await repo.update(edited);

        final stored = (await repo.getById('med1'))!;
        expect(stored.memberId, 'mA');
        expect(stored.name, 'שם חדש');
        expect(stored.dose, '2');
        expect(stored.instructions, isNull);
        expect(stored.reminderTimes, [DoseTime(9, 15)]);
        expect(stored.startDate, DateTime(2026, 10, 21));
        expect(stored.endDate, isNull);
        await expectLater(
          repo.update(medication('missing')),
          throwsA(isA<StateError>()),
        );
      });

      test('a scheduled dose has one record; saving again replaces its '
          'status (example D)', () async {
        await deps.medicationRepository.add(medication('med1'));
        final repo = deps.doseRecordRepository;

        final first = await repo.save(record('r1'));
        expect(first, record('r1'));

        final again = await repo.save(
          record('r2', status: DoseStatus.skipped, recordedMinute: 9),
        );
        expect(again.id, 'r1');
        expect(again.status, DoseStatus.skipped);
        expect(again.recordedAt, DateTime(2026, 10, 21, 8, 9, 0, 0, 123));
        expect(await repo.getAll(), [again]);
      });

      test('records are listed newest first and filtered', () async {
        await deps.medicationRepository.add(medication('med1'));
        await deps.medicationRepository.add(medication('med2', memberId: 'mB'));
        final repo = deps.doseRecordRepository;
        await repo.save(record('r1', day: 21));
        await repo.save(record('r2', day: 22));
        await repo.save(record('r3', day: 21, hour: 20));
        await repo.save(record('r4', medicationId: 'med2', memberId: 'mB'));

        expect((await repo.getAll(memberId: 'mA')).map((r) => r.id), [
          'r2',
          'r3',
          'r1',
        ]);
        expect((await repo.getAll(medicationId: 'med2')).map((r) => r.id), [
          'r4',
        ]);
      });

      test('deleteOccurrence removes only that dose', () async {
        await deps.medicationRepository.add(medication('med1'));
        final repo = deps.doseRecordRepository;
        await repo.save(record('r1', day: 21));
        await repo.save(record('r2', day: 22));

        await repo.deleteOccurrence('med1', DateTime(2026, 10, 21, 8));
        await repo.deleteOccurrence('med1', DateTime(2026, 10, 23, 8));

        expect((await repo.getAll()).map((r) => r.id), ['r2']);
      });

      test(
        "deleting by member leaves the other member's data (example B)",
        () async {
          await deps.medicationRepository.add(medication('med1'));
          await deps.medicationRepository.add(
            medication('med2', memberId: 'mB'),
          );
          await deps.doseRecordRepository.save(record('r1'));
          await deps.doseRecordRepository.save(
            record('r2', medicationId: 'med2', memberId: 'mB'),
          );

          await deps.doseRecordRepository.deleteByMember('mA');
          await deps.medicationRepository.deleteByMember('mA');

          expect((await deps.medicationRepository.getAll()).map((m) => m.id), [
            'med2',
          ]);
          expect((await deps.doseRecordRepository.getAll()).map((r) => r.id), [
            'r2',
          ]);
        },
      );

      test('deleting by medication removes only its records', () async {
        await deps.medicationRepository.add(medication('med1'));
        await deps.medicationRepository.add(medication('med2'));
        await deps.doseRecordRepository.save(record('r1'));
        await deps.doseRecordRepository.save(
          record('r2', medicationId: 'med2'),
        );

        await deps.doseRecordRepository.deleteByMedication('med1');
        await deps.medicationRepository.delete('med1');

        expect(await deps.medicationRepository.getById('med1'), isNull);
        expect((await deps.doseRecordRepository.getAll()).map((r) => r.id), [
          'r2',
        ]);
      });
    });
  }

  group('local database guarantees', () {
    late Directory directory;
    late File file;
    late MemoryDatabaseKeyStore keys;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('mydr_medication_db');
      file = File('${directory.path}/${LocalDatabaseOpener.fileName}');
      keys = MemoryDatabaseKeyStore();
    });

    tearDown(() => directory.deleteSync(recursive: true));

    Future<LocalDatabase> open() => LocalDatabaseOpener(
      keyStore: keys,
      locateFile: () async => file,
    ).open();

    Future<AppDependencies> seeded(LocalDatabase database) async {
      final deps = AppDependencies.local(database);
      await deps.familyRepository.add(memberA);
      await deps.familyRepository.add(memberB);
      return deps;
    }

    Matcher rejected() => throwsA(
      isA<LocalDataException>().having(
        (e) => e.error,
        'error',
        LocalDataError.rejected,
      ),
    );

    test('an end date before the start date is refused', () async {
      final database = await open();
      addTearDown(database.close);
      final deps = await seeded(database);

      await expectLater(
        deps.medicationRepository.add(
          medication('med1', end: DateTime(2026, 10, 19)),
        ),
        rejected(),
      );
      expect(await deps.medicationRepository.getAll(), isEmpty);
    });

    test('a medication needs an existing member and a reminder time', () async {
      final database = await open();
      addTearDown(database.close);
      final deps = await seeded(database);

      await expectLater(
        deps.medicationRepository.add(medication('med1', memberId: 'gone')),
        rejected(),
      );
      await expectLater(
        deps.medicationRepository.add(medication('med1', times: [])),
        rejected(),
      );
    });

    test(
      "a record can never be linked to another member's medication",
      () async {
        final database = await open();
        addTearDown(database.close);
        final deps = await seeded(database);
        await deps.medicationRepository.add(medication('med1'));

        await expectLater(
          deps.doseRecordRepository.save(record('r1', memberId: 'mB')),
          rejected(),
        );
        await expectLater(
          deps.doseRecordRepository.save(record('r1', medicationId: 'missing')),
          rejected(),
        );
        expect(await deps.doseRecordRepository.getAll(), isEmpty);
      },
    );

    test(
      'the database itself refuses a second record of the same dose',
      () async {
        final database = await open();
        addTearDown(database.close);
        final deps = await seeded(database);
        await deps.medicationRepository.add(medication('med1'));
        await deps.doseRecordRepository.save(record('r1'));

        await expectLater(
          database.customStatement(
            'INSERT INTO dose_records (id, member_id, medication_id, '
            'scheduled_at, status, recorded_at) VALUES (?, ?, ?, ?, ?, ?)',
            ['r2', 'mA', 'med1', '2026-10-21T08:00:00.000000', 'taken', 0],
          ),
          throwsA(anything),
        );
      },
    );

    test(
      'a medication or member with records cannot be deleted directly',
      () async {
        final database = await open();
        addTearDown(database.close);
        final deps = await seeded(database);
        await deps.medicationRepository.add(medication('med1'));
        await deps.doseRecordRepository.save(record('r1'));

        await expectLater(deps.medicationRepository.delete('med1'), rejected());
        await expectLater(deps.familyRepository.delete('mA'), rejected());
      },
    );

    test(
      'everything is kept after closing and reopening (example D)',
      () async {
        var database = await open();
        final deps = await seeded(database);
        await deps.medicationRepository.add(medication('med1'));
        await deps.doseRecordRepository.save(record('r1'));
        await database.close();

        database = await open();
        addTearDown(database.close);
        final reopened = AppDependencies.local(database);
        expect(
          await reopened.medicationRepository.getById('med1'),
          medication('med1'),
        );
        expect(await reopened.doseRecordRepository.getAll(), [record('r1')]);

        // Marking the same dose again still leaves a single record.
        await reopened.doseRecordRepository.save(record('r9'));
        expect(await reopened.doseRecordRepository.getAll(), hasLength(1));
      },
    );

    test('unreadable stored times are reported, not guessed', () async {
      final database = await open();
      addTearDown(database.close);
      final deps = await seeded(database);
      await database.customStatement(
        'INSERT INTO medications (id, member_id, name, dose, reminder_times, '
        'start_date) VALUES (?, ?, ?, ?, ?, ?)',
        ['bad', 'mA', 'n', 'd', '["8am"]', '2026-10-20'],
      );

      await expectLater(
        deps.medicationRepository.getAll(),
        throwsA(
          isA<LocalDataException>().having(
            (e) => e.error,
            'error',
            LocalDataError.unreadable,
          ),
        ),
      );
    });

    test(
      'upgrading a version 2 database keeps all data and adds the tables',
      () async {
        // Builds a genuine version 2 file: the current schema minus the
        // medication tables.
        var database = await open();
        final deps = await seeded(database);
        final symptom = SymptomEntry(
          id: 's1',
          memberId: 'mA',
          name: 'שיעול',
          startedAt: DateTime(2026, 10, 1, 9),
          severity: 2,
        );
        await deps.symptomRepository.add(symptom);
        await database.close();
        final raw = sqlite3.open(file.path)
          ..execute("PRAGMA key = \"x'${keys.key}'\"")
          ..execute('DROP TABLE dose_records')
          ..execute('DROP TABLE medications')
          ..execute('PRAGMA user_version = 2');
        expect(
          raw.select(
            "SELECT name FROM sqlite_master WHERE name LIKE 'medications%' "
            "OR name LIKE 'dose_records%'",
          ),
          isEmpty,
        );
        raw.close();

        database = await open();
        addTearDown(database.close);
        final upgraded = AppDependencies.local(database);

        final version = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data.values.first, LocalDatabase.currentSchemaVersion);
        expect(LocalDatabase.currentSchemaVersion, 3);
        expect(await upgraded.familyRepository.getAll(), hasLength(2));
        expect(await upgraded.symptomRepository.getById('s1'), symptom);

        await upgraded.medicationRepository.add(medication('med1'));
        await upgraded.doseRecordRepository.save(record('r1'));
        expect(await upgraded.doseRecordRepository.getAll(), [record('r1')]);
        final indexes = await database
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index' "
              "AND name IN ('medications_by_member', 'dose_records_by_member') "
              'ORDER BY name',
            )
            .get();
        expect(
          [for (final r in indexes) r.read<String>('name')],
          ['dose_records_by_member', 'medications_by_member'],
        );
      },
    );
  });
}
