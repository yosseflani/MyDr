import 'package:flutter/widgets.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/features/family/family_controller.dart';

/// Makes the shared [AppDependencies] and feature controllers available to
/// every widget below it.
///
/// Placed above `MaterialApp` so routes pushed with `Navigator` can reach
/// it too.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.dependencies,
    required this.familyController,
    required super.child,
  });

  final AppDependencies dependencies;
  final FamilyController familyController;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      !identical(dependencies, oldWidget.dependencies) ||
      !identical(familyController, oldWidget.familyController);
}
