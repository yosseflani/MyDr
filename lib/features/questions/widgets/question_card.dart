import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/features/appointments/appointment_formatting.dart';

/// Card for one question to the doctor: the text, who it is about, whether
/// it was handled, the linked appointment (if any) and the recorded answer.
///
/// The status can be toggled from the card. While [isUpdating], the toggle
/// shows progress and ignores taps. The question text can be copied with
/// [onCopy]. Tappable as a whole only when [onTap] is given.
class QuestionCard extends StatelessWidget {
  const QuestionCard({
    super.key,
    required this.question,
    required this.memberName,
    required this.linkedAppointment,
    required this.now,
    required this.onToggleResolved,
    required this.onCopy,
    this.isUpdating = false,
    this.showAppointment = true,
    this.onTap,
  });

  final DoctorQuestion question;
  final String memberName;

  /// The appointment the question is linked to, or null if it is a general
  /// question or the appointment is not available.
  final Appointment? linkedAppointment;

  /// Used to show the appointment time relative to today.
  final DateTime now;
  final VoidCallback onToggleResolved;
  final VoidCallback onCopy;
  final bool isUpdating;

  /// Whether to show the linked appointment (or "general question"). Off
  /// where the appointment is already obvious, e.g. on its own screen.
  final bool showAppointment;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final resolved = question.isResolved;
    final answer = question.doctorAnswer?.trim() ?? '';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppCard.borderRadius),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(8, 12, 16, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ResolvedToggle(
                  resolved: resolved,
                  isUpdating: isUpdating,
                  onPressed: onToggleResolved,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        question.text,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: resolved ? colorScheme.onSurfaceVariant : null,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _StatusChip(resolved: resolved),
                          _IconText(
                            icon: Icons.person_outline,
                            text: memberName,
                          ),
                        ],
                      ),
                      if (showAppointment) ...[
                        const SizedBox(height: 6),
                        _IconText(
                          icon: question.appointmentId == null
                              ? Icons.help_outline
                              : Icons.event,
                          text: _appointmentLine(context),
                        ),
                      ],
                      if (answer.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _RecordedAnswer(answer: answer),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: AppStrings.copyQuestion,
                  onPressed: onCopy,
                  icon: Icon(Icons.copy_outlined, color: colorScheme.outline),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _appointmentLine(BuildContext context) {
    if (question.appointmentId == null) return AppStrings.generalQuestion;
    final appointment = linkedAppointment;
    if (appointment == null) return AppStrings.linkedAppointmentMissing;
    final when = formatAppointmentDateTime(
      appointment.dateTime,
      now,
      MaterialLocalizations.of(context),
    );
    return '${appointment.doctorName} · $when';
  }
}

/// Round check button for the handled/not handled status, or a progress
/// indicator while the change is being saved.
class _ResolvedToggle extends StatelessWidget {
  const _ResolvedToggle({
    required this.resolved,
    required this.isUpdating,
    required this.onPressed,
  });

  final bool resolved;
  final bool isUpdating;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isUpdating) {
      return const SizedBox.square(
        dimension: 48,
        child: Padding(
          padding: EdgeInsets.all(14),
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return IconButton(
      tooltip: resolved
          ? AppStrings.markQuestionUnresolved
          : AppStrings.markQuestionResolved,
      onPressed: onPressed,
      icon: Icon(
        resolved ? Icons.check_circle : Icons.radio_button_unchecked,
        color: resolved ? colorScheme.primary : colorScheme.outline,
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.resolved});

  final bool resolved;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: resolved
            ? colorScheme.primaryContainer
            : colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        resolved
            ? AppStrings.questionStatusResolved
            : AppStrings.questionStatusUnresolved,
        style: theme.textTheme.labelSmall?.copyWith(
          color: resolved
              ? colorScheme.onPrimaryContainer
              : colorScheme.onTertiaryContainer,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _IconText extends StatelessWidget {
  const _IconText({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// The doctor's answer as the user recorded it; shown as-is, never
/// interpreted.
class _RecordedAnswer extends StatelessWidget {
  const _RecordedAnswer({required this.answer});

  final String answer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
      child: MergeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.recordedAnswerLabel,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 2),
            Text(answer, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
