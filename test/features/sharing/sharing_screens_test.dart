import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/cloud/recovery_key_store.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/data/models/sync_state.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_appointment_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_doctor_question_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_family_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_symptom_repository.dart';
import 'package:mydr/features/backup/backup_controller.dart';
import 'package:mydr/features/dashboard/widgets/sharing_card.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/sharing/conflicts_screen.dart';
import 'package:mydr/features/sharing/family_sharing_screen.dart';

import '../../helpers/fake_cloud.dart';
import '../../helpers/fake_household_cloud.dart';
import '../../helpers/fake_media.dart';
import '../../helpers/pump_app.dart';

void main() {
  final child = FamilyMember(
    id: 'child-1',
    name: 'ילד בדוי',
    relation: FamilyRelation.child,
  );
  final self = FamilyMember(
    id: 'self-1',
    name: 'הורה בדוי',
    relation: FamilyRelation.self,
  );
  final symptom = SymptomEntry(
    id: 's1',
    memberId: 'child-1',
    name: 'שיעול',
    startedAt: DateTime(2026, 10, 1, 9),
    severity: 2,
  );

  late Directory temp;
  late FakeCloudBackend cloud;

  setUp(() {
    temp = Directory.systemTemp.createTempSync('mydr_sharing_screen');
    cloud = FakeCloudBackend();
    cloud.storage.currentUid = () => cloud.accounts.current?.uid;
  });
  tearDown(() => temp.deleteSync(recursive: true));

  AppDependencies deps({bool withCloud = true}) {
    final backend = FakeCloudBackend(
      accounts: cloud.accounts,
      storage: cloud.storage,
      household: FakeHouseholdCloud(
        FakeHouseholdServer(),
        uid: () => cloud.accounts.current?.uid,
      ),
    );
    return AppDependencies(
      familyRepository: InMemoryFamilyRepository([self, child]),
      appointmentRepository: InMemoryAppointmentRepository(),
      doctorQuestionRepository: InMemoryDoctorQuestionRepository(),
      symptomRepository: InMemorySymptomRepository([symptom]),
      visitMediaFiles: FakeVisitMediaFileStore(),
      cloudBackend: withCloud ? backend : null,
      recoveryKeyStore: InMemoryRecoveryKeyStore(),
      syncKeyStore: InMemorySyncKeyStore(),
      syncWorkDirectory: () async => Directory('${temp.path}/sync'),
      persistsData: true,
    );
  }

  testWidgets('the home card is hidden without a cloud configuration', (
    tester,
  ) async {
    await tester.pumpApp(
      const Scaffold(body: SharingCard()),
      dependencies: deps(withCloud: false),
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.sharingTitle), findsNothing);
  });

  testWidgets('create a household and share a child, with confirmation', (
    tester,
  ) async {
    final d = deps();
    final family = FamilyController(d);
    addTearDown(family.dispose);
    final backup = BackupController(dependencies: d, familyController: family);
    addTearDown(backup.dispose);
    await tester.runAsync(() async {
      await family.load();
      await backup.start();
      await backup.register('parent@example.test', 'password123');
    });

    await tester.pumpApp(
      const Scaffold(body: SharingCard()),
      dependencies: d,
      familyController: family,
      backupController: backup,
    );
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.sharingTitle), findsOneWidget);
    await tester.tap(find.text(AppStrings.sharingTitle));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.householdCreate), findsOneWidget);
    expect(find.text(AppStrings.householdJoin), findsOneWidget);
    expect(find.text(AppStrings.sharingManualOnly), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text(AppStrings.householdCreate));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.syncNow), findsOneWidget);
    expect(find.text(AppStrings.sharedChildrenTitle), findsOneWidget);
    // Only the child can be shared; the parent's own profile is not listed.
    expect(find.byKey(const ValueKey('share-child-1')), findsOneWidget);
    expect(find.byKey(const ValueKey('share-self-1')), findsNothing);

    tester
        .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger))
        .removeCurrentSnackBar();
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('share-child-1')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('share-child-1')));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.shareConfirmTitle), findsOneWidget);
    await tester.runAsync(() async {
      await tester.tap(find.text(AppStrings.shareConfirm));
      await Future<void>.delayed(const Duration(milliseconds: 300));
    });
    await tester.pumpAndSettle();
    expect(
      await tester.runAsync(() => d.syncStateRepository.sharedMemberIds()),
      {'child-1'},
    );
  });

  testWidgets('a conflict shows both versions and keeps the chosen one', (
    tester,
  ) async {
    final d = deps();
    await tester.runAsync(() async {
      await d.syncStateRepository.saveConflict(
        SyncConflict(
          kind: SyncKind.symptom,
          syncId: 's1',
          localId: 's1',
          memberId: 'child-1',
          reason: ConflictReason.edited,
          local: {'severity': 2},
          remote: {'severity': 4},
          remoteVector: VersionVector({'other': 1}),
          remoteUpdatedAt: DateTime(2026, 10, 19),
          remoteUpdatedBy: 'other',
          fields: const ['severity'],
          detectedAt: DateTime(2026, 10, 19),
        ),
      );
    });
    final family = FamilyController(d);
    addTearDown(family.dispose);
    await tester.runAsync(family.load);

    await tester.pumpApp(
      const ConflictsScreen(),
      dependencies: d,
      familyController: family,
    );
    final scope = tester.element(find.byType(ConflictsScreen));
    await tester.runAsync(() => AppScope.of(scope).syncController.loadLocal());
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.conflictEdited), findsOneWidget);
    expect(
      find.textContaining('${AppStrings.conflictThisDevice}: 2'),
      findsOneWidget,
    );
    expect(
      find.textContaining('${AppStrings.conflictOtherDevice}: 4'),
      findsOneWidget,
    );
    expect(find.textContaining(child.name), findsOneWidget);

    await tester.runAsync(() async {
      await tester.tap(find.text(AppStrings.conflictKeepMine));
      await Future<void>.delayed(const Duration(milliseconds: 200));
    });
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.noConflicts), findsOneWidget);
    expect(
      await tester.runAsync(() => d.syncStateRepository.pendingChanges()),
      hasLength(1),
    );
  });

  testWidgets('the sharing screen asks to sign in first', (tester) async {
    await tester.pumpApp(const FamilySharingScreen(), dependencies: deps());
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pumpAndSettle();
    expect(find.text(AppStrings.sharingSignInFirst), findsOneWidget);
  });
}
