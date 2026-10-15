import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/inline_error_message.dart';
import 'package:mydr/data/models/doctor_question.dart';

/// Confirmation dialog for deleting a question.
///
/// Shows the question text and that the deletion cannot be undone. The
/// deletion itself is [DoctorQuestionController.delete]; this dialog only
/// shows its progress and outcome, and closes with `true` on success.
class DeleteQuestionDialog extends StatefulWidget {
  const DeleteQuestionDialog({super.key, required this.question});

  final DoctorQuestion question;

  /// Shows the dialog. Returns true if the question was deleted.
  static Future<bool> show(
    BuildContext context,
    DoctorQuestion question,
  ) async {
    final deleted = await showDialog<bool>(
      context: context,
      // Only the buttons close it, so it is never dismissed by accident.
      barrierDismissible: false,
      builder: (_) => DeleteQuestionDialog(question: question),
    );
    return deleted ?? false;
  }

  @override
  State<DeleteQuestionDialog> createState() => _DeleteQuestionDialogState();
}

class _DeleteQuestionDialogState extends State<DeleteQuestionDialog> {
  bool _isDeleting = false;
  bool _failed = false;

  Future<void> _delete() async {
    if (_isDeleting) return;
    final controller = AppScope.of(context).doctorQuestionController;
    setState(() {
      _isDeleting = true;
      _failed = false;
    });

    final deleted = await controller.delete(
      widget.question.id,
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

    return PopScope<bool>(
      canPop: !_isDeleting,
      child: AlertDialog(
        icon: Icon(Icons.delete_outline, color: colorScheme.error),
        title: const Text(AppStrings.deleteQuestionTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_failed) ...[
                const InlineErrorMessage(
                  message: AppStrings.deleteQuestionFailed,
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
                child: Text(
                  widget.question.text,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(AppStrings.deleteQuestionKeepsOthers),
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
                        : AppStrings.deleteQuestion,
                  ),
          ),
        ],
      ),
    );
  }
}
