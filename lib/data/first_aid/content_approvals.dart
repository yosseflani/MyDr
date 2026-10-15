/// A trusted sign-off that one exact version of a topic's content was
/// reviewed against its medical source.
///
/// Approvals live in code, not in the content file, so editing the file can
/// never make content count as verified: marking a topic "verified" there
/// only takes effect together with an approval whose [contentSha256] matches
/// the topic's content exactly. Any later change to the content (a word in
/// a step, the source link, the reviewer) changes the fingerprint and voids
/// the approval until the new content is reviewed and approved again.
class ContentApproval {
  const ContentApproval({
    required this.topicId,
    required this.locale,
    required this.contentSha256,
    required this.approvedBy,
    required this.approvedOn,
  });

  final String topicId;
  final String locale;

  /// Fingerprint of the approved content, from `FirstAidContentParser`
  /// (lower case hex).
  final String contentSha256;

  /// The approving reviewer's role or professional title.
  final String approvedBy;

  /// ISO date, e.g. "2026-10-15".
  final String approvedOn;
}

abstract final class FirstAidApprovals {
  /// Approvals the shipped app trusts.
  ///
  /// Empty: no first-aid content has been reviewed yet, so every topic is
  /// pending and no instructions are shown. Add an approval only after a
  /// qualified medical reviewer has checked that exact content against its
  /// source.
  static const List<ContentApproval> trusted = [];
}
