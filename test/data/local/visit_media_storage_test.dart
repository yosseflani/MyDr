import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/local/local_database.dart' hide VisitMedia;
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:mydr/data/local/repositories/local_repository_support.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/visit_media.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../helpers/memory_key_store.dart';

/// Visit media records against both repository implementations, plus the
/// database-only guarantees: constraints, migration from version 1 and
/// keeping everything across a restart. Test data is fictional.
void main() {
  final child = FamilyMember(
    id: 'm1',
    name: 'נועה',
    relation: FamilyRelation.child,
  );
  final sibling = FamilyMember(
    id: 'm2',
    name: 'איתי',
    relation: FamilyRelation.child,
  );
  final childVisit = Appointment(
    id: 'a1',
    memberId: 'm1',
    doctorName: 'רופא',
    dateTime: DateTime(2026, 11, 2, 9, 30),
  );
  final siblingVisit = Appointment(
    id: 'a2',
    memberId: 'm2',
    doctorName: 'רופא',
    dateTime: DateTime(2026, 11, 3, 9, 30),
  );

  VisitMedia media(
    String id, {
    String memberId = 'm1',
    String appointmentId = 'a1',
    int second = 0,
    VisitMediaKind kind = VisitMediaKind.photo,
  }) => VisitMedia(
    id: id,
    memberId: memberId,
    appointmentId: appointmentId,
    kind: kind,
    fileName: 'file-$id.${kind == VisitMediaKind.photo ? 'jpg' : 'mp4'}',
    byteSize: 1234,
    createdAt: DateTime(2026, 10, 17, 20, 0, second, 0, 123),
    description: 'תיאור $id',
  );

  final implementations =
      <String, Future<(AppDependencies, Future<void> Function())> Function()>{
        'in memory': () async => (AppDependencies.empty(), () async {}),
        'local database': () async {
          final directory = Directory.systemTemp.createTempSync(
            'mydr_media_repo',
          );
          final database = await LocalDatabaseOpener(
            keyStore: MemoryDatabaseKeyStore(),
            locateFile: () async => File('${directory.path}/db.sqlite'),
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

  for (final MapEntry(key: name, value: create) in implementations.entries) {
    group('VisitMediaRepository ($name)', () {
      late AppDependencies deps;

      setUp(() async {
        final (created, dispose) = await create();
        deps = created;
        addTearDown(dispose);
        await deps.familyRepository.add(child);
        await deps.familyRepository.add(sibling);
        await deps.appointmentRepository.add(childVisit);
        await deps.appointmentRepository.add(siblingVisit);
      });

      test('stores, reads back exactly and orders by time', () async {
        final repo = deps.visitMediaRepository;
        await repo.add(media('x2', second: 2, kind: VisitMediaKind.video));
        await repo.add(media('x1', second: 1));

        expect(await repo.getById('x1'), media('x1', second: 1));
        expect([for (final m in await repo.getAll()) m.id], ['x1', 'x2']);
        expect((await repo.getById('x2'))!.kind, VisitMediaKind.video);
      });

      test('filters by member and by appointment', () async {
        final repo = deps.visitMediaRepository;
        await repo.add(media('x1'));
        await repo.add(media('y1', memberId: 'm2', appointmentId: 'a2'));

        expect(
          [for (final m in await repo.getAll(memberId: 'm1')) m.id],
          ['x1'],
        );
        expect(
          [for (final m in await repo.getAll(appointmentId: 'a2')) m.id],
          ['y1'],
        );
      });

      test('a duplicate id is refused', () async {
        await deps.visitMediaRepository.add(media('x1'));
        await expectLater(
          deps.visitMediaRepository.add(media('x1')),
          throwsStateError,
        );
      });

      test('update changes only the description', () async {
        final repo = deps.visitMediaRepository;
        await repo.add(media('x1'));

        final changed = VisitMedia(
          id: 'x1',
          memberId: 'm2',
          appointmentId: 'a2',
          kind: VisitMediaKind.video,
          fileName: 'other.mp4',
          byteSize: 1,
          createdAt: DateTime(2000),
          description: 'חדש',
        );
        await repo.update(changed);

        expect(
          await repo.getById('x1'),
          media('x1').copyWith(description: () => 'חדש'),
        );
        await expectLater(repo.update(media('nope')), throwsStateError);
      });

      test('deletes one, by appointment and by member', () async {
        final repo = deps.visitMediaRepository;
        await repo.add(media('x1'));
        await repo.add(media('x2', second: 1));
        await repo.add(
          media('y1', memberId: 'm2', appointmentId: 'a2', second: 2),
        );

        await repo.delete('x1');
        await repo.delete('x1');
        expect([for (final m in await repo.getAll()) m.id], ['x2', 'y1']);

        await repo.deleteByAppointment('a1');
        expect([for (final m in await repo.getAll()) m.id], ['y1']);

        await repo.deleteByMember('m2');
        expect(await repo.getAll(), isEmpty);
      });
    });
  }

  group('local database guarantees', () {
    late Directory directory;
    late File file;
    late MemoryDatabaseKeyStore keys;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('mydr_media_db');
      file = File('${directory.path}/${LocalDatabaseOpener.fileName}');
      keys = MemoryDatabaseKeyStore();
    });

    tearDown(() => directory.deleteSync(recursive: true));

    Future<LocalDatabase> open() => LocalDatabaseOpener(
      keyStore: keys,
      locateFile: () async => file,
    ).open();

    Future<AppDependencies> seeded(LocalDatabase database) async {
      final deps = AppDependencies.local(database);
      await deps.familyRepository.add(child);
      await deps.familyRepository.add(sibling);
      await deps.appointmentRepository.add(childVisit);
      await deps.appointmentRepository.add(siblingVisit);
      return deps;
    }

    Matcher rejected() => throwsA(
      isA<LocalDataException>().having(
        (e) => e.error,
        'error',
        LocalDataError.rejected,
      ),
    );

    test('media cannot be linked to another member\'s appointment', () async {
      final database = await open();
      addTearDown(database.close);
      final deps = await seeded(database);

      await expectLater(
        deps.visitMediaRepository.add(
          media('x1', memberId: 'm2', appointmentId: 'a1'),
        ),
        rejected(),
      );
      await expectLater(
        deps.visitMediaRepository.add(media('x1', appointmentId: 'missing')),
        rejected(),
      );
      expect(await deps.visitMediaRepository.getAll(), isEmpty);
    });

    test(
      'an appointment with media cannot be deleted or moved directly',
      () async {
        final database = await open();
        addTearDown(database.close);
        final deps = await seeded(database);
        await deps.visitMediaRepository.add(media('x1'));

        await expectLater(deps.appointmentRepository.delete('a1'), rejected());
        await expectLater(
          deps.appointmentRepository.update(
            childVisit.copyWith(memberId: 'm2'),
          ),
          rejected(),
        );
        expect(await deps.appointmentRepository.getById('a1'), childVisit);
      },
    );

    test('file names must be bare, unique names', () async {
      final database = await open();
      addTearDown(database.close);
      final deps = await seeded(database);
      await deps.visitMediaRepository.add(media('x1'));

      for (final badName in [
        '../x.jpg',
        'a/b.jpg',
        r'a\b.jpg',
        '.hidden',
        '',
      ]) {
        await expectLater(
          database.customStatement(
            'INSERT INTO visit_media (id, member_id, appointment_id, kind, '
            'file_name, byte_size, created_at) VALUES (?, ?, ?, ?, ?, ?, ?)',
            ['bad', 'm1', 'a1', 'photo', badName, 1, 0],
          ),
          throwsA(anything),
          reason: badName,
        );
      }
      await expectLater(
        deps.visitMediaRepository.add(
          VisitMedia(
            id: 'x2',
            memberId: 'm1',
            appointmentId: 'a1',
            kind: VisitMediaKind.photo,
            fileName: media('x1').fileName,
            byteSize: 1,
            createdAt: DateTime(2026),
          ),
        ),
        rejected(),
      );
    });

    test('records are kept after closing and reopening', () async {
      var database = await open();
      final deps = await seeded(database);
      await deps.visitMediaRepository.add(media('x1'));
      await database.close();

      database = await open();
      addTearDown(database.close);
      expect(
        await AppDependencies.local(
          database,
        ).visitMediaRepository.getById('x1'),
        media('x1'),
      );
    });

    test(
      'upgrading a version 1 database keeps all data and adds the table',
      () async {
        // Builds a genuine version 1 file: the current schema minus
        // visit_media and the later (version 3) medication tables.
        var database = await open();
        await seeded(database);
        await database.close();
        final raw = sqlite3.open(file.path)
          ..execute("PRAGMA key = \"x'${keys.key}'\"")
          ..execute('DROP TABLE dose_records')
          ..execute('DROP TABLE medications')
          ..execute('DROP TABLE visit_media')
          ..execute('PRAGMA user_version = 1');
        expect(
          raw.select(
            "SELECT name FROM sqlite_master WHERE name LIKE 'visit_media%'",
          ),
          isEmpty,
        );
        raw.close();

        database = await open();
        addTearDown(database.close);
        final upgraded = AppDependencies.local(database);

        final version = await database
            .customSelect('PRAGMA user_version')
            .getSingle();
        expect(version.data.values.first, LocalDatabase.currentSchemaVersion);
        expect(await upgraded.familyRepository.getAll(), hasLength(2));
        expect(await upgraded.appointmentRepository.getById('a1'), childVisit);

        await upgraded.visitMediaRepository.add(media('x1'));
        expect(await upgraded.visitMediaRepository.getById('x1'), media('x1'));
        final indexes = await database
            .customSelect(
              "SELECT name FROM sqlite_master WHERE type = 'index' "
              "AND name LIKE 'visit_media_by_%' ORDER BY name",
            )
            .get();
        expect(
          [for (final r in indexes) r.read<String>('name')],
          ['visit_media_by_appointment', 'visit_media_by_member'],
        );
      },
    );
  });
}
