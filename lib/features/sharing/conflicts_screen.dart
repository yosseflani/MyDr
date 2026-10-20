import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/core/widgets/empty_state.dart';
import 'package:mydr/data/models/sync_state.dart';
import 'package:mydr/data/sync/sync_engine.dart';
import 'package:mydr/features/sharing/sharing_messages.dart';
import 'package:mydr/features/sharing/sync_controller.dart';

/// Changes from other devices that wait for the user: concurrent edits of
/// the same fields, and deletions. Shows both versions exactly as entered,
/// and nothing changes until the user chooses.
class ConflictsScreen extends StatelessWidget {
  const ConflictsScreen({super.key});

  static Route<void> route() =>
      MaterialPageRoute<void>(builder: (_) => const ConflictsScreen());

  @override
  Widget build(BuildContext context) {
    final scope = AppScope.of(context);
    final controller = scope.syncController;
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.conflictsTitle)),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final conflicts = controller.conflicts;
              if (conflicts.isEmpty) {
                return const EmptyState(
                  icon: Icons.check_circle_outline,
                  title: AppStrings.conflictsTitle,
                  message: AppStrings.noConflicts,
                );
              }
              final deletions = conflicts
                  .where((c) => c.reason == ConflictReason.deleted)
                  .length;
              return ListView(
                padding: EdgeInsets.fromLTRB(
                  16,
                  16,
                  16,
                  24 + MediaQuery.paddingOf(context).bottom,
                ),
                children: [
                  Text(
                    AppStrings.conflictsIntro,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (controller.isBusy) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                  if (deletions > 1) ...[
                    const SizedBox(height: 12),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: OutlinedButton.icon(
                        onPressed: controller.isBusy
                            ? null
                            : () => _applyAll(context, controller, deletions),
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text(AppStrings.applyAllDeletions),
                      ),
                    ),
                  ],
                  for (final conflict in conflicts) ...[
                    const SizedBox(height: 12),
                    _ConflictCard(
                      key: ValueKey('${conflict.kind.name}-${conflict.syncId}'),
                      conflict: conflict,
                      controller: controller,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static Future<void> _applyAll(
    BuildContext context,
    SyncController controller,
    int count,
  ) async {
    final confirmed = await confirmSharingAction(
      context,
      title: AppStrings.deleteHereConfirmTitle,
      message: AppStrings.applyAllDeletionsMessage(count),
      confirmLabel: AppStrings.conflictDeleteHere,
      destructive: true,
    );
    if (!confirmed) return;
    final failure = await controller.applyAllDeletions(userConfirmed: true);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure == null
                ? AppStrings.conflictResolved
                : sharingFailureMessage(failure),
          ),
        ),
      );
  }
}

class _ConflictCard extends StatelessWidget {
  const _ConflictCard({
    super.key,
    required this.conflict,
    required this.controller,
  });

  final SyncConflict conflict;
  final SyncController controller;

  Future<void> _choose(BuildContext context, ConflictChoice choice) async {
    final deleting =
        conflict.reason == ConflictReason.deleted &&
        choice == ConflictChoice.useOther;
    if (deleting) {
      final confirmed = await confirmSharingAction(
        context,
        title: AppStrings.deleteHereConfirmTitle,
        message: AppStrings.deleteHereConfirmMessage,
        confirmLabel: AppStrings.conflictDeleteHere,
        destructive: true,
      );
      if (!confirmed) return;
    }
    final failure = await controller.resolve(
      conflict,
      choice,
      userConfirmed: deleting,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            failure == null
                ? AppStrings.conflictResolved
                : sharingFailureMessage(failure),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final localizations = MaterialLocalizations.of(context);
    final member = AppScope.of(
      context,
    ).familyController.memberById(conflict.memberId);
    final busy = controller.isBusy;
    final (keepLabel, otherLabel) = switch (conflict.reason) {
      ConflictReason.edited => (
        AppStrings.conflictKeepMine,
        AppStrings.conflictUseOther,
      ),
      ConflictReason.deleted => (
        AppStrings.conflictKeep,
        AppStrings.conflictDeleteHere,
      ),
      ConflictReason.deletedHere => (
        AppStrings.conflictKeepDeleted,
        AppStrings.conflictRestore,
      ),
    };
    final fields = conflict.reason == ConflictReason.edited
        ? conflict.fields
        : const <String>[];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '${syncKindLabel(conflict.kind)} · '
            '${member?.name ?? AppStrings.unknownMember}',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(conflictReasonLabel(conflict.reason)),
          for (final field in fields) ...[
            const SizedBox(height: 8),
            Text(syncFieldLabel(field), style: theme.textTheme.labelLarge),
            Text(
              '${AppStrings.conflictThisDevice}: '
              '${syncFieldValue(field, conflict.local?[field], localizations)}',
            ),
            Text(
              '${AppStrings.conflictOtherDevice}: '
              '${syncFieldValue(field, conflict.remote?[field], localizations)}',
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonal(
                onPressed: busy
                    ? null
                    : () => _choose(context, ConflictChoice.keepThisDevice),
                child: Text(keepLabel),
              ),
              OutlinedButton(
                onPressed: busy
                    ? null
                    : () => _choose(context, ConflictChoice.useOther),
                child: Text(otherLabel),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
