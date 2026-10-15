import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/core/widgets/load_error_views.dart';
import 'package:mydr/core/widgets/not_found_view.dart';
import 'package:mydr/data/models/first_aid_content.dart';
import 'package:mydr/features/emergency/first_aid_controller.dart';
import 'package:mydr/features/emergency/widgets/first_aid_guide.dart';

/// One first-aid topic, from the shared [FirstAidController].
///
/// Only a topic that passed the content approval, or that is based on
/// cited sources, shows instructions (see [FirstAidGuide]): when to call, a
/// choice of age group or situation, numbered steps, warnings, and its
/// sources and verification. Sourced content is always shown under a notice
/// that it has not been professionally approved. Any other topic says its instructions are not available yet and shows
/// nothing else. The screen follows the controller, so a reload that
/// changes or removes the topic is reflected at once.
///
/// Unless the topic is known to be general information, a button to dial
/// 101 stays pinned to the bottom, whatever the state of the content.
class FirstAidTopicScreen extends StatelessWidget {
  const FirstAidTopicScreen({super.key, required this.topicId});

  final String topicId;

  static const double _maxContentWidth = 600;

  static Route<void> route(String topicId) => MaterialPageRoute<void>(
    builder: (_) => FirstAidTopicScreen(topicId: topicId),
  );

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).firstAidController;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final topic = controller.topicById(topicId);
        final showCallBar = topic?.kind != FirstAidTopicKind.generalInfo;

        return Scaffold(
          appBar: AppBar(title: Text(topic?.title ?? '')),
          bottomNavigationBar: showCallBar
              ? const PinnedMedicalCallBar(maxWidth: _maxContentWidth)
              : null,
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: _buildBody(context, controller, topic),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    FirstAidController controller,
    FirstAidTopic? topic,
  ) {
    if (topic == null) {
      if (controller.isLoading) {
        return const Padding(
          padding: EdgeInsets.all(24),
          child: Center(child: Text(AppStrings.firstAidLoading)),
        );
      }
      if (controller.hasLoadError && controller.pack == null) {
        return LoadErrorView(
          title: AppStrings.firstAidLoadErrorTitle,
          message: AppStrings.firstAidLoadErrorMessage,
          onRetry: controller.load,
        );
      }
      return const NotFoundView(
        icon: Icons.menu_book_outlined,
        title: AppStrings.firstAidTopicNotFoundTitle,
        message: AppStrings.firstAidTopicNotFoundMessage,
        backLabel: AppStrings.backToEmergencyCenter,
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        FirstAidTopicHeader(topic: topic),
        const SizedBox(height: 16),
        // Approved or sourced content only; drafts never reach the app's
        // controller, but the screen does not rely on that.
        if (topic.isPublished) ...[
          if (!topic.isVerified) ...[
            const SourcedNotice(),
            const SizedBox(height: 16),
          ],
          FirstAidGuide(key: ValueKey(topic.id), topic: topic),
        ] else
          const _PendingNotice(),
      ],
    );
  }
}

class _PendingNotice extends StatelessWidget {
  const _PendingNotice();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.schedule, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.firstAidPendingTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppStrings.firstAidPendingMessage,
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Says, before the instructions, that they are based on cited sources but
/// have not been professionally approved for MyDr.
class SourcedNotice extends StatelessWidget {
  const SourcedNotice({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      container: true,
      child: AppCard(
        color: colorScheme.secondaryContainer,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, color: colorScheme.onSecondaryContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.firstAidSourcedNoticeTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppStrings.firstAidSourcedNoticeMessage,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
