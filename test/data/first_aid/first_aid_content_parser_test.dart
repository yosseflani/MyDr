import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/first_aid/content_approvals.dart';
import 'package:mydr/data/first_aid/first_aid_content_parser.dart';
import 'package:mydr/data/models/first_aid_content.dart';

/// Test content is placeholder text only; it never contains real medical
/// instructions.
void main() {
  final today = DateTime(2026, 10, 15, 12);

  Map<String, Object?> pendingTopic(String id) => {
    'id': id,
    'kind': 'emergency',
    'status': 'pending',
    'title': 'נושא $id',
    'summary': 'תיאור בדיקה',
  };

  Map<String, Object?> verifiedTopic(String id) => {
    'id': id,
    'kind': 'emergency',
    'status': 'verified',
    'title': 'נושא $id',
    'summary': 'תיאור בדיקה',
    'callAdvice': 'טקסט הפניה לבדיקה',
    'steps': [
      {'order': 1, 'text': 'שלב בדיקה א'},
      {'order': 2, 'text': 'שלב בדיקה ב', 'note': 'הערת בדיקה'},
    ],
    'warnings': ['אזהרת בדיקה'],
    'source': {
      'publisher': 'מקור בדיקה',
      'title': 'מסמך בדיקה',
      'url': 'https://example.org/test',
    },
    'verification': {'verifiedAt': '2026-10-01', 'verifiedBy': 'בודק/ת בדיקה'},
  };

  Map<String, Object?> pack(List<Map<String, Object?>> topics) => {
    'schemaVersion': 1,
    'contentVersion': 3,
    'locale': 'he',
    'publishedAt': '2026-10-15',
    'topics': topics,
  };

  FirstAidContentPack parse(
    Object? json, {
    List<ContentApproval> approvals = const [],
  }) => FirstAidContentParser(
    approvals: approvals,
    clock: () => today,
  ).parse(json is String ? json : jsonEncode(json));

  Matcher throwsContentError(FirstAidContentError error) => throwsA(
    isA<FirstAidContentException>().having((e) => e.error, 'error', error),
  );

  ContentApproval approvalFor(
    String id,
    String fingerprint, {
    String locale = 'he',
  }) => ContentApproval(
    topicId: id,
    locale: locale,
    contentSha256: fingerprint,
    approvedBy: 'בודק/ת בדיקה',
    approvedOn: '2026-10-02',
  );

  group('valid content', () {
    test('reads the pack and pending topics', () {
      final result = parse(pack([pendingTopic('a'), pendingTopic('b')]));

      expect(result.schemaVersion, 1);
      expect(result.contentVersion, 3);
      expect(result.locale, 'he');
      expect(result.publishedAt, DateTime.utc(2026, 10, 15));
      expect([for (final t in result.topics) t.id], ['a', 'b']);
      final topic = result.topicById('a')!;
      expect(topic.status, ContentStatus.pending);
      expect(topic.kind, FirstAidTopicKind.emergency);
      expect(topic.steps, isEmpty);
      expect(topic.warnings, isEmpty);
      expect(topic.callAdvice, isNull);
      expect(result.unapprovedFingerprints, isEmpty);
      expect(result.topicById('missing'), isNull);
    });

    test('the bundled Hebrew file: seven pending topics, no instructions', () {
      final file = File('assets/first_aid/he.json').readAsStringSync();
      final result = FirstAidContentParser(clock: () => today).parse(file);

      expect(result.locale, 'he');
      expect(
        [for (final t in result.topics) t.id],
        [
          'cpr',
          'choking',
          'bleeding',
          'burns',
          'unconsciousness',
          'seizures',
          'severe_allergic_reaction',
        ],
      );
      expect(
        [for (final t in result.topics) t.title],
        [
          'החייאה',
          'חנק',
          'דימום',
          'כוויות',
          'איבוד הכרה',
          'פרכוסים',
          'תגובה אלרגית חמורה',
        ],
      );
      for (final topic in result.topics) {
        expect(topic.status, ContentStatus.pending, reason: topic.id);
        expect(topic.steps, isEmpty, reason: topic.id);
        expect(topic.warnings, isEmpty, reason: topic.id);
        expect(topic.callAdvice, isNull, reason: topic.id);
      }
      expect(result.unapprovedFingerprints, isEmpty);
    });

    test("the bundled descriptions don't repeat the in-preparation notice", () {
      final file = File('assets/first_aid/he.json').readAsStringSync();
      final result = FirstAidContentParser(clock: () => today).parse(file);

      for (final topic in result.topics) {
        expect(topic.summary, isNot(contains('בהכנה')), reason: topic.id);
        expect(topic.summary, contains(topic.title), reason: topic.id);
      }
    });

    test('the shipped app trusts no approvals yet', () {
      expect(FirstAidApprovals.trusted, isEmpty);
    });
  });

  group('rejects', () {
    test('text that is not JSON', () {
      expect(
        () => parse('{"schemaVersion": 1,'),
        throwsContentError(FirstAidContentError.malformed),
      );
    });

    test('JSON that is not an object, or a topic that is not one', () {
      expect(
        () => parse([pack([])]),
        throwsContentError(FirstAidContentError.malformed),
      );
      expect(
        () => parse(pack([])..['topics'] = ['cpr']),
        throwsContentError(FirstAidContentError.malformed),
      );
    });

    test('an unsupported or missing schema version', () {
      expect(
        () => parse(pack([pendingTopic('a')])..['schemaVersion'] = 2),
        throwsContentError(FirstAidContentError.unsupportedSchema),
      );
      expect(
        () => parse(pack([pendingTopic('a')])..remove('schemaVersion')),
        throwsContentError(FirstAidContentError.missingField),
      );
      expect(
        () => parse(pack([pendingTopic('a')])..['schemaVersion'] = '1'),
        throwsContentError(FirstAidContentError.invalidValue),
      );
    });

    test('a newer schema even if its other fields look broken', () {
      expect(
        () => parse({'schemaVersion': 2, 'something': 'else'}),
        throwsContentError(FirstAidContentError.unsupportedSchema),
      );
    });

    for (final field in ['contentVersion', 'locale', 'publishedAt', 'topics']) {
      test('a pack without $field', () {
        expect(
          () => parse(pack([pendingTopic('a')])..remove(field)),
          throwsContentError(FirstAidContentError.missingField),
        );
      });
    }

    for (final field in ['id', 'kind', 'status', 'title', 'summary']) {
      test('a topic without $field', () {
        expect(
          () => parse(pack([pendingTopic('a')..remove(field)])),
          throwsContentError(FirstAidContentError.missingField),
        );
      });
    }

    final invalidValues = <String, Map<String, Object?> Function()>{
      'a date that does not exist': () =>
          pack([pendingTopic('a')])..['publishedAt'] = '2026-13-01',
      'a date in another format': () =>
          pack([pendingTopic('a')])..['publishedAt'] = '15/10/2026',
      'an upper case locale': () =>
          pack([pendingTopic('a')])..['locale'] = 'HE',
      'content version 0': () =>
          pack([pendingTopic('a')])..['contentVersion'] = 0,
      'no topics': () => pack([]),
      'an unknown kind': () => pack([pendingTopic('a')..['kind'] = 'urgent']),
      'an unknown status': () =>
          pack([pendingTopic('a')..['status'] = 'approved']),
      'an id with spaces': () => pack([pendingTopic('a')..['id'] = 'Bad Id']),
      'a blank title': () => pack([pendingTopic('a')..['title'] = '   ']),
      'a non-text summary': () => pack([pendingTopic('a')..['summary'] = 5]),
      'steps out of order': () => pack([
        verifiedTopic('a')
          ..['steps'] = [
            {'order': 2, 'text': 'שלב בדיקה'},
          ],
      ]),
      'a verification date in the future': () => pack([
        verifiedTopic('a')
          ..['verification'] = {
            'verifiedAt': '2026-10-16',
            'verifiedBy': 'בודק/ת בדיקה',
          },
      ]),
    };
    invalidValues.forEach((name, build) {
      test(name, () {
        expect(
          () => parse(build()),
          throwsContentError(FirstAidContentError.invalidValue),
        );
      });
    });

    test('fields the schema does not define (e.g. a typo)', () {
      expect(
        () => parse(pack([pendingTopic('a')..['step'] = []])),
        throwsContentError(FirstAidContentError.unknownField),
      );
      expect(
        () => parse(pack([pendingTopic('a')])..['extra'] = true),
        throwsContentError(FirstAidContentError.unknownField),
      );
      expect(
        () => parse(
          pack([
            verifiedTopic('a')
              ..['source'] = {
                'publisher': 'מקור',
                'title': 'מסמך',
                'url': 'https://example.org',
                'approved': true,
              },
          ]),
        ),
        throwsContentError(FirstAidContentError.unknownField),
      );
    });

    test('duplicate topic ids', () {
      expect(
        () => parse(pack([pendingTopic('a'), pendingTopic('a')])),
        throwsContentError(FirstAidContentError.duplicateTopicId),
      );
    });

    final pendingWithInstructions = {
      'steps': [
        {'order': 1, 'text': 'שלב בדיקה'},
      ],
      'warnings': ['אזהרת בדיקה'],
      'callAdvice': 'טקסט הפניה',
    };
    pendingWithInstructions.forEach((field, value) {
      test('a pending topic with $field entered by mistake', () {
        expect(
          () => parse(pack([pendingTopic('a')..[field] = value])),
          throwsContentError(FirstAidContentError.pendingWithInstructions),
        );
      });
    });

    for (final field in ['steps', 'source', 'verification', 'callAdvice']) {
      test('a topic marked verified without $field', () {
        expect(
          () => parse(pack([verifiedTopic('a')..remove(field)])),
          throwsContentError(FirstAidContentError.incompleteVerification),
        );
      });
    }

    test('a verified topic whose verification has no reviewer', () {
      expect(
        () => parse(
          pack([
            verifiedTopic('a')..['verification'] = {'verifiedAt': '2026-10-01'},
          ]),
        ),
        throwsContentError(FirstAidContentError.missingField),
      );
    });

    for (final url in [
      'http://example.org/test',
      'example.org/test',
      'https://',
    ]) {
      test('a source link that is not https: "$url"', () {
        expect(
          () => parse(
            pack([
              verifiedTopic('a')
                ..['source'] = {
                  'publisher': 'מקור בדיקה',
                  'title': 'מסמך בדיקה',
                  'url': url,
                },
            ]),
          ),
          throwsContentError(FirstAidContentError.incompleteVerification),
        );
      });
    }
  });

  group('approval of verified content', () {
    test('"verified" in the file alone is not enough: the topic stays '
        'pending, without its instructions', () {
      final result = parse(pack([verifiedTopic('a')]));

      final topic = result.topicById('a')!;
      expect(topic.status, ContentStatus.pending);
      expect(topic.isVerified, isFalse);
      expect(topic.steps, isEmpty);
      expect(topic.warnings, isEmpty);
      expect(topic.callAdvice, isNull);
      expect(result.unapprovedFingerprints.keys, ['a']);
      expect(result.unapprovedFingerprints['a'], matches(r'^[0-9a-f]{64}$'));
    });

    test('a trusted approval of that exact content makes it verified', () {
      final fingerprint = parse(
        pack([verifiedTopic('a')]),
      ).unapprovedFingerprints['a']!;

      final result = parse(
        pack([verifiedTopic('a')]),
        approvals: [approvalFor('a', fingerprint)],
      );

      final topic = result.topicById('a')!;
      expect(topic.status, ContentStatus.verified);
      expect([for (final s in topic.steps) s.order], [1, 2]);
      expect(topic.steps[1].note, 'הערת בדיקה');
      expect(topic.warnings, ['אזהרת בדיקה']);
      expect(topic.callAdvice, 'טקסט הפניה לבדיקה');
      expect(topic.source!.url, Uri.parse('https://example.org/test'));
      expect(topic.verification!.verifiedAt, DateTime.utc(2026, 10, 1));
      expect(topic.verification!.verifiedBy, 'בודק/ת בדיקה');
      expect(result.unapprovedFingerprints, isEmpty);
    });

    test('any change after approval voids it', () {
      final fingerprint = parse(
        pack([verifiedTopic('a')]),
      ).unapprovedFingerprints['a']!;
      final approvals = [approvalFor('a', fingerprint)];

      final changes = <String, void Function(Map<String, Object?>)>{
        'a step': (t) => t['steps'] = [
          {'order': 1, 'text': 'שלב בדיקה א!'},
          {'order': 2, 'text': 'שלב בדיקה ב', 'note': 'הערת בדיקה'},
        ],
        'a warning': (t) => t['warnings'] = ['אזהרה אחרת'],
        'the source link': (t) => t['source'] = {
          'publisher': 'מקור בדיקה',
          'title': 'מסמך בדיקה',
          'url': 'https://example.org/other',
        },
        'the reviewer': (t) => t['verification'] = {
          'verifiedAt': '2026-10-01',
          'verifiedBy': 'מישהו אחר',
        },
        'the title': (t) => t['title'] = 'כותרת אחרת',
      };
      changes.forEach((name, change) {
        final topic = verifiedTopic('a');
        change(topic);
        final result = parse(pack([topic]), approvals: approvals);
        expect(result.topicById('a')!.isVerified, isFalse, reason: name);
        expect(result.topicById('a')!.steps, isEmpty, reason: name);
      });
    });

    test('an approval for another topic or language does not count', () {
      final fingerprint = parse(
        pack([verifiedTopic('a')]),
      ).unapprovedFingerprints['a']!;

      for (final approval in [
        approvalFor('b', fingerprint),
        approvalFor('a', fingerprint, locale: 'en'),
      ]) {
        final result = parse(pack([verifiedTopic('a')]), approvals: [approval]);
        expect(result.topicById('a')!.isVerified, isFalse);
      }
    });

    test('a general-information topic does not need call advice', () {
      final topic = verifiedTopic('a')
        ..['kind'] = 'generalInfo'
        ..remove('callAdvice');
      final fingerprint = parse(pack([topic])).unapprovedFingerprints['a']!;

      final result = parse(
        pack([topic]),
        approvals: [approvalFor('a', fingerprint)],
      );
      expect(result.topicById('a')!.isVerified, isTrue);
      expect(result.topicById('a')!.kind, FirstAidTopicKind.generalInfo);
    });
  });

  group('models', () {
    test('a pending topic can never hold instructions', () {
      expect(
        () => FirstAidTopic(
          id: 'a',
          kind: FirstAidTopicKind.emergency,
          title: 'נושא',
          summary: 'תיאור',
          status: ContentStatus.pending,
          steps: [GuideStep(order: 1, text: 'שלב')],
        ),
        throwsArgumentError,
      );
    });

    test('a verified topic needs steps, a source and a verification', () {
      expect(
        () => FirstAidTopic(
          id: 'a',
          kind: FirstAidTopicKind.emergency,
          title: 'נושא',
          summary: 'תיאור',
          status: ContentStatus.verified,
          steps: [GuideStep(order: 1, text: 'שלב')],
        ),
        throwsArgumentError,
      );
    });

    test('a source must be an https link', () {
      expect(
        () => ContentSource(
          publisher: 'מקור',
          title: 'מסמך',
          url: Uri.parse('http://example.org'),
        ),
        throwsArgumentError,
      );
    });

    test('lists are unmodifiable', () {
      final result = parse(pack([pendingTopic('a')]));
      expect(() => result.topics.clear(), throwsUnsupportedError);
      expect(() => result.topics.first.steps.clear(), throwsUnsupportedError);
    });

    test('toString never includes content', () {
      final topic = parse(pack([pendingTopic('a')])).topics.single;
      expect(topic.toString(), 'FirstAidTopic(a, pending)');
    });
  });
}
