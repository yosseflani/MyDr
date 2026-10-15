import 'package:flutter/services.dart';
import 'package:mydr/data/first_aid/content_approvals.dart';
import 'package:mydr/data/first_aid/first_aid_content_parser.dart';
import 'package:mydr/data/models/first_aid_content.dart';

/// Source of first-aid content. The app never depends on where it comes
/// from, so a future source (e.g. a verified download) can replace the
/// bundled one without touching any screen.
abstract interface class FirstAidRepository {
  /// Throws a [FirstAidContentException] if no usable content is available.
  Future<FirstAidContentPack> load();
}

/// Content bundled with the app, so it is available offline.
class AssetFirstAidRepository implements FirstAidRepository {
  const AssetFirstAidRepository({
    this.bundle,
    this.assetPath = hebrewContentPath,
    this.approvals = FirstAidApprovals.trusted,
    this.clock = DateTime.now,
    this.mode = FirstAidContentMode.published,
  });

  /// The drafts awaiting professional review, for the developer review
  /// preview only.
  const AssetFirstAidRepository.review({
    this.bundle,
    this.assetPath = hebrewDraftPath,
    this.clock = DateTime.now,
  }) : approvals = const [],
       mode = FirstAidContentMode.review;

  static const String hebrewContentPath = 'assets/first_aid/he.json';
  static const String hebrewDraftPath = 'assets/first_aid/review/he.draft.json';

  /// Defaults to the app's root bundle.
  final AssetBundle? bundle;
  final String assetPath;
  final List<ContentApproval> approvals;
  final DateTime Function() clock;
  final FirstAidContentMode mode;

  @override
  Future<FirstAidContentPack> load() async {
    final String text;
    try {
      text = await (bundle ?? rootBundle).loadString(assetPath, cache: false);
    } catch (_) {
      throw FirstAidContentException(
        FirstAidContentError.unavailable,
        assetPath,
      );
    }
    return FirstAidContentParser(
      approvals: approvals,
      clock: clock,
      mode: mode,
    ).parse(text);
  }
}
