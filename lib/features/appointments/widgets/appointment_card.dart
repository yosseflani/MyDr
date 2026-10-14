import 'package:flutter/material.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/features/appointments/appointment_formatting.dart';

/// Summary card for one appointment. Past appointments are shown muted.
///
/// Tappable only when [onTap] is given.
class AppointmentCard extends StatelessWidget {
  const AppointmentCard({
    super.key,
    required this.appointment,
    required this.memberName,
    required this.now,
    this.onTap,
  });

  final Appointment appointment;
  final String memberName;

  /// Used for "today"/"tomorrow" and to tell past from upcoming.
  final DateTime now;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isUpcoming = appointment.isUpcoming(now);
    final accent = isUpcoming ? colorScheme.primary : colorScheme.outline;
    final specialty = appointment.specialty?.trim() ?? '';
    final location = appointment.location?.trim() ?? '';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppCard.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isUpcoming
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    isUpcoming ? Icons.event : Icons.event_available,
                    color: isUpcoming
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 16),
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
                          color: accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        appointment.doctorName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isUpcoming
                              ? null
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (specialty.isNotEmpty)
                        Text(
                          specialty,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      const SizedBox(height: 8),
                      _IconLine(icon: Icons.person_outline, text: memberName),
                      if (location.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        _IconLine(icon: Icons.place_outlined, text: location),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: color),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}
