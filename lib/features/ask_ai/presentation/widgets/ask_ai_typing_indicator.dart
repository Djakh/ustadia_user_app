import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class AskAiTypingIndicator extends StatefulWidget {
  final String text;

  const AskAiTypingIndicator({super.key, required this.text});

  @override
  State<AskAiTypingIndicator> createState() => AskAiTypingIndicatorState();
}

class AskAiTypingIndicatorState extends State<AskAiTypingIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  Widget dot(int index) => AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final phase = (animationController.value + (index * 0.18)) % 1;
        final opacity = 0.25 + ((1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0) * 0.75);
        final translateY = -3 * (1 - (phase - 0.5).abs() * 2).clamp(0.0, 1.0);
        return Transform.translate(
            offset: Offset(0, translateY),
            child: Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: opacity), shape: BoxShape.circle)));
      });

  @override
  Widget build(BuildContext context) => Align(
      alignment: Alignment.centerLeft,
      child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.08),
              borderRadius: Style.border16,
              border: Border.all(color: AppColors.white.withValues(alpha: 0.08))),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(widget.text, style: Style.bodyw5(context, color: TextColorRole.whiteColor)),
            const SizedBox(width: 10),
            dot(0),
            const SizedBox(width: 4),
            dot(1),
            const SizedBox(width: 4),
            dot(2)
          ])));
}
