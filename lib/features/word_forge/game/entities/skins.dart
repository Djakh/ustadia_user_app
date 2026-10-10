import 'dart:math' as math;
import '../vfx/glow.dart';
import 'dart:ui';

import 'apprentice_skin.dart';
import 'entity.dart';

export 'apprentice_skin.dart';

/// Procedural development skins. Each is a silhouette-first illustration in
/// unit space (see [EntitySkin]); professional sprites can replace them via
/// `SpriteEntitySkin` without touching gameplay.
EntitySkin skinFor(String id) => switch (id) {
      'ogre' => const OgreSkin(),
      'goblin' => const GoblinSkin(),
      'golem' => const GolemSkin(),
      'mage' => const MageSkin(),
      'blob' => const BlobSkin(),
      'chest' => const ChestSkin(),
      'wisp' => const WispSkin(),
      'knight' => const KnightSkin(),
      'treant' => const TreantSkin(),
      'lich' => const LichSkin(),
      _ => const GoblinSkin(),
    };

Paint _fill(Color color) => Paint()..color = color;

Paint _glowPaint(Color color, double radius) => glowPaint(color, radius);

void _eye(Canvas canvas, Offset at, double r, Color color, EntityPose pose, {bool glow = true}) {
  if (glow) glowCircle(canvas, at, r * 2.4, color.withValues(alpha: 0.55 * pose.alpha), r * 1.6);
  canvas.drawCircle(at, r, _fill(color.withValues(alpha: pose.alpha)));
}

Color _darken(Color color, double amount) => Color.lerp(color, const Color(0xFF000000), amount)!;
Color _lighten(Color color, double amount) => Color.lerp(color, const Color(0xFFFFFFFF), amount)!;

// -----------------------------------------------------------------------------
// Enemies
// -----------------------------------------------------------------------------

class GoblinSkin extends EntitySkin {
  const GoblinSkin();

  @override
  Offset get castPoint => const Offset(0.28, -0.5);

  @override
  Offset get corePoint => const Offset(0, -0.42);

  @override
  void render(Canvas canvas, EntityPose pose, EntityPalette palette) {
    Color c(Color color) => palette.tint(color, pose);
    final skin = palette.primary;
    // Legs.
    canvas.drawRRect(RRect.fromLTRBR(-0.12, -0.18, -0.04, 0, const Radius.circular(0.03)), _fill(c(_darken(skin, 0.3))));
    canvas.drawRRect(RRect.fromLTRBR(0.04, -0.18, 0.12, 0, const Radius.circular(0.03)), _fill(c(_darken(skin, 0.3))));
    // Tunic.
    canvas.drawPath(
      Path()
        ..moveTo(-0.17, -0.14)
        ..lineTo(-0.13, -0.48)
        ..lineTo(0.13, -0.48)
        ..lineTo(0.17, -0.14)
        ..lineTo(0.08, -0.17)
        ..lineTo(0, -0.12)
        ..lineTo(-0.08, -0.17)
        ..close(),
      _fill(c(palette.secondary)),
    );
    canvas.drawRect(const Rect.fromLTRB(-0.14, -0.3, 0.14, -0.27), _fill(c(_darken(palette.secondary, 0.35))));
    // Dagger arm.
    canvas.save();
    canvas.translate(0.12, -0.42);
    canvas.rotate(0.6 - pose.raise * 1.1);
    canvas.drawRRect(RRect.fromLTRBR(-0.02, -0.02, 0.16, 0.04, const Radius.circular(0.02)), _fill(c(skin)));
    canvas.drawPath(
      Path()
        ..moveTo(0.16, -0.01)
        ..lineTo(0.34, 0.01)
        ..lineTo(0.16, 0.04)
        ..close(),
      _fill(c(const Color(0xFFC9D1DB))),
    );
    canvas.restore();
    // Head.
    const head = Offset(0, -0.66);
    canvas.drawPath(
      Path()
        ..moveTo(-0.13, -0.7)
        ..lineTo(-0.36, -0.82 - pose.raise * 0.03)
        ..lineTo(-0.15, -0.62)
        ..close(),
      _fill(c(skin)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0.13, -0.7)
        ..lineTo(0.36, -0.82 - pose.raise * 0.03)
        ..lineTo(0.15, -0.62)
        ..close(),
      _fill(c(skin)),
    );
    canvas.drawOval(Rect.fromCenter(center: head, width: 0.34, height: 0.3), _fill(c(skin)));
    canvas.drawOval(Rect.fromCenter(center: head + const Offset(-0.03, -0.06), width: 0.18, height: 0.08),
        _fill(c(_lighten(skin, 0.18))));
    _eye(canvas, head + const Offset(0.04, -0.02), 0.028, c(palette.accent), pose);
    _eye(canvas, head + const Offset(0.12, -0.02), 0.028, c(palette.accent), pose);
    canvas.drawCircle(head + const Offset(0.05, -0.02), 0.011, _fill(c(const Color(0xFF111111))));
    canvas.drawCircle(head + const Offset(0.13, -0.02), 0.011, _fill(c(const Color(0xFF111111))));
    // Grin.
    final mouth = Path()
      ..moveTo(0.02, -0.59)
      ..quadraticBezierTo(0.1, -0.54 + pose.mouth * 0.04, 0.16, -0.6)
      ..close();
    canvas.drawPath(mouth, _fill(c(const Color(0xFF2A1010))));
    canvas.drawRect(const Rect.fromLTRB(0.06, -0.595, 0.075, -0.575), _fill(c(const Color(0xFFF7F2DC))));
    canvas.drawRect(const Rect.fromLTRB(0.11, -0.595, 0.125, -0.575), _fill(c(const Color(0xFFF7F2DC))));
  }
}

