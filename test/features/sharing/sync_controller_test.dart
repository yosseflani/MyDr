import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/cloud/recovery_key_store.dart';
import 'package:mydr/data/local/local_database.dart' hide SyncSettings;
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:mydr/data/media/visit_media_file_store.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/models/sync_state.dart';
import 'package:mydr/data/sync/sync_engine.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/backup/backup_controller.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/medications/medication_controller.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';
import 'package:mydr/features/sharing/sync_controller.dart';
import 'package:mydr/features/symptoms/symptom_controller.dart';
import 'package:mydr/features/visit_preparation/visit_media_controller.dart';

import '../../helpers/fake_cloud.dart';
import '../../helpers/fake_household_cloud.dart';
import '../../helpers/fake_reminder_scheduler.dart';
import '../../helpers/memory_key_store.dart';

/// One phone's app: an encrypted database, the controllers the app builds,
/// and a fake cloud shared with the other phone.
class _App {
  _App._(this.database, this.deps, this.accounts, this.scheduler);

  final LocalDatabase database;
  final AppDependencies deps;
  final FakeAccountService accounts;
  final FakeReminderScheduler scheduler;
  late final FamilyController family;
  late final AppointmentController appointments;
  late final DoctorQuestionController questions;
  late final SymptomController symptoms;
  late final VisitMediaController media;
  late final MedicationController medications;
  late final BackupController backup;
  late final SyncController sync;

  static Future<_App> create(
    Directory parent,
    String name,
    FakeHouseholdServer server, {
    int skipUids = 0,
  }) async {
    final root = Directory('${parent.path}/$name')..createSync();
    final database = await LocalDatabaseOpener(
      keyStore: MemoryDatabaseKeyStore(),
      locateFile: () async => File('${root.path}/mydr.sqlite'),
    ).open();
    final accounts = FakeAccountService();
    for (var i = 0; i < skipUids; i++) {
      await accounts.register(
        email: 'skip$i@example.test',
        password: 'pass1234',
      );
    }
    await accounts.signOut();
    final scheduler = FakeReminderScheduler();
    final deps = AppDependencies.local(
      database,
      visitMediaFiles: PrivateVisitMediaFileStore(
        locateDirectory: () async => Directory('${root.path}/media'),
      ),
      reminderScheduler: scheduler,
      cloudBackend: FakeCloudBackend(
        accounts: accounts,
        household: FakeHouseholdCloud(server, uid: () => accounts.current?.uid),
      ),
      recoveryKeyStore: InMemoryRecoveryKeyStore(),
      syncKeyStore: InMemorySyncKeyStore(),
      syncWorkDirectory: () async => Directory('${root.path}/sync'),
    );
    final app = _App._(database, deps, accounts, scheduler);
    app.family = FamilyController(deps);
    app.appointments = AppointmentController(
      dependencies: deps,
      familyController: app.family,
    );
    app.questions = DoctorQuestionController(
      dependencies: deps,
      familyController: app.family,
      appointmentController: app.appointments,
    );
    app.symptoms = SymptomController(
      dependencies: deps,
      familyController: app.family,
    );
    app.media = VisitMediaController(
      dependencies: deps,
      familyController: app.family,
      appointmentController: app.appointments,
    );
    app.medications = MedicationController(
      dependencies: deps,
      familyController: app.family,
    );
    app.backup = BackupController(
      dependencies: deps,
      familyController: app.family,
    );
    app.sync = SyncController(
      dependencies: deps,
      backupController: app.backup,
      familyController: app.family,
      appointmentController: app.appointments,
      medicationController: app.medications,
      doctorQuestionController: app.questions,
      symptomController: app.symptoms,
      visitMediaController: app.media,
    );
    await app.family.load();
    await app.medications.load();
    await app.backup.start();
    await app.backup.register('$name@example.test', 'password123');
    await app.sync.start();
    return app;
  }

