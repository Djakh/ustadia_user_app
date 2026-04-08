import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ask_ai_control_icon_button.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ask_ai_microphone_button.dart';

class AskAiVoiceControls extends StatelessWidget {
  final bool isConnecting;
  final bool isRecording;
  final String labelText;
  final VoidCallback? onMicrophoneTap;
  final VoidCallback onKeyboardTap;

  const AskAiVoiceControls(
      {super.key,
      required this.isConnecting,
      required this.isRecording,
      required this.labelText,
      required this.onMicrophoneTap,
      required this.onKeyboardTap});

  @override
  Widget build(BuildContext context) => SizedBox(
      height: 126,
      child: Stack(children: [
        Align(
            alignment: Alignment.bottomCenter,
            child: AskAiMicrophoneButton(
                isConnecting: isConnecting,
                isRecording: isRecording,
                labelText: labelText,
                onTap: onMicrophoneTap)),
        Positioned(
            right: 18,
            bottom: 42,
            child: AskAiControlIconButton(
                iconData: Icons.keyboard_rounded,
                onTap: onKeyboardTap,
                tooltipText: 'Type a message'.tr(),
                backgroundColor: AppColors.gray700))
      ]));
}
