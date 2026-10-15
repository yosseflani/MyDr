/// Whether a topic is for an emergency or general information.
enum FirstAidTopicKind { emergency, generalInfo }

/// Whether a topic's instructions may be shown.
///
/// Always the status the app trusts, never just what the content file
/// claims: see [FirstAidContentPack] and `FirstAidContentParser`.
enum ContentStatus { pending, verified }

/// One numbered instruction of a verified topic.
class GuideStep {
  GuideStep({required this.order, required this.text, this.note}) {
    if (order < 1) throw ArgumentError.value(order, 'order', 'must be >= 1');
    if (text.trim().isEmpty) throw ArgumentError.value(text, 'text');
  }

  final int order;
  final String text;
  final String? note;
}

/// The authoritative medical source a topic's content comes from.
class ContentSource {
  ContentSource({
    required this.publisher,
    required this.title,
    required this.url,
  }) {
    if (publisher.trim().isEmpty) {
      throw ArgumentError.value(publisher, 'publisher');
    }
    if (title.trim().isEmpty) throw ArgumentError.value(title, 'title');
    if (url.scheme != 'https' || url.host.isEmpty) {
      throw ArgumentError.value(url, 'url', 'must be an https link');
    }
  }

  final String publisher;
  final String title;
  final Uri url;
}

/// Who checked a topic's content against its source, and when.
class ContentVerification {
  ContentVerification({required this.verifiedAt, required this.verifiedBy}) {
    if (verifiedBy.trim().isEmpty) {
      throw ArgumentError.value(verifiedBy, 'verifiedBy');
    }
  }

  /// A calendar date (UTC midnight).
  final DateTime verifiedAt;

  /// The reviewer (a role or professional title, not a private person's
  /// details).
  final String verifiedBy;
}

/// A first-aid topic, e.g. choking.
///
/// A pending topic holds no instructions at all (no steps, warnings or call
/// advice), so nothing unverified can ever be shown as guidance. A verified
/// topic always has steps, its source and its verification. Both are
/// enforced here, whatever the content file contains.
class FirstAidTopic {
  FirstAidTopic({
    required this.id,
    required this.kind,
    required this.title,
    required this.summary,
    required this.status,
    this.callAdvice,
    List<GuideStep> steps = const [],
    List<String> warnings = const [],
    this.source,
    this.verification,
  }) : steps = List.unmodifiable(steps),
       warnings = List.unmodifiable(warnings) {
    if (!idPattern.hasMatch(id)) throw ArgumentError.value(id, 'id');
    if (title.trim().isEmpty) throw ArgumentError.value(title, 'title');
    if (summary.trim().isEmpty) throw ArgumentError.value(summary, 'summary');
    switch (status) {
      case ContentStatus.pending:
        if (steps.isNotEmpty || warnings.isNotEmpty || callAdvice != null) {
          throw ArgumentError('A pending topic cannot hold instructions: $id');
        }
      case ContentStatus.verified:
        if (steps.isEmpty || source == null || verification == null) {
          throw ArgumentError(
            'A verified topic needs steps, a source and a verification: $id',
          );
        }
    }
  }

  /// Lower case letters, digits and underscores, starting with a letter.
  static final RegExp idPattern = RegExp(r'^[a-z][a-z0-9_]*$');

  final String id;
  final FirstAidTopicKind kind;
  final String title;

  /// What the topic is about. Never an instruction.
  final String summary;
  final ContentStatus status;

  /// When to call emergency services, shown before the steps.
  final String? callAdvice;

  /// In order.
  final List<GuideStep> steps;
  final List<String> warnings;
  final ContentSource? source;
  final ContentVerification? verification;

  bool get isVerified => status == ContentStatus.verified;

  /// Shows only the id so content never ends up in logs.
  @override
  String toString() => 'FirstAidTopic($id, ${status.name})';
}

/// All first-aid content for one language.
class FirstAidContentPack {
  FirstAidContentPack({
    required this.schemaVersion,
    required this.contentVersion,
    required this.locale,
    required this.publishedAt,
    required List<FirstAidTopic> topics,
    Map<String, String> unapprovedFingerprints = const {},
  }) : topics = List.unmodifiable(topics),
       unapprovedFingerprints = Map.unmodifiable(unapprovedFingerprints);

  final int schemaVersion;
  final int contentVersion;

  /// A language code, e.g. "he".
  final String locale;
  final DateTime publishedAt;

  /// In the order of the content file.
  final List<FirstAidTopic> topics;

  /// Topics the file marks as verified but that have no matching trusted
  /// approval, by id, with the content fingerprint an approval would need.
  /// They are kept as pending, without their instructions.
  final Map<String, String> unapprovedFingerprints;

  FirstAidTopic? topicById(String id) {
    for (final topic in topics) {
      if (topic.id == id) return topic;
    }
    return null;
  }
}
