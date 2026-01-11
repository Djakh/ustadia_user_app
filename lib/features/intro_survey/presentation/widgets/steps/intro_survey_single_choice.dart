import 'package:flutter/material.dart';
import 'package:ustadia_user_app/features/intro_survey/data/intro_survey_models.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/widgets/intro_survey_option_tile.dart';

class IntroSurveySingleChoice extends StatelessWidget {
  final List<IntroSurveyAnswerModel> answers;
  final String? selectedAnswerId;
  final ValueChanged<String> onSelectAnswer;

  const IntroSurveySingleChoice({
    super.key,
    required this.answers,
    required this.selectedAnswerId,
    required this.onSelectAnswer
  });

  /// --- Widgets ---

  Widget get list => Expanded(
      child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: answers.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => IntroSurveyOptionTile(
              answer: answers[index],
              selected: selectedAnswerId == answers[index].id,
              onTap: () => onSelectAnswer(answers[index].id))));

  Widget get view => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        const SizedBox(height: 16),
        list
      ]));

  @override
  Widget build(BuildContext context) => view;
}
