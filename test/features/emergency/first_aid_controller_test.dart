import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/app.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/first_aid/first_aid_content_parser.dart';
import 'package:mydr/data/models/first_aid_content.dart';
import 'package:mydr/data/repositories/first_aid_repository.dart';
import 'package:mydr/features/dashboard/widgets/emergency_card.dart';
import 'package:mydr/features/emergency/emergency_screen.dart';
import 'package:mydr/features/emergency/first_aid_controller.dart';

import '../../helpers/fake_emergency_dialer.dart';
import '../../helpers/fake_first_aid_repository.dart';
import '../../helpers/pump_app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  FirstAidContentPack packWith(List<String> ids) => FirstAidContentPack(
    schemaVersion: 2,
    contentVersion: 1,
    locale: 'he',
    publishedAt: DateTime.utc(2026, 10, 15),
    topics: [
      for (final id in ids)
        FirstAidTopic(
          id: id,
          kind: FirstAidTopicKind.emergency,
          title: 'נושא $id',
          summary: 'תיאור בדיקה',
          status: ContentStatus.pending,
        ),
    ],
  );

  group('AssetFirstAidRepository', () {
    test('loads the bundled Hebrew content', () async {
      final pack = await const AssetFirstAidRepository().load();

      expect(pack.topics, hasLength(7));
      expect(pack.topics.every((t) => !t.isVerified), isTrue);
      expect(pack.topics.every((t) => !t.isDraft), isTrue);
    });

    test('the review repository loads the bundled drafts, never as '
        'verified', () async {
      final pack = await const AssetFirstAidRepository.review().load();

      expect(pack.topics, hasLength(7));
      expect(pack.topics.every((t) => t.isDraft), isTrue);
      expect(pack.topics.every((t) => !t.isVerified), isTrue);
    });

    test('the regular repository refuses the draft file', () async {
      const repository = AssetFirstAidRepository(
        assetPath: AssetFirstAidRepository.hebrewDraftPath,
      );

      await expectLater(
        repository.load(),
        throwsA(
          isA<FirstAidContentException>().having(
            (e) => e.error,
            'error',
            FirstAidContentError.wrongContentMode,
          ),
        ),
      );
    });

    test('a missing draft file is reported as unavailable', () async {
      final repository = AssetFirstAidRepository.review(
        bundle: FakeAssetBundle(null),
      );

      await expectLater(
        repository.load(),
        throwsA(
          isA<FirstAidContentException>().having(
            (e) => e.error,
            'error',
            FirstAidContentError.unavailable,
          ),
        ),
      );
    });

    test('a missing file is reported as unavailable', () async {
      final repository = AssetFirstAidRepository(bundle: FakeAssetBundle(null));

      await expectLater(
        repository.load(),
        throwsA(
          isA<FirstAidContentException>().having(
            (e) => e.error,
            'error',
            FirstAidContentError.unavailable,
          ),
        ),
      );
    });

    test('a broken file is reported as such', () async {
      final repository = AssetFirstAidRepository(bundle: FakeAssetBundle('{'));

      await expectLater(
        repository.load(),
        throwsA(
          isA<FirstAidContentException>().having(
            (e) => e.error,
            'error',
            FirstAidContentError.malformed,
          ),
        ),
      );
    });
  });

  group('FirstAidController', () {
    late FakeFirstAidRepository repository;
    late FirstAidController controller;

    setUp(() {
      repository = FakeFirstAidRepository()..pack = packWith(['a', 'b']);
      controller = FirstAidController(repository);
      addTearDown(controller.dispose);
    });

    test('starts empty, then loads the topics', () async {
      expect(controller.topics, isEmpty);
      expect(controller.pack, isNull);

      final states = <bool>[];
      controller.addListener(() => states.add(controller.isLoading));
      await controller.load();

      expect(states, [true, false]);
      expect([for (final t in controller.topics) t.id], ['a', 'b']);
      expect(controller.topicById('b')?.title, 'נושא b');
      expect(controller.topicById('missing'), isNull);
      expect(controller.hasLoadError, isFalse);
    });

    test('reports why a load failed', () async {
      repository.error = const FirstAidContentException(
        FirstAidContentError.unsupportedSchema,
        'schemaVersion 3',
      );
      await controller.load();

      expect(controller.loadError, FirstAidContentError.unsupportedSchema);
      expect(controller.topics, isEmpty);
      expect(controller.isLoading, isFalse);
    });

    test('an unexpected error counts as unavailable', () async {
      repository.error = StateError('boom');
      await controller.load();

      expect(controller.loadError, FirstAidContentError.unavailable);
    });

    test(
      'a failed reload keeps the content, and a retry clears the error',
      () async {
        await controller.load();
        repository.error = const FirstAidContentException(
          FirstAidContentError.malformed,
          'x',
        );
        await controller.load();

        expect(controller.hasLoadError, isTrue);
        expect(controller.topics, hasLength(2));

        repository
          ..error = null
          ..pack = packWith(['c']);
        await controller.load();

        expect(controller.hasLoadError, isFalse);
        expect([for (final t in controller.topics) t.id], ['c']);
      },
    );

    test('when loads overlap, only the latest result is applied', () async {
      final gate = Completer<void>();
      repository.gate = gate;
      final first = controller.load();
      repository
        ..gate = null
        ..pack = packWith(['new']);
      await controller.load();

      repository.pack = packWith(['old']);
      gate.complete();
      await first;

      expect([for (final t in controller.topics) t.id], ['new']);
      expect(controller.isLoading, isFalse);
    });

    test('finishing after dispose does not throw', () async {
      final gate = Completer<void>();
      repository.gate = gate;
      final other = FirstAidController(repository);
      final load = other.load();
      other.dispose();
      gate.complete();
      await load;
    });
  });

  group('independent from emergency calling', () {
    testWidgets('the call buttons work while the content failed to load', (
      tester,
    ) async {
      final dialer = FakeEmergencyDialer();
      final repository = FakeFirstAidRepository()
        ..error = const FirstAidContentException(
          FirstAidContentError.malformed,
          'x',
        );
      final controller = FirstAidController(repository);
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.hasLoadError, isTrue);

      tester.setScreenSize(const Size(400, 1600));
      await tester.pumpApp(
        const EmergencyScreen(),
        dependencies: AppDependencies.empty(
          emergencyDialer: dialer,
          firstAidRepository: repository,
        ),
        firstAidController: controller,
      );
      await tester.tap(
        find.bySemanticsLabel(
          AppStrings.callServiceLabel(AppStrings.serviceMedical, '101'),
        ),
      );
      await tester.pumpAndSettle();

      expect(dialer.dialed, ['101']);
    });

    testWidgets('the call buttons work while the content is still loading', (
      tester,
    ) async {
      final dialer = FakeEmergencyDialer();
      final repository = FakeFirstAidRepository()
        ..pack = packWith(['a'])
        ..gate = Completer<void>();
      final controller = FirstAidController(repository);
      addTearDown(controller.dispose);
      unawaited(controller.load());
      expect(controller.isLoading, isTrue);

      tester.setScreenSize(const Size(400, 1600));
      await tester.pumpApp(
        const EmergencyScreen(),
        dependencies: AppDependencies.empty(emergencyDialer: dialer),
        firstAidController: controller,
      );
      await tester.tap(
        find.bySemanticsLabel(
          AppStrings.callServiceLabel(AppStrings.servicePolice, '100'),
        ),
      );
      await tester.pumpAndSettle();

      expect(dialer.dialed, ['100']);
      repository.gate!.complete();
    });

    test('a broken dialer does not affect loading the content', () async {
      final dialer = FakeEmergencyDialer()..throws = true;
      expect(dialer.openDialer('101'), throwsStateError);

      final controller = FirstAidController(const AssetFirstAidRepository());
      addTearDown(controller.dispose);
      await controller.load();
      expect(controller.topics, hasLength(7));
    });

    testWidgets('the app starts, loads the content once, and can dial even '
        'when the content fails', (tester) async {
      final dialer = FakeEmergencyDialer();
      final repository = FakeFirstAidRepository()
        ..error = const FirstAidContentException(
          FirstAidContentError.unavailable,
          'x',
        );
      tester.setScreenSize(const Size(400, 2000));
      await tester.pumpWidget(
        MyDrApp(
          dependencies: AppDependencies.withMockData(
            DateTime.now(),
            emergencyDialer: dialer,
            firstAidRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scope = AppScope.of(tester.element(find.byType(EmergencyCard)));
      expect(repository.loads, 1);
      expect(scope.firstAidController.hasLoadError, isTrue);

      await tester.tap(
        find.descendant(
          of: find.byType(EmergencyCard),
          matching: find.text(AppStrings.callMedicalEmergency),
        ),
      );
      await tester.pumpAndSettle();
      expect(dialer.dialed, ['101']);
    });

    testWidgets('the app exposes the loaded content through AppScope', (
      tester,
    ) async {
      final repository = FakeFirstAidRepository()..pack = packWith(['a', 'b']);
      await tester.pumpWidget(
        MyDrApp(
          dependencies: AppDependencies.withMockData(
            DateTime.now(),
            emergencyDialer: FakeEmergencyDialer(),
            firstAidRepository: repository,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scope = AppScope.of(tester.element(find.byType(EmergencyCard)));
      expect(
        [for (final t in scope.firstAidController.topics) t.id],
        ['a', 'b'],
      );
    });
  });
}
