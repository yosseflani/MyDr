import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/core/widgets/empty_state.dart';
import 'package:mydr/core/widgets/load_error_views.dart';
import 'package:mydr/core/widgets/section_header.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/widgets/no_family_members_view.dart';
import 'package:mydr/features/medications/medication_controller.dart';
import 'package:mydr/features/medications/medication_detail_screen.dart';
import 'package:mydr/features/medications/medication_form_screen.dart';
import 'package:mydr/features/medications/widgets/dose_tile.dart';
import 'package:mydr/features/medications/widgets/medication_card.dart';
import 'package:mydr/features/medications/widgets/medication_notice.dart';
import 'package:mydr/features/medications/widgets/reminder_status_card.dart';

/// "Medications" tab: one family member at a time, with today's doses (to
/// record as taken or skipped), the next scheduled doses, and their
/// medications grouped by treatment status.
///
/// Only ever shows the selected member's data.
class MedicationsScreen extends StatefulWidget {
  const MedicationsScreen({super.key, this.initialMemberId});

  /// Family member to show when the screen opens.
  final String? initialMemberId;

  /// The screen on its own (outside the tab), e.g. from a profile.
  static Route<void> route({String? initialMemberId}) =>
      MaterialPageRoute<void>(
        builder: (_) => MedicationsScreen(initialMemberId: initialMemberId),
      );

  @override
  State<MedicationsScreen> createState() => _MedicationsScreenState();
}

class _MedicationsScreenState extends State<MedicationsScreen> {
  static const double _maxContentWidth = 600;

  /// Local to this screen, so it does not affect other screens.
  late String? _selectedMemberId = widget.initialMemberId;

  /// The selected member if they still exist; otherwise the "self" profile
  /// or the first member. Never another member's data under a stale id.
  FamilyMember? _resolveMember(FamilyController family) {
    if (_selectedMemberId case final id?) {
      final member = family.memberById(id);
      if (member != null) return member;
    }
    final members = family.members;
    if (members.isEmpty) return null;
    return members.firstWhere(
      (m) => m.relation == FamilyRelation.self,
      orElse: () => members.first,
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final medications = scope.medicationController;
    final family = scope.familyController;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.medicationsTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: ListenableBuilder(
            listenable: Listenable.merge([medications, family]),
            builder: (context, _) {
              if (family.members.isEmpty) {
                return family.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : const NoFamilyMembersView(
                        title: AppStrings.noFamilyForMedicationsTitle,
                        message: AppStrings.noFamilyForMedicationsMessage,
                      );
              }
              return _buildList(medications, family);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildList(MedicationController medications, FamilyController family) {
    final member = _resolveMember(family)!;
    final navigator = Navigator.of(context);

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const DemoDataBanner(),
        const SizedBox(height: 8),
        const MedicationNotice(),
        const SizedBox(height: 12),
        const ReminderStatusCard(),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in family.members)
              ChoiceChip(
                label: Text(m.name),
                selected: m.id == member.id,
                onSelected: (_) => setState(() => _selectedMemberId = m.id),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.tonalIcon(
            onPressed: () => navigator.push(
              MedicationFormScreen.addRoute(initialMemberId: member.id),
            ),
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.actionAddMedication),
          ),
        ),
        ..._buildContent(medications, member),
      ],
    );
  }

  List<Widget> _buildContent(
    MedicationController medications,
    FamilyMember member,
  ) {
    if (medications.medications.isEmpty) {
      if (medications.isLoading) {
        return const [
          Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      }
      if (medications.hasLoadError) {
        return [
          LoadErrorView(
            title: AppStrings.medicationsLoadErrorTitle,
            message: AppStrings.medicationsLoadErrorMessage,
            onRetry: medications.load,
          ),
        ];
      }
    }

    final own = medications.medicationsFor(member.id);
    final now = medications.now;
    final refreshError = [
      if (medications.hasLoadError) ...[
        const SizedBox(height: 12),
        RefreshErrorCard(
          message: AppStrings.medicationsRefreshError,
          onRetry: medications.load,
        ),
      ],
    ];

    if (own.isEmpty) {
      return [
        ...refreshError,
        Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.medication_outlined,
            title: AppStrings.medicationsEmptyForMember(member.name),
            message: AppStrings.medicationsEmptyMessage,
          ),
        ),
      ];
    }

    final today = medications.dosesOn(member.id, now);
    final upcoming = medications.upcomingDoses(member.id);
    final active = own.where((m) => m.isActiveOn(now)).toList();
    final future = own.where((m) => m.startsAfter(now)).toList();
    final ended = own.where((m) => m.hasEndedBefore(now)).toList();

    return [
      ...refreshError,
      const SizedBox(height: 24),
      const _Header(title: AppStrings.todayDosesTitle),
      if (today.isEmpty)
        const _Muted(text: AppStrings.todayDosesEmpty)
      else
        for (final dose in today)
          DoseTile(
            key: ValueKey('today-${dose.medication.id}-${dose.at}'),
            dose: dose,
          ),
      const SizedBox(height: 24),
      const _Header(title: AppStrings.upcomingDosesTitle),
      if (upcoming.isEmpty)
        const _Muted(text: AppStrings.upcomingDosesEmpty)
      else
        for (final dose in upcoming)
          DoseTile(
            key: ValueKey('upcoming-${dose.medication.id}-${dose.at}'),
            dose: dose,
            showDate: true,
          ),
      ..._group(AppStrings.activeMedicationsTitle, active, now),
      ..._group(AppStrings.futureMedicationsTitle, future, now),
      ..._group(AppStrings.endedMedicationsTitle, ended, now),
    ];
  }

  List<Widget> _group(String title, List<Medication> items, DateTime now) {
    if (items.isEmpty) return const [];
    return [
      const SizedBox(height: 24),
      _Header(title: title),
      for (final medication in items) ...[
        MedicationCard(
          key: ValueKey(medication.id),
          medication: medication,
          now: now,
          onTap: () => Navigator.of(
            context,
          ).push(MedicationDetailScreen.route(medication.id)),
        ),
        const SizedBox(height: 12),
      ],
    ];
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) =>
      Semantics(header: true, child: SectionHeader(title: title));
}

class _Muted extends StatelessWidget {
  const _Muted({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
