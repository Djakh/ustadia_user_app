import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';

class QuizResultComponent extends StatelessWidget {
  final int? all;
  final int? correctOnes;
  final String? aiFeedback;
  final String? feedback;

  const QuizResultComponent({
    super.key,
    this.all,
    this.correctOnes,
    this.aiFeedback,
    this.feedback,
  });

  /// --- Methods ---

  void backToTopic(BuildContext context) => context.pop(true);

  /// --- Widgets ---

  Widget correctAnswers(BuildContext context) {
    if (all == null || correctOnes == null) return const SizedBox.shrink();
    return Text(
      '$correctOnes of $all correct',
      style: Style.small2w3(context, color: TextColorRole.greyColor),
      textAlign: TextAlign.center,
    );
  }

  Widget feedbackHeader(String title, BuildContext context) => Row(children: [
        SvgPicture.asset(AppImages.feedbackIcon),
        const SizedBox(width: 8),
        Text(title, style: Style.bodyw5(context)),
      ]);

  Widget feedbacksBox(BuildContext context, String title, String text) => Container(
        padding: Style.paddingAll16,
        decoration: BoxDecoration(
          borderRadius: Style.border20,
          color: context.cs.surface,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          feedbackHeader(title, context),
          const SizedBox(height: 12),
          Text(text, style: Style.small2w4(context)),
        ]),
      );

  Widget centerBlock(BuildContext context) => Column(
        children: [
          Image.asset(AppImages.learnListeningCheck, height: 160, width: 160),
          Text('Task completed!', style: Style.body3w7(context), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          correctAnswers(context),
          const SizedBox(height: 24),
        ],
      );

  List<Widget> feedbackBlocks(BuildContext context) {
    final blocks = <Widget>[];

    if (feedback != null && feedback!.trim().isNotEmpty) {
      blocks.add(feedbacksBox(context, 'Feedback', feedback!));
      blocks.add(const SizedBox(height: 16));
    }

    if (aiFeedback != null && aiFeedback!.trim().isNotEmpty) {
      blocks.add(feedbacksBox(context, 'AI feedback', aiFeedback!));
      blocks.add(const SizedBox(height: 16));
    }

    return blocks;
  }

  Widget bottomButton(BuildContext context) => Button.primary(
        onTap: () => backToTopic(context),
        text: 'Back to topic',
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 24),
          child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight - 30),
              child: IntrinsicHeight(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                const Spacer(),
                centerBlock(context),
                ...feedbackBlocks(context),
                const Spacer(),
                bottomButton(context)
              ]))));
    });
  }
}
