import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:mydr/data/local/local_transaction_runner.dart';
import 'package:mydr/data/local/repositories/local_appointment_repository.dart';
import 'package:mydr/data/local/repositories/local_doctor_question_repository.dart';
import 'package:mydr/data/local/repositories/local_family_repository.dart';
import 'package:mydr/data/local/repositories/local_symptom_repository.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/data/repositories/appointment_repository.dart';
import 'package:mydr/data/repositories/family_repository.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/family/family_controller.dart';

import '../helpers/memory_key_store.dart';

/// The controllers' multi-step operations on the local database: each runs
/// as one transaction, so a failure part-way changes nothing.
void main() {
  late Directory directory;
  late LocalDatabase database;
  late _FailingFamilyRepository family;
  late _FailingAppointmentRepository appointments;
  late AppDependencies dependencies;
  late FamilyController familyController;
  late AppointmentController appointmentController;

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('mydr_atomic');
    database = await LocalDatabaseOpener(
      keyStore: MemoryDatabaseKeyStore(),
      locateFile: () async => File('${directory.path}/atomic.sqlite'),
    ).open();
    family = _FailingFamilyRepository(LocalFamilyRepository(database));
    appointments = _FailingAppointmentRepository(
      LocalAppointmentRepository(database),
    );
    dependencies = AppDependencies(
      familyRepository: family,
      appointmentRepository: appointments,
      doctorQuestionRepository: LocalDoctorQuestionRepository(database),
      symptomRepository: LocalSymptomRepository(database),
      transactions: LocalTransactionRunner(database),
      persistsData: true,
    );
    familyController = FamilyController(dependencies);
    appointmentController = AppointmentController(
      dependencies: dependencies,
      familyController: familyController,
    );

    for (final member in [
      FamilyMember(id: 'm1', name: 'נועה', relation: FamilyRelation.child),
      FamilyMember(id: 'm2', name: 'אבי', relation: FamilyRelation.spouse),
    ]) {
      await family.add(member);
    }
    await appointments.add(
      Appointment(
        id: 'a1',
        memberId: 'm1',
        doctorName: 'רופא בדיקה',
        dateTime: DateTime(2026, 10, 20, 9),
      ),
    );
    await dependencies.doctorQuestionRepository.add(
      DoctorQuestion(
        id: 'q1',
        memberId: 'm1',
        appointmentId: 'a1',
        text: 'שאלת בדיקה',
        createdAt: DateTime(2026, 10, 15),
      ),
    );
    await dependencies.symptomRepository.add(
      SymptomEntry(
        id: 's1',
        memberId: 'm1',
        name: 'תסמין בדיקה',
        startedAt: DateTime(2026, 10, 14, 8),
        severity: 2,
      ),
    );
    await familyController.load();
    await appointmentController.load();
  });

  tearDown(() async {
    appointmentController.dispose();
    familyController.dispose();
    await database.close();
    directory.deleteSync(recursive: true);
  });

  Future<void> expectEverythingKept() async {
    expect(await family.getById('m1'), isNotNull);
    expect(await appointments.getById('a1'), isNotNull);
    final question = await dependencies.doctorQuestionRepository.getById('q1');
    expect(question?.appointmentId, 'a1');
    expect(await dependencies.symptomRepository.getById('s1'), isNotNull);
  }

  group('deleting a family member', () {
    test('removes them and all their records together', () async {
      final result = await familyController.delete('m1', userConfirmed: true);

      expect(result.isSuccess, isTrue);
      expect(await family.getById('m1'), isNull);
      expect(await appointments.getAll(), isEmpty);
      expect(await dependencies.doctorQuestionRepository.getAll(), isEmpty);
      expect(await dependencies.symptomRepository.getAll(), isEmpty);
      expect(await family.getById('m2'), isNotNull);
    });

    test('a failure at the last step undoes all of it: nothing is half '
        'deleted, and the member is not marked as such', () async {
      family.failDelete = true;

      final result = await familyController.delete('m1', userConfirmed: true);

      expect(result.isSuccess, isFalse);
      expect(result.failedStep, MemberDeletionStep.profile);
      expect(familyController.isDeletionIncomplete('m1'), isFalse);
      await expectEverythingKept();

      // Trying again works.
      family.failDelete = false;
      expect(
        (await familyController.delete('m1', userConfirmed: true)).isSuccess,
        isTrue,
      );
      expect(await dependencies.symptomRepository.getAll(), isEmpty);
    });
  });

  group('deleting an appointment', () {
    test('unlinks its questions and keeps them', () async {
      final result = await appointmentController.delete(
        'a1',
        userConfirmed: true,
      );

      expect(result.isSuccess, isTrue);
      expect(await appointments.getById('a1'), isNull);
      final question = await dependencies.doctorQuestionRepository.getById(
        'q1',
      );
      expect(question, isNotNull);
      expect(question!.appointmentId, isNull);
    });

    test('a failed deletion also undoes the unlinking', () async {
      appointments.failDelete = true;

      final result = await appointmentController.delete(
        'a1',
        userConfirmed: true,
      );

      expect(result.isSuccess, isFalse);
      await expectEverythingKept();
    });
  });

  test('moving an appointment to another member: a failed save also undoes '
      'unlinking its questions', () async {
    appointments.failUpdate = true;
    final appointment = (await appointments.getById('a1'))!;

    final result = await appointmentController.update(
      appointment.copyWith(memberId: 'm2'),
    );

    expect(result, AppointmentSaveResult.failed);
    await expectEverythingKept();
  });

  test(
    'moving an appointment to another member unlinks its questions',
    () async {
      final appointment = (await appointments.getById('a1'))!;

      final result = await appointmentController.update(
        appointment.copyWith(memberId: 'm2'),
      );

      expect(result, AppointmentSaveResult.success);
      expect((await appointments.getById('a1'))!.memberId, 'm2');
      final question = await dependencies.doctorQuestionRepository.getById(
        'q1',
      );
      expect(question!.memberId, 'm1');
      expect(question.appointmentId, isNull);
    },
  );
}

class _FailingFamilyRepository implements FamilyRepository {
  _FailingFamilyRepository(this._inner);

  final FamilyRepository _inner;
  bool failDelete = false;

  @override
  String createId() => _inner.createId();
  @override
  Future<FamilyMember?> getById(String id) => _inner.getById(id);
  @override
  Future<List<FamilyMember>> getAll() => _inner.getAll();
  @override
  Future<void> add(FamilyMember item) => _inner.add(item);
  @override
  Future<void> update(FamilyMember item) => _inner.update(item);
  @override
  Future<void> delete(String id) async {
    if (failDelete) throw StateError('simulated failure');
    return _inner.delete(id);
  }
}

class _FailingAppointmentRepository implements AppointmentRepository {
  _FailingAppointmentRepository(this._inner);

  final AppointmentRepository _inner;
  bool failDelete = false;
  bool failUpdate = false;

  @override
  String createId() => _inner.createId();
  @override
  Future<Appointment?> getById(String id) => _inner.getById(id);
  @override
  Future<List<Appointment>> getAll({String? memberId}) =>
      _inner.getAll(memberId: memberId);
  @override
  Future<void> add(Appointment item) => _inner.add(item);
  @override
  Future<void> update(Appointment item) async {
    if (failUpdate) throw StateError('simulated failure');
    return _inner.update(item);
  }

  @override
  Future<void> delete(String id) async {
    if (failDelete) throw StateError('simulated failure');
    return _inner.delete(id);
  }

  @override
  Future<void> deleteByMember(String memberId) =>
      _inner.deleteByMember(memberId);
}
