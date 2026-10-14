import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';

/// Asks whether to leave a form without saving. "Keep editing" is the
/// default. Returns true only if the user chose to leave.
Future<bool> showDiscardChangesDialog(BuildContext context) async {
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text(AppStrings.discardChangesTitle),
      content: const Text(AppStrings.discardChangesMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(AppStrings.discardChanges),
        ),
        FilledButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.keepEditing),
        ),
      ],
    ),
  );
  return leave ?? false;
}
