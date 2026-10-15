import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/empty_state.dart';
import 'package:mydr/features/family/member_form_screen.dart';

/// Shown instead of a form that needs a family member when there are none
/// yet; offers to add one with the existing member form.
class NoFamilyMembersView extends StatelessWidget {
  const NoFamilyMembersView({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          EmptyState(
            icon: Icons.group_add_outlined,
            title: title,
            message: message,
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () =>
                Navigator.of(context).push(MemberFormScreen.addRoute()),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text(AppStrings.addFamilyMember),
          ),
        ],
      ),
    );
  }
}
