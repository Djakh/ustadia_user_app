import 'dart:math' as math;

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
  late final AnimationController levelController;
  late final AnimationController transitionController;

  @override
  void initState() {
    super.initState();
    orbController =
        AnimationController(vsync: this, duration: durationForState(widget.voiceUiState));
    shimmerController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    levelController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 140), value: activeRawLevel());
    transitionController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 620));
    pulseAnimation = Tween(begin: 0.985, end: 1.018)
        .animate(CurvedAnimation(parent: orbController, curve: Curves.easeInOut));
    orbController.repeat(reverse: true);
    transitionController.forward(from: 0);
    updateShimmerController();
  }

  @override
  void didUpdateWidget(VoiceOrb oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.voiceUiState != widget.voiceUiState) {
      orbController.duration = durationForState(widget.voiceUiState);
      transitionController.forward(from: 0);
      if (!orbController.isAnimating) {
        orbController.repeat(reverse: true);
      }
    }
    if (oldWidget.assistantSpeaking != widget.assistantSpeaking ||
        oldWidget.userSpeaking != widget.userSpeaking) {
      transitionController.forward(from: 0);
    }
    final nextLevel = activeRawLevel();
    if ((levelController.value - nextLevel).abs() > 0.01) {
      levelController.animateTo(nextLevel,
          duration: const Duration(milliseconds: 120), curve: Curves.easeOutCubic);
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
        return const Duration(milliseconds: 2600);
      case VoiceUiState.thinking:
        return const Duration(milliseconds: 1900);
      case VoiceUiState.speaking:
        return const Duration(milliseconds: 980);
      case VoiceUiState.connecting:
        return const Duration(milliseconds: 2100);
      case VoiceUiState.error:
        return const Duration(milliseconds: 2000);
    }
  }

  bool get shouldRunShimmer =>
      widget.assistantSpeaking ||
      widget.userSpeaking ||
      widget.voiceUiState == VoiceUiState.connecting ||
      widget.voiceUiState == VoiceUiState.listening ||
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

  double activeRawLevel() {
    final levelValue = widget.assistantSpeaking
        ? widget.assistantLevel
        : widget.userSpeaking
            ? widget.userLevel
            : 0;
    return levelValue.clamp(0, 1).toDouble();
  }

  double levelBoost() {
    return levelController.value * 0.32;
  }

  Color targetColor() {
    if (widget.assistantSpeaking) return AppColors.green6A;
    if (widget.userSpeaking) return AppColors.blueD3;
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
    levelController.dispose();
    transitionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: Listenable.merge(
          [orbController, shimmerController, levelController, transitionController]),
      builder: (context, child) {
        final levelValue = levelController.value;
        final boostValue = levelBoost();
        final transitionValue = Curves.easeOutCubic.transform(transitionController.value);
        final scaleValue =
            pulseAnimation.value + (boostValue * 0.42) + ((1 - transitionValue) * 0.035);
        final colorValue = targetColor();
        final glowValue = 22 + (boostValue * 46);
        final shimmerShift = (shimmerController.value * 2) - 1;
        return SizedBox(
            width: widget.size * 1.45,
            height: widget.size * 1.45,
            child: Stack(alignment: Alignment.center, children: [
              Positioned.fill(
                  child: CustomPaint(
                      painter: _VoiceOrbAuraPainter(
                          color: colorValue,
                          progress: orbController.value,
                          shimmerProgress: shimmerController.value,
                          level: levelValue,
                          transitionProgress: transitionValue,
                          voiceUiState: widget.voiceUiState,
                          assistantSpeaking: widget.assistantSpeaking,
                          userSpeaking: widget.userSpeaking))),
              Transform.scale(
                  scale: scaleValue,
                  child: AnimatedContainer(
                      duration: const Duration(milliseconds: 420),
                      curve: Curves.easeInOut,
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient:
                              RadialGradient(center: Alignment(shimmerShift * 0.3, -0.24), colors: [
                            colorValue.withValues(alpha: 1),
                            colorValue.withValues(alpha: 0.48),
                            colorValue.withValues(alpha: 0.12)
                          ], stops: const [
                            0.12,
                            0.62,
                            1
                          ]),
                          border:
                              Border.all(color: AppColors.white.withValues(alpha: 0.1), width: 1.2),
                          boxShadow: [
                            BoxShadow(
                                color: colorValue.withValues(alpha: 0.5),
                                blurRadius: glowValue,
                                spreadRadius: 5),
                            BoxShadow(
                                color: AppColors.black.withValues(alpha: 0.22),
                                blurRadius: 18,
                                offset: const Offset(0, 10))
                          ]),
                      child: CustomPaint(
                          painter: _VoiceOrbForegroundPainter(
                              color: AppColors.white,
                              accentColor: colorValue,
                              progress: shimmerController.value,
                              level: levelValue,
                              transitionProgress: transitionValue,
                              voiceUiState: widget.voiceUiState,
                              assistantSpeaking: widget.assistantSpeaking,
                              userSpeaking: widget.userSpeaking))))
            ]));
      });
}

