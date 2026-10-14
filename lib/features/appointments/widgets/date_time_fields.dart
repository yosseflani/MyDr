import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';

/// Required date field that opens a date picker limited to
/// [firstDate]–[lastDate], opening on [today] when nothing is chosen yet.
class AppointmentDateField extends FormField<DateTime> {
  AppointmentDateField({
    super.key,
    super.initialValue,
    required DateTime firstDate,
    required DateTime lastDate,
    required DateTime today,
    required ValueChanged<DateTime> onChanged,
    super.enabled,
  }) : super(
         validator: (value) => value == null ? AppStrings.dateRequired : null,
         builder: (field) {
           final context = field.context;
           final value = field.value;

           Future<void> pick() async {
             // An existing value outside the range must not break the picker.
             final first = value != null && value.isBefore(firstDate)
                 ? value
                 : firstDate;
             final last = value != null && value.isAfter(lastDate)
                 ? value
                 : lastDate;
             final day = DateUtils.dateOnly(today);
             final fallback = day.isBefore(first) || day.isAfter(last)
                 ? first
                 : day;
             final picked = await showDatePicker(
               context: context,
               firstDate: first,
               lastDate: last,
               initialDate: value ?? fallback,
               helpText: AppStrings.appointmentDatePickerHelp,
             );
             if (picked == null) return;
             field.didChange(picked);
             onChanged(picked);
           }

           return _PickerFieldLayout(
             label: AppStrings.dateLabel,
             icon: Icons.calendar_today_outlined,
             text: value == null
                 ? null
                 : MaterialLocalizations.of(context).formatFullDate(value),
             errorText: field.errorText,
             onTap: field.widget.enabled ? pick : null,
           );
         },
       );
}

/// Required time field that opens a 24-hour time picker.
class AppointmentTimeField extends FormField<TimeOfDay> {
  AppointmentTimeField({
    super.key,
    super.initialValue,
    required ValueChanged<TimeOfDay> onChanged,
    super.enabled,
  }) : super(
         validator: (value) => value == null ? AppStrings.timeRequired : null,
         builder: (field) {
           final context = field.context;
           final value = field.value;

           Future<void> pick() async {
             final picked = await showTimePicker(
               context: context,
               initialTime: value ?? const TimeOfDay(hour: 9, minute: 0),
               helpText: AppStrings.appointmentTimePickerHelp,
               builder: (context, child) => MediaQuery(
                 data: MediaQuery.of(
                   context,
                 ).copyWith(alwaysUse24HourFormat: true),
                 child: child!,
               ),
             );
             if (picked == null) return;
             field.didChange(picked);
             onChanged(picked);
           }

           return _PickerFieldLayout(
             label: AppStrings.timeLabel,
             icon: Icons.schedule,
             text: value == null
                 ? null
                 : MaterialLocalizations.of(
                     context,
                   ).formatTimeOfDay(value, alwaysUse24HourFormat: true),
             errorText: field.errorText,
             onTap: field.widget.enabled ? pick : null,
           );
         },
       );
}

/// Looks like a text field; tapping it opens a picker.
class _PickerFieldLayout extends StatelessWidget {
  const _PickerFieldLayout({
    required this.label,
    required this.icon,
    required this.text,
    required this.errorText,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final String? text;
  final String? errorText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          isEmpty: text == null,
          decoration: InputDecoration(
            labelText: label,
            enabled: onTap != null,
            errorText: errorText,
            border: const OutlineInputBorder(),
            prefixIcon: Icon(icon),
          ),
          child: Text(text ?? ''),
        ),
      ),
    );
  }
}
