import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/feature_placeholder.dart';

class SymptomsScreen extends StatelessWidget {
  const SymptomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.symptomsTitle)),
      body: const FeaturePlaceholder(
        icon: Icons.monitor_heart_outlined,
        message: AppStrings.symptomsPlaceholder,
      ),
    );
  }
}
