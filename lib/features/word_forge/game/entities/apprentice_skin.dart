import 'dart:math' as math;
import '../vfx/glow.dart';
import 'dart:ui';

import '../../domain/characters/player_character.dart';
import 'entity.dart';

Paint _fill(Color color) => Paint()..color = color;


Color _darken(Color color, double amount) => Color.lerp(color, const Color(0xFF000000), amount)!;
Color _lighten(Color color, double amount) => Color.lerp(color, const Color(0xFFFFFFFF), amount)!;

/// The player's young apprentice. Both characters share rig, timing and
/// hitbox; they differ in hair, outfit silhouette and accessories only:
///
/// * he: short spiky hair, tunic with belt and satchel, a scarf from tier 1;
/// * she: side braid with a ribbon, flared robe with a sash and a book pouch,
///   a hair clip from tier 1.
///
/// [tier] (0-3) adds small signs of growing skill: trim and colour accents,
/// a short cape and glowing spellbook, then a rune circlet and a brighter wand.
class ApprenticeSkin extends EntitySkin {
  final PlayerCharacterDefinition character;
  final int tier;

  /// Brand-derived spell colour.
  final Color magic;

  const ApprenticeSkin({required this.character, required this.tier, this.magic = const Color(0xFF34E089)});

  @override
  Offset get castPoint => const Offset(0.33, -0.68);

  @override
  Offset get corePoint => const Offset(0, -0.45);

