import 'package:flutter/material.dart';
import 'package:mydr/app.dart';
import 'package:mydr/app_bootstrap.dart';
import 'package:mydr/core/app_dependencies.dart';

/// Demo mode, for development only: fictional data kept in memory, nothing
/// saved. Enable with `--dart-define=MYDR_DEMO=true`.
const bool demoMode = bool.fromEnvironment('MYDR_DEMO');

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    demoMode
        ? MyDrApp(dependencies: AppDependencies.withMockData(DateTime.now()))
        : const MyDrBootstrap(),
  );
}
