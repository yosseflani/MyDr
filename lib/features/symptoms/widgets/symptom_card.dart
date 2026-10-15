import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/features/symptoms/symptom_formatting.dart';

/// Card for one symptom record: what, who, when, the user's own severity
/// rating and their notes.
///
/// It only shows what was reported. The severity uses the same neutral
/// brand color at every level, so it never suggests urgency. Tappable as a
/// whole only when [onTap] is given. With [onOpenTrack], it also links to
/// all records of the same symptom, labeled with their [trackCount].
class SymptomCard extends StatelessWidget {
  const SymptomCard({
    super.key,
    required this.entry,
    required this.memberName,
    this.onTap,
    this.onOpenTrack,
    this.trackCount = 1,
  });

  final SymptomEntry entry;
  final String memberName;
  final VoidCallback? onTap;
  final VoidCallback? onOpenTrack;
  final int trackCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final notes = entry.notes?.trim() ?? '';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppCard.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _IconText(icon: Icons.person_outline, text: memberName),
                const SizedBox(height: 4),
                _IconText(
                  icon: Icons.schedule,
                  text: formatSymptomDateTime(
                    entry.startedAt,
                    MaterialLocalizations.of(context),
                  ),
                ),
                const SizedBox(height: 12),
                SeverityIndicator(severity: entry.severity),
                if (notes.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    notes,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (onOpenTrack != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: onOpenTrack,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      icon: const Icon(Icons.timeline, size: 20),
                      label: Text(AppStrings.openSymptomTrack(trackCount)),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The user's severity rating as text ("3 מתוך 5") with a row of dots.
/// The dots are decorative; screen readers read the text.
class SeverityIndicator extends StatelessWidget {
  const SeverityIndicator({super.key, required this.severity});

  final int severity;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Wrap(
      spacing: 8,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          AppStrings.symptomSeverity(severity, SymptomEntry.maxSeverity),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurface,
          ),
        ),
        ExcludeSemantics(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (
                var level = SymptomEntry.minSeverity;
                level <= SymptomEntry.maxSeverity;
                level++
              )
                Padding(
                  padding: const EdgeInsetsDirectional.only(end: 4),
                  child: Container(
                    key: ValueKey('severity-dot-$level'),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: level <= severity
                          ? colorScheme.primary
                          : colorScheme.surfaceContainerHighest,
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
