import 'package:flutter/material.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/features/medications/medication_formatting.dart';

/// A medication in a list: name, dose, reminder times and treatment dates.
/// Opens its details when tapped.
class MedicationCard extends StatelessWidget {
  const MedicationCard({
    super.key,
    required this.medication,
    required this.now,
    required this.onTap,
  });

  final Medication medication;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final secondary = theme.textTheme.bodySmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppCard.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.medication_outlined, color: colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        medication.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(medication.dose, style: theme.textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(
                        formatReminderTimes(
                          medication.reminderTimes,
                          localizations,
                        ),
                        style: secondary,
                      ),
                      Text(
                        '${formatTreatmentStatus(medication, now, localizations)}'
                        ' · ${formatTreatmentDates(medication, localizations)}',
                        style: secondary,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
