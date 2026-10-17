import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/detail_section.dart';
import 'package:mydr/features/medications/medication_detail_screen.dart';
import 'package:mydr/features/medications/medication_form_screen.dart';
import 'package:mydr/features/medications/medications_screen.dart';
import 'package:mydr/features/medications/widgets/medication_card.dart';

/// A family member's active medications for their profile, with links to
/// adding one and to all their medications and doses.
///
/// Only ever shows medications of [memberId].
class MemberMedicationsSection extends StatelessWidget {
  const MemberMedicationsSection({super.key, required this.memberId});

  final String memberId;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).medicationController;

    return DetailSection(
      title: AppStrings.memberMedicationsTitle,
      icon: Icons.medication_outlined,
      child: ListenableBuilder(
        listenable: controller,
        builder: (context, _) {
          final theme = Theme.of(context);
          final navigator = Navigator.of(context);
          final now = controller.now;
          final all = controller.medicationsFor(memberId);
          final active = all.where((m) => m.isActiveOn(now)).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (all.isEmpty && controller.hasLoadError)
                Row(
                  children: [
                    const Expanded(
                      child: Text(AppStrings.medicationsLoadErrorTitle),
                    ),
                    TextButton(
                      onPressed: controller.load,
                      child: const Text(AppStrings.retry),
                    ),
                  ],
                )
              else if (all.isEmpty && controller.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (active.isEmpty)
                const Text(AppStrings.memberMedicationsEmpty)
              else ...[
                Text(
                  AppStrings.activeMedicationCount(active.length),
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                for (final medication in active) ...[
                  const SizedBox(height: 8),
                  MedicationCard(
                    key: ValueKey(medication.id),
                    medication: medication,
                    now: now,
                    onTap: () => navigator.push(
                      MedicationDetailScreen.route(medication.id),
                    ),
                  ),
                ],
              ],
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.tonalIcon(
                    onPressed: () => navigator.push(
                      MedicationFormScreen.addRoute(initialMemberId: memberId),
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text(AppStrings.actionAddMedication),
                  ),
                  if (all.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => navigator.push(
                        MedicationsScreen.route(initialMemberId: memberId),
                      ),
                      icon: const Icon(Icons.list_alt),
                      label: const Text(AppStrings.allMemberMedications),
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
