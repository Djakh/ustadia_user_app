import 'package:flutter/material.dart';
import 'package:ustadia_user_app/features/intro_survey/data/intro_survey_models.dart';
import 'package:ustadia_user_app/features/intro_survey/widgets/intro_survey_chip.dart';

class IntroSurveyTopicsStep extends StatelessWidget {
  final List<IntroSurveyTopicModel> topics;
  final Set<String> selectedTopics;
  final ValueChanged<String> onToggleTopic;

  const IntroSurveyTopicsStep(
      {super.key, required this.topics, required this.selectedTopics, required this.onToggleTopic});

  /// --- Widgets ---

  Widget chip(IntroSurveyTopicModel topic) => IntroSurveyChip(
      topic: topic, selected: selectedTopics.contains(topic.label), onTap: () => onToggleTopic(topic.label));

  Widget get chips => Center(
      child: Wrap(
          spacing: 10,
          runSpacing: 10,
          alignment: WrapAlignment.center,
          children: topics.map(chip).toList()));

  Widget get view => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        const Spacer(flex: 2),
        chips,
        const Spacer(flex: 3),
      ]));

  @override
  Widget build(BuildContext context) => view;
}
