import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:mydr/data/local/storage_codecs.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../helpers/memory_key_store.dart';

/// The schema enforces the app's data rules itself, so even a bug in a
/// repository cannot store invalid or orphaned records. Test values are
/// fictional and non-medical.
void main() {
  late Directory directory;
  late LocalDatabase database;

  setUp(() async {
    directory = Directory.systemTemp.createTempSync('mydr_schema_test');
    database = await LocalDatabaseOpener(
      keyStore: MemoryDatabaseKeyStore(),
      locateFile: () async => File('${directory.path}/test.sqlite'),
    ).open();
  });

  tearDown(() async {
    await database.close();
    directory.deleteSync(recursive: true);
  });

  final when = StorageCodecs.encodeLocalDateTime(DateTime(2026, 10, 15, 9));
  final rejected = throwsA(isA<SqliteException>());

  Future<void> run(String sql, [List<Object?> args = const []]) =>
      database.customStatement(sql, args);

  Future<void> member(
    String id, {
    String name = 'בדיקה',
    String relation = 'child',
    String? birthDate,
    String allergies = '[]',
  }) => run(
    'INSERT INTO family_members '
    '(id, name, relation, birth_date, allergies) VALUES (?, ?, ?, ?, ?)',
    [id, name, relation, birthDate, allergies],
  );

  Future<void> appointment(String id, String memberId, {String? at}) => run(
    'INSERT INTO appointments (id, member_id, doctor_name, scheduled_at) '
    'VALUES (?, ?, ?, ?)',
    [id, memberId, 'רופא בדיקה', at ?? when],
  );

  Future<void> question(String id, String memberId, {String? appointmentId}) =>
      run(
        'INSERT INTO doctor_questions '
        '(id, member_id, appointment_id, question_text, created_at) '
        'VALUES (?, ?, ?, ?, ?)',
        [id, memberId, appointmentId, 'שאלת בדיקה', 0],
      );

  Future<void> symptom(
    String id,
    String memberId, {
    int severity = 3,
    String status = 'ongoing',
    int? durationMicros,
    String? at,
  }) => run(
    'INSERT INTO symptom_entries (id, member_id, name, name_key, started_at, '
    'severity, status, duration_micros) VALUES (?, ?, ?, ?, ?, ?, ?, ?)',
    [
      id,
      memberId,
      'בדיקה',
      'בדיקה',
      at ?? when,
      severity,
      status,
      durationMicros,
    ],
  );

  group('family members', () {
    test('accept a valid profile', () async {
      await member(
        'm1',
        birthDate: '2016-01-20',
        allergies: '["אבקה"]',
        relation: 'self',
      );
    });

    test('reject a blank name, an unknown relation and bad formats', () async {
      await expectLater(() => member('a', name: '  '), rejected);
      await expectLater(() => member('b', relation: 'friend'), rejected);
      await expectLater(() => member('c', birthDate: '20/01/2016'), rejected);
      await expectLater(() => member('d', allergies: 'not json'), rejected);
      await expectLater(() => member('e', allergies: '{"a": 1}'), rejected);
      await expectLater(() => member('', name: 'בדיקה'), rejected);
    });

    test('allow only one "self" profile', () async {
      await member('m1', relation: 'self');
      await member('m2', relation: 'child');
      await member('m3', relation: 'child');

      await expectLater(() => member('m4', relation: 'self'), rejected);
    });

    test('reject a duplicate id', () async {
      await member('m1');
      await expectLater(() => member('m1'), rejected);
    });
  });

  group('links to family members', () {
    test('records of an unknown member are rejected', () async {
      await expectLater(() => appointment('a1', 'missing'), rejected);
      await expectLater(() => question('q1', 'missing'), rejected);
      await expectLater(() => symptom('s1', 'missing'), rejected);
    });

    test(
      'a member with records cannot be deleted until they are gone',
      () async {
        await member('m1');
        await appointment('a1', 'm1');
        await question('q1', 'm1');
        await symptom('s1', 'm1');

        await expectLater(
          () => run("DELETE FROM family_members WHERE id = 'm1'"),
          rejected,
        );

        await run("DELETE FROM symptom_entries WHERE member_id = 'm1'");
        await run("DELETE FROM doctor_questions WHERE member_id = 'm1'");
        await run("DELETE FROM appointments WHERE member_id = 'm1'");
        await run("DELETE FROM family_members WHERE id = 'm1'");
      },
    );

    test('a failed deletion inside a transaction leaves everything', () async {
      await member('m1');
      await symptom('s1', 'm1');
      await appointment('a1', 'm1');

      await expectLater(
        database.transaction(() async {
          await run("DELETE FROM symptom_entries WHERE member_id = 'm1'");
          await run("DELETE FROM family_members WHERE id = 'm1'");
        }),
        throwsA(anything),
      );

      final symptoms = await database
          .customSelect('SELECT count(*) AS n FROM symptom_entries')
          .getSingle();
      expect(symptoms.read<int>('n'), 1);
    });
  });

  group('questions and appointments', () {
    setUp(() async {
      await member('m1');
      await member('m2');
      await appointment('a1', 'm1');
    });

    test(
      'a question may be general, or linked to its member\'s appointment',
      () async {
        await question('q1', 'm1');
        await question('q2', 'm1', appointmentId: 'a1');
      },
    );

    test('a question cannot link to another member\'s appointment', () async {
      await expectLater(
        () => question('q1', 'm2', appointmentId: 'a1'),
        rejected,
      );
    });

    test('a question cannot link to a missing appointment', () async {
      await expectLater(
        () => question('q1', 'm1', appointmentId: 'missing'),
        rejected,
      );
    });

    test('an appointment with linked questions cannot be deleted or moved '
        'until they are unlinked', () async {
      await question('q1', 'm1', appointmentId: 'a1');

      await expectLater(
        () => run("DELETE FROM appointments WHERE id = 'a1'"),
        rejected,
      );
      await expectLater(
        () => run("UPDATE appointments SET member_id = 'm2' WHERE id = 'a1'"),
        rejected,
      );

      await run(
        "UPDATE doctor_questions SET appointment_id = NULL "
        "WHERE appointment_id = 'a1'",
      );
      await run("UPDATE appointments SET member_id = 'm2' WHERE id = 'a1'");
      await run("DELETE FROM appointments WHERE id = 'a1'");
    });

    test('rejects blank text and an invalid resolved flag', () async {
      await expectLater(
        () => run(
          'INSERT INTO doctor_questions '
          '(id, member_id, question_text, created_at) VALUES (?, ?, ?, ?)',
          ['q1', 'm1', ' ', 0],
        ),
        rejected,
      );
      await expectLater(
        () => run(
          'INSERT INTO doctor_questions (id, member_id, question_text, '
          'created_at, is_resolved) VALUES (?, ?, ?, ?, ?)',
          ['q2', 'm1', 'שאלה', 0, 2],
        ),
        rejected,
      );
    });

    test('an appointment needs a doctor and a valid time', () async {
      await expectLater(
        () => run(
          'INSERT INTO appointments (id, member_id, doctor_name, scheduled_at) '
          'VALUES (?, ?, ?, ?)',
          ['a2', 'm1', '  ', when],
        ),
        rejected,
      );
      await expectLater(
        () => appointment('a3', 'm1', at: '2026-10-15 09:00'),
        rejected,
      );
    });
  });

  group('symptom entries', () {
    setUp(() => member('m1'));

    test('accept the full range of ratings and both statuses', () async {
      for (var severity = 1; severity <= 5; severity++) {
        await symptom('s$severity', 'm1', severity: severity);
      }
      await symptom('r', 'm1', status: 'resolved', durationMicros: 0);
    });

    test('reject ratings outside 1-5, unknown statuses, negative durations '
        'and bad times', () async {
      await expectLater(() => symptom('a', 'm1', severity: 0), rejected);
      await expectLater(() => symptom('b', 'm1', severity: 6), rejected);
      await expectLater(() => symptom('c', 'm1', status: 'better'), rejected);
      await expectLater(() => symptom('d', 'm1', durationMicros: -1), rejected);
      await expectLater(() => symptom('e', 'm1', at: '2026-10-15'), rejected);
    });

    test('strict column types: text is not accepted as a rating', () async {
      await expectLater(
        () => run(
          'INSERT INTO symptom_entries (id, member_id, name, name_key, '
          'started_at, severity) VALUES (?, ?, ?, ?, ?, ?)',
          ['x', 'm1', 'בדיקה', 'בדיקה', when, 'high'],
        ),
        rejected,
      );
    });
  });
}
