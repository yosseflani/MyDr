import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/features/family/family_controller.dart';

enum _Phase { loadingSummary, summaryFailed, ready, deleting }

/// Confirmation dialog for deleting a family member and their data.
///
/// Shows exactly how many records will be removed and only allows deleting
/// once that summary has loaded. It runs the deletion itself, so it can show
/// progress and a retry after a partial failure, and closes with `true`
/// only when everything was deleted.
class DeleteMemberDialog extends StatefulWidget {
  const DeleteMemberDialog({super.key, required this.member});

  final FamilyMember member;

  /// Shows the dialog. Returns true if the member was deleted.
  static Future<bool> show(BuildContext context, FamilyMember member) async {
    final deleted = await showDialog<bool>(
      context: context,
      // Only the buttons close it, so it is never dismissed by accident.
      barrierDismissible: false,
      builder: (_) => DeleteMemberDialog(member: member),
    );
    return deleted ?? false;
  }

  @override
  State<DeleteMemberDialog> createState() => _DeleteMemberDialogState();
}

class _DeleteMemberDialogState extends State<DeleteMemberDialog> {
  late final FamilyController _controller;
  bool _isInitialized = false;

  _Phase _phase = _Phase.loadingSummary;
  RelatedDataSummary? _summary;
  bool _deletionFailed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInitialized) return;
    _isInitialized = true;
    _controller = AppScope.of(context).familyController;
    _loadSummary();
  }

  /// Loads the counts. Callers set [_Phase.loadingSummary] first if needed.
  Future<void> _loadSummary() async {
    final summary = await _controller.relatedDataSummary(widget.member.id);
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _phase = summary == null ? _Phase.summaryFailed : _Phase.ready;
    });
  }

  void _retrySummary() {
    setState(() => _phase = _Phase.loadingSummary);
    _loadSummary();
  }

  Future<void> _delete() async {
    if (_phase != _Phase.ready) return;
    setState(() {
      _phase = _Phase.deleting;
      _deletionFailed = false;
    });

    final result = await _controller.delete(
      widget.member.id,
      userConfirmed: true,
    );
    if (!mounted) return;

    if (result.isSuccess) {
      Navigator.of(context).pop(true);
      return;
    }

    // Part of the data may be gone now, so re-count what is left.
    setState(() {
      _deletionFailed = true;
      _phase = _Phase.loadingSummary;
    });
    await _loadSummary();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDeleting = _phase == _Phase.deleting;

    return PopScope<bool>(
      canPop: !isDeleting,
      child: AlertDialog(
        icon: Icon(Icons.delete_forever_outlined, color: colorScheme.error),
        title: Text(AppStrings.deleteDialogTitle(widget.member.name)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_deletionFailed) ...[
                const _ErrorMessage(message: AppStrings.deleteIncomplete),
                const SizedBox(height: 16),
              ],
              ..._buildPhaseContent(context),
            ],
          ),
        ),
        actions: [
          TextButton(
            autofocus: true,
            onPressed: isDeleting
                ? null
                : () => Navigator.of(context).pop(false),
            child: const Text(AppStrings.cancel),
          ),
          FilledButton(
            onPressed: _phase == _Phase.ready ? _delete : null,
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            child: isDeleting
                ? SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onError,
                    ),
                  )
                : Text(
                    _deletionFailed
                        ? AppStrings.retryDelete
                        : AppStrings.delete,
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPhaseContent(BuildContext context) {
    final theme = Theme.of(context);

    switch (_phase) {
      case _Phase.loadingSummary:
        return [
          Row(
            children: [
              const SizedBox.square(
                dimension: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(width: 12),
              const Expanded(child: Text(AppStrings.deleteSummaryLoading)),
            ],
          ),
        ];
      case _Phase.summaryFailed:
        return [
          const _ErrorMessage(message: AppStrings.deleteSummaryFailed),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: _retrySummary,
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
            ),
          ),
        ];
      case _Phase.ready:
      case _Phase.deleting:
        final summary = _summary!;
        return [
          const Text(AppStrings.deleteDialogIntro),
          const SizedBox(height: 8),
          const _CountRow(label: AppStrings.deleteItemProfile),
          _CountRow(
            label: AppStrings.deleteItemAppointments,
            count: summary.appointments,
          ),
          _CountRow(
            label: AppStrings.deleteItemQuestions,
            count: summary.doctorQuestions,
          ),
          _CountRow(
            label: AppStrings.deleteItemSymptoms,
            count: summary.symptoms,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.deleteIrreversible,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.error,
              fontWeight: FontWeight.bold,
            ),
          ),
        ];
    }
  }
}

/// One line of the "will be deleted" list. Without [count] it stands for a
/// single item (the profile itself).
class _CountRow extends StatelessWidget {
  const _CountRow({required this.label, this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentCount = count;

    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.remove_circle_outline,
              size: 18,
              color: theme.colorScheme.error,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(label)),
            if (currentCount != null)
              Text(
                '$currentCount',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ErrorMessage extends StatelessWidget {
  const _ErrorMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: colorScheme.errorContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
