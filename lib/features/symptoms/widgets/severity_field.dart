import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/symptom_entry.dart';

/// Required choice of the user's own severity rating, from
/// [SymptomEntry.minSeverity] to [SymptomEntry.maxSeverity], with a note
/// that it is a personal rating and not a medical assessment.
///
/// Every level looks the same apart from being selected, so no level
/// suggests urgency. Each one is read out as "עוצמה N מתוך 5".
class SeverityField extends FormField<int> {
  SeverityField({
    super.key,
    super.initialValue,
    required ValueChanged<int> onChanged,
    super.enabled,
  }) : super(
         validator: (value) =>
             value == null ? AppStrings.severityRequired : null,
         builder: (field) {
           final theme = Theme.of(field.context);
           final colorScheme = theme.colorScheme;
           final value = field.value;
           final errorText = field.errorText;
           const max = SymptomEntry.maxSeverity;

           return Column(
             crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
               Text(
                 AppStrings.severityLabel,
                 style: theme.textTheme.titleSmall,
               ),
               const SizedBox(height: 8),
               SegmentedButton<int>(
                 showSelectedIcon: false,
                 emptySelectionAllowed: true,
                 segments: [
                   for (
                     var level = SymptomEntry.minSeverity;
                     level <= max;
                     level++
                   )
                     ButtonSegment(
                       value: level,
                       label: Text(
                         '$level',
                         semanticsLabel: AppStrings.severityOption(level, max),
                       ),
                     ),
                 ],
                 selected: {?value},
                 onSelectionChanged: field.widget.enabled
                     ? (selection) {
                         // Tapping the selected level again keeps it.
                         if (selection.isEmpty) return;
                         field.didChange(selection.single);
                         onChanged(selection.single);
                       }
                     : null,
               ),
               const SizedBox(height: 6),
               Text(
                 AppStrings.severityHint,
                 style: theme.textTheme.bodySmall?.copyWith(
                   color: colorScheme.onSurfaceVariant,
                 ),
               ),
               if (errorText != null) ...[
                 const SizedBox(height: 4),
                 Text(
                   errorText,
                   style: theme.textTheme.bodySmall?.copyWith(
                     color: colorScheme.error,
                   ),
                 ),
               ],
             ],
           );
         },
       );
}
