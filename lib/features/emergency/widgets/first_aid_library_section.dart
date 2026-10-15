import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/features/emergency/first_aid_topic_screen.dart';
import 'package:mydr/features/emergency/widgets/first_aid_topic_tile.dart';

/// The first-aid topics from the shared [FirstAidController], in the order
/// of the content. Shows loading and failure states in place, without ever
/// affecting the call buttons around it.
class FirstAidLibrarySection extends StatelessWidget {
  const FirstAidLibrarySection({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).firstAidController;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final topics = controller.topics;

        if (controller.pack == null) {
          if (controller.hasLoadError && !controller.isLoading) {
            return _Message(
              icon: Icons.error_outline,
              title: AppStrings.firstAidLoadErrorTitle,
              message: AppStrings.firstAidLoadErrorMessage,
              onRetry: controller.load,
            );
          }
          // Loading, or about to start. Static text rather than a spinner:
          // nothing moves on the emergency screens.
          return const _Message(
            icon: Icons.hourglass_empty,
            message: AppStrings.firstAidLoading,
          );
        }
        if (topics.isEmpty) {
          return const _Message(
            icon: Icons.menu_book_outlined,
            message: AppStrings.firstAidEmpty,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (controller.hasLoadError) ...[
              _Message(
                icon: Icons.error_outline,
                message: AppStrings.firstAidLoadErrorTitle,
                onRetry: controller.load,
              ),
              const SizedBox(height: 12),
            ],
            for (final (index, topic) in topics.indexed) ...[
              if (index > 0) const SizedBox(height: 12),
              FirstAidTopicTile(
                key: ValueKey(topic.id),
                topic: topic,
                onTap: () => Navigator.of(
                  context,
                ).push(FirstAidTopicScreen.route(topic.id)),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({
    required this.icon,
    required this.message,
    this.title,
    this.onRetry,
  });

  final IconData icon;
  final String? title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = this.title;
    final onRetry = this.onRetry;

    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                ],
                Text(message, style: theme.textTheme.bodyMedium),
                if (onRetry != null) ...[
                  const SizedBox(height: 8),
                  FilledButton.tonalIcon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text(AppStrings.retry),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
