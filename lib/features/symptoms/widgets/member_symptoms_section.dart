import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/detail_section.dart';
import 'package:mydr/features/symptoms/symptom_form_screen.dart';
import 'package:mydr/features/symptoms/symptom_track_screen.dart';
import 'package:mydr/features/symptoms/symptoms_screen.dart';
import 'package:mydr/features/symptoms/widgets/recent_symptom_tile.dart';

/// A family member's latest symptom records for their profile: up to
/// [maxPreview] of them (each opens for editing, or its symptom's track),
/// and links to recording a symptom for them and to all of their records.
///
/// Only ever shows records of [memberId].
class MemberSymptomsSection extends StatelessWidget {
  const MemberSymptomsSection({
    super.key,
    required this.memberId,
    this.clock = DateTime.now,
  });

  final String memberId;

  /// Source of the current time; replaceable in tests.
  final DateTime Function() clock;

  static const int maxPreview = 3;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).symptomController;

    return DetailSection(
      title: AppStrings.recentSymptomsTitle,
      icon: Icons.monitor_heart_outlined,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final theme = Theme.of(context);
          final secondary = theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          );
          final history = controller.history(memberId: memberId);
          final navigator = Navigator.of(context);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (history.isEmpty && controller.hasLoadError)
                Row(
                  children: [
                    const Expanded(
                      child: Text(AppStrings.symptomsLoadErrorTitle),
                    ),
                    TextButton(
                      onPressed: controller.load,
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                )
              else if (history.isEmpty && controller.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (history.isEmpty)
                const Text(AppStrings.memberSymptomsEmpty)
              else ...[
                Text(
                  AppStrings.symptomRecordCount(history.length),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                for (final entry in history.take(maxPreview))
                  RecentSymptomTile(
                    key: ValueKey(entry.id),
                    entry: entry,
                    onTap: () => navigator.push(
                      SymptomFormScreen.editRoute(entry.id, clock: clock),
                    ),
                    onOpenTrack: () => navigator.push(
                      SymptomTrackScreen.route(
                        memberId: memberId,
                        name: entry.name,
                        clock: clock,
                      ),
                    ),
                  ),
              ],
              const SizedBox(height: 8),
              Text(AppStrings.symptomsDisclaimer, style: secondary),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => navigator.push(
                      SymptomFormScreen.addRoute(
                        initialMemberId: memberId,
                        clock: clock,
                      ),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.actionLogSymptom),
                  ),
                  if (history.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => navigator.push(
                        SymptomsScreen.route(
                          initialMemberId: memberId,
                          clock: clock,
                        ),
                      ),
                      icon: const Icon(Icons.list_alt),
                      label: const Text(AppStrings.allMemberSymptoms),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
