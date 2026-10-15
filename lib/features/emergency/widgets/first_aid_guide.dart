import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/core/widgets/detail_section.dart';
import 'package:mydr/core/widgets/section_header.dart';
import 'package:mydr/data/first_aid/first_aid_content_parser.dart';
import 'package:mydr/data/models/first_aid_content.dart';
import 'package:mydr/features/emergency/widgets/first_aid_topic_tile.dart';
import 'package:mydr/features/emergency/widgets/medical_call_button.dart';

/// The topic's icon, title, kind and status labels, and summary.
class FirstAidTopicHeader extends StatelessWidget {
  const FirstAidTopicHeader({super.key, required this.topic});

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
                container: true,
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
        _Node(child: FirstAidTopicLabels(topic: topic)),
        const SizedBox(height: 12),
        _Node(
          child: Text(
            topic.summary,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// A compact button to dial 101, pinned to the bottom of a topic screen.
class PinnedMedicalCallBar extends StatelessWidget {
  const PinnedMedicalCallBar({super.key, required this.maxWidth});

  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Align(
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: const MedicalCallButton(compact: true),
          ),
        ),
      ),
    );
  }
}

/// A topic's full instructions: when to call, how to recognize the
/// condition, a choice of situation or age group, its numbered steps and
/// what not to do, warnings, follow-up care, and the sources.
///
/// Callers decide whether the topic may be shown at all: the app shows it
/// only for verified topics, the review preview only for drafts, under a
/// banner saying they are not approved.
///
/// With several variants, no steps are shown until one is chosen, and the
/// chooser says to dial 101 when unsure: the guide never guesses who is
/// being helped.
class FirstAidGuide extends StatefulWidget {
  const FirstAidGuide({
    super.key,
    required this.topic,
    this.showReviewNotes = false,
  });

  final FirstAidTopic topic;

  /// Drafts only, in the review preview.
  final bool showReviewNotes;

  @override
  State<FirstAidGuide> createState() => _FirstAidGuideState();
}

class _FirstAidGuideState extends State<FirstAidGuide> {
  String? _chosenId;

