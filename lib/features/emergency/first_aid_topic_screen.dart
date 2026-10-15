import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/core/widgets/detail_section.dart';
import 'package:mydr/core/widgets/load_error_views.dart';
import 'package:mydr/core/widgets/not_found_view.dart';
import 'package:mydr/core/widgets/section_header.dart';
import 'package:mydr/data/models/first_aid_content.dart';
import 'package:mydr/features/emergency/first_aid_controller.dart';
import 'package:mydr/features/emergency/widgets/first_aid_topic_tile.dart';
import 'package:mydr/features/emergency/widgets/medical_call_button.dart';

/// One first-aid topic, from the shared [FirstAidController].
///
/// Only a topic that passed the content approval shows instructions: when
/// to call, numbered steps, warnings, and its source and verification. A
/// pending topic says its instructions are not available yet and shows
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
              ? SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Align(
                      heightFactor: 1,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxWidth: _maxContentWidth,
                        ),
                        child: const MedicalCallButton(compact: true),
                      ),
                    ),
                  ),
                )
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
        _Header(topic: topic),
        const SizedBox(height: 16),
        if (topic.isVerified)
          ..._verifiedContent(context, topic)
        else
          const _PendingNotice(),
      ],
    );
  }

  List<Widget> _verifiedContent(BuildContext context, FirstAidTopic topic) {
    final theme = Theme.of(context);
    final callAdvice = topic.callAdvice;
    final source = topic.source;
    final verification = topic.verification;
    final localizations = MaterialLocalizations.of(context);

    return [
      if (callAdvice != null) ...[
        AppCard(
          borderColor: theme.colorScheme.error.withValues(alpha: 0.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Semantics(
                header: true,
                child: Text(
                  AppStrings.firstAidCallAdviceTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(callAdvice, style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
      const SectionHeader(title: AppStrings.firstAidStepsTitle),
      for (final (index, step) in topic.steps.indexed) ...[
        if (index > 0) const SizedBox(height: 12),
        _StepTile(step: step, total: topic.steps.length),
      ],
      if (topic.warnings.isNotEmpty) ...[
        const SizedBox(height: 24),
        const SectionHeader(title: AppStrings.firstAidWarningsTitle),
        for (final warning in topic.warnings)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(warning, style: theme.textTheme.bodyLarge),
                ),
              ],
            ),
          ),
      ],
      // Shown only from what the content holds; nothing is filled in.
      if (source != null || verification != null) ...[
        const SizedBox(height: 24),
        DetailSection(
          title: AppStrings.firstAidSourceTitle,
          icon: Icons.verified_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (source != null) ...[
                LabeledValue(
                  label: AppStrings.firstAidSourceLabel,
                  value: '${source.publisher} – ${source.title}',
                ),
                const SizedBox(height: 4),
                SelectableText(
                  source.url.toString(),
                  textDirection: TextDirection.ltr,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
              if (verification != null) ...[
                const SizedBox(height: 12),
                LabeledValue(
                  label: AppStrings.firstAidVerifiedOnLabel,
                  value: localizations.formatFullDate(verification.verifiedAt),
                ),
                const SizedBox(height: 12),
                LabeledValue(
                  label: AppStrings.firstAidVerifiedByLabel,
                  value: verification.verifiedBy,
                ),
              ],
            ],
          ),
        ),
      ],
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.topic});

  final FirstAidTopic topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            FirstAidKindIcon(kind: topic.kind, size: 48),
            const SizedBox(width: 12),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  topic.title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        FirstAidTopicLabels(topic: topic),
        const SizedBox(height: 12),
        Text(
          topic.summary,
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
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

/// A numbered step; read out as "שלב 2 מתוך 5: …".
class _StepTile extends StatelessWidget {
  const _StepTile({required this.step, required this.total});

  final GuideStep step;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final note = step.note;

    return Semantics(
      label: AppStrings.firstAidStepLabel(step.order, total, step.text),
      excludeSemantics: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${step.order}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(step.text, style: theme.textTheme.bodyLarge),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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
