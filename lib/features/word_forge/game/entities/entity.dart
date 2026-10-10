import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';

/// Visual states shared by the player and every enemy.
enum EntityState { idle, cast, channel, attack, hit, shield, enraged, chomp, victory, defeated }

/// Per-frame pose parameters. Skins read these instead of owning timelines,
/// so one animator drives every character.
class EntityPose {
  double time = 0;
  double bob = 0;
  double lean = 0;
  double lunge = 0;
  double squash = 0;
  double flash = 0;
  double alpha = 1;
  double raise = 0;
  double mouth = 0;
  double glow = 0;
  double enrage = 0;
  double sink = 0;
}

/// Palette with the pose tint applied (hit flash, enrage) so skins never
/// duplicate colour logic.
class EntityPalette {
  final Color primary;
  final Color secondary;
  final Color accent;

  const EntityPalette({required this.primary, required this.secondary, required this.accent});

  Color tint(Color color, EntityPose pose) {
    var result = color;
    if (pose.enrage > 0) result = Color.lerp(result, const Color(0xFFFF3B3B), pose.enrage * 0.28)!;
    if (pose.flash > 0) result = Color.lerp(result, const Color(0xFFFFFFFF), pose.flash * 0.85)!;
    return pose.alpha < 1 ? result.withValues(alpha: result.a * pose.alpha) : result;
  }
}

/// Draws a character in unit space: feet at (0, 0), height 1 upwards (-y),
/// facing right (+x). Components flip and scale it.
abstract class EntitySkin {
  const EntitySkin();

  /// Where spells leave / arrive, in unit space.
  Offset get castPoint => const Offset(0.3, -0.7);
  Offset get corePoint => const Offset(0, -0.5);

  /// Enemies that float do not bob on the ground.
  bool get floats => false;

  void render(Canvas canvas, EntityPose pose, EntityPalette palette);

  /// Soft contact shadow shared by all skins.
  void shadow(Canvas canvas, EntityPose pose, {double width = 0.5}) {
    final lift = floats ? 0.08 + math.sin(pose.time * 2) * 0.02 : 0.0;
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(0, 0.01), width: width * (1 - lift), height: 0.07),
      Paint()..color = const Color(0xFF000000).withValues(alpha: 0.35 * pose.alpha),
    );
  }
}

class _Clip {
  final EntityState state;
  final double duration;
  final bool loop;

  const _Clip(this.state, this.duration, {this.loop = false});
}

/// Converts the current state + elapsed time into an [EntityPose].
class EntityAnimator {
  final double tempo;
  final EntityPose pose = EntityPose();
  _Clip _clip = const _Clip(EntityState.idle, 1, loop: true);
  double _t = 0;
  double _flash = 0;
  bool _enraged = false;

  EntityAnimator({this.tempo = 1});

  EntityState get state => _clip.state;

  void play(EntityState state, {double? duration}) {
    if (_clip.state == EntityState.defeated) return;
    final loop = state == EntityState.idle || state == EntityState.channel || state == EntityState.shield;
    _clip = _Clip(state, duration ?? _defaultDuration(state), loop: loop);
    _t = 0;
    if (state == EntityState.hit) _flash = 1;
  }

  void setEnraged(bool value) => _enraged = value;

  double _defaultDuration(EntityState state) => switch (state) {
        EntityState.cast => 0.55,
        EntityState.attack => 0.5,
        EntityState.hit => 0.42,
        EntityState.chomp => 0.5,
        EntityState.enraged => 0.9,
        EntityState.victory => 1.2,
        EntityState.defeated => 1.1,
        _ => 1,
      };

