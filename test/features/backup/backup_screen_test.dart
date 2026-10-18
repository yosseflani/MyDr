import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/backup/recovery_key.dart';
import 'package:mydr/data/cloud/recovery_key_store.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_family_repository.dart';
import 'package:mydr/features/backup/backup_controller.dart';
import 'package:mydr/features/backup/backup_screen.dart';
import 'package:mydr/features/backup/widgets/recovery_key_dialogs.dart';
import 'package:mydr/features/backup/widgets/restore_confirm_dialog.dart';
import 'package:mydr/features/dashboard/widgets/backup_card.dart';
import 'package:mydr/features/family/family_controller.dart';

import '../../helpers/fake_cloud.dart';
import '../../helpers/fake_media.dart';
import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  const email = 'dana@example.test';
  const password = 'password123';
  final dana = FamilyMember(
    id: 'm1',
    name: 'דנה',
    relation: FamilyRelation.self,
  );

  late Directory temp;
  late FakeCloudBackend cloud;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('mydr_backup_screen');
    cloud = FakeCloudBackend();
  });
  tearDown(() => temp.deleteSync(recursive: true));

  ({AppDependencies deps, FamilyController family, BackupController backup})
  phone(
    String name, {
    List<FamilyMember> members = const [],
    bool persists = true,
  }) {
    final deps = AppDependencies(
      familyRepository: InMemoryFamilyRepository(members),
      appointmentRepository: FlakyAppointmentRepository(),
      doctorQuestionRepository: FlakyDoctorQuestionRepository(),
      symptomRepository: FlakySymptomRepository(),
      visitMediaFiles: FakeVisitMediaFileStore(),
      cloudBackend: cloud,
      recoveryKeyStore: InMemoryRecoveryKeyStore(),
      backupWorkDirectory: () async => Directory('${temp.path}/$name'),
      persistsData: persists,
    );
    final family = FamilyController(deps);
    final backup = BackupController(
      dependencies: deps,
      familyController: family,
    );
    addTearDown(backup.dispose);
    addTearDown(family.dispose);
    return (deps: deps, family: family, backup: backup);
  }

  Future<void> pumpScreen(
    WidgetTester tester,
    ({AppDependencies deps, FamilyController family, BackupController backup})
    p,
  ) async {
    await tester.pumpApp(
      const BackupScreen(),
      dependencies: p.deps,
      familyController: p.family,
      backupController: p.backup,
    );
    await tester.runAsync(() => p.family.load());
    await tester.pumpAndSettle();
  }

  /// Runs real file work (encryption, temp files) outside the fake clock.
  Future<void> tapAndWait(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    for (var i = 0; i < 20; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('a build without cloud configuration says so', (tester) async {
    await tester.pumpApp(const BackupScreen());
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.backupNotConfiguredTitle), findsOneWidget);
    expect(find.text(AppStrings.backupPrivacy), findsOneWidget);
  });

  testWidgets('when the cloud cannot be reached, offers to retry', (
    tester,
  ) async {
    cloud.failConnect = true;
    await pumpScreen(tester, phone('a'));
    expect(find.text(AppStrings.cloudConnectFailed), findsOneWidget);

    cloud.failConnect = false;
    await tester.tap(find.text(AppStrings.retry));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.signInTitle), findsOneWidget);
  });

  testWidgets('sign-in form checks its fields and shows account errors', (
    tester,
  ) async {
    await pumpScreen(tester, phone('a'));

    await tester.tap(find.widgetWithText(FilledButton, AppStrings.signIn));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.emailRequired), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.emailLabel),
      email,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.passwordLabel),
      'short',
    );
    await tester.tap(find.text(AppStrings.createAccount));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.passwordTooShort), findsOneWidget);

    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.passwordLabel),
      password,
    );
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.signIn));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.accountWrongCredentials), findsOneWidget);
  });

  testWidgets('create an account, save a recovery key, and back up', (
    tester,
  ) async {
    final a = phone('a', members: [dana]);
    await pumpScreen(tester, a);

    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.emailLabel),
      email,
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.passwordLabel),
      password,
    );
    await tester.tap(find.text(AppStrings.createAccount));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.signedInAs(email)), findsOneWidget);
    expect(find.text(AppStrings.recoveryKeyNeeded), findsOneWidget);
    // Backing up needs the key first.
    // FilledButton.icon builds a subclass, so match by type test.
    final backUpButton = find.ancestor(
      of: find.text(AppStrings.backUpNow),
      matching: find.byWidgetPredicate((w) => w is FilledButton),
    );
    expect(tester.widget<FilledButton>(backUpButton).onPressed, isNull);

    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.createRecoveryKey),
    );
    await tester.pumpAndSettle();
    final shown = tester.widget<RecoveryKeyText>(find.byType(RecoveryKeyText));
    final lastGroup = shown.recoveryKey.format().split('-').last;

    await tester.enterText(find.byType(TextField).last, 'ZZZZ');
    await tester.tap(find.text(AppStrings.recoveryKeySaved));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.confirmLastGroupMismatch), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).last,
      lastGroup.toLowerCase(),
    );
    await tester.tap(find.text(AppStrings.recoveryKeySaved));
    await tester.pumpAndSettle();
    expect(a.backup.hasRecoveryKey, isTrue);

    await tapAndWait(tester, backUpButton);
    expect(find.text(AppStrings.backupSucceeded), findsOneWidget);
    expect(a.backup.backups, hasLength(1));
    expect(find.textContaining('הגיבוי האחרון'), findsOneWidget);
  });

  testWidgets('restoring on a new phone asks for the key and an explicit '
      'confirmation', (tester) async {
    // Phone A backs up.
    final a = phone('a', members: [dana]);
    late RecoveryKey key;
    await tester.runAsync(() async {
      await a.backup.start();
      await a.backup.register(email, password);
      key = a.backup.createRecoveryKey();
      await a.backup.saveNewRecoveryKey(key);
      await a.backup.backUpNow();
      await a.backup.signOut();
    });

    // Phone B has other data.
    final other = FamilyMember(
      id: 'x',
      name: 'אחר',
      relation: FamilyRelation.other,
    );
    final b = phone('b', members: [other]);
    await tester.runAsync(() async {
      await b.backup.start();
      await b.backup.signIn(email, password);
    });
    await pumpScreen(tester, b);
    expect(find.text(AppStrings.recoveryKeyNeededWithBackups), findsOneWidget);

    final restoreButton = find.widgetWithText(TextButton, AppStrings.restore);
    await tester.scrollUntilVisible(
      restoreButton,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(restoreButton);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), key.format());
    await tapAndWait(tester, find.text(AppStrings.continueLabel));

    expect(find.byType(RestoreConfirmDialog), findsOneWidget);
    expect(find.text(AppStrings.restoreReplacesWarning), findsOneWidget);
    // Nothing changed yet, and the button waits for the checkbox.
    expect(b.family.members.single.id, 'x');
    final confirm = find.widgetWithText(
      FilledButton,
      AppStrings.restoreConfirm,
    );
    expect(tester.widget<FilledButton>(confirm).onPressed, isNull);

    await tester.ensureVisible(find.byType(Checkbox));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    expect(tester.widget<FilledButton>(confirm).onPressed, isNotNull);
    await tapAndWait(tester, confirm);

    expect(find.text(AppStrings.restoreSucceeded), findsOneWidget);
    expect(b.family.members, [dana]);
    expect(b.backup.hasRecoveryKey, isTrue);
  });

  testWidgets('cancelling the confirmation changes nothing', (tester) async {
    final a = phone('a', members: [dana]);
    await tester.runAsync(() async {
      await a.backup.start();
      await a.backup.register(email, password);
      await a.backup.saveNewRecoveryKey(a.backup.createRecoveryKey());
      await a.backup.backUpNow();
    });
    await pumpScreen(tester, a);

    await tapAndWait(
      tester,
      find.widgetWithText(TextButton, AppStrings.restore),
    );
    expect(find.byType(RestoreConfirmDialog), findsOneWidget);
    await tester.tap(find.text(AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(RestoreConfirmDialog), findsNothing);
    expect(a.family.members, [dana]);
  });

  testWidgets('demo mode explains that nothing is backed up', (tester) async {
    final a = phone('a', persists: false);
    await tester.runAsync(() async {
      await a.backup.start();
      await a.backup.register(email, password);
    });
    await pumpScreen(tester, a);
    expect(find.text(AppStrings.backupDemoMode), findsOneWidget);
  });

  testWidgets('the home card opens the screen', (tester) async {
    await tester.pumpApp(const Scaffold(body: BackupCard()));
    await tester.tap(find.byType(BackupCard));
    await tester.pumpAndSettle();
    expect(find.byType(BackupScreen), findsOneWidget);
  });

  testWidgets('lays out without overflow on a narrow screen with large text', (
    tester,
  ) async {
    final a = phone('a', members: [dana]);
    await tester.runAsync(() async {
      await a.backup.start();
      await a.backup.register(email, password);
    });
    tester.setScreenSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    await pumpScreen(tester, a);
    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
  });
}
