import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/reminders/reminder_scheduler.dart';
import 'package:mydr/features/medications/medication_controller.dart';
import 'package:mydr/features/medications/medication_formatting.dart';

/// Whether reminders are working, and what to do if not.
///
/// Never blocks anything: medications and dose records work the same with
/// or without notifications.
class ReminderStatusCard extends StatefulWidget {
  const ReminderStatusCard({super.key});

  @override
  State<ReminderStatusCard> createState() => _ReminderStatusCardState();
}

class _ReminderStatusCardState extends State<ReminderStatusCard> {
  bool _isRequesting = false;

  /// Set once the user asked and notifications stayed off, so the hint
  /// about the system settings can be shown.
  bool _requestRefused = false;

  Future<void> _request(MedicationController controller) async {
    if (_isRequesting) return;
    setState(() => _isRequesting = true);
    final result = await controller.requestReminderPermission();
    if (!mounted) return;
    setState(() {
      _isRequesting = false;
      _requestRefused = result == ReminderAvailability.disabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).medicationController;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final status = controller.reminderStatus;
        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        if (status.hasFailed) {
          return _Banner(
            icon: Icons.error_outline,
            background: colorScheme.errorContainer,
            foreground: colorScheme.onErrorContainer,
            message: AppStrings.remindersFailed,
            action: TextButton(
              onPressed: controller.refreshReminders,
              child: const Text(AppStrings.retry),
            ),
          );
        }

        switch (status.availability) {
          case null:
            return const SizedBox.shrink();
          case ReminderAvailability.unsupported:
            return _Note(
              icon: Icons.info_outline,
              lines: const [AppStrings.remindersUnsupported],
            );
          case ReminderAvailability.disabled:
            return _Banner(
              icon: Icons.notifications_off_outlined,
              background: colorScheme.tertiaryContainer,
              foreground: colorScheme.onTertiaryContainer,
              message: _requestRefused
                  ? '${AppStrings.remindersDisabled}\n'
                        '${AppStrings.openNotificationSettingsHint}'
                  : AppStrings.remindersDisabled,
              action: TextButton(
                onPressed: _isRequesting ? null : () => _request(controller),
                child: const Text(AppStrings.enableReminders),
              ),
            );
          case ReminderAvailability.enabled:
            final plan = status.plan;
            final last = plan?.lastReminderAt;
            return _Note(
              icon: Icons.notifications_active_outlined,
              lines: [
                if (last == null)
                  AppStrings.remindersNoneScheduled
                else
                  AppStrings.remindersScheduledUntil(
                    formatDoseMoment(
                      last,
                      controller.now,
                      MaterialLocalizations.of(context),
                    ),
                  ),
                if (plan?.isTruncated ?? false) AppStrings.remindersTruncated,
                AppStrings.remindersPrivacy,
              ],
            );
        }
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({
    required this.icon,
    required this.background,
    required this.foreground,
    required this.message,
    required this.action,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final String message;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 4),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: foreground),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    message,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: foreground,
                    ),
                  ),
                ),
              ],
            ),
            Align(alignment: AlignmentDirectional.centerEnd, child: action),
          ],
        ),
      ),
    );
  }
}

class _Note extends StatelessWidget {
  const _Note({required this.icon, required this.lines});

  final IconData icon;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              lines.join('\n'),
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
  }
}
