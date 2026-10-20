import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/sync_state.dart';
import 'package:mydr/data/sync/sync_merge.dart';

void main() {
  group('version vectors', () {
    final a1 = VersionVector({'a': 1});
    final a2 = VersionVector({'a': 2});
    final a1b1 = VersionVector({'a': 1, 'b': 1});
    final b1 = VersionVector({'b': 1});

    test('order', () {
      expect(a1.compareTo(a1), VectorOrder.equal);
      expect(a1.compareTo(a2), VectorOrder.before);
      expect(a2.compareTo(a1), VectorOrder.after);
      expect(a1b1.compareTo(a1), VectorOrder.after);
      expect(a2.compareTo(a1b1), VectorOrder.concurrent);
      expect(a1.compareTo(b1), VectorOrder.concurrent);
      expect(VersionVector.empty.compareTo(a1), VectorOrder.before);
    });

    test('merge and increment', () {
      expect(a2.merge(b1), VersionVector({'a': 2, 'b': 1}));
      expect(a1.increment('b'), a1b1);
      expect(a2.merge(b1).includes(a2), isTrue);
      expect(a2.merge(b1).includes(a1b1), isTrue);
      expect(a1.includes(a2), isFalse);
      expect(VersionVector({'a': 0}), VersionVector.empty);
    });

    test('toString shows no device ids', () {
      expect(VersionVector({'device-123': 3}).toString(), 'VersionVector(1)');
    });
  });

  group('three-way merge', () {
    final base = {'id': 'x', 'name': 'a', 'notes': null, 'location': 'l'};

    test('changes to different fields combine', () {
      final result = SyncMerge.threeWay(
        SyncKind.appointment,
        base: base,
        local: {...base, 'notes': 'mine'},
        remote: {...base, 'location': 'theirs'},
      );
      expect(result, isA<MergeCombined>());
      expect((result as MergeCombined).payload, {
        ...base,
        'notes': 'mine',
        'location': 'theirs',
      });
    });

    test('the same field changed differently is a conflict', () {
      final result = SyncMerge.threeWay(
        SyncKind.appointment,
        base: base,
        local: {...base, 'name': 'b', 'notes': 'n'},
        remote: {...base, 'name': 'c', 'notes': 'n'},
      );
      expect(result, isA<MergeConflict>());
      expect((result as MergeConflict).fields, ['name']);
    });

    test('identical changes are the same', () {
      expect(
        SyncMerge.threeWay(
          SyncKind.appointment,
          base: base,
          local: {...base, 'name': 'b'},
          remote: {...base, 'name': 'b'},
        ),
        isA<MergeSame>(),
      );
    });

    test('without a base, every difference is a conflict', () {
      final result = SyncMerge.threeWay(
        SyncKind.symptom,
        base: null,
        local: {'id': 's', 'severity': 2},
        remote: {'id': 's', 'severity': 3},
      );
      expect((result as MergeConflict).fields, ['severity']);
    });

    test('lists compare by value', () {
      expect(
        SyncMerge.threeWay(
          SyncKind.member,
          base: {
            'allergies': ['a'],
          },
          local: {
            'allergies': ['a', 'b'],
          },
          remote: {
            'allergies': ['a', 'b'],
          },
        ),
        isA<MergeSame>(),
      );
    });

    test('a dose recorded with the same status keeps the later time', () {
      final result = SyncMerge.threeWay(
        SyncKind.dose,
        base: null,
        local: {'id': 'local', 'status': 'taken', 'recordedAt': 5},
        remote: {'id': 'remote', 'status': 'taken', 'recordedAt': 9},
      );
      expect((result as MergeCombined).payload['recordedAt'], 9);
      expect(result.payload['id'], 'local');
    });

    test('a dose recorded differently is a conflict', () {
      final result = SyncMerge.threeWay(
        SyncKind.dose,
        base: null,
        local: {'status': 'taken', 'recordedAt': 5},
        remote: {'status': 'skipped', 'recordedAt': 5},
      );
      expect((result as MergeConflict).fields, ['status']);
    });

    test('a photo\'s upload description is not a change', () {
      final record = {'id': 'm', 'description': 'd'};
      expect(
        SyncMerge.same(SyncKind.media, record, {
          ...record,
          'blob': {'object': 'x'},
        }),
        isTrue,
      );
    });
  });

  group('dose ids', () {
    test('the same scheduled dose has the same id everywhere', () {
      final at = DateTime(2026, 10, 19, 8);
      final id = DoseRecord.idFor('med-1', at);
      expect(id, DoseRecord.idFor('med-1', DateTime(2026, 10, 19, 8, 0, 30)));
      expect(id, isNot(DoseRecord.idFor('med-1', DateTime(2026, 10, 19, 20))));
      expect(id, isNot(DoseRecord.idFor('med-2', at)));
      expect(
        id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-8[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
          ),
        ),
      );
    });

    test('sync ids name a dose by its medication and time', () {
      expect(
        SyncIds.dose('med-1', '2026-10-19T08:00:00.000000'),
        'med-1@2026-10-19T08:00:00.000000',
      );
    });
  });
}
