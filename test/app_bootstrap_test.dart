import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/app.dart';
import 'package:mydr/app_bootstrap.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/data/local/database_key_store.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/local_database_exception.dart';
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/features/dashboard/widgets/emergency_card.dart';
import 'package:mydr/features/emergency/emergency_screen.dart';
import 'package:mydr/features/family/family_screen.dart';
import 'package:mydr/features/family/widgets/member_card.dart';
import 'package:mydr/features/shell/home_shell.dart';

import 'helpers/fake_emergency_dialer.dart';
import 'helpers/fake_first_aid_repository.dart';
import 'helpers/memory_key_store.dart';

/// Starting the app on the encrypted local database, and what happens when
/// it cannot be opened. Uses a temporary file and an in-memory key store,
/// never the app's real data.
void main() {
  late Directory directory;
  late File file;
  late MemoryDatabaseKeyStore keys;
  late FakeEmergencyDialer dialer;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('mydr_bootstrap');
    file = File('${directory.path}/${LocalDatabaseOpener.fileName}');
    keys = MemoryDatabaseKeyStore();
    dialer = FakeEmergencyDialer();
  });

  tearDown(() {
    try {
      directory.deleteSync(recursive: true);
    } catch (_) {
      // Windows may still hold the file for a moment; it is a temp folder.
    }
  });

  Future<LocalDatabase> openReal(
    WidgetTester tester, [
    DatabaseKeyStore? k,
  ]) async => (await tester.runAsync(
    () => LocalDatabaseOpener(
      keyStore: k ?? keys,
      locateFile: () async => file,
    ).open(),
  ))!;

  Widget bootstrap(Future<LocalDatabase> Function() open) => MyDrBootstrap(
    openDatabase: open,
    emergencyDialer: dialer,
    firstAidRepository: FakeFirstAidRepository(bundledHebrewContent()),
  );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  /// Unmounts the app, closing its database.
  Future<void> closeApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 50)),
    );
  }

  Future<void> openTab(WidgetTester tester, String label) async {
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(label),
      ),
    );
    await settle(tester);
  }

  testWidgets('first start: the encrypted database, empty, with no demo data '
      'and no "not saved" notice', (tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final database = await openReal(tester);
    await tester.pumpWidget(bootstrap(() async => database));
    await settle(tester);

    expect(find.byType(HomeShell), findsOneWidget);
    final scope = AppScope.of(tester.element(find.byType(HomeShell)));
    expect(scope.dependencies.persistsData, isTrue);
    expect(scope.familyController.members, isEmpty);
    expect(find.text(AppStrings.demoDataBanner), findsNothing);

    await openTab(tester, AppStrings.tabFamily);
    expect(find.byType(FamilyScreen), findsOneWidget);
    expect(find.byType(MemberCard), findsNothing);
    expect(find.text(AppStrings.demoDataBanner), findsNothing);
    await closeApp(tester);
  });

  testWidgets('what is saved is there after the app restarts', (tester) async {
    tester.view.physicalSize = const Size(400, 2000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final first = await openReal(tester);
    await tester.pumpWidget(bootstrap(() async => first));
    await settle(tester);
    final family = AppScope.of(
      tester.element(find.byType(HomeShell)),
    ).familyController;
    await tester.runAsync(
      () => family.add(
        FamilyMember(id: 'm1', name: 'נועה', relation: FamilyRelation.child),
      ),
    );
    await settle(tester);
    await closeApp(tester);

    // A new start, with the same file and key.
    final second = await openReal(tester);
    await tester.pumpWidget(bootstrap(() async => second));
    await settle(tester);
    await openTab(tester, AppStrings.tabFamily);

    expect(find.widgetWithText(MemberCard, 'נועה'), findsOneWidget);
    expect(keys.writes, 1);
    await closeApp(tester);
  });

  group('when the database cannot be opened', () {
    for (final error in LocalDatabaseError.values) {
      testWidgets('${error.name}: explains, says nothing was deleted, offers '
          'a retry', (tester) async {
        await tester.pumpWidget(
          bootstrap(() async => throw LocalDatabaseException(error)),
        );
        await settle(tester);

        expect(find.byType(HomeShell), findsNothing);
        expect(find.text(AppStrings.storageUnavailableTitle), findsOneWidget);
        expect(
          find.text(DatabaseStartupScreen.messageFor(error)),
          findsOneWidget,
        );
        expect(find.text(AppStrings.storageNothingDeleted), findsOneWidget);
        expect(find.text(AppStrings.retry), findsOneWidget);
      });
    }

    testWidgets('each problem has its own message', (tester) async {
      final messages = {
        for (final error in LocalDatabaseError.values)
          DatabaseStartupScreen.messageFor(error),
      };
      expect(messages, hasLength(LocalDatabaseError.values.length));
    });

    testWidgets('an unexpected error is reported too', (tester) async {
      await tester.pumpWidget(bootstrap(() async => throw StateError('x')));
      await settle(tester);

      expect(find.text(AppStrings.storageOpenFailed), findsOneWidget);
    });

    testWidgets('calling 101 and the emergency center still work', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 1600);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        bootstrap(
          () async =>
              throw const LocalDatabaseException(LocalDatabaseError.keyMissing),
        ),
      );
      await settle(tester);

      await tester.tap(
        find.bySemanticsLabel(
          AppStrings.callServiceLabel(AppStrings.serviceMedical, '101'),
        ),
      );
      await settle(tester);
      expect(dialer.dialed, ['101']);

      await tester.tap(find.text(AppStrings.openEmergencyCenter));
      await settle(tester);
      expect(find.byType(EmergencyScreen), findsOneWidget);
      await tester.tap(find.text(AppStrings.servicePolice));
      await settle(tester);
      expect(dialer.dialed, ['101', '100']);
      expect(find.text('חנק'), findsOneWidget);
    });

    testWidgets('while opening: a notice, and calling already works', (
      tester,
    ) async {
      final pending = Completer<LocalDatabase>();
      await tester.pumpWidget(bootstrap(() => pending.future));
      await tester.pump();

      expect(find.text(AppStrings.storageOpening), findsOneWidget);
      expect(find.text(AppStrings.retry), findsNothing);
      await tester.tap(
        find.bySemanticsLabel(
          AppStrings.callServiceLabel(AppStrings.serviceMedical, '101'),
        ),
      );
      await tester.pump();
      expect(dialer.dialed, ['101']);

      pending.completeError(
        const LocalDatabaseException(LocalDatabaseError.openFailed),
      );
      await settle(tester);
      expect(find.text(AppStrings.storageOpenFailed), findsOneWidget);
    });

    testWidgets('retrying opens the app once the problem is gone', (
      tester,
    ) async {
      var attempts = 0;
      final database = await openReal(tester);
      await tester.pumpWidget(
        bootstrap(() async {
          attempts++;
          if (attempts == 1) {
            throw const LocalDatabaseException(
              LocalDatabaseError.keyStoreUnavailable,
            );
          }
          return database;
        }),
      );
      await settle(tester);
      expect(find.byType(HomeShell), findsNothing);

      await tester.tap(find.text(AppStrings.retry));
      await settle(tester);

      expect(attempts, 2);
      expect(find.byType(HomeShell), findsOneWidget);
      expect(find.byType(EmergencyCard), findsOneWidget);
      await closeApp(tester);
    });

    testWidgets('a wrong key: the saved file is reported and left as it is', (
      tester,
    ) async {
      final original = await openReal(tester);
      await tester.runAsync(
        () => original.customStatement(
          'INSERT INTO family_members (id, name, relation) VALUES (?, ?, ?)',
          ['m1', 'בדיקה', 'child'],
        ),
      );
      await tester.runAsync(original.close);
      final before = file.readAsBytesSync();
      final otherKeys = MemoryDatabaseKeyStore(DatabaseKeys.generate());

      await tester.pumpWidget(
        bootstrap(
          () => LocalDatabaseOpener(
            keyStore: otherKeys,
            locateFile: () async => file,
          ).open(),
        ),
      );
      await settle(tester);

      expect(find.text(AppStrings.storageUnreadable), findsOneWidget);
      expect(file.readAsBytesSync(), before);
    });
  });

  group('demo mode', () {
    testWidgets('demo data is clearly marked as not saved', (tester) async {
      await tester.pumpWidget(
        MyDrApp(
          dependencies: AppDependencies.withMockData(
            DateTime.now(),
            emergencyDialer: dialer,
            firstAidRepository: FakeFirstAidRepository(bundledHebrewContent()),
          ),
        ),
      );
      await settle(tester);
      await openTab(tester, AppStrings.tabFamily);

      final scope = AppScope.of(tester.element(find.byType(HomeShell)));
      expect(scope.dependencies.persistsData, isFalse);
      expect(find.byType(DemoDataBanner), findsOneWidget);
      expect(find.text(AppStrings.demoDataBanner), findsOneWidget);
      expect(find.byType(MemberCard), findsNWidgets(5));
    });
  });
}
