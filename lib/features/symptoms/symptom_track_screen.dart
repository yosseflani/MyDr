import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/core/widgets/load_error_views.dart';
import 'package:mydr/core/widgets/not_found_view.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/symptoms/symptom_controller.dart';
import 'package:mydr/features/symptoms/symptom_form_screen.dart';
import 'package:mydr/features/symptoms/symptom_formatting.dart';
import 'package:mydr/features/symptoms/widgets/symptom_card.dart';

/// All records of one symptom name for one family member, oldest first,
/// from [SymptomController.groupFor], with a shortcut to add a follow-up.
///
/// Records are grouped by name only, so they may belong to different
/// times or illnesses; the screen says so and never interprets them. It
/// shows exactly what was entered, without trends or charts.
///
/// Identified by member and name rather than a record id, so it keeps
/// following the group as records are added, edited or deleted.
class SymptomTrackScreen extends StatelessWidget {
  const SymptomTrackScreen({
    super.key,
    required this.memberId,
    required this.name,
    this.clock = DateTime.now,
  });

  final String memberId;

  /// The symptom name; compared ignoring case and extra spaces.
  final String name;

  /// Source of the current time; replaceable in tests.
  final DateTime Function() clock;

  static const double _maxContentWidth = 600;

  /// Leaves room so the last record is not hidden behind the add button.
  static const double _bottomPaddingForFab = 96;

  static Route<void> route({
    required String memberId,
    required String name,
    DateTime Function() clock = DateTime.now,
  }) => MaterialPageRoute<void>(
    builder: (_) =>
        SymptomTrackScreen(memberId: memberId, name: name, clock: clock),
  );

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final symptoms = scope.symptomController;
    final family = scope.familyController;

    return ListenableBuilder(
      listenable: Listenable.merge([symptoms, family]),
      builder: (context, _) {
        final member = family.memberById(memberId);
        final group = symptoms.groupFor(memberId, name);
        final canAdd = member != null;

        return Scaffold(
          appBar: AppBar(title: const Text(AppStrings.symptomTrackTitle)),
          floatingActionButton: canAdd
              ? FloatingActionButton.extended(
                  heroTag: 'symptom-track-add-button',
                  onPressed: () => Navigator.of(context).push(
                    SymptomFormScreen.addRoute(
                      initialMemberId: memberId,
                      initialName: group?.name ?? name,
                      clock: clock,
                    ),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text(AppStrings.addFollowUpRecord),
                )
              : null,
          body: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxContentWidth),
              child: _buildBody(context, symptoms, family, group),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(
    BuildContext context,
    SymptomController symptoms,
    FamilyController family,
    SymptomGroup? group,
  ) {
    final member = family.memberById(memberId);
    if (member == null) {
      if (family.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return const NotFoundView(
        icon: Icons.person_off_outlined,
        title: AppStrings.symptomTrackMemberMissingTitle,
        message: AppStrings.symptomTrackMemberMissingMessage,
        backLabel: AppStrings.backToSymptoms,
      );
    }

    if (group == null) {
      if (symptoms.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      if (symptoms.hasLoadError) {
        return LoadErrorView(
          title: AppStrings.symptomsLoadErrorTitle,
          message: AppStrings.symptomsLoadErrorMessage,
          onRetry: symptoms.load,
        );
      }
      return NotFoundView(
        icon: Icons.monitor_heart_outlined,
        title: AppStrings.symptomTrackEmptyTitle(
          SymptomController.tidyName(name),
        ),
        message: AppStrings.symptomTrackEmptyMessage,
        backLabel: AppStrings.backToSymptoms,
      );
    }

    final localizations = MaterialLocalizations.of(context);
    final entries = group.entries;

    return ListView(
      padding: EdgeInsets.fromLTRB(
        16,
        8,
        16,
        _bottomPaddingForFab + MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const DemoDataBanner(),
        if (symptoms.hasLoadError) ...[
          const SizedBox(height: 12),
          RefreshErrorCard(
            message: AppStrings.symptomsRefreshError,
            onRetry: symptoms.load,
          ),
        ],
        const SizedBox(height: 12),
        _Summary(
          name: group.name,
          memberName: member.name,
          count: entries.length,
          lastRecorded: formatSymptomDateTime(
            group.latest.startedAt,
            localizations,
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Padding(
            padding: const EdgeInsetsDirectional.only(start: 4, bottom: 12),
            child: Text(
              AppStrings.symptomTrackOrder,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        for (final (index, entry) in entries.indexed) ...[
          if (index > 0) const SizedBox(height: 12),
          _RecordTile(
            key: ValueKey(entry.id),
            entry: entry,
            onTap: () => Navigator.of(
              context,
            ).push(SymptomFormScreen.editRoute(entry.id, clock: clock)),
          ),
        ],
      ],
    );
  }
}

/// What the group is, how many records it has and when the latest was,
/// with a note that the records are not interpreted.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.name,
    required this.memberName,
    required this.count,
    required this.lastRecorded,
  });

  final String name;
  final String memberName;
  final int count;
  final String lastRecorded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(memberName, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(AppStrings.symptomRecordCount(count), style: secondary),
          Text(AppStrings.lastRecordedAt(lastRecorded), style: secondary),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  AppStrings.symptomTrackDisclaimer,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
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

/// One record in the track: when, the rating and the notes; tap to edit.
class _RecordTile extends StatelessWidget {
  const _RecordTile({super.key, required this.entry, required this.onTap});

  final SymptomEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final notes = entry.notes?.trim() ?? '';

    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppCard.borderRadius),
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(16, 14, 8, 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formatSymptomDateTime(
                          entry.startedAt,
                          MaterialLocalizations.of(context),
                        ),
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SeverityIndicator(severity: entry.severity),
                      if (notes.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          notes,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
