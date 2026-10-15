import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_symptom_repository.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/family/family_controller.dart';

import '../../helpers/flaky_repositories.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);

  // m1 and m2 have appointments; m3 has none.
  final members = [
    FamilyMember(id: 'm1', name: 'דנה', relation: FamilyRelation.self),
    FamilyMember(id: 'm2', name: 'נועה', relation: FamilyRelation.child),
    FamilyMember(id: 'm3', name: 'אבי', relation: FamilyRelation.spouse),
  ];

  Appointment appointment(String id, String memberId, Duration fromNow) =>
      Appointment(
        id: id,
        memberId: memberId,
        doctorName: 'ד״ר $id',
        dateTime: now.add(fromNow),
      );

  final appointments = [
    appointment('past-old', 'm1', const Duration(days: -30)),
    appointment('past-recent', 'm2', const Duration(hours: -2)),
    appointment('now', 'm1', Duration.zero),
    appointment('soon', 'm1', const Duration(hours: 1)),
    appointment('later', 'm2', const Duration(days: 5)),
  ];

  DoctorQuestion question(String id, String memberId, String? appointmentId) =>
      DoctorQuestion(
        id: id,
        memberId: memberId,
        appointmentId: appointmentId,
        text: 'שאלה $id',
        createdAt: now,
      );

  final questions = [
    question('q1', 'm1', 'soon'),
    question('q2', 'm1', 'soon'),
    question('q3', 'm1', null),
    question('q4', 'm2', 'later'),
  ];

  late FlakyFamilyRepository familyRepository;
  late FlakyAppointmentRepository appointmentRepository;
  late FlakyDoctorQuestionRepository questionRepository;
  late FamilyController familyController;
  late AppointmentController controller;
  late int notifications;

  setUp(() async {
    familyRepository = FlakyFamilyRepository(members);
    appointmentRepository = FlakyAppointmentRepository(appointments);
    questionRepository = FlakyDoctorQuestionRepository(questions);
    final dependencies = AppDependencies(
      familyRepository: familyRepository,
      appointmentRepository: appointmentRepository,
      doctorQuestionRepository: questionRepository,
      symptomRepository: InMemorySymptomRepository(),
    );
    familyController = FamilyController(dependencies);
    controller = AppointmentController(
      dependencies: dependencies,
      familyController: familyController,
    );
    await familyController.load();
    await controller.load();

    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() {
    controller.dispose();
    familyController.dispose();
  });

  List<String> ids(List<Appointment> list) => list.map((a) => a.id).toList();

  Future<DoctorQuestion> storedQuestion(String id) async =>
      (await questionRepository.getById(id))!;

  group('load', () {
    test('reads all appointments, earliest first', () {
      expect(ids(controller.appointments), [
        'past-old',
        'past-recent',
        'now',
        'soon',
        'later',
      ]);
      expect(controller.isLoading, isFalse);
      expect(controller.hasLoadError, isFalse);
    });

    test('reports loading, then done, to listeners', () async {
      final loadingStates = <bool>[];
      controller.addListener(() => loadingStates.add(controller.isLoading));

      await controller.load();

      expect(loadingStates, [true, false]);
    });

    test('sets an error flag on failure and keeps the previous list', () async {
      appointmentRepository.failGetAll = true;
      await controller.load();

      expect(controller.hasLoadError, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.appointments, hasLength(5));
    });

    test('clears the error flag when a retry succeeds', () async {
      appointmentRepository.failGetAll = true;
      await controller.load();
      appointmentRepository.failGetAll = false;
      await controller.load();

      expect(controller.hasLoadError, isFalse);
    });

    test('when loads overlap, only the latest result is applied', () async {
      final first = controller.load();
      await appointmentRepository.add(
        appointment('new', 'm3', const Duration(days: 2)),
      );
      final second = controller.load();
      await Future.wait([first, second]);

      expect(controller.appointmentById('new'), isNotNull);
      expect(controller.isLoading, isFalse);
    });
  });

  test('appointmentById finds loaded appointments, null otherwise', () {
    expect(controller.appointmentById('soon')?.memberId, 'm1');
    expect(controller.appointmentById('missing'), isNull);
  });

  test('createId returns a new id each time', () {
    final first = controller.createId();
    expect(controller.createId(), isNot(first));
    expect(controller.appointmentById(first), isNull);
  });

  group('upcoming and past', () {
    test('upcoming is nearest first and includes an appointment right now', () {
      expect(ids(controller.upcoming(now)), ['now', 'soon', 'later']);
    });

    test('past is most recent first', () {
      expect(ids(controller.past(now)), ['past-recent', 'past-old']);
    });

    test('both can be filtered by family member', () {
      expect(ids(controller.upcoming(now, memberId: 'm1')), ['now', 'soon']);
      expect(ids(controller.past(now, memberId: 'm1')), ['past-old']);
      expect(ids(controller.upcoming(now, memberId: 'm2')), ['later']);
      expect(ids(controller.past(now, memberId: 'm2')), ['past-recent']);
      expect(controller.upcoming(now, memberId: 'm3'), isEmpty);
    });

    test('depend only on the given time', () {
      final muchLater = now.add(const Duration(days: 10));
      expect(controller.upcoming(muchLater), isEmpty);
      expect(controller.past(muchLater), hasLength(5));
    });

    test('return unmodifiable lists', () {
      expect(() => controller.upcoming(now).clear(), throwsUnsupportedError);
      expect(() => controller.past(now).clear(), throwsUnsupportedError);
    });
  });

  group('add', () {
    test('stores the appointment, refreshes the list and notifies', () async {
      final added = appointment(
        controller.createId(),
        'm3',
        const Duration(days: 1),
      );

      final result = await controller.add(added);

      expect(result, AppointmentSaveResult.success);
      expect(controller.appointmentById(added.id), added);
      expect(notifications, 1);
    });

    test('rejects an unknown family member', () async {
      final result = await controller.add(
        appointment('x', 'missing-member', const Duration(days: 1)),
      );

      expect(result, AppointmentSaveResult.memberNotFound);
      expect(await appointmentRepository.getById('x'), isNull);
      expect(notifications, 0);
    });

    test('reports failure without changing the list', () async {
      appointmentRepository.failAdd = true;

      final result = await controller.add(
        appointment('x', 'm3', const Duration(days: 1)),
      );

      expect(result, AppointmentSaveResult.failed);
      expect(controller.appointments, hasLength(5));
      expect(notifications, 0);
    });
  });

  group('update', () {
    test('stores the change, refreshes the list and notifies', () async {
      final soon = controller.appointmentById('soon')!;

      final result = await controller.update(
        soon.copyWith(doctorName: 'ד״ר חדש', location: () => 'מרפאה'),
      );

      expect(result, AppointmentSaveResult.success);
      expect(controller.appointmentById('soon')!.doctorName, 'ד״ר חדש');
      expect(controller.appointmentById('soon')!.location, 'מרפאה');
      expect(notifications, 1);
    });

    test('keeps linked questions when the member does not change', () async {
      final soon = controller.appointmentById('soon')!;

      await controller.update(soon.copyWith(doctorName: 'ד״ר חדש'));

      expect(questionRepository.detachCalls, 0);
      expect((await storedQuestion('q1')).appointmentId, 'soon');
    });

    test('rejects an unknown family member', () async {
      final soon = controller.appointmentById('soon')!;

      final result = await controller.update(
        soon.copyWith(memberId: 'missing-member'),
      );

      expect(result, AppointmentSaveResult.memberNotFound);
      expect(controller.appointmentById('soon')!.memberId, 'm1');
      expect(questionRepository.detachCalls, 0);
    });

    test('rejects an appointment that no longer exists', () async {
      final result = await controller.update(
        appointment('missing', 'm1', const Duration(days: 1)),
      );

      expect(result, AppointmentSaveResult.appointmentNotFound);
      expect(await appointmentRepository.getById('missing'), isNull);
    });

    test('reports failure without changing anything', () async {
      appointmentRepository.failUpdate = true;
      final soon = controller.appointmentById('soon')!;

      final result = await controller.update(
        soon.copyWith(doctorName: 'ד״ר חדש'),
      );

      expect(result, AppointmentSaveResult.failed);
      expect(controller.appointmentById('soon')!.doctorName, soon.doctorName);
      expect(notifications, 0);
    });
  });

  group('changing the family member', () {
    test(
      'unlinks the questions and keeps them with the original member',
      () async {
        final soon = controller.appointmentById('soon')!;

        final result = await controller.update(soon.copyWith(memberId: 'm3'));

        expect(result, AppointmentSaveResult.success);
        expect(controller.appointmentById('soon')!.memberId, 'm3');
        for (final id in ['q1', 'q2']) {
          final stored = await storedQuestion(id);
          expect(stored.appointmentId, isNull);
          expect(stored.memberId, 'm1');
        }
        // Unrelated questions are untouched.
        expect((await storedQuestion('q3')).appointmentId, isNull);
        expect((await storedQuestion('q4')).appointmentId, 'later');
        expect(await questionRepository.getAll(), hasLength(4));
      },
    );

    test('if unlinking fails, nothing changes', () async {
      questionRepository.failDetach = true;
      final soon = controller.appointmentById('soon')!;

      final result = await controller.update(soon.copyWith(memberId: 'm3'));

      expect(result, AppointmentSaveResult.failed);
      expect(controller.appointmentById('soon')!.memberId, 'm1');
      expect((await storedQuestion('q1')).appointmentId, 'soon');
    });

    test('if saving fails after unlinking, the partial state is reported '
        'and a retry completes it', () async {
      appointmentRepository.failUpdate = true;
      final soon = controller.appointmentById('soon')!;

      final result = await controller.update(soon.copyWith(memberId: 'm3'));

      expect(result, AppointmentSaveResult.failedAfterDetachingQuestions);
      expect(controller.appointmentById('soon')!.memberId, 'm1');
      // Unlinked, but not deleted and still with their member.
      expect((await storedQuestion('q1')).appointmentId, isNull);
      expect((await storedQuestion('q1')).memberId, 'm1');

      appointmentRepository.failUpdate = false;
      final retry = await controller.update(soon.copyWith(memberId: 'm3'));

      expect(retry, AppointmentSaveResult.success);
      expect(controller.appointmentById('soon')!.memberId, 'm3');
    });
  });

  group('linkedQuestionCount', () {
    test('counts the questions linked to an appointment', () async {
      expect(await controller.linkedQuestionCount('soon'), 2);
      expect(await controller.linkedQuestionCount('later'), 1);
      expect(await controller.linkedQuestionCount('past-old'), 0);
    });

    test('returns null when the questions cannot be read', () async {
      questionRepository.failGetAll = true;
      expect(await controller.linkedQuestionCount('soon'), isNull);
    });
  });

  group('delete', () {
    test('refuses to run without user confirmation', () async {
      await expectLater(
        controller.delete('soon', userConfirmed: false),
        throwsArgumentError,
      );

      expect(await appointmentRepository.getById('soon'), isNotNull);
      expect(questionRepository.detachCalls, 0);
      expect(notifications, 0);
    });

    test('removes the appointment and keeps its questions, unlinked', () async {
      final result = await controller.delete('soon', userConfirmed: true);

      expect(result.isSuccess, isTrue);
      expect(controller.appointmentById('soon'), isNull);
      expect(await appointmentRepository.getById('soon'), isNull);
      final q1 = await storedQuestion('q1');
      expect(q1.appointmentId, isNull);
      expect(q1.memberId, 'm1');
      expect(await questionRepository.getAll(), hasLength(4));
      expect(notifications, 1);
    });

    test('if unlinking fails, the appointment is kept', () async {
      questionRepository.failDetach = true;

      final result = await controller.delete('soon', userConfirmed: true);

      expect(result.failedStep, AppointmentDeletionStep.detachQuestions);
      expect(controller.appointmentById('soon'), isNotNull);
      expect((await storedQuestion('q1')).appointmentId, 'soon');
    });

    test('if deleting fails after unlinking, a retry completes it', () async {
      appointmentRepository.failDelete = true;

      final result = await controller.delete('soon', userConfirmed: true);

      expect(result.failedStep, AppointmentDeletionStep.appointment);
      expect(controller.appointmentById('soon'), isNotNull);
      expect((await storedQuestion('q1')).appointmentId, isNull);

      appointmentRepository.failDelete = false;
      final retry = await controller.delete('soon', userConfirmed: true);

      expect(retry.isSuccess, isTrue);
      expect(controller.appointmentById('soon'), isNull);
    });
  });

  group('questionLinksRevision', () {
    test('increases after every deletion attempt', () async {
      final start = controller.questionLinksRevision;

      await controller.delete('soon', userConfirmed: true);
      expect(controller.questionLinksRevision, start + 1);

      appointmentRepository.failDelete = true;
      await controller.delete('later', userConfirmed: true);
      expect(controller.questionLinksRevision, start + 2);
    });

    test('increases when the member changes, even if saving fails', () async {
      final start = controller.questionLinksRevision;
      final soon = controller.appointmentById('soon')!;

      await controller.update(soon.copyWith(memberId: 'm3'));
      expect(controller.questionLinksRevision, start + 1);

      appointmentRepository.failUpdate = true;
      final later = controller.appointmentById('later')!;
      final notifiedBefore = notifications;
      await controller.update(later.copyWith(memberId: 'm3'));
      expect(controller.questionLinksRevision, start + 2);
      // Listeners hear about it even though the update failed.
      expect(notifications, greaterThan(notifiedBefore));
    });

    test('stays the same for other changes', () async {
      final start = controller.questionLinksRevision;
      final soon = controller.appointmentById('soon')!;

      await controller.load();
      await controller.add(appointment('x', 'm3', const Duration(days: 1)));
      await controller.update(soon.copyWith(doctorName: 'ד״ר אחר'));
      await controller.update(soon.copyWith(memberId: 'missing-member'));

      expect(controller.questionLinksRevision, start);
    });
  });

  group('sync with FamilyController', () {
    test('reloads after a family member is deleted', () async {
      await familyController.delete('m1', userConfirmed: true);
      await pumpEventQueue();

      expect(ids(controller.appointments), ['past-recent', 'later']);
      expect(notifications, greaterThan(0));
    });

    test('reloads even when the member deletion fails part-way', () async {
      // Appointments are deleted, then deleting the profile itself fails.
      familyRepository.failDelete = true;

      await familyController.delete('m1', userConfirmed: true);
      await pumpEventQueue();

      expect(familyController.memberById('m1'), isNotNull);
      expect(controller.upcoming(now, memberId: 'm1'), isEmpty);
    });

    test('does not reload on other family changes', () async {
      final callsBefore = appointmentRepository.getAllCalls;

      await familyController.load();
      await familyController.add(
        FamilyMember(id: 'm4', name: 'יעל', relation: FamilyRelation.sibling),
      );
      await familyController.update(members[1].copyWith(name: 'נועה ל.'));
      await pumpEventQueue();

      expect(appointmentRepository.getAllCalls, callsBefore);
      expect(notifications, 0);
    });

    test('stops listening once disposed', () async {
      final dependencies = AppDependencies(
        familyRepository: familyRepository,
        appointmentRepository: appointmentRepository,
        doctorQuestionRepository: questionRepository,
        symptomRepository: InMemorySymptomRepository(),
      );
      final other = AppointmentController(
        dependencies: dependencies,
        familyController: familyController,
      );
      other.dispose();
      final callsBefore = appointmentRepository.getAllCalls;

      await familyController.delete('m2', userConfirmed: true);
      await pumpEventQueue();

      // Only the live controller from setUp reloaded.
      expect(appointmentRepository.getAllCalls, callsBefore + 1);
    });
  });
}
