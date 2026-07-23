import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/app_colors_scheme.dart';

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColorScheme.light,
      scaffoldBackgroundColor: AppColorScheme.light.surface,
      brightness: Brightness.light,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.greenE7.withValues(alpha: 0.9),
        selectionHandleColor: AppColors.primary,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: AppColorScheme.dark,
      scaffoldBackgroundColor: AppColorScheme.dark.surface,
      brightness: Brightness.dark,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: AppColors.primary,
        selectionColor: AppColors.greenE7.withValues(alpha: 0.35),
        selectionHandleColor: AppColors.primary,
      ),
    );
  }
}
