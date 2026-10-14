import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/core/widgets/empty_state.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/features/appointments/appointment_detail_screen.dart';
import 'package:mydr/features/appointments/appointment_formatting.dart';

/// Home screen card with the nearest upcoming appointments from the shared
/// [AppointmentController]. Each one opens its details.
class NextAppointmentCard extends StatelessWidget {
  const NextAppointmentCard({super.key, this.clock = DateTime.now});

  /// Source of the current time; replaceable in tests.
  final DateTime Function() clock;

  static const int maxShown = 3;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scope = AppScope.of(context);
    final appointments = scope.appointmentController;
    final family = scope.familyController;

    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.event, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Semantics(
                  header: true,
                  child: Text(
                    AppStrings.nextAppointmentTitle,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ListenableBuilder(
            listenable: Listenable.merge([appointments, family]),
            builder: (context, _) {
              final now = clock();
              final upcoming = appointments.upcoming(now);

              if (upcoming.isEmpty) {
                if (appointments.isLoading) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (appointments.hasLoadError) {
                  return Column(
                    children: [
                      const EmptyState(
                        icon: Icons.error_outline,
                        title: AppStrings.appointmentsLoadErrorTitle,
                        message: AppStrings.appointmentsLoadErrorMessage,
                      ),
                      TextButton(
                        onPressed: appointments.load,
                        child: const Text(AppStrings.retry),
                      ),
                    ],
                  );
                }
                return const EmptyState(
                  icon: Icons.event_available,
                  title: AppStrings.nextAppointmentEmptyTitle,
                  message: AppStrings.nextAppointmentEmptyMessage,
                );
              }

              final shown = upcoming.take(maxShown).toList();
              final remaining = upcoming.length - shown.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final (index, appointment) in shown.indexed) ...[
                    if (index > 0) const Divider(height: 1),
                    _UpcomingAppointmentTile(
                      appointment: appointment,
                      memberName:
                          family.memberById(appointment.memberId)?.name ??
                          AppStrings.unknownMember,
                      now: now,
                      onTap: () => Navigator.of(context).push(
                        AppointmentDetailScreen.route(
                          appointment.id,
                          clock: clock,
                        ),
                      ),
                    ),
                  ],
                  if (remaining > 0) ...[
                    const SizedBox(height: 8),
                    Text(
                      AppStrings.moreUpcomingAppointments(remaining),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

/// Compact row: when, doctor, and who (with the specialty, or else the
/// location, when there is one).
class _UpcomingAppointmentTile extends StatelessWidget {
  const _UpcomingAppointmentTile({
    required this.appointment,
    required this.memberName,
    required this.now,
    required this.onTap,
  });

  final Appointment appointment;
  final String memberName;
  final DateTime now;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final extra = [appointment.specialty, appointment.location]
        .map((value) => value?.trim() ?? '')
        .firstWhere((value) => value.isNotEmpty, orElse: () => '');
    final secondLine = [memberName, if (extra.isNotEmpty) extra].join(' · ');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.event,
                size: 20,
                color: colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatAppointmentDateTime(
                      appointment.dateTime,
                      now,
                      MaterialLocalizations.of(context),
                    ),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    appointment.doctorName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    secondLine,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Mirrored automatically, so it points forward (left) in RTL.
            Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
