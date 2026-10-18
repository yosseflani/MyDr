import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/inline_error_message.dart';
import 'package:mydr/data/backup/recovery_key.dart';

/// The key in large monospace groups, selectable but never copied for the
/// user: the clipboard is readable by other apps.
class RecoveryKeyText extends StatelessWidget {
  const RecoveryKeyText({super.key, required this.recoveryKey});

  final RecoveryKey recoveryKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      // Latin characters, read left to right even in a Hebrew layout.
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: SelectableText(
          recoveryKey.format().replaceAll('-', ' '),
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontFamily: 'monospace',
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            height: 1.6,
          ),
        ),
      ),
    );
  }
}

/// Shows a new key and returns true once the user confirmed they wrote it
/// down, by typing its last four characters.
Future<bool> showNewRecoveryKeyDialog(
  BuildContext context,
  RecoveryKey key, {
  required bool hasOlderBackups,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _NewRecoveryKeyDialog(
      recoveryKey: key,
      hasOlderBackups: hasOlderBackups,
    ),
  );
  return confirmed ?? false;
}

class _NewRecoveryKeyDialog extends StatefulWidget {
  const _NewRecoveryKeyDialog({
    required this.recoveryKey,
    required this.hasOlderBackups,
  });

  final RecoveryKey recoveryKey;
  final bool hasOlderBackups;

  @override
  State<_NewRecoveryKeyDialog> createState() => _NewRecoveryKeyDialogState();
}

class _NewRecoveryKeyDialogState extends State<_NewRecoveryKeyDialog> {
  final _controller = TextEditingController();
  bool _mismatch = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _confirm() {
    final lastGroup = widget.recoveryKey.format().split('-').last;
    final typed = _controller.text.trim().toUpperCase();
    if (typed != lastGroup) {
      setState(() => _mismatch = true);
      return;
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AlertDialog(
      icon: const Icon(Icons.key),
      title: const Text(AppStrings.newRecoveryKeyTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(AppStrings.newRecoveryKeyMessage),
            if (widget.hasOlderBackups) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.newRecoveryKeyOldBackups,
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 16),
            RecoveryKeyText(recoveryKey: widget.recoveryKey),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              maxLength: 4,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              decoration: InputDecoration(
                labelText: AppStrings.confirmLastGroupLabel,
                border: const OutlineInputBorder(),
                errorText: _mismatch
                    ? AppStrings.confirmLastGroupMismatch
                    : null,
              ),
              onSubmitted: (_) => _confirm(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _confirm,
          child: const Text(AppStrings.recoveryKeySaved),
        ),
      ],
    );
  }
}

/// Asks for a recovery key and returns what was typed, or null if
/// cancelled. [error] is shown under the field (e.g. after a wrong key).
Future<String?> showEnterRecoveryKeyDialog(
  BuildContext context, {
  String? error,
}) => showDialog<String>(
  context: context,
  builder: (_) => _EnterRecoveryKeyDialog(error: error),
);

class _EnterRecoveryKeyDialog extends StatefulWidget {
  const _EnterRecoveryKeyDialog({this.error});

  final String? error;

  @override
  State<_EnterRecoveryKeyDialog> createState() =>
      _EnterRecoveryKeyDialogState();
}

class _EnterRecoveryKeyDialogState extends State<_EnterRecoveryKeyDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void initState() {
    super.initState();
    _error = widget.error;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    try {
      RecoveryKey.parse(_controller.text);
    } on FormatException {
      setState(() => _error = AppStrings.recoveryKeyInvalid);
      return;
    }
    Navigator.of(context).pop(_controller.text);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      icon: const Icon(Icons.key),
      title: const Text(AppStrings.recoveryKeyTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_error case final error?) ...[
              InlineErrorMessage(message: error),
              const SizedBox(height: 12),
            ],
            Directionality(
              textDirection: TextDirection.ltr,
              child: TextField(
                controller: _controller,
                autofocus: true,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                keyboardType: TextInputType.visiblePassword,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: const InputDecoration(
                  labelText: AppStrings.recoveryKeyFieldLabel,
                  hintText: AppStrings.recoveryKeyHint,
                  border: OutlineInputBorder(),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text(AppStrings.continueLabel),
        ),
      ],
    );
  }
}

/// Shows the saved key again.
Future<void> showRecoveryKeyDialog(BuildContext context, RecoveryKey key) =>
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.key),
        title: const Text(AppStrings.recoveryKeyTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RecoveryKeyText(recoveryKey: key),
            const SizedBox(height: 12),
            const Text(AppStrings.recoveryKeyRevealWarning),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(AppStrings.close),
          ),
        ],
      ),
    );
