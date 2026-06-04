import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class AskAiMicrophoneButton extends StatefulWidget {
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
  State<AskAiMicrophoneButton> createState() => AskAiMicrophoneButtonState();
}

class AskAiMicrophoneButtonState extends State<AskAiMicrophoneButton>
    with SingleTickerProviderStateMixin {
  static const double buttonSize = 72;
  static const double wavePadding = 6;
  static const double labelSpacing = 6;
  static const double bottomPadding = 8;

  late final AnimationController waveController;
  bool isPressed = false;

  bool get isDisabled => widget.onTap == null || widget.isConnecting;

  void setPressed(bool value) {
    if (isDisabled || isPressed == value) return;
    setState(() => isPressed = value);
  }

  @override
  void initState() {
    super.initState();
    waveController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700));
    updateWaveController();
  }

  @override
  void didUpdateWidget(covariant AskAiMicrophoneButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isRecording != widget.isRecording ||
        oldWidget.isConnecting != widget.isConnecting) {
      updateWaveController();
    }
  }

  void updateWaveController() {
    if (widget.isRecording && !widget.isConnecting) {
      if (!waveController.isAnimating) waveController.repeat();
      return;
    }
    if (waveController.isAnimating) waveController.stop();
    waveController.value = 0;
  }

  @override
  void dispose() {
    waveController.dispose();
    super.dispose();
  }

  Widget microphoneButton(
          {required Color buttonColor, required Color backgroundColor, required IconData icon}) =>
      SizedBox(
          width: buttonSize + wavePadding * 2,
          height: buttonSize + wavePadding * 2,
          child: AnimatedBuilder(
              animation: waveController,
              builder: (context, child) {
                final breath = widget.isRecording
                    ? 1 + (math.sin(waveController.value * math.pi * 2) * 0.025)
                    : 1.0;
                return CustomPaint(
                    painter: _MicrophoneWavePainter(
                        progress: waveController.value,
                        color: backgroundColor,
                        isRecording: widget.isRecording),
                    child: Padding(
                        padding: const EdgeInsets.all(wavePadding),
                        child: AnimatedScale(
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOutCubic,
                            scale: (isPressed ? 0.94 : 1) * breath,
                            child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                curve: Curves.easeOutCubic,
                                width: buttonSize,
                                height: buttonSize,
                                decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          buttonColor.withValues(alpha: 0.98),
                                          buttonColor.withValues(alpha: 0.72)
                                        ]),
                                    border: Border.all(
                                        color: AppColors.white
                                            .withValues(alpha: widget.isRecording ? 0.2 : 0.12)),
                                    boxShadow: [
                                      BoxShadow(
                                          color: backgroundColor.withValues(
                                              alpha: widget.isRecording ? 0.44 : 0.28),
                                          blurRadius: widget.isRecording ? 34 : 22,
                                          spreadRadius: widget.isRecording ? 5 : 2),
                                      BoxShadow(
                                          color: AppColors.black.withValues(alpha: 0.22),
                                          blurRadius: 18,
                                          offset: const Offset(0, 10))
                                    ]),
                                child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 180),
                                    transitionBuilder: (child, animation) =>
                                        ScaleTransition(scale: animation, child: child),
                                    child: Icon(icon,
                                        key: ValueKey(icon), color: AppColors.white, size: 34))))));
              }));

  @override
  Widget build(BuildContext context) {
    final backgroundColor = widget.isRecording ? AppColors.error : AppColors.primary;
    final icon = widget.isRecording ? Icons.stop_rounded : Icons.mic_rounded;
    final buttonColor = widget.isConnecting || isDisabled ? AppColors.gray500 : backgroundColor;

    return SafeArea(
        top: false,
        child: Padding(
            padding: const EdgeInsets.only(bottom: bottomPadding),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              GestureDetector(
                  onTap: isDisabled ? null : widget.onTap,
                  onTapDown: (_) => setPressed(true),
                  onTapCancel: () => setPressed(false),
                  onTapUp: (_) => setPressed(false),
                  child: microphoneButton(
                      buttonColor: buttonColor, backgroundColor: backgroundColor, icon: icon)),
              const SizedBox(height: labelSpacing),
              AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(widget.labelText,
                      key: ValueKey(widget.labelText),
                      style: Style.small3w5(context, color: TextColorRole.whiteColor)))
            ])));
  }
}

class _MicrophoneWavePainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isRecording;

  const _MicrophoneWavePainter(
      {required this.progress, required this.color, required this.isRecording});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isRecording) return;
    final center = size.center(Offset.zero);
    final baseRadius = size.shortestSide * 0.34;
    for (var index = 0; index < 3; index++) {
      final waveProgress = (progress + index / 3) % 1;
      final radius = baseRadius + waveProgress * size.shortestSide * 0.22;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2 + (1 - waveProgress) * 1.8
        ..color = color.withValues(alpha: (1 - waveProgress) * 0.24);
      canvas.drawCircle(center, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MicrophoneWavePainter oldDelegate) =>
      progress != oldDelegate.progress ||
      color != oldDelegate.color ||
      isRecording != oldDelegate.isRecording;
}
