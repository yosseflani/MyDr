import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:mydr/data/first_aid/content_approvals.dart';
import 'package:mydr/data/models/first_aid_content.dart';

/// Why first-aid content could not be used.
enum FirstAidContentError {
  /// The content file could not be read.
  unavailable,

  /// Not valid JSON, or not the expected structure.
  malformed,

  /// Written for a schema version this app does not support.
  unsupportedSchema,

  /// A required field is missing.
  missingField,

  /// A field has the wrong type or an invalid value.
  invalidValue,

  /// A field this schema does not define, e.g. a misspelled name.
  unknownField,

  /// Two topics, variants or sources share an id.
  duplicateId,

  /// A topic refers to a source the file does not list.
  unknownSource,

  /// A pending topic contains instructions, sources or review notes.
  pendingWithInstructions,

  /// A sourced, verified or draft topic lacks something it requires.
  incompleteVerification,

  /// Draft content, or review notes, in the app's published content; or an
  /// approval claimed in the review file.
  wrongContentMode,
}

class FirstAidContentException implements Exception {
  const FirstAidContentException(this.error, this.detail);

  final FirstAidContentError error;

  /// Where the problem is, e.g. "topics[2].variants[0].steps[1]". For
  /// developers only; never shown to users.
  final String detail;

  @override
  String toString() => 'FirstAidContentException(${error.name}: $detail)';
}

/// Which content file is being read.
enum FirstAidContentMode {
  /// The app's content (assets/first_aid/he.json): pending, sourced, or
  /// approved verified topics. Drafts reject the whole file.
  published,

  /// The review file (assets/first_aid/review/): pending or draft topics,
  /// with review notes. Never verified. Shown only in the developer review
  /// preview.
  review,
}

/// Reads a first-aid content file (schema version 2) and checks it strictly.
///
/// Sourced topics are kept as they are: complete instructions with cited
/// sources, never counted as verified.
///
/// Fails closed: anything unexpected rejects the whole file rather than
/// showing content that may be wrong. A topic counts as verified only if the
/// file says so, its content and verification are complete, and a trusted
/// [ContentApproval] matches its exact content (see [publishedFingerprint]).
/// Otherwise it is kept as pending, without any instructions.
class FirstAidContentParser {
  const FirstAidContentParser({
    this.approvals = FirstAidApprovals.trusted,
    this.clock = DateTime.now,
    this.mode = FirstAidContentMode.published,
  });

  static const int supportedSchemaVersion = 2;

  final List<ContentApproval> approvals;
  final DateTime Function() clock;
  final FirstAidContentMode mode;

  static const _packKeys = {
    'schemaVersion',
    'contentVersion',
    'locale',
    'publishedAt',
    'sources',
    'topics',
  };
  static const _sourceKeys = {
    'id',
    'publisher',
    'title',
    'url',
    'published',
    'accessedOn',
  };
  static const _topicKeys = {
    'id',
    'kind',
    'status',
    'title',
    'summary',
    'overview',
    'recognize',
    'callNow',
    'variants',
    'warnings',
    'afterCare',
    'sourceIds',
    'reviewNotes',
    'verification',
  };
  static const _variantKeys = {'id', 'label', 'appliesTo', 'steps', 'doNot'};
  static const _stepKeys = {'order', 'text', 'note'};
  static const _verificationKeys = {'verifiedAt', 'verifiedBy'};

  static final RegExp _localePattern = RegExp(r'^[a-z]{2,3}$');
  static final RegExp _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');
  static final RegExp _publishedPattern = RegExp(r'^\d{4}-\d{2}(-\d{2})?$');