class GolemSkin extends EntitySkin {
  const GolemSkin();

  @override
  Offset get castPoint => const Offset(0.1, -0.62);

  @override
  Offset get corePoint => const Offset(0, -0.5);

  @override
  void render(Canvas canvas, EntityPose pose, EntityPalette palette) {
    Color c(Color color) => palette.tint(color, pose);
    final stone = palette.primary;
    final dark = palette.secondary;
    RRect block(double l, double t, double r, double b) => RRect.fromLTRBR(l, t, r, b, const Radius.circular(0.04));
    canvas.drawRRect(block(-0.22, -0.22, -0.06, 0), _fill(c(dark)));
    canvas.drawRRect(block(0.06, -0.22, 0.22, 0), _fill(c(dark)));
    canvas.drawRRect(block(-0.28, -0.72, 0.28, -0.2), _fill(c(stone)));
    canvas.drawRRect(block(-0.28, -0.72, 0.28, -0.62), _fill(c(_lighten(stone, 0.15))));
    // Cracks.
    final crack = Paint()
      ..color = c(_darken(stone, 0.4))
      ..strokeWidth = 0.012
      ..style = PaintingStyle.stroke;
    canvas.drawPath(Path()..moveTo(-0.2, -0.55)..lineTo(-0.12, -0.48)..lineTo(-0.16, -0.36), crack);
    canvas.drawPath(Path()..moveTo(0.22, -0.3)..lineTo(0.14, -0.26)..lineTo(0.16, -0.22), crack);
    // Rune core.
    final coreGlow = 0.6 + pose.glow * 0.6;
    glowCircle(canvas, const Offset(0, -0.46), 0.1 * coreGlow, palette.accent.withValues(alpha: 0.7 * pose.alpha), 0.06);
    canvas.drawPath(
      Path()
        ..moveTo(0, -0.54)
        ..lineTo(0.05, -0.46)
        ..lineTo(0, -0.38)
        ..lineTo(-0.05, -0.46)
        ..close(),
      _fill(c(_lighten(palette.accent, 0.3))),
    );
    // Arms / fists.
    final raise = pose.raise * 0.12;
    canvas.drawRRect(block(-0.44, -0.66 - raise, -0.3, -0.3 - raise), _fill(c(_darken(stone, 0.1))));
    canvas.drawRRect(block(-0.47, -0.36 - raise, -0.29, -0.2 - raise), _fill(c(dark)));
    canvas.drawRRect(block(0.3, -0.66 - raise, 0.44, -0.3 - raise), _fill(c(_darken(stone, 0.1))));
    canvas.drawRRect(block(0.29, -0.36 - raise, 0.47, -0.2 - raise), _fill(c(dark)));
    // Head.
    canvas.drawRRect(block(-0.13, -0.92, 0.13, -0.72), _fill(c(stone)));
    canvas.drawRRect(RRect.fromLTRBR(-0.08, -0.84, 0.1, -0.8, const Radius.circular(0.02)),
        _glowPaint(palette.accent.withValues(alpha: pose.alpha), 0.012));
    canvas.drawRRect(RRect.fromLTRBR(-0.08, -0.84, 0.1, -0.8, const Radius.circular(0.02)), _fill(c(palette.accent)));
  }
}

