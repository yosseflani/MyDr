import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/load_error_views.dart';
import 'package:mydr/core/widgets/not_found_view.dart';
import 'package:mydr/data/first_aid/content_approvals.dart';
import 'package:mydr/data/first_aid/first_aid_content_parser.dart';
import 'package:mydr/data/models/first_aid_content.dart';
import 'package:mydr/features/emergency/emergency_screen.dart';
import 'package:mydr/features/emergency/first_aid_controller.dart';
import 'package:mydr/features/emergency/first_aid_topic_screen.dart';
import 'package:mydr/features/emergency/widgets/first_aid_topic_tile.dart';

import '../../helpers/fake_emergency_dialer.dart';
import '../../helpers/fake_first_aid_repository.dart';
import '../../helpers/pump_app.dart';

/// "Verified" content here is placeholder test text, never real medical
/// instructions; it counts as verified only by passing the real approval
/// check, with approvals made for it in the test.
void main() {
  final today = DateTime(2026, 10, 15);

  Map<String, Object?> variant(String id, String label) => {
    'id': id,
    'label': label,
    'appliesTo': 'קבוצת בדיקה $id',
    'steps': [
      {'order': 1, 'text': 'שלב בדיקה ראשון $id'},
      {'order': 2, 'text': 'שלב בדיקה שני $id', 'note': 'הערת בדיקה $id'},
    ],
    'doNot': ['איסור בדיקה $id'],
  };

  /// One variant ("only") unless [twoVariants].
  Map<String, Object?> verifiedTopic(
    String id, {
    String kind = 'emergency',
    bool twoVariants = false,
  }) => {
    'id': id,
    'kind': kind,
    'status': 'verified',
    'title': 'נושא בדיקה $id',
    'summary': 'תיאור בדיקה $id',
    'overview': 'הסבר בדיקה',
    'recognize': ['סימן בדיקה'],
    if (kind == 'emergency') 'callNow': ['טקסט הפניה לבדיקה'],
    'variants': twoVariants
        ? [variant('older', 'מצב בדיקה א'), variant('younger', 'מצב בדיקה ב')]
        : [variant('only', 'מצב בדיקה')],
    'warnings': ['אזהרת בדיקה'],
    'afterCare': ['המשך בדיקה'],
    'sourceIds': ['s1'],
    'verification': {'verifiedAt': '2026-10-01', 'verifiedBy': 'בודק/ת בדיקה'},
  };

  Map<String, Object?> pendingTopic(String id) => {
    'id': id,
    'kind': 'emergency',
    'status': 'pending',
    'title': 'נושא בדיקה $id',
    'summary': 'תיאור בדיקה $id',
  };

  String packJson(List<Map<String, Object?>> topics) => jsonEncode({
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
    'topics': topics,
  });

  /// Parses [topics] with approvals for every topic the file marks verified,
  /// unless listed in [leaveUnapproved].
  FirstAidContentPack approvedPack(
    List<Map<String, Object?>> topics, {
    Set<String> leaveUnapproved = const {},
  }) {
    final json = packJson(topics);
    final claims = FirstAidContentParser(
      clock: () => today,
    ).parse(json).unapprovedFingerprints;
    return FirstAidContentParser(
      clock: () => today,
      approvals: [
        for (final MapEntry(key: id, value: hash) in claims.entries)
          if (!leaveUnapproved.contains(id))
            ContentApproval(
              topicId: id,
              locale: 'he',
              contentSha256: hash,
              approvedBy: 'בודק/ת בדיקה',
              approvedOn: '2026-10-02',
            ),
      ],
    ).parse(json);
  }

  late FakeEmergencyDialer dialer;
  late FakeFirstAidRepository repository;
  late FirstAidController controller;

  Future<void> setUpWith(FirstAidContentPack? pack, {bool load = true}) async {
    dialer = FakeEmergencyDialer();
    repository = FakeFirstAidRepository(pack);
    controller = FirstAidController(repository);
    addTearDown(controller.dispose);
    if (load) await controller.load();
  }

  Future<void> pump(WidgetTester tester, Widget screen, {Size? size}) {
    tester.setScreenSize(size ?? const Size(400, 2400));
    return tester.pumpApp(
      screen,
      dependencies: AppDependencies.empty(
        emergencyDialer: dialer,
        firstAidRepository: repository,
      ),
      firstAidController: controller,
    );
  }

  Future<void> pumpTopic(WidgetTester tester, String id, {Size? size}) =>
      pump(tester, FirstAidTopicScreen(topicId: id), size: size);

  Future<void> reload(WidgetTester tester) async {
    await tester.runAsync(controller.load);
    await tester.pumpAndSettle();
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Finder callBar() => find.bySemanticsLabel(
    AppStrings.callServiceLabel(AppStrings.serviceMedical, '101'),
  );

  /// Topic ids of the library tiles, top to bottom.
  List<String> shownTopics(WidgetTester tester) {
    final tiles = tester.widgetList<FirstAidTopicTile>(
      find.byType(FirstAidTopicTile),
    );
    final byPosition = [
      for (final tile in tiles)
        (tile.topic.id, tester.getTopLeft(find.byWidget(tile)).dy),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final (id, _) in byPosition) id];
  }

  group('library in the emergency center', () {
    testWidgets('lists the seven bundled topics, each with its kind and '
        '"based on sources, not approved"', (tester) async {
      await setUpWith(bundledHebrewContent());
      await pump(tester, const EmergencyScreen());

      expect(shownTopics(tester), [
        'cpr',
        'choking',
        'bleeding',
        'burns',
        'unconsciousness',
        'seizures',
        'severe_allergic_reaction',
      ]);
      for (final title in [
        'החייאה ושימוש בדפיברילטור',
        'חנק',
        'דימום',
        'כוויות',
        'איבוד הכרה',
        'פרכוסים',
        'תגובה אלרגית חמורה',
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      expect(find.text(AppStrings.topicKindEmergency), findsNWidgets(7));
      expect(find.text(AppStrings.contentStatusSourced), findsNWidgets(7));
      expect(find.text(AppStrings.contentStatusPending), findsNothing);
      expect(find.text(AppStrings.contentStatusVerified), findsNothing);
    });

    testWidgets('shows whatever the controller holds, not a fixed list', (
      tester,
    ) async {
      await setUpWith(
        approvedPack([
          pendingTopic('first'),
          verifiedTopic('second', kind: 'generalInfo'),
        ]),
      );
      await pump(tester, const EmergencyScreen());

      expect(shownTopics(tester), ['first', 'second']);
      expect(find.text(AppStrings.topicKindGeneralInfo), findsOneWidget);
      expect(find.text(AppStrings.contentStatusVerified), findsOneWidget);
    });

    testWidgets('each topic is read out with its kind and status', (
      tester,
    ) async {
      await setUpWith(bundledHebrewContent());
      await pump(tester, const EmergencyScreen());

      expect(
        find.bySemanticsLabel(
          AppStrings.firstAidTopicLabel(
            'חנק',
            AppStrings.topicKindEmergency,
            AppStrings.contentStatusSourced,
          ),
        ),
        findsOneWidget,
      );
    });

    testWidgets('opens a topic, and back returns to the center', (
      tester,
    ) async {
      await setUpWith(bundledHebrewContent());
      await pump(tester, const EmergencyScreen());

      await tapAndSettle(tester, find.text('דימום'));

      final screen = tester.widget<FirstAidTopicScreen>(
        find.byType(FirstAidTopicScreen),
      );
      expect(screen.topicId, 'bleeding');

      await tapAndSettle(tester, find.byType(BackButton));
      expect(find.byType(FirstAidTopicScreen), findsNothing);
      expect(find.byType(EmergencyScreen), findsOneWidget);
    });

    testWidgets('while loading: a static notice, and calling still works', (
      tester,
    ) async {
      await setUpWith(bundledHebrewContent(), load: false);
      repository.gate = Completer<void>();
      unawaited(controller.load());
      await pump(tester, const EmergencyScreen());

      expect(find.text(AppStrings.firstAidLoading), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);

      await tapAndSettle(tester, callBar());
      expect(dialer.dialed, ['101']);

      repository.gate!.complete();
      await tester.pumpAndSettle();
      expect(shownTopics(tester), hasLength(7));
    });

    testWidgets('a failed load offers a retry, and calling still works', (
      tester,
    ) async {
      await setUpWith(null, load: false);
      repository.error = const FirstAidContentException(
        FirstAidContentError.malformed,
        'x',
      );
      await controller.load();
      await pump(tester, const EmergencyScreen());

      expect(find.text(AppStrings.firstAidLoadErrorTitle), findsOneWidget);
      await tapAndSettle(tester, callBar());
      expect(dialer.dialed, ['101']);

      repository
        ..error = null
        ..pack = bundledHebrewContent();
      await tapAndSettle(tester, find.text(AppStrings.retry));
      expect(find.text(AppStrings.firstAidLoadErrorTitle), findsNothing);
      expect(shownTopics(tester), hasLength(7));
    });

    testWidgets('a failed reload keeps the topics, with a notice', (
      tester,
    ) async {
      await setUpWith(bundledHebrewContent());
      repository.error = const FirstAidContentException(
        FirstAidContentError.unavailable,
        'x',
      );
      await controller.load();
      await pump(tester, const EmergencyScreen());

      expect(shownTopics(tester), hasLength(7));
      expect(find.text(AppStrings.firstAidLoadErrorTitle), findsOneWidget);
    });

    testWidgets('no topics: says so', (tester) async {
      await setUpWith(
        FirstAidContentPack(
          schemaVersion: 2,
          contentVersion: 1,
          locale: 'he',
          publishedAt: DateTime.utc(2026, 10, 15),
          topics: const [],
        ),
      );
      await pump(tester, const EmergencyScreen());

      expect(find.text(AppStrings.firstAidEmpty), findsOneWidget);
      expect(find.byType(FirstAidTopicTile), findsNothing);
    });
  });

  group('topic screen', () {
    testWidgets('a pending topic says its instructions are coming, and '
        'shows none', (tester) async {
      await setUpWith(approvedPack([pendingTopic('p')]));
      await pumpTopic(tester, 'p');

      expect(find.text('נושא בדיקה p'), findsWidgets);
      expect(find.text(AppStrings.contentStatusPending), findsOneWidget);
      expect(find.text(AppStrings.firstAidSourcedNoticeTitle), findsNothing);
      expect(find.text(AppStrings.firstAidPendingTitle), findsOneWidget);
      expect(find.text(AppStrings.firstAidPendingMessage), findsOneWidget);
      for (final heading in [
        AppStrings.firstAidCallNowTitle,
        AppStrings.firstAidRecognizeTitle,
        AppStrings.firstAidChooseVariantTitle,
        AppStrings.firstAidStepsTitle,
        AppStrings.firstAidDoNotTitle,
        AppStrings.firstAidWarningsTitle,
        AppStrings.firstAidAfterCareTitle,
        AppStrings.firstAidSourcesTitle,
        AppStrings.firstAidVerifiedOnLabel,
      ]) {
        expect(find.text(heading), findsNothing, reason: heading);
      }
    });

    testWidgets('content marked verified without a trusted approval is '
        'shown as pending', (tester) async {
      await setUpWith(
        approvedPack([verifiedTopic('claimed')], leaveUnapproved: {'claimed'}),
      );
      await pumpTopic(tester, 'claimed');

      expect(find.text(AppStrings.firstAidPendingTitle), findsOneWidget);
      expect(find.text('שלב בדיקה ראשון only'), findsNothing);
      expect(find.text('טקסט הפניה לבדיקה'), findsNothing);
      expect(find.text(AppStrings.contentStatusVerified), findsNothing);
    });

    testWidgets('an emergency topic has the 101 button, which dials at once', (
      tester,
    ) async {
      await setUpWith(bundledHebrewContent());
      await pumpTopic(tester, 'cpr');

      expect(callBar(), findsOneWidget);
      await tapAndSettle(tester, callBar());

      expect(dialer.dialed, ['101']);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('approved content shows when to call, how to recognize, '
        'numbered steps, what not to do, warnings, after-care, its sources '
        'and verification', (tester) async {
      await setUpWith(approvedPack([verifiedTopic('approved')]));
      await pumpTopic(tester, 'approved');

      expect(find.text(AppStrings.contentStatusVerified), findsOneWidget);
      expect(find.text(AppStrings.firstAidPendingTitle), findsNothing);
      expect(find.text(AppStrings.firstAidCallNowTitle), findsOneWidget);
      expect(find.text('טקסט הפניה לבדיקה'), findsOneWidget);
      expect(find.text('הסבר בדיקה'), findsOneWidget);
      expect(find.text('סימן בדיקה'), findsOneWidget);
      // A single variant needs no choice.
      expect(find.text(AppStrings.firstAidChooseVariantTitle), findsNothing);
      expect(
        find.bySemanticsLabel(
          AppStrings.firstAidStepLabel(1, 2, 'שלב בדיקה ראשון only'),
        ),
        findsOneWidget,
      );
      expect(
        find.bySemanticsLabel(
          AppStrings.firstAidStepLabel(
            2,
            2,
            'שלב בדיקה שני only הערת בדיקה only',
          ),
        ),
        findsOneWidget,
      );
      expect(
        tester.getTopLeft(find.text('שלב בדיקה ראשון only')).dy,
        lessThan(tester.getTopLeft(find.text('שלב בדיקה שני only')).dy),
      );
      // When to call comes before the steps.
      expect(
        tester.getTopLeft(find.text('טקסט הפניה לבדיקה')).dy,
        lessThan(tester.getTopLeft(find.text('שלב בדיקה ראשון only')).dy),
      );
      expect(find.text('הערת בדיקה only'), findsOneWidget);
      expect(
        find.bySemanticsLabel(
          AppStrings.firstAidDoNotLabel('איסור בדיקה only'),
        ),
        findsOneWidget,
      );
      expect(find.text('אזהרת בדיקה'), findsOneWidget);
      expect(find.text('המשך בדיקה'), findsOneWidget);
      expect(find.text('מקור בדיקה: מסמך בדיקה'), findsOneWidget);
      expect(
        find.text(AppStrings.firstAidSourcePublished('2025-10')),
        findsOneWidget,
      );
      expect(find.text('https://example.org/test'), findsOneWidget);
      final localizations = MaterialLocalizations.of(
        tester.element(find.byType(FirstAidTopicScreen)),
      );
      expect(
        find.text(AppStrings.firstAidSourceAccessed('2026-10-01')),
        findsOneWidget,
      );
      // The last check and the verification are both on 2026-10-01.
      expect(
        find.text(localizations.formatFullDate(DateTime.utc(2026, 10, 1))),
        findsNWidgets(2),
      );
      expect(find.text('בודק/ת בדיקה'), findsOneWidget);
      expect(find.text(AppStrings.firstAidNotVerifiedLabel), findsNothing);
      expect(callBar(), findsOneWidget);

      // Each part is read on its own, not the whole guide as one block.
      final handle = tester.ensureSemantics();
      await tester.pump();
      for (final text in [
        'טקסט הפניה לבדיקה',
        'הסבר בדיקה',
        'סימן בדיקה',
        'אזהרת בדיקה',
        'המשך בדיקה',
      ]) {
        expect(tester.getSemantics(find.text(text)).label, text);
      }
      expect(
        tester.getSemantics(find.text(AppStrings.firstAidCallNowTitle)),
        containsSemantics(
          label: AppStrings.firstAidCallNowTitle,
          isHeader: true,
        ),
      );
      handle.dispose();
    });

    testWidgets('with several variants, no steps until one is chosen; '
        'unsure means 101', (tester) async {
      final handle = tester.ensureSemantics();
      await setUpWith(
        approvedPack([verifiedTopic('approved', twoVariants: true)]),
      );
      await pumpTopic(tester, 'approved');

      expect(find.text(AppStrings.firstAidChooseVariantTitle), findsOneWidget);
      expect(find.text(AppStrings.firstAidChooseVariantHint), findsOneWidget);
      expect(find.textContaining('שלב בדיקה'), findsNothing);
      expect(find.textContaining('איסור בדיקה'), findsNothing);
      // The parts that apply to everyone are already there.
      expect(find.text('טקסט הפניה לבדיקה'), findsOneWidget);
      expect(find.text('אזהרת בדיקה'), findsOneWidget);

      final older = find.byKey(const ValueKey('variant-older'));
      final younger = find.byKey(const ValueKey('variant-younger'));
      expect(
        tester.getSemantics(older),
        containsSemantics(
          label: AppStrings.firstAidVariantLabel(
            'מצב בדיקה א',
            'קבוצת בדיקה older',
          ),
          isButton: true,
          hasCheckedState: true,
          isChecked: false,
          isInMutuallyExclusiveGroup: true,
          hasTapAction: true,
        ),
      );

      await tapAndSettle(tester, younger);
      expect(find.text('שלב בדיקה ראשון younger'), findsOneWidget);
      expect(find.text('שלב בדיקה ראשון older'), findsNothing);
      expect(find.text('איסור בדיקה younger'), findsOneWidget);
      expect(
        tester.getSemantics(younger),
        containsSemantics(isChecked: true, hasCheckedState: true),
      );
      // The hint stays: the choice can still be wrong.
      expect(find.text(AppStrings.firstAidChooseVariantHint), findsOneWidget);

      await tapAndSettle(tester, older);
      expect(find.text('שלב בדיקה ראשון older'), findsOneWidget);
      expect(find.text('שלב בדיקה ראשון younger'), findsNothing);
      handle.dispose();
    });

    testWidgets('sourced content is shown in full, under a notice that it '
        'is not professionally approved, and never as verified', (
      tester,
    ) async {
      final sourced = verifiedTopic('sourced', twoVariants: true)
        ..['status'] = 'sourced'
        ..remove('verification');
      await setUpWith(approvedPack([sourced]));
      await pumpTopic(tester, 'sourced');

      expect(find.text(AppStrings.contentStatusSourced), findsOneWidget);
      expect(find.text(AppStrings.contentStatusVerified), findsNothing);
      expect(find.text(AppStrings.firstAidPendingTitle), findsNothing);
      expect(find.text(AppStrings.firstAidSourcedNoticeTitle), findsOneWidget);
      expect(
        find.text(AppStrings.firstAidSourcedNoticeMessage),
        findsOneWidget,
      );
      // The notice comes before any instruction.
      expect(
        tester.getTopLeft(find.text(AppStrings.firstAidSourcedNoticeTitle)).dy,
        lessThan(tester.getTopLeft(find.text('טקסט הפניה לבדיקה')).dy),
      );
      expect(find.text(AppStrings.firstAidCallNowTitle), findsOneWidget);
      // No default choice: no steps until a situation is chosen.
      expect(find.text(AppStrings.firstAidChooseVariantHint), findsOneWidget);
      expect(find.textContaining('שלב בדיקה'), findsNothing);
      await tapAndSettle(tester, find.byKey(const ValueKey('variant-older')));
      expect(find.text('שלב בדיקה ראשון older'), findsOneWidget);

      expect(find.text('מקור בדיקה: מסמך בדיקה'), findsOneWidget);
      expect(find.text(AppStrings.firstAidNotVerifiedLabel), findsOneWidget);
      expect(find.text(AppStrings.firstAidVerifiedByLabel), findsNothing);
      expect(find.text(AppStrings.firstAidVerifiedOnLabel), findsNothing);
      expect(callBar(), findsOneWidget);
    });

    testWidgets('every bundled topic shows its sourced guidance; where the '
        'steps differ by age or situation, none until one is chosen', (
      tester,
    ) async {
      final pack = bundledHebrewContent();
      await setUpWith(pack);
      for (final topic in pack.topics) {
        // A fresh screen each time, scrolled to the top.
        await tester.pumpWidget(const SizedBox());
        await pumpTopic(tester, topic.id);

        expect(
          find.text(AppStrings.firstAidSourcedNoticeTitle),
          findsOneWidget,
          reason: topic.id,
        );
        expect(find.text(AppStrings.contentStatusVerified), findsNothing);
        expect(callBar(), findsOneWidget, reason: topic.id);
        for (final callNow in topic.callNow) {
          expect(find.text(callNow), findsOneWidget, reason: topic.id);
        }
        if (topic.variants.length > 1) {
          for (final variant in topic.variants) {
            expect(
              find.text(variant.steps.first.text),
              findsNothing,
              reason: '${topic.id}/${variant.id} shown before a choice',
            );
          }
          final first = topic.variants.first;
          await tapAndSettle(
            tester,
            find.byKey(ValueKey('variant-${first.id}')),
          );
          expect(find.text(first.steps.first.text), findsOneWidget);
        } else {
          expect(
            find.text(topic.variants.single.steps.first.text),
            findsOneWidget,
            reason: topic.id,
          );
        }
        await tester.scrollUntilVisible(
          find.text(AppStrings.firstAidNotVerifiedLabel),
          500,
          scrollable: find.byType(Scrollable).first,
        );
        for (final source in topic.sources) {
          expect(
            find.text(source.url.toString()),
            findsOneWidget,
            reason: '${topic.id}/${source.id}',
          );
        }
        expect(tester.takeException(), isNull, reason: topic.id);
      }
    });

    testWidgets('a draft that reached the app controller is still not '
        'shown', (tester) async {
      final draft = FirstAidTopic(
        id: 'draft',
        kind: FirstAidTopicKind.emergency,
        title: 'נושא בדיקה',
        summary: 'תיאור בדיקה',
        status: ContentStatus.draft,
        callNow: ['טקסט הפניה לבדיקה'],
        variants: [
          GuideVariant(
            id: 'v',
            label: 'מצב',
            steps: [GuideStep(order: 1, text: 'שלב טיוטה')],
          ),
        ],
        sources: [
          ContentSource(
            id: 's',
            publisher: 'מקור בדיקה',
            title: 'מסמך בדיקה',
            url: Uri.parse('https://example.org/test'),
            published: '2025',
            accessedOn: DateTime.utc(2026, 10, 1),
          ),
        ],
      );
      await setUpWith(
        FirstAidContentPack(
          schemaVersion: 2,
          contentVersion: 1,
          locale: 'he',
          publishedAt: DateTime.utc(2026, 10, 15),
          topics: [draft],
        ),
      );
      await pumpTopic(tester, 'draft');

      expect(find.text(AppStrings.firstAidPendingTitle), findsOneWidget);
      expect(find.text('שלב טיוטה'), findsNothing);
      expect(find.text('טקסט הפניה לבדיקה'), findsNothing);
      expect(callBar(), findsOneWidget);
    });

    testWidgets('a general-information topic is marked as such, without the '
        'call bar', (tester) async {
      await setUpWith(
        approvedPack([verifiedTopic('info', kind: 'generalInfo')]),
      );
      await pumpTopic(tester, 'info');

      expect(find.text(AppStrings.topicKindGeneralInfo), findsOneWidget);
      expect(find.text(AppStrings.firstAidCallNowTitle), findsNothing);
      expect(callBar(), findsNothing);
    });

    testWidgets('an unknown topic: not found, with the call bar', (
      tester,
    ) async {
      await setUpWith(bundledHebrewContent());
      await pumpTopic(tester, 'missing');

      expect(find.byType(NotFoundView), findsOneWidget);
      expect(find.text(AppStrings.firstAidTopicNotFoundTitle), findsOneWidget);
      expect(callBar(), findsOneWidget);
    });

    testWidgets('content that failed to load: retry, with the call bar', (
      tester,
    ) async {
      await setUpWith(null, load: false);
      repository.error = const FirstAidContentException(
        FirstAidContentError.unsupportedSchema,
        'x',
      );
      await controller.load();
      await pumpTopic(tester, 'cpr');

      expect(find.byType(LoadErrorView), findsOneWidget);
      await tapAndSettle(tester, callBar());
      expect(dialer.dialed, ['101']);

      repository
        ..error = null
        ..pack = bundledHebrewContent();
      await tapAndSettle(tester, find.text(AppStrings.retry));
      expect(find.text(AppStrings.firstAidSourcedNoticeTitle), findsOneWidget);
    });

    testWidgets('while loading: a static notice and the call bar', (
      tester,
    ) async {
      await setUpWith(bundledHebrewContent(), load: false);
      repository.gate = Completer<void>();
      unawaited(controller.load());
      await pumpTopic(tester, 'cpr');

      expect(find.text(AppStrings.firstAidLoading), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(callBar(), findsOneWidget);
      repository.gate!.complete();
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.firstAidSourcedNoticeTitle), findsOneWidget);
    });

    testWidgets('follows reloads: approved, no longer approved, removed', (
      tester,
    ) async {
      await setUpWith(approvedPack([pendingTopic('t')]));
      await pumpTopic(tester, 't');
      expect(find.text(AppStrings.firstAidPendingTitle), findsOneWidget);

      repository.pack = approvedPack([verifiedTopic('t')]);
      await reload(tester);
      expect(find.text('שלב בדיקה ראשון only'), findsOneWidget);
      expect(find.text(AppStrings.firstAidPendingTitle), findsNothing);

      repository.pack = approvedPack(
        [verifiedTopic('t')],
        leaveUnapproved: {'t'},
      );
      await reload(tester);
      expect(find.text('שלב בדיקה ראשון only'), findsNothing);
      expect(find.text(AppStrings.firstAidPendingTitle), findsOneWidget);

      repository.pack = approvedPack([pendingTopic('other')]);
      await reload(tester);
      expect(find.byType(NotFoundView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('accessibility and layout', () {
    testWidgets('screen readers can activate the 101 button and the topics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await setUpWith(bundledHebrewContent());
      await pump(tester, const EmergencyScreen());

      final call = find.bySemanticsLabel(
        AppStrings.callServiceLabel(AppStrings.serviceMedical, '101'),
      );
      expect(
        tester.getSemantics(call),
        containsSemantics(isButton: true, hasTapAction: true),
      );
      tester.semantics.tap(
        find.semantics.byLabel(
          AppStrings.callServiceLabel(AppStrings.serviceMedical, '101'),
        ),
      );
      await tester.pumpAndSettle();
      expect(dialer.dialed, ['101']);

      final choking = find.bySemanticsLabel(
        AppStrings.firstAidTopicLabel(
          'חנק',
          AppStrings.topicKindEmergency,
          AppStrings.contentStatusSourced,
        ),
      );
      expect(
        tester.getSemantics(choking),
        containsSemantics(isButton: true, hasTapAction: true),
      );
      tester.semantics.tap(
        find.semantics.byLabel(
          AppStrings.firstAidTopicLabel(
            'חנק',
            AppStrings.topicKindEmergency,
            AppStrings.contentStatusSourced,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(FirstAidTopicScreen), findsOneWidget);
      handle.dispose();
    });

    testWidgets('the center with topics meets the guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await setUpWith(bundledHebrewContent());
      await pump(tester, const EmergencyScreen());

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    for (final id in ['pending', 'approved']) {
      testWidgets('a $id topic meets the guidelines', (tester) async {
        final handle = tester.ensureSemantics();
        await setUpWith(
          approvedPack([pendingTopic('pending'), verifiedTopic('approved')]),
        );
        await pumpTopic(tester, id);

        await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
        await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
        await expectLater(tester, meetsGuideline(textContrastGuideline));
        handle.dispose();
      });
    }

    testWidgets('a bundled sourced topic, with its notice, meets the '
        'guidelines', (tester) async {
      final handle = tester.ensureSemantics();
      await setUpWith(bundledHebrewContent());
      await pumpTopic(tester, 'choking');

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      expect(
        tester.getSemantics(find.text(AppStrings.firstAidSourcedNoticeTitle)),
        containsSemantics(
          label:
              '${AppStrings.firstAidSourcedNoticeTitle}\n'
              '${AppStrings.firstAidSourcedNoticeMessage}',
        ),
      );
      handle.dispose();
    });

    for (final scale in [1.5, 2.0]) {
      testWidgets('a bundled sourced topic fits a narrow screen at text '
          'scale $scale', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await setUpWith(bundledHebrewContent());
        await pumpTopic(tester, 'cpr', size: const Size(320, 568));

        final infant = find.byKey(const ValueKey('variant-infant'));
        await tester.scrollUntilVisible(
          infant,
          300,
          scrollable: find.byType(Scrollable).first,
        );
        await tapAndSettle(tester, infant);
        await tester.scrollUntilVisible(
          find.text(AppStrings.firstAidNotVerifiedLabel),
          1000,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
        expect(tester.getRect(callBar()).bottom, lessThanOrEqualTo(568));
      });
    }

    for (final scale in [1.5, 2.0]) {
      testWidgets('fits a narrow screen at text scale $scale', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await setUpWith(
          approvedPack([pendingTopic('pending'), verifiedTopic('approved')]),
        );
        const size = Size(320, 568);

        await pump(tester, const EmergencyScreen(), size: size);
        await tester.scrollUntilVisible(
          find.byKey(const ValueKey('approved')),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);

        await tapAndSettle(tester, find.byKey(const ValueKey('approved')));
        expect(tester.takeException(), isNull);
        // The call bar stays on screen while the content scrolls.
        expect(tester.getRect(callBar()).bottom, lessThanOrEqualTo(568));
        await tester.scrollUntilVisible(
          find.text('בודק/ת בדיקה'),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
        expect(tester.getRect(callBar()).bottom, lessThanOrEqualTo(568));
      });
    }
  });
}
