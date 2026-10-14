import 'package:flutter/material.dart';
import 'package:mydr/core/widgets/app_card.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/features/family/member_formatting.dart';
import 'package:mydr/features/family/widgets/member_avatar.dart';

/// Summary card for one family member: name, relation and age.
///
/// Tappable only when [onTap] is given.
class MemberCard extends StatelessWidget {
  const MemberCard({
    super.key,
    required this.member,
    required this.today,
    this.onTap,
  });

  final FamilyMember member;

  /// Used to compute the age, passed in so the whole list agrees on it.
  final DateTime today;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: EdgeInsets.zero,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppCard.borderRadius),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                MemberAvatar(name: member.name),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        memberSummaryLine(member, today),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
