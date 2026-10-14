import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/feature_placeholder.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.familyTitle)),
      body: const FeaturePlaceholder(
        icon: Icons.people_outline,
        message: AppStrings.familyPlaceholder,
      ),
    );
  }
}
