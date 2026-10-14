import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/feature_placeholder.dart';

class AppointmentsScreen extends StatelessWidget {
  const AppointmentsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.appointmentsTitle)),
      body: const FeaturePlaceholder(
        icon: Icons.event_outlined,
        message: AppStrings.appointmentsPlaceholder,
      ),
    );
  }
}
