import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/theme/app_colors.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/core/widgets/coming_soon_badge.dart';

/// Three shortcut tiles. They are shown as unavailable until the matching
/// features exist, so none of them is tappable yet.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  static const List<({IconData icon, String label, Color color})> _actions = [
    (
      icon: Icons.event_available,
      label: AppStrings.actionNewAppointment,
      color: AppColors.blue,
    ),
    (
      icon: Icons.edit_note,
      label: AppStrings.actionLogSymptom,
      color: AppColors.teal,
    ),
    (
      icon: Icons.question_answer_outlined,
      label: AppStrings.actionDoctorQuestions,
      color: AppColors.skyBlue,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, action) in _actions.indexed) ...[
            if (index > 0) const SizedBox(width: 12),
            Expanded(
              child: QuickActionTile(
                icon: action.icon,
                label: action.label,
                color: action.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '$label, ${AppStrings.comingSoonBadge}',
      enabled: false,
      excludeSemantics: true,
      child: AppCard(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const Spacer(),
            const SizedBox(height: 8),
            const ComingSoonBadge(),
          ],
        ),
      ),
    );
  }
}
