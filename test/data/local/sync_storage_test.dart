import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/local/local_database.dart' hide SyncSettings;
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:mydr/data/local/repositories/local_repository_support.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/data/models/sync_state.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../helpers/memory_key_store.dart';
import '../../helpers/schema_versions.dart';

/// The database-only guarantees of household sync (schema version 4):
/// change tracking by triggers, only children shared, and the upgrade from
/// a real encrypted version 3 file. Test data is fictional.
void main() {
  late Directory directory;
  late File file;
  late MemoryDatabaseKeyStore keys;

  final self = FamilyMember(
    id: 'm-self',
    name: 'דנה',
    relation: FamilyRelation.self,
  );
  final child = FamilyMember(
    id: 'm-child',
    name: 'נועה',
    relation: FamilyRelation.child,
  );
  Appointment appointment(String id, String memberId) => Appointment(
    id: id,
    memberId: memberId,
    doctorName: 'רופא',
    dateTime: DateTime(2026, 11, 1, 9),
  );

  setUp(() {
    directory = Directory.systemTemp.createTempSync('mydr_sync_db');
    file = File('${directory.path}/${LocalDatabaseOpener.fileName}');
    keys = MemoryDatabaseKeyStore();
  });

  tearDown(() => directory.deleteSync(recursive: true));

  Future<LocalDatabase> open() =>
      LocalDatabaseOpener(keyStore: keys, locateFile: () async => file).open();

  Future<AppDependencies> seeded(LocalDatabase database) async {
    final deps = AppDependencies.local(database);
    await deps.familyRepository.add(self);
    await deps.familyRepository.add(child);
    return deps;
  }

  Future<void> joinHousehold(AppDependencies deps) async {
    final state = deps.syncStateRepository;
    await state.saveSettings(
      (await state.settings()).copyWith(
        householdId: () => 'h1',
        accountUid: () => 'uid',
        role: () => HouseholdRole.admin,
        state: SyncState.active,
      ),
    );
  }

  test('without a household nothing is tracked', () async {
    final database = await open();
    addTearDown(database.close);
    final deps = await seeded(database);
    await deps.appointmentRepository.add(appointment('a1', 'm-child'));
    expect(await deps.syncStateRepository.pendingChanges(), isEmpty);
  });

  test(
    'changes to a shared child are tracked, a private profile never',
    () async {
      final database = await open();
      addTearDown(database.close);
      final deps = await seeded(database);
      await joinHousehold(deps);
      final state = deps.syncStateRepository;
      await state.setShared(
        'm-child',
        shared: true,
        at: DateTime(2026, 10, 19),
      );

      await deps.appointmentRepository.add(appointment('a1', 'm-child'));
      await deps.appointmentRepository.add(appointment('a2', 'm-self'));
      await deps.symptomRepository.add(
        SymptomEntry(
          id: 's1',
          memberId: 'm-self',
          name: 'x',
          startedAt: DateTime(2026, 10, 1),
          severity: 1,
        ),
      );
      await deps.medicationRepository.add(
        Medication(
          id: 'med1',
          memberId: 'm-child',
          name: 'n',
          dose: 'd',
          reminderTimes: [DoseTime(8, 0)],
          startDate: DateTime(2026, 10, 1),
        ),
      );
      await deps.doseRecordRepository.save(
        DoseRecord(
          id: DoseRecord.idFor('med1', DateTime(2026, 10, 2, 8)),
          memberId: 'm-child',
          medicationId: 'med1',
          scheduledAt: DateTime(2026, 10, 2, 8),
          status: DoseStatus.taken,
          recordedAt: DateTime(2026, 10, 2, 8, 1),
        ),
      );
      final pending = await state.pendingChanges();
      expect(
        {for (final p in pending) '${p.kind.name}:${p.syncId}'},
        {
          'appointment:a1',
          'medication:med1',
          'dose:med1@2026-10-02T08:00:00.000000',
        },
      );

      // Edited twice: one entry, counted twice.
      await deps.appointmentRepository.update(
        appointment('a1', 'm-child').copyWith(notes: () => 'n'),
      );
      final entry = (await state.pendingChanges()).firstWhere(
        (p) => p.syncId == 'a1',
      );
      expect(entry.changeCount, 2);

      // An upload clears only what it read.
      await state.clearPending(
        PendingChange(
          kind: SyncKind.appointment,
          syncId: 'a1',
          localId: 'a1',
          changeCount: 1,
        ),
      );
      expect(
        (await state.pendingChanges()).where((p) => p.syncId == 'a1'),
        hasLength(1),
      );
      await state.clearPending(entry);
      expect(
        (await state.pendingChanges()).where((p) => p.syncId == 'a1'),
        isEmpty,
      );
    },
  );

  test('a deletion of a record known to the household is tracked', () async {
    final database = await open();
    addTearDown(database.close);
    final deps = await seeded(database);
    await joinHousehold(deps);
    final state = deps.syncStateRepository;
    await deps.appointmentRepository.add(appointment('a1', 'm-child'));
    await state.saveRecord(
      SyncRecordState(
        kind: SyncKind.appointment,
        syncId: 'a1',
        localId: 'a1',
        memberId: 'm-child',
        vector: VersionVector({'d1': 1}),
        updatedAt: DateTime(2026, 10, 1),
        updatedBy: 'd1',
      ),
    );
    await deps.appointmentRepository.delete('a1');
    expect((await state.pendingChanges()).single.syncId, 'a1');
  });

  test('changes applied from another device are not tracked', () async {
    final database = await open();
    addTearDown(database.close);
    final deps = await seeded(database);
    await joinHousehold(deps);
    final state = deps.syncStateRepository;
    await state.setShared('m-child', shared: true, at: DateTime(2026, 10, 19));
    await deps.transactions.run(
      () => state.applyingRemote(
        () => deps.appointmentRepository.add(appointment('a1', 'm-child')),
      ),
    );
    expect(await state.pendingChanges(), isEmpty);
    // Tracking is back on afterwards.
    await deps.appointmentRepository.add(appointment('a2', 'm-child'));
    expect((await state.pendingChanges()).single.syncId, 'a2');
  });

  test(
    'only a child can be shared, and a shared profile stays a child',
    () async {
      final database = await open();
      addTearDown(database.close);
      final deps = await seeded(database);
      final state = deps.syncStateRepository;
      await expectLater(
        state.setShared('m-self', shared: true, at: DateTime(2026)),
        throwsStateError,
      );
      await expectLater(
        database.customStatement(
          'INSERT INTO sync_shared_members (member_id, shared_at) '
          "VALUES ('m-self', 1)",
        ),
        throwsA(anything),
      );
      await state.setShared('m-child', shared: true, at: DateTime(2026));
      await expectLater(
        deps.familyRepository.update(
          child.copyWith(relation: FamilyRelation.spouse),
        ),
        throwsA(isA<LocalDataException>()),
      );
      // A shared profile cannot be deleted while still shared.
      await expectLater(
        deps.familyRepository.delete('m-child'),
        throwsA(isA<LocalDataException>()),
      );
      await state.setShared('m-child', shared: false);
      await deps.familyRepository.delete('m-child');
      expect(await deps.familyRepository.getById('m-child'), isNull);
    },
  );

  test('upgrading an encrypted version 3 database keeps all data and adds '
      'the sync tables', () async {
    // A genuine version 3 file: the current schema minus version 4.
    var database = await open();
    final deps = await seeded(database);
    await deps.appointmentRepository.add(appointment('a1', 'm-child'));
    await database.close();
    final raw = sqlite3.open(file.path)
      ..execute("PRAGMA key = \"x'${keys.key}'\"");
    dropVersion4Objects(raw);
    raw.execute('PRAGMA user_version = 3');
    expect(
      raw.select("SELECT name FROM sqlite_master WHERE name LIKE 'sync%'"),
      isEmpty,
    );
    raw.close();
    // Still encrypted: unreadable without the key.
    final locked = sqlite3.open(file.path);
    expect(
      () => locked.select('SELECT * FROM family_members'),
      throwsA(anything),
    );
    locked.close();

    database = await open();
    addTearDown(database.close);
    final upgraded = AppDependencies.local(database);
    final version = await database
        .customSelect('PRAGMA user_version')
        .getSingle();
    expect(version.data.values.first, LocalDatabase.currentSchemaVersion);
    expect(LocalDatabase.currentSchemaVersion, 4);
    expect(await upgraded.familyRepository.getAll(), hasLength(2));
    expect(
      await upgraded.appointmentRepository.getById('a1'),
      appointment('a1', 'm-child'),
    );

    // Off until the device joins a household.
    final settings = await upgraded.syncStateRepository.settings();
    expect(settings.state, SyncState.off);
    expect(settings.deviceId, isNotEmpty);
    await upgraded.appointmentRepository.add(appointment('a2', 'm-child'));
    expect(await upgraded.syncStateRepository.pendingChanges(), isEmpty);

    final objects = await database
        .customSelect(
          "SELECT COUNT(*) AS n FROM sqlite_master WHERE name LIKE 'sync%'",
        )
        .getSingle();
    // 7 tables, 2 indexes, 23 triggers.
    expect(objects.read<int>('n'), 7 + 2 + 23);
  });
}
