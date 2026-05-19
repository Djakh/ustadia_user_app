import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/features/ask_ai/state/voice_call_notifier.dart';

class VoiceOrb extends StatefulWidget {
  final VoiceUiState voiceUiState;
  final double assistantLevel;
  final double userLevel;
  final bool assistantSpeaking;
  final bool userSpeaking;
  final double size;

  const VoiceOrb(
      {super.key,
      required this.voiceUiState,
      required this.assistantLevel,
      required this.userLevel,
      required this.assistantSpeaking,
      required this.userSpeaking,
      this.size = 180});

  @override
  State<VoiceOrb> createState() => VoiceOrbState();
}

class VoiceOrbState extends State<VoiceOrb> with TickerProviderStateMixin {
  late final AnimationController orbController;
  late Animation<double> pulseAnimation;
  late final AnimationController shimmerController;

  @override
  void initState() {
    super.initState();
    orbController =
        AnimationController(vsync: this, duration: durationForState(widget.voiceUiState));
    shimmerController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    pulseAnimation = Tween(begin: 0.96, end: 1.04)
        .animate(CurvedAnimation(parent: orbController, curve: Curves.easeInOut));
    orbController.repeat(reverse: true);
    updateShimmerController();
  }

  @override
  void didUpdateWidget(VoiceOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.voiceUiState != widget.voiceUiState) {
      orbController.duration = durationForState(widget.voiceUiState);
      if (!orbController.isAnimating) {
        orbController.repeat(reverse: true);
      }
    }
    if (oldWidget.voiceUiState != widget.voiceUiState ||
        oldWidget.assistantSpeaking != widget.assistantSpeaking ||
        oldWidget.userSpeaking != widget.userSpeaking) {
      updateShimmerController();
    }
  }

  Duration durationForState(VoiceUiState state) {
    switch (state) {
      case VoiceUiState.listening:
        return const Duration(milliseconds: 2400);
      case VoiceUiState.thinking:
        return const Duration(milliseconds: 1600);
      case VoiceUiState.speaking:
        return const Duration(milliseconds: 900);
      case VoiceUiState.connecting:
        return const Duration(milliseconds: 1800);
      case VoiceUiState.error:
        return const Duration(milliseconds: 2000);
    }
  }

  bool get shouldRunShimmer =>
      widget.assistantSpeaking ||
      widget.userSpeaking ||
      widget.voiceUiState == VoiceUiState.connecting ||
      widget.voiceUiState == VoiceUiState.thinking ||
      widget.voiceUiState == VoiceUiState.speaking;

  void updateShimmerController() {
    if (shouldRunShimmer) {
      if (!shimmerController.isAnimating) shimmerController.repeat();
      return;
    }
    if (shimmerController.isAnimating) shimmerController.stop();
    shimmerController.value = 0.5;
  }

  double levelBoost() {
    final levelValue = widget.assistantSpeaking
        ? widget.assistantLevel
        : widget.userSpeaking
            ? widget.userLevel
            : 0;
    final raw = levelValue.clamp(0, 1).toDouble();
    return raw * 0.28;
  }

  Color targetColor() {
    if (widget.assistantSpeaking) return AppColors.green6A;
    if (widget.userSpeaking) return AppColors.blueFB;
    switch (widget.voiceUiState) {
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

  @override
  void dispose() {
    orbController.dispose();
    shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: Listenable.merge([orbController, shimmerController]),
      builder: (context, child) {
        final scaleValue = pulseAnimation.value + levelBoost();
        final colorValue = targetColor();
        final glowValue = 18 + (levelBoost() * 50);
        final shimmerShift = (shimmerController.value * 2) - 1;
        final ringScale = 1.08 + (levelBoost() * 0.8);
        return Transform.scale(
            scale: scaleValue,
            child: Stack(alignment: Alignment.center, children: [
              Transform.scale(
                  scale: ringScale,
                  child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: colorValue.withValues(alpha: 0.18), width: 1.5)))),
              AnimatedContainer(
                  duration: const Duration(milliseconds: 420),
                  curve: Curves.easeInOut,
                  width: widget.size,
                  height: widget.size,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient:
                          RadialGradient(center: Alignment(shimmerShift * 0.35, -0.2), colors: [
                        colorValue.withValues(alpha: 0.98),
                        colorValue.withValues(alpha: 0.42),
                        colorValue.withValues(alpha: 0.08)
                      ], stops: const [
                        0.16,
                        0.62,
                        1
                      ]),
                      boxShadow: [
                        BoxShadow(
                            color: colorValue.withValues(alpha: 0.45),
                            blurRadius: glowValue,
                            spreadRadius: 6)
                      ]))
            ]));
      });
}
