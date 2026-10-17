import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/core/widgets/detail_section.dart';
import 'package:mydr/core/widgets/not_found_view.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/features/appointments/appointment_form_screen.dart';
import 'package:mydr/features/appointments/appointment_formatting.dart';
import 'package:mydr/features/appointments/widgets/delete_appointment_dialog.dart';
import 'package:mydr/features/visit_preparation/widgets/doctor_visit_preparation_section.dart';

/// Details of one appointment.
///
/// Receives only the appointment id and always reads the current data from
/// the shared [AppointmentController] (and the member name from
/// [FamilyController]), so it reflects changes made anywhere in the app.
class AppointmentDetailScreen extends StatelessWidget {
  const AppointmentDetailScreen({
    super.key,
    required this.appointmentId,
    this.clock = DateTime.now,
  });

  final String appointmentId;

  /// Source of the current time; replaceable in tests.
  final DateTime Function() clock;

  static const double _maxContentWidth = 600;

  static Route<void> route(
    String appointmentId, {
    DateTime Function() clock = DateTime.now,
  }) {
    return MaterialPageRoute<void>(
      builder: (_) =>
          AppointmentDetailScreen(appointmentId: appointmentId, clock: clock),
    );
  }

  /// Deletes only after the user confirms in [DeleteAppointmentDialog]; on
  /// success returns to the previous screen with a confirmation message.
  Future<void> _confirmAndDelete(
    BuildContext context,
    Appointment appointment,
    String memberName,
    DateTime now,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final deleted = await DeleteAppointmentDialog.show(
      context,
      appointment: appointment,
      memberName: memberName,
      now: now,
    );
    if (!deleted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(AppStrings.appointmentDeleted)),
      );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final appointments = scope.appointmentController;
    final family = scope.familyController;

    return ListenableBuilder(
      listenable: Listenable.merge([appointments, family]),
      builder: (context, _) {
        final appointment = appointments.appointmentById(appointmentId);

        final Widget body;
        if (appointment != null) {
          final memberName =
              family.memberById(appointment.memberId)?.name ??
              AppStrings.unknownMember;
          final now = clock();
          body = _AppointmentDetails(
            appointment: appointment,
            memberName: memberName,
            now: now,
            clock: clock,
            onDelete: () =>
                _confirmAndDelete(context, appointment, memberName, now),
          );
        } else if (appointments.isLoading) {
          body = const Center(child: CircularProgressIndicator());
        } else {
          body = const NotFoundView(
            icon: Icons.event_busy,
            title: AppStrings.appointmentNotFoundTitle,
            message: AppStrings.appointmentNotFoundMessage,
            backLabel: AppStrings.backToAppointments,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(appointment?.doctorName ?? ''),
            actions: [
              if (appointment != null)
                IconButton(
                  tooltip: AppStrings.editAppointment,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(context).push(
                    AppointmentFormScreen.editRoute(
                      appointment.id,
                      clock: clock,
                    ),
                  ),
                ),
            ],
          ),
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: body,
            ),
          ),
        );
      },
    );
  }
}

class _AppointmentDetails extends StatelessWidget {
  const _AppointmentDetails({
    required this.appointment,
    required this.memberName,
    required this.now,
    required this.clock,
    required this.onDelete,
  });

  final Appointment appointment;
  final String memberName;
  final DateTime now;
  final DateTime Function() clock;
  final VoidCallback onDelete;

  /// Null for an empty or missing optional field, shown as "not specified".
  static String? _optional(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = MaterialLocalizations.of(context);
    final dateTime = appointment.dateTime;
    final notes = _optional(appointment.notes);

    return ListView(
      // Keeps the content clear of the system navigation bar.
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const DemoDataBanner(),
        const SizedBox(height: 16),
        _Header(appointment: appointment, now: now),
        const SizedBox(height: 16),
        DetailSection(
          title: AppStrings.appointmentTimeSection,
          icon: Icons.schedule,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledValue(
                label: AppStrings.dateLabel,
                value: localizations.formatFullDate(dateTime),
              ),
              const SizedBox(height: 12),
              LabeledValue(
                label: AppStrings.timeLabel,
                value: localizations.formatTimeOfDay(
                  TimeOfDay.fromDateTime(dateTime),
                  alwaysUse24HourFormat: true,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: AppStrings.appointmentInfoSection,
          icon: Icons.medical_services_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledValue(
                label: AppStrings.doctorLabel,
                value: appointment.doctorName,
              ),
              const SizedBox(height: 12),
              LabeledValue(
                label: AppStrings.specialtyLabel,
                value: _optional(appointment.specialty),
              ),
              const SizedBox(height: 12),
              LabeledValue(
                label: AppStrings.familyMemberLabel,
                value: memberName,
              ),
              const SizedBox(height: 12),
              LabeledValue(
                label: AppStrings.locationLabel,
                value: _optional(appointment.location),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: AppStrings.notesSection,
          icon: Icons.notes,
          child: notes == null ? const NotSpecifiedText() : Text(notes),
        ),
        const SizedBox(height: 24),
        DoctorVisitPreparationSection(appointment: appointment, clock: clock),
        // Destructive action, kept apart from the regular actions.
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text(AppStrings.deleteAppointment),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}

/// Highlighted summary: upcoming/past status, doctor and when.
class _Header extends StatelessWidget {
  const _Header({required this.appointment, required this.now});

  final Appointment appointment;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUpcoming = appointment.isUpcoming(now);
    final background = isUpcoming
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHigh;
    final foreground = isUpcoming
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurfaceVariant;

    return AppCard(
      color: background,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _StatusBadge(isUpcoming: isUpcoming),
          const SizedBox(height: 12),
          Text(
            appointment.doctorName,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.event, size: 20, color: foreground),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  formatAppointmentDateTime(
                    appointment.dateTime,
                    now,
                    MaterialLocalizations.of(context),
                  ),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.isUpcoming});

  final bool isUpcoming;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = isUpcoming
        ? colorScheme.primary
        : colorScheme.surfaceContainerHighest;
    final foreground = isUpcoming
        ? colorScheme.onPrimary
        : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isUpcoming ? Icons.schedule : Icons.history,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              isUpcoming
                  ? AppStrings.appointmentStatusUpcoming
                  : AppStrings.appointmentStatusPast,
              style: theme.textTheme.labelMedium?.copyWith(
                color: foreground,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
