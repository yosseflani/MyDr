import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/core/widgets/empty_state.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/member_detail_screen.dart';
import 'package:mydr/features/family/member_form_screen.dart';
import 'package:mydr/features/family/widgets/member_card.dart';

/// "Family" tab: lists all family members from the shared
/// [FamilyController].
class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  static const double _maxContentWidth = 600;

  @override
  Widget build(BuildContext context) {
    final controller = AppScope.of(context).familyController;

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.familyTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            Navigator.of(context).push(MemberFormScreen.addRoute()),
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text(AppStrings.addFamilyMember),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxContentWidth),
          child: ListenableBuilder(
            listenable: controller,
            builder: (context, _) => _FamilyBody(controller: controller),
          ),
        ),
      ),
    );
  }
}

class _FamilyBody extends StatelessWidget {
  const _FamilyBody({required this.controller});

  final FamilyController controller;

  /// Leaves room so the last card is not hidden behind the add button.
  static const double _bottomPaddingForFab = 96;

  @override
  Widget build(BuildContext context) {
    final members = controller.members;

    if (members.isEmpty) {
      final Widget content;
      if (controller.isLoading) {
        content = const Center(child: CircularProgressIndicator());
      } else if (controller.hasLoadError) {
        content = _LoadErrorView(onRetry: controller.load);
      } else {
        content = const SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: EmptyState(
            icon: Icons.people_outline,
            title: AppStrings.familyEmptyTitle,
            message: AppStrings.familyEmptyMessage,
          ),
        );
      }

      return Column(
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: DemoDataBanner(),
          ),
          Expanded(child: content),
        ],
      );
    }

    final today = DateTime.now();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, _bottomPaddingForFab),
      children: [
        const DemoDataBanner(),
        if (controller.hasLoadError) ...[
          const SizedBox(height: 12),
          _RefreshErrorCard(onRetry: controller.load),
        ],
        for (final member in members) ...[
          const SizedBox(height: 12),
          MemberCard(
            member: member,
            today: today,
            onTap: () =>
                Navigator.of(context).push(MemberDetailScreen.route(member.id)),
          ),
        ],
      ],
    );
  }
}

/// Full-screen error shown when nothing could be loaded.
class _LoadErrorView extends StatelessWidget {
  const _LoadErrorView({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const EmptyState(
            icon: Icons.error_outline,
            title: AppStrings.familyLoadErrorTitle,
            message: AppStrings.familyLoadErrorMessage,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text(AppStrings.retry),
          ),
        ],
      ),
    );
  }
}

/// Inline warning shown above an existing list that failed to refresh.
class _RefreshErrorCard extends StatelessWidget {
  const _RefreshErrorCard({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 4, 8),
      decoration: BoxDecoration(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppStrings.familyRefreshError,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onErrorContainer,
              ),
            ),
          ),
          TextButton(onPressed: onRetry, child: const Text(AppStrings.retry)),
        ],
      ),
    );
  }
}
