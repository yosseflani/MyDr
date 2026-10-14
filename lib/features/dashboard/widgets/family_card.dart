import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';

/// Highlighted "My family" card with a summary of the family members from
/// the shared [FamilyController].
class FamilyCard extends StatelessWidget {
  const FamilyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).familyController;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) =>
          _buildCard(context, controller.members.map((m) => m.name).toList()),
    );
  }

  Widget _buildCard(BuildContext context, List<String> memberNames) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = colorScheme.onPrimaryContainer;
    final hasMembers = memberNames.isNotEmpty;

    return AppCard(
      color: colorScheme.primaryContainer,
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.family_restroom,
              size: 30,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.familyCardTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  hasMembers
                      ? AppStrings.familyCardCount(memberNames.length)
                      : AppStrings.familyCardEmpty,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (hasMembers) ...[
                  const SizedBox(height: 2),
                  Text(
                    memberNames.join(', '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: foreground,
                    ),
                  ),
                ],
                const SizedBox(height: 4),
                Text(
                  hasMembers
                      ? AppStrings.familyCardManageHint
                      : AppStrings.familyCardEmptyHint,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: foreground.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
