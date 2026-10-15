import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/first_aid/content_approvals.dart';
import 'package:mydr/data/first_aid/first_aid_content_parser.dart';
import 'package:mydr/data/first_aid/first_aid_review_document.dart';
import 'package:mydr/data/models/first_aid_content.dart';
import 'package:mydr/data/repositories/first_aid_repository.dart';

/// Checks the content files that ship with the app. Nothing here approves
/// anything: the real content is only read, never marked verified.
void main() {
  final today = DateTime(2026, 10, 15, 12);
  const topicIds = [
    'cpr',
    'choking',
    'bleeding',
    'burns',
    'unconsciousness',
    'seizures',
    'severe_allergic_reaction',
  ];

  FirstAidContentPack published() => FirstAidContentParser(
    clock: () => today,
  ).parse(File(AssetFirstAidRepository.hebrewContentPath).readAsStringSync());

  FirstAidContentPack drafts() => FirstAidContentParser(
    clock: () => today,
    mode: FirstAidContentMode.review,
  ).parse(File(AssetFirstAidRepository.hebrewDraftPath).readAsStringSync());

  group('the app content (he.json)', () {
    test('seven sourced topics: full instructions with sources, none '
        'verified', () {
      final pack = published();

      expect(pack.locale, 'he');
      expect([for (final t in pack.topics) t.id], topicIds);
      expect(
        [for (final t in pack.topics) t.title],
        [
          'החייאה ושימוש בדפיברילטור',
          'חנק',
          'דימום',
          'כוויות',
          'איבוד הכרה',
          'פרכוסים',
          'תגובה אלרגית חמורה',
        ],
      );
      for (final topic in pack.topics) {
        expect(topic.status, ContentStatus.sourced, reason: topic.id);
        expect(topic.isVerified, isFalse, reason: topic.id);
        expect(topic.verification, isNull, reason: topic.id);
        expect(topic.reviewNotes, isEmpty, reason: topic.id);
        expect(topic.callNow, isNotEmpty, reason: topic.id);
        expect(topic.variants, isNotEmpty, reason: topic.id);
        expect(topic.sources, isNotEmpty, reason: topic.id);
      }
      expect(pack.unapprovedFingerprints, isEmpty);
    });

    test('the file never claims verification', () {
      final text = File(
        AssetFirstAidRepository.hebrewContentPath,
      ).readAsStringSync();
      expect(text, isNot(contains('"verified"')));
      expect(text, isNot(contains('"verification"')));
      expect(text, isNot(contains('"reviewNotes"')));
    });

    test('each topic is word for word the wording in the review document', () {
      final pack = published();
      final review = drafts();
      for (final topic in pack.topics) {
        expect(
          FirstAidContentParser.reviewFingerprint(topic),
          FirstAidContentParser.reviewFingerprint(review.topicById(topic.id)!),
          reason: '${topic.id}: he.json and the review file differ',
        );
      }
    });

    test("descriptions don't repeat the in-preparation notice", () {
      for (final topic in published().topics) {
        expect(topic.summary, isNot(contains('בהכנה')), reason: topic.id);
        expect(topic.summary, contains(topic.title), reason: topic.id);
      }
    });

    test('the shipped app trusts no approvals: no content was reviewed', () {
      expect(FirstAidApprovals.trusted, isEmpty);
    });

    test('the draft file is not valid app content', () {
      expect(
        () => FirstAidContentParser(clock: () => today).parse(
          File(AssetFirstAidRepository.hebrewDraftPath).readAsStringSync(),
        ),
        throwsA(
          isA<FirstAidContentException>().having(
            (e) => e.error,
            'error',
            FirstAidContentError.wrongContentMode,
          ),
        ),
      );
    });
  });

  group('the review file (review/he.draft.json)', () {
    test('a full draft for each of the seven topics, same titles', () {
      final pack = drafts();
      final live = published();

      expect([for (final t in pack.topics) t.id], topicIds);
      for (final topic in pack.topics) {
        expect(topic.isDraft, isTrue, reason: topic.id);
        expect(topic.verification, isNull, reason: topic.id);
        expect(topic.kind, FirstAidTopicKind.emergency, reason: topic.id);
        expect(topic.title, live.topicById(topic.id)!.title, reason: topic.id);
        expect(topic.summary, live.topicById(topic.id)!.summary);
        expect(topic.overview, isNotNull, reason: topic.id);
        expect(topic.callNow, isNotEmpty, reason: topic.id);
        expect(topic.variants, isNotEmpty, reason: topic.id);
        expect(topic.sources, isNotEmpty, reason: topic.id);
        expect(topic.reviewNotes, isNotEmpty, reason: topic.id);
      }
    });

    test('every source is an https link with its dates', () {
      for (final topic in drafts().topics) {
        for (final source in topic.sources) {
          expect(source.url.scheme, 'https', reason: source.id);
          expect(source.published, matches(r'^\d{4}-\d{2}(-\d{2})?$'));
          expect(source.accessedOn.isAfter(DateTime.utc(2026)), isTrue);
        }
      }
    });

    test('age groups are separate where the steps differ', () {
      final pack = drafts();
      List<String> variantIds(String topic) => [
        for (final v in pack.topicById(topic)!.variants) v.id,
      ];

      expect(variantIds('cpr'), ['adult', 'child', 'infant', 'aed']);
      expect(variantIds('choking'), [
        'adult_or_child',
        'infant',
        'unconscious',
      ]);
      expect(variantIds('bleeding'), ['controllable', 'life_threatening']);
      expect(variantIds('burns'), ['heat', 'chemical_or_electrical']);
      expect(variantIds('unconsciousness'), [
        'breathing_normally',
        'not_breathing_normally',
      ]);

      // Infants never get abdominal thrusts.
      final infantChoking = pack
          .topicById('choking')!
          .variants
          .firstWhere((v) => v.id == 'infant');
      for (final step in infantChoking.steps) {
        expect(step.text, isNot(contains('לחיצות בטן')));
      }
      for (final topic in pack.topics) {
        for (final variant in topic.variants) {
          expect(variant.appliesTo, isNotNull, reason: variant.id);
        }
      }
    });

    test('no instruction names a foreign emergency number', () {
      final pack = drafts();
      for (final topic in pack.topics) {
        final texts = [
          ...topic.callNow,
          for (final v in topic.variants) ...[
            for (final s in v.steps) s.text,
            ...v.doNot,
          ],
          ...topic.warnings,
          ...topic.afterCare,
        ];
        for (final text in texts) {
          expect(text, isNot(matches(RegExp(r'\b(999|911|112|111)\b'))));
        }
      }
    });

    test('no medication doses', () {
      final dose = RegExp(r'(\bmg\b|מ"ג|מ״ג|מיליגרם|\bml\b|מ"ל|מ״ל)');
      for (final topic in drafts().topics) {
        for (final variant in topic.variants) {
          for (final step in variant.steps) {
            expect(step.text, isNot(matches(dose)), reason: variant.id);
          }
        }
      }
    });
  });

  test('the medical review document is up to date', () {
    final expected = buildFirstAidReviewDocument(
      drafts: drafts(),
      published: published(),
    );
    final actual = File(
      'docs/first_aid_medical_review.md',
    ).readAsStringSync().replaceAll('\r\n', '\n');
    expect(
      actual,
      expected,
      reason: 'Run: dart run tool/first_aid_review.dart',
    );
  });

  test('the review document never claims an approval the app would not '
      'honor', () {
    final document = buildFirstAidReviewDocument(
      drafts: drafts(),
      published: published(),
    );
    expect(document, contains('אישורים מקצועיים רשומים: 0'));
    for (final id in topicIds) {
      expect(document, contains('(`$id`)'));
    }
    expect('אישור מקצועי: אין'.allMatches(document).length, topicIds.length);
  });
}
