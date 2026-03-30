import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/ask_ai/state/voice_call_notifier.dart';
import 'package:ustadia_user_app/features/ask_ai/widgets/voice_orb.dart';

class AskAiVoiceAgentSection extends StatelessWidget {
  final VoiceCallNotifier voiceCallNotifier;
  final VoiceUiState voiceUiState;
  final String statusText;

  const AskAiVoiceAgentSection(
      {super.key,
      required this.voiceCallNotifier,
      required this.voiceUiState,
      required this.statusText});

  Widget equalizerBar(double height, double opacity) => AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: 4,
      height: height,
      decoration: BoxDecoration(
          color: AppColors.white.withValues(alpha: opacity), borderRadius: Style.border95));

  Widget equalizer(BuildContext context) {
    final speakingLevel = voiceCallNotifier.agentAudioLevel.clamp(0.0, 1.0);
    final baseHeight = 10 + (speakingLevel * 34);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      equalizerBar(baseHeight * 0.6, 0.45),
      const SizedBox(width: 4),
      equalizerBar(baseHeight, 0.9),
      const SizedBox(width: 4),
      equalizerBar(baseHeight * 0.75, 0.65)
    ]);
  }

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
      tween: Tween(begin: -40, end: 0),
      duration: const Duration(milliseconds: 620),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) =>
          Transform.translate(offset: Offset(0, value), child: child),
      child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          child: Column(children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.05),
                    borderRadius: Style.border24,
                    border: Border.all(color: AppColors.white.withValues(alpha: 0.08))),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedOpacity(
                        opacity: voiceCallNotifier.assistantSpeaking ? 1 : 0.24,
                        duration: const Duration(milliseconds: 220),
                        child: equalizer(context)),
                    const SizedBox(width: 16),
                    VoiceOrb(
                        voiceUiState: voiceUiState,
                        assistantLevel: voiceCallNotifier.agentAudioLevel,
                        userLevel: voiceCallNotifier.localAudioLevel,
                        assistantSpeaking: voiceCallNotifier.assistantSpeaking,
                        userSpeaking: voiceCallNotifier.userSpeaking,
                        size: 132),
                    const SizedBox(width: 16),
                    AnimatedOpacity(
                        opacity: voiceCallNotifier.assistantSpeaking ? 1 : 0.24,
                        duration: const Duration(milliseconds: 220),
                        child: equalizer(context))
                  ]),
                  const SizedBox(height: 16),
                  Text(statusText,
                      textAlign: TextAlign.center,
                      style: Style.bodyw6(context, color: TextColorRole.whiteColor))
                ]))
          ])));
}