class MageSkin extends EntitySkin {
  const MageSkin();

  @override
  bool get floats => true;

  @override
  Offset get castPoint => const Offset(0.3, -0.62);

  @override
  Offset get corePoint => const Offset(0, -0.52);

  @override
  void render(Canvas canvas, EntityPose pose, EntityPalette palette) {
    Color c(Color color) => palette.tint(color, pose);
    canvas.translate(0, -0.08);
    final flutter = math.sin(pose.time * 5) * 0.02;
    final robe = Path()
      ..moveTo(-0.12, -0.7)
      ..quadraticBezierTo(-0.24, -0.35, -0.24, -0.04)
      ..lineTo(-0.16, -0.1 + flutter)
      ..lineTo(-0.08, 0.0)
      ..lineTo(0.0, -0.09 - flutter)
      ..lineTo(0.08, 0.0)
      ..lineTo(0.16, -0.1 + flutter)
      ..lineTo(0.24, -0.04)
      ..quadraticBezierTo(0.24, -0.35, 0.12, -0.7)
      ..close();
    canvas.drawPath(robe, _fill(c(palette.primary)));
    canvas.drawPath(
      Path()
        ..moveTo(-0.02, -0.68)
        ..lineTo(0.02, -0.68)
        ..lineTo(0.06, -0.06)
        ..lineTo(-0.06, -0.06)
        ..close(),
      _fill(c(_darken(palette.primary, 0.3))),
    );
    // Hood.
    canvas.drawPath(
      Path()
        ..moveTo(-0.15, -0.66)
        ..quadraticBezierTo(-0.18, -0.9, 0.0, -1.02)
        ..quadraticBezierTo(0.18, -0.9, 0.15, -0.66)
        ..close(),
      _fill(c(palette.secondary)),
    );
    canvas.drawOval(const Rect.fromLTRB(-0.09, -0.88, 0.09, -0.7), _fill(c(const Color(0xFF07060F))));
    _eye(canvas, const Offset(-0.03, -0.79), 0.018, c(palette.accent), pose);
    _eye(canvas, const Offset(0.04, -0.79), 0.018, c(palette.accent), pose);
    // Casting hand with orb.
    final hand = Offset(0.24 + pose.raise * 0.05, -0.5 - pose.raise * 0.12);
    canvas.drawLine(const Offset(0.1, -0.58), hand,
        Paint()
          ..color = c(palette.primary)
          ..strokeWidth = 0.06
          ..strokeCap = StrokeCap.round);
    final orb = 0.05 + pose.glow * 0.04;
    glowCircle(canvas, hand + const Offset(0.03, -0.04), orb * 2, palette.accent.withValues(alpha: 0.6 * pose.alpha), 0.05);
    canvas.drawCircle(hand + const Offset(0.03, -0.04), orb, _fill(c(_lighten(palette.accent, 0.4))));
  }
}

class BlobSkin extends EntitySkin {
  const BlobSkin();

  @override
  Offset get castPoint => const Offset(0.2, -0.36);

  @override
  Offset get corePoint => const Offset(0, -0.3);

