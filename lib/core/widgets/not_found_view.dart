import 'package:flutter/material.dart';
import 'package:mydr/core/widgets/empty_state.dart';

/// Shown when an id no longer matches an item, e.g. after it was deleted,
/// with a button back to the previous screen.
class NotFoundView extends StatelessWidget {
  const NotFoundView({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.backLabel,
  });

  final IconData icon;
  final String title;
  final String message;
  final String backLabel;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          EmptyState(icon: icon, title: title, message: message),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const BackButtonIcon(),
            label: Text(backLabel),
          ),
        ],
      ),
    );
  }
}
