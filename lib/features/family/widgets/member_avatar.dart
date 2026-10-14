import 'package:flutter/material.dart';

/// Circle showing the first letter of a family member's name.
class MemberAvatar extends StatelessWidget {
  const MemberAvatar({
    super.key,
    required this.name,
    this.size = 48,
    this.backgroundColor,
  });

  final String name;
  final double size;

  /// Defaults to the primary container color. Pass a contrasting color when
  /// the avatar sits on a primary-container surface.
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final trimmed = name.trim();
    final initial = trimmed.isEmpty ? '?' : trimmed.characters.first;

    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor ?? colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        child: Text(
          initial,
          style: theme.textTheme.titleLarge?.copyWith(
            color: colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
