import 'dart:ui';

import 'package:flame/components.dart';

import 'entity.dart';

/// Replaces a procedural skin with a single illustrated sprite (feet at the
/// bottom centre of the image). Enable per enemy with `"sprite"` in
/// enemies.json; the file lives under `assets/word_forge/enemies/`.
/// Pose effects (bob, lean, hit flash, fade) still apply.
class SpriteEntitySkin extends EntitySkin {
  final Sprite sprite;
  final EntitySkin fallback;

  const SpriteEntitySkin({required this.sprite, required this.fallback});

  @override
  Offset get castPoint => fallback.castPoint;

  @override
  Offset get corePoint => fallback.corePoint;

  @override
  bool get floats => fallback.floats;

  @override
  void render(Canvas canvas, EntityPose pose, EntityPalette palette) {
    final aspect = sprite.srcSize.x / sprite.srcSize.y;
    final paint = Paint()..color = Color.fromRGBO(255, 255, 255, pose.alpha.clamp(0.0, 1.0));
    if (pose.flash > 0) {
      paint.colorFilter = ColorFilter.mode(
          const Color(0xFFFFFFFF).withValues(alpha: pose.flash * 0.7), BlendMode.srcATop);
    }
    sprite.render(
      canvas,
      position: Vector2(-aspect / 2, -1),
      size: Vector2(aspect, 1),
      overridePaint: paint,
    );
  }
}
