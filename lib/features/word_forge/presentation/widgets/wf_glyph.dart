import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/content/region_definition.dart';
import '../../domain/progression/buffs.dart';
import '../../domain/progression/upgrades.dart';

/// Word Forge's own line-icon set, drawn on a 24×24 grid so every icon shares
/// stroke weight and style. Replace with final artwork by swapping [WfGlyph].
enum WfGlyphType {
  battle,
  elite,
  challenge,
  bonus,
  recovery,
  miniBoss,
  boss,
  mystery,
  lock,
  check,
  star,
  hint,
  reveal,
  timeFreeze,
  extraTime,
  secondChance,
  runeSense,
  ward,
  book,
  skills,
  back,
  forward,
  sound,
  soundOff,
  pause,
  undo,
  clear,
  bolt,
  heart,
  flame,
  close,
  sparkle;

  static WfGlyphType forNode(MapNodeType type) => switch (type) {
        MapNodeType.battle => battle,
        MapNodeType.elite => elite,
        MapNodeType.challenge => challenge,
        MapNodeType.bonus => bonus,
        MapNodeType.recovery => recovery,
        MapNodeType.miniBoss => miniBoss,
        MapNodeType.boss => boss,
        MapNodeType.mystery => mystery,
      };

  static WfGlyphType forBuff(BuffType type) => switch (type) {
        BuffType.hint => hint,
        BuffType.reveal => reveal,
        BuffType.timeFreeze => timeFreeze,
        BuffType.extraTime => extraTime,
        BuffType.secondChance => secondChance,
        BuffType.runeSense => runeSense,
        BuffType.shield => ward,
      };

  static WfGlyphType forUpgrade(UpgradeType type) => switch (type) {
        UpgradeType.focus => challenge,
        UpgradeType.insight => hint,
        UpgradeType.protection => ward,
        UpgradeType.momentum => flame,
      };
}

class WfGlyph extends StatelessWidget {
  final WfGlyphType type;
  final double size;
  final Color color;

  const WfGlyph(this.type, {super.key, this.size = 24, this.color = Colors.white});

  @override
  Widget build(BuildContext context) => SizedBox.square(
        dimension: size,
        child: CustomPaint(painter: _GlyphPainter(type, color)),
      );
}

class _GlyphPainter extends CustomPainter {
  final WfGlyphType type;
  final Color color;

  _GlyphPainter(this.type, this.color);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final fill = Paint()..color = color;
    void line(double x1, double y1, double x2, double y2) =>
        canvas.drawLine(Offset(x1, y1), Offset(x2, y2), stroke);
    Path poly(List<double> points, {bool close = false}) {
      final path = Path()..moveTo(points[0], points[1]);
      for (var i = 2; i < points.length; i += 2) {
        path.lineTo(points[i], points[i + 1]);
      }
      if (close) path.close();
      return path;
    }

