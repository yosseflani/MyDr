import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:mydr/data/local/local_ids.dart';
import 'package:mydr/data/local/local_transaction_runner.dart';
import 'package:mydr/data/local/repositories/local_repository_support.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/symptom_entry.dart';

import '../../helpers/memory_key_store.dart';

/// Behavior specific to the encrypted local database (the shared behavior
/// is in repository_contract_test.dart). Fictional, non-medical data.
void main() {
  late Directory directory;
  late MemoryDatabaseKeyStore keys;
  late LocalDatabase database;
  late AppDependencies repos;

  Future<LocalDatabase> open() => LocalDatabaseOpener(
    keyStore: keys,
    locateFile: () async => File('${directory.path}/repos.sqlite'),
  ).open();

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('mydr_local_repos');
    keys = MemoryDatabaseKeyStore();
    database = await open();
    repos = AppDependencies.local(database);
  });

  tearDown(() async {
    await database.close();
    directory.deleteSync(recursive: true);
  });

  Matcher rejectedWith(LocalDataError error) =>
      throwsA(isA<LocalDataException>().having((e) => e.error, 'error', error));

  final noa = FamilyMember(
    id: 'm1',
    name: 'נועה',
    relation: FamilyRelation.child,
    allergies: const ['אבקה'],
  );
  final avi = FamilyMember(
    id: 'm2',
    name: 'אבי',
    relation: FamilyRelation.spouse,
  );
  final visit = Appointment(
    id: 'a1',
    memberId: 'm1',
    doctorName: 'רופא בדיקה',
    dateTime: DateTime(2026, 10, 20, 9, 30),
  );
  final linked = DoctorQuestion(
    id: 'q1',
    memberId: 'm1',
    appointmentId: 'a1',
    text: 'שאלת בדיקה',
    createdAt: DateTime(2026, 10, 15, 12, 0, 0, 1, 2),
  );
  final cough = SymptomEntry(
    id: 's1',
    memberId: 'm1',
    name: 'תסמין בדיקה',
    startedAt: DateTime(2026, 10, 14, 8, 15),
    severity: 2,
    duration: const Duration(minutes: 90),
  );

  Future<void> addAll() async {
    await repos.familyRepository.add(noa);
    await repos.familyRepository.add(avi);
    await repos.appointmentRepository.add(visit);
    await repos.doctorQuestionRepository.add(linked);
    await repos.symptomRepository.add(cough);
  }

  test('everything survives closing and opening the database again', () async {
    await addAll();
    await database.close();

    database = await open();
    repos = AppDependencies.local(database);

    expect(await repos.familyRepository.getAll(), [avi, noa]);
    expect(await repos.appointmentRepository.getAll(), [visit]);
    expect(await repos.doctorQuestionRepository.getAll(), [linked]);
    expect(await repos.symptomRepository.getAll(), [cough]);
    expect(keys.writes, 1);
  });

  test('new ids are random UUIDs', () {
    final pattern = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
    );
    final ids = {for (var i = 0; i < 100; i++) LocalIds.generate()};
    expect(ids, hasLength(100));
    expect(ids.every(pattern.hasMatch), isTrue);
    expect(repos.symptomRepository.createId(), matches(pattern));
  });

  group('the database itself keeps records consistent', () {
    setUp(addAll);

    test('no record for a missing family member', () async {
      await expectLater(
        repos.symptomRepository.add(
          cough.copyWith(memberId: 'missing').copyWithId('s2'),
        ),
        rejectedWith(LocalDataError.rejected),
      );
      await expectLater(
        repos.appointmentRepository.add(
          Appointment(
            id: 'a2',
            memberId: 'missing',
            doctorName: 'רופא',
            dateTime: DateTime(2026, 11, 1, 9),
          ),
        ),
        rejectedWith(LocalDataError.rejected),
      );
    });

    test("no question linked to another member's appointment", () async {
      await expectLater(
        repos.doctorQuestionRepository.add(
          DoctorQuestion(
            id: 'q2',
            memberId: 'm2',
            appointmentId: 'a1',
            text: 'שאלה',
            createdAt: DateTime(2026, 10, 15),
          ),
        ),
        rejectedWith(LocalDataError.rejected),
      );
      await expectLater(
        repos.doctorQuestionRepository.update(linked.copyWith(memberId: 'm2')),
        rejectedWith(LocalDataError.rejected),
      );
    });

    test('a member with records cannot be deleted on its own', () async {
      await expectLater(
        repos.familyRepository.delete('m1'),
        rejectedWith(LocalDataError.rejected),
      );
      expect(await repos.familyRepository.getById('m1'), noa);
    });

    test('an appointment with linked questions is not deleted or moved '
        'until they are unlinked', () async {
      await expectLater(
        repos.appointmentRepository.delete('a1'),
        rejectedWith(LocalDataError.rejected),
      );
      await expectLater(
        repos.appointmentRepository.update(visit.copyWith(memberId: 'm2')),
        rejectedWith(LocalDataError.rejected),
      );

      await repos.doctorQuestionRepository.detachFromAppointment('a1');
      await repos.appointmentRepository.delete('a1');
      expect(
        (await repos.doctorQuestionRepository.getById('q1'))!.appointmentId,
        isNull,
      );
    });

    test('invalid values are refused', () async {
      await expectLater(
        repos.familyRepository.add(
          FamilyMember(id: 'm3', name: '   ', relation: FamilyRelation.child),
        ),
        rejectedWith(LocalDataError.rejected),
      );
      await expectLater(
        repos.familyRepository.add(
          FamilyMember(id: 'm4', name: 'שני', relation: FamilyRelation.self),
        ),
        completes,
      );
      await expectLater(
        repos.familyRepository.add(
          FamilyMember(id: 'm5', name: 'שלישי', relation: FamilyRelation.self),
        ),
        rejectedWith(LocalDataError.rejected),
      );
    });
  });

  test('errors never include stored values', () async {
    await addAll();
    try {
      await repos.familyRepository.delete('m1');
      fail('should be refused');
    } on LocalDataException catch (e) {
      final message = e.toString();
      expect(message, 'LocalDataException(rejected)');
      expect(message, isNot(contains('נועה')));
    }
  });

  test('a stored value that cannot be read is reported, not guessed', () async {
    await database.customStatement(
      'INSERT INTO family_members (id, name, relation, allergies) '
      "VALUES ('bad', 'בדיקה', 'child', '[1, 2]')",
    );

    await expectLater(
      repos.familyRepository.getAll(),
      rejectedWith(LocalDataError.unreadable),
    );
  });

  group('transactions', () {
    setUp(addAll);

    test('a failure undoes every change made in it', () async {
      final transactions = LocalTransactionRunner(database);
      expect(transactions.isAtomic, isTrue);

      await expectLater(
        transactions.run(() async {
          await repos.symptomRepository.deleteByMember('m1');
          await repos.doctorQuestionRepository.deleteByMember('m1');
          throw StateError('a later step failed');
        }),
        throwsStateError,
      );

      expect(await repos.symptomRepository.getAll(), [cough]);
      expect(await repos.doctorQuestionRepository.getAll(), [linked]);
    });

    test('success keeps every change', () async {
      final transactions = LocalTransactionRunner(database);
      await transactions.run(() async {
        await repos.symptomRepository.deleteByMember('m1');
        await repos.doctorQuestionRepository.deleteByMember('m1');
        await repos.appointmentRepository.deleteByMember('m1');
        await repos.familyRepository.delete('m1');
      });

      expect(await repos.familyRepository.getAll(), [avi]);
      expect(await repos.symptomRepository.getAll(), isEmpty);
    });
  });
}

extension on SymptomEntry {
  SymptomEntry copyWithId(String id) => SymptomEntry(
    id: id,
    memberId: memberId,
    name: name,
    startedAt: startedAt,
    severity: severity,
    status: status,
    duration: duration,
    notes: notes,
  );
}
