import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/local/database_key_store.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/local_database_exception.dart';
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../helpers/memory_key_store.dart';

/// Runs against the real SQLCipher library (selected in pubspec.yaml), so
/// encryption is really exercised.
void main() {
  late Directory directory;
  late File file;
  late MemoryDatabaseKeyStore keys;
  final opened = <LocalDatabase>[];

  setUp(() {
    directory = Directory.systemTemp.createTempSync('mydr_db_test');
    file = File('${directory.path}/${LocalDatabaseOpener.fileName}');
    keys = MemoryDatabaseKeyStore();
  });

  tearDown(() async {
    for (final database in opened) {
      await database.close();
    }
    opened.clear();
    directory.deleteSync(recursive: true);
  });

  LocalDatabaseOpener opener([DatabaseKeyStore? store]) => LocalDatabaseOpener(
    keyStore: store ?? keys,
    locateFile: () async => file,
  );

  Future<LocalDatabase> open([DatabaseKeyStore? store]) async {
    final database = await opener(store).open();
    opened.add(database);
    return database;
  }

  Future<void> closeAll() async {
    for (final database in opened) {
      await database.close();
    }
    opened.clear();
  }

  Matcher failsWith(LocalDatabaseError error) => throwsA(
    isA<LocalDatabaseException>().having((e) => e.error, 'error', error),
  );

  Future<void> addMember(LocalDatabase database, String id) =>
      database.customStatement(
        'INSERT INTO family_members (id, name, relation) VALUES (?, ?, ?)',
        [id, 'בדיקה', 'child'],
      );

  Future<List<String>> memberIds(LocalDatabase database) async => [
    for (final row
        in await database
            .customSelect('SELECT id FROM family_members ORDER BY id')
            .get())
      row.read<String>('id'),
  ];

  group('first use', () {
    test('creates the database and a new random key', () async {
      final database = await open();

      expect(file.existsSync(), isTrue);
      expect(keys.writes, 1);
      expect(DatabaseKeys.isValid(keys.key!), isTrue);

      final cipher = await database
          .customSelect('PRAGMA cipher_version')
          .getSingle();
      expect('${cipher.data.values.first}', isNotEmpty);
      final version = await database
          .customSelect('PRAGMA user_version')
          .getSingle();
      expect(version.data.values.first, LocalDatabase.currentSchemaVersion);
      final foreignKeys = await database
          .customSelect('PRAGMA foreign_keys')
          .getSingle();
      expect(foreignKeys.data.values.first, 1);

      final tables = [
        for (final row
            in await database
                .customSelect(
                  "SELECT name FROM sqlite_master WHERE type = 'table' "
                  'ORDER BY name',
                )
                .get())
          row.read<String>('name'),
      ];
      expect(
        tables,
        containsAll([
          'family_members',
          'appointments',
          'doctor_questions',
          'symptom_entries',
        ]),
      );
    });

    test('every new database gets its own key', () async {
      await open();
      await closeAll();
      final firstKey = keys.key;
      file.deleteSync();
      final otherKeys = MemoryDatabaseKeyStore();

      await open(otherKeys);

      expect(otherKeys.key, isNot(firstKey));
    });
  });

  group('encryption', () {
    test('the file is not readable as a plain SQLite database', () async {
      final database = await open();
      await addMember(database, 'm1');
      await closeAll();

      final header = file.readAsBytesSync().sublist(0, 16);
      expect(String.fromCharCodes(header), isNot('SQLite format 3\u0000'));
      expect(
        file.readAsStringSync(encoding: latin1),
        isNot(contains('family_members')),
      );

      final plain = sqlite3.open(file.path);
      addTearDown(plain.close);
      expect(
        () => plain.select('SELECT count(*) FROM sqlite_master'),
        throwsA(isA<SqliteException>()),
      );
    });

    test('data survives closing and opening again', () async {
      final database = await open();
      await addMember(database, 'm1');
      await addMember(database, 'm2');
      await closeAll();

      final reopened = await open();

      expect(await memberIds(reopened), ['m1', 'm2']);
      expect(keys.writes, 1);
    });

    test(
      'a wrong key does not open the file, and leaves it untouched',
      () async {
        final database = await open();
        await addMember(database, 'm1');
        await closeAll();
        final before = file.readAsBytesSync();

        await expectLater(
          opener(MemoryDatabaseKeyStore(DatabaseKeys.generate())).open(),
          failsWith(LocalDatabaseError.wrongKeyOrDamaged),
        );

        expect(file.readAsBytesSync(), before);
        expect(await memberIds(await open()), ['m1']);
      },
    );

    test('a damaged file is reported and left as it is', () async {
      await open();
      await closeAll();
      final damaged = file.readAsBytesSync()..fillRange(0, 64, 0);
      file.writeAsBytesSync(damaged);

      await expectLater(
        opener().open(),
        failsWith(LocalDatabaseError.wrongKeyOrDamaged),
      );
      expect(file.readAsBytesSync(), damaged);
    });
  });

  group('never replaces or deletes data', () {
    test(
      'a file whose key is missing is reported; no new key is made',
      () async {
        final database = await open();
        await addMember(database, 'm1');
        await closeAll();
        final before = file.readAsBytesSync();
        final emptyStore = MemoryDatabaseKeyStore();

        await expectLater(
          opener(emptyStore).open(),
          failsWith(LocalDatabaseError.keyMissing),
        );

        expect(emptyStore.writes, 0);
        expect(emptyStore.key, isNull);
        expect(file.readAsBytesSync(), before);
      },
    );

    test('a newer schema version is refused, untouched', () async {
      await open();
      await closeAll();
      final raw = sqlite3.open(file.path)
        ..execute("PRAGMA key = \"x'${keys.key}'\"")
        ..execute('PRAGMA user_version = 2');
      raw.close();
      final before = file.readAsBytesSync();

      await expectLater(
        opener().open(),
        failsWith(LocalDatabaseError.unsupportedSchema),
      );

      expect(file.readAsBytesSync(), before);
      final check = sqlite3.open(file.path)
        ..execute("PRAGMA key = \"x'${keys.key}'\"");
      addTearDown(check.close);
      expect(check.select('PRAGMA user_version').first.values.first, 2);
    });

    test('an invalid stored key is reported', () async {
      keys.key = 'not-a-key';

      await expectLater(
        opener().open(),
        failsWith(LocalDatabaseError.keyInvalid),
      );
      expect(file.existsSync(), isFalse);
    });

    test('unreadable secure storage: nothing is created', () async {
      keys.failRead = true;

      await expectLater(
        opener().open(),
        failsWith(LocalDatabaseError.keyStoreUnavailable),
      );
      expect(file.existsSync(), isFalse);
    });

    test('a key that cannot be stored: no database is created', () async {
      keys.failWrite = true;

      await expectLater(
        opener().open(),
        failsWith(LocalDatabaseError.keyStoreUnavailable),
      );
      expect(file.existsSync(), isFalse);
    });

    test('a location that cannot be found is reported', () async {
      final failing = LocalDatabaseOpener(
        keyStore: keys,
        locateFile: () async => throw const FileSystemException('no access'),
      );

      await expectLater(
        failing.open(),
        failsWith(LocalDatabaseError.openFailed),
      );
    });
  });

  group('errors never reveal the key', () {
    test('no message contains the key or the statement that set it', () async {
      await open();
      await closeAll();
      final wrongKey = DatabaseKeys.generate();

      for (final store in [
        MemoryDatabaseKeyStore(wrongKey),
        MemoryDatabaseKeyStore(),
        MemoryDatabaseKeyStore()..failRead = true,
      ]) {
        try {
          await opener(store).open();
          fail('should not open');
        } on LocalDatabaseException catch (e) {
          final message = e.toString();
          expect(message, isNot(contains(wrongKey)));
          expect(message, isNot(contains(keys.key!)));
          expect(message.toLowerCase(), isNot(contains('pragma')));
        }
      }
    });
  });
}
