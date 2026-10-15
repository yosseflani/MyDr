/// Whether a topic is for an emergency or general information.
enum FirstAidTopicKind { emergency, generalInfo }

/// How far a topic's content may be trusted.
///
/// * [pending]: no instructions at all; the topic is listed as "in
///   preparation".
/// * [draft]: instructions being written or revised, with open questions
///   for the reviewer. Only the developer review preview shows them,
///   always marked as unapproved; the app itself never loads drafts.
/// * [sourced]: complete instructions based on cited, checked medical
///   sources, shown in the app under a clear notice that they have not
///   been professionally approved for MyDr. Never shown as verified.
/// * [verified]: approved by a qualified professional. Never just what the
///   content file claims: see `FirstAidContentParser` and
///   `FirstAidApprovals`.
enum ContentStatus { pending, draft, sourced, verified }

/// One numbered instruction.
class GuideStep {
  GuideStep({required this.order, required this.text, this.note}) {
    if (order < 1) throw ArgumentError.value(order, 'order', 'must be >= 1');
    if (text.trim().isEmpty) throw ArgumentError.value(text, 'text');
  }

  final int order;
  final String text;
  final String? note;
}

/// The instructions for one group of people or one situation, e.g. "infant
/// under one year" or "life-threatening bleeding". A topic with several
/// variants never shows steps until the user has chosen one.
class GuideVariant {
  GuideVariant({
    required this.id,
    required this.label,
    required List<GuideStep> steps,
    this.appliesTo,
    List<String> doNot = const [],
  }) : steps = List.unmodifiable(steps),
       doNot = List.unmodifiable(doNot) {
    if (!FirstAidTopic.idPattern.hasMatch(id)) {
      throw ArgumentError.value(id, 'id');
    }
    if (label.trim().isEmpty) throw ArgumentError.value(label, 'label');
    if (steps.isEmpty) throw ArgumentError('A variant needs steps: $id');
  }

  final String id;
  final String label;

  /// Who or what the variant is for, in a few words.
  final String? appliesTo;

  /// In order.
  final List<GuideStep> steps;

  /// What must not be done in this situation.
  final List<String> doNot;
}

/// An authoritative medical source a topic's content is based on.
class ContentSource {
  ContentSource({
    required this.id,
    required this.publisher,
    required this.title,
    required this.url,
    required this.published,
    required this.accessedOn,
  }) {
    if (!FirstAidTopic.idPattern.hasMatch(id)) {
      throw ArgumentError.value(id, 'id');
    }
    if (publisher.trim().isEmpty) {
      throw ArgumentError.value(publisher, 'publisher');
    }
    if (title.trim().isEmpty) throw ArgumentError.value(title, 'title');
    if (url.scheme != 'https' || url.host.isEmpty) {
      throw ArgumentError.value(url, 'url', 'must be an https link');
    }
    if (published.trim().isEmpty) {
      throw ArgumentError.value(published, 'published');
    }
  }

  final String id;
  final String publisher;
  final String title;
  final Uri url;

  /// When the source was published or last reviewed, as the source states
  /// it ("2025-10-27" or "2024-08").
  final String published;

  /// When its content was checked for MyDr (UTC midnight).
  final DateTime accessedOn;
}

/// Who approved a topic's content, and when.
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
/// The constructor enforces what each [status] may hold, whatever the
/// content file says:
/// * pending: no instructions, sources or review notes at all;
/// * draft: instructions and sources, review notes allowed, no approval;
/// * sourced: instructions and sources, no review notes, no approval. An
///   emergency topic must also say when to call for help;
/// * verified: instructions, sources and its verification; never review
///   notes. An emergency topic must also say when to call for help.
class FirstAidTopic {
  FirstAidTopic({
    required this.id,
    required this.kind,
    required this.title,
    required this.summary,
    required this.status,
    this.overview,
    List<String> recognize = const [],
    List<String> callNow = const [],
    List<GuideVariant> variants = const [],
    List<String> warnings = const [],
    List<String> afterCare = const [],
    List<ContentSource> sources = const [],
    List<String> reviewNotes = const [],
    this.verification,
  }) : recognize = List.unmodifiable(recognize),
       callNow = List.unmodifiable(callNow),
       variants = List.unmodifiable(variants),
       warnings = List.unmodifiable(warnings),
       afterCare = List.unmodifiable(afterCare),
       sources = List.unmodifiable(sources),
       reviewNotes = List.unmodifiable(reviewNotes) {
    if (!idPattern.hasMatch(id)) throw ArgumentError.value(id, 'id');
    if (title.trim().isEmpty) throw ArgumentError.value(title, 'title');
    if (summary.trim().isEmpty) throw ArgumentError.value(summary, 'summary');
    final variantIds = {for (final v in variants) v.id};
    if (variantIds.length != variants.length) {
      throw ArgumentError('Duplicate variant ids in $id');
    }
    switch (status) {
      case ContentStatus.pending:
        if (hasInstructions ||
            sources.isNotEmpty ||
            reviewNotes.isNotEmpty ||
            verification != null) {
          throw ArgumentError('A pending topic cannot hold instructions: $id');
        }
      case ContentStatus.draft:
        if (variants.isEmpty || sources.isEmpty || verification != null) {
          throw ArgumentError(
            'A draft needs instructions and sources, and no approval: $id',
          );
        }
      case ContentStatus.sourced:
        if (variants.isEmpty ||
            sources.isEmpty ||
            verification != null ||
            reviewNotes.isNotEmpty ||
            (kind == FirstAidTopicKind.emergency && callNow.isEmpty)) {
          throw ArgumentError('A sourced topic is incomplete: $id');
        }
      case ContentStatus.verified:
        if (variants.isEmpty ||
            sources.isEmpty ||
            verification == null ||
            reviewNotes.isNotEmpty ||
            (kind == FirstAidTopicKind.emergency && callNow.isEmpty)) {
          throw ArgumentError('A verified topic is incomplete: $id');
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

  /// A short explanation of the condition.
  final String? overview;

  /// Signs that suggest the condition.
  final List<String> recognize;

  /// When to call emergency services immediately; shown before the steps.
  final List<String> callNow;

  /// The instructions, one set per age group or situation.
  final List<GuideVariant> variants;

  /// Warning signs and cautions.
  final List<String> warnings;

  /// When medical assessment is needed even after improvement.
  final List<String> afterCare;
  final List<ContentSource> sources;

  /// Open questions for the professional reviewer. Drafts only.
  final List<String> reviewNotes;
  final ContentVerification? verification;

  bool get isVerified => status == ContentStatus.verified;
  bool get isDraft => status == ContentStatus.draft;
  bool get isSourced => status == ContentStatus.sourced;

  /// Whether the app may show the instructions to users: approved, or
  /// based on cited sources (always with a notice that it is not approved).
  bool get isPublished => isVerified || isSourced;

  /// Whether the topic holds any instructions or medical explanation.
  bool get hasInstructions =>
      overview != null ||
      recognize.isNotEmpty ||
      callNow.isNotEmpty ||
      variants.isNotEmpty ||
      warnings.isNotEmpty ||
      afterCare.isNotEmpty;

  /// The date the content was last checked against its sources.
  DateTime? get lastChecked => sources.isEmpty
      ? null
      : sources.map((s) => s.accessedOn).reduce((a, b) => a.isAfter(b) ? a : b);

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
