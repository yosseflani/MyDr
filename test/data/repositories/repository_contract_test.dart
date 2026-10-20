import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/data/models/sync_state.dart';

import '../../helpers/memory_key_store.dart';

/// The same expectations, run against every repository implementation:
/// the in-memory one used in demo mode and tests, and the encrypted local
/// database used by the app. Whatever passes here behaves the same for the
/// controllers on both. Test data is fictional and non-medical.
void main() {
  final implementations =
      <String, Future<(AppDependencies, Future<void> Function())> Function()>{
        'in memory': () async => (AppDependencies.empty(), () async {}),
        'local database': () async {
          final directory = Directory.systemTemp.createTempSync(
            'mydr_contract',
          );
          final database = await LocalDatabaseOpener(
            keyStore: MemoryDatabaseKeyStore(),
            locateFile: () async => File('${directory.path}/contract.sqlite'),
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

  final dana = FamilyMember(
    id: 'm1',
    name: 'דנה',
    relation: FamilyRelation.self,
    birthDate: DateTime(1988, 4, 12),
    allergies: const ['אבקה', 'חתולים'],
    chronicConditions: const ['מצב בדיקה'],
    notes: 'הערה',
  );
  final noa = FamilyMember(
    id: 'm2',
    name: 'נועה',
    relation: FamilyRelation.child,
  );
  final itai = FamilyMember(
    id: 'm3',
    name: 'איתי',
    relation: FamilyRelation.child,
  );

  Appointment appointment(String id, String memberId, DateTime at) =>
      Appointment(
        id: id,
        memberId: memberId,
        doctorName: 'רופא $id',
        dateTime: at,
      );

  DoctorQuestion question(
    String id,
    String memberId,
    DateTime createdAt, {
    String? appointmentId,
  }) => DoctorQuestion(
    id: id,
    memberId: memberId,
    appointmentId: appointmentId,
    text: 'שאלה $id',
    createdAt: createdAt,
  );

  SymptomEntry symptom(String id, String memberId, DateTime at) => SymptomEntry(
    id: id,
    memberId: memberId,
    name: 'תסמין $id',
    startedAt: at,
    severity: 3,
  );

  for (final MapEntry(key: name, value: create) in implementations.entries) {
    group(name, () {
      late AppDependencies repos;
      late Future<void> Function() close;

      setUp(() async {
        (repos, close) = await create();
      });
      tearDown(() => close());

      Future<void> addFamily() async {
        for (final member in [noa, dana, itai]) {
          await repos.familyRepository.add(member);
        }
      }

      group('family', () {
        test('new ids are unique', () {
          final ids = {
            for (var i = 0; i < 50; i++) repos.familyRepository.createId(),
          };
          expect(ids, hasLength(50));
        });

        test('stores and reads back every field', () async {
          await repos.familyRepository.add(dana);
          expect(await repos.familyRepository.getById('m1'), dana);
          expect(await repos.familyRepository.getById('missing'), isNull);
        });

        test('lists by relation, then name', () async {
          await addFamily();
          final all = await repos.familyRepository.getAll();
          expect([for (final m in all) m.id], ['m1', 'm3', 'm2']);
          expect(() => all.clear(), throwsUnsupportedError);
        });

        test('updates, including clearing optional fields', () async {
          await repos.familyRepository.add(dana);
          final changed = dana.copyWith(
            name: 'דנה ל.',
            birthDate: () => null,
            allergies: const [],
            notes: () => null,
          );
          await repos.familyRepository.update(changed);
          expect(await repos.familyRepository.getById('m1'), changed);
        });

        test('a duplicate id or a missing record is an error', () async {
          await repos.familyRepository.add(dana);
          await expectLater(repos.familyRepository.add(dana), throwsStateError);
          await expectLater(
            repos.familyRepository.update(noa),
            throwsStateError,
          );
        });

        test('deletes; deleting a missing record does nothing', () async {
          await addFamily();
          await repos.familyRepository.delete('m2');
          await repos.familyRepository.delete('missing');
          expect(await repos.familyRepository.getById('m2'), isNull);
          expect(await repos.familyRepository.getAll(), hasLength(2));
        });
      });

      group('appointments', () {
        setUp(addFamily);

        test(
          'store every field and list by time, filtered by member',
          () async {
            final full = Appointment(
              id: 'a1',
              memberId: 'm1',
              doctorName: 'רופא',
              dateTime: DateTime(2026, 10, 20, 9, 30),
              specialty: 'תחום',
              location: 'מקום',
              notes: 'הערה',
            );
            await repos.appointmentRepository.add(full);
            await repos.appointmentRepository.add(
              appointment('a2', 'm2', DateTime(2026, 10, 18, 16)),
            );
            await repos.appointmentRepository.add(
              appointment('a3', 'm1', DateTime(2025, 1, 1, 8)),
            );

            expect(await repos.appointmentRepository.getById('a1'), full);
            expect(
              [
                for (final a in await repos.appointmentRepository.getAll())
                  a.id,
              ],
              ['a3', 'a2', 'a1'],
            );
            expect(
              [
                for (final a in await repos.appointmentRepository.getAll(
                  memberId: 'm1',
                ))
                  a.id,
              ],
              ['a3', 'a1'],
            );
          },
        );

        test('update, move to another member, and delete by member', () async {
          final a1 = appointment('a1', 'm1', DateTime(2026, 10, 20, 9));
          await repos.appointmentRepository.add(a1);
          await repos.appointmentRepository.add(
            appointment('a2', 'm2', DateTime(2026, 10, 21, 9)),
          );

          final moved = a1.copyWith(memberId: 'm3', notes: () => 'הועבר');
          await repos.appointmentRepository.update(moved);
          expect(await repos.appointmentRepository.getById('a1'), moved);

          await repos.appointmentRepository.deleteByMember('m2');
          expect(
            [for (final a in await repos.appointmentRepository.getAll()) a.id],
            ['a1'],
          );
        });

        test('a duplicate id or a missing record is an error', () async {
          final a1 = appointment('a1', 'm1', DateTime(2026, 10, 20, 9));
          await repos.appointmentRepository.add(a1);
          await expectLater(
            repos.appointmentRepository.add(a1),
            throwsStateError,
          );
          await expectLater(
            repos.appointmentRepository.update(
              appointment('missing', 'm1', DateTime(2026, 10, 20, 9)),
            ),
            throwsStateError,
          );
        });
      });

      group('questions', () {
        setUp(() async {
          await addFamily();
          await repos.appointmentRepository.add(
            appointment('a1', 'm1', DateTime(2026, 10, 20, 9)),
          );
        });

        test('store every field, to the microsecond', () async {
          final q = DoctorQuestion(
            id: 'q1',
            memberId: 'm1',
            appointmentId: 'a1',
            text: 'שאלה',
            createdAt: DateTime(2026, 10, 15, 12, 30, 5, 123, 456),
            isResolved: true,
            doctorAnswer: 'תשובה',
          );
          await repos.doctorQuestionRepository.add(q);
          expect(await repos.doctorQuestionRepository.getById('q1'), q);
        });

        test('list oldest first, filtered by member and appointment', () async {
          final base = DateTime(2026, 10, 1);
          await repos.doctorQuestionRepository.add(
            question('q1', 'm1', base.add(const Duration(days: 3))),
          );
          await repos.doctorQuestionRepository.add(
            question(
              'q2',
              'm1',
              base.add(const Duration(days: 1)),
              appointmentId: 'a1',
            ),
          );
          await repos.doctorQuestionRepository.add(
            question('q3', 'm2', base.add(const Duration(days: 2))),
          );

          Future<List<String>> ids({
            String? memberId,
            String? appointmentId,
          }) async => [
            for (final q in await repos.doctorQuestionRepository.getAll(
              memberId: memberId,
              appointmentId: appointmentId,
            ))
              q.id,
          ];
          expect(await ids(), ['q2', 'q3', 'q1']);
          expect(await ids(memberId: 'm1'), ['q2', 'q1']);
          expect(await ids(appointmentId: 'a1'), ['q2']);
          expect(await ids(memberId: 'm2', appointmentId: 'a1'), isEmpty);
        });

        test('unlinking an appointment keeps its questions', () async {
          await repos.doctorQuestionRepository.add(
            question('q1', 'm1', DateTime(2026, 10, 1), appointmentId: 'a1'),
          );
          await repos.doctorQuestionRepository.detachFromAppointment('a1');

          final q = await repos.doctorQuestionRepository.getById('q1');
          expect(q, isNotNull);
          expect(q!.appointmentId, isNull);
        });

        test('update and delete by member', () async {
          final q1 = question('q1', 'm1', DateTime(2026, 10, 1));
          await repos.doctorQuestionRepository.add(q1);
          await repos.doctorQuestionRepository.add(
            question('q2', 'm2', DateTime(2026, 10, 2)),
          );
          final resolved = q1.copyWith(
            isResolved: true,
            doctorAnswer: () => 'תשובה',
          );
          await repos.doctorQuestionRepository.update(resolved);
          expect(await repos.doctorQuestionRepository.getById('q1'), resolved);

          await repos.doctorQuestionRepository.deleteByMember('m1');
          expect(
            [
              for (final q in await repos.doctorQuestionRepository.getAll())
                q.id,
            ],
            ['q2'],
          );
        });
      });

      group('symptoms', () {
        setUp(addFamily);

        test('store every field and list newest first', () async {
          final full = SymptomEntry(
            id: 's1',
            memberId: 'm1',
            name: '  שם   עם רווחים ',
            startedAt: DateTime(2026, 10, 14, 8, 0, 0, 0, 1),
            severity: 5,
            status: SymptomStatus.resolved,
            duration: const Duration(hours: 3, microseconds: 7),
            notes: 'הערה',
          );
          await repos.symptomRepository.add(full);
          await repos.symptomRepository.add(
            symptom('s2', 'm2', DateTime(2026, 10, 15, 8)),
          );
          await repos.symptomRepository.add(
            symptom('s3', 'm1', DateTime(2026, 10, 1, 8)),
          );

          expect(await repos.symptomRepository.getById('s1'), full);
          expect(
            [for (final s in await repos.symptomRepository.getAll()) s.id],
            ['s2', 's1', 's3'],
          );
          expect(
            [
              for (final s in await repos.symptomRepository.getAll(
                memberId: 'm1',
              ))
                s.id,
            ],
            ['s1', 's3'],
          );
        });

        test('update keeps status and duration; delete by member', () async {
          final s1 = symptom(
            's1',
            'm1',
            DateTime(2026, 10, 14, 8),
          ).copyWith(status: SymptomStatus.resolved);
          await repos.symptomRepository.add(s1);
          await repos.symptomRepository.add(
            symptom('s2', 'm2', DateTime(2026, 10, 14, 9)),
          );
          final changed = s1.copyWith(severity: 1, notes: () => 'עודכן');
          await repos.symptomRepository.update(changed);
          expect(await repos.symptomRepository.getById('s1'), changed);

          await repos.symptomRepository.deleteByMember('m1');
          expect(
            [for (final s in await repos.symptomRepository.getAll()) s.id],
            ['s2'],
          );
          await expectLater(
            repos.symptomRepository.update(changed),
            throwsStateError,
          );
        });
      });

      test(
        'deleting a member the way the app does leaves nothing behind',
        () async {
          await addFamily();
          await repos.appointmentRepository.add(
            appointment('a1', 'm2', DateTime(2026, 10, 20, 9)),
          );
          await repos.doctorQuestionRepository.add(
            question('q1', 'm2', DateTime(2026, 10, 1), appointmentId: 'a1'),
          );
          await repos.symptomRepository.add(
            symptom('s1', 'm2', DateTime(2026, 10, 1)),
          );

          await repos.symptomRepository.deleteByMember('m2');
          await repos.doctorQuestionRepository.deleteByMember('m2');
          await repos.appointmentRepository.deleteByMember('m2');
          await repos.familyRepository.delete('m2');

          expect(await repos.familyRepository.getById('m2'), isNull);
          expect(await repos.appointmentRepository.getAll(), isEmpty);
          expect(await repos.doctorQuestionRepository.getAll(), isEmpty);
          expect(await repos.symptomRepository.getAll(), isEmpty);
        },
      );

      group('sync state', () {
        test('settings start off, with a lasting device id', () async {
          final state = repos.syncStateRepository;
          final first = await state.settings();
          expect(first.state, SyncState.off);
          expect(first.householdId, isNull);
          expect(first.deviceId, isNotEmpty);
          expect((await state.settings()).deviceId, first.deviceId);
          final joined = first.copyWith(
            householdId: () => 'h1',
            accountUid: () => 'uid-1',
            role: () => HouseholdRole.member,
            state: SyncState.active,
            lastSyncAt: () => DateTime(2026, 10, 19, 12, 0, 0, 0, 7),
            nextSeq: 3,
          );
          await state.saveSettings(joined);
          expect(await state.settings(), joined);
        });

        test('only a child can be shared; stopping keeps the profile', () async {
          await addFamily();
          final state = repos.syncStateRepository;
          await state.setShared('m2', shared: true, at: DateTime(2026));
          await expectLater(
            state.setShared('m1', shared: true, at: DateTime(2026)),
            throwsStateError,
          );
          await expectLater(
            state.setShared('missing', shared: true, at: DateTime(2026)),
            throwsStateError,
          );
          expect(await state.sharedMemberIds(), {'m2'});
          await state.setShared('m2', shared: false);
          expect(await state.sharedMemberIds(), isEmpty);
          expect(await repos.familyRepository.getById('m2'), noa);
        });

        test('pending changes count up and clear only what was sent', () async {
          final state = repos.syncStateRepository;
          await state.markPending(SyncKind.symptom, 's1', 's1');
          await state.markPending(SyncKind.symptom, 's1', 's1');
          final pending = (await state.pendingChanges()).single;
          expect(pending.changeCount, 2);
          await state.clearPending(
            const PendingChange(
              kind: SyncKind.symptom,
              syncId: 's1',
              localId: 's1',
              changeCount: 1,
            ),
          );
          expect(await state.pendingChanges(), hasLength(1));
          await state.clearPending(pending);
          expect(await state.pendingChanges(), isEmpty);
        });

        test('records, tombstones and parked records round-trip', () async {
          final state = repos.syncStateRepository;
          final record = SyncRecordState(
            kind: SyncKind.dose,
            syncId: 'med@2026-10-19T08:00:00.000000',
            localId: 'local-dose',
            memberId: 'm2',
            vector: VersionVector({'d1': 2, 'd2': 1}),
            updatedAt: DateTime(2026, 10, 19, 8, 0, 0, 0, 5),
            updatedBy: 'd1',
            base: {
              'status': 'taken',
              'list': ['a'],
              'n': null,
            },
          );
          final tombstone = SyncRecordState(
            kind: SyncKind.symptom,
            syncId: 's1',
            localId: 's1',
            memberId: 'm2',
            vector: VersionVector({'d2': 1}),
            updatedAt: DateTime(2026, 10, 19),
            updatedBy: 'd2',
            deleted: true,
          );
          final parked = tombstone.copyWith(
            deleted: false,
            base: () => {'id': 'q1'},
            parked: true,
          );
          await state.saveRecord(record);
          await state.saveRecord(tombstone);
          expect(await state.record(SyncKind.dose, record.syncId), record);
          expect(
            await state.recordByLocalId(SyncKind.dose, 'local-dose'),
            record,
          );
          expect(await state.record(SyncKind.symptom, 's1'), tombstone);
          await state.saveRecord(parked);
          expect(await state.records(parked: true), [parked]);
          expect(await state.records(memberId: 'm2'), hasLength(2));
          expect(await state.record(SyncKind.member, 'none'), isNull);
        });

        test('conflicts round-trip and are removed', () async {
          final state = repos.syncStateRepository;
          final conflict = SyncConflict(
            kind: SyncKind.appointment,
            syncId: 'a1',
            localId: 'a1',
            memberId: 'm2',
            reason: ConflictReason.edited,
            local: {'doctorName': 'x'},
            remote: {'doctorName': 'y'},
            remoteVector: VersionVector({'d2': 3}),
            remoteUpdatedAt: DateTime(2026, 10, 19, 9),
            remoteUpdatedBy: 'd2',
            fields: const ['doctorName'],
            detectedAt: DateTime(2026, 10, 19, 10),
          );
          await state.saveConflict(conflict);
          expect(await state.conflicts(), [conflict]);
          expect(await state.conflict(SyncKind.appointment, 'a1'), conflict);
          await state.deleteConflict(SyncKind.appointment, 'a1');
          expect(await state.conflicts(), isEmpty);
        });

        test('cursors and verified members', () async {
          final state = repos.syncStateRepository;
          await state.saveCursor('d1', 4);
          await state.saveCursor('d1', 5);
          expect(await state.cursors(), {'d1': 5});
          const member = KnownMember(
            uid: 'u1',
            publicKey: 'cHVibGlj',
            role: HouseholdRole.admin,
            label: 'a@example.test',
          );
          await state.saveKnownMember(member);
          expect(await state.knownMembers(), [member]);
          await state.deleteKnownMember('u1');
          expect(await state.knownMembers(), isEmpty);
        });

        test(
          'reset keeps family data; clearing also forgets the household',
          () async {
            await addFamily();
            final state = repos.syncStateRepository;
            await state.saveSettings(
              (await state.settings()).copyWith(
                householdId: () => 'h1',
                state: SyncState.active,
              ),
            );
            await state.setShared('m2', shared: true, at: DateTime(2026));
            await state.markPending(SyncKind.member, 'm2', 'm2');
            await state.saveCursor('d1', 2);
            await state.saveKnownMember(
              const KnownMember(
                uid: 'u1',
                publicKey: 'cA==',
                role: HouseholdRole.member,
              ),
            );
            await state.resetHistory();
            expect(await state.sharedMemberIds(), isEmpty);
            expect(await state.pendingChanges(), isEmpty);
            expect(await state.cursors(), isEmpty);
            expect((await state.settings()).householdId, 'h1');
            expect(await state.knownMembers(), hasLength(1));

            final deviceId = (await state.settings()).deviceId;
            await state.clearHousehold(state: SyncState.removed);
            final settings = await state.settings();
            expect(settings.householdId, isNull);
            expect(settings.state, SyncState.removed);
            expect(settings.deviceId, deviceId);
            expect(await state.knownMembers(), isEmpty);
            expect(await repos.familyRepository.getAll(), hasLength(3));
          },
        );
      });
    });
  }
}
