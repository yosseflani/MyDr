import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/data/emergency/emergency_numbers.dart';
import 'package:mydr/features/emergency/emergency_screen.dart';
import 'package:mydr/features/emergency/widgets/emergency_dial_action.dart';

/// Compact, clearly marked entry point for first aid and emergencies, with a
/// button that opens the dialer with 101 and one into the emergency center.
///
/// Intentionally shows no medical instructions: only the national emergency
/// number and a note that verified first-aid content will be added later.
class EmergencyCard extends StatelessWidget {
  const EmergencyCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      borderColor: colorScheme.error.withValues(alpha: 0.35),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colorScheme.errorContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.emergency, color: colorScheme.onErrorContainer),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.emergencyTitle,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AppStrings.emergencyCallLine,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.error,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  AppStrings.emergencyNoInstructions,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    EmergencyDialAction(
                      number: EmergencyNumbers.medical,
                      builder: (context, onPressed) => Semantics(
                        button: true,
                        label: AppStrings.callServiceLabel(
                          AppStrings.serviceMedical,
                          EmergencyNumbers.medical.number,
                        ),
                        excludeSemantics: true,
                        child: FilledButton.icon(
                          onPressed: onPressed,
                          style: FilledButton.styleFrom(
                            backgroundColor: colorScheme.error,
                            foregroundColor: colorScheme.onError,
                            minimumSize: const Size(0, 48),
                          ),
                          icon: const Icon(Icons.call),
                          label: const Text(AppStrings.callMedicalEmergency),
                        ),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () =>
                          Navigator.of(context).push(EmergencyScreen.route()),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      icon: const Icon(Icons.emergency_outlined),
                      label: const Text(AppStrings.openEmergencyCenter),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
