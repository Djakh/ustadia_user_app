import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/boxes/border_box.dart';
import 'package:ustadia_user_app/features/intro_survey/data/intro_survey_models.dart';

class IntroSurveyChip extends StatelessWidget {
  final IntroSurveyTopicModel topic;
  final bool selected;
  final VoidCallback onTap;

  const IntroSurveyChip(
      {super.key, required this.topic, required this.selected, required this.onTap});

  /// --- Methods ---

  Color get background => selected ? topic.selectedBackgroundColor : topic.backgroundColor;
  Color get textColor => selected ? AppColors.white : topic.textColor;

  /// --- Widgets ---

  Widget label(BuildContext context) =>
      Text(topic.label, style: Style.small2w5(context).copyWith(color: textColor));

  Widget view(BuildContext context) => PrimaryBox(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      borderRadius: Style.border95,
      backgroundColor: background,
      child: label(context));

  @override
  Widget build(BuildContext context) => view(context);
}