  @override
  void render(Canvas canvas, EntityPose pose, EntityPalette palette) {
    Color c(Color color) => palette.tint(color, pose);
    final wobble = math.sin(pose.time * 4) * 0.02;
    final body = Path()
      ..moveTo(-0.36, 0)
      ..quadraticBezierTo(-0.42 - wobble, -0.36, -0.14, -0.6 + wobble)
      ..quadraticBezierTo(0.1, -0.72, 0.3, -0.52)
      ..quadraticBezierTo(0.44 + wobble, -0.28, 0.36, 0)
      ..close();
    canvas.drawPath(body, _fill(c(palette.primary)));
    canvas.drawOval(const Rect.fromLTRB(-0.2, -0.56, 0.02, -0.44), _fill(c(_lighten(palette.primary, 0.3)).withValues(alpha: 0.6 * pose.alpha)));
    // Mouth opens when chomping.
    final open = 0.05 + pose.mouth * 0.14;
    final mouth = Path()
      ..moveTo(-0.08, -0.26)
      ..quadraticBezierTo(0.12, -0.26 - open, 0.32, -0.28)
      ..quadraticBezierTo(0.12, -0.26 + open, -0.08, -0.26)
      ..close();
    canvas.drawPath(mouth, _fill(c(_darken(palette.secondary, 0.4))));
    final tooth = _fill(c(const Color(0xFFF7F2DC)));
    for (var i = 0; i < 5; i++) {
      final x = -0.02 + i * 0.07;
      canvas.drawPath(Path()..moveTo(x, -0.27 - open * 0.7)..lineTo(x + 0.03, -0.27 - open * 0.7)..lineTo(x + 0.015, -0.23 - open * 0.4)..close(), tooth);
    }
    // Floating letters inside.
    final letter = Paint()
      ..color = c(palette.accent).withValues(alpha: 0.5 * pose.alpha)
      ..strokeWidth = 0.014
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final at = Offset(-0.18 + i * 0.14, -0.12 + math.sin(pose.time * 2 + i) * 0.03);
      canvas.drawPath(Path()..moveTo(at.dx, at.dy)..lineTo(at.dx + 0.03, at.dy - 0.06)..lineTo(at.dx + 0.06, at.dy), letter);
    }
    // Eye stalks.
    for (final dx in [0.02, 0.18]) {
      final tip = Offset(dx + math.sin(pose.time * 3 + dx * 10) * 0.02, -0.74);
      canvas.drawLine(Offset(dx, -0.6), tip,
          Paint()
            ..color = c(palette.primary)
            ..strokeWidth = 0.03);
      canvas.drawCircle(tip, 0.045, _fill(c(const Color(0xFFF7F2DC))));
      canvas.drawCircle(tip + const Offset(0.012, 0), 0.02, _fill(c(palette.secondary)));
    }
  }
}

class ChestSkin extends EntitySkin {
  const ChestSkin();

  @override
  Offset get castPoint => const Offset(0.2, -0.4);

  @override
  Offset get corePoint => const Offset(0, -0.3);

  @override
  void render(Canvas canvas, EntityPose pose, EntityPalette palette) {
    Color c(Color color) => palette.tint(color, pose);
    final wood = palette.primary;
    final band = palette.accent;
    canvas.drawRRect(RRect.fromLTRBR(-0.32, -0.34, 0.32, 0, const Radius.circular(0.03)), _fill(c(wood)));
    for (final x in [-0.2, 0.18]) {
      canvas.drawRect(Rect.fromLTRB(x, -0.34, x + 0.05, 0), _fill(c(band)));
    }
    // Mouth interior and tongue.
    final open = 0.08 + pose.mouth * 0.14 + math.sin(pose.time * 3) * 0.01;
    canvas.drawRect(Rect.fromLTRB(-0.3, -0.34 - open, 0.3, -0.34), _fill(c(const Color(0xFF1A0707))));
    canvas.drawOval(const Rect.fromLTRB(-0.06, -0.38, 0.22, -0.3), _fill(c(const Color(0xFFD9425A))));
    _eye(canvas, Offset(-0.1, -0.34 - open * 0.55), 0.022, c(const Color(0xFFFFE066)), pose);
    _eye(canvas, Offset(0.06, -0.34 - open * 0.55), 0.022, c(const Color(0xFFFFE066)), pose);
    // Teeth.
    final tooth = _fill(c(const Color(0xFFF7F2DC)));
    for (var i = 0; i < 7; i++) {
      final x = -0.28 + i * 0.085;
      canvas.drawPath(Path()..moveTo(x, -0.34)..lineTo(x + 0.04, -0.34)..lineTo(x + 0.02, -0.3)..close(), tooth);
    }
    // Lid.
    canvas.save();
    canvas.translate(-0.32, -0.34 - open);
    canvas.rotate(-pose.mouth * 0.12);
    canvas.drawPath(
      Path()
        ..moveTo(0, 0)
        ..lineTo(0, -0.1)
        ..quadraticBezierTo(0.32, -0.26, 0.64, -0.1)
        ..lineTo(0.64, 0)
        ..close(),
      _fill(c(_lighten(wood, 0.1))),
    );
    for (var i = 0; i < 7; i++) {
      final x = 0.04 + i * 0.085;
      canvas.drawPath(Path()..moveTo(x, 0)..lineTo(x + 0.04, 0)..lineTo(x + 0.02, 0.04)..close(), tooth);
    }
    canvas.drawRect(const Rect.fromLTRB(0.29, -0.12, 0.35, 0), _fill(c(band)));
    canvas.restore();
  }
}

