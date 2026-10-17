import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/features/medications/medication_controller.dart';
import 'package:mydr/features/medications/medication_formatting.dart';

/// One scheduled dose: when, optionally which medication, and its record.
///
/// A dose on today or an earlier day can be recorded as taken or skipped;
/// a recorded one can be changed or cleared. Recording the same dose again
/// never adds a second record. A dose without a record is shown as "not
/// recorded", never judged as missed.
class DoseTile extends StatefulWidget {
  const DoseTile({
    super.key,
    required this.dose,
    this.showMedication = true,
    this.showDate = false,
  });

  final ScheduledDose dose;

  /// Whether to show the medication's name and dose (in lists that mix
  /// medications).
  final bool showMedication;

  /// Whether to show the day as well as the time.
  final bool showDate;

  @override
  State<DoseTile> createState() => _DoseTileState();
}

class _DoseTileState extends State<DoseTile> {
  bool _isSaving = false;

  Future<void> _record(MedicationController controller, DoseStatus status) =>
      _run(() async {
        final result = await controller.recordDose(
          widget.dose.medication.id,
          widget.dose.at,
          status,
        );
        return switch (result) {
          DoseRecordResult.success =>
            status == DoseStatus.taken
                ? AppStrings.doseRecordedTaken
                : AppStrings.doseRecordedSkipped,
          DoseRecordResult.notScheduled => AppStrings.doseNotScheduled,
          DoseRecordResult.inFuture => AppStrings.doseInFuture,
          DoseRecordResult.medicationNotFound =>
            AppStrings.doseMedicationMissing,
          DoseRecordResult.failed => AppStrings.doseRecordFailed,
        };
      });

  Future<void> _clear(MedicationController controller) => _run(() async {
    final cleared = await controller.clearDose(
      widget.dose.medication.id,
      widget.dose.at,
    );
    return cleared ? AppStrings.doseRecordCleared : AppStrings.doseRecordFailed;
  });

  /// Runs one action at a time and shows its outcome.
  Future<void> _run(Future<String> Function() action) async {
    if (_isSaving) return;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _isSaving = true);
    final message = await action();
    if (mounted) setState(() => _isSaving = false);
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).medicationController;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final dose = widget.dose;
    final record = dose.record;
    final canRecord = controller.canRecord(dose.at);
    final when = widget.showDate
        ? formatDoseMoment(dose.at, controller.now, localizations)
        : formatClock(dose.at, localizations);
    final statusText = switch (record?.status) {
      DoseStatus.taken => AppStrings.doseTaken,
      DoseStatus.skipped => AppStrings.doseSkipped,
      null => canRecord ? AppStrings.doseNotRecorded : AppStrings.doseScheduled,
    };

    final Widget trailing;
    if (record != null) {
      trailing = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StatusChip(status: record.status),
          PopupMenuButton<_Action>(
            tooltip: AppStrings.doseActions,
            enabled: !_isSaving,
            onSelected: (action) => switch (action) {
              _Action.taken => _record(controller, DoseStatus.taken),
              _Action.skipped => _record(controller, DoseStatus.skipped),
              _Action.clear => _clear(controller),
            },
            itemBuilder: (_) => [
              if (record.status != DoseStatus.taken)
                const PopupMenuItem(
                  value: _Action.taken,
                  child: Text(AppStrings.changeToTaken),
                ),
              if (record.status != DoseStatus.skipped)
                const PopupMenuItem(
                  value: _Action.skipped,
                  child: Text(AppStrings.changeToSkipped),
                ),
              const PopupMenuItem(
                value: _Action.clear,
                child: Text(AppStrings.clearDoseRecord),
              ),
            ],
          ),
        ],
      );
    } else if (canRecord) {
      trailing = Wrap(
        spacing: 8,
        children: [
          FilledButton.tonal(
            onPressed: _isSaving
                ? null
                : () => _record(controller, DoseStatus.taken),
            child: const Text(AppStrings.markDoseTaken),
          ),
          OutlinedButton(
            onPressed: _isSaving
                ? null
                : () => _record(controller, DoseStatus.skipped),
            child: const Text(AppStrings.markDoseSkipped),
          ),
        ],
      );
    } else {
      trailing = Text(
        AppStrings.doseScheduled,
        style: theme.textTheme.bodySmall?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      );
    }

    return Semantics(
      container: true,
      label: AppStrings.doseSemantics(when, statusText),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 4,
          spacing: 8,
          children: [
            ExcludeSemantics(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    when,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.showMedication)
                    Text(
                      '${dose.medication.name} · ${dose.medication.dose}',
                      style: theme.textTheme.bodyMedium,
                    ),
                  if (record != null)
                    Text(
                      AppStrings.doseRecordedAt(
                        formatDoseMoment(
                          record.recordedAt,
                          controller.now,
                          localizations,
                        ),
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            trailing,
          ],
        ),
      ),
    );
  }
}

enum _Action { taken, skipped, clear }

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final DoseStatus status;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final taken = status == DoseStatus.taken;

    return Chip(
      avatar: Icon(
        taken ? Icons.check_circle_outline : Icons.remove_circle_outline,
        size: 18,
        color: taken ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
      label: Text(taken ? AppStrings.doseTaken : AppStrings.doseSkipped),
      backgroundColor: taken
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHigh,
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
