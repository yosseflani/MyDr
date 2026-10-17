import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';

/// That the app gives no medical advice, and that reminders are only an
/// aid the operating system may delay or drop. Shown wherever medications
/// are listed or entered.
class MedicationNotice extends StatelessWidget {
  const MedicationNotice({super.key, this.showReminderNote = true});

  /// Whether to include the note about reminders.
  final bool showReminderNote;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;
    final style = theme.textTheme.bodySmall?.copyWith(color: color);

    Widget line(IconData icon, String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(child: Text(text, style: style)),
      ],
    );

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          line(Icons.info_outline, AppStrings.medicationsNoAdvice),
          if (showReminderNote) ...[
            const SizedBox(height: 6),
            line(Icons.notifications_none, AppStrings.remindersAreAnAid),
          ],
        ],
      ),
    );
  }
}
