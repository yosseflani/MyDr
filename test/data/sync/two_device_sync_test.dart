import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/backup/backup_data_store.dart';
import 'package:mydr/data/cloud/account_service.dart';
import 'package:mydr/data/cloud/household_cloud.dart';
import 'package:mydr/data/cloud/recovery_key_store.dart';
import 'package:mydr/data/local/local_database.dart'
    hide SyncSettings, VisitMedia;
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:mydr/data/media/visit_media_file_store.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/data/models/sync_state.dart';
import 'package:mydr/data/models/visit_media.dart';
import 'package:mydr/data/sync/household_crypto.dart';
import 'package:mydr/data/sync/household_service.dart';
import 'package:mydr/data/sync/sync_engine.dart';

import '../../helpers/fake_household_cloud.dart';
import '../../helpers/fake_media.dart';
import '../../helpers/memory_key_store.dart';

/// One phone: its own encrypted database, media folder, secure key store
/// and account, sharing one simulated cloud with the other phones.
class _Phone {
  _Phone._(
    this.root,
    this.database,
    this.files,
    this.deps,
    this.keys,
    this.cloud,
    this.account,
    this.households,
    this.engine,
  );

  final Directory root;
  final LocalDatabase database;
  final PrivateVisitMediaFileStore files;
  final AppDependencies deps;
  final InMemorySyncKeyStore keys;
  final FakeHouseholdCloud cloud;
  final Account account;
  final HouseholdService households;
  final SyncEngine engine;

  static Future<_Phone> create(
    Directory parent,
    String name,
    FakeHouseholdServer server, {
    required String uid,
    required DateTime Function() clock,
  }) async {
    final root = Directory('${parent.path}/$name')..createSync();
    final database = await LocalDatabaseOpener(
      keyStore: MemoryDatabaseKeyStore(),
      locateFile: () async => File('${root.path}/mydr.sqlite'),
    ).open();
    final files = PrivateVisitMediaFileStore(
      locateDirectory: () async => Directory('${root.path}/media'),
    );
    final keys = InMemorySyncKeyStore();
    final deps = AppDependencies.local(
      database,
      visitMediaFiles: files,
      syncKeyStore: keys,
      syncWorkDirectory: () async => Directory('${root.path}/sync_work'),
    );
    final cloud = FakeHouseholdCloud(server, uid: () => uid);
    final households = HouseholdService(
      cloud: cloud,
      keys: keys,
      state: deps.syncStateRepository,
      clock: clock,
      random: Random(name.hashCode),
    );
    return _Phone._(
      root,
      database,
      files,
      deps,
      keys,
      cloud,
      Account(uid: uid, email: '$name@example.test'),
      households,
      SyncEngine(
        dependencies: deps,
        cloud: cloud,
        households: households,
        clock: clock,
        random: Random(name.hashCode + 1),
        maxChangesPerBatch: 4,
      ),
    );
  }

  Future<SyncReport> sync() => engine.sync(account);

  Future<List<SyncConflict>> conflicts() =>
      deps.syncStateRepository.conflicts();
}

