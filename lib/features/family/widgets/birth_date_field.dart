import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';

/// Optional birth date picker. Tapping opens a date picker limited to
/// past dates; a clear button removes the selection.
class BirthDateField extends StatelessWidget {
  const BirthDateField({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  final bool enabled;

  static final DateTime firstDate = DateTime(1900);

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      firstDate: firstDate,
      lastDate: today,
      initialDate: value ?? today,
      helpText: AppStrings.birthDatePickerHelp,
    );
    if (picked != null) onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final currentValue = value;
    final formatted = currentValue == null
        ? null
        : MaterialLocalizations.of(context).formatCompactDate(currentValue);

    return Semantics(
      button: true,
      enabled: enabled,
      child: InkWell(
        onTap: enabled ? () => _pickDate(context) : null,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          isEmpty: formatted == null,
          decoration: InputDecoration(
            labelText: AppStrings.birthDateOptionalLabel,
            enabled: enabled,
            border: const OutlineInputBorder(),
            prefixIcon: const Icon(Icons.cake_outlined),
            suffixIcon: currentValue == null
                ? null
                : IconButton(
                    tooltip: AppStrings.clearBirthDate,
                    icon: const Icon(Icons.clear),
                    onPressed: enabled ? () => onChanged(null) : null,
                  ),
          ),
          child: Text(formatted ?? ''),
        ),
      ),
    );
  }
}
