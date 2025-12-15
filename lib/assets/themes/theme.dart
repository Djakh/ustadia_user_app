import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors_scheme.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColorScheme.light,
      scaffoldBackgroundColor: AppColorScheme.light.surface,
      brightness: Brightness.light,
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColorScheme.dark,
      scaffoldBackgroundColor: AppColorScheme.dark.surface,
      brightness: Brightness.dark,
    );
  }
}
