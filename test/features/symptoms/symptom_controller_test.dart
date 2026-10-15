import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/symptoms/symptom_controller.dart';

import '../../helpers/flaky_repositories.dart';

void main() {
  final now = DateTime(2026, 10, 15, 12);

  final members = [
    FamilyMember(id: 'm1', name: 'דנה', relation: FamilyRelation.self),
    FamilyMember(id: 'm2', name: 'נועה', relation: FamilyRelation.child),
  ];

  SymptomEntry entry(
    String id,
    String memberId,
    String name,
    Duration ago,
    int severity, {
    SymptomStatus status = SymptomStatus.ongoing,
    Duration? duration,
    String? notes,
  }) => SymptomEntry(
    id: id,
    memberId: memberId,
    name: name,
    startedAt: now.subtract(ago),
    severity: severity,
    status: status,
    duration: duration,
    notes: notes,
  );

  // Stored in no particular order. s1/s2 are the same symptom (s2 has extra
  // spaces), as are s6/s7 (different case); s4 and s5 share a moment.
  final initialEntries = [
    entry('s4', 'm2', 'חום', const Duration(hours: 72), 5),
    entry('s1', 'm1', 'שיעול', const Duration(hours: 48), 3),
    entry('s7', 'm1', 'cough', const Duration(hours: 3), 2),
    entry(
      's3',
      'm1',
      'כאב ראש',
      const Duration(hours: 5),
      2,
      status: SymptomStatus.resolved,
      duration: const Duration(hours: 3),
      notes: 'אחרי העבודה',
    ),
    entry('s2', 'm1', '  שיעול ', const Duration(hours: 24), 4),
    entry('s6', 'm1', 'Cough', const Duration(hours: 96), 1),
    entry('s5', 'm2', 'חום', const Duration(hours: 72), 4),
  ];

  late FlakyFamilyRepository familyRepository;
  late FlakySymptomRepository symptomRepository;
  late AppDependencies dependencies;
  late FamilyController familyController;
  late SymptomController controller;
  late int notifications;

  SymptomController buildController() => SymptomController(
    dependencies: dependencies,
    familyController: familyController,
    clock: () => now,
  );

  setUp(() async {
    familyRepository = FlakyFamilyRepository(members);
    symptomRepository = FlakySymptomRepository(initialEntries);
    dependencies = AppDependencies(
      familyRepository: familyRepository,
      appointmentRepository: FlakyAppointmentRepository(),
      doctorQuestionRepository: FlakyDoctorQuestionRepository(),
      symptomRepository: symptomRepository,
    );
    familyController = FamilyController(dependencies);
    controller = buildController();
    await familyController.load();
    await controller.load();

    notifications = 0;
    controller.addListener(() => notifications++);
  });

  tearDown(() {
    controller.dispose();
    familyController.dispose();
  });

  List<String> ids(Iterable<SymptomEntry> list) =>
      list.map((e) => e.id).toList();

  SymptomEntry newEntry({
    String memberId = 'm1',
    String name = 'בחילה',
    DateTime? startedAt,
    int severity = 2,
    String? notes,
  }) => SymptomEntry(
    id: controller.createId(),
    memberId: memberId,
    name: name,
    startedAt: startedAt ?? now.subtract(const Duration(hours: 1)),
    severity: severity,
    notes: notes,
  );

  Future<SymptomSaveResult> updateS3({
    String memberId = 'm1',
    String name = 'כאב ראש',
    DateTime? startedAt,
    int severity = 3,
    String? notes = 'עדכון',
  }) => controller.update(
    's3',
    memberId: memberId,
    name: name,
    startedAt: startedAt ?? now.subtract(const Duration(hours: 5)),
    severity: severity,
    notes: notes,
  );

  group('load', () {
    test('reads all records, newest first, ties by id', () {
      expect(ids(controller.entries), [
        's7',
        's3',
        's2',
        's1',
        's4',
        's5',
        's6',
      ]);
      expect(controller.isLoading, isFalse);
      expect(controller.hasLoadError, isFalse);
    });

    test('reports loading, then done, to listeners', () async {
      final states = <bool>[];
      controller.addListener(() => states.add(controller.isLoading));

      await controller.load();

      expect(states, [true, false]);
    });

    test('sets an error flag on failure and keeps the previous list', () async {
      symptomRepository.failGetAll = true;
      await controller.load();

      expect(controller.hasLoadError, isTrue);
      expect(controller.isLoading, isFalse);
      expect(controller.entries, hasLength(7));
    });

    test('clears the error flag when a retry succeeds', () async {
      symptomRepository.failGetAll = true;
      await controller.load();
      symptomRepository.failGetAll = false;
      await controller.load();

      expect(controller.hasLoadError, isFalse);
    });

    test('when loads overlap, only the latest result is applied', () async {
      final gate = Completer<void>();
      symptomRepository.getAllGate = gate;
      final first = controller.load();
      symptomRepository.getAllGate = null;

      await symptomRepository.add(newEntry());
      await controller.load();
      expect(controller.entries, hasLength(8));
      expect(controller.isLoading, isFalse);

      // The first load now reads newer data, but it is outdated: ignored.
      await symptomRepository.delete('s1');
      gate.complete();
      await first;

      expect(controller.entries, hasLength(8));
      expect(controller.entryById('s1'), isNotNull);
      expect(controller.isLoading, isFalse);
    });
  });

  group('queries', () {
    test('entryById finds loaded records, null otherwise', () {
      expect(controller.entryById('s3')?.notes, 'אחרי העבודה');
      expect(controller.entryById('missing'), isNull);
    });

    test('history filters by member, newest first', () {
      expect(ids(controller.history(memberId: 'm2')), ['s4', 's5']);
      expect(ids(controller.history(memberId: 'm1')), [
        's7',
        's3',
        's2',
        's1',
        's6',
      ]);
    });

    test('groups by member and normalized name, each oldest first', () {
      final groups = controller.groups();

      expect(
        [for (final g in groups) g.name],
        ['cough', 'כאב ראש', 'שיעול', 'חום'],
      );
      expect(ids(groups[0].entries), ['s6', 's7']);
      expect(ids(groups[2].entries), ['s1', 's2']);
      expect(groups[2].latest.id, 's2');
      // Same moment: the order matches the history's.
      expect(ids(groups[3].entries), ['s5', 's4']);
      expect(groups[3].memberId, 'm2');
    });

    test('groups can be limited to one member', () {
      final groups = controller.groups(memberId: 'm2');
      expect([for (final g in groups) g.name], ['חום']);
    });

    test('the same name of different members is never grouped together', () {
      final group = controller.groupFor('m1', 'חום');
      expect(group, isNull);
      expect(controller.groupFor('m2', 'חום')!.entries, hasLength(2));
    });

    test('groupFor ignores case and extra spaces', () {
      expect(ids(controller.groupFor('m1', '  COUGH ')!.entries), ['s6', 's7']);
      expect(ids(controller.groupFor('m1', 'שיעול')!.entries), ['s1', 's2']);
      expect(controller.groupFor('m1', 'בחילה'), isNull);
    });

    test("suggests the member's names first, then the family's, once each", () {
      expect(controller.nameSuggestions(memberId: 'm2'), [
        'חום',
        'cough',
        'כאב ראש',
        'שיעול',
      ]);
      expect(controller.nameSuggestions(), [
        'cough',
        'כאב ראש',
        'שיעול',
        'חום',
      ]);
    });

    test('return unmodifiable lists', () {
      expect(() => controller.history().clear(), throwsUnsupportedError);
      expect(() => controller.groups().clear(), throwsUnsupportedError);
      expect(
        () => controller.groups().first.entries.clear(),
        throwsUnsupportedError,
      );
      expect(
        () => controller.nameSuggestions().clear(),
        throwsUnsupportedError,
      );
    });

    test('normalizeName and tidyName', () {
      expect(
        SymptomController.normalizeName('  Sore   Throat '),
        'sore throat',
      );
      expect(SymptomController.tidyName('  Sore   Throat '), 'Sore Throat');
    });

    test('createId returns a new id each time', () {
      final first = controller.createId();
      expect(controller.createId(), isNot(first));
    });
  });

  group('add', () {
    test('stores a record with tidy name and notes, and notifies', () async {
      final added = newEntry(name: '  כאב   בטן ', notes: '  אחרי ארוחה  ');

      expect(await controller.add(added), SymptomSaveResult.success);

      final stored = controller.entryById(added.id)!;
      expect(stored.name, 'כאב בטן');
      expect(stored.notes, 'אחרי ארוחה');
      expect(stored.status, SymptomStatus.ongoing);
      expect(notifications, 1);
    });

    test('blank notes are stored as none', () async {
      final added = newEntry(notes: '   ');
      await controller.add(added);
      expect(controller.entryById(added.id)!.notes, isNull);
    });

    test('a follow-up record joins the existing group', () async {
      await controller.add(newEntry(name: 'שיעול'));
      expect(controller.groupFor('m1', 'שיעול')!.entries, hasLength(3));
    });

    test('rejects an empty name', () async {
      expect(
        await controller.add(newEntry(name: '   ')),
        SymptomSaveResult.nameRequired,
      );
      expect(controller.entries, hasLength(7));
    });

    test('rejects an unknown member', () async {
      expect(
        await controller.add(newEntry(memberId: 'missing')),
        SymptomSaveResult.memberNotFound,
      );
    });

    test('accepts now, rejects the future', () async {
      expect(
        await controller.add(newEntry(startedAt: now)),
        SymptomSaveResult.success,
      );
      expect(
        await controller.add(
          newEntry(startedAt: now.add(const Duration(minutes: 1))),
        ),
        SymptomSaveResult.dateInFuture,
      );
    });

    test('accepts up to five years back, not more', () async {
      expect(controller.earliestAllowedDate, DateTime(2021, 10, 15));
      expect(
        await controller.add(newEntry(startedAt: DateTime(2021, 10, 15))),
        SymptomSaveResult.success,
      );
      expect(
        await controller.add(newEntry(startedAt: DateTime(2021, 10, 14, 23))),
        SymptomSaveResult.dateTooOld,
      );
    });

    test('reports failure without changing the list', () async {
      symptomRepository.failAdd = true;

      expect(await controller.add(newEntry()), SymptomSaveResult.failed);
      expect(controller.entries, hasLength(7));
      expect(notifications, 0);
    });
  });

  group('update', () {
    test('saves the editable details and keeps status and duration', () async {
      final result = await updateS3(name: 'מיגרנה', severity: 5);

      expect(result, SymptomSaveResult.success);
      final stored = (await symptomRepository.getById('s3'))!;
      expect(stored.name, 'מיגרנה');
      expect(stored.severity, 5);
      expect(stored.notes, 'עדכון');
      // Not editable in the UI, so never lost.
      expect(stored.status, SymptomStatus.resolved);
      expect(stored.duration, const Duration(hours: 3));
      expect(notifications, 1);
    });

    test('can clear the notes', () async {
      await updateS3(notes: null);
      expect((await symptomRepository.getById('s3'))!.notes, isNull);
    });

    test('can move a record to another member', () async {
      expect(await updateS3(memberId: 'm2'), SymptomSaveResult.success);
      expect(controller.entryById('s3')!.memberId, 'm2');
      expect(ids(controller.history(memberId: 'm2')), contains('s3'));
    });

    test('rejects an unknown member, changing nothing', () async {
      expect(
        await updateS3(memberId: 'missing'),
        SymptomSaveResult.memberNotFound,
      );
      expect(controller.entryById('s3')!.memberId, 'm1');
    });

    test('rejects a record that no longer exists', () async {
      final result = await controller.update(
        'missing',
        memberId: 'm1',
        name: 'x',
        startedAt: now,
        severity: 1,
        notes: null,
      );
      expect(result, SymptomSaveResult.entryNotFound);
    });

    test('rejects an empty name and a future date', () async {
      expect(await updateS3(name: ''), SymptomSaveResult.nameRequired);
      expect(
        await updateS3(startedAt: now.add(const Duration(hours: 1))),
        SymptomSaveResult.dateInFuture,
      );
      expect(controller.entryById('s3')!.name, 'כאב ראש');
    });

    test('keeps an old date that was already stored, but rejects a new '
        'too-old date', () async {
      final old = entry(
        'old',
        'm1',
        'שבר',
        Duration.zero,
        3,
      ).copyWith(startedAt: DateTime(2019, 1, 1));
      await symptomRepository.add(old);
      await controller.load();

      final keep = await controller.update(
        'old',
        memberId: 'm1',
        name: 'שבר',
        startedAt: DateTime(2019, 1, 1),
        severity: 3,
        notes: 'הערה חדשה',
      );
      expect(keep, SymptomSaveResult.success);

      final change = await controller.update(
        'old',
        memberId: 'm1',
        name: 'שבר',
        startedAt: DateTime(2019, 2, 1),
        severity: 3,
        notes: null,
      );
      expect(change, SymptomSaveResult.dateTooOld);
    });

    test('reports failure without changing anything', () async {
      symptomRepository.failUpdate = true;

      expect(await updateS3(name: 'שונה'), SymptomSaveResult.failed);
      expect(controller.entryById('s3')!.name, 'כאב ראש');
      expect(notifications, 0);
    });
  });

  group('delete', () {
    test('refuses to run without user confirmation', () async {
      await expectLater(
        controller.delete('s1', userConfirmed: false),
        throwsArgumentError,
      );
      expect(await symptomRepository.getById('s1'), isNotNull);
      expect(notifications, 0);
    });

    test('removes only that record, also from its group', () async {
      expect(await controller.delete('s1', userConfirmed: true), isTrue);

      expect(controller.entryById('s1'), isNull);
      expect(ids(controller.groupFor('m1', 'שיעול')!.entries), ['s2']);
      expect(controller.entries, hasLength(6));
    });

    test('a failure keeps the record, and a retry works', () async {
      symptomRepository.failDelete = true;
      expect(await controller.delete('s1', userConfirmed: true), isFalse);
      expect(controller.entryById('s1'), isNotNull);

      symptomRepository.failDelete = false;
      expect(await controller.delete('s1', userConfirmed: true), isTrue);
      expect(controller.entryById('s1'), isNull);
    });
  });

  group('sync with FamilyController', () {
    test("deleting a family member removes their records", () async {
      await familyController.delete('m2', userConfirmed: true);
      await pumpEventQueue();

      expect(controller.history(memberId: 'm2'), isEmpty);
      expect(controller.entries, hasLength(5));
    });

    test('a partly failed member deletion still reloads', () async {
      // Symptoms are deleted first, then deleting the profile fails.
      familyRepository.failDelete = true;

      await familyController.delete('m2', userConfirmed: true);
      await pumpEventQueue();

      expect(familyController.memberById('m2'), isNotNull);
      expect(controller.history(memberId: 'm2'), isEmpty);
    });

    test(
      'a member deletion that failed on symptoms keeps them shown',
      () async {
        symptomRepository.failDeleteByMember = true;

        await familyController.delete('m2', userConfirmed: true);
        await pumpEventQueue();

        expect(ids(controller.history(memberId: 'm2')), ['s4', 's5']);
      },
    );

    test('does not reload on unrelated family changes', () async {
      final callsBefore = symptomRepository.getAllCalls;

      await familyController.load();
      await familyController.add(
        FamilyMember(id: 'm3', name: 'אבי', relation: FamilyRelation.spouse),
      );
      await familyController.update(members[1].copyWith(name: 'נועה ל.'));
      await pumpEventQueue();

      expect(symptomRepository.getAllCalls, callsBefore);
      expect(notifications, 0);
    });

    test('reloads once per member deletion, without loops', () async {
      final callsBefore = symptomRepository.getAllCalls;

      await familyController.delete('m2', userConfirmed: true);
      await pumpEventQueue();

      expect(symptomRepository.getAllCalls, callsBefore + 1);
    });

    test('stops listening once disposed', () async {
      final other = buildController();
      other.dispose();
      final callsBefore = symptomRepository.getAllCalls;

      await familyController.delete('m2', userConfirmed: true);
      await pumpEventQueue();

      // Only the live controller from setUp reloaded.
      expect(symptomRepository.getAllCalls, callsBefore + 1);
    });
  });
}
