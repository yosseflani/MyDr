import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/section_header.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/features/questions/doctor_question_form_screen.dart';
import 'package:mydr/features/questions/widgets/question_tile.dart';

/// The questions linked to an appointment, for its details screen: each can
/// be opened for editing or marked as handled, and new ones can be added
/// already linked to the appointment.
class AppointmentQuestionsSection extends StatelessWidget {
  const AppointmentQuestionsSection({
    super.key,
    required this.appointment,
    required this.clock,
  });

  final Appointment appointment;

  /// Source of the current time; replaceable in tests.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).doctorQuestionController;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final theme = Theme.of(context);
        final questions = controller.forAppointment(appointment.id);
        final now = clock();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SectionHeader(title: AppStrings.doctorQuestionsTitle),
            if (questions.isEmpty)
              Padding(
                padding: const EdgeInsetsDirectional.only(start: 4),
                child: Text(
                  AppStrings.noQuestionsForAppointment,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            for (final (index, question) in questions.indexed) ...[
              if (index > 0) const SizedBox(height: 12),
              QuestionTile(
                key: ValueKey(question.id),
                question: question,
                now: now,
                // Already shown at the top of the appointment screen.
                showAppointment: false,
                onTap: () => Navigator.of(context).push(
                  DoctorQuestionFormScreen.editRoute(question.id, clock: clock),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: FilledButton.tonalIcon(
                onPressed: () => Navigator.of(context).push(
                  DoctorQuestionFormScreen.addRoute(
                    initialMemberId: appointment.memberId,
                    initialAppointmentId: appointment.id,
                    clock: clock,
                  ),
                ),
                icon: const Icon(Icons.add_comment_outlined),
                label: const Text(AppStrings.addQuestionToAppointment),
              ),
            ),
          ],
        );
      },
    );
  }
}
