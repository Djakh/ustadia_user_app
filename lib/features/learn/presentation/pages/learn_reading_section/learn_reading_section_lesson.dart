import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';

class LearnReadingLesson extends StatelessWidget {
  final Function() changeStage;
  const LearnReadingLesson({super.key, required this.changeStage});

  /// --- Widgets ---

  Widget title(BuildContext context) => Text(
        "Daily Routines",
        style: Style.body2w5(context),
      );

  Widget lessonText(BuildContext context) => Text(
        "Many people start their day with simple morning routines. These routines help them feel more focused, calm, and ready for the day ahead.\n\nA typical morning often begins with waking up early. Some people wake up at the same time every day to keep a stable schedule. After waking up, they usually wash their face, brush their teeth, and get dressed. These basic actions help the body and mind wake up fully.\n\nBreakfast is an important part of the morning routine. Some people eat a light breakfast, such as fruit or yogurt, while others prefer a full meal with eggs, bread, or cereal. Eating in the morning gives energy and helps people concentrate better during the day.\n\nMany people also take time to read, exercise, or plan their day in the morning. Reading the news or a short book helps them stay informed. Light exercise, like stretching or walking, helps the body feel more active. Planning tasks for the day helps people stay organized and productive.\n\nAlthough morning routines are different for everyone, having regular habits can make the day easier and more balanced.",
        style: Style.bodyw4(context),
      );

  Widget readingText(BuildContext context) =>
      ListView(children: [title(context), const SizedBox(height: 16), lessonText(context)]);

  Widget view(BuildContext context) => Column(children: [
        const SizedBox(height: 24),
        Expanded(child: readingText(context)),
        const SizedBox(height: 8),
        Button.primary(onTap: changeStage, text: 'Continue')
      ]);

  @override
  Widget build(BuildContext context) => view(context);
}
