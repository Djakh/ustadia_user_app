import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ask_ai_control_icon_button.dart';

class AskAiTextMessageComposer extends StatelessWidget {
  static const double minComposerHeight = 76;
  static const double maxComposerHeight = 132;

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
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none);

  Expanded textInputSender(BuildContext context) {
    return Expanded(
        child: AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic,
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
                constraints: const BoxConstraints(
                    minHeight: minComposerHeight, maxHeight: maxComposerHeight),
                child: Container(
                    padding: const EdgeInsets.fromLTRB(18, 0, 12, 0),
                    decoration: BoxDecoration(
                        color: AppColors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(minComposerHeight / 2),
                        border: Border.all(color: AppColors.white.withValues(alpha: 0.08))),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                      Expanded(
                          child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextField(
                                  controller: controller,
                                  focusNode: focusNode,
                                  minLines: 1,
                                  maxLines: 5,
                                  textAlignVertical: TextAlignVertical.center,
                                  textCapitalization: TextCapitalization.sentences,
                                  textInputAction: TextInputAction.newline,
                                  keyboardAppearance: Brightness.dark,
                                  style: Style.bodyw5(context, color: TextColorRole.whiteColor),
                                  cursorColor: AppColors.primary,
                                  decoration: inputDecoration(),
                                  onSubmitted: (value) {
                                    final hasText = value.trim().isNotEmpty;
                                    if (!canSend || !hasText) return;
                                    unawaited(onSend());
                                  }))),
                      const SizedBox(width: 10),
                      Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: controller,
                              builder: (context, value, child) {
                                final hasText = value.text.trim().isNotEmpty;
                                final sendEnabled = canSend && hasText;
                                return AskAiControlIconButton(
                                    iconData: Icons.send_rounded,
                                    onTap: sendEnabled ? () => unawaited(onSend()) : null,
                                    tooltipText: 'Send'.tr(),
                                    backgroundColor:
                                        sendEnabled ? AppColors.primary : AppColors.gray700,
                                    size: 44);
                              }))
                    ])))));
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