  /// Throws a [FirstAidContentException] if [source] cannot be used.
  FirstAidContentPack parse(String source) {
    final Object? decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException catch (e) {
      throw FirstAidContentException(
        FirstAidContentError.malformed,
        'not JSON: ${e.message}',
      );
    }
    if (decoded is! Map<String, Object?>) {
      throw const FirstAidContentException(
        FirstAidContentError.malformed,
        'the file must be a JSON object',
      );
    }
    final pack = _Fields(decoded, '');

    // Checked first: another schema may differ in every other field.
    final schemaVersion = pack.integer('schemaVersion');
    if (schemaVersion != supportedSchemaVersion) {
      throw FirstAidContentException(
        FirstAidContentError.unsupportedSchema,
        'schemaVersion $schemaVersion, supported: $supportedSchemaVersion',
      );
    }
    pack.onlyKeys(_packKeys);

    final contentVersion = pack.integer('contentVersion');
    if (contentVersion < 1) pack.invalid('contentVersion', 'must be >= 1');
    final locale = pack.string('locale');
    if (!_localePattern.hasMatch(locale)) {
      pack.invalid('locale', 'must be a language code, e.g. "he"');
    }
    final publishedAt = _date(pack, 'publishedAt');
    final sources = _sources(pack);

    final rawTopics = pack.list('topics');
    if (rawTopics.isEmpty) pack.invalid('topics', 'must not be empty');

    final topics = <FirstAidTopic>[];
    final unapproved = <String, String>{};
    final ids = <String>{};
    for (final (index, raw) in rawTopics.indexed) {
      final fields = _Fields.of(raw, 'topics[$index]');
      final (topic, unapprovedFingerprint) = _topic(fields, locale, sources);
      if (!ids.add(topic.id)) {
        throw FirstAidContentException(
          FirstAidContentError.duplicateId,
          'topics[$index].id "${topic.id}"',
        );
      }
      if (unapprovedFingerprint != null) {
        unapproved[topic.id] = unapprovedFingerprint;
      }
      topics.add(topic);
    }

    return FirstAidContentPack(
      schemaVersion: schemaVersion,
      contentVersion: contentVersion,
      locale: locale,
      publishedAt: publishedAt,
      topics: topics,
      unapprovedFingerprints: unapproved,
    );
  }

  /// SHA-256 (lower case hex) of a canonical JSON form of [content].
  static String fingerprint(Map<String, Object?> content) =>
      sha256.convert(utf8.encode(jsonEncode(content))).toString();

  /// The fingerprint a [ContentApproval] must match: everything shown to
  /// users, including the verification. Never includes review notes.
  static String publishedFingerprint(FirstAidTopic topic) =>
      fingerprint(canonicalContent(topic, includeVerification: true));

  /// Identifies the exact reviewed wording of a draft: everything shown to
  /// users, without the verification (which is added on approval) and
  /// without review notes.
  static String reviewFingerprint(FirstAidTopic topic) =>
      fingerprint(canonicalContent(topic, includeVerification: false));

  static Map<String, Object?> canonicalContent(
    FirstAidTopic topic, {
    required bool includeVerification,
  }) {
    final verification = topic.verification;
    return {
      'id': topic.id,
      'kind': topic.kind.name,
      'title': topic.title,
      'summary': topic.summary,
      'overview': topic.overview,
      'recognize': topic.recognize,
      'callNow': topic.callNow,
      'variants': [
        for (final variant in topic.variants)
          {
            'id': variant.id,
            'label': variant.label,
            'appliesTo': variant.appliesTo,
            'steps': [
              for (final step in variant.steps)
                {'order': step.order, 'text': step.text, 'note': step.note},
            ],
            'doNot': variant.doNot,
          },
      ],
      'warnings': topic.warnings,
      'afterCare': topic.afterCare,
      'sources': [
        for (final source in topic.sources)
          {
            'id': source.id,
            'publisher': source.publisher,
            'title': source.title,
            'url': source.url.toString(),
            'published': source.published,
            'accessedOn': formatDate(source.accessedOn),
          },
      ],
      if (includeVerification)
        'verification': verification == null
            ? null
            : {
                'verifiedAt': formatDate(verification.verifiedAt),
                'verifiedBy': verification.verifiedBy,
              },
    };
  }

