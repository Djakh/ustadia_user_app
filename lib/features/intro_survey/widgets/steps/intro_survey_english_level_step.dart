import 'package:flutter/material.dart';
import 'package:ustadia_user_app/features/intro_survey/widgets/intro_survey_option_tile.dart';

class IntroSurveyEnglishLevelStep extends StatelessWidget {
  final List<IntroSurveyOptionData> options;
  final int? selectedIndex;
  final ValueChanged<int> onSelectIndex;

  const IntroSurveyEnglishLevelStep({
    super.key,
    required this.options,
    required this.selectedIndex,
    required this.onSelectIndex,
  });

  /// --- Widgets ---

  Widget get list => Expanded(
      child: ListView.separated(
          padding: EdgeInsets.zero,
          itemCount: options.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => IntroSurveyOptionTile(
              data: options[index],
              selected: selectedIndex == index,
              onTap: () => onSelectIndex(index))));

  Widget get view => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        const SizedBox(height: 16),
        list,
      ]));

  @override
  Widget build(BuildContext context) => view;
}
