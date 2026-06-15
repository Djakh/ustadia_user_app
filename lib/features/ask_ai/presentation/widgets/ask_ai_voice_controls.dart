import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ask_ai_control_icon_button.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/widgets/ask_ai_microphone_button.dart';
import 'package:ustadia_user_app/features/ask_ai/state/voice_call_notifier.dart';

class AskAiVoiceControls extends StatelessWidget {
  final bool isConnecting;
  final bool isRecording;
  final VoiceAudioOutputMode outputMode;
  final bool hasExternalOutputRoute;
  final String labelText;
  final VoidCallback? onMicrophoneTap;
  final VoidCallback? onAudioOutputTap;
  final VoidCallback onKeyboardTap;

  const AskAiVoiceControls(
      {super.key,
      required this.isConnecting,
      required this.isRecording,
      required this.outputMode,
      required this.hasExternalOutputRoute,
      required this.labelText,
      required this.onMicrophoneTap,
      required this.onAudioOutputTap,
      required this.onKeyboardTap});

  IconData get outputIcon => hasExternalOutputRoute
      ? Icons.headphones_rounded
      : outputMode == VoiceAudioOutputMode.speaker
          ? Icons.volume_up_rounded
          : Icons.phone_in_talk_rounded;

  String get outputTooltip => hasExternalOutputRoute
      ? 'Headphones'.tr()
      : outputMode == VoiceAudioOutputMode.speaker
          ? 'Speaker'.tr()
          : 'Phone'.tr();

  Color get outputButtonColor {
    if (hasExternalOutputRoute) return AppColors.gray700;
    return outputMode == VoiceAudioOutputMode.speaker ? AppColors.primary : AppColors.gray700;
  }

  @override
  Widget build(BuildContext context) => SizedBox(
      height: 126,
      child: Stack(children: [
        Positioned(
            left: 22,
            bottom: 42,
            child: TweenAnimationBuilder<double>(
                key: ValueKey(outputMode),
                tween: Tween(begin: 0.88, end: 1),
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutBack,
                builder: (context, value, child) => Transform.rotate(
                    angle: (1 - value) * 0.45, child: Transform.scale(scale: value, child: child)),
                child: AskAiControlIconButton(
                    iconData: outputIcon,
                    onTap: hasExternalOutputRoute ? null : onAudioOutputTap,
                    tooltipText: outputTooltip,
                    backgroundColor: outputButtonColor,
                    size: 50))),
        Align(
            alignment: Alignment.bottomCenter,
            child: AskAiMicrophoneButton(
                isConnecting: isConnecting,
                isRecording: isRecording,
                labelText: labelText,
                onTap: onMicrophoneTap)),
        Positioned(
            right: 22,
            bottom: 42,
            child: AskAiControlIconButton(
                iconData: Icons.keyboard_rounded,
                onTap: onKeyboardTap,
                tooltipText: 'Type a message'.tr(),
                backgroundColor: AppColors.gray700,
                size: 50))
      ]));
}
