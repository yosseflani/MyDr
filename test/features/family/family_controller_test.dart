import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/mock/mock_data.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_symptom_repository.dart';
import 'package:mydr/features/family/family_controller.dart';

import '../../helpers/flaky_repositories.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);

  late FlakyFamilyRepository familyRepository;
  late FlakyAppointmentRepository appointmentRepository;
  late FlakyDoctorQuestionRepository questionRepository;
  late InMemorySymptomRepository symptomRepository;
  late FamilyController controller;
  late int notifications;

  setUp(() async {
    familyRepository = FlakyFamilyRepository(MockData.members());
    appointmentRepository = FlakyAppointmentRepository(
      MockData.appointments(now),
    );
    questionRepository = FlakyDoctorQuestionRepository(MockData.questions(now));
    symptomRepository = InMemorySymptomRepository(MockData.symptoms(now));
    controller = FamilyController(
      AppDependencies(
        familyRepository: familyRepository,
        appointmentRepository: appointmentRepository,
        doctorQuestionRepository: questionRepository,
        symptomRepository: symptomRepository,
      ),
    );
    await controller.load();

    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() => controller.dispose());

  FamilyMember newMember({
    String name = 'חדש',
    FamilyRelation relation = FamilyRelation.other,
  }) => FamilyMember(id: controller.createId(), name: name, relation: relation);

  /// What is currently stored for [memberId].
  Future<({bool hasProfile, int appointments, int questions, int symptoms})>
  storedDataOf(String memberId) async => (
    hasProfile: await familyRepository.getById(memberId) != null,
    appointments: (await appointmentRepository.getAll(
      memberId: memberId,
    )).length,
    questions: (await questionRepository.getAll(memberId: memberId)).length,
    symptoms: (await symptomRepository.getAll(memberId: memberId)).length,
  );

  group('load', () {
    test('reads all members from the repository', () {
      expect(controller.members, hasLength(5));
      expect(controller.members.first.relation, FamilyRelation.self);
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
      familyRepository.failGetAll = true;
      await controller.load();

      expect(controller.hasLoadError, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.members, hasLength(5));
    });

    test('clears the error flag when a retry succeeds', () async {
      familyRepository.failGetAll = true;
      await controller.load();
      familyRepository.failGetAll = false;
      await controller.load();

      expect(controller.hasLoadError, isFalse);
    });
  });

  test('memberById finds loaded members and returns null otherwise', () {
    expect(controller.memberById(MockData.sonId)?.name, 'איתי');
    expect(controller.memberById('missing'), isNull);
  });

  test('createId returns a new id each time', () {
    final first = controller.createId();
    expect(controller.createId(), isNot(first));
    expect(controller.memberById(first), isNull);
  });

  group('add', () {
    test('stores the member, refreshes the list and notifies', () async {
      final member = newMember();

      final result = await controller.add(member);

      expect(result, FamilySaveResult.success);
      expect(controller.memberById(member.id), member);
      expect(await familyRepository.getById(member.id), member);
      expect(notifications, 1);
    });

    test('reports failure without changing the list', () async {
      familyRepository.failAdd = true;

      final result = await controller.add(newMember());

      expect(result, FamilySaveResult.failed);
      expect(controller.members, hasLength(5));
      expect(notifications, 0);
    });
  });

  group('update', () {
    test('stores the change, refreshes the list and notifies', () async {
      final son = controller.memberById(MockData.sonId)!;

      final result = await controller.update(son.copyWith(name: 'איתי כ.'));

      expect(result, FamilySaveResult.success);
      expect(controller.memberById(MockData.sonId)!.name, 'איתי כ.');
      expect(notifications, 1);
    });

    test('reports failure without changing the list', () async {
      familyRepository.failUpdate = true;
      final son = controller.memberById(MockData.sonId)!;

      final result = await controller.update(son.copyWith(name: 'שונה'));

      expect(result, FamilySaveResult.failed);
      expect(controller.memberById(MockData.sonId)!.name, 'איתי');
      expect(notifications, 0);
    });
  });

  group('single "self" profile', () {
    test('is not available while a self profile exists', () {
      expect(controller.isSelfRelationAvailable(), isFalse);
    });

    test('is available to the existing self profile itself', () {
      expect(
        controller.isSelfRelationAvailable(excludingMemberId: MockData.selfId),
        isTrue,
      );
    });

    test('rejects adding a second self profile', () async {
      final result = await controller.add(
        newMember(relation: FamilyRelation.self),
      );

      expect(result, FamilySaveResult.selfAlreadyExists);
      expect(controller.members, hasLength(5));
    });

    test('rejects changing another member to self', () async {
      final son = controller.memberById(MockData.sonId)!;

      final result = await controller.update(
        son.copyWith(relation: FamilyRelation.self),
      );

      expect(result, FamilySaveResult.selfAlreadyExists);
      expect(
        controller.memberById(MockData.sonId)!.relation,
        FamilyRelation.child,
      );
    });

    test('allows editing the self profile itself', () async {
      final self = controller.memberById(MockData.selfId)!;

      final result = await controller.update(self.copyWith(name: 'דנה כ.'));

      expect(result, FamilySaveResult.success);
    });

    test('allows a new self profile once the old one is deleted', () async {
      await controller.delete(MockData.selfId, userConfirmed: true);

      expect(controller.isSelfRelationAvailable(), isTrue);
      expect(
        await controller.add(newMember(relation: FamilyRelation.self)),
        FamilySaveResult.success,
      );
    });
  });

  group('relatedDataSummary', () {
    test('counts appointments, questions and symptoms', () async {
      final summary = await controller.relatedDataSummary(MockData.daughterId);

      expect(summary!.appointments, 1);
      expect(summary.doctorQuestions, 1);
      expect(summary.symptoms, 1);
      expect(summary.isEmpty, isFalse);
    });

    test('is empty for a member without related data', () async {
      final summary = await controller.relatedDataSummary(MockData.spouseId);
      expect(summary!.isEmpty, isTrue);
    });

    test('returns null when the data cannot be read', () async {
      questionRepository.failGetAll = true;
      expect(await controller.relatedDataSummary(MockData.daughterId), isNull);
    });
  });

  group('delete', () {
    test('refuses to run without user confirmation', () async {
      await expectLater(
        controller.delete(MockData.daughterId, userConfirmed: false),
        throwsArgumentError,
      );

      final stored = await storedDataOf(MockData.daughterId);
      expect(stored.hasProfile, isTrue);
      expect(stored.symptoms, 1);
      expect(notifications, 0);
    });

    test('removes the member and all of their related data', () async {
      final result = await controller.delete(
        MockData.daughterId,
        userConfirmed: true,
      );

      expect(result.isSuccess, isTrue);
      expect(controller.memberById(MockData.daughterId), isNull);
      expect(controller.isDeletionIncomplete(MockData.daughterId), isFalse);
      final stored = await storedDataOf(MockData.daughterId);
      expect(stored, (
        hasProfile: false,
        appointments: 0,
        questions: 0,
        symptoms: 0,
      ));
    });

    test('leaves other members and their data untouched', () async {
      final before = await storedDataOf(MockData.grandmotherId);

      await controller.delete(MockData.daughterId, userConfirmed: true);

      expect(await storedDataOf(MockData.grandmotherId), before);
      expect(controller.members, hasLength(4));
    });

    test('marks the member as deleting while it runs', () async {
      final deletingStates = <bool>[];
      controller.addListener(
        () => deletingStates.add(controller.isDeleting(MockData.daughterId)),
      );

      await controller.delete(MockData.daughterId, userConfirmed: true);

      expect(deletingStates, [true, false]);
    });

    test('stops at a failed step and keeps the profile', () async {
      questionRepository.failDeleteByMember = true;

      final result = await controller.delete(
        MockData.daughterId,
        userConfirmed: true,
      );

      expect(result.isSuccess, isFalse);
      expect(result.failedStep, MemberDeletionStep.doctorQuestions);
      expect(controller.isDeletionIncomplete(MockData.daughterId), isTrue);
      expect(controller.isDeleting(MockData.daughterId), isFalse);
      expect(controller.memberById(MockData.daughterId), isNotNull);

      // Symptoms (the step before) are gone; later steps never ran.
      final stored = await storedDataOf(MockData.daughterId);
      expect(stored, (
        hasProfile: true,
        appointments: 1,
        questions: 1,
        symptoms: 0,
      ));
    });

    test('retrying after a partial failure completes the deletion', () async {
      questionRepository.failDeleteByMember = true;
      await controller.delete(MockData.daughterId, userConfirmed: true);
      questionRepository.failDeleteByMember = false;

      final result = await controller.delete(
        MockData.daughterId,
        userConfirmed: true,
      );

      expect(result.isSuccess, isTrue);
      expect(controller.isDeletionIncomplete(MockData.daughterId), isFalse);
      expect(controller.memberById(MockData.daughterId), isNull);
      expect(await storedDataOf(MockData.daughterId), (
        hasProfile: false,
        appointments: 0,
        questions: 0,
        symptoms: 0,
      ));
    });

    test('a failure deleting the profile keeps it for a retry', () async {
      familyRepository.failDelete = true;

      final result = await controller.delete(
        MockData.daughterId,
        userConfirmed: true,
      );

      expect(result.failedStep, MemberDeletionStep.profile);
      expect(controller.memberById(MockData.daughterId), isNotNull);
      expect(await storedDataOf(MockData.daughterId), (
        hasProfile: true,
        appointments: 0,
        questions: 0,
        symptoms: 0,
      ));

      familyRepository.failDelete = false;
      final retry = await controller.delete(
        MockData.daughterId,
        userConfirmed: true,
      );
      expect(retry.isSuccess, isTrue);
      expect(controller.memberById(MockData.daughterId), isNull);
    });

    test('a failure deleting appointments is reported as that step', () async {
      appointmentRepository.failDeleteByMember = true;

      final result = await controller.delete(
        MockData.daughterId,
        userConfirmed: true,
      );

      expect(result.failedStep, MemberDeletionStep.appointments);
      expect(controller.isDeletionIncomplete(MockData.daughterId), isTrue);
    });
  });
}
