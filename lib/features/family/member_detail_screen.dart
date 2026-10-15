import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/core/widgets/detail_section.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/features/family/member_form_screen.dart';
import 'package:mydr/features/family/member_formatting.dart';
import 'package:mydr/features/family/widgets/delete_member_dialog.dart';
import 'package:mydr/features/family/widgets/member_avatar.dart';
import 'package:mydr/features/family/widgets/member_not_found_view.dart';
import 'package:mydr/features/questions/widgets/member_questions_section.dart';

/// Profile of one family member.
///
/// Receives only the member id and always reads the current data from the
/// shared [FamilyController], so it reflects edits and deletions made
/// anywhere in the app.
class MemberDetailScreen extends StatelessWidget {
  const MemberDetailScreen({super.key, required this.memberId});

  final String memberId;

  static const double _maxContentWidth = 600;

  static Route<void> route(String memberId) {
    return MaterialPageRoute<void>(
      builder: (_) => MemberDetailScreen(memberId: memberId),
    );
  }

  /// Deletes only after the user confirms in [DeleteMemberDialog]; on
  /// success returns to the family list with a confirmation message.
  Future<void> _confirmAndDelete(
    BuildContext context,
    FamilyMember member,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final deleted = await DeleteMemberDialog.show(context, member);
    if (!deleted) return;

    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(AppStrings.deleteSucceeded(member.name))),
      );
    navigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).familyController;

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final member = controller.memberById(memberId);

        final Widget body;
        if (member != null) {
          body = _MemberDetails(
            member: member,
            deletionIncomplete: controller.isDeletionIncomplete(member.id),
            onDelete: () => _confirmAndDelete(context, member),
          );
        } else if (controller.isLoading) {
          body = const Center(child: CircularProgressIndicator());
        } else {
          body = const MemberNotFoundView();
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(member?.name ?? ''),
            actions: [
              if (member != null)
                IconButton(
                  tooltip: AppStrings.edit,
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () => Navigator.of(
                    context,
                  ).push(MemberFormScreen.editRoute(member.id)),
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

class _MemberDetails extends StatelessWidget {
  const _MemberDetails({
    required this.member,
    required this.deletionIncomplete,
    required this.onDelete,
  });

  final FamilyMember member;
  final bool deletionIncomplete;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final birthDate = member.birthDate;
    final notes = member.notes?.trim() ?? '';

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
        if (deletionIncomplete) ...[
          const SizedBox(height: 12),
          const _DeletionIncompleteBanner(),
        ],
        const SizedBox(height: 16),
        _ProfileHeader(member: member),
        const SizedBox(height: 16),
        DetailSection(
          title: AppStrings.personalDetailsSection,
          icon: Icons.badge_outlined,
          child: LabeledValue(
            label: AppStrings.birthDateLabel,
            value: birthDate == null
                ? null
                : MaterialLocalizations.of(
                    context,
                  ).formatCompactDate(birthDate),
          ),
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: AppStrings.allergiesSection,
          icon: Icons.warning_amber_rounded,
          child: TagList(values: member.allergies),
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: AppStrings.chronicConditionsSection,
          icon: Icons.medical_information_outlined,
          child: TagList(values: member.chronicConditions),
        ),
        const SizedBox(height: 12),
        DetailSection(
          title: AppStrings.notesSection,
          icon: Icons.notes,
          child: notes.isEmpty ? const NotSpecifiedText() : Text(notes),
        ),
        const SizedBox(height: 12),
        MemberQuestionsSection(memberId: member.id),
        // Destructive action, kept apart from the regular actions.
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
          label: const Text(AppStrings.deleteProfile),
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

class _DeletionIncompleteBanner extends StatelessWidget {
  const _DeletionIncompleteBanner();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.warning_amber_rounded,
            color: colorScheme.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.deletionIncompleteBanner,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.member});

  final FamilyMember member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppCard(
      color: colorScheme.primaryContainer,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // White circle, like the icon on the home screen's family card.
          MemberAvatar(
            name: member.name,
            size: 72,
            backgroundColor: colorScheme.surfaceContainerLowest,
          ),
          const SizedBox(height: 12),
          Text(
            member.name,
            textAlign: TextAlign.center,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: colorScheme.onPrimaryContainer,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            memberSummaryLine(member, DateTime.now()),
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}
