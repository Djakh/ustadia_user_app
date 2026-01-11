import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/features/intro_survey/data/intro_survey_models.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/widgets/intro_survey_chip.dart';

class IntroSurveyMultipleChoice extends StatelessWidget {
  final List<IntroSurveyAnswerModel> answers;
  final Set<String> selectedAnswerIds;
  final ValueChanged<String> onToggleAnswer;

  const IntroSurveyMultipleChoice(
      {super.key,
      required this.answers,
      required this.selectedAnswerIds,
      required this.onToggleAnswer});

  /// --- Widgets ---

  static const chipBackgroundColors = [
    AppColors.purpleFF,
    AppColors.greenE9,
    AppColors.orangeE6,
    AppColors.blueFF,
    AppColors.greenD8,
    AppColors.pinkF7
  ];

  static const chipSelectedBackgroundColors = [
    AppColors.purpleD6,
    AppColors.green55,
    AppColors.orange00,
    AppColors.blueB3,
    AppColors.green00,
    AppColors.pinkB7
  ];

  static const chipTextColors = [
    AppColors.purpleD6,
    AppColors.green3B,
    AppColors.orange5A,
    AppColors.blueD3,
    AppColors.green7C,
    AppColors.pink72
  ];

  Color backgroundColorFor(int index) =>
      chipBackgroundColors[index % chipBackgroundColors.length];

  Color selectedBackgroundColorFor(int index) =>
      chipSelectedBackgroundColors[index % chipSelectedBackgroundColors.length];

  Color textColorFor(int index) => chipTextColors[index % chipTextColors.length];

  Widget chip(IntroSurveyAnswerModel answer, int index) => IntroSurveyChip(
      label: answer.text,
      backgroundColor: backgroundColorFor(index),
      selectedBackgroundColor: selectedBackgroundColorFor(index),
      textColor: textColorFor(index),
      selected: selectedAnswerIds.contains(answer.id),
      onTap: () => onToggleAnswer(answer.id));

  Widget get chips => Center(
      child: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: List.generate(
              answers.length,
              (index) => chip(answers[index], index))));

  Widget get view => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        const Spacer(flex: 2),
        chips,
        const Spacer(flex: 3)
      ]));

  @override
  Widget build(BuildContext context) => view;
}
