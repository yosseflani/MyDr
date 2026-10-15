import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/features/symptoms/symptom_formatting.dart';

/// Compact row for a symptom record in a summary (home screen, profile):
/// the symptom, who (when [memberName] is given) and when. Tapping it
/// opens the record; [onOpenTrack] adds a button to its symptom's track.
class RecentSymptomTile extends StatelessWidget {
  const RecentSymptomTile({
    super.key,
    required this.entry,
    required this.onTap,
    this.memberName,
    this.onOpenTrack,
  });

  final SymptomEntry entry;
  final VoidCallback onTap;
  final String? memberName;
  final VoidCallback? onOpenTrack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final when = formatSymptomDateTime(
      entry.startedAt,
      MaterialLocalizations.of(context),
    );
    final memberName = this.memberName;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.name,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    memberName == null ? when : '$memberName · $when',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (onOpenTrack != null)
              IconButton(
                tooltip: AppStrings.symptomTrackTitle,
                onPressed: onOpenTrack,
                icon: const Icon(Icons.timeline),
              )
            else
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
