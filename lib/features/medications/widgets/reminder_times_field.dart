import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/features/medications/medication_formatting.dart';

/// The daily reminder times of a medication: chips that can be removed,
/// and a button that adds a time with a 24-hour time picker. Times are kept
/// in order and each only once. At least one is required.
class ReminderTimesField extends FormField<List<DoseTime>> {
  ReminderTimesField({
    super.key,
    required List<DoseTime> super.initialValue,
    required ValueChanged<List<DoseTime>> onChanged,
    super.enabled,
  }) : super(
         validator: (times) {
           if (times == null || times.isEmpty) {
             return AppStrings.reminderTimeRequired;
           }
           if (times.length > Medication.maxReminderTimes) {
             return AppStrings.tooManyReminderTimes(
               Medication.maxReminderTimes,
             );
           }
           return null;
         },
         builder: (field) {
           final context = field.context;
           final theme = Theme.of(context);
           final localizations = MaterialLocalizations.of(context);
           final times = field.value ?? const <DoseTime>[];
           final enabled = field.widget.enabled;
           final isFull = times.length >= Medication.maxReminderTimes;

           void set(List<DoseTime> updated) {
             final sorted = updated.toSet().toList()..sort();
             field.didChange(sorted);
             onChanged(sorted);
           }

           Future<void> add() async {
             final picked = await showTimePicker(
               context: context,
               initialTime: const TimeOfDay(hour: 8, minute: 0),
               helpText: AppStrings.reminderTimePickerHelp,
               builder: (context, child) => MediaQuery(
                 data: MediaQuery.of(
                   context,
                 ).copyWith(alwaysUse24HourFormat: true),
                 child: child!,
               ),
             );
             if (picked == null || !context.mounted) return;
             final time = DoseTime(picked.hour, picked.minute);
             if (times.contains(time)) {
               ScaffoldMessenger.of(context)
                 ..hideCurrentSnackBar()
                 ..showSnackBar(
                   const SnackBar(
                     content: Text(AppStrings.reminderTimeDuplicate),
                   ),
                 );
               return;
             }
             set([...times, time]);
           }

           return InputDecorator(
             decoration: InputDecoration(
               labelText: AppStrings.reminderTimesLabel,
               border: const OutlineInputBorder(),
               prefixIcon: const Icon(Icons.alarm),
               errorText: field.errorText,
               enabled: enabled,
             ),
             child: Wrap(
               spacing: 8,
               runSpacing: 8,
               crossAxisAlignment: WrapCrossAlignment.center,
               children: [
                 for (final time in times)
                   InputChip(
                     label: Text(formatDoseTime(time, localizations)),
                     isEnabled: enabled,
                     deleteButtonTooltipMessage: AppStrings.removeReminderTime(
                       formatDoseTime(time, localizations),
                     ),
                     onDeleted: () => set([
                       for (final t in times)
                         if (t != time) t,
                     ]),
                   ),
                 TextButton.icon(
                   onPressed: enabled && !isFull ? add : null,
                   icon: const Icon(Icons.add_alarm),
                   label: Text(
                     AppStrings.addReminderTime,
                     style: theme.textTheme.labelLarge,
                   ),
                 ),
               ],
             ),
           );
         },
       );
}
