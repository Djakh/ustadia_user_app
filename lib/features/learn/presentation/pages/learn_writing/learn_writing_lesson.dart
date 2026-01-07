import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_writing_model.dart';

class LearnWritingLesson extends StatelessWidget {
  final LearnWritingLessonModel lessonDataModel;
  final Function() onTapContinue;
  const LearnWritingLesson({super.key, required this.lessonDataModel, required this.onTapContinue});

  Widget lessonTitle(BuildContext context) =>
      Text(lessonDataModel.topicTitle, style: Style.body2w5(context));

  Widget lessonParagraph(String text) => Builder(
      builder: (context) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(text, style: Style.bodyw4(context))));

  Widget lessonContent(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        lessonTitle(context),
        const SizedBox(height: 12),
        ...lessonDataModel.paragraphs.map(lessonParagraph)
      ]);

  Widget view(BuildContext context) => Column(children: [
        const SizedBox(height: 24),
        Expanded(child: SingleChildScrollView(child: lessonContent(context))),
        const SizedBox(height: 16),
        Button.primary(onTap: onTapContinue, text: 'Continue')
      ]);

  @override
  Widget build(BuildContext context) => view(context);
}
