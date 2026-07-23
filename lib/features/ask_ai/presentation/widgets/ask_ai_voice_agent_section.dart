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

  Color get accentColor {
    if (voiceCallNotifier.assistantSpeaking) return AppColors.green6A;
    if (voiceCallNotifier.userSpeaking) return AppColors.blueFB;
    switch (voiceUiState) {
      case VoiceUiState.connecting:
        return AppColors.blueD3;
      case VoiceUiState.listening:
        return AppColors.primary;
      case VoiceUiState.thinking:
        return AppColors.purpleD6;
      case VoiceUiState.speaking:
        return AppColors.green6A;
      case VoiceUiState.error:
        return AppColors.error;
    }
  }

  bool get isVoiceActive =>
      voiceCallNotifier.assistantSpeaking ||
      voiceCallNotifier.userSpeaking ||
      voiceUiState == VoiceUiState.speaking;

  double get activeAudioLevel {
    if (voiceCallNotifier.assistantSpeaking) {
      return voiceCallNotifier.agentAudioLevel.clamp(0.0, 1.0).toDouble();
    }
    if (voiceCallNotifier.userSpeaking) {
      return voiceCallNotifier.localAudioLevel.clamp(0.0, 1.0).toDouble();
    }
    return 0;
  }

  Widget equalizerBar(double height, double opacity) => AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      width: 4,
      height: height,
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.white.withValues(alpha: opacity),
                accentColor.withValues(alpha: opacity * 0.72)
              ]),
          borderRadius: Style.border95));

  Widget equalizer(BuildContext context) {
    final baseHeight = 10 + (activeAudioLevel * 34);
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
            AnimatedContainer(
                duration: const Duration(milliseconds: 360),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                    gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.white.withValues(alpha: 0.075),
                          AppColors.white.withValues(alpha: 0.038)
                        ]),
                    borderRadius: Style.border24,
                    border: Border.all(color: accentColor.withValues(alpha: 0.2)),
                    boxShadow: [
                      BoxShadow(
                          color: accentColor.withValues(alpha: 0.18),
                          blurRadius: 34,
                          spreadRadius: -8,
                          offset: const Offset(0, 18)),
                      BoxShadow(
                          color: AppColors.black.withValues(alpha: 0.22),
                          blurRadius: 26,
                          offset: const Offset(0, 14))
                    ]),
                child: Column(children: [
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    AnimatedOpacity(
                        opacity: isVoiceActive ? 1 : 0.24,
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
                        opacity: isVoiceActive ? 1 : 0.24,
                        duration: const Duration(milliseconds: 220),
                        child: equalizer(context))
                  ]),
                  const SizedBox(height: 16),
                  AnimatedSwitcher(
                      duration: const Duration(milliseconds: 220),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeOutCubic,
                      child: Text(statusText,
                          key: ValueKey(statusText),
                          textAlign: TextAlign.center,
                          style: Style.bodyw6(context, color: TextColorRole.whiteColor))),
                  const SizedBox(height: 8),
                  Opacity(
                      opacity: 0.64,
                      child: Text(
                          'Responses are generated by AI, not by another user or teacher.'.tr(),
                          textAlign: TextAlign.center,
                          style: Style.small2w4(context, color: TextColorRole.whiteColor)))
                ]))
          ])));
}
