import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/inline_error_message.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/appointments/appointment_formatting.dart';

enum _Phase { countingQuestions, countFailed, ready, deleting }

/// Confirmation dialog for deleting an appointment.
///
/// Shows exactly which appointment will be deleted and how many questions
/// are linked to it, and only allows deleting once that count has loaded.
/// The deletion itself is [AppointmentController.delete]; this dialog only
/// shows its progress and outcome, and closes with `true` on success.
class DeleteAppointmentDialog extends StatefulWidget {
  const DeleteAppointmentDialog({
    super.key,
    required this.appointment,
    required this.memberName,
    required this.now,
  });

  final Appointment appointment;
  final String memberName;

  /// Used to show the appointment time relative to today.
  final DateTime now;

  /// Shows the dialog. Returns true if the appointment was deleted.
  static Future<bool> show(
    BuildContext context, {
    required Appointment appointment,
    required String memberName,
    required DateTime now,
  }) async {
    final deleted = await showDialog<bool>(
      context: context,
      // Only the buttons close it, so it is never dismissed by accident.
      barrierDismissible: false,
      builder: (_) => DeleteAppointmentDialog(
        appointment: appointment,
        memberName: memberName,
        now: now,
      ),
    );
    return deleted ?? false;
  }

  @override
  State<DeleteAppointmentDialog> createState() =>
      _DeleteAppointmentDialogState();
}

class _DeleteAppointmentDialogState extends State<DeleteAppointmentDialog> {
  late final AppointmentController _controller;
  bool _isInitialized = false;

  _Phase _phase = _Phase.countingQuestions;
  int? _questionCount;

  /// Photos and videos that will be deleted with the appointment.
  int? _mediaCount;

  /// Explains the last failed attempt, or null.
  String? _failureMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;
    _controller = AppScope.of(context).appointmentController;
    _countQuestions();
  }

  /// Callers set [_Phase.countingQuestions] first if needed.
  Future<void> _countQuestions() async {
    final (count, mediaCount) = await (
      _controller.linkedQuestionCount(widget.appointment.id),
      _controller.linkedVisitMediaCount(widget.appointment.id),
    ).wait;
    if (!mounted) return;
    setState(() {
      _questionCount = count;
      _mediaCount = mediaCount;
      _phase = count == null || mediaCount == null
          ? _Phase.countFailed
          : _Phase.ready;
    });
  }

  void _retryCount() {
    setState(() => _phase = _Phase.countingQuestions);
    _countQuestions();
  }

  Future<void> _delete() async {
    if (_phase != _Phase.ready) return;
    setState(() {
      _phase = _Phase.deleting;
      _failureMessage = null;
    });

    final result = await _controller.delete(
      widget.appointment.id,
      userConfirmed: true,
    );
    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }

    // After a partial failure the questions are already unlinked, so the
    // count is refreshed to show what is actually linked now.
    setState(() {
      _failureMessage = switch (result.failedStep!) {
        AppointmentDeletionStep.detachQuestions =>
          AppStrings.deleteAppointmentFailed,
        AppointmentDeletionStep.visitMedia ||
        AppointmentDeletionStep.appointment =>
          AppStrings.deleteAppointmentPartiallyFailed(widget.memberName),
      };
      _phase = _Phase.countingQuestions;
    });
    await _countQuestions();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDeleting = _phase == _Phase.deleting;

    return PopScope<bool>(
      canPop: !isDeleting,
      child: AlertDialog(
        icon: Icon(Icons.event_busy, color: colorScheme.error),
        title: const Text(AppStrings.deleteAppointmentTitle),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_failureMessage case final message?) ...[
                InlineErrorMessage(message: message),
                const SizedBox(height: 16),
              ],
              _AppointmentSummary(
                appointment: widget.appointment,
                memberName: widget.memberName,
                now: widget.now,
              ),
              const SizedBox(height: 16),
              ..._buildQuestionsInfo(),
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
            onPressed: isDeleting
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: _phase == _Phase.ready ? _delete : null,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: isDeleting
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onError,
                    ),
                  )
                : Text(
                    _failureMessage == null
                        ? AppStrings.deleteAppointment
                        : AppStrings.retryDelete,
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildQuestionsInfo() {
    switch (_phase) {
      case _Phase.countingQuestions:
        return const [
          Row(
            children: [
              SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(AppStrings.deleteAppointmentQuestionsLoading),
              ),
            ],
          ),
        ];
      case _Phase.countFailed:
        return [
          const InlineErrorMessage(
            message: AppStrings.deleteAppointmentQuestionsFailed,
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _retryCount,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ),
        ];
      case _Phase.ready:
      case _Phase.deleting:
        final count = _questionCount!;
        final mediaCount = _mediaCount!;
        return [
          _InfoLine(
            icon: Icons.question_answer_outlined,
            text: count == 0
                ? AppStrings.deleteAppointmentNoQuestions
                : AppStrings.deleteAppointmentQuestions(
                    count,
                    widget.memberName,
                  ),
          ),
          if (mediaCount > 0) ...[
            const SizedBox(height: 8),
            _InfoLine(
              icon: Icons.photo_library_outlined,
              text: AppStrings.deleteAppointmentMedia(mediaCount),
            ),
          ],
        ];
    }
  }
}

/// Doctor, time and member of the appointment being deleted.
class _AppointmentSummary extends StatelessWidget {
  const _AppointmentSummary({
    required this.appointment,
    required this.memberName,
    required this.now,
  });

  final Appointment appointment;
  final String memberName;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // Contrasts with the dialog's own surface color.
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appointment.doctorName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          _InfoLine(
            icon: Icons.event,
            text: formatAppointmentDateTime(
              appointment.dateTime,
              now,
              MaterialLocalizations.of(context),
            ),
          ),
          const SizedBox(height: 2),
          _InfoLine(icon: Icons.person_outline, text: memberName),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(
            icon,
            size: 18,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ],
    );
  }
}
