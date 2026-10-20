import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/features/sharing/family_sharing_screen.dart';

/// Entry to household sharing. Shown only in builds with a cloud
/// configuration and saved data; reads only this device's state, so the
/// home screen never connects to the cloud.
class SharingCard extends StatelessWidget {
  const SharingCard({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).syncController;
    if (!controller.isAvailable) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final conflicts = controller.conflicts.length;
          return AppCard(
            padding: EdgeInsets.zero,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: BorderRadius.circular(AppCard.borderRadius),
                onTap: () =>
                    Navigator.of(context).push(FamilySharingScreen.route()),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.family_restroom, color: colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppStrings.sharingTitle,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              conflicts > 0
                                  ? AppStrings.sharingCardConflicts(conflicts)
                                  : AppStrings.sharingCardSubtitle,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: conflicts > 0
                                    ? colorScheme.error
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
