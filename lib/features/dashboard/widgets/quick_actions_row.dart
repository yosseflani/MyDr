import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/theme/app_colors.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/core/widgets/coming_soon_badge.dart';

/// Three shortcut tiles. "New appointment" and "Questions for the doctor"
/// open their screens; "Log a symptom" is shown as unavailable until that
/// feature exists.
class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({
    super.key,
    required this.onNewAppointment,
    required this.onDoctorQuestions,
  });

  final VoidCallback onNewAppointment;
  final VoidCallback onDoctorQuestions;

  @override
  Widget build(BuildContext context) {
    final actions =
        <({IconData icon, String label, Color color, VoidCallback? onTap})>[
          (
            icon: Icons.event_available,
            label: AppStrings.actionNewAppointment,
            color: AppColors.blue,
            onTap: onNewAppointment,
          ),
          (
            icon: Icons.edit_note,
            label: AppStrings.actionLogSymptom,
            color: AppColors.teal,
            onTap: null,
          ),
          (
            icon: Icons.question_answer_outlined,
            label: AppStrings.actionDoctorQuestions,
            color: AppColors.skyBlue,
            onTap: onDoctorQuestions,
          ),
        ];

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final (index, action) in actions.indexed) ...[
            if (index > 0) const SizedBox(width: 12),
            Expanded(
              child: QuickActionTile(
                icon: action.icon,
                label: action.label,
                color: action.color,
                onTap: action.onTap,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A shortcut tile. Without [onTap] it is shown muted with a "coming soon"
/// badge and cannot be tapped.
class QuickActionTile extends StatelessWidget {
  const QuickActionTile({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = onTap != null;

    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withValues(alpha: isAvailable ? 0.16 : 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icon,
              color: isAvailable ? color : color.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelLarge?.copyWith(
              color: isAvailable
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: isAvailable ? FontWeight.bold : null,
            ),
          ),
          if (!isAvailable) ...[
            const Spacer(),
            const SizedBox(height: 8),
            const ComingSoonBadge(),
          ],
        ],
      ),
    );

    if (!isAvailable) {
      return Semantics(
        label: '$label, ${AppStrings.comingSoonBadge}',
        enabled: false,
        excludeSemantics: true,
        child: AppCard(padding: EdgeInsets.zero, child: content),
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppCard.borderRadius),
          child: content,
        ),
      ),
    );
  }
}