  static String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  Map<String, ContentSource> _sources(_Fields pack) {
    final sources = <String, ContentSource>{};
    for (final (i, raw) in pack.optionalList('sources').indexed) {
      final fields = _Fields.of(raw, 'sources[$i]')..onlyKeys(_sourceKeys);
      final id = fields.string('id');
      if (!FirstAidTopic.idPattern.hasMatch(id)) {
        fields.invalid('id', 'lower case letters, digits and "_" only');
      }
      final url = Uri.tryParse(fields.string('url'));
      if (url == null || url.scheme != 'https' || url.host.isEmpty) {
        throw FirstAidContentException(
          FirstAidContentError.invalidValue,
          '${fields.path}.url must be an https link',
        );
      }
      final published = fields.string('published');
      if (!_publishedPattern.hasMatch(published)) {
        fields.invalid('published', 'must be like 2025-10-27 or 2024-08');
      }
      final accessedOn = _date(fields, 'accessedOn');
      _notInFuture(fields, 'accessedOn', accessedOn);
      if (sources.containsKey(id)) {
        throw FirstAidContentException(
          FirstAidContentError.duplicateId,
          '${fields.path}.id "$id"',
        );
      }
      sources[id] = ContentSource(
        id: id,
        publisher: fields.string('publisher'),
        title: fields.string('title'),
        url: url,
        published: published,
        accessedOn: accessedOn,
      );
    }
    return sources;
  }

