import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/backup/backup_service.dart';
import 'package:mydr/data/backup/recovery_key.dart';
import 'package:mydr/data/cloud/account_service.dart';
import 'package:mydr/data/cloud/recovery_key_store.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_family_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_medication_repository.dart';
import 'package:mydr/features/backup/backup_controller.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/medications/medication_controller.dart';

import '../../helpers/fake_cloud.dart';
import '../../helpers/fake_media.dart';
import '../../helpers/fake_reminder_scheduler.dart';
import '../../helpers/flaky_repositories.dart';

void main() {
  const email = 'dana@example.test';
  const password = 'password123';

  late Directory temp;
  late FakeCloudBackend cloud;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('mydr_backup_ctrl');
    cloud = FakeCloudBackend();
  });
  tearDown(() => temp.deleteSync(recursive: true));

  /// A phone with in-memory data that counts as saved, sharing [cloud].
  ({
    AppDependencies deps,
    FamilyController family,
    BackupController backup,
    MedicationController medications,
    InMemoryRecoveryKeyStore keys,
    FakeReminderScheduler reminders,
  })
  phone(
    String name, {
    List<FamilyMember> members = const [],
    List<Medication> meds = const [],
    bool persistsData = true,
  }) {
    final keys = InMemoryRecoveryKeyStore();
    final reminders = FakeReminderScheduler();
    final deps = AppDependencies(
      familyRepository: InMemoryFamilyRepository(members),
      appointmentRepository: FlakyAppointmentRepository(),
      doctorQuestionRepository: FlakyDoctorQuestionRepository(),
      symptomRepository: FlakySymptomRepository(),
      medicationRepository: InMemoryMedicationRepository(meds),
      visitMediaFiles: FakeVisitMediaFileStore(),
      reminderScheduler: reminders,
      cloudBackend: cloud,
      recoveryKeyStore: keys,
      backupWorkDirectory: () async => Directory('${temp.path}/$name'),
      persistsData: persistsData,
    );
    final family = FamilyController(deps);
    final medications = MedicationController(
      dependencies: deps,
      familyController: family,
      clock: () => DateTime(2026, 10, 20, 7),
    );
    final backup = BackupController(
      dependencies: deps,
      familyController: family,
    );
    addTearDown(backup.dispose);
    addTearDown(medications.dispose);
    addTearDown(family.dispose);
    return (
      deps: deps,
      family: family,
      backup: backup,
      medications: medications,
      keys: keys,
      reminders: reminders,
    );
  }

  final dana = FamilyMember(
    id: 'm1',
    name: 'דנה',
    relation: FamilyRelation.self,
  );
  final medication = Medication(
    id: 'med1',
    memberId: 'm1',
    name: 'תרופה',
    dose: '1',
    reminderTimes: [DoseTime(8, 0)],
    startDate: DateTime(2026, 10, 20),
    endDate: DateTime(2026, 10, 22),
  );

  test('without configuration nothing connects', () async {
    final deps = AppDependencies.empty();
    final family = FamilyController(deps);
    final controller = BackupController(
      dependencies: deps,
      familyController: family,
    );
    addTearDown(controller.dispose);
    addTearDown(family.dispose);

    await controller.start();
    expect(controller.status, CloudStatus.notConfigured);
    expect(cloud.connects, 0);
  });

  test('connects only when started, and can retry after a failure', () async {
    final a = phone('a');
    expect(a.backup.status, CloudStatus.idle);
    expect(cloud.connects, 0);

    cloud.failConnect = true;
    await a.backup.start();
    expect(a.backup.status, CloudStatus.failed);

    cloud.failConnect = false;
    await a.backup.start();
    expect(a.backup.status, CloudStatus.connected);
    expect(a.backup.account, isNull);
  });

  test('account errors are reported as values', () async {
    final a = phone('a');
    await a.backup.start();

    expect(
      await a.backup.signIn(email, password),
      AccountError.wrongCredentials,
    );
    expect(
      await a.backup.register('no-at', password),
      AccountError.invalidEmail,
    );
    expect(await a.backup.register(email, password), isNull);
    expect(a.backup.account?.email, email);
    expect(a.backup.hasRecoveryKey, isFalse);
    expect(a.backup.backups, isEmpty);

    cloud.accounts.failWith = AccountError.network;
    expect(await a.backup.sendPasswordReset(email), AccountError.network);
  });

  test('backs up on one phone and restores on another, reloading every '
      'screen and rescheduling reminders', () async {
    final a = phone('a', members: [dana], meds: [medication]);
    await a.backup.start();
    await a.backup.register(email, password);
    final key = a.backup.createRecoveryKey();
    expect(await a.backup.saveNewRecoveryKey(key), isTrue);
    expect(await a.backup.backUpNow(), isNull);
    expect(a.backup.backups, hasLength(1));
    expect(a.backup.lastBackupAt, isNotNull);

    final b = phone('b');
    await b.family.load();
    await b.medications.load();
    await b.backup.start();
    expect(await b.backup.signIn(email, password), isNull);
    // A new phone: backups exist, but not the key.
    expect(b.backup.hasRecoveryKey, isFalse);
    expect(b.backup.backups, hasLength(1));

    final prepared = await b.backup.prepareRestore(
      b.backup.backups!.first,
      key: key,
    );
    expect(prepared, isNotNull);
    expect(b.family.members, isEmpty);

    expect(
      await b.backup.applyRestore(prepared!, userConfirmed: true, key: key),
      isNull,
    );
    await pumpEventQueue();
    expect(b.family.members, [dana]);
    expect(b.medications.medications, [medication]);
    expect(b.reminders.scheduled, isNotEmpty);
    // The key typed for the restore is remembered for future backups.
    expect(b.backup.hasRecoveryKey, isTrue);
    expect(await b.keys.read(b.backup.account!.uid), key);
  });

  test('restoring needs confirmation', () async {
    final a = phone('a', members: [dana]);
    await a.backup.start();
    await a.backup.register(email, password);
    await a.backup.saveNewRecoveryKey(a.backup.createRecoveryKey());
    await a.backup.backUpNow();
    final prepared = await a.backup.prepareRestore(a.backup.backups!.first);

    expect(
      () => a.backup.applyRestore(prepared!, userConfirmed: false),
      throwsArgumentError,
    );
    await a.backup.cancelRestore(prepared!);
  });

  test(
    'an existing key is checked against the backups before saving',
    () async {
      final a = phone('a', members: [dana]);
      await a.backup.start();
      await a.backup.register(email, password);
      final key = a.backup.createRecoveryKey();
      await a.backup.saveNewRecoveryKey(key);
      await a.backup.backUpNow();

      final b = phone('b');
      await b.backup.start();
      await b.backup.signIn(email, password);
      expect(
        await b.backup.enterRecoveryKey('not a key'),
        RecoveryKeyEntryResult.invalid,
      );
      expect(
        await b.backup.enterRecoveryKey(
          RecoveryKey.generate(Random(5)).format(),
        ),
        RecoveryKeyEntryResult.doesNotMatch,
      );
      expect(b.backup.hasRecoveryKey, isFalse);
      expect(
        await b.backup.enterRecoveryKey(key.format().toLowerCase()),
        RecoveryKeyEntryResult.saved,
      );
      expect(b.backup.hasRecoveryKey, isTrue);
    },
  );

  test('a wrong key fails the restore and changes nothing', () async {
    final a = phone('a', members: [dana]);
    await a.backup.start();
    await a.backup.register(email, password);
    await a.backup.saveNewRecoveryKey(a.backup.createRecoveryKey());
    await a.backup.backUpNow();

    final b = phone(
      'b',
      members: [
        FamilyMember(id: 'x', name: 'אחר', relation: FamilyRelation.other),
      ],
    );
    await b.family.load();
    await b.backup.start();
    await b.backup.signIn(email, password);

    final prepared = await b.backup.prepareRestore(
      b.backup.backups!.first,
      key: RecoveryKey.generate(Random(7)),
    );
    expect(prepared, isNull);
    expect(b.backup.lastFailure, BackupFailure.wrongKey);
    expect(b.family.members.single.id, 'x');
  });

  test('a failed upload is reported and the previous backup stays', () async {
    final a = phone('a', members: [dana]);
    await a.backup.start();
    await a.backup.register(email, password);
    await a.backup.saveNewRecoveryKey(a.backup.createRecoveryKey());
    await a.backup.backUpNow();
    final first = a.backup.backups!.single;

    cloud.storage
      ..uploads = 0
      ..failUploadNumber = 1;
    expect(await a.backup.backUpNow(), BackupFailure.network);
    expect(a.backup.lastFailure, BackupFailure.network);
    expect(a.backup.backups, [first]);
  });

  test('demo mode never backs up or restores', () async {
    final a = phone('a', members: [dana], persistsData: false);
    await a.backup.start();
    await a.backup.register(email, password);
    await a.backup.saveNewRecoveryKey(a.backup.createRecoveryKey());

    expect(a.backup.canBackUp, isFalse);
    expect(await a.backup.backUpNow(), isNotNull);
    expect(cloud.storage.objects, isEmpty);
  });

  test('signing out removes the key from the phone, not the backups', () async {
    final a = phone('a', members: [dana]);
    await a.backup.start();
    await a.backup.register(email, password);
    await a.backup.saveNewRecoveryKey(a.backup.createRecoveryKey());
    await a.backup.backUpNow();
    final uid = a.backup.account!.uid;

    await a.backup.signOut();
    expect(a.backup.account, isNull);
    expect(await a.keys.read(uid), isNull);
    expect(cloud.storage.objects, isNotEmpty);
  });
}