    switch (type) {
      case WfGlyphType.battle:
        line(5, 19, 17.5, 6.5);
        line(19, 19, 6.5, 6.5);
        canvas.drawPath(poly([17.5, 6.5, 19.5, 4.5, 18.8, 7.2], close: true), fill);
        canvas.drawPath(poly([6.5, 6.5, 4.5, 4.5, 5.2, 7.2], close: true), fill);
        line(6, 14.5, 9.5, 18);
        line(14.5, 18, 18, 14.5);
      case WfGlyphType.elite:
        line(12, 3.5, 12, 16);
        line(8, 16, 16, 16);
        line(12, 16, 12, 20.5);
        canvas.drawPath(poly([4, 8, 8, 11, 4, 14]), stroke);
        canvas.drawPath(poly([20, 8, 16, 11, 20, 14]), stroke);
      case WfGlyphType.challenge:
        line(6, 3.5, 18, 3.5);
        line(6, 20.5, 18, 20.5);
        canvas.drawPath(poly([7, 3.5, 12, 11, 17, 3.5]), stroke);
        canvas.drawPath(poly([7, 20.5, 12, 13, 17, 20.5]), stroke);
        canvas.drawPath(poly([9.5, 20, 12, 16.5, 14.5, 20], close: true), fill);
      case WfGlyphType.bonus:
        canvas.drawRRect(RRect.fromLTRBR(4, 10, 20, 20, const Radius.circular(2)), stroke);
        canvas.drawPath(
            Path()
              ..moveTo(4, 10)
              ..quadraticBezierTo(12, 2, 20, 10),
            stroke);
        line(4, 13, 20, 13);
        canvas.drawRect(const Rect.fromLTWH(10.5, 12, 3, 3.5), fill);
      case WfGlyphType.recovery:
        canvas.drawPath(
            Path()
              ..moveTo(12, 3.5)
              ..cubicTo(17, 8, 16.5, 12, 15.5, 14)
              ..quadraticBezierTo(12, 17.5, 8.5, 14)
              ..cubicTo(7.5, 11.5, 9, 9.5, 10, 8.5)
              ..quadraticBezierTo(10.5, 11, 12, 11.5)
              ..quadraticBezierTo(12.5, 7.5, 12, 3.5),
            fill);
        line(5, 20, 19, 16.5);
        line(5, 16.5, 19, 20);
      case WfGlyphType.miniBoss:
        canvas.drawPath(
            Path()
              ..moveTo(6, 19)
              ..lineTo(6, 12)
              ..quadraticBezierTo(12, 3.5, 18, 12)
              ..lineTo(18, 19)
              ..close(),
            stroke);
        line(8.5, 13, 15.5, 13);
        canvas.drawPath(poly([6.5, 10, 3.5, 5, 4, 10.5]), stroke);
        canvas.drawPath(poly([17.5, 10, 20.5, 5, 20, 10.5]), stroke);
        line(12, 13, 12, 18);
      case WfGlyphType.boss:
        canvas.drawPath(poly([4, 17, 4, 7, 8.5, 11.5, 12, 5, 15.5, 11.5, 20, 7, 20, 17], close: true), stroke);
        line(4, 20.5, 20, 20.5);
        canvas.drawCircle(const Offset(12, 13.5), 1.6, fill);
      case WfGlyphType.mystery:
        canvas.drawPath(poly([12, 2.5, 21.5, 12, 12, 21.5, 2.5, 12], close: true), stroke);
        canvas.drawPath(
            Path()
              ..moveTo(9.5, 9.5)
              ..quadraticBezierTo(9.5, 7, 12, 7)
              ..quadraticBezierTo(14.5, 7, 14.5, 9.5)
              ..quadraticBezierTo(14.5, 11, 12, 12.5)
              ..lineTo(12, 13.5),
            stroke);
        canvas.drawCircle(const Offset(12, 16.5), 1.2, fill);
      case WfGlyphType.lock:
        canvas.drawRRect(RRect.fromLTRBR(5, 10.5, 19, 20.5, const Radius.circular(2.5)), fill);
        canvas.drawPath(
            Path()
              ..moveTo(8, 10.5)
              ..lineTo(8, 8)
              ..arcToPoint(const Offset(16, 8), radius: const Radius.circular(4))
              ..lineTo(16, 10.5),
            stroke);
      case WfGlyphType.check:
        canvas.drawPath(poly([5, 12.5, 10, 17.5, 19.5, 6.5]), stroke..strokeWidth = 3);
      case WfGlyphType.star:
        canvas.drawPath(_starPath(12, 12.5, 10, 4.2), fill);
      case WfGlyphType.hint:
        canvas.drawPath(
            Path()
              ..moveTo(9, 16)
              ..cubicTo(9, 13.5, 6, 12.5, 6, 9)
              ..arcToPoint(const Offset(18, 9), radius: const Radius.circular(6))
              ..cubicTo(18, 12.5, 15, 13.5, 15, 16)
              ..close(),
            stroke);
        line(9.5, 19, 14.5, 19);
        line(10.5, 21.5, 13.5, 21.5);
      case WfGlyphType.reveal:
        canvas.drawCircle(const Offset(10.5, 10.5), 6, stroke);
        line(15, 15, 20.5, 20.5);
        canvas.drawPath(poly([8.3, 13, 10.5, 7.5, 12.7, 13]), stroke..strokeWidth = 1.6);
      case WfGlyphType.timeFreeze:
        for (var i = 0; i < 3; i++) {
          final angle = i * math.pi / 3;
          final dx = math.cos(angle) * 9;
          final dy = math.sin(angle) * 9;
          line(12 - dx, 12 - dy, 12 + dx, 12 + dy);
        }
        for (var i = 0; i < 6; i++) {
          final angle = i * math.pi / 3;
          final tip = Offset(12 + math.cos(angle) * 6, 12 + math.sin(angle) * 6);
          final left = Offset(12 + math.cos(angle - 0.5) * 8.5, 12 + math.sin(angle - 0.5) * 8.5);
          final right = Offset(12 + math.cos(angle + 0.5) * 8.5, 12 + math.sin(angle + 0.5) * 8.5);
          canvas.drawLine(tip, left, stroke..strokeWidth = 1.5);
          canvas.drawLine(tip, right, stroke);
        }
      case WfGlyphType.extraTime:
        canvas.drawCircle(const Offset(11, 13), 7.5, stroke);
        line(11, 13, 11, 9);
        line(11, 13, 14, 14.5);
        line(19, 2.5, 19, 7.5);
        line(16.5, 5, 21.5, 5);
      case WfGlyphType.secondChance:
        canvas.drawArc(Rect.fromCircle(center: const Offset(12, 12.5), radius: 7.5), -math.pi * 0.35,
            math.pi * 1.7, false, stroke);
        canvas.drawPath(poly([16.5, 2.5, 18.5, 6.8, 13.8, 7.3], close: true), fill);
      case WfGlyphType.runeSense:
        canvas.drawPath(poly([12, 2.5, 19, 9, 12, 21.5, 5, 9], close: true), stroke);
        line(5, 9, 19, 9);
        line(12, 2.5, 12, 21.5);
      case WfGlyphType.ward:
        canvas.drawPath(
            Path()
              ..moveTo(12, 2.5)
              ..lineTo(19.5, 5.5)
              ..cubicTo(19.5, 13, 16.5, 18.5, 12, 21.5)
              ..cubicTo(7.5, 18.5, 4.5, 13, 4.5, 5.5)
              ..close(),
            stroke);
        canvas.drawPath(poly([8.5, 12, 11, 14.5, 15.5, 9.5]), stroke);
      case WfGlyphType.book:
        canvas.drawPath(
            Path()
              ..moveTo(12, 6.5)
              ..quadraticBezierTo(8, 4, 3, 5)
              ..lineTo(3, 18.5)
              ..quadraticBezierTo(8, 17.5, 12, 20)
              ..quadraticBezierTo(16, 17.5, 21, 18.5)
              ..lineTo(21, 5)
              ..quadraticBezierTo(16, 4, 12, 6.5)
              ..close(),
            stroke);
        line(12, 6.5, 12, 20);
      case WfGlyphType.skills:
      case WfGlyphType.sparkle:
        canvas.drawPath(_starPath(10, 13, 7.5, 2, points: 4), fill);
        canvas.drawPath(_starPath(18.5, 5.5, 3.5, 1, points: 4), fill);
      case WfGlyphType.back:
        canvas.drawPath(poly([15, 4.5, 7.5, 12, 15, 19.5]), stroke..strokeWidth = 2.6);
      case WfGlyphType.forward:
        canvas.drawPath(poly([9, 4.5, 16.5, 12, 9, 19.5]), stroke..strokeWidth = 2.6);
      case WfGlyphType.sound:
      case WfGlyphType.soundOff:
        canvas.drawPath(poly([3.5, 9, 7.5, 9, 12.5, 4.5, 12.5, 19.5, 7.5, 15, 3.5, 15], close: true), fill);
        if (type == WfGlyphType.sound) {
          canvas.drawArc(Rect.fromCircle(center: const Offset(13, 12), radius: 4.5), -0.9, 1.8, false, stroke);
          canvas.drawArc(Rect.fromCircle(center: const Offset(13, 12), radius: 8), -0.9, 1.8, false, stroke);
        } else {
          line(16, 9, 21, 15);
          line(21, 9, 16, 15);
        }
      case WfGlyphType.pause:
        canvas.drawRRect(RRect.fromLTRBR(6.5, 4.5, 10, 19.5, const Radius.circular(1.5)), fill);
        canvas.drawRRect(RRect.fromLTRBR(14, 4.5, 17.5, 19.5, const Radius.circular(1.5)), fill);
      case WfGlyphType.undo:
        canvas.drawPath(
            Path()
              ..moveTo(8, 9)
              ..lineTo(15, 9)
              ..arcToPoint(const Offset(15, 19), radius: const Radius.circular(5))
              ..lineTo(9, 19),
            stroke);
        canvas.drawPath(poly([11, 5, 7, 9, 11, 13]), stroke);
      case WfGlyphType.clear:
      case WfGlyphType.close:
        line(6, 6, 18, 18);
        line(18, 6, 6, 18);
      case WfGlyphType.bolt:
        canvas.drawPath(poly([13.5, 2, 5, 13.5, 11, 13.5, 9.5, 22, 19, 9.5, 13, 9.5], close: true), fill);
      case WfGlyphType.heart:
        canvas.drawPath(
            Path()
              ..moveTo(12, 20.5)
              ..cubicTo(3, 14, 2.5, 8.5, 5.5, 5.8)
              ..cubicTo(8, 3.6, 11, 4.8, 12, 7.3)
              ..cubicTo(13, 4.8, 16, 3.6, 18.5, 5.8)
              ..cubicTo(21.5, 8.5, 21, 14, 12, 20.5)
              ..close(),
            fill);
      case WfGlyphType.flame:
        canvas.drawPath(
            Path()
              ..moveTo(12, 2)
              ..cubicTo(19, 8, 19.5, 13.5, 17.5, 17)
              ..quadraticBezierTo(12, 23.5, 6.5, 17)
              ..cubicTo(4.5, 13.5, 6.5, 10, 8.5, 8.5)
              ..quadraticBezierTo(9, 12, 11, 12.5)
              ..quadraticBezierTo(12.8, 7, 12, 2)
              ..close(),
            fill);
    }
  }

  Path _starPath(double cx, double cy, double outer, double inner, {int points = 5}) {
    final path = Path();
    for (var i = 0; i < points * 2; i++) {
      final radius = i.isEven ? outer : inner;
      final angle = -math.pi / 2 + i * math.pi / points;
      final point = Offset(cx + math.cos(angle) * radius, cy + math.sin(angle) * radius);
      i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_GlyphPainter oldDelegate) => oldDelegate.type != type || oldDelegate.color != color;
}
