import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/core/widgets/empty_state.dart';
import 'package:mydr/core/widgets/load_error_views.dart';
import 'package:mydr/core/widgets/member_filter_chips.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/symptoms/symptom_controller.dart';
import 'package:mydr/features/symptoms/symptom_form_screen.dart';
import 'package:mydr/features/symptoms/symptom_formatting.dart';
import 'package:mydr/features/symptoms/symptom_track_screen.dart';
import 'package:mydr/features/symptoms/widgets/symptom_card.dart';

/// "Symptoms" tab: the family's symptom records from the shared
/// [SymptomController], newest first and grouped by day, with a filter by
/// family member.
///
/// A journal only: records are shown as reported, never interpreted.
class SymptomsScreen extends StatefulWidget {
  const SymptomsScreen({
    super.key,
    this.initialMemberId,
    this.clock = DateTime.now,
  });

  /// Family member to filter on when the screen opens.
  final String? initialMemberId;

  /// Source of the current time; replaceable in tests.
  final DateTime Function() clock;

  /// The journal as a screen of its own (outside the tab), e.g. opened from
  /// a profile already filtered on that family member.
  static Route<void> route({
    String? initialMemberId,
    DateTime Function() clock = DateTime.now,
  }) => MaterialPageRoute<void>(
    builder: (_) =>
        SymptomsScreen(initialMemberId: initialMemberId, clock: clock),
  );

  @override
  State<SymptomsScreen> createState() => _SymptomsScreenState();
}

class _SymptomsScreenState extends State<SymptomsScreen> {
  static const double _maxContentWidth = 600;

  /// Selected family member, or null for the whole family. Local to this
  /// screen, so it does not affect other screens.
  late String? _selectedMemberId = widget.initialMemberId;

  /// Opens the form, preselecting the member currently filtered on.
  void _openAddForm() {
    Navigator.of(context).push(
      SymptomFormScreen.addRoute(
        initialMemberId: _selectedMemberId,
        clock: widget.clock,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final symptoms = scope.symptomController;
    final family = scope.familyController;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.symptomsTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: ListenableBuilder(
            listenable: Listenable.merge([symptoms, family]),
            builder: (context, _) => _buildList(symptoms, family),
          ),
        ),
      ),
    );
  }

  Widget _buildList(SymptomController symptoms, FamilyController family) {
    // A filtered member that was deleted falls back to the whole family.
    if (_selectedMemberId case final id? when family.memberById(id) == null) {
      if (!family.isLoading) _selectedMemberId = null;
    }
    final memberId = _selectedMemberId;

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
        const _Disclaimer(),
        const SizedBox(height: 12),
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: FilledButton.tonalIcon(
            onPressed: _openAddForm,
            icon: const Icon(Icons.add),
            label: const Text(AppStrings.actionLogSymptom),
          ),
        ),
        if (symptoms.entries.isNotEmpty && family.members.isNotEmpty) ...[
          const SizedBox(height: 16),
          MemberFilterChips(
            members: family.members,
            selectedMemberId: memberId,
            onSelected: (id) => setState(() => _selectedMemberId = id),
          ),
        ],
        ..._buildContent(symptoms, family, memberId),
      ],
    );
  }

  List<Widget> _buildContent(
    SymptomController symptoms,
    FamilyController family,
    String? memberId,
  ) {
    if (symptoms.entries.isEmpty) {
      if (symptoms.isLoading) {
        return const [
          Padding(
            padding: EdgeInsets.all(48),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      }
      if (symptoms.hasLoadError) {
        return [
          LoadErrorView(
            title: AppStrings.symptomsLoadErrorTitle,
            message: AppStrings.symptomsLoadErrorMessage,
            onRetry: symptoms.load,
          ),
        ];
      }
      return const [
        Padding(
          padding: EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.monitor_heart_outlined,
            title: AppStrings.symptomsEmptyTitle,
            message: AppStrings.symptomsEmptyMessage,
          ),
        ),
      ];
    }

    final history = symptoms.history(memberId: memberId);

    return [
      if (symptoms.hasLoadError) ...[
        const SizedBox(height: 12),
        RefreshErrorCard(
          message: AppStrings.symptomsRefreshError,
          onRetry: symptoms.load,
        ),
      ],
      if (history.isEmpty)
        _EmptyForMember(
          memberName: family.memberById(memberId ?? '')?.name ?? '',
          onShowAll: () => setState(() => _selectedMemberId = null),
        )
      else
        ..._buildDays(history, symptoms, family),
    ];
  }

  /// [history] is newest first, so each day's records are consecutive.
  List<Widget> _buildDays(
    List<SymptomEntry> history,
    SymptomController symptoms,
    FamilyController family,
  ) {
    final localizations = MaterialLocalizations.of(context);
    // How many records each member's symptom has, across all dates.
    String groupKey(String memberId, String name) =>
        '$memberId\u0000${SymptomController.normalizeName(name)}';
    final groupSizes = {
      for (final group in symptoms.groups())
        groupKey(group.memberId, group.name): group.entries.length,
    };
    final now = widget.clock();
    final widgets = <Widget>[];
    DateTime? currentDay;

    for (final entry in history) {
      final day = DateUtils.dateOnly(entry.startedAt);
      if (day != currentDay) {
        currentDay = day;
        widgets
          ..add(const SizedBox(height: 24))
          ..add(_DayHeader(title: formatSymptomDay(day, now, localizations)));
      } else {
        widgets.add(const SizedBox(height: 12));
      }
      widgets.add(
        SymptomCard(
          key: ValueKey(entry.id),
          entry: entry,
          memberName:
              family.memberById(entry.memberId)?.name ??
              AppStrings.unknownMember,
          onTap: () => Navigator.of(
            context,
          ).push(SymptomFormScreen.editRoute(entry.id, clock: widget.clock)),
          trackCount: groupSizes[groupKey(entry.memberId, entry.name)] ?? 1,
          onOpenTrack: () => Navigator.of(context).push(
            SymptomTrackScreen.route(
              memberId: entry.memberId,
              name: entry.name,
              clock: widget.clock,
            ),
          ),
        ),
      );
    }
    return widgets;
  }
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(start: 4, bottom: 12),
        child: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.edit_note, size: 18, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              AppStrings.symptomsDisclaimer,
              style: theme.textTheme.bodySmall?.copyWith(color: color),
            ),
          ),
        ],
      ),
    );
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
            icon: Icons.monitor_heart_outlined,
            title: AppStrings.symptomsEmptyForMember(memberName),
            message: AppStrings.symptomsEmptyForMemberMessage,
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
