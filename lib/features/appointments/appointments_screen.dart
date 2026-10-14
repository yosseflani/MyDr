import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/core/widgets/empty_state.dart';
import 'package:mydr/core/widgets/load_error_views.dart';
import 'package:mydr/core/widgets/section_header.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/appointments/appointment_detail_screen.dart';
import 'package:mydr/features/appointments/appointment_form_screen.dart';
import 'package:mydr/features/appointments/widgets/appointment_card.dart';
import 'package:mydr/features/appointments/widgets/member_filter_chips.dart';
import 'package:mydr/features/family/family_controller.dart';

/// "Appointments" tab: upcoming and past appointments from the shared
/// [AppointmentController], with a filter by family member.
class AppointmentsScreen extends StatefulWidget {
  const AppointmentsScreen({super.key, this.clock = DateTime.now});

  /// Source of the current time; replaceable in tests.
  final DateTime Function() clock;

  @override
  State<AppointmentsScreen> createState() => _AppointmentsScreenState();
}

class _AppointmentsScreenState extends State<AppointmentsScreen> {
  static const double _maxContentWidth = 600;

  /// Leaves room so the last card is not hidden behind the add button.
  static const double _bottomPaddingForFab = 96;

  /// Selected family member, or null for the whole family. Local to this
  /// screen, so it does not affect other screens.
  String? _selectedMemberId;

  /// Opens the form, preselecting the member currently filtered on.
  void _openAddForm() {
    Navigator.of(context).push(
      AppointmentFormScreen.addRoute(
        initialMemberId: _selectedMemberId,
        clock: widget.clock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final appointments = scope.appointmentController;
    final family = scope.familyController;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appointmentsTitle)),
      floatingActionButton: FloatingActionButton.extended(
        // Each tab's button needs its own tag: all tabs live in one route.
        heroTag: 'appointments-add-button',
        onPressed: _openAddForm,
        icon: const Icon(Icons.add),
        label: const Text(AppStrings.newAppointment),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: ListenableBuilder(
            listenable: Listenable.merge([appointments, family]),
            builder: (context, _) => _buildList(appointments, family),
          ),
        ),
      ),
    );
  }

  Widget _buildList(
    AppointmentController appointments,
    FamilyController family,
  ) {
    // A filtered member that was deleted falls back to the whole family.
    if (_selectedMemberId case final id? when family.memberById(id) == null) {
      _selectedMemberId = null;
    }
    final memberId = _selectedMemberId;
    final now = widget.clock();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, _bottomPaddingForFab),
      children: [
        const DemoDataBanner(),
        if (family.members.isNotEmpty) ...[
          const SizedBox(height: 12),
          MemberFilterChips(
            members: family.members,
            selectedMemberId: memberId,
            onSelected: (id) => setState(() => _selectedMemberId = id),
          ),
        ],
        ..._buildContent(appointments, family, memberId, now),
      ],
    );
  }

  List<Widget> _buildContent(
    AppointmentController appointments,
    FamilyController family,
    String? memberId,
    DateTime now,
  ) {
    if (appointments.appointments.isEmpty) {
      if (appointments.isLoading) {
        return const [
          Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      }
      if (appointments.hasLoadError) {
        return [
          LoadErrorView(
            title: AppStrings.appointmentsLoadErrorTitle,
            message: AppStrings.appointmentsLoadErrorMessage,
            onRetry: appointments.load,
          ),
        ];
      }
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.event_note_outlined,
            title: AppStrings.appointmentsEmptyTitle,
            message: AppStrings.appointmentsEmptyMessage,
          ),
        ),
      ];
    }

    final upcoming = appointments.upcoming(now, memberId: memberId);
    final past = appointments.past(now, memberId: memberId);

    return [
      if (appointments.hasLoadError) ...[
        const SizedBox(height: 12),
        RefreshErrorCard(
          message: AppStrings.appointmentsRefreshError,
          onRetry: appointments.load,
        ),
      ],
      if (memberId != null && upcoming.isEmpty && past.isEmpty)
        _EmptyForMember(
          memberName: family.memberById(memberId)!.name,
          onShowAll: () => setState(() => _selectedMemberId = null),
        )
      else ...[
        const SizedBox(height: 24),
        const SectionHeader(title: AppStrings.upcomingAppointmentsSection),
        ..._buildSection(
          upcoming,
          family,
          now,
          AppStrings.noUpcomingAppointments,
        ),
        const SizedBox(height: 24),
        const SectionHeader(title: AppStrings.pastAppointmentsSection),
        ..._buildSection(past, family, now, AppStrings.noPastAppointments),
      ],
    ];
  }

  List<Widget> _buildSection(
    List<Appointment> items,
    FamilyController family,
    DateTime now,
    String emptyText,
  ) {
    if (items.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4),
          child: Text(
            emptyText,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ];
    }
    return [
      for (final (index, appointment) in items.indexed) ...[
        if (index > 0) const SizedBox(height: 12),
        AppointmentCard(
          appointment: appointment,
          memberName:
              family.memberById(appointment.memberId)?.name ??
              AppStrings.unknownMember,
          now: now,
          onTap: () => Navigator.of(context).push(
            AppointmentDetailScreen.route(appointment.id, clock: widget.clock),
          ),
        ),
      ],
    ];
  }
}

class _EmptyForMember extends StatelessWidget {
  const _EmptyForMember({required this.memberName, required this.onShowAll});

  final String memberName;
  final VoidCallback onShowAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          EmptyState(
            icon: Icons.event_busy,
            title: AppStrings.appointmentsEmptyForMember(memberName),
            message: AppStrings.appointmentsEmptyForMemberMessage,
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: onShowAll,
            child: const Text(AppStrings.showAllFamily),
          ),
        ],
      ),
    );
  }
}
