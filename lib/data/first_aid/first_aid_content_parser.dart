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

  /// Two topics share an id.
  duplicateTopicId,

  /// A pending topic contains steps, warnings or call advice.
  pendingWithInstructions,

  /// A topic marked verified lacks its steps, source or verification.
  incompleteVerification,
}

class FirstAidContentException implements Exception {
  const FirstAidContentException(this.error, this.detail);

  final FirstAidContentError error;

  /// Where the problem is, e.g. "topics[2].source.url". For developers only;
  /// never shown to users.
  final String detail;

  @override
  String toString() => 'FirstAidContentException(${error.name}: $detail)';
}

/// Reads a first-aid content file and checks it strictly.
///
/// Fails closed: anything unexpected rejects the whole file rather than
/// showing content that may be wrong. A topic counts as verified only if the
/// file says so, its verification details are complete, and a trusted
/// [ContentApproval] matches its exact content (see [fingerprint]).
/// Otherwise it is kept as pending, without any instructions.
class FirstAidContentParser {
  const FirstAidContentParser({
    this.approvals = FirstAidApprovals.trusted,
    this.clock = DateTime.now,
  });

  static const int supportedSchemaVersion = 1;

  final List<ContentApproval> approvals;
  final DateTime Function() clock;

  static const _packKeys = {
    'schemaVersion',
    'contentVersion',
    'locale',
    'publishedAt',
    'topics',
  };
  static const _topicKeys = {
    'id',
    'kind',
    'status',
    'title',
    'summary',
    'callAdvice',
    'steps',
    'warnings',
    'source',
    'verification',
  };
  static const _stepKeys = {'order', 'text', 'note'};
  static const _sourceKeys = {'publisher', 'title', 'url'};
  static const _verificationKeys = {'verifiedAt', 'verifiedBy'};

  static final RegExp _localePattern = RegExp(r'^[a-z]{2,3}$');
  static final RegExp _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

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

    // Checked first: a newer schema may differ in every other field.
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

    final rawTopics = pack.list('topics');
    if (rawTopics.isEmpty) pack.invalid('topics', 'must not be empty');

