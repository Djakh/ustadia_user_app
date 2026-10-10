import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/content/region_definition.dart';
import '../theme/wf_theme.dart';

/// Layered, procedurally drawn fantasy landscape for a region. Used by the
/// adventure card and (through a Flame wrapper) as the battle backdrop.
///
/// Geometry is generated once per size and cached; each frame only moves
/// the layers (parallax sway) and twinkles particles, so repainting is cheap.
/// A future art pass can replace this with layered sprites per region.
class RegionBackdropPainter extends CustomPainter {
  final RegionTheme theme;
  final RegionPalette palette;

  /// Seconds; drives parallax sway and particles.
  double time;

  /// 0..1 fraction of the height where the ground begins.
  final double horizon;

  final bool animateParticles;

  RegionBackdropPainter({
    required this.theme,
    this.time = 0,
    this.horizon = 0.72,
    this.animateParticles = true,
  }) : palette = RegionPalette.of(theme);

  Size? _cachedSize;
  late Path _far;
  late Path _mid;
  late Path _near;
  late List<Offset> _stars;
  late List<_Mote> _motes;

  void _build(Size size) {
    _cachedSize = size;
    final random = math.Random(theme.index * 7919 + 3);
    final w = size.width;
    final h = size.height;
    final ground = h * horizon;

    // Far mountains.
    _far = Path()..moveTo(-40, ground);
    for (var x = -40.0; x <= w + 40; x += w / 7) {
      _far.lineTo(x, ground - h * (0.18 + random.nextDouble() * 0.16));
      _far.lineTo(x + w / 14, ground - h * (0.1 + random.nextDouble() * 0.1));
    }
    _far
      ..lineTo(w + 40, ground)
      ..close();

    // Mid layer, themed.
    _mid = Path();
    switch (theme) {
      case RegionTheme.road:
        _mid.moveTo(-40, ground);
        for (var x = -40.0; x <= w + 40; x += 24) {
          _mid.lineTo(x, ground - h * 0.07 - math.sin(x / w * math.pi * 2.3) * h * 0.035);
        }
        _mid
          ..lineTo(w + 40, ground)
          ..close();
        // Distant gate: two towers and an arch.
        final gx = w * 0.8;
        final top = ground - h * 0.3;
        _mid.addRect(Rect.fromLTRB(gx - w * 0.07, top, gx - w * 0.035, ground));
        _mid.addRect(Rect.fromLTRB(gx + w * 0.035, top, gx + w * 0.07, ground));
        _mid.addPath(
            Path()
              ..moveTo(gx - w * 0.035, top + h * 0.06)
              ..quadraticBezierTo(gx, top + h * 0.01, gx + w * 0.035, top + h * 0.06)
              ..lineTo(gx + w * 0.035, top + h * 0.09)
              ..lineTo(gx - w * 0.035, top + h * 0.09)
              ..close(),
            Offset.zero);
        for (final dx in [-0.07, -0.0525, 0.035, 0.0525]) {
          _mid.addRect(Rect.fromLTWH(gx + w * dx, top - h * 0.02, w * 0.011, h * 0.02));
        }
      case RegionTheme.forest:
        _mid.moveTo(-40, ground);
        _mid.lineTo(w + 40, ground);
        for (var x = -20.0; x < w + 20; x += w / 11) {
          final treeHeight = h * (0.2 + random.nextDouble() * 0.14);
          final treeWidth = w * (0.05 + random.nextDouble() * 0.03);
          final cx = x + random.nextDouble() * 10;
          for (var tier = 0; tier < 3; tier++) {
            final tierTop = ground - treeHeight + tier * treeHeight * 0.22;
            final tierBottom = ground - treeHeight * 0.18 - (2 - tier) * treeHeight * 0.18;
            final spread = treeWidth * (0.6 + tier * 0.25);
            _mid.addPath(
                Path()
                  ..moveTo(cx, tierTop)
                  ..lineTo(cx + spread, tierBottom)
                  ..lineTo(cx - spread, tierBottom)
                  ..close(),
                Offset.zero);
          }
          _mid.addRect(Rect.fromLTRB(cx - 2, ground - treeHeight * 0.2, cx + 2, ground));
        }
      case RegionTheme.ruins:
        _mid.moveTo(-40, ground);
        _mid.lineTo(w + 40, ground);
        for (var i = 0; i < 7; i++) {
          final cx = w * (0.05 + i * 0.15) + random.nextDouble() * 12;
          final columnHeight = h * (0.12 + random.nextDouble() * 0.2);
          final columnWidth = w * 0.035;
          final brokenTop = ground - columnHeight;
          _mid.addPath(
              Path()
                ..moveTo(cx - columnWidth / 2, ground)
                ..lineTo(cx - columnWidth / 2, brokenTop + 6)
                ..lineTo(cx - columnWidth * 0.1, brokenTop)
                ..lineTo(cx + columnWidth * 0.2, brokenTop + 8)
                ..lineTo(cx + columnWidth / 2, brokenTop + 3)
                ..lineTo(cx + columnWidth / 2, ground)
                ..close(),
              Offset.zero);
          _mid.addRect(Rect.fromLTRB(cx - columnWidth * 0.7, ground - 6, cx + columnWidth * 0.7, ground));
        }
        // A broken arch.
        final ax = w * 0.62;
        _mid.addPath(
            Path()
              ..moveTo(ax - w * 0.1, ground)
              ..lineTo(ax - w * 0.1, ground - h * 0.2)
              ..quadraticBezierTo(ax, ground - h * 0.34, ax + w * 0.06, ground - h * 0.25)
              ..lineTo(ax + w * 0.045, ground - h * 0.22)
              ..quadraticBezierTo(ax, ground - h * 0.28, ax - w * 0.065, ground - h * 0.18)
              ..lineTo(ax - w * 0.065, ground)
              ..close(),
            Offset.zero);
    }

    // Near ground band.
    _near = Path()
      ..moveTo(-40, ground)
      ..quadraticBezierTo(w * 0.5, ground - h * 0.025, w + 40, ground)
      ..lineTo(w + 40, h + 40)
      ..lineTo(-40, h + 40)
      ..close();

    _stars = List.generate(34, (_) => Offset(random.nextDouble() * w, random.nextDouble() * ground * 0.6));
    _motes = List.generate(18, (_) => _Mote(random));
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (_cachedSize != size) _build(size);
    final w = size.width;
    final h = size.height;
    final ground = h * horizon;
    final rect = Offset.zero & size;

    canvas.drawRect(
      rect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.skyTop, palette.skyBottom],
          stops: [0.0, horizon],
        ).createShader(rect),
    );

    final starPaint = Paint();
    for (var i = 0; i < _stars.length; i++) {
      final twinkle = 0.35 + 0.35 * math.sin(time * 1.3 + i * 1.7);
      starPaint.color = Colors.white.withValues(alpha: twinkle * (theme == RegionTheme.road ? 0.5 : 0.9));
      canvas.drawCircle(_stars[i], i.isEven ? 1.1 : 0.7, starPaint);
    }

    final celestial = switch (theme) {
      RegionTheme.road => Offset(w * 0.3, ground - h * 0.12),
      RegionTheme.forest => Offset(w * 0.24, h * 0.2),
      RegionTheme.ruins => Offset(w * 0.5, h * 0.24),
    };
    final glowRadius = w * (theme == RegionTheme.road ? 0.38 : 0.26);
    canvas.drawCircle(
      celestial,
      glowRadius,
      Paint()
        ..shader = RadialGradient(colors: [palette.glow.withValues(alpha: 0.45), palette.glow.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: celestial, radius: glowRadius)),
    );
    canvas.drawCircle(celestial, w * 0.045,
        Paint()..color = Color.lerp(palette.glow, Colors.white, 0.55)!.withValues(alpha: 0.9));
    if (theme == RegionTheme.ruins) {
      final ring = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2
        ..color = palette.accent.withValues(alpha: 0.25);
      canvas.save();
      canvas.translate(celestial.dx, celestial.dy);
      canvas.rotate(time * 0.05);
      canvas.drawCircle(Offset.zero, w * 0.11, ring);
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        canvas.drawLine(Offset(math.cos(angle) * w * 0.09, math.sin(angle) * w * 0.09),
            Offset(math.cos(angle) * w * 0.13, math.sin(angle) * w * 0.13), ring);
      }
      canvas.restore();
    }

    void layer(Path path, Color color, double sway) {
      canvas.save();
      canvas.translate(math.sin(time * 0.12) * sway, 0);
      canvas.drawPath(path, Paint()..color = color);
      canvas.restore();
    }

    layer(_far, palette.far, 3);
    canvas.drawRect(
      Rect.fromLTRB(0, ground - h * 0.16, w, ground + 4),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.glow.withValues(alpha: 0), palette.glow.withValues(alpha: 0.14)],
        ).createShader(Rect.fromLTRB(0, ground - h * 0.16, w, ground + 4)),
    );
    layer(_mid, palette.mid, 6);

    canvas.drawPath(
      _near,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.ground, palette.near],
        ).createShader(Rect.fromLTRB(0, ground - 10, w, h)),
    );
    if (theme == RegionTheme.road) {
      final road = Path()
        ..moveTo(w * 0.44, ground)
        ..lineTo(w * 0.56, ground)
        ..lineTo(w * 0.95, h)
        ..lineTo(w * 0.05, h)
        ..close();
      canvas.drawPath(road, Paint()..color = palette.glow.withValues(alpha: 0.08));
    } else if (theme == RegionTheme.ruins) {
      final tile = Paint()
        ..color = palette.accent.withValues(alpha: 0.07)
        ..strokeWidth = 1;
      for (var i = 1; i < 5; i++) {
        final y = ground + (h - ground) * (i / 5) * (i / 5);
        canvas.drawLine(Offset(0, y), Offset(w, y), tile);
      }
    }

    if (animateParticles) {
      final motePaint = Paint();
      for (final mote in _motes) {
        final progress = (mote.phase + time * mote.speed) % 1.0;
        final x = (mote.x * w + math.sin(time * mote.wobble + mote.phase * 6) * 18) % w;
        final y = switch (theme) {
          RegionTheme.forest => ground - h * 0.35 * mote.height + math.sin(time * 0.8 + mote.phase * 9) * 10,
          _ => h * (1 - progress) * 0.95,
        };
        final alpha = theme == RegionTheme.forest
            ? (0.3 + 0.7 * (0.5 + 0.5 * math.sin(time * 2 + mote.phase * 12)))
            : math.sin(progress * math.pi);
        motePaint.color = palette.accent.withValues(alpha: alpha * 0.55);
        canvas.drawCircle(Offset(x, y), mote.size, motePaint);
      }
    }

    // Vignette keeps the eye on the characters and words.
    canvas.drawRect(
      rect,
      Paint()
        ..shader = RadialGradient(
          radius: 0.9,
          colors: [Colors.transparent, Colors.black.withValues(alpha: 0.45)],
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(RegionBackdropPainter oldDelegate) => true;
}

class _Mote {
  final double x;
  final double phase;
  final double speed;
  final double wobble;
  final double size;
  final double height;

  _Mote(math.Random random)
      : x = random.nextDouble(),
        phase = random.nextDouble(),
        speed = 0.03 + random.nextDouble() * 0.05,
        wobble = 0.3 + random.nextDouble() * 0.7,
        size = 1 + random.nextDouble() * 1.8,
        height = random.nextDouble();
}

/// Static thumbnail of a region (menus), animated gently when [animate].
class RegionVignette extends StatefulWidget {
  final RegionTheme theme;
  final bool animate;

  const RegionVignette({super.key, required this.theme, this.animate = true});

  @override
  State<RegionVignette> createState() => _RegionVignetteState();
}

class _RegionVignetteState extends State<RegionVignette> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 60));
  late RegionBackdropPainter _painter = RegionBackdropPainter(theme: widget.theme, horizon: 0.78);

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void didUpdateWidget(RegionVignette oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.theme != widget.theme) {
      _painter = RegionBackdropPainter(theme: widget.theme, horizon: 0.78);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RepaintBoundary(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            _painter.time = _controller.value * 60;
            return CustomPaint(painter: _painter, size: Size.infinite);
          },
        ),
      );
}

/// Blur-free glow helper used by several painters.
void paintGlow(Canvas canvas, Offset center, double radius, Color color, {double strength = 0.5}) {
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..shader = RadialGradient(colors: [color.withValues(alpha: strength), color.withValues(alpha: 0)])
          .createShader(Rect.fromCircle(center: center, radius: radius))
      ..blendMode = BlendMode.plus,
  );
}