  /// Returns the topic and, if the file claims it is verified but no trusted
  /// approval matches, the fingerprint an approval would need.
  (FirstAidTopic, String?) _topic(
    _Fields fields,
    String locale,
    Map<String, ContentSource> allSources,
  ) {
    fields.onlyKeys(_topicKeys);
    final id = fields.string('id');
    if (!FirstAidTopic.idPattern.hasMatch(id)) {
      fields.invalid('id', 'lower case letters, digits and "_" only');
    }
    final kind = fields.choice('kind', FirstAidTopicKind.values);
    final declared = fields.choice('status', ContentStatus.values);
    final title = fields.string('title');
    final summary = fields.string('summary');
    final overview = fields.optionalString('overview');
    final recognize = fields.textList('recognize');
    final callNow = fields.textList('callNow');
    final variants = _variants(fields);
    final warnings = fields.textList('warnings');
    final afterCare = fields.textList('afterCare');
    final reviewNotes = fields.textList('reviewNotes');
    final verification = _verification(fields);

    final sourceIds = fields.textList('sourceIds');
    final sources = <ContentSource>[];
    for (final (i, sourceId) in sourceIds.indexed) {
      final source = allSources[sourceId];
      if (source == null) {
        throw FirstAidContentException(
          FirstAidContentError.unknownSource,
          '${fields.path}.sourceIds[$i] "$sourceId"',
        );
      }
      if (sources.contains(source)) {
        throw FirstAidContentException(
          FirstAidContentError.duplicateId,
          '${fields.path}.sourceIds[$i] "$sourceId"',
        );
      }
      sources.add(source);
    }

    final hasInstructions =
        overview != null ||
        recognize.isNotEmpty ||
        callNow.isNotEmpty ||
        variants.isNotEmpty ||
        warnings.isNotEmpty ||
        afterCare.isNotEmpty;

    FirstAidTopic pending() => FirstAidTopic(
      id: id,
      kind: kind,
      title: title,
      summary: summary,
      status: ContentStatus.pending,
    );

    FirstAidTopic withContent(ContentStatus status) => FirstAidTopic(
      id: id,
      kind: kind,
      title: title,
      summary: summary,
      status: status,
      overview: overview,
      recognize: recognize,
      callNow: callNow,
      variants: variants,
      warnings: warnings,
      afterCare: afterCare,
      sources: sources,
      reviewNotes: reviewNotes,
      verification: verification,
    );

    void requireComplete(String what) {
      final missing = [
        if (variants.isEmpty) 'variants',
        if (sources.isEmpty) 'sourceIds',
        if (kind == FirstAidTopicKind.emergency && callNow.isEmpty) 'callNow',
      ];
      if (missing.isNotEmpty) {
        throw FirstAidContentException(
          FirstAidContentError.incompleteVerification,
          '${fields.path} ("$id") is $what but lacks ${missing.join(', ')}',
        );
      }
    }

    switch (declared) {
      case ContentStatus.pending:
        if (hasInstructions ||
            sources.isNotEmpty ||
            reviewNotes.isNotEmpty ||
            verification != null) {
          throw FirstAidContentException(
            FirstAidContentError.pendingWithInstructions,
            '${fields.path} ("$id") is pending but has content',
          );
        }
        return (pending(), null);

      case ContentStatus.draft:
        if (mode == FirstAidContentMode.published) {
          throw FirstAidContentException(
            FirstAidContentError.wrongContentMode,
            '${fields.path} ("$id") is a draft in published content',
          );
        }
        if (verification != null) {
          throw FirstAidContentException(
            FirstAidContentError.wrongContentMode,
            '${fields.path} ("$id") is a draft with a verification',
          );
        }
        requireComplete('a draft');
        return (withContent(ContentStatus.draft), null);

      case ContentStatus.sourced:
        if (mode == FirstAidContentMode.review) {
          throw FirstAidContentException(
            FirstAidContentError.wrongContentMode,
            '${fields.path} ("$id") is sourced content in the review file',
          );
        }
        if (reviewNotes.isNotEmpty) {
          throw FirstAidContentException(
            FirstAidContentError.wrongContentMode,
            '${fields.path} ("$id") has review notes in published content',
          );
        }
        // Only an approval can add a reviewer; sourced content never has one.
        if (verification != null) {
          throw FirstAidContentException(
            FirstAidContentError.wrongContentMode,
            '${fields.path} ("$id") is sourced but claims a verification',
          );
        }
        requireComplete('sourced');
        return (withContent(ContentStatus.sourced), null);

      case ContentStatus.verified:
        if (mode == FirstAidContentMode.review) {
          throw FirstAidContentException(
            FirstAidContentError.wrongContentMode,
            '${fields.path} ("$id") claims approval in the review file',
          );
        }
        if (reviewNotes.isNotEmpty) {
          throw FirstAidContentException(
            FirstAidContentError.wrongContentMode,
            '${fields.path} ("$id") has review notes in published content',
          );
        }
        requireComplete('marked verified');
        if (verification == null) {
          throw FirstAidContentException(
            FirstAidContentError.incompleteVerification,
            '${fields.path} ("$id") is marked verified but lacks verification',
          );
        }
        final claimed = withContent(ContentStatus.verified);
        final hash = publishedFingerprint(claimed);
        final approved = approvals.any(
          (a) =>
              a.topicId == id && a.locale == locale && a.contentSha256 == hash,
        );
        // Claimed but not approved: keep the topic, never its instructions.
        return approved ? (claimed, null) : (pending(), hash);
    }
  }

  List<GuideVariant> _variants(_Fields fields) {
    final variants = <GuideVariant>[];
    final ids = <String>{};
    for (final (i, raw) in fields.optionalList('variants').indexed) {
      final variant = _Fields.of(raw, '${fields.path}.variants[$i]')
        ..onlyKeys(_variantKeys);
      final id = variant.string('id');
      if (!FirstAidTopic.idPattern.hasMatch(id)) {
        variant.invalid('id', 'lower case letters, digits and "_" only');
      }
      if (!ids.add(id)) {
        throw FirstAidContentException(
          FirstAidContentError.duplicateId,
          '${variant.path}.id "$id"',
        );
      }
      final steps = <GuideStep>[];
      final rawSteps = variant.list('steps');
      if (rawSteps.isEmpty) variant.invalid('steps', 'must not be empty');
      for (final (j, item) in rawSteps.indexed) {
        final step = _Fields.of(item, '${variant.path}.steps[$j]')
          ..onlyKeys(_stepKeys);
        final order = step.integer('order');
        if (order != j + 1) {
          step.invalid('order', 'steps must be numbered 1, 2, 3… in order');
        }
        steps.add(
          GuideStep(
            order: order,
            text: step.string('text'),
            note: step.optionalString('note'),
          ),
        );
      }
      variants.add(
        GuideVariant(
          id: id,
          label: variant.string('label'),
          appliesTo: variant.optionalString('appliesTo'),
          steps: steps,
          doNot: variant.textList('doNot'),
        ),
      );
    }
    return variants;
  }

