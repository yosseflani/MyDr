import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/app.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/theme/app_theme.dart';
import 'package:mydr/features/family/family_controller.dart';

extension PumpApp on WidgetTester {
  /// Pumps [child] with the same theme, Hebrew locale, RTL setup and
  /// [AppScope] as the app. Uses fresh empty repositories unless
  /// [dependencies] is given, and a [FamilyController] built on them unless
  /// [familyController] is given.
  Future<void> pumpApp(
    Widget child, {
    AppDependencies? dependencies,
    FamilyController? familyController,
  }) {
    final resolvedDependencies = dependencies ?? AppDependencies.empty();
    final resolvedController =
        familyController ?? FamilyController(resolvedDependencies);
    if (familyController == null) addTearDown(resolvedController.dispose);

    return pumpWidget(
      AppScope(
        dependencies: resolvedDependencies,
        familyController: resolvedController,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: MyDrApp.hebrew,
          supportedLocales: const [MyDrApp.hebrew],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: child,
        ),
      ),
    );
  }

  /// Sets the logical screen size for the current test.
  void setScreenSize(Size size) {
    view.physicalSize = size;
    view.devicePixelRatio = 1;
    addTearDown(view.reset);
  }
}
