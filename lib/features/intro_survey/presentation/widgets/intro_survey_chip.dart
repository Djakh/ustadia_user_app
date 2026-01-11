import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';

class IntroSurveyChip extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color selectedBackgroundColor;
  final Color textColor;
  final bool selected;
  final VoidCallback onTap;

  const IntroSurveyChip(
      {super.key,
      required this.label,
      required this.backgroundColor,
      required this.selectedBackgroundColor,
      required this.textColor,
      required this.selected,
      required this.onTap});

  /// --- Methods ---

  Color get background => selected ? selectedBackgroundColor : backgroundColor;
  Color get currentTextColor => selected ? AppColors.white : textColor;

  /// --- Widgets ---

  Widget title(BuildContext context) =>
      Text(label, style: Style.small2w5(context).copyWith(color: currentTextColor));

  Widget view(BuildContext context) => PrimaryBox(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      borderRadius: Style.border95,
      backgroundColor: background,
      child: title(context));

  @override
  Widget build(BuildContext context) => view(context);
}