  @override
  void render(Canvas canvas, EntityPose pose, EntityPalette palette) {
    Color c(Color color) => palette.tint(color, pose);
    final robe = Color(character.robeColor);
    final trim = Color(character.trimColor);
    final hair = Color(character.hairColor);
    final skin = Color(character.skinColor);
    final sway = math.sin(pose.time * 2.4) * 0.015;
    final feminine = character.feminine;

    // Braid / back hair sits behind the body.
    if (feminine) {
      final braid = Path()
        ..moveTo(-0.08, -0.84)
        ..quadraticBezierTo(-0.3 + sway * 2, -0.76, -0.24 + sway * 3, -0.46)
        ..quadraticBezierTo(-0.19, -0.58, -0.05, -0.72)
        ..close();
      canvas.drawPath(braid, _fill(c(hair)));
      // Braid knots.
      for (var i = 0; i < 3; i++) {
        final t = 0.25 + i * 0.22;
        final p = Offset(-0.1 - 0.12 * t + sway * 2 * t, -0.82 + 0.34 * t);
        canvas.drawCircle(p, 0.028, _fill(c(_darken(hair, 0.18))));
      }
      canvas.drawCircle(Offset(-0.24 + sway * 3, -0.47), 0.024, _fill(c(const Color(0xFFFF7AB6))));
    }

    // Short cape from tier 2.
    if (tier >= 2) {
      canvas.drawPath(
        Path()
          ..moveTo(-0.1, -0.58)
          ..quadraticBezierTo(-0.26 + sway, -0.32, -0.22 + sway * 2, -0.14)
          ..lineTo(-0.02, -0.18)
          ..close(),
        _fill(c(_darken(robe, 0.35))),
      );
    }

    // Boots.
    final boot = _fill(c(const Color(0xFF5A3A24)));
    canvas.drawRRect(RRect.fromLTRBR(-0.1, -0.14, -0.02, 0, const Radius.circular(0.03)), boot);
    canvas.drawRRect(RRect.fromLTRBR(0.02, -0.14, 0.11, 0, const Radius.circular(0.03)), boot);

    // Outfit: a belted tunic for him, a flared robe for her.
    final Path outfit;
    if (feminine) {
      outfit = Path()
        ..moveTo(-0.12, -0.58)
        ..quadraticBezierTo(-0.2, -0.36, -0.25 + sway, -0.1)
        ..quadraticBezierTo(0, -0.05, 0.25 - sway, -0.1)
        ..quadraticBezierTo(0.2, -0.36, 0.12, -0.58)
        ..close();
    } else {
      outfit = Path()
        ..moveTo(-0.12, -0.58)
        ..quadraticBezierTo(-0.17, -0.34, -0.19, -0.12)
        ..quadraticBezierTo(0, -0.08, 0.19, -0.12)
        ..quadraticBezierTo(0.17, -0.34, 0.12, -0.58)
        ..close();
    }
    canvas.drawPath(outfit, _fill(c(robe)));
    canvas.drawPath(
      Path()
        ..moveTo(0.03, -0.56)
        ..quadraticBezierTo(0.08, -0.34, feminine ? 0.16 : 0.12, -0.13)
        ..lineTo(feminine ? 0.22 : 0.18, -0.13)
        ..quadraticBezierTo(0.14, -0.36, 0.11, -0.57)
        ..close(),
      _fill(c(_lighten(robe, 0.14))),
    );
    if (tier >= 1) {
      final trimPaint = Paint()
        ..color = c(trim)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.018;
      canvas.drawPath(
        Path()
          ..moveTo(feminine ? -0.25 : -0.19, -0.13)
          ..quadraticBezierTo(0, feminine ? -0.07 : -0.09, feminine ? 0.25 : 0.19, -0.13),
        trimPaint,
      );
      canvas.drawLine(const Offset(-0.06, -0.57), const Offset(0.06, -0.57), trimPaint);
    }

    if (feminine) {
      // Sash tied at the hip, book pouch on the other side.
      canvas.drawPath(
        Path()
          ..moveTo(-0.15, -0.4)
          ..lineTo(0.15, -0.34)
          ..lineTo(0.15, -0.3)
          ..lineTo(-0.15, -0.36)
          ..close(),
        _fill(c(tier >= 1 ? trim : const Color(0xFF8A5A34))),
      );
      canvas.drawPath(
        Path()
          ..moveTo(0.14, -0.33)
          ..quadraticBezierTo(0.2, -0.26, 0.17 + sway, -0.18)
          ..lineTo(0.13, -0.2)
          ..close(),
        _fill(c(tier >= 1 ? _darken(trim, 0.2) : const Color(0xFF6B4428))),
      );
      canvas.drawRRect(RRect.fromLTRBR(-0.18, -0.33, -0.09, -0.23, const Radius.circular(0.015)),
          _fill(c(const Color(0xFF7A3A2A))));
      canvas.drawRect(const Rect.fromLTRB(-0.165, -0.315, -0.105, -0.245), _fill(c(const Color(0xFFE8DCC0))));
    } else {
      // Belt with buckle and a small satchel.
      canvas.drawRect(const Rect.fromLTRB(-0.15, -0.37, 0.15, -0.33), _fill(c(const Color(0xFF6B4428))));
      canvas.drawRect(const Rect.fromLTRB(-0.02, -0.38, 0.02, -0.32), _fill(c(tier >= 1 ? trim : const Color(0xFFB08A50))));
      canvas.drawRRect(RRect.fromLTRBR(-0.17, -0.34, -0.08, -0.25, const Radius.circular(0.02)),
          _fill(c(const Color(0xFF8A5A34))));
      canvas.drawRect(const Rect.fromLTRB(-0.17, -0.34, -0.08, -0.31), _fill(c(const Color(0xFF6B4428))));
    }

    // Glowing spellbook from tier 2.
    if (tier >= 2) {
      glowCircle(canvas, const Offset(0.13, -0.29), 0.07, magic.withValues(alpha: 0.45 * pose.alpha), 0.04);
      canvas.drawRRect(RRect.fromLTRBR(0.08, -0.34, 0.18, -0.24, const Radius.circular(0.012)),
          _fill(c(const Color(0xFF7A3A2A))));
      canvas.drawRect(const Rect.fromLTRB(0.095, -0.325, 0.165, -0.255), _fill(c(_lighten(magic, 0.5))));
    }
    if (tier >= 3) {
      glowCircle(canvas, const Offset(0, -0.46), 0.03, magic.withValues(alpha: pose.alpha), 0.02);
    }

    // Back arm.
    canvas.drawRRect(RRect.fromLTRBR(-0.17, -0.55, -0.1, -0.38, const Radius.circular(0.035)),
        _fill(c(_darken(robe, 0.12))));
    canvas.drawCircle(const Offset(-0.135, -0.37), 0.032, _fill(c(skin)));

    // Scarf for him from tier 1 (colour accent at the neck).
    if (!feminine && tier >= 1) {
      canvas.drawPath(
        Path()
          ..moveTo(-0.1, -0.6)
          ..quadraticBezierTo(0, -0.55, 0.1, -0.6)
          ..lineTo(0.08, -0.55)
          ..quadraticBezierTo(0, -0.5, -0.08, -0.55)
          ..close(),
        _fill(c(trim)),
      );
      canvas.drawPath(
        Path()
          ..moveTo(-0.09, -0.57)
          ..quadraticBezierTo(-0.16 + sway * 2, -0.48, -0.13 + sway * 3, -0.4)
          ..lineTo(-0.07, -0.44)
          ..close(),
        _fill(c(_darken(trim, 0.15))),
      );
    }

    // Head: big, round, friendly — clearly young.
    const head = Offset(0.01, -0.73);
    canvas.drawOval(Rect.fromCenter(center: head + const Offset(0, 0.11), width: 0.07, height: 0.06), _fill(c(skin)));
    canvas.drawCircle(head, 0.15, _fill(c(skin)));
    // Cheeks, eyes, smile.
    canvas.drawCircle(head + const Offset(-0.06, 0.04), 0.025, _fill(c(const Color(0xFFF29A8A)).withValues(alpha: 0.5 * pose.alpha)));
    canvas.drawCircle(head + const Offset(0.09, 0.04), 0.025, _fill(c(const Color(0xFFF29A8A)).withValues(alpha: 0.5 * pose.alpha)));
    final eye = _fill(c(const Color(0xFF231A2E)));
    final blink = (pose.time % 3.7) < 0.12 ? 0.25 : 1.0;
    final eyeHeight = (feminine ? 0.056 : 0.05) * blink;
    canvas.drawOval(Rect.fromCenter(center: head + const Offset(-0.01, 0.0), width: 0.035, height: eyeHeight), eye);
    canvas.drawOval(Rect.fromCenter(center: head + const Offset(0.075, 0.0), width: 0.035, height: eyeHeight), eye);
    if (blink == 1) {
      canvas.drawCircle(head + const Offset(-0.004, -0.012), 0.008, _fill(c(const Color(0xFFFFFFFF))));
      canvas.drawCircle(head + const Offset(0.081, -0.012), 0.008, _fill(c(const Color(0xFFFFFFFF))));
      if (feminine) {
        // Lashes.
        final lash = Paint()
          ..color = c(const Color(0xFF231A2E))
          ..strokeWidth = 0.008
          ..strokeCap = StrokeCap.round;
        canvas.drawLine(head + const Offset(-0.028, -0.02), head + const Offset(-0.04, -0.03), lash);
        canvas.drawLine(head + const Offset(0.093, -0.02), head + const Offset(0.105, -0.03), lash);
      }
    }
    canvas.drawPath(
      Path()
        ..moveTo(0.015, 0.06)
        ..quadraticBezierTo(0.035, 0.085 + pose.raise * 0.015, 0.06, 0.06),
      Paint()
        ..color = c(const Color(0xFF8A3B3B))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.012
        ..strokeCap = StrokeCap.round
        ..blendMode = BlendMode.srcOver,
    );

    // Hair.
    final hairPaint = _fill(c(hair));
    if (feminine) {
      // Smooth fringe swept to one side, braid starting behind the ear.
      canvas.drawPath(
        Path()
          ..moveTo(-0.15, -0.69)
          ..quadraticBezierTo(-0.17, -0.9, 0.01, -0.9)
          ..quadraticBezierTo(0.17, -0.9, 0.16, -0.72)
          ..quadraticBezierTo(0.12, -0.82, 0.02, -0.81)
          ..quadraticBezierTo(-0.04, -0.8, -0.1, -0.64)
          ..close(),
        hairPaint,
      );
      // Hair clip (tier 1+) or a simple ribbon.
      if (tier >= 1) {
        canvas.drawPath(
          Path()
            ..moveTo(0.08, -0.86)
            ..lineTo(0.13, -0.9)
            ..lineTo(0.14, -0.84)
            ..close(),
          _fill(c(trim)),
        );
        canvas.drawCircle(const Offset(0.11, -0.865), 0.012, _fill(c(magic)));
      }
      canvas.drawCircle(const Offset(-0.1, -0.83), 0.025, _fill(c(const Color(0xFFFF7AB6))));
    } else {
      // Short, spiky, a little messy.
      canvas.drawPath(
        Path()
          ..moveTo(-0.15, -0.7)
          ..quadraticBezierTo(-0.16, -0.89, 0.01, -0.9)
          ..quadraticBezierTo(0.16, -0.89, 0.16, -0.74)
          ..lineTo(0.11, -0.79)
          ..lineTo(0.08, -0.76)
          ..lineTo(0.04, -0.8)
          ..lineTo(0.0, -0.77)
          ..lineTo(-0.05, -0.8)
          ..lineTo(-0.1, -0.73)
          ..close(),
        hairPaint,
      );
      for (final spike in [(-0.08, -0.88, -0.1, -0.97, -0.02, -0.9), (-0.02, -0.9, 0.02, -0.98, 0.05, -0.89), (0.07, -0.88, 0.13, -0.95, 0.12, -0.86)]) {
        canvas.drawPath(
          Path()
            ..moveTo(spike.$1, spike.$2)
            ..lineTo(spike.$3, spike.$4)
            ..lineTo(spike.$5, spike.$6)
            ..close(),
          hairPaint,
        );
      }
    }
    if (tier >= 3) {
      canvas.drawArc(Rect.fromCenter(center: head + const Offset(0, -0.02), width: 0.3, height: 0.2), math.pi * 1.1,
          math.pi * 0.8, false,
          Paint()
            ..color = c(trim)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 0.016);
      canvas.drawCircle(head + const Offset(0.0, -0.12), 0.018, _fill(c(magic)));
    }

    // Wand arm, raised while casting.
    canvas.save();
    canvas.translate(0.1, -0.52);
    canvas.rotate(0.35 - pose.raise * 0.9);
    canvas.drawRRect(RRect.fromLTRBR(-0.03, -0.035, 0.15, 0.035, const Radius.circular(0.035)), _fill(c(robe)));
    canvas.drawCircle(const Offset(0.16, 0), 0.033, _fill(c(skin)));
    canvas.drawLine(const Offset(0.16, 0), const Offset(0.29, -0.03),
        Paint()
          ..color = c(const Color(0xFF9A6A3E))
          ..strokeWidth = 0.022
          ..strokeCap = StrokeCap.round);
    final glow = 0.5 + pose.glow * (0.8 + tier * 0.15);
    glowCircle(canvas, const Offset(0.3, -0.032), 0.05 * glow, magic.withValues(alpha: 0.7 * pose.alpha), 0.035);
    canvas.drawCircle(const Offset(0.3, -0.032), 0.018, _fill(c(_lighten(magic, 0.5))));
    canvas.restore();
  }
}

