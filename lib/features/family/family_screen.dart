import 'package:flutter/material.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/core/widgets/empty_state.dart';
import 'package:mydr/core/widgets/load_error_views.dart';
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
        // Each tab's button needs its own tag: all tabs live in one route.
        heroTag: 'family-add-button',
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
        content = LoadErrorView(
          title: AppStrings.familyLoadErrorTitle,
          message: AppStrings.familyLoadErrorMessage,
          onRetry: controller.load,
        );
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
          RefreshErrorCard(
            message: AppStrings.familyRefreshError,
            onRetry: controller.load,
          ),
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