class _VoiceOrbAuraPainter extends CustomPainter {
  final Color color;
  final double progress;
  final double shimmerProgress;
  final double level;
  final double transitionProgress;
  final VoiceUiState voiceUiState;
  final bool assistantSpeaking;
  final bool userSpeaking;

  const _VoiceOrbAuraPainter(
      {required this.color,
      required this.progress,
      required this.shimmerProgress,
      required this.level,
      required this.transitionProgress,
      required this.voiceUiState,
      required this.assistantSpeaking,
      required this.userSpeaking});

  bool get isActive =>
      assistantSpeaking ||
      userSpeaking ||
      voiceUiState == VoiceUiState.thinking ||
      voiceUiState == VoiceUiState.speaking ||
      voiceUiState == VoiceUiState.connecting;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final baseRadius = size.shortestSide * 0.32;
    final pulse = Curves.easeInOut.transform(progress);
    final rippleCount = isActive ? 3 : 2;
    final voiceLevel = level.clamp(0.0, 1.0);

    for (var index = 0; index < rippleCount; index++) {
      final rippleProgress = (shimmerProgress + index / rippleCount) % 1;
      final radius = baseRadius +
          (rippleProgress * size.shortestSide * (isActive ? 0.17 + voiceLevel * 0.07 : 0.08));
      final alpha = (1 - rippleProgress) * (isActive ? 0.18 + voiceLevel * 0.1 : 0.08);
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 + (voiceLevel * 5.2)
        ..color = color.withValues(alpha: alpha.clamp(0.02, 0.22));
      canvas.drawCircle(center, radius, paint);
    }

    final glowPaint = Paint()
      ..shader = RadialGradient(colors: [
        color.withValues(alpha: 0.2 + (voiceLevel * 0.22)),
        color.withValues(alpha: 0.04 + (pulse * 0.04)),
        AppColors.transparent
      ]).createShader(Rect.fromCircle(center: center, radius: size.shortestSide * 0.46));
    canvas.drawCircle(center, size.shortestSide * 0.46, glowPaint);

    _drawRotatingArcs(canvas, center, baseRadius, voiceLevel);
    _drawStateBurst(canvas, center, baseRadius);
    _drawOrbitingParticles(canvas, center, baseRadius, voiceLevel);

