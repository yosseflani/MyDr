import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/app.dart';
import 'package:mydr/core/theme/app_theme.dart';

extension PumpApp on WidgetTester {
  /// Pumps [child] with the same theme, Hebrew locale and RTL setup as the app.
  Future<void> pumpApp(Widget child) {
    return pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: MyDrApp.hebrew,
        supportedLocales: const [MyDrApp.hebrew],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: child,
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
