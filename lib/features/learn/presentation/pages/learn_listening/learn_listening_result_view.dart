import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';

class LearnListeningResultView extends StatelessWidget {
  final int correctCount;
  final int questionsLength;
  const LearnListeningResultView(
      {super.key, required this.correctCount, required this.questionsLength});

  /// --- Methods ---

  void backToTopic(BuildContext context) => context.pop();

  /// --- Widgets ---

  Text resultInfo(BuildContext context) =>
      Text('You got $correctCount out of $questionsLength correct.',
          style: Style.bodyw4(context, color: TextColorRole.greyColor));

  Widget view(BuildContext context) => Column(children: [
        const Spacer(),
        Image.asset(AppImages.learnListeningCheck, height: 160, width: 160),
        Text('Quiz completed!', style: Style.body3w7(context)),
        const SizedBox(height: 4),
        resultInfo(context),
        const Spacer(),
        Button.primary(onTap: () => backToTopic(context), text: 'Back to topic')
      ]);

  @override
  Widget build(BuildContext context) => view(context);
}
