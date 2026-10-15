import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_symptom_repository.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';

import '../../helpers/flaky_repositories.dart';

void main() {
  final now = DateTime(2026, 10, 15, 12);

  final members = [
    FamilyMember(id: 'm1', name: 'דנה', relation: FamilyRelation.self),
    FamilyMember(id: 'm2', name: 'נועה', relation: FamilyRelation.child),
  ];

  Appointment appointment(String id, String memberId, Duration fromNow) =>
      Appointment(
        id: id,
        memberId: memberId,
        doctorName: 'ד״ר $id',
        dateTime: now.add(fromNow),
      );

  final appointments = [
    appointment('a1', 'm1', const Duration(days: 2)),
    appointment('a2', 'm2', const Duration(days: 3)),
    appointment('past', 'm1', const Duration(days: -10)),
  ];

  DoctorQuestion question(
    String id,
    String memberId,
    String? appointmentId,
    int minute, {
    bool resolved = false,
    String? answer,
  }) => DoctorQuestion(
    id: id,
    memberId: memberId,
    appointmentId: appointmentId,
    text: 'שאלה $id',
    createdAt: now.add(Duration(minutes: minute)),
    isResolved: resolved,
    doctorAnswer: answer,
  );

  // Stored out of order, to check that the controller keeps createdAt order.
  final questions = [
    question('q4', 'm1', 'a1', 4, resolved: true),
    question('q2', 'm1', null, 2),
    question('q3', 'm2', 'a2', 3, resolved: true, answer: 'תשובה'),
    question('q1', 'm1', 'a1', 1),
  ];

  late FlakyFamilyRepository familyRepository;
  late FlakyAppointmentRepository appointmentRepository;
  late FlakyDoctorQuestionRepository questionRepository;
  late AppDependencies dependencies;
  late FamilyController familyController;
  late AppointmentController appointmentController;
  late DoctorQuestionController controller;
  late int notifications;

  setUp(() async {
    familyRepository = FlakyFamilyRepository(members);
    appointmentRepository = FlakyAppointmentRepository(appointments);
    questionRepository = FlakyDoctorQuestionRepository(questions);
    dependencies = AppDependencies(
      familyRepository: familyRepository,
      appointmentRepository: appointmentRepository,
      doctorQuestionRepository: questionRepository,
      symptomRepository: InMemorySymptomRepository(),
    );
    familyController = FamilyController(dependencies);
    appointmentController = AppointmentController(
      dependencies: dependencies,
      familyController: familyController,
    );
    controller = DoctorQuestionController(
      dependencies: dependencies,
      familyController: familyController,
      appointmentController: appointmentController,
    );
    await familyController.load();
    await appointmentController.load();
    await controller.load();

    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() {
    controller.dispose();
    appointmentController.dispose();
    familyController.dispose();
  });

  List<String> ids(List<DoctorQuestion> list) => list.map((q) => q.id).toList();

  DoctorQuestion newQuestion({String memberId = 'm1', String? appointmentId}) =>
      DoctorQuestion(
        id: controller.createId(),
        memberId: memberId,
        appointmentId: appointmentId,
        text: 'שאלה חדשה',
        createdAt: now.add(const Duration(minutes: 10)),
      );

  group('load', () {
    test('reads all questions, oldest first', () {
      expect(ids(controller.questions), ['q1', 'q2', 'q3', 'q4']);
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
      questionRepository.failGetAll = true;
      await controller.load();

      expect(controller.hasLoadError, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.questions, hasLength(4));
    });

    test('clears the error flag when a retry succeeds', () async {
      questionRepository.failGetAll = true;
      await controller.load();
      questionRepository.failGetAll = false;
      await controller.load();

      expect(controller.hasLoadError, isFalse);
    });

    test('when loads overlap, only the latest result is applied', () async {
      final first = controller.load();
      await questionRepository.add(newQuestion());
      final second = controller.load();
      await Future.wait([first, second]);

      expect(controller.questions, hasLength(5));
      expect(controller.isLoading, isFalse);
    });
  });

  group('queries', () {
    test('questionById finds loaded questions, null otherwise', () {
      expect(controller.questionById('q3')?.doctorAnswer, 'תשובה');
      expect(controller.questionById('missing'), isNull);
    });

    test('filter by member and by appointment, oldest first', () {
      expect(ids(controller.forMember('m1')), ['q1', 'q2', 'q4']);
      expect(ids(controller.forMember('m2')), ['q3']);
      expect(ids(controller.forAppointment('a1')), ['q1', 'q4']);
      expect(controller.forAppointment('past'), isEmpty);
    });

    test('split into handled and not yet handled, optionally per member', () {
      expect(ids(controller.unresolved()), ['q1', 'q2']);
      expect(ids(controller.resolved()), ['q3', 'q4']);
      expect(ids(controller.unresolved(memberId: 'm1')), ['q1', 'q2']);
      expect(ids(controller.resolved(memberId: 'm1')), ['q4']);
      expect(controller.unresolved(memberId: 'm2'), isEmpty);
    });

    test('return unmodifiable lists', () {
      expect(() => controller.forMember('m1').clear(), throwsUnsupportedError);
      expect(() => controller.unresolved().clear(), throwsUnsupportedError);
      expect(() => controller.resolved().clear(), throwsUnsupportedError);
    });

    test('createId returns a new id each time', () {
      final first = controller.createId();
      expect(controller.createId(), isNot(first));
      expect(controller.questionById(first), isNull);
    });
  });

  group('add', () {
    test('a general question', () async {
      final added = newQuestion();

      expect(await controller.add(added), QuestionSaveResult.success);
      expect(controller.questionById(added.id), added);
      expect(notifications, 1);
    });

    test(
      'linked to an appointment of the same member, also a past one',
      () async {
        final upcoming = newQuestion(appointmentId: 'a1');
        final past = newQuestion(appointmentId: 'past');

        expect(await controller.add(upcoming), QuestionSaveResult.success);
        expect(await controller.add(past), QuestionSaveResult.success);
        expect(ids(controller.forAppointment('past')), [past.id]);
      },
    );

    test('rejects empty text', () async {
      final blank = newQuestion().copyWith(text: '   ');

      expect(await controller.add(blank), QuestionSaveResult.textRequired);
      expect(controller.questions, hasLength(4));
    });

    test('rejects an unknown member', () async {
      final result = await controller.add(newQuestion(memberId: 'missing'));
      expect(result, QuestionSaveResult.memberNotFound);
    });

    test('rejects an unknown appointment', () async {
      final result = await controller.add(
        newQuestion(appointmentId: 'missing'),
      );
      expect(result, QuestionSaveResult.appointmentNotFound);
    });

    test("rejects another member's appointment", () async {
      final result = await controller.add(newQuestion(appointmentId: 'a2'));

      expect(result, QuestionSaveResult.appointmentOfAnotherMember);
      expect(controller.questions, hasLength(4));
    });

    test('reports failure without changing the list', () async {
      questionRepository.failAdd = true;

      expect(await controller.add(newQuestion()), QuestionSaveResult.failed);
      expect(controller.questions, hasLength(4));
      expect(notifications, 0);
    });
  });

  group('update', () {
    test('stores the change and notifies', () async {
      final q1 = controller.questionById('q1')!;

      final result = await controller.update(
        q1.copyWith(text: 'נוסח חדש', doctorAnswer: () => 'תשובה'),
      );

      expect(result, QuestionSaveResult.success);
      expect(controller.questionById('q1')!.text, 'נוסח חדש');
      expect(controller.questionById('q1')!.doctorAnswer, 'תשובה');
      expect(notifications, 1);
    });

    test(
      'can link a general question to an appointment and unlink it',
      () async {
        final q2 = controller.questionById('q2')!;

        await controller.update(q2.copyWith(appointmentId: () => 'past'));
        expect(controller.questionById('q2')!.appointmentId, 'past');

        await controller.update(
          controller.questionById('q2')!.copyWith(appointmentId: () => null),
        );
        expect(controller.questionById('q2')!.appointmentId, isNull);
      },
    );

    test('rejects a question that no longer exists', () async {
      final result = await controller.update(newQuestion());
      expect(result, QuestionSaveResult.questionNotFound);
    });

    test('rejects an unknown member', () async {
      final q2 = controller.questionById('q2')!;
      final result = await controller.update(q2.copyWith(memberId: 'missing'));

      expect(result, QuestionSaveResult.memberNotFound);
      expect(controller.questionById('q2')!.memberId, 'm1');
    });

    test("rejects linking to another member's appointment", () async {
      final q2 = controller.questionById('q2')!;

      final result = await controller.update(
        q2.copyWith(appointmentId: () => 'a2'),
      );

      expect(result, QuestionSaveResult.appointmentOfAnotherMember);
      expect(controller.questionById('q2')!.appointmentId, isNull);
    });

    test('reports failure without changing anything', () async {
      questionRepository.failUpdate = true;
      final q1 = controller.questionById('q1')!;

      final result = await controller.update(q1.copyWith(text: 'שונה'));

      expect(result, QuestionSaveResult.failed);
      expect(controller.questionById('q1')!.text, 'שאלה q1');
      expect(notifications, 0);
    });
  });

  group('moving a question to another member', () {
    test(
      'clears the old appointment link, even if it is passed along',
      () async {
        final q1 = controller.questionById('q1')!;
        expect(q1.appointmentId, 'a1');

        final result = await controller.update(q1.copyWith(memberId: 'm2'));

        expect(result, QuestionSaveResult.success);
        final moved = controller.questionById('q1')!;
        expect(moved.memberId, 'm2');
        expect(moved.appointmentId, isNull);
        expect(controller.forAppointment('a1').map((q) => q.id), ['q4']);
      },
    );

    test("keeps a newly chosen appointment of the new member", () async {
      final q1 = controller.questionById('q1')!;

      final result = await controller.update(
        q1.copyWith(memberId: 'm2', appointmentId: () => 'a2'),
      );

      expect(result, QuestionSaveResult.success);
      expect(controller.questionById('q1')!.appointmentId, 'a2');
    });

    test(
      'rejects an appointment that is neither old nor of the new member',
      () async {
        final q2 = controller.questionById('q2')!;

        final result = await controller.update(
          q2.copyWith(memberId: 'm2', appointmentId: () => 'past'),
        );

        expect(result, QuestionSaveResult.appointmentOfAnotherMember);
        expect(controller.questionById('q2')!.memberId, 'm1');
      },
    );
  });

  group('setResolved', () {
    test('marks as handled and back, keeping text and answer', () async {
      await controller.setResolved('q3', resolved: false);
      var q3 = controller.questionById('q3')!;
      expect(q3.isResolved, isFalse);
      expect(q3.doctorAnswer, 'תשובה');
      expect(q3.text, 'שאלה q3');
      expect(q3.appointmentId, 'a2');

      await controller.setResolved('q3', resolved: true);
      q3 = controller.questionById('q3')!;
      expect(q3.isResolved, isTrue);
      expect(q3.doctorAnswer, 'תשובה');
    });

    test('moves the question between the two lists', () async {
      await controller.setResolved('q1', resolved: true);

      expect(ids(controller.unresolved()), ['q2']);
      expect(ids(controller.resolved()), ['q1', 'q3', 'q4']);
    });

    test('rejects a question that no longer exists', () async {
      expect(
        await controller.setResolved('missing', resolved: true),
        QuestionSaveResult.questionNotFound,
      );
    });

    test('reports failure without changing anything', () async {
      questionRepository.failUpdate = true;

      expect(
        await controller.setResolved('q1', resolved: true),
        QuestionSaveResult.failed,
      );
      expect(controller.questionById('q1')!.isResolved, isFalse);
    });
  });

  group('delete', () {
    test('refuses to run without user confirmation', () async {
      await expectLater(
        controller.delete('q1', userConfirmed: false),
        throwsArgumentError,
      );
      expect(await questionRepository.getById('q1'), isNotNull);
      expect(notifications, 0);
    });

    test('removes only that question', () async {
      expect(await controller.delete('q1', userConfirmed: true), isTrue);

      expect(controller.questionById('q1'), isNull);
      expect(controller.questions, hasLength(3));
      expect(notifications, 1);
    });

    test('a failure keeps the question, and a retry works', () async {
      questionRepository.failDelete = true;
      expect(await controller.delete('q1', userConfirmed: true), isFalse);
      expect(controller.questionById('q1'), isNotNull);

      questionRepository.failDelete = false;
      expect(await controller.delete('q1', userConfirmed: true), isTrue);
      expect(controller.questionById('q1'), isNull);
    });
  });

  group('sync with other controllers', () {
    test('deleting an appointment shows its questions as general', () async {
      await appointmentController.delete('a1', userConfirmed: true);
      await pumpEventQueue();

      expect(controller.forAppointment('a1'), isEmpty);
      for (final id in ['q1', 'q4']) {
        final q = controller.questionById(id)!;
        expect(q.appointmentId, isNull);
        expect(q.memberId, 'm1');
      }
    });

    test('a partly failed appointment deletion still reloads', () async {
      // Questions are unlinked, then deleting the appointment fails.
      appointmentRepository.failDelete = true;

      await appointmentController.delete('a1', userConfirmed: true);
      await pumpEventQueue();

      expect(appointmentController.appointmentById('a1'), isNotNull);
      expect(controller.forAppointment('a1'), isEmpty);
    });

    test('moving an appointment to another member reloads', () async {
      final a1 = appointmentController.appointmentById('a1')!;

      await appointmentController.update(a1.copyWith(memberId: 'm2'));
      await pumpEventQueue();

      expect(controller.forAppointment('a1'), isEmpty);
      expect(controller.questionById('q1')!.memberId, 'm1');
    });

    test('deleting a family member removes their questions', () async {
      await familyController.delete('m1', userConfirmed: true);
      await pumpEventQueue();

      expect(ids(controller.questions), ['q3']);
    });

    test('a partly failed member deletion still reloads', () async {
      familyRepository.failDelete = true;

      await familyController.delete('m1', userConfirmed: true);
      await pumpEventQueue();

      expect(familyController.memberById('m1'), isNotNull);
      expect(controller.forMember('m1'), isEmpty);
    });

    test('does not reload on unrelated changes', () async {
      final callsBefore = questionRepository.getAllCalls;
      final a1 = appointmentController.appointmentById('a1')!;

      await appointmentController.load();
      await appointmentController.add(
        appointment('new', 'm2', const Duration(days: 1)),
      );
      await appointmentController.update(a1.copyWith(doctorName: 'ד״ר אחר'));
      await familyController.load();
      await familyController.update(members[1].copyWith(name: 'נועה ל.'));
      await pumpEventQueue();

      expect(questionRepository.getAllCalls, callsBefore);
      expect(notifications, 0);
    });

    test('reloads once per related change, without loops', () async {
      final callsBefore = questionRepository.getAllCalls;

      await appointmentController.delete('past', userConfirmed: true);
      await pumpEventQueue();

      // One reload by this controller; the appointment controller itself
      // never reads questions while deleting.
      expect(questionRepository.getAllCalls, callsBefore + 1);
    });

    test('stops listening once disposed', () async {
      final other = DoctorQuestionController(
        dependencies: dependencies,
        familyController: familyController,
        appointmentController: appointmentController,
      );
      other.dispose();
      final callsBefore = questionRepository.getAllCalls;

      await appointmentController.delete('a2', userConfirmed: true);
      await familyController.delete('m2', userConfirmed: true);
      await pumpEventQueue();

      // Only the live controller from setUp reloaded, once per change.
      expect(questionRepository.getAllCalls, callsBefore + 2);
    });
  });
}
