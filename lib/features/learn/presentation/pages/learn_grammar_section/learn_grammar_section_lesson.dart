import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/audio_card.dart';

class LearnGrammarLesson extends StatelessWidget {
  final LearnSectionModel sectionModel;
  final Function() changeStage;
  const LearnGrammarLesson({super.key, required this.changeStage, required this.sectionModel});

  /// --- Widgets ---

  Widget title(BuildContext context) => Text(
        "Daily Routines",
        style: Style.body2w5(context),
      );

  Widget lessonText(BuildContext context) => Text(
        "We use the Present Simple to talk about habits, daily routines, and general facts. It describes things that happen regularly or are always true.\n\nFor habits, the Present Simple shows what people do every day or often. For example, a person wakes up early, drinks coffee, and goes to work. These actions happen again and again.\n\nIn the Present Simple, the verb stays the same for most subjects. However, with he, she, and it, we usually add -s or -es to the verb. For example, “She works in an office” or “He watches TV in the evening.”\n\nTo make negative sentences, we use do not (don’t) or does not (doesn’t) before the verb. To ask questions, we use do or does at the beginning of the sentence.\n\nThe Present Simple helps us talk clearly about habits and facts in everyday English.",
        style: Style.bodyw4(context),
      );

  Widget grammarText(BuildContext context) =>
      ListView(children: [title(context), const SizedBox(height: 16), lessonText(context)]);

  Widget view(BuildContext context) => Column(children: [
        const SizedBox(height: 24),
        Text(sectionModel.subtitle, style: Style.small3w4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 16),
        const AudioCard(),
        const SizedBox(height: 24),
        Expanded(child: grammarText(context)),
        const SizedBox(height: 8),
        Button.primary(onTap: changeStage, text: 'Continue')
      ]);

  @override
  Widget build(BuildContext context) => view(context);
}
