import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mydr/data/local/database_key_store.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/local_database_exception.dart';
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3/sqlite3.dart';

import '../test/helpers/memory_key_store.dart';

/// Runs on a real device or emulator: the platform's SQLCipher library and
/// the operating system's secure storage (Android Keystore).
///
///   `flutter test integration_test/encrypted_database_test.dart -d DEVICE`
///
/// Uses its own file and key name, and removes both afterwards, so the
/// app's real database (if any) is never touched.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const keyName = 'mydr.database_key.integration_test';
  const storage = FlutterSecureStorage(aOptions: AndroidOptions());
  late File file;

  LocalDatabaseOpener opener([DatabaseKeyStore? keys]) => LocalDatabaseOpener(
    keyStore: keys ?? const SecureDatabaseKeyStore(keyName: keyName),
    locateFile: () async => file,
  );

  setUpAll(() async {
    final directory = await getApplicationSupportDirectory();
    file = File(p.join(directory.path, 'integration_test.sqlite'));
    if (file.existsSync()) file.deleteSync();
    await storage.delete(key: keyName);
  });

  tearDownAll(() async {
    if (file.existsSync()) file.deleteSync();
    await storage.delete(key: keyName);
  });

  testWidgets('creates an encrypted database with a key in the Keystore', (
    tester,
  ) async {
    final database = await opener().open();
    final cipher = await database
        .customSelect('PRAGMA cipher_version')
        .getSingle();
    // ignore: avoid_print
    print('SQLCipher on device: ${cipher.data.values.first}');
    expect('${cipher.data.values.first}', isNotEmpty);

    await database.customStatement(
      'INSERT INTO family_members (id, name, relation) VALUES (?, ?, ?)',
      ['m1', 'בדיקה', 'child'],
    );
    await database.close();

    final storedKey = await storage.read(key: keyName);
    expect(storedKey, isNotNull);
    expect(DatabaseKeys.isValid(storedKey!), isTrue);
  });

  testWidgets('data survives closing and opening again', (tester) async {
    final database = await opener().open();
    final rows = await database
        .customSelect('SELECT id FROM family_members')
        .get();
    await database.close();

    expect([for (final row in rows) row.read<String>('id')], ['m1']);
  });

  testWidgets('the file cannot be read as a plain SQLite database', (
    tester,
  ) async {
    final header = String.fromCharCodes(file.readAsBytesSync().sublist(0, 16));
    expect(header, isNot('SQLite format 3\u0000'));

    final plain = sqlite3.open(file.path);
    try {
      expect(
        () => plain.select('SELECT count(*) FROM sqlite_master'),
        throwsA(isA<SqliteException>()),
      );
    } finally {
      plain.close();
    }
  });

  testWidgets('a wrong key does not open it, and leaves it untouched', (
    tester,
  ) async {
    final before = file.readAsBytesSync();

    await expectLater(
      opener(MemoryDatabaseKeyStore(DatabaseKeys.generate())).open(),
      throwsA(
        isA<LocalDatabaseException>().having(
          (e) => e.error,
          'error',
          LocalDatabaseError.wrongKeyOrDamaged,
        ),
      ),
    );
    expect(file.readAsBytesSync(), before);

    // The right key still works afterwards.
    final LocalDatabase database = await opener().open();
    await database.close();
  });
}
