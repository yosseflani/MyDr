import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/first_aid/content_approvals.dart';
import 'package:mydr/data/first_aid/first_aid_content_parser.dart';
import 'package:mydr/data/models/first_aid_content.dart';

/// Test content is synthetic placeholder text only; it never contains real
/// medical instructions, and every approval here is a test approval of
/// that placeholder content.
void main() {
  final today = DateTime(2026, 10, 15, 12);

  Map<String, Object?> source(String id) => {
    'id': id,
    'publisher': 'מפרסם בדיקה',
    'title': 'מסמך בדיקה $id',
    'url': 'https://example.org/$id',
    'published': '2025-10',
    'accessedOn': '2026-10-01',
  };

  Map<String, Object?> pendingTopic(String id) => {
    'id': id,
    'kind': 'emergency',
    'status': 'pending',
    'title': 'נושא $id',
    'summary': 'תיאור בדיקה',
  };

  Map<String, Object?> variant(String id) => {
    'id': id,
    'label': 'מצב בדיקה $id',
    'appliesTo': 'קבוצת בדיקה',
    'steps': [
      {'order': 1, 'text': 'שלב בדיקה א'},
      {'order': 2, 'text': 'שלב בדיקה ב', 'note': 'הערת בדיקה'},
    ],
    'doNot': ['איסור בדיקה'],
  };

  Map<String, Object?> contentTopic(String id, String status) => {
    'id': id,
    'kind': 'emergency',
    'status': status,
    'title': 'נושא $id',
    'summary': 'תיאור בדיקה',
    'overview': 'הסבר בדיקה',
    'recognize': ['סימן בדיקה'],
    'callNow': ['הפניית בדיקה'],
    'variants': [variant('first'), variant('second')],
    'warnings': ['אזהרת בדיקה'],
    'afterCare': ['המשך בדיקה'],
    'sourceIds': ['s1'],
  };

  Map<String, Object?> verifiedTopic(String id) => contentTopic(id, 'verified')
    ..['verification'] = {
      'verifiedAt': '2026-10-01',
      'verifiedBy': 'סוקר/ת בדיקה',
    };

  Map<String, Object?> draftTopic(String id) =>
      contentTopic(id, 'draft')..['reviewNotes'] = ['שאלת בדיקה לסוקר'];

  Map<String, Object?> pack(List<Map<String, Object?>> topics) => {
    'schemaVersion': 2,
    'contentVersion': 3,
    'locale': 'he',
    'publishedAt': '2026-10-15',
    'sources': [source('s1'), source('s2')],
    'topics': topics,
  };

  FirstAidContentPack parse(
    Object? json, {
    List<ContentApproval> approvals = const [],
    FirstAidContentMode mode = FirstAidContentMode.published,
  }) => FirstAidContentParser(
    approvals: approvals,
    clock: () => today,
    mode: mode,
  ).parse(json is String ? json : jsonEncode(json));

  FirstAidContentPack review(Object? json) =>
      parse(json, mode: FirstAidContentMode.review);

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
    approvedBy: 'סוקר/ת בדיקה',
    approvedOn: '2026-10-02',
  );

  /// The fingerprint an approval of [topic] would need.
  String fingerprintOf(Map<String, Object?> topic) =>
      parse(pack([topic])).unapprovedFingerprints[topic['id']]!;

  group('valid content', () {
    test('reads the pack and pending topics', () {
      final result = parse(pack([pendingTopic('a'), pendingTopic('b')]));

      expect(result.schemaVersion, 2);
      expect(result.contentVersion, 3);
      expect(result.locale, 'he');
      expect(result.publishedAt, DateTime.utc(2026, 10, 15));
      expect([for (final t in result.topics) t.id], ['a', 'b']);
      final topic = result.topicById('a')!;
      expect(topic.status, ContentStatus.pending);
      expect(topic.kind, FirstAidTopicKind.emergency);
      expect(topic.hasInstructions, isFalse);
      expect(topic.variants, isEmpty);
      expect(topic.sources, isEmpty);
      expect(topic.lastChecked, isNull);
      expect(result.unapprovedFingerprints, isEmpty);
      expect(result.topicById('missing'), isNull);
    });

    test('sources are optional for a pack of pending topics', () {
      final result = parse(pack([pendingTopic('a')])..remove('sources'));
      expect(result.topics.single.isVerified, isFalse);
    });

    test('the shipped app trusts no approvals yet', () {
      expect(FirstAidApprovals.trusted, isEmpty);
    });
  });

  group('rejects', () {
    test('text that is not JSON', () {
      expect(
        () => parse('{"schemaVersion": 2,'),
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
      expect(
        () => parse(pack([pendingTopic('a')])..['sources'] = ['s1']),
        throwsContentError(FirstAidContentError.malformed),
      );
    });

    test('an unsupported or missing schema version', () {
      for (final version in [1, 3]) {
        expect(
          () => parse(pack([pendingTopic('a')])..['schemaVersion'] = version),
          throwsContentError(FirstAidContentError.unsupportedSchema),
        );
      }
      expect(
        () => parse(pack([pendingTopic('a')])..remove('schemaVersion')),
        throwsContentError(FirstAidContentError.missingField),
      );
      expect(
        () => parse(pack([pendingTopic('a')])..['schemaVersion'] = '2'),
        throwsContentError(FirstAidContentError.invalidValue),
      );
    });

    test('another schema even if its other fields look broken', () {
      expect(
        () => parse({'schemaVersion': 3, 'something': 'else'}),
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

    for (final field in [
      'id',
      'publisher',
      'title',
      'url',
      'published',
      'accessedOn',
    ]) {
      test('a source without $field', () {
        expect(
          () => parse(
            pack([pendingTopic('a')])
              ..['sources'] = [source('s1')..remove(field)],
          ),
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
          ..['variants'] = [
            variant('v')
              ..['steps'] = [
                {'order': 2, 'text': 'שלב בדיקה'},
              ],
          ],
      ]),
      'a variant without steps': () => pack([
        verifiedTopic('a')..['variants'] = [variant('v')..['steps'] = []],
      ]),
      'a blank do-not item': () => pack([
        verifiedTopic('a')
          ..['variants'] = [
            variant('v')..['doNot'] = ['  '],
          ],
      ]),
      'a verification date in the future': () => pack([
        verifiedTopic('a')
          ..['verification'] = {
            'verifiedAt': '2026-10-16',
            'verifiedBy': 'סוקר/ת בדיקה',
          },
      ]),
      'a source checked in the future': () =>
          pack([pendingTopic('a')])
            ..['sources'] = [source('s1')..['accessedOn'] = '2026-10-16'],
      'a source publication date in another format': () =>
          pack([pendingTopic('a')])
            ..['sources'] = [source('s1')..['published'] = 'October 2025'],
    };
    invalidValues.forEach((name, build) {
      test(name, () {
        expect(
          () => parse(build()),
          throwsContentError(FirstAidContentError.invalidValue),
        );
      });
    });

    for (final url in [
      'http://example.org/test',
      'example.org/test',
      'https://',
    ]) {
      test('a source link that is not https: "$url"', () {
        expect(
          () => parse(
            pack([pendingTopic('a')])
              ..['sources'] = [source('s1')..['url'] = url],
          ),
          throwsContentError(FirstAidContentError.invalidValue),
        );
      });
    }

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
          pack([pendingTopic('a')])
            ..['sources'] = [source('s1')..['approved'] = true],
        ),
        throwsContentError(FirstAidContentError.unknownField),
      );
      expect(
        () => parse(
          pack([
            verifiedTopic('a')
              ..['variants'] = [variant('v')..['approvedBy'] = 'מישהו'],
          ]),
        ),
        throwsContentError(FirstAidContentError.unknownField),
      );
      // The v1 fields are gone.
      expect(
        () => parse(pack([verifiedTopic('a')..['callAdvice'] = 'טקסט'])),
        throwsContentError(FirstAidContentError.unknownField),
      );
    });

    test('duplicate topic, variant or source ids', () {
      expect(
        () => parse(pack([pendingTopic('a'), pendingTopic('a')])),
        throwsContentError(FirstAidContentError.duplicateId),
      );
      expect(
        () => parse(
          pack([
            verifiedTopic('a')..['variants'] = [variant('v'), variant('v')],
          ]),
        ),
        throwsContentError(FirstAidContentError.duplicateId),
      );
      expect(
        () => parse(
          pack([pendingTopic('a')])..['sources'] = [source('s1'), source('s1')],
        ),
        throwsContentError(FirstAidContentError.duplicateId),
      );
      expect(
        () => parse(
          pack([
            verifiedTopic('a')..['sourceIds'] = ['s1', 's1'],
          ]),
        ),
        throwsContentError(FirstAidContentError.duplicateId),
      );
    });

    test('a topic citing a source the file does not list', () {
      expect(
        () => parse(
          pack([
            verifiedTopic('a')..['sourceIds'] = ['missing'],
          ]),
        ),
        throwsContentError(FirstAidContentError.unknownSource),
      );
      expect(
        () => review(
          pack([
            draftTopic('a')..['sourceIds'] = ['missing'],
          ]),
        ),
        throwsContentError(FirstAidContentError.unknownSource),
      );
    });

    final pendingWithContent = <String, Object?>{
      'overview': 'הסבר בדיקה',
      'recognize': ['סימן בדיקה'],
      'callNow': ['הפניית בדיקה'],
      'variants': [variant('v')],
      'warnings': ['אזהרת בדיקה'],
      'afterCare': ['המשך בדיקה'],
      'sourceIds': ['s1'],
      'reviewNotes': ['שאלת בדיקה'],
      'verification': {
        'verifiedAt': '2026-10-01',
        'verifiedBy': 'סוקר/ת בדיקה',
      },
    };
    pendingWithContent.forEach((field, value) {
      test('a pending topic with $field entered by mistake', () {
        expect(
          () => parse(pack([pendingTopic('a')..[field] = value])),
          throwsContentError(FirstAidContentError.pendingWithInstructions),
        );
      });
    });

    for (final field in ['variants', 'sourceIds', 'callNow', 'verification']) {
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
  });

  group('drafts and review mode', () {
    test('the app content rejects drafts: a draft never reaches the app', () {
      expect(
        () => parse(pack([pendingTopic('a'), draftTopic('b')])),
        throwsContentError(FirstAidContentError.wrongContentMode),
      );
      // Even with an approval of the same wording.
      final draft = draftTopic('b')..remove('reviewNotes');
      expect(
        () => parse(
          pack([draft]),
          approvals: [approvalFor('b', fingerprintOf(verifiedTopic('b')))],
        ),
        throwsContentError(FirstAidContentError.wrongContentMode),
      );
    });

    test('the app content rejects review notes on a verified topic', () {
      expect(
        () => parse(
          pack([
            verifiedTopic('a')..['reviewNotes'] = ['שאלה'],
          ]),
        ),
        throwsContentError(FirstAidContentError.wrongContentMode),
      );
    });

    test('the review file reads drafts with their review notes', () {
      final result = review(pack([draftTopic('a'), pendingTopic('b')]));

      final topic = result.topicById('a')!;
      expect(topic.status, ContentStatus.draft);
      expect(topic.isDraft, isTrue);
      expect(topic.isVerified, isFalse);
      expect(topic.verification, isNull);
      expect(topic.overview, 'הסבר בדיקה');
      expect(topic.recognize, ['סימן בדיקה']);
      expect(topic.callNow, ['הפניית בדיקה']);
      expect([for (final v in topic.variants) v.id], ['first', 'second']);
      final first = topic.variants.first;
      expect(first.label, 'מצב בדיקה first');
      expect(first.appliesTo, 'קבוצת בדיקה');
      expect([for (final s in first.steps) s.order], [1, 2]);
      expect(first.steps[1].note, 'הערת בדיקה');
      expect(first.doNot, ['איסור בדיקה']);
      expect(topic.warnings, ['אזהרת בדיקה']);
      expect(topic.afterCare, ['המשך בדיקה']);
      expect(topic.sources.single.id, 's1');
      expect(topic.sources.single.url, Uri.parse('https://example.org/s1'));
      expect(topic.sources.single.published, '2025-10');
      expect(topic.sources.single.accessedOn, DateTime.utc(2026, 10, 1));
      expect(topic.lastChecked, DateTime.utc(2026, 10, 1));
      expect(topic.reviewNotes, ['שאלת בדיקה לסוקר']);
      expect(result.topicById('b')!.status, ContentStatus.pending);
      expect(result.unapprovedFingerprints, isEmpty);
    });

    test('the review file can never claim an approval', () {
      expect(
        () => review(pack([verifiedTopic('a')])),
        throwsContentError(FirstAidContentError.wrongContentMode),
      );
      expect(
        () => review(
          pack([
            draftTopic('a')
              ..['verification'] = {
                'verifiedAt': '2026-10-01',
                'verifiedBy': 'סוקר/ת בדיקה',
              },
          ]),
        ),
        throwsContentError(FirstAidContentError.wrongContentMode),
      );
    });

    test('approvals do not apply in the review file', () {
      final topic = verifiedTopic('a');
      final approvals = [approvalFor('a', fingerprintOf(topic))];
      expect(
        () => FirstAidContentParser(
          approvals: approvals,
          clock: () => today,
          mode: FirstAidContentMode.review,
        ).parse(jsonEncode(pack([topic]))),
        throwsContentError(FirstAidContentError.wrongContentMode),
      );
    });

    for (final field in ['variants', 'sourceIds', 'callNow']) {
      test('a draft without $field', () {
        expect(
          () => review(pack([draftTopic('a')..remove(field)])),
          throwsContentError(FirstAidContentError.incompleteVerification),
        );
      });
    }

    test('a general-information draft does not need call advice', () {
      final result = review(
        pack([
          draftTopic('a')
            ..['kind'] = 'generalInfo'
            ..remove('callNow'),
        ]),
      );
      expect(result.topics.single.isDraft, isTrue);
    });
  });

  group('sourced content', () {
    Map<String, Object?> sourcedTopic(String id) => contentTopic(id, 'sourced');

    test('is read with all its instructions and sources, never as '
        'verified', () {
      final result = parse(pack([sourcedTopic('a'), pendingTopic('b')]));

      final topic = result.topicById('a')!;
      expect(topic.status, ContentStatus.sourced);
      expect(topic.isSourced, isTrue);
      expect(topic.isPublished, isTrue);
      expect(topic.isVerified, isFalse);
      expect(topic.verification, isNull);
      expect([for (final v in topic.variants) v.id], ['first', 'second']);
      expect(topic.callNow, ['הפניית בדיקה']);
      expect(topic.sources.single.id, 's1');
      expect(topic.reviewNotes, isEmpty);
      expect(result.topicById('b')!.isPublished, isFalse);
      expect(result.unapprovedFingerprints, isEmpty);
    });

    for (final field in ['variants', 'sourceIds', 'callNow']) {
      test('is refused without $field: no instructions without a source', () {
        expect(
          () => parse(pack([sourcedTopic('a')..remove(field)])),
          throwsContentError(FirstAidContentError.incompleteVerification),
        );
      });
    }

    test('is refused when it cites a source the file does not list', () {
      expect(
        () => parse(
          pack([
            sourcedTopic('a')..['sourceIds'] = ['missing'],
          ]),
        ),
        throwsContentError(FirstAidContentError.unknownSource),
      );
      expect(
        () => parse(pack([sourcedTopic('a')])..remove('sources')),
        throwsContentError(FirstAidContentError.unknownSource),
      );
    });

    test('can never claim a reviewer or carry review notes', () {
      expect(
        () => parse(
          pack([
            sourcedTopic('a')
              ..['verification'] = {
                'verifiedAt': '2026-10-01',
                'verifiedBy': 'סוקר/ת בדיקה',
              },
          ]),
        ),
        throwsContentError(FirstAidContentError.wrongContentMode),
      );
      expect(
        () => parse(
          pack([
            sourcedTopic('a')..['reviewNotes'] = ['שאלה'],
          ]),
        ),
        throwsContentError(FirstAidContentError.wrongContentMode),
      );
    });

    test('is not accepted in the review file', () {
      expect(
        () => review(pack([sourcedTopic('a')])),
        throwsContentError(FirstAidContentError.wrongContentMode),
      );
    });

    test('an approval does not turn it into verified content', () {
      final hash = fingerprintOf(verifiedTopic('a'));
      final result = parse(
        pack([sourcedTopic('a')]),
        approvals: [approvalFor('a', hash)],
      );
      expect(result.topicById('a')!.isVerified, isFalse);
      expect(result.topicById('a')!.isSourced, isTrue);
    });

    test('has the same review fingerprint as the draft of the same '
        'wording', () {
      final sourced = parse(pack([sourcedTopic('a')])).topics.single;
      final draft = review(pack([draftTopic('a')])).topics.single;
      expect(
        FirstAidContentParser.reviewFingerprint(sourced),
        FirstAidContentParser.reviewFingerprint(draft),
      );
    });

    test('a verified claim without approval falls back to pending, not to '
        'sourced', () {
      final result = parse(pack([verifiedTopic('a')]));
      expect(result.topicById('a')!.status, ContentStatus.pending);
      expect(result.topicById('a')!.hasInstructions, isFalse);
    });
  });

  group('approval of verified content', () {
    test('"verified" in the file alone is not enough: the topic stays '
        'pending, without its instructions', () {
      final result = parse(pack([verifiedTopic('a')]));

      final topic = result.topicById('a')!;
      expect(topic.status, ContentStatus.pending);
      expect(topic.isVerified, isFalse);
      expect(topic.hasInstructions, isFalse);
      expect(topic.variants, isEmpty);
      expect(topic.sources, isEmpty);
      expect(topic.verification, isNull);
      expect(result.unapprovedFingerprints.keys, ['a']);
      expect(result.unapprovedFingerprints['a'], matches(r'^[0-9a-f]{64}$'));
    });

    test('a trusted approval of that exact content makes it verified', () {
      final result = parse(
        pack([verifiedTopic('a')]),
        approvals: [approvalFor('a', fingerprintOf(verifiedTopic('a')))],
      );

      final topic = result.topicById('a')!;
      expect(topic.status, ContentStatus.verified);
      expect([for (final v in topic.variants) v.id], ['first', 'second']);
      expect(topic.variants.first.steps[1].note, 'הערת בדיקה');
      expect(topic.callNow, ['הפניית בדיקה']);
      expect(topic.sources.single.url, Uri.parse('https://example.org/s1'));
      expect(topic.verification!.verifiedAt, DateTime.utc(2026, 10, 1));
      expect(topic.verification!.verifiedBy, 'סוקר/ת בדיקה');
      expect(topic.reviewNotes, isEmpty);
      expect(result.unapprovedFingerprints, isEmpty);
    });

    test('the approval matches the published fingerprint of the topic', () {
      final hash = fingerprintOf(verifiedTopic('a'));
      final topic = parse(
        pack([verifiedTopic('a')]),
        approvals: [approvalFor('a', hash)],
      ).topics.single;
      expect(FirstAidContentParser.publishedFingerprint(topic), hash);
      // The review fingerprint leaves out the verification, so it differs.
      expect(FirstAidContentParser.reviewFingerprint(topic), isNot(hash));
    });

    test('the review fingerprint of a draft is the same wording once it is '
        'published, and ignores review notes', () {
      final draft = review(pack([draftTopic('a')])).topics.single;
      final withOtherNotes = review(
        pack([
          draftTopic('a')..['reviewNotes'] = ['שאלה אחרת'],
        ]),
      ).topics.single;
      final published = parse(
        pack([verifiedTopic('a')]),
        approvals: [approvalFor('a', fingerprintOf(verifiedTopic('a')))],
      ).topics.single;

      expect(
        FirstAidContentParser.reviewFingerprint(draft),
        FirstAidContentParser.reviewFingerprint(published),
      );
      expect(
        FirstAidContentParser.reviewFingerprint(draft),
        FirstAidContentParser.reviewFingerprint(withOtherNotes),
      );
    });

    test('any change after approval voids it', () {
      final approvals = [approvalFor('a', fingerprintOf(verifiedTopic('a')))];

      final changes = <String, void Function(Map<String, Object?>)>{
        'a step': (t) => t['variants'] = [
          variant('first')
            ..['steps'] = [
              {'order': 1, 'text': 'שלב בדיקה א!'},
              {'order': 2, 'text': 'שלב בדיקה ב', 'note': 'הערת בדיקה'},
            ],
          variant('second'),
        ],
        'a step note': (t) => t['variants'] = [
          variant('first')
            ..['steps'] = [
              {'order': 1, 'text': 'שלב בדיקה א'},
              {'order': 2, 'text': 'שלב בדיקה ב'},
            ],
          variant('second'),
        ],
        'the variant order': (t) =>
            t['variants'] = [variant('second'), variant('first')],
        'a removed variant': (t) => t['variants'] = [variant('first')],
        'a variant label': (t) => t['variants'] = [
          variant('first')..['label'] = 'תווית אחרת',
          variant('second'),
        ],
        'a do-not item': (t) => t['variants'] = [
          variant('first')..['doNot'] = <String>[],
          variant('second'),
        ],
        'the overview': (t) => t['overview'] = 'הסבר אחר',
        'the call advice': (t) => t['callNow'] = ['הפניה אחרת'],
        'a warning': (t) => t['warnings'] = ['אזהרה אחרת'],
        'the after-care': (t) => t['afterCare'] = ['המשך אחר'],
        'the cited source': (t) => t['sourceIds'] = ['s2'],
        'the reviewer': (t) => t['verification'] = {
          'verifiedAt': '2026-10-01',
          'verifiedBy': 'מישהו אחר',
        },
        'the verification date': (t) => t['verification'] = {
          'verifiedAt': '2026-10-02',
          'verifiedBy': 'סוקר/ת בדיקה',
        },
        'the title': (t) => t['title'] = 'כותרת אחרת',
        'the kind': (t) => t['kind'] = 'generalInfo',
      };
      changes.forEach((name, change) {
        final topic = verifiedTopic('a');
        change(topic);
        final result = parse(pack([topic]), approvals: approvals);
        expect(result.topicById('a')!.isVerified, isFalse, reason: name);
        expect(result.topicById('a')!.hasInstructions, isFalse, reason: name);
        expect(result.unapprovedFingerprints.keys, ['a'], reason: name);
      });
    });

    test('a change to a cited source entry voids the approval', () {
      final approvals = [approvalFor('a', fingerprintOf(verifiedTopic('a')))];
      for (final change in <String, Object>{
        'url': 'https://example.org/changed',
        'title': 'כותרת אחרת',
        'published': '2025-11',
        'accessedOn': '2026-10-02',
      }.entries) {
        final changed = pack([verifiedTopic('a')])
          ..['sources'] = [source('s1')..[change.key] = change.value];
        final result = parse(changed, approvals: approvals);
        expect(result.topicById('a')!.isVerified, isFalse, reason: change.key);
      }
    });

    test('an approval for another topic or language does not count', () {
      final fingerprint = fingerprintOf(verifiedTopic('a'));

      for (final approval in [
        approvalFor('b', fingerprint),
        approvalFor('a', fingerprint, locale: 'en'),
        approvalFor('a', fingerprint.toUpperCase()),
        approvalFor('a', fingerprint.substring(1)),
      ]) {
        final result = parse(pack([verifiedTopic('a')]), approvals: [approval]);
        expect(result.topicById('a')!.isVerified, isFalse);
      }
    });

    test('an approval of the review fingerprint is not enough', () {
      final draft = review(pack([draftTopic('a')])).topics.single;
      final result = parse(
        pack([verifiedTopic('a')]),
        approvals: [
          approvalFor('a', FirstAidContentParser.reviewFingerprint(draft)),
        ],
      );
      expect(result.topicById('a')!.isVerified, isFalse);
    });

    test('approving one topic leaves the others pending', () {
      final result = parse(
        pack([verifiedTopic('a'), verifiedTopic('b')]),
        approvals: [approvalFor('a', fingerprintOf(verifiedTopic('a')))],
      );
      expect(result.topicById('a')!.isVerified, isTrue);
      expect(result.topicById('b')!.isVerified, isFalse);
      expect(result.unapprovedFingerprints.keys, ['b']);
    });

    test('a general-information topic does not need call advice', () {
      final topic = verifiedTopic('a')
        ..['kind'] = 'generalInfo'
        ..remove('callNow');

      final result = parse(
        pack([topic]),
        approvals: [approvalFor('a', fingerprintOf(topic))],
      );
      expect(result.topicById('a')!.isVerified, isTrue);
      expect(result.topicById('a')!.kind, FirstAidTopicKind.generalInfo);
    });
  });

  group('models', () {
    FirstAidTopic topic(
      ContentStatus status, {
      List<GuideVariant>? variants,
      List<ContentSource>? sources,
      ContentVerification? verification,
      List<String> reviewNotes = const [],
      List<String> callNow = const ['הפניה'],
    }) => FirstAidTopic(
      id: 'a',
      kind: FirstAidTopicKind.emergency,
      title: 'נושא',
      summary: 'תיאור',
      status: status,
      callNow: callNow,
      variants:
          variants ??
          [
            GuideVariant(
              id: 'v',
              label: 'מצב',
              steps: [GuideStep(order: 1, text: 'שלב')],
            ),
          ],
      sources:
          sources ??
          [
            ContentSource(
              id: 's',
              publisher: 'מפרסם',
              title: 'מסמך',
              url: Uri.parse('https://example.org'),
              published: '2025',
              accessedOn: DateTime.utc(2026, 10, 1),
            ),
          ],
      verification: verification,
      reviewNotes: reviewNotes,
    );

    final verification = ContentVerification(
      verifiedAt: DateTime.utc(2026, 10, 1),
      verifiedBy: 'סוקר/ת',
    );

    test('a pending topic can never hold instructions', () {
      expect(
        () => FirstAidTopic(
          id: 'a',
          kind: FirstAidTopicKind.emergency,
          title: 'נושא',
          summary: 'תיאור',
          status: ContentStatus.pending,
          warnings: ['אזהרה'],
        ),
        throwsArgumentError,
      );
    });

    test('a draft needs instructions and sources and never an approval', () {
      expect(topic(ContentStatus.draft).isDraft, isTrue);
      expect(
        () => topic(ContentStatus.draft, variants: []),
        throwsArgumentError,
      );
      expect(
        () => topic(ContentStatus.draft, sources: []),
        throwsArgumentError,
      );
      expect(
        () => topic(ContentStatus.draft, verification: verification),
        throwsArgumentError,
      );
    });

    test('a verified topic needs everything, and no review notes', () {
      expect(
        topic(ContentStatus.verified, verification: verification).isVerified,
        isTrue,
      );
      expect(() => topic(ContentStatus.verified), throwsArgumentError);
      expect(
        () => topic(
          ContentStatus.verified,
          verification: verification,
          reviewNotes: ['שאלה'],
        ),
        throwsArgumentError,
      );
      expect(
        () => topic(
          ContentStatus.verified,
          verification: verification,
          callNow: [],
        ),
        throwsArgumentError,
      );
    });

    test('a sourced topic needs everything, and no approval or notes', () {
      expect(topic(ContentStatus.sourced).isPublished, isTrue);
      expect(topic(ContentStatus.sourced).isVerified, isFalse);
      expect(
        () => topic(ContentStatus.sourced, variants: []),
        throwsArgumentError,
      );
      expect(
        () => topic(ContentStatus.sourced, sources: []),
        throwsArgumentError,
      );
      expect(
        () => topic(ContentStatus.sourced, callNow: []),
        throwsArgumentError,
      );
      expect(
        () => topic(ContentStatus.sourced, verification: verification),
        throwsArgumentError,
      );
      expect(
        () => topic(ContentStatus.sourced, reviewNotes: ['שאלה']),
        throwsArgumentError,
      );
    });

    test('a variant needs steps and a unique id', () {
      expect(
        () => GuideVariant(id: 'v', label: 'מצב', steps: []),
        throwsArgumentError,
      );
      final v = GuideVariant(
        id: 'v',
        label: 'מצב',
        steps: [GuideStep(order: 1, text: 'שלב')],
      );
      expect(
        () => topic(ContentStatus.draft, variants: [v, v]),
        throwsArgumentError,
      );
    });

    test('a source must be an https link', () {
      expect(
        () => ContentSource(
          id: 's',
          publisher: 'מקור',
          title: 'מסמך',
          url: Uri.parse('http://example.org'),
          published: '2025',
          accessedOn: DateTime.utc(2026, 10, 1),
        ),
        throwsArgumentError,
      );
    });

    test('lists are unmodifiable', () {
      final result = review(pack([draftTopic('a')]));
      final t = result.topics.single;
      expect(() => result.topics.clear(), throwsUnsupportedError);
      expect(() => t.variants.clear(), throwsUnsupportedError);
      expect(() => t.variants.first.steps.clear(), throwsUnsupportedError);
      expect(() => t.sources.clear(), throwsUnsupportedError);
      expect(() => t.reviewNotes.clear(), throwsUnsupportedError);
    });

    test('toString never includes content', () {
      final t = review(pack([draftTopic('a')])).topics.single;
      expect(t.toString(), 'FirstAidTopic(a, draft)');
    });
  });
}
