import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';

class AskAiConversationContent extends StatelessWidget {
  final Widget messagesPanel;
  final Widget voiceAgentSection;
  final Widget bottomControl;

  const AskAiConversationContent(
      {super.key,
      required this.messagesPanel,
      required this.voiceAgentSection,
      required this.bottomControl});

  @override
  Widget build(BuildContext context) => Stack(children: [
        const Positioned.fill(child: _AskAiAnimatedBackground()),
        Positioned.fill(child: messagesPanel),
        Positioned(top: 8, left: 0, right: 0, child: voiceAgentSection),
        Positioned(left: 0, right: 0, bottom: 0, child: bottomControl)
      ]);
}

class _AskAiAnimatedBackground extends StatefulWidget {
  const _AskAiAnimatedBackground();

  @override
  State<_AskAiAnimatedBackground> createState() => _AskAiAnimatedBackgroundState();
}

class _AskAiAnimatedBackgroundState extends State<_AskAiAnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 12000))
      ..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: RepaintBoundary(
          child: AnimatedBuilder(
              animation: controller,
              builder: (context, child) => CustomPaint(
                  painter: _AskAiBackgroundPainter(progress: controller.value),
                  child: const SizedBox.expand()))));
}

class _AskAiBackgroundPainter extends CustomPainter {
  final double progress;

  const _AskAiBackgroundPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final backgroundPaint = Paint()
      ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.secondary, Color(0xFF0D1210), Color(0xFF07110D)],
          stops: [0, 0.58, 1]).createShader(rect);
    canvas.drawRect(rect, backgroundPaint);

    final drift = Curves.easeInOut.transform(progress < 0.5 ? progress * 2 : (1 - progress) * 2);
    _drawGlow(canvas, size, Offset(-54 + drift * 18, 72 + drift * 8), 220,
        AppColors.primary.withValues(alpha: 0.15));
    _drawGlow(canvas, size, Offset(size.width - 34 - drift * 14, 230 - drift * 12), 250,
        AppColors.green6A.withValues(alpha: 0.11));
    _drawGlow(canvas, size, Offset(size.width * 0.42, size.height + 30), 280,
        AppColors.primary.withValues(alpha: 0.075));

    final linePaint = Paint()
      ..shader = LinearGradient(colors: [
        AppColors.transparent,
        AppColors.white.withValues(alpha: 0.05),
        AppColors.transparent
      ]).createShader(Rect.fromLTWH(36, size.height - 84, size.width - 72, 1));
    canvas.drawRect(Rect.fromLTWH(36, size.height - 84, size.width - 72, 1), linePaint);

    final particlePaint = Paint()..color = AppColors.white.withValues(alpha: 0.05);
    for (var index = 0; index < 10; index++) {
      final x = ((index * 73.0) + progress * 22) % size.width;
      final y = 110 + ((index * 97.0) % (size.height * 0.72));
      final opacity = 0.02 + ((index % 3) * 0.012);
      particlePaint.color = AppColors.white.withValues(alpha: opacity);
      canvas.drawCircle(Offset(x, y), 1.2 + (index % 2), particlePaint);
    }
  }

  void _drawGlow(Canvas canvas, Size size, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader =
          RadialGradient(colors: [color, color.withValues(alpha: 0.035), AppColors.transparent])
              .createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  bool shouldRepaint(covariant _AskAiBackgroundPainter oldDelegate) =>
      progress != oldDelegate.progress;
}