  GuideVariant? get _chosen {
    final variants = widget.topic.variants;
    if (variants.length == 1) return variants.single;
    for (final variant in variants) {
      if (variant.id == _chosenId) return variant;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topic = widget.topic;
    final overview = topic.overview;
    final chosen = _chosen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (topic.callNow.isNotEmpty) ...[
          _CallNowCard(items: topic.callNow),
          const SizedBox(height: 24),
        ],
        if (overview != null) ...[
          _Node(child: Text(overview, style: theme.textTheme.bodyLarge)),
          const SizedBox(height: 24),
        ],
        if (topic.recognize.isNotEmpty) ...[
          const _Heading(title: AppStrings.firstAidRecognizeTitle),
          _BulletList(items: topic.recognize, icon: Icons.visibility_outlined),
          const SizedBox(height: 24),
        ],
        if (topic.variants.length > 1) ...[
          _VariantChooser(
            variants: topic.variants,
            chosenId: chosen?.id,
            onChosen: (id) => setState(() => _chosenId = id),
          ),
          const SizedBox(height: 24),
        ],
        if (chosen != null) ...[
          _Heading(
            title: topic.variants.length > 1
                ? '${AppStrings.firstAidStepsTitle}: ${chosen.label}'
                : AppStrings.firstAidStepsTitle,
          ),
          for (final (index, step) in chosen.steps.indexed) ...[
            if (index > 0) const SizedBox(height: 12),
            _StepTile(step: step, total: chosen.steps.length),
          ],
          if (chosen.doNot.isNotEmpty) ...[
            const SizedBox(height: 24),
            const _Heading(title: AppStrings.firstAidDoNotTitle),
            for (final item in chosen.doNot) _DoNotItem(text: item),
          ],
          const SizedBox(height: 24),
        ],
        if (topic.warnings.isNotEmpty) ...[
          const _Heading(title: AppStrings.firstAidWarningsTitle),
          _BulletList(
            items: topic.warnings,
            icon: Icons.warning_amber_rounded,
            iconColor: theme.colorScheme.error,
          ),
          const SizedBox(height: 24),
        ],
        if (topic.afterCare.isNotEmpty) ...[
          const _Heading(title: AppStrings.firstAidAfterCareTitle),
          _BulletList(
            items: topic.afterCare,
            icon: Icons.local_hospital_outlined,
          ),
          const SizedBox(height: 24),
        ],
        _SourcesSection(topic: topic),
        if (widget.showReviewNotes && topic.reviewNotes.isNotEmpty) ...[
          const SizedBox(height: 24),
          _Node(
            child: DetailSection(
              title: AppStrings.firstAidReviewNotesTitle,
              icon: Icons.rate_review_outlined,
              child: _BulletList(
                items: topic.reviewNotes,
                icon: Icons.help_outline,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _CallNowCard extends StatelessWidget {
  const _CallNowCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      borderColor: theme.colorScheme.error.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            container: true,
            header: true,
            child: Text(
              AppStrings.firstAidCallNowTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.error,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _BulletList(
            items: items,
            icon: Icons.call,
            iconColor: theme.colorScheme.error,
          ),
        ],
      ),
    );
  }
}

class _BulletList extends StatelessWidget {
  const _BulletList({required this.items, required this.icon, this.iconColor});

  final List<String> items;
  final IconData icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          _Node(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ExcludeSemantics(
                    child: Icon(
                      icon,
                      size: 22,
                      color: iconColor ?? theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(item, style: theme.textTheme.bodyLarge)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

/// One option per variant, as large cards; read out as a group of
/// mutually exclusive choices.
class _VariantChooser extends StatelessWidget {
  const _VariantChooser({
    required this.variants,
    required this.chosenId,
    required this.onChosen,
  });

  final List<GuideVariant> variants;
  final String? chosenId;
  final ValueChanged<String> onChosen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Heading(title: AppStrings.firstAidChooseVariantTitle),
        for (final variant in variants) ...[
          Builder(
            builder: (context) {
              final selected = variant.id == chosenId;
              final appliesTo = variant.appliesTo;
              return Semantics(
                key: ValueKey('variant-${variant.id}'),
                container: true,
                button: true,
                inMutuallyExclusiveGroup: true,
                checked: selected,
                onTap: () => onChosen(variant.id),
                label: AppStrings.firstAidVariantLabel(
                  variant.label,
                  appliesTo,
                ),
                excludeSemantics: true,
                child: AppCard(
                  padding: EdgeInsets.zero,
                  color: selected ? colorScheme.primaryContainer : null,
                  borderColor: selected ? colorScheme.primary : null,
                  child: Material(
                    type: MaterialType.transparency,
                    child: InkWell(
                      onTap: () => onChosen(variant.id),
                      borderRadius: BorderRadius.circular(AppCard.borderRadius),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minHeight: 56),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                selected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: selected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      variant.label,
                                      style: theme.textTheme.titleMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                    ),
                                    if (appliesTo != null)
                                      Text(
                                        appliesTo,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              color:
                                                  colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 8),
        ],
        _Node(
          child: Text(
            AppStrings.firstAidChooseVariantHint,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
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
      container: true,
      label: AppStrings.firstAidStepLabel(
        step.order,
        total,
        note == null ? step.text : '${step.text} $note',
      ),
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
                    style: theme.textTheme.bodyMedium?.copyWith(
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

class _DoNotItem extends StatelessWidget {
  const _DoNotItem({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      container: true,
      label: AppStrings.firstAidDoNotLabel(text),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.close, color: theme.colorScheme.error),
            const SizedBox(width: 8),
            Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
          ],
        ),
      ),
    );
  }
}

/// Every source with its publication and check dates, then the approval
/// (or that there is none). Shown only from what the content holds.
class _SourcesSection extends StatelessWidget {
  const _SourcesSection({required this.topic});

  final FirstAidTopic topic;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final verification = topic.verification;
    final lastChecked = topic.lastChecked;
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );

    return _Node(
      child: DetailSection(
        title: AppStrings.firstAidSourcesTitle,
        icon: Icons.menu_book_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final source in topic.sources) ...[
              _Node(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${source.publisher}: ${source.title}',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      AppStrings.firstAidSourcePublished(source.published),
                      style: secondary,
                    ),
                    Text(
                      AppStrings.firstAidSourceAccessed(
                        FirstAidContentParser.formatDate(source.accessedOn),
                      ),
                      style: secondary,
                    ),
                    SelectableText(
                      source.url.toString(),
                      textDirection: TextDirection.ltr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (lastChecked != null) ...[
              LabeledValue(
                label: AppStrings.firstAidLastCheckedLabel,
                value: localizations.formatFullDate(lastChecked),
              ),
              const SizedBox(height: 12),
            ],
            if (verification != null) ...[
              LabeledValue(
                label: AppStrings.firstAidVerifiedOnLabel,
                value: localizations.formatFullDate(verification.verifiedAt),
              ),
              const SizedBox(height: 12),
              LabeledValue(
                label: AppStrings.firstAidVerifiedByLabel,
                value: verification.verifiedBy,
              ),
            ] else
              _Node(
                child: Text(
                  AppStrings.firstAidNotVerifiedLabel,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Its own semantics node, so a screen reader reads each part on its own
/// rather than the whole guide as one block.
class _Node extends StatelessWidget {
  const _Node({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) =>
      Semantics(container: true, child: child);
}

/// A section title, announced as a heading.
class _Heading extends StatelessWidget {
  const _Heading({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    header: true,
    child: SectionHeader(title: title),
  );
}