class WispSkin extends EntitySkin {
  const WispSkin();

  @override
  bool get floats => true;

  @override
  Offset get castPoint => const Offset(0.12, -0.55);

  @override
  Offset get corePoint => const Offset(0, -0.5);

  @override
  void render(Canvas canvas, EntityPose pose, EntityPalette palette) {
    Color c(Color color) => palette.tint(color, pose);
    canvas.translate(0, -0.12);
    final t = pose.time;
    Path flame(double width, double height, double phase) => Path()
      ..moveTo(0, -height)
      ..cubicTo(width * 0.8 + math.sin(t * 6 + phase) * 0.03, -height * 0.6, width, -height * 0.15, 0, 0)
      ..cubicTo(-width, -height * 0.15, -width * 0.8 + math.sin(t * 5 + phase) * 0.03, -height * 0.6, 0, -height)
      ..close();
    glowCircle(canvas, const Offset(0, -0.35), 0.36, palette.primary.withValues(alpha: 0.45 * pose.alpha), 0.12);
    canvas.drawPath(flame(0.26, 0.78 + math.sin(t * 7) * 0.03, 0), _fill(c(palette.secondary)));
    canvas.drawPath(flame(0.19, 0.62 + math.sin(t * 8) * 0.03, 1), _fill(c(palette.primary)));
    canvas.drawPath(flame(0.1, 0.4, 2), _fill(c(palette.accent)));
    _eye(canvas, const Offset(-0.05, -0.3), 0.022, c(const Color(0xFF2A1405)), pose, glow: false);
    _eye(canvas, const Offset(0.06, -0.3), 0.022, c(const Color(0xFF2A1405)), pose, glow: false);
  }
}

class KnightSkin extends EntitySkin {
  const KnightSkin();

  @override
  Offset get castPoint => const Offset(0.22, -0.7);

  @override
  Offset get corePoint => const Offset(0, -0.55);

  @override
  void render(Canvas canvas, EntityPose pose, EntityPalette palette) {
    Color c(Color color) => palette.tint(color, pose);
    final steel = palette.primary;
    final dark = palette.secondary;
    // Legs.
    canvas.drawRRect(RRect.fromLTRBR(-0.14, -0.3, -0.04, 0, const Radius.circular(0.02)), _fill(c(dark)));
    canvas.drawRRect(RRect.fromLTRBR(0.04, -0.3, 0.14, 0, const Radius.circular(0.02)), _fill(c(dark)));
    // Cape.
    canvas.drawPath(
      Path()
        ..moveTo(-0.2, -0.78)
        ..quadraticBezierTo(-0.34, -0.4, -0.3 + math.sin(pose.time * 2) * 0.02, -0.04)
        ..lineTo(0.0, -0.1)
        ..close(),
      _fill(c(const Color(0xFF6B1E2E))),
    );
    // Torso plate.
    canvas.drawPath(
      Path()
        ..moveTo(-0.2, -0.8)
        ..lineTo(0.2, -0.8)
        ..lineTo(0.16, -0.32)
        ..lineTo(-0.16, -0.32)
        ..close(),
      _fill(c(steel)),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, -0.78)
        ..lineTo(0.14, -0.74)
        ..lineTo(0.1, -0.36)
        ..lineTo(0, -0.34)
        ..close(),
      _fill(c(_lighten(steel, 0.2))),
    );
    // Pauldrons.
    canvas.drawOval(const Rect.fromLTRB(-0.3, -0.86, -0.1, -0.7), _fill(c(_lighten(steel, 0.1))));
    canvas.drawOval(const Rect.fromLTRB(0.1, -0.86, 0.3, -0.7), _fill(c(_lighten(steel, 0.1))));
    // Helmet with horns.
    canvas.drawPath(Path()..moveTo(-0.1, -0.98)..quadraticBezierTo(-0.26, -1.06, -0.24, -1.2)..quadraticBezierTo(-0.18, -1.06, -0.06, -1.02)..close(),
        _fill(c(const Color(0xFFE8DCC0))));
    canvas.drawPath(Path()..moveTo(0.1, -0.98)..quadraticBezierTo(0.26, -1.06, 0.24, -1.2)..quadraticBezierTo(0.18, -1.06, 0.06, -1.02)..close(),
        _fill(c(const Color(0xFFE8DCC0))));
    canvas.drawRRect(RRect.fromLTRBR(-0.12, -1.06, 0.12, -0.8, const Radius.circular(0.06)), _fill(c(steel)));
    canvas.drawRect(const Rect.fromLTRB(-0.08, -0.96, 0.1, -0.93), _glowPaint(palette.accent.withValues(alpha: pose.alpha), 0.015));
    canvas.drawRect(const Rect.fromLTRB(-0.08, -0.96, 0.1, -0.93), _fill(c(palette.accent)));
    // Sword arm.
    canvas.save();
    canvas.translate(0.18, -0.7);
    canvas.rotate(0.9 - pose.raise * 1.6);
    canvas.drawRRect(RRect.fromLTRBR(-0.03, -0.03, 0.2, 0.05, const Radius.circular(0.02)), _fill(c(steel)));
    canvas.drawRect(const Rect.fromLTRB(0.18, -0.06, 0.21, 0.08), _fill(c(palette.accent)));
    canvas.drawPath(Path()..moveTo(0.21, -0.02)..lineTo(0.62, 0.0)..lineTo(0.21, 0.04)..close(), _fill(c(const Color(0xFFD7DEE8))));
    canvas.restore();
    // Tower shield.
    canvas.drawPath(
      Path()
        ..moveTo(0.02, -0.72)
        ..lineTo(0.3, -0.7)
        ..lineTo(0.3, -0.3)
        ..quadraticBezierTo(0.26, -0.14, 0.16, -0.08)
        ..quadraticBezierTo(0.06, -0.14, 0.02, -0.3)
        ..close(),
      _fill(c(dark)),
    );
    canvas.drawCircle(const Offset(0.16, -0.44), 0.05, _fill(c(palette.accent)));
  }
}

