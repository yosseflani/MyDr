import 'package:flutter/material.dart';
import 'package:mydr/core/theme/app_colors.dart';

/// Material 3 themes for the app, generated from the brand teal.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);

  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: AppColors.teal,
      brightness: brightness,
    );

    // A slightly tinted background lets white cards stand out.
    final backgroundColor = colorScheme.surfaceContainerLow;

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: backgroundColor,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        backgroundColor: backgroundColor,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
