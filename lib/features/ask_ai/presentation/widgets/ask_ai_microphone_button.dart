import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class AskAiMicrophoneButton extends StatelessWidget {
  final bool isConnecting;
  final bool isRecording;
  final String labelText;
  final VoidCallback? onTap;

  const AskAiMicrophoneButton(
      {super.key,
      required this.isConnecting,
      required this.isRecording,
      required this.labelText,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isRecording ? AppColors.error : AppColors.primary;
    final icon = isRecording ? Icons.stop_rounded : Icons.mic_rounded;
    final isDisabled = onTap == null;
    final buttonColor = isConnecting || isDisabled ? AppColors.gray500 : backgroundColor;

    return SafeArea(
        top: false,
        child: Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                  onTap: isConnecting ? null : onTap,
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                          color: buttonColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                                color: backgroundColor.withValues(alpha: 0.35),
                                blurRadius: 22,
                                spreadRadius: 2)
                          ]),
                      child: Icon(icon, color: AppColors.white, size: 34))),
              const SizedBox(height: 10),
              Text(labelText, style: Style.small3w5(context, color: TextColorRole.whiteColor))
            ])));
  }
}
