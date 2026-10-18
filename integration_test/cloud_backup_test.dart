import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mydr/app.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/backup/recovery_key.dart';
import 'package:mydr/data/cloud/backup_storage.dart';
import 'package:mydr/data/cloud/firebase_cloud_backend.dart';
import 'package:mydr/data/cloud/recovery_key_store.dart';
import 'package:mydr/data/local/database_key_store.dart';
import 'package:mydr/data/local/local_database.dart' hide VisitMedia;
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:mydr/data/media/visit_media_file_store.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/models/visit_media.dart';
import 'package:mydr/features/backup/backup_screen.dart';
import 'package:mydr/features/backup/widgets/recovery_key_dialogs.dart';
import 'package:mydr/features/backup/widgets/restore_confirm_dialog.dart';
import 'package:mydr/features/dashboard/widgets/backup_card.dart';
import 'package:mydr/features/shell/home_shell.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../test/helpers/fake_media.dart';

/// Account sign-in, cloud backup and restore through the real app screens
/// and the real Firebase plugins, against the Firebase Local Emulator
/// Suite (a "demo-" project: no real cloud, no real data):
///
///     cd firebase && firebase emulators:start --project demo-mydr --only auth,storage
///     flutter test integration_test/cloud_backup_test.dart -d <emulator> \
///       --dart-define-from-file=config/firebase.emulator.json
///
/// Two "phones" are simulated with separate encrypted databases, keys and
/// media folders. Use a test emulator: the test run uninstalls the app.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final config = CloudConfig.fromEnvironment();
  final backend = config == null ? null : FirebaseCloudBackend(config);
  final run = Random().nextInt(1 << 30);
  final emailA = 'phone-a-$run@example.test';
  final emailB = 'other-$run@example.test';
  const password = 'test-password-123';
  final photo = fakeJpeg(40000);

  late Directory root;
  RecoveryKey? savedKey;
  String? uidA;

  setUpAll(() async {
    expect(
      config?.usesEmulator,
      isTrue,
      reason: 'run with the emulator config',
    );
    root = Directory(
      p.join((await getApplicationSupportDirectory()).path, 'cloud_test_$run'),
    )..createSync(recursive: true);
    // Firebase keeps the last session across runs; start signed out.
    await (await backend!.connect()).accounts.signOut();
  });

  tearDownAll(() async {
    if (root.existsSync()) root.deleteSync(recursive: true);
    const storage = FlutterSecureStorage(aOptions: AndroidOptions());
    for (final name in ['a', 'b']) {
      await storage.delete(key: 'mydr.cloud_test.$run.$name');
    }
  });

  Future<(LocalDatabase, AppDependencies)> openPhone(String name) async {
    final database = await LocalDatabaseOpener(
      keyStore: SecureDatabaseKeyStore(keyName: 'mydr.cloud_test.$run.$name'),
      locateFile: () async => File(p.join(root.path, '$name.sqlite')),
    ).open();
    final deps = AppDependencies.local(
      database,
      visitMediaFiles: PrivateVisitMediaFileStore(
        locateDirectory: () async =>
            Directory(p.join(root.path, '$name-media')),
      ),
      cloudBackend: backend,
      recoveryKeyStore: const SecureRecoveryKeyStore(),
    );
    return (database, deps);
  }

  /// Pumps until [finder] shows, with real time passing (network calls).
  Future<void> waitFor(
    WidgetTester tester,
    Finder finder, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    final end = DateTime.now().add(timeout);
    while (finder.evaluate().isEmpty) {
      if (DateTime.now().isAfter(end)) {
        // Explains the failure: what the screen and the controller show.
        final texts = [
          for (final t in find.byType(Text).evaluate())
            (t.widget as Text).data ?? '',
        ].where((t) => t.isNotEmpty).take(40).join(' | ');
        final scopes = find.byType(BackupScreen).evaluate();
        final state = scopes.isEmpty
            ? 'no backup screen'
            : () {
                final c = AppScope.of(scopes.first).backupController;
                return 'status=${c.status} activity=${c.activity} '
                    'progress=${c.progress} failure=${c.lastFailure} '
                    'key=${c.hasRecoveryKey} backups=${c.backups?.length}';
              }();
        fail('Timed out waiting for $finder | $state | Screen: $texts');
      }
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  Future<void> tapWhenVisible(WidgetTester tester, Finder finder) async {
    await waitFor(tester, finder);
    await tester.ensureVisible(finder.first);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(finder.first);
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> openBackup(WidgetTester tester) async {
    await waitFor(tester, find.byType(HomeShell));
    await tester.scrollUntilVisible(
      find.byType(BackupCard),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tapWhenVisible(tester, find.byType(BackupCard));
    await waitFor(tester, find.byType(BackupScreen));
  }

  Future<void> signIn(
    WidgetTester tester,
    String email, {
    bool create = false,
  }) async {
    await waitFor(tester, find.text(AppStrings.signInTitle));
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.emailLabel),
      email,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.passwordLabel),
      password,
    );
    await tapWhenVisible(
      tester,
      create
          ? find.text(AppStrings.createAccount)
          : find.widgetWithText(FilledButton, AppStrings.signIn),
    );
    await waitFor(tester, find.text(AppStrings.signedInAs(email)));
  }

  testWidgets('1. phone A: create an account, a recovery key, and a backup', (
    tester,
  ) async {
    final (database, deps) = await openPhone('a');
    // Fictional data, including a photo file.
    await deps.familyRepository.add(
      FamilyMember(id: 'm1', name: 'דנה בדיקה', relation: FamilyRelation.self),
    );
    await deps.appointmentRepository.add(
      Appointment(
        id: 'a1',
        memberId: 'm1',
        doctorName: 'רופאת בדיקה',
        dateTime: DateTime(2026, 11, 2, 9, 30),
      ),
    );
    final source = File(p.join(root.path, 'photo.jpg'))
      ..writeAsBytesSync(photo);
    final stored = await deps.visitMediaFiles.import(source.path);
    await deps.visitMediaRepository.add(
      VisitMedia(
        id: 'v1',
        memberId: 'm1',
        appointmentId: 'a1',
        kind: VisitMediaKind.photo,
        fileName: stored.fileName,
        byteSize: stored.byteSize,
        createdAt: DateTime(2026, 10, 17, 10),
      ),
    );
    await deps.medicationRepository.add(
      Medication(
        id: 'med1',
        memberId: 'm1',
        name: 'תרופת בדיקה',
        dose: '1',
        reminderTimes: [DoseTime(8, 0)],
        startDate: DateTime(2026, 10, 1),
      ),
    );

    await tester.pumpWidget(MyDrApp(dependencies: deps));
    await openBackup(tester);
    await signIn(tester, emailA, create: true);
    await waitFor(tester, find.text(AppStrings.recoveryKeyNeeded));

    await tapWhenVisible(
      tester,
      find.widgetWithText(FilledButton, AppStrings.createRecoveryKey),
    );
    await waitFor(tester, find.byType(RecoveryKeyText));
    final key = tester
        .widget<RecoveryKeyText>(find.byType(RecoveryKeyText))
        .recoveryKey;
    await tester.enterText(
      find.byType(TextField).last,
      key.format().split('-').last,
    );
    await tapWhenVisible(tester, find.text(AppStrings.recoveryKeySaved));
    // The first save goes through the Keystore; wait until it is done.
    await waitFor(tester, find.text(AppStrings.recoveryKeyStored));
    savedKey = key;

    final backUp = find.ancestor(
      of: find.text(AppStrings.backUpNow),
      matching: find.byWidgetPredicate(
        (w) => w is FilledButton && w.onPressed != null,
      ),
    );
    await tapWhenVisible(tester, backUp);
    await waitFor(tester, find.text(AppStrings.backupSucceeded));
    final scope = AppScope.of(tester.element(find.byType(BackupScreen)));
    uidA = scope.backupController.account!.uid;
    expect(scope.backupController.backups, hasLength(1));

    // Moving to another phone: sign out here.
    await tapWhenVisible(
      tester,
      find.widgetWithText(TextButton, AppStrings.signOut),
    );
    await tapWhenVisible(
      tester,
      find.widgetWithText(FilledButton, AppStrings.signOut),
    );
    await waitFor(tester, find.text(AppStrings.signInTitle));

    await tester.pumpWidget(const SizedBox());
    await database.close();
  });

  testWidgets("2. another account can neither list nor read A's backups", (
    tester,
  ) async {
    expect(uidA, isNotNull, reason: 'test 1 must have backed up');
    final services = await backend!.connect();
    await services.accounts.register(email: emailB, password: password);
    final root = 'users/$uidA/backups';

    Matcher refused() => throwsA(
      isA<BackupStorageException>().having(
        (e) => e.error,
        'error',
        BackupStorageError.unauthorized,
      ),
    );
    await expectLater(services.storage.listFolders(root), refused());
    await expectLater(
      services.storage.downloadBytes('$root/any/manifest.bin', maxBytes: 1024),
      throwsA(isA<BackupStorageException>()),
    );
    await expectLater(
      services.storage.uploadBytes('$root/evil/manifest.bin', Uint8List(4)),
      refused(),
    );
    await services.accounts.signOut();
  });

  testWidgets('3. phone B: sign in, a wrong key fails, the right key '
      'restores after confirmation', (tester) async {
    final (database, deps) = await openPhone('b');
    await deps.familyRepository.add(
      FamilyMember(id: 'x', name: 'מידע קודם', relation: FamilyRelation.other),
    );

    await tester.pumpWidget(MyDrApp(dependencies: deps));
    await openBackup(tester);
    await signIn(tester, emailA);
    await waitFor(tester, find.text(AppStrings.recoveryKeyNeededWithBackups));

    final restore = find.widgetWithText(TextButton, AppStrings.restore);
    await waitFor(tester, restore);
    await tester.scrollUntilVisible(
      restore,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tapWhenVisible(tester, restore);

    // A wrong key is refused, and nothing changes.
    await waitFor(tester, find.text(AppStrings.recoveryKeyFieldLabel));
    await tester.enterText(
      find.byType(TextField),
      RecoveryKey.generate().format(),
    );
    await tapWhenVisible(tester, find.text(AppStrings.continueLabel));
    await waitFor(tester, find.text(AppStrings.backupFailedWrongKey));
    expect((await deps.familyRepository.getAll()).single.name, 'מידע קודם');

    await tester.enterText(find.byType(TextField), savedKey!.format());
    await tapWhenVisible(tester, find.text(AppStrings.continueLabel));
    await waitFor(tester, find.byType(RestoreConfirmDialog));
    // Still nothing changed before confirming.
    expect((await deps.familyRepository.getAll()).single.id, 'x');

    await tapWhenVisible(tester, find.byType(Checkbox));
    await tapWhenVisible(
      tester,
      find.widgetWithText(FilledButton, AppStrings.restoreConfirm),
    );
    await waitFor(tester, find.text(AppStrings.restoreSucceeded));

    final members = await deps.familyRepository.getAll();
    expect(members.single.name, 'דנה בדיקה');
    expect(
      (await deps.medicationRepository.getAll()).single.name,
      'תרופת בדיקה',
    );
    final media = (await deps.visitMediaRepository.getAll()).single;
    expect(await deps.visitMediaFiles.readBytes(media.fileName), photo);

    // Cleanup: this run's backups, from the account that owns them.
    final services = await backend!.connect();
    final folder = 'users/$uidA/backups';
    for (final id in await services.storage.listFolders(folder)) {
      for (final name in await services.storage.listObjects(
        '$folder/$id/media',
      )) {
        await services.storage.delete('$folder/$id/media/$name');
      }
      for (final name in await services.storage.listObjects('$folder/$id')) {
        await services.storage.delete('$folder/$id/$name');
      }
    }
    await const SecureRecoveryKeyStore().delete(uidA!);
    await services.accounts.signOut();

    await tester.pumpWidget(const SizedBox());
    await database.close();
  });
}
