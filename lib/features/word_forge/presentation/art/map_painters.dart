import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/content/region_definition.dart';
import '../../domain/progression/map_rules.dart';
import '../theme/wf_theme.dart';

/// Top-down terrain for a region map: themed ground with scattered props kept
/// away from the central travel corridor so nodes stay readable.
class MapTerrainPainter extends CustomPainter {
  final RegionTheme theme;
  final RegionPalette palette;

  MapTerrainPainter(this.theme) : palette = RegionPalette.of(theme);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            Color.lerp(palette.ground, palette.skyBottom, 0.25)!,
            palette.ground,
            Color.lerp(palette.near, Colors.black, 0.35)!,
          ],
        ).createShader(rect),
    );

    final random = math.Random(theme.index * 31 + 5);
    // Fine ground texture (grass tufts / pebbles / dust).
    final speck = Paint()..color = palette.accent.withValues(alpha: 0.06);
    for (var i = 0; i < size.height / 6; i++) {
      canvas.drawCircle(Offset(random.nextDouble() * size.width, random.nextDouble() * size.height),
          1 + random.nextDouble() * 2, speck);
    }
    final props = (size.height / 34).round();
    for (var i = 0; i < props; i++) {
      final side = random.nextBool() ? 1 : -1;
      final x = size.width / 2 + side * size.width * (0.36 + random.nextDouble() * 0.2);
      final y = random.nextDouble() * size.height;
      final scale = 0.7 + random.nextDouble() * 0.8;
      _prop(canvas, Offset(x, y), scale, random);
    }

    // Soft light pools along the corridor.
    for (var y = size.height - 60; y > 0; y -= 260) {
      canvas.drawCircle(
        Offset(size.width / 2, y),
        size.width * 0.45,
        Paint()
          ..shader = RadialGradient(colors: [palette.glow.withValues(alpha: 0.07), Colors.transparent])
              .createShader(Rect.fromCircle(center: Offset(size.width / 2, y), radius: size.width * 0.45)),
      );
    }
  }

  void _prop(Canvas canvas, Offset at, double scale, math.Random random) {
    final dark = Paint()..color = palette.near.withValues(alpha: 0.9);
    final mid = Paint()..color = palette.mid;
    switch (theme) {
      case RegionTheme.road:
        if (random.nextDouble() < 0.5) {
          // Round tree seen from above.
          canvas.drawCircle(at + const Offset(3, 4), 16 * scale, Paint()..color = Colors.black.withValues(alpha: 0.25));
          canvas.drawCircle(at, 16 * scale, Paint()..color = const Color(0xFF4F6136));
          canvas.drawCircle(at - Offset(4 * scale, 4 * scale), 8 * scale, Paint()..color = const Color(0xFF6E8448));
        } else {
          // Stones.
          canvas.drawOval(Rect.fromCenter(center: at, width: 18 * scale, height: 11 * scale), dark);
          canvas.drawOval(Rect.fromCenter(center: at + Offset(12 * scale, 5 * scale), width: 10 * scale, height: 7 * scale), mid);
        }
      case RegionTheme.forest:
        for (var k = 0; k < 3; k++) {
          final offset = Offset((k - 1) * 13.0 * scale, (k.isEven ? 0 : 7) * scale);
          canvas.drawCircle(at + offset + const Offset(3, 5), 17 * scale, Paint()..color = Colors.black.withValues(alpha: 0.3));
          canvas.drawCircle(at + offset, 17 * scale, k == 1 ? mid : dark);
        }
        if (random.nextDouble() < 0.35) {
          canvas.drawCircle(at + Offset(0, 26 * scale), 2.4, Paint()..color = palette.accent.withValues(alpha: 0.7));
        }
      case RegionTheme.ruins:
        if (random.nextDouble() < 0.5) {
          canvas.drawCircle(at, 13 * scale, dark);
          canvas.drawCircle(at, 9 * scale, mid);
          canvas.drawCircle(at, 9 * scale,
              Paint()
                ..style = PaintingStyle.stroke
                ..color = palette.accent.withValues(alpha: 0.25));
        } else {
          canvas.save();
          canvas.translate(at.dx, at.dy);
          canvas.rotate(random.nextDouble() * math.pi);
          canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset.zero, width: 34 * scale, height: 11 * scale),
              const Radius.circular(3)), dark);
          canvas.restore();
        }
    }
  }

  @override
  bool shouldRepaint(MapTerrainPainter oldDelegate) => oldDelegate.theme != theme;
}

class MapEdge {
  final Offset from;
  final Offset to;
  final NodeState fromState;
  final NodeState toState;

  const MapEdge({required this.from, required this.to, required this.fromState, required this.toState});

  bool get travelled => fromState == NodeState.completed && toState == NodeState.completed;
  bool get open => fromState == NodeState.completed && toState == NodeState.available;
}

/// Curved trails between nodes. Open trails shimmer to show where to go next.
class MapPathPainter extends CustomPainter {
  final List<MapEdge> edges;
  final Animation<double> shimmer;
  final Color accent;

  MapPathPainter({required this.edges, required this.shimmer, required this.accent}) : super(repaint: shimmer);

  @override
  void paint(Canvas canvas, Size size) {
    for (final edge in edges) {
      final path = _curve(edge.from, edge.to);
      final shadow = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 11
        ..strokeCap = StrokeCap.round
        ..color = Colors.black.withValues(alpha: 0.28);
      canvas.drawPath(path, shadow);

      final color = edge.travelled
          ? WfColors.gold
          : edge.open
              ? accent
              : Colors.white.withValues(alpha: 0.18);
      final base = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = edge.travelled ? 5 : 4
        ..strokeCap = StrokeCap.round
        ..color = color.withValues(alpha: edge.travelled ? 0.85 : (edge.open ? 0.5 : 1));
      if (edge.travelled || edge.open) {
        canvas.drawPath(path, base);
      } else {
        _dashed(canvas, path, base, 7, 9, 0);
      }
      if (edge.open) {
        final glow = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round
          ..color = accent;
        _dashed(canvas, path, glow, 10, 14, shimmer.value * 24);
      }
    }
  }

  Path _curve(Offset a, Offset b) {
    final mid = (a.dy + b.dy) / 2;
    return Path()
      ..moveTo(a.dx, a.dy)
      ..cubicTo(a.dx, mid, b.dx, mid, b.dx, b.dy);
  }

  void _dashed(Canvas canvas, Path path, Paint paint, double dash, double gap, double phase) {
    for (final metric in path.computeMetrics()) {
      var distance = -phase % (dash + gap);
      while (distance < metric.length) {
        final start = distance.clamp(0.0, metric.length);
        final end = (distance + dash).clamp(0.0, metric.length);
        if (end > start) canvas.drawPath(metric.extractPath(start, end), paint);
        distance += dash + gap;
      }
    }
  }

  @override
  bool shouldRepaint(MapPathPainter oldDelegate) => oldDelegate.edges != edges;
}
