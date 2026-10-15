import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/core/widgets/empty_state.dart';
import 'package:mydr/features/symptoms/symptom_form_screen.dart';
import 'package:mydr/features/symptoms/widgets/recent_symptom_tile.dart';

/// Home screen card with the family's latest symptom records from the shared
/// [SymptomController]. Each one opens for editing; [onShowAll] (when given)
/// leads to the whole journal.
class RecentSymptomsCard extends StatelessWidget {
  const RecentSymptomsCard({
    super.key,
    this.onShowAll,
    this.clock = DateTime.now,
  });

  final VoidCallback? onShowAll;

  /// Source of the current time; replaceable in tests.
  final DateTime Function() clock;

  static const int maxShown = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = AppScope.of(context);
    final symptoms = scope.symptomController;
    final family = scope.familyController;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.monitor_heart_outlined,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    AppStrings.recentSymptomsTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            AppStrings.symptomsDisclaimer,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ListenableBuilder(
            listenable: Listenable.merge([symptoms, family]),
            builder: (context, _) {
              final entries = symptoms.entries;

              if (entries.isEmpty) {
                if (symptoms.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (symptoms.hasLoadError) {
                  return Column(
                    children: [
                      const EmptyState(
                        icon: Icons.error_outline,
                        title: AppStrings.symptomsLoadErrorTitle,
                        message: AppStrings.symptomsLoadErrorMessage,
                      ),
                      TextButton(
                        onPressed: symptoms.load,
                        child: const Text(AppStrings.retry),
                      ),
                    ],
                  );
                }
                return const EmptyState(
                  icon: Icons.monitor_heart_outlined,
                  title: AppStrings.recentSymptomsEmptyTitle,
                  message: AppStrings.recentSymptomsEmptyMessage,
                );
              }

              final onShowAll = this.onShowAll;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, entry)
                      in entries.take(maxShown).indexed) ...[
                    if (index > 0) const Divider(height: 1),
                    RecentSymptomTile(
                      key: ValueKey(entry.id),
                      entry: entry,
                      memberName:
                          family.memberById(entry.memberId)?.name ??
                          AppStrings.unknownMember,
                      onTap: () => Navigator.of(context).push(
                        SymptomFormScreen.editRoute(entry.id, clock: clock),
                      ),
                    ),
                  ],
                  if (onShowAll != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: TextButton.icon(
                        onPressed: onShowAll,
                        icon: const Icon(Icons.list_alt),
                        label: const Text(AppStrings.showAllSymptoms),
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