void main() {
  late Directory temp;
  late FakeHouseholdServer server;
  late DateTime now;
  late _Phone a;
  late _Phone b;

  DateTime clock() => now;

  final child = FamilyMember(
    id: 'child-noa',
    name: 'נועה בדויה',
    relation: FamilyRelation.child,
    birthDate: DateTime(2019, 5, 3),
    allergies: const ['אבקה בדויה'],
  );
  final appointment = Appointment(
    id: 'appt-1',
    memberId: 'child-noa',
    doctorName: 'ד"ר בדוי',
    dateTime: DateTime(2026, 11, 2, 9, 30),
    location: 'מרפאה',
  );
  final question = DoctorQuestion(
    id: 'question-1',
    memberId: 'child-noa',
    appointmentId: 'appt-1',
    text: 'שאלה בדויה',
    createdAt: DateTime(2026, 10, 1, 8),
  );
  final symptom = SymptomEntry(
    id: 'symptom-1',
    memberId: 'child-noa',
    name: 'שיעול בדוי',
    startedAt: DateTime(2026, 10, 10, 21),
    severity: 2,
  );
  final medication = Medication(
    id: 'med-1',
    memberId: 'child-noa',
    name: 'סירופ בדוי',
    dose: '5 ml',
    reminderTimes: [DoseTime(8, 0), DoseTime(20, 0)],
    startDate: DateTime(2026, 10, 1),
    endDate: DateTime(2026, 12, 31),
  );
  final photo = fakeJpeg(4000);

  setUp(() async {
    temp = Directory.systemTemp.createTempSync('mydr_sync');
    now = DateTime(2026, 10, 19, 12);
    server = FakeHouseholdServer(now: clock);
    a = await _Phone.create(temp, 'a', server, uid: 'uid-a', clock: clock);
    b = await _Phone.create(temp, 'b', server, uid: 'uid-b', clock: clock);
  });

  tearDown(() async {
    await a.database.close();
    await b.database.close();
    temp.deleteSync(recursive: true);
  });

  /// A creates the household and adds B through an invitation.
  Future<void> joinBoth() async {
    await a.households.create(a.account);
    final code = await a.households.invite(a.account);
    final preview = await b.households.lookup(b.account, code.format());
    await b.households.respond(b.account, preview, accept: true);
    final invites = await a.households.invites(a.account);
    expect(invites.single.verified, isTrue);
    await a.households.completeInvite(
      a.account,
      invites.single.id,
      role: HouseholdRole.member,
    );
    expect(await b.households.checkJoined(b.account), isTrue);
  }

  /// A's shared child with one record of every kind, and a photo.
  Future<void> seedChild(_Phone phone) async {
    final d = phone.deps;
    await d.familyRepository.add(child);
    await d.appointmentRepository.add(appointment);
    await d.doctorQuestionRepository.add(question);
    await d.symptomRepository.add(symptom);
    await d.medicationRepository.add(medication);
    await d.doseRecordRepository.save(
      DoseRecord(
        id: DoseRecord.idFor('med-1', DateTime(2026, 10, 18, 8)),
        memberId: 'child-noa',
        medicationId: 'med-1',
        scheduledAt: DateTime(2026, 10, 18, 8),
        status: DoseStatus.taken,
        recordedAt: DateTime(2026, 10, 18, 8, 5),
      ),
    );
    final source = File('${temp.path}/src-${phone.account.uid}.jpg')
      ..writeAsBytesSync(photo);
    final stored = await phone.files.import(source.path);
    await d.visitMediaRepository.add(
      VisitMedia(
        id: 'media-1',
        memberId: 'child-noa',
        appointmentId: 'appt-1',
        kind: VisitMediaKind.photo,
        fileName: stored.fileName,
        byteSize: stored.byteSize,
        createdAt: DateTime(2026, 10, 3, 10),
        description: 'תיאור בדוי',
      ),
    );
  }

  Future<void> shareChild() async {
    await seedChild(a);
    await a.engine.share('child-noa', userConfirmed: true);
    await a.sync();
    await b.sync();
  }

  group('household and invitation', () {
    test(
      'the invited parent joins with keys checked against the code',
      () async {
        await joinBoth();
        final settings = await b.deps.syncStateRepository.settings();
        expect(settings.state, SyncState.active);
        expect(settings.role, HouseholdRole.member);
        final members = await b.households.members(b.account);
        expect(members.map((m) => m.uid), containsAll(['uid-a', 'uid-b']));
        expect(members.every((m) => m.verified), isTrue);
        // Both sides see the same fingerprints.
        final fromA = await a.households.members(a.account);
        expect(
          {for (final m in fromA) m.uid: m.fingerprint},
          {for (final m in members) m.uid: m.fingerprint},
        );
      },
    );

    test(
      'a wrong code, a used invitation and an expired one are refused',
      () async {
        await a.households.create(a.account);
        final code = await a.households.invite(a.account);
        await expectLater(
          b.households.lookup(b.account, InviteCode.generate().format()),
          throwsA(
            isA<HouseholdException>().having(
              (e) => e.failure,
              'failure',
              HouseholdFailure.invalidCode,
            ),
          ),
        );
        await expectLater(
          b.households.lookup(b.account, 'not a code'),
          throwsA(isA<HouseholdException>()),
        );
        now = now.add(const Duration(hours: 49));
        await expectLater(
          b.households.lookup(b.account, code.format()),
          throwsA(
            isA<HouseholdException>().having(
              (e) => e.failure,
              'failure',
              HouseholdFailure.expired,
            ),
          ),
        );
      },
    );

    test('a key swapped by the server is never accepted', () async {
      await a.households.create(a.account);
      final code = await a.households.invite(a.account);
      // The server replaces the inviter's key with its own.
      final stored = server.invites.values.single;
      final attacker = await IdentityKeyPair.fromSeed(List.filled(32, 7));
      server.invites[stored.id] = RemoteInvite(
        id: stored.id,
        householdId: stored.householdId,
        inviterUid: stored.inviterUid,
        inviterPublicKey: attacker.publicKey,
        inviterMac: stored.inviterMac,
        inviterLabel: stored.inviterLabel,
        createdAt: stored.createdAt,
        expiresAt: stored.expiresAt,
      );
      await expectLater(
        b.households.lookup(b.account, code.format()),
        throwsA(
          isA<HouseholdException>().having(
            (e) => e.failure,
            'failure',
            HouseholdFailure.verificationFailed,
          ),
        ),
      );
    });

    test(
      'an invitee key swapped after acceptance cannot be completed',
      () async {
        await a.households.create(a.account);
        final code = await a.households.invite(a.account);
        final preview = await b.households.lookup(b.account, code.format());
        await b.households.respond(b.account, preview, accept: true);
        final stored = server.invites.values.single;
        final attacker = await IdentityKeyPair.fromSeed(List.filled(32, 9));
        server.invites[stored.id] = stored.respond(
          status: InviteStatus.accepted,
          inviteeUid: stored.inviteeUid!,
          inviteePublicKey: attacker.publicKey,
          inviteeMac: stored.inviteeMac,
          inviteeLabel: stored.inviteeLabel,
        );
        expect(
          (await a.households.invites(a.account)).single.verified,
          isFalse,
        );
        await expectLater(
          a.households.completeInvite(
            a.account,
            stored.id,
            role: HouseholdRole.member,
          ),
          throwsA(
            isA<HouseholdException>().having(
              (e) => e.failure,
              'failure',
              HouseholdFailure.verificationFailed,
            ),
          ),
        );
        expect(server.members.values.single.keys, ['uid-a']);
      },
    );

    test('rejecting an invitation adds nobody', () async {
      await a.households.create(a.account);
      final code = await a.households.invite(a.account);
      final preview = await b.households.lookup(b.account, code.format());
      await b.households.respond(b.account, preview, accept: false);
      expect(server.invites.values.single.status, InviteStatus.rejected);
      expect(
        (await b.deps.syncStateRepository.settings()).state,
        SyncState.off,
      );
      expect(server.members.values.single.keys, ['uid-a']);
    });
  });

  group('two-way sync', () {
    test('a shared child arrives complete, with its photo', () async {
      await joinBoth();
      await shareChild();

      final d = b.deps;
      expect(await d.familyRepository.getById('child-noa'), child);
      expect(await d.appointmentRepository.getById('appt-1'), appointment);
      expect(await d.doctorQuestionRepository.getById('question-1'), question);
      expect(await d.symptomRepository.getById('symptom-1'), symptom);
      expect(await d.medicationRepository.getById('med-1'), medication);
      final doses = await d.doseRecordRepository.getAll();
      expect(
        doses.single.id,
        DoseRecord.idFor('med-1', DateTime(2026, 10, 18, 8)),
      );
      final media = await d.visitMediaRepository.getById('media-1');
      expect(media!.description, 'תיאור בדוי');
      expect(await b.files.readBytes(media.fileName), photo);
      expect(await d.syncStateRepository.sharedMemberIds(), {'child-noa'});
      expect(await b.conflicts(), isEmpty);
    });

    test(
      'only ciphertext reaches the server, and private profiles never',
      () async {
        await joinBoth();
        await b.deps.familyRepository.add(
          FamilyMember(
            id: 'b-self',
            name: 'פרטי בדוי',
            relation: FamilyRelation.self,
          ),
        );
        await a.deps.familyRepository.add(
          FamilyMember(
            id: 'a-other',
            name: 'ילד פרטי',
            relation: FamilyRelation.child,
          ),
        );
        await shareChild();
        await b.sync();
        final bytes = server.allBytes;
        bool contains(List<int> needle) {
          outer:
          for (var i = 0; i + needle.length <= bytes.length; i++) {
            for (var j = 0; j < needle.length; j++) {
              if (bytes[i + j] != needle[j]) continue outer;
            }
            return true;
          }
          return false;
        }

        for (final text in [
          'נועה',
          'פרטי בדוי',
          'ילד פרטי',
          'child-noa',
          'b-self',
          'appt-1',
          'שיעול',
        ]) {
          expect(contains(utf8.encode(text)), isFalse, reason: text);
        }
        expect(contains(photo.sublist(0, 64)), isFalse);
        expect(await a.deps.familyRepository.getById('b-self'), isNull);
        expect(await b.deps.familyRepository.getById('a-other'), isNull);
      },
    );

    test('offline edits wait, then merge with the other parent\'s', () async {
      await joinBoth();
      await shareChild();

      a.cloud.offline = true;
      await a.deps.appointmentRepository.update(
        appointment.copyWith(notes: () => 'הערה מ־A'),
      );
      await expectLater(
        a.sync(),
        throwsA(
          isA<SyncException>().having(
            (e) => e.failure,
            'failure',
            SyncFailure.network,
          ),
        ),
      );
      expect(await a.deps.syncStateRepository.pendingChanges(), isNotEmpty);
      await b.deps.appointmentRepository.update(
        appointment.copyWith(location: () => 'מרפאה חדשה'),
      );
      await b.sync();

      a.cloud.offline = false;
      await a.sync();
      await b.sync();
      await a.sync();
      final expected = appointment.copyWith(
        notes: () => 'הערה מ־A',
        location: () => 'מרפאה חדשה',
      );
      expect(await a.deps.appointmentRepository.getById('appt-1'), expected);
      expect(await b.deps.appointmentRepository.getById('appt-1'), expected);
      expect(await a.conflicts(), isEmpty);
      expect(await b.conflicts(), isEmpty);
      expect(await a.deps.syncStateRepository.pendingChanges(), isEmpty);
    });

    test(
      'the same field edited on both is a conflict, never overwritten',
      () async {
        await joinBoth();
        await shareChild();
        await a.deps.appointmentRepository.update(
          appointment.copyWith(doctorName: 'ד"ר א'),
        );
        await b.deps.appointmentRepository.update(
          appointment.copyWith(doctorName: 'ד"ר ב'),
        );
        await a.sync();
        final report = await b.sync();
        expect(report.newConflicts, 1);

        final conflict = (await b.conflicts()).single;
        expect(conflict.reason, ConflictReason.edited);
        expect(conflict.fields, ['doctorName']);
        expect(conflict.local!['doctorName'], 'ד"ר ב');
        expect(conflict.remote!['doctorName'], 'ד"ר א');
        // B keeps its version until the user decides.
        expect(
          (await b.deps.appointmentRepository.getById('appt-1'))!.doctorName,
          'ד"ר ב',
        );

        await b.engine.resolve(conflict, ConflictChoice.keepThisDevice);
        await b.sync();
        await a.sync();
        expect(
          (await a.deps.appointmentRepository.getById('appt-1'))!.doctorName,
          'ד"ר ב',
        );
        expect(await a.conflicts(), isEmpty);
        expect(await b.conflicts(), isEmpty);
      },
    );

    test('choosing the other version takes it', () async {
      await joinBoth();
      await shareChild();
      await a.deps.symptomRepository.update(symptom.copyWith(severity: 4));
      await b.deps.symptomRepository.update(symptom.copyWith(severity: 1));
      await a.sync();
      await b.sync();
      final conflict = (await b.conflicts()).single;
      await b.engine.resolve(conflict, ConflictChoice.useOther);
      expect(
        (await b.deps.symptomRepository.getById('symptom-1'))!.severity,
        4,
      );
      await b.sync();
      await a.sync();
      expect(
        (await a.deps.symptomRepository.getById('symptom-1'))!.severity,
        4,
      );
      expect(await a.conflicts(), isEmpty);
    });

    test('a deletion waits for confirmation, and never comes back', () async {
      await joinBoth();
      await shareChild();
      await a.deps.symptomRepository.delete('symptom-1');
      await a.sync();
      await b.sync();

      // Still on B until confirmed.
      expect(await b.deps.symptomRepository.getById('symptom-1'), isNotNull);
      final conflict = (await b.conflicts()).single;
      expect(conflict.reason, ConflictReason.deleted);

      // Confirmed: deleted the normal way, then recorded.
      await b.deps.symptomRepository.delete('symptom-1');
      await b.engine.resolve(conflict, ConflictChoice.useOther);
      await b.sync();
      await a.sync();
      await b.sync();
      expect(await a.deps.symptomRepository.getById('symptom-1'), isNull);
      expect(await b.deps.symptomRepository.getById('symptom-1'), isNull);
      expect(await b.conflicts(), isEmpty);

      // A third phone of A's account replays the whole history.
      final c = await _Phone.create(
        temp,
        'c',
        server,
        uid: 'uid-c',
        clock: clock,
      );
      addTearDown(c.database.close);
      final code = await a.households.invite(a.account);
      await c.households.respond(
        c.account,
        await c.households.lookup(c.account, code.format()),
        accept: true,
      );
      final invite = (await a.households.invites(
        a.account,
      )).firstWhere((i) => i.status == InviteStatus.accepted);
      await a.households.completeInvite(
        a.account,
        invite.id,
        role: HouseholdRole.member,
      );
      await c.households.checkJoined(c.account);
      await c.sync();
      expect(await c.deps.symptomRepository.getById('symptom-1'), isNull);
      expect(await c.deps.appointmentRepository.getById('appt-1'), appointment);
    });

    test(
      'keeping a record deleted elsewhere brings it back for everyone',
      () async {
        await joinBoth();
        await shareChild();
        await a.deps.symptomRepository.delete('symptom-1');
        await a.sync();
        await b.sync();
        await b.engine.resolve(
          (await b.conflicts()).single,
          ConflictChoice.keepThisDevice,
        );
        await b.sync();
        await a.sync();
        expect(await a.deps.symptomRepository.getById('symptom-1'), symptom);
      },
    );

    test('an edit of a record deleted here is a conflict', () async {
      await joinBoth();
      await shareChild();
      await a.deps.symptomRepository.update(symptom.copyWith(severity: 5));
      await b.deps.symptomRepository.delete('symptom-1');
      await a.sync();
      await b.sync();
      final conflict = (await b.conflicts()).single;
      expect(conflict.reason, ConflictReason.deletedHere);
      await b.engine.resolve(conflict, ConflictChoice.useOther);
      expect(
        (await b.deps.symptomRepository.getById('symptom-1'))!.severity,
        5,
      );
    });

    test('one dose marked on both phones stays one record', () async {
      await joinBoth();
      await shareChild();
      final at = DateTime(2026, 10, 19, 8);
      Future<void> mark(_Phone phone, DoseStatus status, int minute) =>
          phone.deps.doseRecordRepository.save(
            DoseRecord(
              id: DoseRecord.idFor('med-1', at),
              memberId: 'child-noa',
              medicationId: 'med-1',
              scheduledAt: at,
              status: status,
              recordedAt: DateTime(2026, 10, 19, 8, minute),
            ),
          );
      await mark(a, DoseStatus.taken, 2);
      await mark(b, DoseStatus.taken, 9);
      await a.sync();
      await b.sync();
      await a.sync();
      for (final phone in [a, b]) {
        final records = await phone.deps.doseRecordRepository.getAll(
          medicationId: 'med-1',
        );
        final ofDay = records.where((r) => r.scheduledAt == at).toList();
        expect(ofDay, hasLength(1));
        expect(ofDay.single.id, DoseRecord.idFor('med-1', at));
        // The same status: no conflict; the later time of recording.
        expect(ofDay.single.recordedAt, DateTime(2026, 10, 19, 8, 9));
        expect(await phone.conflicts(), isEmpty);
      }
    });

    test('a dose marked differently on both phones is a conflict', () async {
      await joinBoth();
      await shareChild();
      final at = DateTime(2026, 10, 19, 20);
      for (final (phone, status) in [
        (a, DoseStatus.taken),
        (b, DoseStatus.skipped),
      ]) {
        await phone.deps.doseRecordRepository.save(
          DoseRecord(
            id: DoseRecord.idFor('med-1', at),
            memberId: 'child-noa',
            medicationId: 'med-1',
            scheduledAt: at,
            status: status,
            recordedAt: at,
          ),
        );
      }
      await a.sync();
      await b.sync();
      final conflict = (await b.conflicts()).single;
      expect(conflict.kind, SyncKind.dose);
      expect(conflict.fields, ['status']);
    });

    test(
      'a question added to an appointment deleted elsewhere waits safely',
      () async {
        await joinBoth();
        await shareChild();
        // A deletes the appointment (as AppointmentController does).
        await a.deps.transactions.run(() async {
          await a.deps.doctorQuestionRepository.detachFromAppointment('appt-1');
          await a.deps.visitMediaRepository.deleteByAppointment('appt-1');
          await a.deps.appointmentRepository.delete('appt-1');
        });
        // B adds a question to it meanwhile.
        await b.deps.doctorQuestionRepository.add(
          DoctorQuestion(
            id: 'question-2',
            memberId: 'child-noa',
            appointmentId: 'appt-1',
            text: 'שאלה חדשה',
            createdAt: DateTime(2026, 10, 19),
          ),
        );
        await a.sync();
        final report = await b.sync();
        // B keeps the appointment until the user decides.
        expect(await b.deps.appointmentRepository.getById('appt-1'), isNotNull);
        expect(report.newConflicts, greaterThan(0));
        // A cannot place the new question yet; nothing breaks.
        final fromA = await a.sync();
        expect(fromA.waiting, 1);
        expect(
          await a.deps.doctorQuestionRepository.getById('question-2'),
          isNull,
        );
      },
    );

    test('unsharing keeps every copy and stops syncing', () async {
      await joinBoth();
      await shareChild();
      await a.engine.unshare('child-noa');
      await a.sync();
      await b.sync();
      expect(await b.deps.syncStateRepository.sharedMemberIds(), isEmpty);
      expect(await b.deps.familyRepository.getById('child-noa'), child);

      await a.deps.symptomRepository.update(symptom.copyWith(notes: () => 'x'));
      await a.sync();
      await b.sync();
      expect(
        (await b.deps.symptomRepository.getById('symptom-1'))!.notes,
        isNull,
      );
    });
  });

  group('revocation and keys', () {
    test('a removed member loses access and cannot read new changes', () async {
      await joinBoth();
      await shareChild();
      final oldKeys = await b.keys.readHouseholdKeys(
        (await b.deps.syncStateRepository.settings()).householdId!,
      );

      await a.households.revoke(a.account, 'uid-b');
      final household = server.households.values.single;
      expect(household.epoch, 2);
      expect(server.members[household.id]!.keys, ['uid-a']);

      await a.deps.symptomRepository.update(
        symptom.copyWith(notes: () => 'אחרי ההסרה'),
      );
      await a.sync();

      await expectLater(
        b.sync(),
        throwsA(
          isA<SyncException>().having(
            (e) => e.failure,
            'failure',
            SyncFailure.removed,
          ),
        ),
      );
      final settings = await b.deps.syncStateRepository.settings();
      expect(settings.state, SyncState.removed);
      expect(settings.householdId, isNull);
      // B's data stays on B.
      expect(await b.deps.familyRepository.getById('child-noa'), child);
      // The server refuses B, and B's old key opens no new change.
      await expectLater(
        b.cloud.devices(household.id),
        throwsA(isA<HouseholdCloudException>()),
      );
      final newest = server.logs[household.id]!.values
          .expand((entries) => entries.values)
          .where((e) => e.epoch == 2);
      expect(newest, isNotEmpty);
      expect(oldKeys.keys, [1]);
    });

    test('a member who leaves triggers a key rotation at the admin', () async {
      await joinBoth();
      await shareChild();
      await b.households.leave(b.account);
      expect(
        (await b.deps.syncStateRepository.settings()).state,
        SyncState.off,
      );
      expect(server.households.values.single.needsRotation, isTrue);
      await a.sync();
      final household = server.households.values.single;
      expect(household.epoch, 2);
      expect(household.needsRotation, isFalse);
    });

    test('the last admin cannot leave while others remain', () async {
      await joinBoth();
      await expectLater(
        a.households.leave(a.account),
        throwsA(
          isA<HouseholdException>().having(
            (e) => e.failure,
            'failure',
            HouseholdFailure.lastAdmin,
          ),
        ),
      );
    });

    test('a member is never given keys by a non-admin', () async {
      await joinBoth();
      await expectLater(
        b.households.invite(b.account),
        throwsA(
          isA<HouseholdException>().having(
            (e) => e.failure,
            'failure',
            HouseholdFailure.notAdmin,
          ),
        ),
      );
    });
  });

  group('restore from backup', () {
    test('resets sync history and never pushes mass deletions', () async {
      await joinBoth();
      await shareChild();
      final snapshot = await RepositoryBackupDataStore(b.deps).export();
      expect(snapshot.sharedMemberIds, ['child-noa']);

      await a.deps.symptomRepository.add(
        SymptomEntry(
          id: 'symptom-2',
          memberId: 'child-noa',
          name: 'חום בדוי',
          startedAt: DateTime(2026, 10, 18, 7),
          severity: 3,
        ),
      );
      await a.sync();
      await b.sync();
      expect(await b.deps.symptomRepository.getById('symptom-2'), isNotNull);

      // B restores the older backup: symptom-2 is not in it.
      await RepositoryBackupDataStore(
        b.deps,
        clock: clock,
      ).replaceAll(snapshot);
      expect(await b.deps.symptomRepository.getById('symptom-2'), isNull);
      final pending = await b.deps.syncStateRepository.pendingChanges();
      expect(pending.where((p) => p.syncId == 'symptom-2'), isEmpty);

      await b.sync();
      await a.sync();
      // Nothing was deleted at A, and B has the household's data again.
      expect(await a.deps.symptomRepository.getById('symptom-2'), isNotNull);
      expect(await b.deps.symptomRepository.getById('symptom-2'), isNotNull);
      expect(await a.conflicts(), isEmpty);
      expect(await b.conflicts(), isEmpty);
      expect(await b.deps.syncStateRepository.sharedMemberIds(), {'child-noa'});
    });
  });
}