    if (voiceUiState != VoiceUiState.thinking && voiceUiState != VoiceUiState.connecting) return;
    final dotPaint = Paint()..color = AppColors.white.withValues(alpha: 0.58);
    for (var index = 0; index < 6; index++) {
      final angle = (math.pi * 2 * shimmerProgress) + (math.pi * 2 * index / 6);
      final dotCenter = center + Offset(math.cos(angle), math.sin(angle)) * (baseRadius * 0.84);
      final dotAlpha = 0.24 + (0.42 * (1 - index / 6));
      dotPaint.color = AppColors.white.withValues(alpha: dotAlpha);
      canvas.drawCircle(dotCenter, 2.2, dotPaint);
    }
  }

  void _drawRotatingArcs(Canvas canvas, Offset center, double baseRadius, double voiceLevel) {
    final rect = Rect.fromCircle(center: center, radius: baseRadius * (1.12 + voiceLevel * 0.12));
    final arcPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6 + voiceLevel * 1.6
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: isActive ? 0.32 : 0.16);
    final start = shimmerProgress * math.pi * 2;
    canvas.drawArc(rect, start, math.pi * (0.18 + voiceLevel * 0.12), false, arcPaint);
    canvas.drawArc(rect, start + math.pi * 1.18, math.pi * 0.16, false, arcPaint);
  }

  void _drawStateBurst(Canvas canvas, Offset center, double baseRadius) {
    if (transitionProgress >= 1) return;
    final inverse = 1 - transitionProgress;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 + inverse * 2.4
      ..color = color.withValues(alpha: inverse * 0.24);
    canvas.drawCircle(center, baseRadius * (1.05 + transitionProgress * 0.5), paint);
  }

  void _drawOrbitingParticles(Canvas canvas, Offset center, double baseRadius, double voiceLevel) {
    if (!isActive && voiceLevel == 0) return;
    final particlePaint = Paint();
    final particleCount = assistantSpeaking || userSpeaking ? 8 : 5;
    for (var index = 0; index < particleCount; index++) {
      final phase = shimmerProgress + index / particleCount;
      final angle = phase * math.pi * 2;
      final radius = baseRadius * (1.28 + (index % 2) * 0.08 + voiceLevel * 0.12);
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      particlePaint.color = AppColors.white.withValues(alpha: 0.08 + voiceLevel * 0.18);
      canvas.drawCircle(point, 1.3 + voiceLevel * 1.8, particlePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceOrbAuraPainter oldDelegate) =>
      color != oldDelegate.color ||
      progress != oldDelegate.progress ||
      shimmerProgress != oldDelegate.shimmerProgress ||
      level != oldDelegate.level ||
      transitionProgress != oldDelegate.transitionProgress ||
      voiceUiState != oldDelegate.voiceUiState ||
      assistantSpeaking != oldDelegate.assistantSpeaking ||
      userSpeaking != oldDelegate.userSpeaking;
}

class _VoiceOrbForegroundPainter extends CustomPainter {
  final Color color;
  final Color accentColor;
  final double progress;
  final double level;
  final double transitionProgress;
  final VoiceUiState voiceUiState;
  final bool assistantSpeaking;
  final bool userSpeaking;

  const _VoiceOrbForegroundPainter(
      {required this.color,
      required this.accentColor,
      required this.progress,
      required this.level,
      required this.transitionProgress,
      required this.voiceUiState,
      required this.assistantSpeaking,
      required this.userSpeaking});

  bool get shouldPaintWave =>
      assistantSpeaking || userSpeaking || voiceUiState == VoiceUiState.speaking;

  @override
  void paint(Canvas canvas, Size size) {
    if (!shouldPaintWave) return;
    final center = size.center(Offset.zero);
    final barPaint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 4.2
      ..color = color.withValues(alpha: 0.78);
    final activeLevel = (level * 1.7).clamp(0.18, 1.0);
    const barCount = 5;
    const spacing = 10.0;
    for (var index = 0; index < barCount; index++) {
      final phase = (progress + index * 0.13) % 1;
      final wave = 0.45 + (math.sin(phase * math.pi * 2).abs() * 0.55);
      final height = 10 + (wave * activeLevel * 34);
      final x = center.dx + ((index - 2) * spacing);
      canvas.drawLine(
          Offset(x, center.dy - height / 2), Offset(x, center.dy + height / 2), barPaint);
    }

    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = accentColor.withValues(alpha: 0.38);
    canvas.drawCircle(center, size.shortestSide * (0.35 + activeLevel * 0.04), ringPaint);

    if (transitionProgress < 1) {
      final flashPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = color.withValues(alpha: (1 - transitionProgress) * 0.34);
      canvas.drawCircle(center, size.shortestSide * (0.22 + transitionProgress * 0.12), flashPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VoiceOrbForegroundPainter oldDelegate) =>
      color != oldDelegate.color ||
      accentColor != oldDelegate.accentColor ||
      progress != oldDelegate.progress ||
      level != oldDelegate.level ||
      transitionProgress != oldDelegate.transitionProgress ||
      voiceUiState != oldDelegate.voiceUiState ||
      assistantSpeaking != oldDelegate.assistantSpeaking ||
      userSpeaking != oldDelegate.userSpeaking;
}
