import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/family_member.dart';

/// Chips to filter by family member, starting with "the whole family" (a
/// null selection). They wrap onto more lines rather than scroll sideways,
/// so every member is visible.
class MemberFilterChips extends StatelessWidget {
  const MemberFilterChips({
    super.key,
    required this.members,
    required this.selectedMemberId,
    required this.onSelected,
  });

  final List<FamilyMember> members;
  final String? selectedMemberId;
  final ValueChanged<String?> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(null, AppStrings.filterAllFamily),
        for (final member in members) _chip(member.id, member.name),
      ],
    );
  }

  Widget _chip(String? memberId, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: selectedMemberId == memberId,
      onSelected: (_) => onSelected(memberId),
    );
  }
}
