import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/data/emergency/emergency_numbers.dart';
import 'package:mydr/features/emergency/widgets/emergency_dial_action.dart';

/// Large, full-width button that opens the dialer with Magen David Adom
/// (101). Built from constants only, so it never waits for anything.
///
/// [compact] puts everything on one line, for a bar pinned to the bottom of
/// a screen.
class MedicalCallButton extends StatelessWidget {
  const MedicalCallButton({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    const number = EmergencyNumbers.medical;

    return EmergencyDialAction(
      number: number,
      builder: (context, onPressed) => Semantics(
        button: true,
        // The child's own semantics, with its tap action, are excluded.
        onTap: onPressed,
        label: AppStrings.callServiceLabel(
          AppStrings.serviceMedical,
          number.number,
        ),
        excludeSemantics: true,
        child: FilledButton(
          onPressed: onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
            minimumSize: Size.fromHeight(compact ? 56 : 88),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppCard.borderRadius),
            ),
          ),
          child: compact
              ? Row(
                  children: [
                    const Icon(Icons.call, size: 28),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${AppStrings.callMedicalEmergencyTitle} · '
                        '${number.number}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: colorScheme.onError,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Icon(Icons.call, size: 36),
                    const SizedBox(width: 16),
                    // Stacked rather than side by side, so both still fit with
                    // very large text on a narrow screen.
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppStrings.callMedicalEmergencyTitle,
                            style: theme.textTheme.titleLarge?.copyWith(
                              color: colorScheme.onError,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            number.number,
                            style: theme.textTheme.displaySmall?.copyWith(
                              color: colorScheme.onError,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