class TreantSkin extends EntitySkin {
  const TreantSkin();

  @override
  Offset get castPoint => const Offset(0.3, -0.8);

  @override
  Offset get corePoint => const Offset(0, -0.55);

  @override
  void render(Canvas canvas, EntityPose pose, EntityPalette palette) {
    Color c(Color color) => palette.tint(color, pose);
    final bark = palette.secondary;
    final leaves = palette.primary;
    final sway = math.sin(pose.time * 1.6) * 0.03;
    // Roots.
    for (final dx in [-0.2, -0.05, 0.12]) {
      canvas.drawPath(Path()..moveTo(dx, -0.1)..quadraticBezierTo(dx - 0.08, -0.02, dx - 0.12, 0)..lineTo(dx + 0.06, 0)..close(), _fill(c(bark)));
    }
    // Trunk.
    canvas.drawPath(
      Path()
        ..moveTo(-0.18, 0)
        ..quadraticBezierTo(-0.12, -0.5, -0.2, -0.86)
        ..lineTo(0.2, -0.86)
        ..quadraticBezierTo(0.12, -0.5, 0.18, 0)
        ..close(),
      _fill(c(bark)),
    );
    final grain = Paint()
      ..color = c(_darken(bark, 0.35))
      ..strokeWidth = 0.014
      ..style = PaintingStyle.stroke;
    canvas.drawPath(Path()..moveTo(-0.08, -0.1)..quadraticBezierTo(-0.04, -0.4, -0.1, -0.7), grain);
    canvas.drawPath(Path()..moveTo(0.1, -0.12)..quadraticBezierTo(0.05, -0.45, 0.1, -0.72), grain);
    // Branch arms.
    final lift = pose.raise * 0.12;
    final arm = Paint()
      ..color = c(bark)
      ..strokeWidth = 0.07
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(Path()..moveTo(-0.14, -0.62)..quadraticBezierTo(-0.4, -0.66 - lift, -0.46, -0.9 - lift), arm);
    canvas.drawPath(Path()..moveTo(0.14, -0.62)..quadraticBezierTo(0.4, -0.66 - lift, 0.46, -0.9 - lift), arm);
    // Crown of leaves.
    final leaf = _fill(c(leaves));
    final leafLight = _fill(c(_lighten(leaves, 0.15)));
    for (final spot in const [Offset(-0.2, -0.98), Offset(0.0, -1.1), Offset(0.22, -0.98), Offset(-0.34, -0.86), Offset(0.34, -0.86)]) {
      canvas.drawCircle(spot + Offset(sway, 0), 0.17, leaf);
    }
    canvas.drawCircle(Offset(-0.06 + sway, -1.08), 0.09, leafLight);
    // Blossoms.
    for (final spot in const [Offset(-0.26, -0.92), Offset(0.12, -1.16), Offset(0.3, -0.9)]) {
      canvas.drawCircle(spot + Offset(sway, 0), 0.03, _fill(c(palette.accent)));
    }
    // Face.
    _eye(canvas, const Offset(-0.07, -0.64), 0.028, c(palette.accent), pose);
    _eye(canvas, const Offset(0.07, -0.64), 0.028, c(palette.accent), pose);
    canvas.drawOval(Rect.fromCenter(center: const Offset(0, -0.5), width: 0.12, height: 0.04 + pose.mouth * 0.08),
        _fill(c(_darken(bark, 0.6))));
  }
}