    final topics = <FirstAidTopic>[];
    final unapproved = <String, String>{};
    final ids = <String>{};
    for (final (index, raw) in rawTopics.indexed) {
      final fields = _Fields.of(raw, 'topics[$index]');
      final (topic, unapprovedFingerprint) = _topic(fields, locale);
      if (!ids.add(topic.id)) {
        throw FirstAidContentException(
          FirstAidContentError.duplicateTopicId,
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

  /// The fingerprint a [ContentApproval] must match: SHA-256 (lower case
  /// hex) of a canonical JSON form of everything shown to users.
  static String fingerprint(Map<String, Object?> canonicalContent) =>
      sha256.convert(utf8.encode(jsonEncode(canonicalContent))).toString();

  /// Returns the topic and, if the file claims it is verified but no trusted
  /// approval matches, the fingerprint an approval would need.
  (FirstAidTopic, String?) _topic(_Fields fields, String locale) {
    fields.onlyKeys(_topicKeys);
    final id = fields.string('id');
    if (!FirstAidTopic.idPattern.hasMatch(id)) {
      fields.invalid('id', 'lower case letters, digits and "_" only');
    }
    final kind = fields.choice('kind', FirstAidTopicKind.values);
    final declared = fields.choice('status', ContentStatus.values);
    final title = fields.string('title');
    final summary = fields.string('summary');
    final callAdvice = fields.optionalString('callAdvice');
    final steps = _steps(fields);
    final warnings = [
      for (final (i, w) in fields.optionalList('warnings').indexed)
        _Fields.nonEmptyString(w, '${fields.path}.warnings[$i]'),
    ];
    final source = _source(fields);
    final verification = _verification(fields);

    if (declared == ContentStatus.pending) {
      if (steps.isNotEmpty || warnings.isNotEmpty || callAdvice != null) {
        throw FirstAidContentException(
          FirstAidContentError.pendingWithInstructions,
          '${fields.path} ("$id") is pending but has instructions',
        );
      }
      return (
        FirstAidTopic(
          id: id,
          kind: kind,
          title: title,
          summary: summary,
          status: ContentStatus.pending,
          source: source,
          verification: verification,
        ),
        null,
      );
    }

    final missing = [
      if (steps.isEmpty) 'steps',
      if (source == null) 'source',
      if (verification == null) 'verification',
      if (kind == FirstAidTopicKind.emergency && callAdvice == null)
        'callAdvice',
    ];
    if (missing.isNotEmpty) {
      throw FirstAidContentException(
        FirstAidContentError.incompleteVerification,
        '${fields.path} ("$id") is marked verified but lacks '
        '${missing.join(', ')}',
      );
    }

    final hash = fingerprint({
      'id': id,
      'kind': kind.name,
      'title': title,
      'summary': summary,
      'callAdvice': callAdvice,
      'steps': [
        for (final s in steps)
          {'order': s.order, 'text': s.text, 'note': s.note},
      ],
      'warnings': warnings,
      'source': {
        'publisher': source!.publisher,
        'title': source.title,
        'url': source.url.toString(),
      },
      'verification': {
        'verifiedAt': _formatDate(verification!.verifiedAt),
        'verifiedBy': verification.verifiedBy,
      },
    });
    final approved = approvals.any(
      (a) => a.topicId == id && a.locale == locale && a.contentSha256 == hash,
    );

    if (!approved) {
      // Claimed but not approved: keep the topic, never its instructions.
      return (
        FirstAidTopic(
          id: id,
          kind: kind,
          title: title,
          summary: summary,
          status: ContentStatus.pending,
          source: source,
          verification: verification,
        ),
        hash,
      );
    }
    return (
      FirstAidTopic(
        id: id,
        kind: kind,
        title: title,
        summary: summary,
        status: ContentStatus.verified,
        callAdvice: callAdvice,
        steps: steps,
        warnings: warnings,
        source: source,
        verification: verification,
      ),
      null,
    );
  }

  List<GuideStep> _steps(_Fields fields) {
    final raw = fields.optionalList('steps');
    final steps = <GuideStep>[];
    for (final (i, item) in raw.indexed) {
      final step = _Fields.of(item, '${fields.path}.steps[$i]')
        ..onlyKeys(_stepKeys);
      final order = step.integer('order');
      if (order != i + 1) {
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
    return steps;
  }

  ContentSource? _source(_Fields fields) {
    final source = fields.optionalObject('source');
    if (source == null) return null;
    source.onlyKeys(_sourceKeys);
    final publisher = source.string('publisher');
    final title = source.string('title');
    final url = Uri.tryParse(source.string('url'));
    if (url == null || url.scheme != 'https' || url.host.isEmpty) {
      throw FirstAidContentException(
        FirstAidContentError.incompleteVerification,
        '${source.path}.url must be an https link',
      );
    }
    return ContentSource(publisher: publisher, title: title, url: url);
  }

  ContentVerification? _verification(_Fields fields) {
    final verification = fields.optionalObject('verification');
    if (verification == null) return null;
    verification.onlyKeys(_verificationKeys);
    final verifiedAt = _date(verification, 'verifiedAt');
    final now = clock();
    if (verifiedAt.isAfter(DateTime.utc(now.year, now.month, now.day))) {
      verification.invalid('verifiedAt', 'is in the future');
    }
    return ContentVerification(
      verifiedAt: verifiedAt,
      verifiedBy: verification.string('verifiedBy'),
    );
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
      if (_formatDate(date) == text) return date;
    }
    fields.invalid(key, 'must be a date like 2026-10-15');
  }

  static String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
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

  String string(String key) => nonEmptyString(_required(key), _at(key));

  String? optionalString(String key) => _map[key] == null ? null : string(key);

  static String nonEmptyString(Object? value, String path) {
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

  _Fields? optionalObject(String key) =>
      _map[key] == null ? null : _Fields.of(_map[key], _at(key));
}
