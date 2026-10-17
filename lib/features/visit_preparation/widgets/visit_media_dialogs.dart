import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/inline_error_message.dart';
import 'package:mydr/data/models/visit_media.dart';
import 'package:mydr/features/visit_preparation/visit_media_controller.dart';

/// Adds or edits the description of a photo or video, and saves it.
/// Closes with true once saved.
class VisitMediaDescriptionDialog extends StatefulWidget {
  const VisitMediaDescriptionDialog({super.key, required this.media});

  final VisitMedia media;

  static const int maxLength = 500;

  static Future<bool> show(BuildContext context, VisitMedia media) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => VisitMediaDescriptionDialog(media: media),
    );
    return saved ?? false;
  }

  @override
  State<VisitMediaDescriptionDialog> createState() =>
      _VisitMediaDescriptionDialogState();
}

class _VisitMediaDescriptionDialogState
    extends State<VisitMediaDescriptionDialog> {
  late final TextEditingController _text = TextEditingController(
    text: widget.media.description ?? '',
  );
  bool _isSaving = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_isSaving) return;
    setState(() {
      _isSaving = true;
      _error = null;
    });
    final result = await AppScope.of(
      context,
    ).visitMediaController.updateDescription(widget.media.id, _text.text);
    if (!mounted) return;
    if (result == VisitMediaSaveResult.success) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _isSaving = false;
      _error = result == VisitMediaSaveResult.notFound
          ? AppStrings.visitMediaMissingDuringEdit
          : AppStrings.descriptionSaveFailed;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<bool>(
      canPop: !_isSaving,
      child: AlertDialog(
        title: const Text(AppStrings.visitMediaDescriptionTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_error case final error?) ...[
                InlineErrorMessage(message: error),
                const SizedBox(height: 12),
              ],
              TextField(
                controller: _text,
                autofocus: true,
                enabled: !_isSaving,
                minLines: 2,
                maxLines: 5,
                maxLength: VisitMediaDescriptionDialog.maxLength,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: AppStrings.visitMediaDescriptionLabel,
                  hintText: AppStrings.visitMediaDescriptionHint,
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(AppStrings.save),
          ),
        ],
      ),
    );
  }
}

/// Confirms and deletes a photo or video. Closes with true once deleted.
class DeleteVisitMediaDialog extends StatefulWidget {
  const DeleteVisitMediaDialog({super.key, required this.media});

  final VisitMedia media;

  static Future<bool> show(BuildContext context, VisitMedia media) async {
    final deleted = await showDialog<bool>(
      context: context,
      // Only the buttons close it, so it is never dismissed by accident.
      barrierDismissible: false,
      builder: (_) => DeleteVisitMediaDialog(media: media),
    );
    return deleted ?? false;
  }

  @override
  State<DeleteVisitMediaDialog> createState() => _DeleteVisitMediaDialogState();
}

class _DeleteVisitMediaDialogState extends State<DeleteVisitMediaDialog> {
  bool _isDeleting = false;
  bool _failed = false;

  Future<void> _delete() async {
    if (_isDeleting) return;
    setState(() {
      _isDeleting = true;
      _failed = false;
    });
    final deleted = await AppScope.of(
      context,
    ).visitMediaController.delete(widget.media.id, userConfirmed: true);
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
    final colorScheme = Theme.of(context).colorScheme;

    return PopScope<bool>(
      canPop: !_isDeleting,
      child: AlertDialog(
        icon: Icon(Icons.delete_outline, color: colorScheme.error),
        title: const Text(AppStrings.deleteVisitMediaTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_failed) ...[
                const InlineErrorMessage(
                  message: AppStrings.deleteVisitMediaFailed,
                ),
                const SizedBox(height: 12),
              ],
              const Text(AppStrings.deleteVisitMediaMessage),
              const SizedBox(height: 12),
              Text(
                AppStrings.deleteIrreversible,
                style: TextStyle(
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
                : Text(_failed ? AppStrings.retryDelete : AppStrings.delete),
          ),
        ],
      ),
    );
  }
}
