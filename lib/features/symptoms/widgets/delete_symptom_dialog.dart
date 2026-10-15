import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/inline_error_message.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/features/symptoms/symptom_formatting.dart';

/// Confirmation dialog for deleting a symptom record.
///
/// Shows which record (symptom, family member and when) and that the
/// deletion cannot be undone. The deletion itself is
/// [SymptomController.delete]; this dialog only shows its progress and
/// outcome, and closes with `true` on success.
class DeleteSymptomDialog extends StatefulWidget {
  const DeleteSymptomDialog({
    super.key,
    required this.entry,
    required this.memberName,
  });

  final SymptomEntry entry;
  final String memberName;

  /// Shows the dialog. Returns true if the record was deleted.
  static Future<bool> show(
    BuildContext context,
    SymptomEntry entry, {
    required String memberName,
  }) async {
    final deleted = await showDialog<bool>(
      context: context,
      // Only the buttons close it, so it is never dismissed by accident.
      barrierDismissible: false,
      builder: (_) => DeleteSymptomDialog(entry: entry, memberName: memberName),
    );
    return deleted ?? false;
  }

  @override
  State<DeleteSymptomDialog> createState() => _DeleteSymptomDialogState();
}

class _DeleteSymptomDialogState extends State<DeleteSymptomDialog> {
  bool _isDeleting = false;
  bool _failed = false;

  Future<void> _delete() async {
    if (_isDeleting) return;
    final controller = AppScope.of(context).symptomController;
    setState(() {
      _isDeleting = true;
      _failed = false;
    });

    final deleted = await controller.delete(
      widget.entry.id,
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
    final entry = widget.entry;

    return PopScope<bool>(
      canPop: !_isDeleting,
      child: AlertDialog(
        icon: Icon(Icons.delete_outline, color: colorScheme.error),
        title: const Text(AppStrings.deleteSymptomTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_failed) ...[
                const InlineErrorMessage(
                  message: AppStrings.deleteSymptomFailed,
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
                      entry.name,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.memberName),
                    Text(
                      formatSymptomDateTime(
                        entry.startedAt,
                        MaterialLocalizations.of(context),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(AppStrings.deleteSymptomKeepsOthers),
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
                    _failed ? AppStrings.retryDelete : AppStrings.deleteSymptom,
                  ),
          ),
        ],
      ),
    );
  }
}
