import 'package:easy_localization/easy_localization.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_type_theme.dart';

class AssignmentThemeCatalog {
  static AssignmentTypeTheme themeForType(String type) {
    final normalized = type.trim().toLowerCase();
    if (normalized.startsWith('writing')) return writing;
    if (normalized.startsWith('speaking')) return speaking;
    switch (normalized) {
      case 'listening':
        return listening;
      case 'reading':
        return reading;
      case 'speaking':
        return speaking;
      case 'grammar':
        return grammar;
      case 'writing':
        return writing;
      case 'vocabulary':
        return vocabulary;
      default:
        return reading;
    }
  }

  static AssignmentTypeTheme get listening => AssignmentTypeTheme(
      label: 'Listening'.tr(),
      textColor: AppColors.green6B,
      backgroundColor: AppColors.greenE7,
      accentColor: AppColors.green6B,
      emoji: '👂');

  static AssignmentTypeTheme get reading => AssignmentTypeTheme(
      label: 'Reading'.tr(),
      textColor: AppColors.blueD3,
      backgroundColor: AppColors.blueFF,
      accentColor: AppColors.blueD3,
      emoji: '📚');

  static AssignmentTypeTheme get speaking => AssignmentTypeTheme(
      label: 'Speaking'.tr(),
      textColor: AppColors.purpleD6,
      backgroundColor: AppColors.purpleFF,
      accentColor: AppColors.purpleD6,
      emoji: '🗣️');

  static AssignmentTypeTheme get grammar => AssignmentTypeTheme(
      label: 'Grammar'.tr(),
      textColor: AppColors.orange12,
      backgroundColor: AppColors.orangeEB,
      accentColor: AppColors.orange12,
      emoji: '🧩');

  static AssignmentTypeTheme get writing => AssignmentTypeTheme(
      label: 'Writing'.tr(),
      textColor: AppColors.orange12,
      backgroundColor: AppColors.orangeEB,
      accentColor: AppColors.orange12,
      emoji: '📝');

  static AssignmentTypeTheme get vocabulary => AssignmentTypeTheme(
      label: 'Vocabulary'.tr(),
      textColor: AppColors.blueB3,
      backgroundColor: AppColors.blueFF,
      accentColor: AppColors.blueB3,
      emoji: '📖');
}