class LichSkin extends EntitySkin {
  const LichSkin();

  @override
  bool get floats => true;

  @override
  Offset get castPoint => const Offset(0.32, -0.7);

  @override
  Offset get corePoint => const Offset(0, -0.6);

  @override
  void render(Canvas canvas, EntityPose pose, EntityPalette palette) {
    Color c(Color color) => palette.tint(color, pose);
    const bone = Color(0xFFE9E3CF);
    canvas.translate(0, -0.1);
    final flutter = math.sin(pose.time * 4) * 0.025;
    glowCircle(canvas, const Offset(0, -0.6), 0.5, palette.primary.withValues(alpha: 0.18 * pose.alpha), 0.15);
    // Tattered robe.
    final robe = Path()..moveTo(-0.16, -0.84);
    robe.quadraticBezierTo(-0.32, -0.4, -0.3, 0);
    for (var i = 0; i < 6; i++) {
      final x = -0.3 + i * 0.12;
      robe.lineTo(x + 0.06, -0.1 + (i.isEven ? flutter : -flutter));
      robe.lineTo(x + 0.12, 0);
    }
    robe
      ..quadraticBezierTo(0.32, -0.4, 0.16, -0.84)
      ..close();
    canvas.drawPath(robe, _fill(c(palette.secondary)));
    canvas.drawPath(
      Path()
        ..moveTo(-0.05, -0.8)
        ..lineTo(0.05, -0.8)
        ..lineTo(0.08, -0.1)
        ..lineTo(-0.08, -0.1)
        ..close(),
      _fill(c(_lighten(palette.secondary, 0.1))),
    );
    // Skull.
    canvas.drawOval(const Rect.fromLTRB(-0.12, -1.06, 0.12, -0.82), _fill(c(bone)));
    canvas.drawRect(const Rect.fromLTRB(-0.07, -0.86, 0.07, -0.8), _fill(c(bone)));
    _eye(canvas, const Offset(-0.045, -0.95), 0.03, c(palette.primary), pose);
    _eye(canvas, const Offset(0.05, -0.95), 0.03, c(palette.primary), pose);
    // Crown.
    canvas.drawPath(
      Path()
        ..moveTo(-0.12, -1.04)
        ..lineTo(-0.1, -1.16)
        ..lineTo(-0.05, -1.08)
        ..lineTo(0, -1.2)
        ..lineTo(0.05, -1.08)
        ..lineTo(0.1, -1.16)
        ..lineTo(0.12, -1.04)
        ..close(),
      _fill(c(palette.accent)),
    );
    // Bony hand and floating book.
    final hand = Offset(0.26 + pose.raise * 0.04, -0.62 - pose.raise * 0.1);
    canvas.drawLine(const Offset(0.12, -0.72), hand,
        Paint()
          ..color = c(palette.secondary)
          ..strokeWidth = 0.06
          ..strokeCap = StrokeCap.round);
    canvas.drawCircle(hand, 0.035, _fill(c(bone)));
    final book = Offset(-0.32, -0.5 + math.sin(pose.time * 2.5) * 0.03);
    glowCircle(canvas, book, 0.14, palette.accent.withValues(alpha: 0.5 * pose.alpha), 0.06);
    canvas.save();
    canvas.translate(book.dx, book.dy);
    canvas.rotate(-0.2);
    canvas.drawPath(Path()..moveTo(0, 0)..lineTo(-0.12, -0.04)..lineTo(-0.12, 0.08)..lineTo(0, 0.1)..close(), _fill(c(_lighten(palette.accent, 0.5))));
    canvas.drawPath(Path()..moveTo(0, 0)..lineTo(0.12, -0.04)..lineTo(0.12, 0.08)..lineTo(0, 0.1)..close(), _fill(c(_lighten(palette.accent, 0.35))));
    canvas.restore();
  }
}
