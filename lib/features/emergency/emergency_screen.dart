import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/core/widgets/section_header.dart';
import 'package:mydr/data/emergency/emergency_numbers.dart';
import 'package:mydr/features/emergency/widgets/emergency_dial_action.dart';
import 'package:mydr/features/emergency/widgets/first_aid_library_section.dart';
import 'package:mydr/features/emergency/widgets/medical_call_button.dart';

/// Emergency center: one large button to dial Magen David Adom (101), the
/// other official emergency numbers, and the first-aid library.
///
/// The call buttons are built from constants, with nothing to load, so they
/// are always there, whatever the state of the library below them. No
/// demo-data notice: the numbers are real.
class EmergencyScreen extends StatelessWidget {
  const EmergencyScreen({super.key});

  static const double _maxContentWidth = 600;

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const EmergencyScreen());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final otherNumbers = EmergencyNumbers.israel.where(
      (number) => number.service != EmergencyService.medical,
    );

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.emergencyCenterTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              24 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              const MedicalCallButton(),
              const SizedBox(height: 8),
              Text(AppStrings.dialerHint, style: secondary),
              const SizedBox(height: 24),
              const SectionHeader(title: AppStrings.otherEmergencyNumbers),
              for (final (index, number) in otherNumbers.indexed) ...[
                if (index > 0) const SizedBox(height: 12),
                _NumberTile(number: number),
              ],
              const SizedBox(height: 24),
              const SectionHeader(title: AppStrings.firstAidSectionTitle),
              const FirstAidLibrarySection(),
              const SizedBox(height: 24),
              Text(AppStrings.emergencyDisclaimer, style: secondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _NumberTile extends StatelessWidget {
  const _NumberTile({required this.number});

  final EmergencyNumber number;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = emergencyServiceName(number.service);

    return EmergencyDialAction(
      number: number,
      builder: (context, onPressed) => Semantics(
        button: true,
        label: AppStrings.callServiceLabel(name, number.number),
        excludeSemantics: true,
        child: AppCard(
          padding: EdgeInsets.zero,
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              onTap: onPressed,
              borderRadius: BorderRadius.circular(AppCard.borderRadius),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 64),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.call, color: theme.colorScheme.primary),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        number.number,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
