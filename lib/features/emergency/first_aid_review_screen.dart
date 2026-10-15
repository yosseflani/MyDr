import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/core/widgets/load_error_views.dart';
import 'package:mydr/core/widgets/section_header.dart';
import 'package:mydr/data/first_aid/first_aid_content_parser.dart';
import 'package:mydr/data/models/first_aid_content.dart';
import 'package:mydr/data/repositories/first_aid_repository.dart';
import 'package:mydr/features/emergency/first_aid_controller.dart';
import 'package:mydr/features/emergency/widgets/first_aid_guide.dart';
import 'package:mydr/features/emergency/widgets/first_aid_topic_tile.dart';

/// The developer review preview of first-aid drafts.
abstract final class FirstAidReview {
  /// Whether the emergency center links to the preview: only in a debug
  /// build run with `--dart-define=MYDR_FIRST_AID_REVIEW=true`. A release
  /// build never shows it, whatever it is run with.
  static const bool enabled =
      kDebugMode && bool.fromEnvironment('MYDR_FIRST_AID_REVIEW');
}

/// Lists the drafts awaiting professional review, from their own file and
/// controller, apart from the app's content: nothing here can reach the
/// first-aid library. Every screen says the content is not approved.
class FirstAidReviewScreen extends StatefulWidget {
  const FirstAidReviewScreen({super.key, this.repository});

  /// Defaults to the bundled drafts.
  final FirstAidRepository? repository;

  static const double _maxContentWidth = 600;

  static Route<void> route({FirstAidRepository? repository}) =>
      MaterialPageRoute<void>(
        builder: (_) => FirstAidReviewScreen(repository: repository),
      );

  @override
  State<FirstAidReviewScreen> createState() => _FirstAidReviewScreenState();
}

class _FirstAidReviewScreenState extends State<FirstAidReviewScreen> {
  late final FirstAidController _controller = FirstAidController(
    widget.repository ?? const AssetFirstAidRepository.review(),
  );

  @override
  void initState() {
    super.initState();
    _controller.load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.firstAidReviewTitle)),
      bottomNavigationBar: const PinnedMedicalCallBar(
        maxWidth: FirstAidReviewScreen._maxContentWidth,
      ),
      body: Column(
        children: [
          const DraftBanner(),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: FirstAidReviewScreen._maxContentWidth,
                ),
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => _buildBody(context),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final pack = _controller.pack;
    if (pack == null) {
      if (_controller.hasLoadError && !_controller.isLoading) {
        return LoadErrorView(
          title: AppStrings.firstAidReviewLoadErrorTitle,
          message: AppStrings.firstAidLoadErrorMessage,
          onRetry: _controller.load,
        );
      }
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: Text(AppStrings.firstAidLoading)),
      );
    }
    final drafts = pack.topics.where((t) => t.isDraft).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        const DraftNotice(),
        const SizedBox(height: 16),
        for (final (index, topic) in drafts.indexed) ...[
          if (index > 0) const SizedBox(height: 12),
          FirstAidTopicTile(
            key: ValueKey(topic.id),
            topic: topic,
            onTap: () => Navigator.of(
              context,
            ).push(FirstAidReviewTopicScreen.route(topic)),
          ),
        ],
      ],
    );
  }
}

/// One draft, in full, under a banner that it is not approved, with its
/// review notes and the fingerprint an approval of this exact wording
/// would refer to.
class FirstAidReviewTopicScreen extends StatelessWidget {
  const FirstAidReviewTopicScreen({super.key, required this.topic});

  final FirstAidTopic topic;

  static Route<void> route(FirstAidTopic topic) => MaterialPageRoute<void>(
    builder: (_) => FirstAidReviewTopicScreen(topic: topic),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(topic.title)),
      bottomNavigationBar: const PinnedMedicalCallBar(
        maxWidth: FirstAidReviewScreen._maxContentWidth,
      ),
      body: Column(
        children: [
          const DraftBanner(),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: FirstAidReviewScreen._maxContentWidth,
                ),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    const DraftNotice(),
                    const SizedBox(height: 16),
                    FirstAidTopicHeader(topic: topic),
                    const SizedBox(height: 16),
                    // The preview shows drafts only; anything else (which
                    // the review parser never yields) shows nothing.
                    if (topic.isDraft) ...[
                      FirstAidGuide(topic: topic, showReviewNotes: true),
                      const SizedBox(height: 24),
                      const SectionHeader(
                        title: AppStrings.firstAidReviewFingerprintLabel,
                      ),
                      SelectableText(
                        FirstAidContentParser.reviewFingerprint(topic),
                        textDirection: TextDirection.ltr,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A short line always visible above the scrolling content of the review
/// preview; short so it fits even at the largest text sizes.
class DraftBanner extends StatelessWidget {
  const DraftBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      container: true,
      child: ColoredBox(
        color: colorScheme.error,
        child: SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ExcludeSemantics(
                  child: Icon(
                    Icons.report_outlined,
                    color: colorScheme.onError,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    AppStrings.firstAidDraftBanner,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: colorScheme.onError,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The full warning, at the top of every review screen's content.
class DraftNotice extends StatelessWidget {
  const DraftNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
      color: colorScheme.errorContainer,
      child: Text(
        AppStrings.firstAidDraftNotice,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
          color: colorScheme.onErrorContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
