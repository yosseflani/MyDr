import 'package:flutter/material.dart';

/// Brand colors used on top of the generated Material 3 color scheme.
abstract final class AppColors {
  static const Color teal = Color(0xFF0F9D9A);
  static const Color blue = Color(0xFF2B6CB0);
  static const Color skyBlue = Color(0xFF0284C7);

  /// Teal-to-blue gradient. Directional, so it mirrors correctly in RTL.
  static const LinearGradient brandGradient = LinearGradient(
    begin: AlignmentDirectional.topStart,
    end: AlignmentDirectional.bottomEnd,
    colors: [teal, blue],
  );
}
