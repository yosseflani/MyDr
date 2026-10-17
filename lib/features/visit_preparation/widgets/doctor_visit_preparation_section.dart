import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/features/questions/widgets/appointment_questions_section.dart';
import 'package:mydr/features/visit_preparation/widgets/visit_media_section.dart';

/// Everything to bring to the appointment: the questions for the doctor
/// (the existing questions feature, not a copy) and the photos and videos
/// documenting symptoms that may change or disappear before the visit.
class DoctorVisitPreparationSection extends StatelessWidget {
  const DoctorVisitPreparationSection({
    super.key,
    required this.appointment,
    required this.clock,
  });

  final Appointment appointment;

  /// Source of the current time; replaceable in tests.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(Icons.checklist, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  AppStrings.visitPreparationTitle,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          AppStrings.visitPreparationIntro,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 16),
        AppointmentQuestionsSection(appointment: appointment, clock: clock),
        const SizedBox(height: 24),
        VisitMediaSection(appointment: appointment),
      ],
    );
  }
}