  Future<void> close() async {
    sync.dispose();
    backup.dispose();
    medications.dispose();
    media.dispose();
    symptoms.dispose();
    questions.dispose();
    appointments.dispose();
    family.dispose();
    await database.close();
  }
}

void main() {
  late Directory temp;
  late FakeHouseholdServer server;
  late _App a;
  late _App b;

  final child = FamilyMember(
    id: 'child-1',
    name: 'ילד בדוי',
    relation: FamilyRelation.child,
  );
  final medication = Medication(
    id: 'med-1',
    memberId: 'child-1',
    name: 'תרופה בדויה',
    dose: '1',
    reminderTimes: [DoseTime(8, 0), DoseTime(20, 0)],
    startDate: DateTime(2020, 1, 1),
  );

  setUp(() async {
    temp = Directory.systemTemp.createTempSync('mydr_sync_controller');
    server = FakeHouseholdServer();
    a = await _App.create(temp, 'a', server);
    b = await _App.create(temp, 'b', server, skipUids: 1);
  });

  tearDown(() async {
    await a.close();
    await b.close();
    temp.deleteSync(recursive: true);
  });

  Future<void> joinBoth() async {
    expect(a.sync.status, SharingStatus.none);
    expect(await a.sync.createHousehold(), isNull);
    expect(a.sync.status, SharingStatus.active);
    final code = await a.sync.createInvite();
    final (preview, failure) = await b.sync.lookupInvite(code!.format());
    expect(failure, isNull);
    expect(await b.sync.respondToInvite(preview!, accept: true), isNull);
    expect(b.sync.status, SharingStatus.joining);
    await a.sync.refresh();
    final invite = a.sync.invites!.single;
    expect(invite.verified, isTrue);
    expect(
      await a.sync.completeInvite(invite.id, HouseholdRole.member),
      isNull,
    );
    expect(await b.sync.checkJoined(), isNull);
    expect(b.sync.status, SharingStatus.active);
  }

  test('sharing needs a cloud configuration and saved data', () {
    final family = FamilyController(AppDependencies.empty());
    final backup = BackupController(
      dependencies: AppDependencies.empty(),
      familyController: family,
    );
    final appointments = AppointmentController(
      dependencies: AppDependencies.empty(),
      familyController: family,
    );
    final controller = SyncController(
      dependencies: AppDependencies.empty(),
      backupController: backup,
      familyController: family,
      appointmentController: appointments,
      medicationController: MedicationController(
        dependencies: AppDependencies.empty(),
        familyController: family,
      ),
      doctorQuestionController: DoctorQuestionController(
        dependencies: AppDependencies.empty(),
        familyController: family,
        appointmentController: appointments,
      ),
      symptomController: SymptomController(
        dependencies: AppDependencies.empty(),
        familyController: family,
      ),
      visitMediaController: VisitMediaController(
        dependencies: AppDependencies.empty(),
        familyController: family,
        appointmentController: appointments,
      ),
    );
    expect(controller.isAvailable, isFalse);
    expect(controller.status, SharingStatus.unavailable);
  });

  test('a sync reloads the screens and reschedules reminders from the '
      'synced data', () async {
    await joinBoth();
    await a.deps.familyRepository.add(child);
    await a.deps.medicationRepository.add(medication);
    await a.family.load();
    expect(
      () => a.sync.share('child-1', userConfirmed: false),
      throwsArgumentError,
    );
    expect(await a.sync.share('child-1', userConfirmed: true), isNull);
    expect(a.sync.sharedMemberIds, {'child-1'});
    expect(a.sync.pendingCount, greaterThan(0));
    expect(await a.sync.syncNow(), isNull);
    expect(a.sync.pendingCount, 0);

    final revision = b.family.relatedDataRevision;
    final replacements = b.scheduler.replacements.length;
    expect(await b.sync.syncNow(), isNull);
    expect(b.sync.lastReport!.received, greaterThan(0));
    expect(b.family.relatedDataRevision, greaterThan(revision));
    await pumpEventQueue();
    expect(b.medications.medications.map((m) => m.id), ['med-1']);
    expect(b.scheduler.replacements.length, greaterThan(replacements));
    expect(b.scheduler.scheduled, isNotEmpty);
    expect(b.sync.lastSyncAt, isNotNull);
  });

  test('a deletion by the other parent is applied only after confirmation, '
      'through the normal deletion', () async {
    await joinBoth();
    await a.deps.familyRepository.add(child);
    await a.deps.medicationRepository.add(medication);
    await a.family.load();
    await a.sync.share('child-1', userConfirmed: true);
    await a.sync.syncNow();
    await b.sync.syncNow();

    expect(await a.medications.delete('med-1', userConfirmed: true), isTrue);
    await a.sync.syncNow();
    await b.sync.syncNow();
    final conflict = b.sync.conflicts.single;
    expect(conflict.reason, ConflictReason.deleted);
    expect(await b.deps.medicationRepository.getById('med-1'), isNotNull);

    expect(
      () => b.sync.resolve(conflict, ConflictChoice.useOther),
      throwsArgumentError,
    );
    expect(
      await b.sync.resolve(
        conflict,
        ConflictChoice.useOther,
        userConfirmed: true,
      ),
      isNull,
    );
    expect(await b.deps.medicationRepository.getById('med-1'), isNull);
    expect(b.sync.conflicts, isEmpty);
    expect(await b.sync.syncNow(), isNull);
    expect(await a.sync.syncNow(), isNull);
    expect(await a.deps.medicationRepository.getById('med-1'), isNull);
  });

  test('a removed parent sees it, and keeps the data', () async {
    await joinBoth();
    await a.deps.familyRepository.add(child);
    await a.family.load();
    await a.sync.share('child-1', userConfirmed: true);
    await a.sync.syncNow();
    await b.sync.syncNow();

    await a.sync.refresh();
    final member = a.sync.members!.firstWhere((m) => !m.isMe);
    expect(
      () => a.sync.revokeMember(member.uid, userConfirmed: false),
      throwsArgumentError,
    );
    expect(await a.sync.revokeMember(member.uid, userConfirmed: true), isNull);
    expect(await b.sync.syncNow(), SharingFailure.removed);
    expect(b.sync.status, SharingStatus.removed);
    expect(await b.deps.familyRepository.getById('child-1'), child);
    await b.sync.acknowledgeRemoval();
    expect(b.sync.status, SharingStatus.none);
  });

  test('offline: the sync fails without changing anything', () async {
    await joinBoth();
    final cloud = (a.backup.services!.household as FakeHouseholdCloud)
      ..offline = true;
    expect(await a.sync.syncNow(), SharingFailure.network);
    cloud.offline = false;
    expect(await a.sync.syncNow(), isNull);
  });

  test(
    'a shared profile stays a child, and its appointments do not move',
    () async {
      await joinBoth();
      await a.deps.familyRepository.add(child);
      await a.family.load();
      await a.sync.share('child-1', userConfirmed: true);
      expect(
        await a.family.update(child.copyWith(relation: FamilyRelation.parent)),
        FamilySaveResult.sharedMustStayChild,
      );
      final other = FamilyMember(
        id: 'other',
        name: 'אחר',
        relation: FamilyRelation.sibling,
      );
      await a.family.add(other);
      final appointmentId = a.appointments.createId();
      await a.appointments.add(_appointment(appointmentId, 'child-1'));
      expect(
        await a.appointments.update(_appointment(appointmentId, 'other')),
        AppointmentSaveResult.sharedMember,
      );
      final result = await a.family.delete('child-1', userConfirmed: true);
      expect(result.isSuccess, isTrue);
      await a.sync.loadLocal();
      expect(a.sync.sharedMemberIds, isEmpty);
    },
  );
}

Appointment _appointment(String id, String memberId) => Appointment(
  id: id,
  memberId: memberId,
  doctorName: 'רופא בדוי',
  dateTime: DateTime(2030, 1, 1, 9),
);
