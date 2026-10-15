import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/load_error_views.dart';
import 'package:mydr/data/first_aid/first_aid_content_parser.dart';
import 'package:mydr/data/models/first_aid_content.dart';
import 'package:mydr/data/repositories/first_aid_repository.dart';
import 'package:mydr/features/emergency/emergency_screen.dart';
import 'package:mydr/features/emergency/first_aid_controller.dart';
import 'package:mydr/features/emergency/first_aid_review_screen.dart';
import 'package:mydr/features/emergency/first_aid_topic_screen.dart';
import 'package:mydr/features/emergency/widgets/first_aid_topic_tile.dart';

import '../../helpers/fake_emergency_dialer.dart';
import '../../helpers/fake_first_aid_repository.dart';
import '../../helpers/pump_app.dart';

/// The developer review preview. Draft content here is synthetic
/// placeholder text, except where a test reads the bundled draft file.
void main() {
  final today = DateTime(2026, 10, 15);

  String draftJson() => jsonEncode({
    'schemaVersion': 2,
    'contentVersion': 1,
    'locale': 'he',
    'publishedAt': '2026-10-15',
    'sources': [
      {
        'id': 's1',
        'publisher': 'מקור בדיקה',
        'title': 'מסמך בדיקה',
        'url': 'https://example.org/test',
        'published': '2025-10',
        'accessedOn': '2026-10-01',
      },
    ],
    'topics': [
      {
        'id': 'draft',
        'kind': 'emergency',
        'status': 'draft',
        'title': 'נושא טיוטה',
        'summary': 'תיאור טיוטה',
        'callNow': ['הפניית טיוטה'],
        'variants': [
          {
            'id': 'v',
            'label': 'מצב טיוטה',
            'steps': [
              {'order': 1, 'text': 'שלב טיוטה'},
            ],
          },
        ],
        'sourceIds': ['s1'],
        'reviewNotes': ['שאלת טיוטה לסוקר'],
      },
    ],
  });

  FirstAidRepository draftRepository([String? content]) =>
      AssetFirstAidRepository.review(
        bundle: FakeAssetBundle(content ?? draftJson()),
        clock: () => today,
      );

  late FakeEmergencyDialer dialer;

  Future<void> pump(WidgetTester tester, Widget screen) async {
    tester.setScreenSize(const Size(400, 2400));
    dialer = FakeEmergencyDialer();
    final controller = FirstAidController(
      FakeFirstAidRepository(bundledHebrewContent()),
    );
    addTearDown(controller.dispose);
    await controller.load();
    await tester.pumpApp(
      screen,
      dependencies: AppDependencies.empty(emergencyDialer: dialer),
      firstAidController: controller,
    );
  }

  Finder callBar() => find.bySemanticsLabel(
    AppStrings.callServiceLabel(AppStrings.serviceMedical, '101'),
  );

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('access', () {
    test('the preview is off unless asked for, in a debug build', () {
      // Tests run without MYDR_FIRST_AID_REVIEW; a release build compiles
      // the flag to false whatever it is run with.
      expect(FirstAidReview.enabled, isFalse);
    });

    testWidgets('the emergency center does not link to it by default', (
      tester,
    ) async {
      await pump(tester, const EmergencyScreen());

      expect(find.text(AppStrings.firstAidReviewEntryTitle), findsNothing);
      expect(find.text(AppStrings.contentStatusDraft), findsNothing);
      expect(find.text(AppStrings.firstAidDraftBanner), findsNothing);
    });

    testWidgets('the regular library shows no draft content, even with the '
        'review link on', (tester) async {
      await pump(tester, const EmergencyScreen(showReviewEntry: true));

      expect(find.text(AppStrings.firstAidReviewEntryTitle), findsOneWidget);
      expect(find.text(AppStrings.contentStatusSourced), findsNWidgets(7));
      expect(find.text(AppStrings.firstAidReviewNotesTitle), findsNothing);
      expect(find.text(AppStrings.contentStatusDraft), findsNothing);
    });

    testWidgets('with the link on, it opens the bundled drafts under the '
        'banner, and back returns to the center', (tester) async {
      await pump(tester, const EmergencyScreen(showReviewEntry: true));

      await tester.runAsync(() async {
        await tester.tap(find.byKey(const ValueKey('first-aid-review-entry')));
        await tester.pump();
        // Let the asset load finish.
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();

      expect(find.byType(FirstAidReviewScreen), findsOneWidget);
      expect(find.text(AppStrings.firstAidDraftBanner), findsOneWidget);
      expect(find.byType(FirstAidTopicTile), findsNWidgets(7));
      expect(find.text(AppStrings.contentStatusDraft), findsNWidgets(7));

      await tapAndSettle(tester, find.byType(BackButton));
      expect(find.byType(EmergencyScreen), findsOneWidget);
      // The library is unchanged by the preview.
      expect(find.text(AppStrings.contentStatusDraft), findsNothing);
    });
  });

  group('review screens', () {
    testWidgets('a draft is shown in full, with its review notes, the '
        'fingerprint and the banner, never as verified', (tester) async {
      await pump(tester, FirstAidReviewScreen(repository: draftRepository()));
      await tester.pumpAndSettle();

      await tapAndSettle(tester, find.text('נושא טיוטה'));

      expect(find.byType(FirstAidReviewTopicScreen), findsOneWidget);
      expect(find.byType(FirstAidTopicScreen), findsNothing);
      expect(find.text(AppStrings.firstAidDraftBanner), findsOneWidget);
      expect(find.text(AppStrings.firstAidDraftNotice), findsOneWidget);
      expect(find.text(AppStrings.contentStatusDraft), findsOneWidget);
      expect(find.text(AppStrings.contentStatusVerified), findsNothing);
      expect(find.text('הפניית טיוטה'), findsOneWidget);
      expect(find.text('שלב טיוטה'), findsOneWidget);
      expect(find.text(AppStrings.firstAidReviewNotesTitle), findsOneWidget);
      expect(find.text('שאלת טיוטה לסוקר'), findsOneWidget);
      expect(find.text(AppStrings.firstAidNotVerifiedLabel), findsOneWidget);
      expect(find.text(AppStrings.firstAidVerifiedByLabel), findsNothing);

      final draft = FirstAidContentParser(
        clock: () => today,
        mode: FirstAidContentMode.review,
      ).parse(draftJson()).topics.single;
      expect(
        find.text(FirstAidContentParser.reviewFingerprint(draft)),
        findsOneWidget,
      );

      // The banner stays in place while the content scrolls.
      final bannerTop = tester
          .getTopLeft(find.text(AppStrings.firstAidDraftBanner))
          .dy;
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(
        tester.getTopLeft(find.text(AppStrings.firstAidDraftBanner)).dy,
        bannerTop,
      );

      await tapAndSettle(tester, callBar());
      expect(dialer.dialed, ['101']);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a draft file claiming approval is refused', (tester) async {
      final claimed = (jsonDecode(draftJson()) as Map<String, Object?>);
      final topic = (claimed['topics']! as List).single as Map<String, Object?>
        ..['status'] = 'verified'
        ..remove('reviewNotes')
        ..['verification'] = {
          'verifiedAt': '2026-10-01',
          'verifiedBy': 'סוקר/ת בדיקה',
        };
      expect(topic['status'], 'verified');

      await pump(
        tester,
        FirstAidReviewScreen(repository: draftRepository(jsonEncode(claimed))),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LoadErrorView), findsOneWidget);
      expect(
        find.text(AppStrings.firstAidReviewLoadErrorTitle),
        findsOneWidget,
      );
      expect(find.byType(FirstAidTopicTile), findsNothing);
      expect(find.text(AppStrings.firstAidDraftBanner), findsOneWidget);
    });

    for (final (name, content) in [
      ('a missing', null),
      ('a broken', '{"schemaVersion": 2,'),
    ]) {
      testWidgets('$name draft file: an error with retry, and the call bar', (
        tester,
      ) async {
        await pump(
          tester,
          FirstAidReviewScreen(
            repository: AssetFirstAidRepository.review(
              bundle: FakeAssetBundle(content),
              clock: () => today,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byType(LoadErrorView), findsOneWidget);
        expect(find.text(AppStrings.retry), findsOneWidget);
        await tapAndSettle(tester, callBar());
        expect(dialer.dialed, ['101']);
      });
    }

    testWidgets('a non-draft topic shows no instructions in the preview', (
      tester,
    ) async {
      final pending = FirstAidTopic(
        id: 'p',
        kind: FirstAidTopicKind.emergency,
        title: 'נושא בהכנה',
        summary: 'תיאור',
        status: ContentStatus.pending,
      );
      await pump(tester, FirstAidReviewTopicScreen(topic: pending));

      expect(find.text(AppStrings.firstAidDraftBanner), findsOneWidget);
      expect(find.text(AppStrings.firstAidStepsTitle), findsNothing);
      expect(
        find.text(AppStrings.firstAidReviewFingerprintLabel),
        findsNothing,
      );
    });

    testWidgets('the bundled drafts: each one renders, right to left, with '
        'its sources and age groups', (tester) async {
      final drafts = bundledHebrewDrafts();
      for (final topic in drafts.topics) {
        await pump(tester, FirstAidReviewTopicScreen(topic: topic));

        final context = tester.element(
          find.text(AppStrings.firstAidDraftBanner),
        );
        expect(Directionality.of(context), TextDirection.rtl);
        expect(tester.takeException(), isNull, reason: topic.id);
        if (topic.variants.length > 1) {
          expect(
            find.text(AppStrings.firstAidChooseVariantHint),
            findsOneWidget,
            reason: topic.id,
          );
          for (final variant in topic.variants) {
            expect(
              find.byKey(ValueKey('variant-${variant.id}')),
              findsOneWidget,
              reason: '${topic.id}/${variant.id}',
            );
          }
          // Choose each in turn: its first step appears.
          for (final variant in topic.variants) {
            await tapAndSettle(
              tester,
              find.byKey(ValueKey('variant-${variant.id}')),
            );
            expect(
              find.text(variant.steps.first.text),
              findsOneWidget,
              reason: '${topic.id}/${variant.id}',
            );
          }
        } else {
          expect(
            find.text(topic.variants.single.steps.first.text),
            findsOneWidget,
          );
        }
        for (final source in topic.sources) {
          expect(
            find.text(source.url.toString()),
            findsOneWidget,
            reason: source.id,
          );
        }
      }
    });
  });

  group('accessibility and layout', () {
    testWidgets('the review topic screen meets the guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      final drafts = bundledHebrewDrafts();
      await pump(
        tester,
        FirstAidReviewTopicScreen(topic: drafts.topicById('choking')!),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    for (final scale in [1.5, 2.0]) {
      testWidgets('a long draft fits a narrow screen at text scale $scale', (
        tester,
      ) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        final drafts = bundledHebrewDrafts();
        await pump(
          tester,
          FirstAidReviewTopicScreen(topic: drafts.topicById('cpr')!),
        );
        tester.setScreenSize(const Size(320, 568));
        await tester.pumpAndSettle();

        final infant = find.byKey(const ValueKey('variant-infant'));
        await tester.scrollUntilVisible(
          infant,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tapAndSettle(tester, infant);
        expect(find.text(AppStrings.firstAidDraftBanner), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text(AppStrings.firstAidReviewFingerprintLabel),
          1000,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
        expect(tester.getRect(callBar()).bottom, lessThanOrEqualTo(568));
      });
    }
  });
}
