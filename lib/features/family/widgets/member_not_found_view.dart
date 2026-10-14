import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/not_found_view.dart';

/// Shown when a member id no longer matches a profile, e.g. after it was
/// deleted, with a way back to the family list.
class MemberNotFoundView extends StatelessWidget {
  const MemberNotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    return const NotFoundView(
      icon: Icons.person_off_outlined,
      title: AppStrings.memberNotFoundTitle,
      message: AppStrings.memberNotFoundMessage,
      backLabel: AppStrings.backToFamily,
    );
  }
}
