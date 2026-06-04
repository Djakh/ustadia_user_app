import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ask_ai_control_icon_button.dart';

class AskAiTextMessageComposer extends StatelessWidget {
  static const double minComposerHeight = 58;
  static const double maxComposerHeight = 124;
  static const double textLineHeight = 22.4;
  static const double textVerticalPadding = 10;
  static const double inputHorizontalPadding = 30;
  static const double sendButtonWidth = 44;
  static const double sendButtonSpacing = 10;

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool canSend;
  final Future<void> Function() onSend;
  final VoidCallback onVoiceModeTap;

  const AskAiTextMessageComposer(
      {super.key,
      required this.controller,
      required this.focusNode,
      required this.canSend,
      required this.onSend,
      required this.onVoiceModeTap});

  InputDecoration inputDecoration() => InputDecoration(
      isDense: true,
      hintText: 'Type a message'.tr(),
      hintStyle:
          const TextStyle(color: AppColors.gray400, fontSize: 16, fontWeight: FontWeight.w400),
      contentPadding: const EdgeInsets.symmetric(vertical: textVerticalPadding),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none);

  double composerHeight({required String text, required TextStyle style, required double width}) {
    final textWidth = (width - inputHorizontalPadding - sendButtonWidth - sendButtonSpacing)
        .clamp(0, double.infinity)
        .toDouble();

    if (text.trim().isEmpty || textWidth == 0) return minComposerHeight;

    final painter = TextPainter(
        text: TextSpan(text: text, style: style), maxLines: 4, textDirection: ui.TextDirection.ltr)
      ..layout(maxWidth: textWidth);
    final lineCount = painter.computeLineMetrics().length.clamp(1, 4);
    final contentHeight = textLineHeight * lineCount + textVerticalPadding * 2;

    return contentHeight.clamp(minComposerHeight, maxComposerHeight).toDouble();
  }

  Expanded textInputSender(BuildContext context) {
    return Expanded(child: LayoutBuilder(builder: (context, constraints) {
      final textStyle = Style.bodyw5(context, color: TextColorRole.whiteColor);

      return ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            final height =
                composerHeight(text: value.text, style: textStyle, width: constraints.maxWidth);
            final hasText = value.text.trim().isNotEmpty;
            final sendEnabled = canSend && hasText;

            return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                height: height,
                padding: const EdgeInsets.fromLTRB(18, 0, 12, 0),
                decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(minComposerHeight / 2),
                    border: Border.all(color: AppColors.white.withValues(alpha: 0.08))),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  Expanded(
                      child: TextField(
                          controller: controller,
                          focusNode: focusNode,
                          minLines: 1,
                          maxLines: null,
                          textAlignVertical: TextAlignVertical.center,
                          textCapitalization: TextCapitalization.sentences,
                          textInputAction: TextInputAction.newline,
                          keyboardAppearance: Brightness.dark,
                          style: textStyle,
                          cursorColor: AppColors.primary,
                          decoration: inputDecoration(),
                          onSubmitted: (value) {
                            final hasText = value.trim().isNotEmpty;
                            if (!canSend || !hasText) return;
                            unawaited(onSend());
                          })),
                  const SizedBox(width: sendButtonSpacing),
                  Padding(
                      padding: const EdgeInsets.only(top: 1),
                      child: AskAiControlIconButton(
                          iconData: Icons.send_rounded,
                          onTap: sendEnabled ? () => unawaited(onSend()) : null,
                          tooltipText: 'Send'.tr(),
                          backgroundColor: sendEnabled ? AppColors.primary : AppColors.gray700,
                          size: sendButtonWidth))
                ]));
          });
    }));
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: AskAiControlIconButton(
                    iconData: Icons.mic_rounded,
                    onTap: onVoiceModeTap,
                    tooltipText: 'Tap microphone'.tr(),
                    backgroundColor: AppColors.gray700,
                    size: 58)),
            const SizedBox(width: 12),
            textInputSender(context)
          ])));
}
