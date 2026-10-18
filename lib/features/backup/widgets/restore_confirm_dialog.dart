import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/backup/backup_service.dart';
import 'package:mydr/data/backup/backup_snapshot.dart';
import 'package:mydr/features/backup/backup_messages.dart';

/// The explicit confirmation a restore needs: what the backup holds, what
/// is on the device now and will be replaced, and a box the user must
/// tick. Returns true only when confirmed.
Future<bool> showRestoreConfirmDialog(
  BuildContext context, {
  required PreparedRestore restore,
  required BackupCounts? local,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => RestoreConfirmDialog(restore: restore, local: local),
  );
  return confirmed ?? false;
}

class RestoreConfirmDialog extends StatefulWidget {
  const RestoreConfirmDialog({
    super.key,
    required this.restore,
    required this.local,
  });

  final PreparedRestore restore;

  /// Null if it could not be read.
  final BackupCounts? local;

  @override
  State<RestoreConfirmDialog> createState() => _RestoreConfirmDialogState();
}

class _RestoreConfirmDialogState extends State<RestoreConfirmDialog> {
  bool _understood = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final local = widget.local;
    final restore = widget.restore;

    Widget counts(String title, BackupCounts counts) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        for (final line in describeCounts(counts)) Text(line),
      ],
    );

    return AlertDialog(
      icon: Icon(Icons.restore, color: colorScheme.error),
      title: const Text(AppStrings.restoreConfirmTitle),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              AppStrings.restoreFrom(
                formatBackupTime(restore.backup.createdAt, localizations),
              ),
            ),
            const SizedBox(height: 12),
            counts(AppStrings.restoreBackupContains, restore.counts),
            if (restore.missingFiles > 0) ...[
              const SizedBox(height: 8),
              Text(
                AppStrings.restoreMissingFiles(restore.missingFiles),
                style: theme.textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            if (local == null || !local.isEmpty)
              counts(
                AppStrings.restoreDeviceHas,
                local ??
                    const BackupCounts(
                      familyMembers: 0,
                      appointments: 0,
                      doctorQuestions: 0,
                      symptoms: 0,
                      visitMedia: 0,
                      medications: 0,
                      doseRecords: 0,
                    ),
              )
            else
              const Text(AppStrings.restoreDeviceEmpty),
            const SizedBox(height: 12),
            Text(
              AppStrings.restoreReplacesWarning,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
            ),
            CheckboxListTile(
              value: _understood,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              title: const Text(AppStrings.restoreUnderstand),
              onChanged: (value) =>
                  setState(() => _understood = value ?? false),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(AppStrings.cancel),
        ),
        FilledButton(
          onPressed: _understood ? () => Navigator.of(context).pop(true) : null,
          style: FilledButton.styleFrom(
            backgroundColor: colorScheme.error,
            foregroundColor: colorScheme.onError,
          ),
          child: const Text(AppStrings.restoreConfirm),
        ),
      ],
    );
  }
}