  ContentVerification? _verification(_Fields fields) {
    final verification = fields.optionalObject('verification');
    if (verification == null) return null;
    verification.onlyKeys(_verificationKeys);
    final verifiedAt = _date(verification, 'verifiedAt');
    _notInFuture(verification, 'verifiedAt', verifiedAt);
    return ContentVerification(
      verifiedAt: verifiedAt,
      verifiedBy: verification.string('verifiedBy'),
    );
  }

  void _notInFuture(_Fields fields, String key, DateTime date) {
    final now = clock();
    if (date.isAfter(DateTime.utc(now.year, now.month, now.day))) {
      fields.invalid(key, 'is in the future');
    }
  }

  /// A strict "yyyy-mm-dd" calendar date, as UTC midnight.
  DateTime _date(_Fields fields, String key) {
    final text = fields.string(key);
    final match = _datePattern.firstMatch(text);
    if (match != null) {
      final date = DateTime.utc(
        int.parse(match[1]!),
        int.parse(match[2]!),
        int.parse(match[3]!),
      );
      if (formatDate(date) == text) return date;
    }
    fields.invalid(key, 'must be a date like 2026-10-15');
  }
}

/// Typed, path-aware access to one JSON object's fields.
class _Fields {
  _Fields(this._map, this.path);

  factory _Fields.of(Object? value, String path) {
    if (value is! Map<String, Object?>) {
      throw FirstAidContentException(
        FirstAidContentError.malformed,
        '$path must be a JSON object',
      );
    }
    return _Fields(value, path);
  }

  final Map<String, Object?> _map;
  final String path;

  String _at(String key) => path.isEmpty ? key : '$path.$key';

  Never invalid(String key, String reason) => throw FirstAidContentException(
    FirstAidContentError.invalidValue,
    '${_at(key)} $reason',
  );

  void onlyKeys(Set<String> allowed) {
    for (final key in _map.keys) {
      if (!allowed.contains(key)) {
        throw FirstAidContentException(
          FirstAidContentError.unknownField,
          _at(key),
        );
      }
    }
  }

  Object _required(String key) {
    final value = _map[key];
    if (value == null) {
      throw FirstAidContentException(
        FirstAidContentError.missingField,
        _at(key),
      );
    }
    return value;
  }

  String string(String key) => _nonEmptyString(_required(key), _at(key));

  String? optionalString(String key) => _map[key] == null ? null : string(key);

  static String _nonEmptyString(Object? value, String path) {
    if (value is! String || value.trim().isEmpty) {
      throw FirstAidContentException(
        FirstAidContentError.invalidValue,
        '$path must be non-empty text',
      );
    }
    return value;
  }

  int integer(String key) {
    final value = _required(key);
    if (value is! int) invalid(key, 'must be a whole number');
    return value;
  }

  T choice<T extends Enum>(String key, List<T> values) {
    final value = string(key);
    for (final option in values) {
      if (option.name == value) return option;
    }
    invalid(key, 'must be one of ${values.map((v) => v.name).join(', ')}');
  }

  List<Object?> list(String key) {
    final value = _required(key);
    if (value is! List<Object?>) invalid(key, 'must be a list');
    return value;
  }

  List<Object?> optionalList(String key) =>
      _map[key] == null ? const [] : list(key);

  /// An optional list of non-empty texts.
  List<String> textList(String key) => [
    for (final (i, item) in optionalList(key).indexed)
      _nonEmptyString(item, '${_at(key)}[$i]'),
  ];

  _Fields? optionalObject(String key) =>
      _map[key] == null ? null : _Fields.of(_map[key], _at(key));
}
