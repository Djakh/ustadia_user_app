import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/router.dart';

class PracticeSpeedMixResultStats {
  final int total;
  final int completed;
  final int correct;
  final bool timeUp;

  const PracticeSpeedMixResultStats(
      {required this.total, required this.completed, required this.correct, required this.timeUp});
}

class PracticeSpeedMixResultPage extends StatelessWidget {
  final PracticeSpeedMixResultStats stats;
  const PracticeSpeedMixResultPage({super.key, required this.stats});

  /// --- Methods ---

  void onPlayAgain(BuildContext context) {
    context.pushReplacement(speedMixRoute);
  }

  void onBackToPractice(BuildContext context) => context.go(practiceRoute);

  /// --- Widgets ---

  Widget get summaryImage => Image.asset(AppImages.speedMixClock, height: 160, width: 160);

  Widget titleText(BuildContext context) =>
      Text(stats.timeUp ? "Time's up!" : 'Completed', style: Style.body2w6(context));

  Widget statLine(BuildContext context, String text) =>
      Text(text, style: Style.small3w4(context, color: TextColorRole.greyColor));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.cs.surface,
        body: PrimaryBackground(
            title: 'Speed Mix',
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(),
                summaryImage,
                const SizedBox(height: 12),
                titleText(context),
                const SizedBox(height: 6),
                statLine(context, 'Completed: ${stats.completed} / ${stats.total}'),
                const SizedBox(height: 6),
                statLine(context, 'Correct answers: ${stats.correct}'),
                const SizedBox(height: 6),
                statLine(context, 'Remaining: ${stats.total - stats.completed}'),
                const Spacer(),
                Button.primary(onTap: () => onPlayAgain(context), text: 'Play again'),
                const SizedBox(height: 10),
                Button.border(onTap: () => onBackToPractice(context), text: 'Back to practice')
              ],
            )),
      );
}
