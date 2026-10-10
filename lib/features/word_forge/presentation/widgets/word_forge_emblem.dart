import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/wf_theme.dart';

/// Word Forge crest for host menus: an open spellbook with a rising rune.
class WordForgeEmblem extends StatelessWidget {
  final double size;

  const WordForgeEmblem({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _EmblemPainter()),
      );
}

class _EmblemPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(s * 0.24));
    canvas.drawRRect(
      rrect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2B2466), WfColors.night],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(s * 0.5, s * 0.42),
      s * 0.42,
      Paint()
        ..shader = RadialGradient(colors: [WfColors.gold.withValues(alpha: 0.45), Colors.transparent])
            .createShader(Rect.fromCircle(center: Offset(s * 0.5, s * 0.42), radius: s * 0.42)),
    );
    // Open book.
    final page = Paint()..color = const Color(0xFFF6E7C1);
    final left = Path()
      ..moveTo(s * 0.5, s * 0.62)
      ..quadraticBezierTo(s * 0.34, s * 0.55, s * 0.16, s * 0.6)
      ..lineTo(s * 0.16, s * 0.78)
      ..quadraticBezierTo(s * 0.34, s * 0.73, s * 0.5, s * 0.8)
      ..close();
    final right = Path()
      ..moveTo(s * 0.5, s * 0.62)
      ..quadraticBezierTo(s * 0.66, s * 0.55, s * 0.84, s * 0.6)
      ..lineTo(s * 0.84, s * 0.78)
      ..quadraticBezierTo(s * 0.66, s * 0.73, s * 0.5, s * 0.8)
      ..close();
    canvas.drawPath(left, page);
    canvas.drawPath(right, Paint()..color = const Color(0xFFE9D4A2));
    canvas.drawLine(Offset(s * 0.5, s * 0.62), Offset(s * 0.5, s * 0.8),
        Paint()
          ..color = WfColors.goldDeep
          ..strokeWidth = s * 0.02);
    // Rune diamond rising from the pages.
    final rune = Path()
      ..moveTo(s * 0.5, s * 0.14)
      ..lineTo(s * 0.62, s * 0.34)
      ..lineTo(s * 0.5, s * 0.54)
      ..lineTo(s * 0.38, s * 0.34)
      ..close();
    canvas.drawPath(rune, Paint()..color = WfColors.arcane.withValues(alpha: 0.35)..maskFilter = MaskFilter.blur(BlurStyle.normal, s * 0.06));
    canvas.drawPath(rune, Paint()..color = WfColors.arcane);
    canvas.drawPath(
      rune,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = s * 0.02
        ..color = Colors.white.withValues(alpha: 0.8),
    );
    // Sparks.
    final spark = Paint()..color = WfColors.gold;
    for (var i = 0; i < 3; i++) {
      final angle = -math.pi / 2 + (i - 1) * 0.9;
      canvas.drawCircle(Offset(s * 0.5 + math.cos(angle) * s * 0.3, s * 0.36 + math.sin(angle) * s * 0.24), s * 0.025, spark);
    }
  }

  @override
  bool shouldRepaint(_EmblemPainter oldDelegate) => false;
}
