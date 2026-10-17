import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/inline_error_message.dart';
import 'package:mydr/data/models/medication.dart';

/// Confirmation dialog for deleting a medication with its dose records.
///
/// Shows which medication, whose, how many records go with it, and that
/// the deletion cannot be undone. The deletion itself is
/// [MedicationController.delete]; this dialog shows its progress and
/// outcome, and closes with `true` on success.
class DeleteMedicationDialog extends StatefulWidget {
  const DeleteMedicationDialog({
    super.key,
    required this.medication,
    required this.memberName,
    required this.recordCount,
  });

  final Medication medication;
  final String memberName;
  final int recordCount;

  /// Shows the dialog. Returns true if the medication was deleted.
  static Future<bool> show(
    BuildContext context,
    Medication medication, {
    required String memberName,
  }) async {
    final recordCount = AppScope.of(
      context,
    ).medicationController.records(medicationId: medication.id).length;
    final deleted = await showDialog<bool>(
      context: context,
      // Only the buttons close it, so it is never dismissed by accident.
      barrierDismissible: false,
      builder: (_) => DeleteMedicationDialog(
        medication: medication,
        memberName: memberName,
        recordCount: recordCount,
      ),
    );
    return deleted ?? false;
  }

  @override
  State<DeleteMedicationDialog> createState() => _DeleteMedicationDialogState();
}

class _DeleteMedicationDialogState extends State<DeleteMedicationDialog> {
  bool _isDeleting = false;
  bool _failed = false;

  Future<void> _delete() async {
    if (_isDeleting) return;
    final controller = AppScope.of(context).medicationController;
    setState(() {
      _isDeleting = true;
      _failed = false;
    });

    final deleted = await controller.delete(
      widget.medication.id,
      userConfirmed: true,
    );
    if (!mounted) return;

    if (deleted) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isDeleting = false;
      _failed = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final medication = widget.medication;

    return PopScope<bool>(
      canPop: !_isDeleting,
      child: AlertDialog(
        icon: Icon(Icons.delete_outline, color: colorScheme.error),
        title: const Text(AppStrings.deleteMedicationTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_failed) ...[
                const InlineErrorMessage(
                  message: AppStrings.deleteMedicationFailed,
                ),
                const SizedBox(height: 16),
              ],
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  // Contrasts with the dialog's own surface color.
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medication.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.memberName),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Text(AppStrings.deleteMedicationRecords(widget.recordCount)),
              const SizedBox(height: 8),
              const Text(AppStrings.deleteMedicationRemovesReminders),
              const SizedBox(height: 12),
              Text(
                AppStrings.deleteIrreversible,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: _isDeleting
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: _isDeleting ? null : _delete,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: _isDeleting
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onError,
                    ),
                  )
                : Text(
                    _failed
                        ? AppStrings.retryDelete
                        : AppStrings.deleteMedication,
                  ),
          ),
        ],
      ),
    );
  }
}
