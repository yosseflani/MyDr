import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/data/models/first_aid_content.dart';

String firstAidKindLabel(FirstAidTopicKind kind) => switch (kind) {
  FirstAidTopicKind.emergency => AppStrings.topicKindEmergency,
  FirstAidTopicKind.generalInfo => AppStrings.topicKindGeneralInfo,
};

String contentStatusLabel(ContentStatus status) => switch (status) {
  ContentStatus.pending => AppStrings.contentStatusPending,
  ContentStatus.verified => AppStrings.contentStatusVerified,
};

/// Icon set apart by kind: emergencies in the error colors, general
/// information in the neutral ones, so the two are told apart at a glance
/// (and by the label next to it, never by color alone).
class FirstAidKindIcon extends StatelessWidget {
  const FirstAidKindIcon({super.key, required this.kind, this.size = 44});

  final FirstAidTopicKind kind;
  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEmergency = kind == FirstAidTopicKind.emergency;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isEmergency
            ? colorScheme.errorContainer
            : colorScheme.secondaryContainer,
        shape: BoxShape.circle,
      ),
      child: Icon(
        isEmergency ? Icons.emergency : Icons.info_outline,
        color: isEmergency
            ? colorScheme.onErrorContainer
            : colorScheme.onSecondaryContainer,
      ),
    );
  }
}

/// The topic's kind and content status as two small labels.
class FirstAidTopicLabels extends StatelessWidget {
  const FirstAidTopicLabels({super.key, required this.topic});

  final FirstAidTopic topic;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEmergency = topic.kind == FirstAidTopicKind.emergency;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _Label(
          text: firstAidKindLabel(topic.kind),
          background: isEmergency
              ? colorScheme.errorContainer
              : colorScheme.secondaryContainer,
          foreground: isEmergency
              ? colorScheme.onErrorContainer
              : colorScheme.onSecondaryContainer,
        ),
        _Label(
          text: contentStatusLabel(topic.status),
          icon: topic.isVerified ? Icons.verified_outlined : Icons.schedule,
          background: topic.isVerified
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHigh,
          foreground: topic.isVerified
              ? colorScheme.onPrimaryContainer
              : colorScheme.onSurfaceVariant,
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({
    required this.text,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String text;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final icon = this.icon;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A topic in the library: what it is, its kind and status; opens it.
class FirstAidTopicTile extends StatelessWidget {
  const FirstAidTopicTile({
    super.key,
    required this.topic,
    required this.onTap,
  });

  final FirstAidTopic topic;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      label: AppStrings.firstAidTopicLabel(
        topic.title,
        firstAidKindLabel(topic.kind),
        contentStatusLabel(topic.status),
      ),
      excludeSemantics: true,
      child: AppCard(
        padding: EdgeInsets.zero,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppCard.borderRadius),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 8, 14),
              child: Row(
                children: [
                  FirstAidKindIcon(kind: topic.kind),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          topic.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          topic.summary,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        FirstAidTopicLabels(topic: topic),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
