import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_type_theme.dart';

class AssignmentThemeCatalog {
  static AssignmentTypeTheme themeForType(String type) {
    switch (type) {
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

  static const AssignmentTypeTheme listening = AssignmentTypeTheme(
    label: 'Listening',
    textColor: AppColors.green6B,
    backgroundColor: AppColors.greenE7,
    accentColor: AppColors.green6B,
    emoji: '👂'
  );

  static const AssignmentTypeTheme reading = AssignmentTypeTheme(
    label: 'Reading',
    textColor: AppColors.blueD3,
    backgroundColor: AppColors.blueFF,
    accentColor: AppColors.blueD3,
    emoji: '📚'
  );

  static const AssignmentTypeTheme speaking = AssignmentTypeTheme(
    label: 'Speaking',
    textColor: AppColors.purpleD6,
    backgroundColor: AppColors.purpleFF,
    accentColor: AppColors.purpleD6,
    emoji: '🗣️'
  );

  static const AssignmentTypeTheme grammar = AssignmentTypeTheme(
    label: 'Grammar',
    textColor: AppColors.orange12,
    backgroundColor: AppColors.orangeEB,
    accentColor: AppColors.orange12,
    emoji: '🧩'
  );

  static const AssignmentTypeTheme writing = AssignmentTypeTheme(
    label: 'Writing',
    textColor: AppColors.orange12,
    backgroundColor: AppColors.orangeEB,
    accentColor: AppColors.orange12,
    emoji: '📝'
  );

  static const AssignmentTypeTheme vocabulary = AssignmentTypeTheme(
    label: 'Vocabulary',
    textColor: AppColors.blueB3,
    backgroundColor: AppColors.blueFF,
    accentColor: AppColors.blueB3,
    emoji: '📖'
  );
}