  void update(double dt, {required bool floats}) {
    final step = dt * tempo;
    pose.time += dt;
    _t += step;
    _flash = math.max(0, _flash - dt * 4);
    final progress = (_t / _clip.duration).clamp(0.0, 1.0);
    final bell = math.sin(progress * math.pi);

    pose
      ..bob = math.sin(pose.time * (floats ? 2.2 : 3.1) * tempo) * (floats ? 0.035 : 0.012)
      ..squash = math.sin(pose.time * 3.1 * tempo) * 0.012
      ..lean = 0
      ..lunge = 0
      ..raise = 0
      ..mouth = 0
      ..glow = 0.25 + 0.15 * math.sin(pose.time * 4)
      ..flash = _flash
      ..enrage = _enraged ? 0.6 + 0.4 * math.sin(pose.time * 8) : 0
      ..alpha = 1
      ..sink = 0;

    switch (_clip.state) {
      case EntityState.idle:
        break;
      case EntityState.cast:
        pose
          ..raise = bell
          ..lean = bell * 0.08
          ..glow = 0.4 + bell * 0.6;
      case EntityState.channel:
        pose
          ..raise = 0.8 + 0.2 * math.sin(pose.time * 6)
          ..glow = 0.7 + 0.3 * math.sin(pose.time * 9)
          ..lean = 0.04;
      case EntityState.attack:
        pose
          ..lunge = progress < 0.4 ? -progress / 0.4 * 0.05 : bell * 0.22
          ..lean = bell * 0.15
          ..raise = bell;
      case EntityState.hit:
        pose
          ..lunge = -bell * 0.12
          ..lean = -bell * 0.12
          ..squash = bell * 0.05;
      case EntityState.shield:
        pose
          ..raise = 0.6
          ..lean = -0.03
          ..glow = 0.6 + 0.2 * math.sin(pose.time * 5);
      case EntityState.enraged:
        pose
          ..squash = -bell * 0.08
          ..raise = bell
          ..mouth = bell;
      case EntityState.chomp:
        pose
          ..mouth = math.sin(progress * math.pi * 3).abs()
          ..lunge = bell * 0.08;
      case EntityState.victory:
        pose
          ..raise = math.min(1, progress * 2)
          ..bob += bell * 0.05
          ..glow = 1;
      case EntityState.defeated:
        pose
          ..alpha = 1 - progress
          ..sink = progress * 0.25
          ..lean = -progress * 0.35
          ..flash = math.max(_flash, (1 - progress) * 0.4);
    }

    if (!_clip.loop && _t >= _clip.duration && _clip.state != EntityState.defeated &&
        _clip.state != EntityState.victory) {
      _clip = const _Clip(EntityState.idle, 1, loop: true);
      _t = 0;
    }
  }
}

/// A character on stage. Skin, palette and animator are injected, so adding
/// an enemy never requires a new component class.
class EntityComponent extends PositionComponent {
  final EntitySkin skin;
  final EntityPalette palette;
  final EntityAnimator animator;

  /// 1 = facing right (player), -1 = facing left (enemy).
  final double facing;

  EntityComponent({
    required this.skin,
    required this.palette,
    required this.animator,
    required this.facing,
  }) : super(anchor: Anchor.bottomCenter);

  /// Unit height in pixels.
  double get unit => size.y;

  Vector2 _unitToWorld(Offset unitPoint) {
    final pose = animator.pose;
    return Vector2(
      position.x + (unitPoint.dx + pose.lunge) * unit * facing,
      position.y + (unitPoint.dy - pose.bob + pose.sink) * unit,
    );
  }

  Vector2 get castPoint => _unitToWorld(skin.castPoint);
  Vector2 get corePoint => _unitToWorld(skin.corePoint);

  void play(EntityState state, {double? duration}) => animator.play(state, duration: duration);

  @override
  void update(double dt) {
    super.update(dt);
    animator.update(dt, floats: skin.floats);
  }

  @override
  void render(Canvas canvas) {
    final pose = animator.pose;
    if (pose.alpha <= 0.01) return;
    canvas.save();
    // Anchor is bottom-centre, so local (size.x / 2, size.y) is the feet.
    canvas.translate(size.x / 2, size.y);
    canvas.scale(unit * facing, unit);
    skin.shadow(canvas, pose);
    canvas.translate(pose.lunge, -pose.bob + pose.sink);
    canvas.rotate(pose.lean * 0.6);
    canvas.scale(1 + pose.squash, 1 - pose.squash);
    skin.render(canvas, pose, palette);
    canvas.restore();
  }
}
