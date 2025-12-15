import 'package:flutter/material.dart';

import 'app_colors.dart';

class AppColorScheme {
  static const ColorScheme light = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    surface: AppColors.surface,
    onSurface: AppColors.secondary,
    tertiary: AppColors.white,
    onTertiary: AppColors.gray8D,
    error: AppColors.error,
    onError: AppColors.white,
  );

  static const ColorScheme dark = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    secondary: AppColors.secondary,
    onSecondary: AppColors.black,
    surface: AppColors.secondary,
    onSurface: AppColors.white,
    tertiary: AppColors.white,
    onTertiary: AppColors.gray8D,
    error: AppColors.error,
    onError: AppColors.white,
  );
}
