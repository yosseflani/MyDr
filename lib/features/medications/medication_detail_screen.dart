import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/core/widgets/detail_section.dart';
import 'package:mydr/core/widgets/not_found_view.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/features/medications/medication_controller.dart';
import 'package:mydr/features/medications/medication_form_screen.dart';
import 'package:mydr/features/medications/medication_formatting.dart';
import 'package:mydr/features/medications/widgets/delete_medication_dialog.dart';
import 'package:mydr/features/medications/widgets/dose_tile.dart';
import 'package:mydr/features/medications/widgets/medication_notice.dart';

/// One medication: its details, the doses of the last week (to record as
/// taken or skipped), and every record made for it.
///
/// Receives only the id and always reads the current data from the shared
/// [MedicationController], so it reflects edits and deletions made
/// anywhere, including deleting the family member.
class MedicationDetailScreen extends StatelessWidget {
  const MedicationDetailScreen({super.key, required this.medicationId});

  final String medicationId;

  static const double _maxContentWidth = 600;

  static Route<void> route(String medicationId) => MaterialPageRoute<void>(
    builder: (_) => MedicationDetailScreen(medicationId: medicationId),
  );

  /// Deletes only after the user confirms in [DeleteMedicationDialog]; on
  /// success returns to the previous screen.
  Future<void> _confirmAndDelete(
    BuildContext context,
    Medication medication,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final memberName =
        AppScope.of(
          context,
        ).familyController.memberById(medication.memberId)?.name ??
        AppStrings.unknownMember;

    final deleted = await DeleteMedicationDialog.show(
      context,
      medication,
      memberName: memberName,
    );
    if (!deleted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text(AppStrings.medicationDeleted)),
      );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final controller = scope.medicationController;

    return ListenableBuilder(
      listenable: Listenable.merge([controller, scope.familyController]),
      builder: (context, _) {
        final medication = controller.medicationById(medicationId);

        final Widget body;
        if (medication != null) {
          body = _Details(
            medication: medication,
            controller: controller,
            memberName:
                scope.familyController.memberById(medication.memberId)?.name ??
                AppStrings.unknownMember,
            onDelete: () => _confirmAndDelete(context, medication),
          );
        } else if (controller.isLoading) {
          body = const Center(child: CircularProgressIndicator());
        } else {
          body = const NotFoundView(
            icon: Icons.help_outline,
            title: AppStrings.medicationNotFoundTitle,
            message: AppStrings.medicationNotFoundMessage,
            backLabel: AppStrings.backToMedications,
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(medication?.name ?? ''),
            actions: [
              if (medication != null)
                IconButton(
                  tooltip: AppStrings.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MedicationFormScreen.editRoute(medication.id)),
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

class _Details extends StatelessWidget {
  const _Details({
    required this.medication,
    required this.controller,
    required this.memberName,
    required this.onDelete,
  });

  final Medication medication;
  final MedicationController controller;
  final String memberName;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final now = controller.now;
    final instructions = medication.instructions;
    final recent = controller.recentDoses(medication.id);
    final history = controller.records(medicationId: medication.id);
    final taken = history.where((r) => r.status == DoseStatus.taken).length;

    return ListView(
      // Keeps the delete button clear of the system navigation bar.
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
        const SizedBox(height: 16),
        DetailSection(
          title: AppStrings.medicationDetailsSection,
          icon: Icons.medication_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LabeledValue(
                label: AppStrings.familyMemberLabel,
                value: memberName,
              ),
              const SizedBox(height: 12),
              LabeledValue(label: AppStrings.doseLabel, value: medication.dose),
              const SizedBox(height: 12),
              LabeledValue(
                label: AppStrings.instructionsLabel,
                value: instructions,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: AppStrings.reminderTimesSection,
          icon: Icons.alarm,
          child: Text(
            formatReminderTimes(medication.reminderTimes, localizations),
            style: theme.textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: AppStrings.treatmentDatesSection,
          icon: Icons.date_range_outlined,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatTreatmentDates(medication, localizations),
                style: theme.textTheme.bodyLarge,
              ),
              Text(
                formatTreatmentStatus(medication, now, localizations),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: AppStrings.recentDosesTitle,
          icon: Icons.checklist,
          child: recent.isEmpty
              ? const Text(AppStrings.recentDosesEmpty)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final dose in recent)
                      DoseTile(
                        key: ValueKey('recent-${dose.at}'),
                        dose: dose,
                        showMedication: false,
                        showDate: true,
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: AppStrings.doseHistoryTitle,
          icon: Icons.history,
          child: history.isEmpty
              ? const Text(AppStrings.doseHistoryEmpty)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.doseCountSummary(
                        taken,
                        history.length - taken,
                      ),
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    for (final record in history)
                      _HistoryRow(key: ValueKey(record.id), record: record),
                  ],
                ),
        ),
        // Destructive action, kept apart from the regular actions.
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text(AppStrings.deleteMedication),
          style: OutlinedButton.styleFrom(
            foregroundColor: colorScheme.error,
            side: BorderSide(color: colorScheme.error),
            minimumSize: const Size.fromHeight(48),
          ),
        ),
      ],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({super.key, required this.record});

  final DoseRecord record;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final taken = record.status == DoseStatus.taken;
    final time = formatClock(record.scheduledAt, localizations);
    final date = localizations.formatShortDate(record.scheduledAt);

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              taken ? Icons.check_circle_outline : Icons.remove_circle_outline,
              size: 20,
              color: taken ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text('$date · $time')),
            Text(
              taken ? AppStrings.doseTaken : AppStrings.doseSkipped,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