/// Brute archetype: slow, heavy, obvious.
class OgreSkin extends EntitySkin {
  const OgreSkin();

  @override
  Offset get castPoint => const Offset(0.3, -0.62);

  @override
  Offset get corePoint => const Offset(0, -0.48);

  @override
  void shadow(Canvas canvas, EntityPose pose, {double width = 0.5}) => super.shadow(canvas, pose, width: 0.7);

  @override
  void render(Canvas canvas, EntityPose pose, EntityPalette palette) {
    Color c(Color color) => palette.tint(color, pose);
    final hide = palette.primary;
    final cloth = palette.secondary;
    // Legs.
    canvas.drawRRect(RRect.fromLTRBR(-0.2, -0.2, -0.06, 0, const Radius.circular(0.05)), _fill(c(_darken(hide, 0.2))));
    canvas.drawRRect(RRect.fromLTRBR(0.06, -0.2, 0.2, 0, const Radius.circular(0.05)), _fill(c(_darken(hide, 0.2))));
    // Big belly.
    canvas.drawOval(const Rect.fromLTRB(-0.3, -0.7, 0.3, -0.14), _fill(c(hide)));
    canvas.drawOval(const Rect.fromLTRB(-0.18, -0.52, 0.2, -0.18), _fill(c(_lighten(hide, 0.12))));
    // Loincloth and belt.
    canvas.drawPath(
      Path()
        ..moveTo(-0.24, -0.26)
        ..lineTo(0.24, -0.26)
        ..lineTo(0.16, -0.08)
        ..lineTo(-0.16, -0.08)
        ..close(),
      _fill(c(cloth)),
    );
    canvas.drawRect(const Rect.fromLTRB(-0.26, -0.3, 0.26, -0.25), _fill(c(_darken(cloth, 0.4))));
    // Back arm.
    canvas.drawRRect(RRect.fromLTRBR(-0.42, -0.62, -0.26, -0.3, const Radius.circular(0.07)), _fill(c(_darken(hide, 0.1))));
    // Small head with tusks.
    const head = Offset(0.04, -0.78);
    canvas.drawOval(Rect.fromCenter(center: head, width: 0.26, height: 0.22), _fill(c(hide)));
    canvas.drawRect(Rect.fromCenter(center: head + const Offset(0.02, -0.03), width: 0.2, height: 0.025),
        _fill(c(_darken(hide, 0.35))));
    canvas.drawCircle(head + const Offset(-0.02, 0.0), 0.022, _fill(c(palette.accent)));
    canvas.drawCircle(head + const Offset(0.07, 0.0), 0.022, _fill(c(palette.accent)));
    final tusk = _fill(c(const Color(0xFFF2EAD3)));
    canvas.drawPath(Path()..moveTo(-0.03, 0.06 + head.dy)..lineTo(-0.02, head.dy + 0.01)..lineTo(0.0, head.dy + 0.06)..close(), tusk);
    canvas.drawPath(Path()..moveTo(0.08, 0.06 + head.dy)..lineTo(0.09, head.dy + 0.01)..lineTo(0.11, head.dy + 0.06)..close(), tusk);
    // Club arm.
    canvas.save();
    canvas.translate(0.24, -0.58);
    canvas.rotate(0.6 - pose.raise * 1.5);
    canvas.drawRRect(RRect.fromLTRBR(-0.04, -0.06, 0.18, 0.06, const Radius.circular(0.06)), _fill(c(hide)));
    canvas.drawRRect(RRect.fromLTRBR(0.14, -0.05, 0.5, 0.05, const Radius.circular(0.04)), _fill(c(const Color(0xFF6E4A2C))));
    canvas.drawOval(const Rect.fromLTRB(0.4, -0.1, 0.6, 0.1), _fill(c(const Color(0xFF7E5636))));
    canvas.restore();
  }
}
