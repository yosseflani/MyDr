import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/empty_state.dart';

/// Shown when a member id no longer matches a profile, e.g. after it was
/// deleted, with a way back to the family list.
class MemberNotFoundView extends StatelessWidget {
  const MemberNotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const EmptyState(
            icon: Icons.person_off_outlined,
            title: AppStrings.memberNotFoundTitle,
            message: AppStrings.memberNotFoundMessage,
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const BackButtonIcon(),
            label: const Text(AppStrings.backToFamily),
          ),
        ],
      ),
    );
  }
}
