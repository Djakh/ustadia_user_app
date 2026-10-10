import 'dart:math' as math;
import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/particles.dart';
import 'package:flutter/painting.dart' show TextStyle, FontWeight, Shadow, TextPainter, TextSpan;

import 'glow.dart';

export 'glow.dart';

/// Effect quality knobs. Reduced mode lowers particle counts, shake and
/// flashes for low-end devices and motion-sensitive players.
class VfxConfig {
  final double particleScale;
  final double shakeScale;
  final bool flashes;

  const VfxConfig({this.particleScale = 1, this.shakeScale = 1, this.flashes = true});

  static const full = VfxConfig();
  static const reduced = VfxConfig(particleScale: 0.35, shakeScale: 0.3, flashes: false);

  int particles(int base) => math.max(3, (base * particleScale).round());
}

Paint _glow(Color color, double sigma) => glowPaint(color, sigma);

/// Text drawn once into an image (shadow included), then blitted with a
/// paint alpha. Fading text this way avoids a full-screen `saveLayer` and a
/// shadow blur on every frame, which is what made damage numbers and the
/// parry letter burst stutter on Android GPUs.
class TextSprite {
  final Image image;

  /// Logical size, shadow padding included.
  final double width;
  final double height;

  const TextSprite._(this.image, this.width, this.height);

  static final Map<String, TextSprite> _cache = {};
  static const int _cacheLimit = 120;
  static const double _pad = 12;

  static double get _ratio {
    try {
      return PlatformDispatcher.instance.views.first.devicePixelRatio.clamp(1.0, 3.0);
    } on Object {
      return 2;
    }
  }

  static TextSprite of(String text, TextStyle style) {
    final key = '$text\u0000${style.hashCode}';
    final cached = _cache.remove(key);
    if (cached != null) {
      _cache[key] = cached; // most recently used last
      return cached;
    }
    final painter = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr)..layout();
    final width = painter.width + _pad * 2;
    final height = painter.height + _pad * 2;
    final ratio = _ratio;
    final recorder = PictureRecorder();
    final canvas = Canvas(recorder)..scale(ratio);
    painter.paint(canvas, const Offset(_pad, _pad));
    painter.dispose();
    final picture = recorder.endRecording();
    final image = picture.toImageSync(math.max(1, (width * ratio).ceil()), math.max(1, (height * ratio).ceil()));
    picture.dispose();
    final sprite = TextSprite._(image, width, height);
    // Evicted images are left to the garbage collector: a component may still
    // be drawing one this frame.
    if (_cache.length >= _cacheLimit) _cache.remove(_cache.keys.first);
    _cache[key] = sprite;
    return sprite;
  }

  static final Paint _paint = Paint()..filterQuality = FilterQuality.medium;

  /// Draws the text with its [anchor] point (0..1 of the text box) at [at].
  void draw(Canvas canvas, Offset at, {double alpha = 1, double scale = 1, Offset anchor = const Offset(0.5, 0.5)}) {
    if (alpha <= 0.01) return;
    final w = width * scale;
    final h = height * scale;
    _paint.color = Color.fromRGBO(255, 255, 255, alpha.clamp(0.0, 1.0));
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Rect.fromLTWH(at.dx - w * anchor.dx, at.dy - h * anchor.dy, w, h),
      _paint,
    );
  }
}

/// Runs callbacks after a delay in game time (pauses with the game).
class Sequencer extends Component {
  final List<({double at, void Function() run})> _queue = [];
  double _time = 0;

  void after(double seconds, void Function() run) => _queue.add((at: _time + seconds, run: run));

  @override
  void update(double dt) {
    _time += dt;
    if (_queue.isEmpty) return;
    final due = _queue.where((item) => item.at <= _time).toList();
    if (due.isEmpty) return;
    _queue.removeWhere((item) => item.at <= _time);
    for (final item in due) {
      item.run();
    }
  }
}

/// Screen shake applied to the scene root.
class Shaker extends Component {
  final PositionComponent target;
  final double scale;
  final math.Random _random = math.Random();
  double _time = 0;
  double _strength = 0;

  Shaker(this.target, {this.scale = 1});

  void shake(double strength, {double duration = 0.3}) {
    _strength = math.max(_strength, strength * scale);
    _time = math.max(_time, duration);
  }

  @override
  void update(double dt) {
    if (_time <= 0) {
      if (target.position.x != 0 || target.position.y != 0) target.position.setZero();
      return;
    }
    _time -= dt;
    final falloff = (_time / 0.3).clamp(0.0, 1.0);
    target.position.setValues(
      (_random.nextDouble() * 2 - 1) * _strength * falloff,
      (_random.nextDouble() * 2 - 1) * _strength * falloff,
    );
    if (_time <= 0) _strength = 0;
  }
}

/// A glowing projectile with a short trail, optionally carrying a word.
class SpellOrb extends PositionComponent {
  final Color color;
  final double radius;
  final String? label;
  /// Recent positions for the trail (ring buffer), readable by subclasses.
  final List<Vector2> trail = List.generate(10, (_) => Vector2.zero());
  int trailHead = 0;
  int trailCount = 0;

  Vector2? _from;
  Vector2? _to;
  double _flight = 0;
  double _duration = 1;
  double _arc = 0;
  void Function()? _onArrive;
  double _time = 0;
  bool _hovering = true;
  TextSprite? _labelSprite;
  final Paint _trailPaint = Paint();
  final Paint _bodyPaint = Paint();
  final Paint _corePaint = Paint()..color = const Color(0xFFFFFFFF);

  /// Word label above the orb, readable by subclasses.
  TextSprite? get labelSprite => _labelSprite;

  SpellOrb({required this.color, required this.radius, this.label, required Vector2 position})
      : super(position: position, anchor: Anchor.center, priority: 20) {
    final text = label;
    if (text != null) {
      _labelSprite = TextSprite.of(
        text,
        TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: math.max(12, radius * 0.9),
          fontWeight: FontWeight.w700,
          color: const Color(0xFFFFFFFF),
          letterSpacing: 1,
          shadows: [Shadow(color: color, blurRadius: 8)],
        ),
      );
    }
  }


  void launch(Vector2 target, {double duration = 0.45, double arc = 0, void Function()? onArrive}) {
    _from = position.clone();
    _to = target.clone();
    _flight = 0;
    _duration = duration;
    _arc = arc;
    _onArrive = onArrive;
    _hovering = false;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    trail[trailHead].setFrom(position);
    trailHead = (trailHead + 1) % trail.length;
    trailCount = math.min(trailCount + 1, trail.length);
    if (_hovering) {
      position.y += math.sin(_time * 6) * 0.25;
      return;
    }
    final from = _from;
    final to = _to;
    if (from == null || to == null) return;
    _flight += dt / _duration;
    final t = _flight.clamp(0.0, 1.0);
    final eased = t * t * (3 - 2 * t);
    position
      ..setFrom(from + (to - from) * eased)
      ..y -= math.sin(t * math.pi) * _arc;
    if (_flight >= 1) {
      final callback = _onArrive;
      _onArrive = null;
      removeFromParent();
      callback?.call();
    }
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    for (var i = 0; i < trailCount; i++) {
      final index = (trailHead - 1 - i) % trail.length;
      final point = trail[index < 0 ? index + trail.length : index];
      final local = Offset(point.x - position.x, point.y - position.y) + center;
      final fade = 1 - i / trail.length;
      _trailPaint.color = color.withValues(alpha: 0.35 * fade);
      canvas.drawCircle(local, radius * 0.6 * fade, _trailPaint);
    }
    final pulse = 1 + math.sin(_time * 12) * 0.08;
    glowCircle(canvas, center, radius * 1.9 * pulse, color.withValues(alpha: 0.55), radius * 0.8);
    canvas.drawCircle(center, radius * pulse, _bodyPaint..color = color);
    canvas.drawCircle(center, radius * 0.5, _corePaint);
    _labelSprite?.draw(canvas, Offset(center.dx, center.dy - radius * 2.1), anchor: const Offset(0.5, 1));
  }
}

/// Expanding ring used for impacts and phase changes.
class Shockwave extends PositionComponent {
  final Color color;
  final double maxRadius;
  final double duration;
  double _t = 0;

  Shockwave({required Vector2 position, required this.color, required this.maxRadius, this.duration = 0.45})
      : super(position: position, anchor: Anchor.center, priority: 25);

  @override
  void update(double dt) {
    _t += dt / duration;
    if (_t >= 1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = _t.clamp(0.0, 1.0);
    canvas.drawCircle(
      Offset.zero,
      maxRadius * (0.2 + 0.8 * t),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6 * (1 - t) + 1
        ..color = color.withValues(alpha: (1 - t) * 0.9),
    );
  }
}

/// Radial particle burst.
ParticleSystemComponent burst({
  required Vector2 at,
  required Color color,
  required int count,
  double speed = 220,
  double lifespan = 0.6,
  double size = 3,
}) {
  final random = math.Random();
  // One paint per system, mutated per particle: no allocation per frame.
  final paint = Paint();
  return ParticleSystemComponent(
    position: at,
    priority: 30,
    particle: Particle.generate(
      count: count,
      lifespan: lifespan,
      generator: (i) {
        final angle = random.nextDouble() * math.pi * 2;
        final velocity = Vector2(math.cos(angle), math.sin(angle)) * (speed * (0.4 + random.nextDouble() * 0.8));
        return AcceleratedParticle(
          speed: velocity,
          acceleration: Vector2(0, 220),
          child: ComputedParticle(
            renderer: (canvas, particle) {
              final fade = 1 - particle.progress;
              canvas.drawCircle(Offset.zero, size * (0.5 + fade),
                  paint..color = color.withValues(alpha: fade));
            },
          ),
        );
      },
    ),
  );
}

/// Grey puff for failed spells.
ParticleSystemComponent fizzle({required Vector2 at, required int count}) {
  final random = math.Random();
  // One paint per system, mutated per particle: no allocation per frame.
  final paint = Paint();
  return ParticleSystemComponent(
    position: at,
    priority: 30,
    particle: Particle.generate(
      count: count,
      lifespan: 0.7,
      generator: (i) => AcceleratedParticle(
        speed: Vector2((random.nextDouble() - 0.5) * 80, -40 - random.nextDouble() * 60),
        acceleration: Vector2(0, -30),
        child: ComputedParticle(
          renderer: (canvas, particle) {
            final fade = 1 - particle.progress;
            canvas.drawCircle(Offset.zero, 4 + particle.progress * 10,
                paint..color = const Color(0xFF9A98B0).withValues(alpha: fade * 0.45));
          },
        ),
      ),
    ),
  );
}

/// Floating combat text (damage numbers, "Blocked!").
class FloatingText extends PositionComponent {
  final String text;
  final TextSprite _sprite;
  double _t = 0;

  FloatingText({required this.text, required Vector2 position, required Color color, double fontSize = 22})
      : _sprite = TextSprite.of(
          text,
          TextStyle(
            fontFamily: 'Ubuntu',
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color,
            shadows: const [Shadow(color: Color(0xCC000000), blurRadius: 6, offset: Offset(0, 2))],
          ),
        ),
        super(position: position, anchor: Anchor.center, priority: 40);

  @override
  void update(double dt) {
    _t += dt;
    position.y -= dt * 46;
    if (_t > 0.95) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final scale = _t < 0.12 ? 0.6 + _t / 0.12 * 0.5 : 1.1 - math.min(0.1, (_t - 0.12));
    final alpha = _t > 0.7 ? 1 - (_t - 0.7) / 0.25 : 1.0;
    _sprite.draw(canvas, Offset.zero, alpha: alpha, scale: scale);
  }
}

/// Full-scene colour flash.
class ScreenFlash extends PositionComponent {
  final Color color;
  final double duration;
  double _t = 0;

  ScreenFlash({required Vector2 size, required this.color, this.duration = 0.35})
      : super(size: size, priority: 100);

  @override
  void update(double dt) {
    _t += dt / duration;
    if (_t >= 1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(size.toRect(), Paint()..color = color.withValues(alpha: color.a * (1 - _t).clamp(0.0, 1.0)));
  }
}

/// Enemy protection: a visible barrier with strength segments. Each correct
/// similar-meaning hit adds cracks; the last one shatters it into shards.
class ShieldBubble extends PositionComponent {
  final Color color;
  double radius;
  final VfxConfig vfx;
  double _raise = 0;
  bool _active = false;
  double _pulse = 0;
  double _ripple = 0;
  double _time = 0;
  int _strength = 0;
  int _remaining = 0;

  ShieldBubble({required this.color, required this.radius, required this.vfx})
      : super(anchor: Anchor.center, priority: 15);

  bool get isActive => _active;

  void raise({int strength = 1}) {
    _active = true;
    _strength = strength;
    _remaining = strength;
    _pulse = 1;
  }

  /// A rejected spell: the barrier flares.
  void reject() => _pulse = 1;

  /// A successful hit that does not break the barrier yet.
  void hit() {
    if (!_active) return;
    _remaining = math.max(0, _remaining - 1);
    _ripple = 1;
    _pulse = 0.6;
  }

  void shatter() {
    if (!_active) return;
    _active = false;
    _remaining = 0;
    final random = math.Random();
    final count = vfx.particles(22);
    parent?.add(ParticleSystemComponent(
      position: position.clone(),
      priority: 30,
      particle: Particle.generate(
        count: count,
        lifespan: 0.9,
        generator: (i) {
          final angle = i / count * math.pi * 2 + random.nextDouble() * 0.3;
          final spin = random.nextDouble() * 8 - 4;
          final size = 5 + random.nextDouble() * 6;
          return AcceleratedParticle(
            position: Vector2(math.cos(angle), math.sin(angle)) * radius,
            speed: Vector2(math.cos(angle), math.sin(angle)) * (180 + random.nextDouble() * 160),
            acceleration: Vector2(0, 420),
            child: ComputedParticle(
              renderer: (canvas, particle) {
                final fade = 1 - particle.progress;
                canvas.save();
                canvas.rotate(particle.progress * spin);
                canvas.drawPath(
                  Path()
                    ..moveTo(0, -size)
                    ..lineTo(size * 0.7, size * 0.5)
                    ..lineTo(-size * 0.6, size * 0.7)
                    ..close(),
                  Paint()..color = Color.lerp(color, const Color(0xFFFFFFFF), 0.4)!.withValues(alpha: fade),
                );
                canvas.restore();
              },
            ),
          );
        },
      ),
    ));
  }

  void lower() {
    _active = false;
    _remaining = 0;
  }

  @override
  void update(double dt) {
    _time += dt;
    _raise = (_raise + (_active ? dt * 4 : -dt * 5)).clamp(0.0, 1.0);
    _pulse = math.max(0, _pulse - dt * 2.5);
    _ripple = math.max(0, _ripple - dt * 1.8);
  }

  @override
  void render(Canvas canvas) {
    if (_raise <= 0.01) return;
    final r = radius * (0.7 + 0.3 * _raise) * (1 + _pulse * 0.08);
    final alpha = _raise;
    canvas.drawCircle(
      Offset.zero,
      r,
      Paint()
        ..shader = Gradient.radial(Offset.zero, r, [
          color.withValues(alpha: 0.04 * alpha),
          color.withValues(alpha: (0.2 + _pulse * 0.3) * alpha),
          color.withValues(alpha: 0.55 * alpha),
        ], [0.0, 0.78, 1.0]),
    );
    // Hexagonal rune lattice.
    final lattice = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = color.withValues(alpha: 0.35 * alpha);
    for (var ring = 1; ring <= 2; ring++) {
      final path = Path();
      for (var k = 0; k <= 6; k++) {
        final angle = k * math.pi / 3 + _time * 0.2 * (ring.isEven ? -1 : 1);
        final point = Offset(math.cos(angle), math.sin(angle)) * r * (ring / 2.6);
        k == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path, lattice);
    }
    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3 + _pulse * 3
      ..color = color.withValues(alpha: 0.95 * alpha);
    // Strength segments around the rim (lit = remaining).
    final segments = math.max(1, _strength);
    const gap = 0.12;
    final sweep = math.pi * 2 / segments;
    for (var k = 0; k < segments; k++) {
      final lit = k < _remaining;
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        -math.pi / 2 + k * sweep + gap / 2,
        sweep - gap,
        false,
        ring..color = (lit ? color : const Color(0xFFFFFFFF)).withValues(alpha: (lit ? 0.95 : 0.25) * alpha),
      );
    }
    if (_ripple > 0) {
      canvas.drawCircle(
        Offset.zero,
        r * (1 + (1 - _ripple) * 0.35),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 * _ripple
          ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.8 * _ripple),
      );
    }
    // Progressive cracks: more cracks as strength drops.
    final damage = _strength - _remaining;
    if (damage > 0) {
      final crackPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = const Color(0xFFFFFFFF).withValues(alpha: 0.9 * alpha);
      final cracks = damage * 3;
      for (var i = 0; i < cracks; i++) {
        final angle = i * 2.17 + 0.4;
        final path = Path()..moveTo(math.cos(angle) * r * 0.15, math.sin(angle) * r * 0.15);
        for (var k = 1; k <= 4; k++) {
          final jitter = (k.isEven ? 0.22 : -0.18);
          final point = Offset(math.cos(angle + jitter), math.sin(angle + jitter)) * (r * (0.15 + k * 0.21));
          path.lineTo(point.dx, point.dy);
        }
        canvas.drawPath(path, crackPaint);
      }
    }
  }
}

/// Wavy link between the player's word and the enemy shield.
class ResonanceBeam extends Component {
  final Vector2 Function() from;
  final Vector2 Function() to;
  final Color color;
  final double duration;
  final bool bounce;
  double _t = 0;

  ResonanceBeam({
    required this.from,
    required this.to,
    required this.color,
    this.duration = 0.8,
    this.bounce = false,
  }) : super(priority: 18);

  @override
  void update(double dt) {
    _t += dt / duration;
    if (_t >= 1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final a = from();
    final b = to();
    final t = _t.clamp(0.0, 1.0);
    final reach = bounce ? math.sin(t * math.pi) * 0.75 : math.min(1.0, t * 2.2);
    final alpha = t > 0.75 ? (1 - t) / 0.25 : 1.0;
    final direction = b - a;
    final length = direction.length;
    if (length <= 0) return;
    final normal = Vector2(-direction.y, direction.x)..normalize();
    for (var strand = 0; strand < 2; strand++) {
      final path = Path()..moveTo(a.x, a.y);
      const steps = 28;
      for (var i = 1; i <= steps; i++) {
        final f = i / steps * reach;
        final wave = math.sin(f * 14 + _t * 18 + strand * math.pi) * 10 * math.sin(f * math.pi);
        final point = a + direction * f + normal * wave;
        path.lineTo(point.x, point.y);
      }
      canvas.drawPath(
        path,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strand == 0 ? 4 : 2
          ..strokeCap = StrokeCap.round
          ..color = (strand == 0 ? color : const Color(0xFFFFFFFF)).withValues(alpha: alpha * (strand == 0 ? 0.85 : 0.7)),
      );
    }
  }
}

/// Thick energy beam for incantations and finishing spells.
class BeamStrike extends Component {
  final Vector2 from;
  final Vector2 to;
  final Color color;
  final double width;
  final double duration;
  double _t = 0;

  BeamStrike({required this.from, required this.to, required this.color, this.width = 26, this.duration = 0.7})
      : super(priority: 22);

  @override
  void update(double dt) {
    _t += dt / duration;
    if (_t >= 1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = _t.clamp(0.0, 1.0);
    final grow = math.min(1.0, t * 5);
    final fade = t > 0.6 ? (1 - t) / 0.4 : 1.0;
    final end = from + (to - from) * grow;
    final w = width * (0.6 + 0.4 * math.sin(t * math.pi)) * fade;
    canvas.drawLine(from.toOffset(), end.toOffset(),
        _glow(color.withValues(alpha: 0.7 * fade), w * 0.6)
          ..strokeWidth = w * 1.8
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(from.toOffset(), end.toOffset(),
        Paint()
          ..color = color.withValues(alpha: fade)
          ..strokeWidth = w
          ..strokeCap = StrokeCap.round);
    canvas.drawLine(from.toOffset(), end.toOffset(),
        Paint()
          ..color = const Color(0xFFFFFFFF).withValues(alpha: fade)
          ..strokeWidth = w * 0.35
          ..strokeCap = StrokeCap.round);
  }
}

/// Rotating rune circle that charges around the caster.
class RuneCircle extends PositionComponent {
  final Color color;
  final double radius;
  double charge = 0;
  bool _collapsing = false;
  bool _releasing = false;
  double _time = 0;

  RuneCircle({required this.color, required this.radius, required Vector2 position})
      : super(position: position, anchor: Anchor.center, priority: 12);

  void release() => _releasing = true;

  void collapse() => _collapsing = true;

  @override
  void update(double dt) {
    _time += dt;
    if (_releasing) {
      charge += dt * 4;
      if (charge > 2) removeFromParent();
    } else if (_collapsing) {
      charge -= dt * 3;
      if (charge <= 0) removeFromParent();
    } else {
      charge = math.min(1, charge + dt * 2);
    }
  }

  @override
  void render(Canvas canvas) {
    final c = charge.clamp(0.0, 1.0);
    final expand = _releasing ? 1 + (charge - 1).clamp(0.0, 1.0) * 0.6 : 1.0;
    final alpha = _releasing ? (2 - charge).clamp(0.0, 1.0) : c;
    final r = radius * (0.6 + 0.4 * c) * expand;
    canvas.save();
    canvas.scale(1, 0.38);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..color = color.withValues(alpha: 0.85 * alpha);
    canvas.drawCircle(Offset.zero, r, _glow(color.withValues(alpha: 0.35 * alpha), 8)..style = PaintingStyle.stroke..strokeWidth = 8);
    canvas.drawCircle(Offset.zero, r, paint);
    canvas.drawCircle(Offset.zero, r * 0.72, paint..strokeWidth = 1.5);
    canvas.rotate(_time * 1.5);
    for (var i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final p = Offset(math.cos(angle), math.sin(angle)) * r * 0.86;
      canvas.drawRect(Rect.fromCenter(center: p, width: 6, height: 6), Paint()..color = color.withValues(alpha: alpha));
    }
    canvas.restore();
  }
}

/// Soft aura while the player is in Word Flow (or protected by a Ward).
class AuraComponent extends PositionComponent {
  final Color color;
  final double radius;
  bool active = false;
  double _level = 0;
  double _time = 0;

  AuraComponent({required this.color, required this.radius}) : super(anchor: Anchor.center, priority: 8);

  @override
  void update(double dt) {
    _time += dt;
    _level = (_level + (active ? dt * 3 : -dt * 3)).clamp(0.0, 1.0);
  }

  @override
  void render(Canvas canvas) {
    if (_level <= 0.01) return;
    final pulse = 1 + math.sin(_time * 5) * 0.06;
    canvas.drawCircle(
      Offset.zero,
      radius * pulse,
      Paint()
        ..shader = Gradient.radial(Offset.zero, radius * pulse, [
          color.withValues(alpha: 0.35 * _level),
          color.withValues(alpha: 0),
        ]),
    );
  }
}


/// Word that breaks into flying letters (spell collisions).
class LetterBurst extends PositionComponent {
  final String word;
  final Color color;
  final List<_Letter> _letters = [];
  double _t = 0;

  LetterBurst({required this.word, required this.color, required Vector2 position})
      : super(position: position, anchor: Anchor.center, priority: 35) {
    final random = math.Random();
    final letters = word.toUpperCase().split('').where((char) => char.trim().isNotEmpty).toList();
    for (var i = 0; i < letters.length; i++) {
      final angle = (i / math.max(1, letters.length)) * math.pi * 2 + random.nextDouble();
      _letters.add(_Letter(
        letters[i],
        Vector2((i - letters.length / 2) * 14, 0),
        Vector2(math.cos(angle), math.sin(angle) - 0.6) * (140 + random.nextDouble() * 120),
        random.nextDouble() * 6 - 3,
      ));
    }
  }

  TextSprite _sprite(String char) => TextSprite.of(
        char,
        TextStyle(
          fontFamily: 'Ubuntu',
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFFFFFFF),
          shadows: [Shadow(color: color, blurRadius: 10)],
        ),
      );

  @override
  void update(double dt) {
    _t += dt;
    for (final letter in _letters) {
      letter.position.add(letter.velocity * dt);
      letter.velocity.y += 380 * dt;
    }
    if (_t > 0.9) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final alpha = (1 - _t / 0.9).clamp(0.0, 1.0);
    for (final letter in _letters) {
      canvas.save();
      canvas.translate(letter.position.x, letter.position.y);
      canvas.rotate(letter.spin * _t);
      (letter.sprite ??= _sprite(letter.char)).draw(canvas, Offset.zero, alpha: alpha);
      canvas.restore();
    }
  }
}

class _Letter {
  final String char;
  final Vector2 position;
  final Vector2 velocity;
  final double spin;
  TextSprite? sprite;

  _Letter(this.char, this.position, this.velocity, this.spin);
}

/// Darkens the arena backdrop for Special and Critical moments.
class ArenaDim extends PositionComponent {
  double _level = 0;
  double _target = 0;
  Color tint = const Color(0xFF05060F);

  ArenaDim() : super(priority: -5);

  void dim(double amount, {Color color = const Color(0xFF05060F)}) {
    _target = amount;
    tint = color;
  }

  @override
  void update(double dt) {
    _level += (_target - _level) * math.min(1, dt * 6);
  }

  @override
  void render(Canvas canvas) {
    if (_level <= 0.01) return;
    canvas.drawRect(size.toRect(), Paint()..color = tint.withValues(alpha: _level));
  }
}

/// Smooth camera zoom around a focus point (applied to the stage layer).
class Zoomer extends Component {
  final PositionComponent stage;
  double _scale = 1;
  double _target = 1;
  Vector2 _focus = Vector2.zero();

  Zoomer(this.stage);

  void zoomTo(double scale, Vector2 focus) {
    _target = scale;
    _focus = focus.clone();
  }

  void reset() => _target = 1;

  @override
  void update(double dt) {
    _scale += (_target - _scale) * math.min(1, dt * 5);
    stage.scale.setAll(_scale);
    stage.position.setValues(_focus.x * (1 - _scale), _focus.y * (1 - _scale));
  }
}

/// Telegraph above an enemy: "!" for a coming Critical, a star for a Special.
class IntentMarker extends PositionComponent {
  final Color color;
  final bool critical;
  double _time = 0;

  IntentMarker({required this.color, required this.critical}) : super(anchor: Anchor.center, priority: 26);

  @override
  void update(double dt) => _time += dt;

  @override
  void render(Canvas canvas) {
    final bob = math.sin(_time * 4) * 4;
    canvas.save();
    canvas.translate(0, bob);
    glowCircle(canvas, Offset.zero, 16, color.withValues(alpha: 0.45), 8);
    canvas.drawCircle(Offset.zero, 12, Paint()..color = const Color(0xE60A0D1E));
    canvas.drawCircle(Offset.zero, 12, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..color = color);
    final mark = Paint()..color = color;
    if (critical) {
      canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(-2, -7, 4, 9), const Radius.circular(2)), mark);
      canvas.drawCircle(const Offset(0, 5.5), 2, mark);
    } else {
      final path = Path();
      for (var i = 0; i < 10; i++) {
        final r = i.isEven ? 7.0 : 3.0;
        final angle = -math.pi / 2 + i * math.pi / 5;
        final point = Offset(math.cos(angle) * r, math.sin(angle) * r);
        i == 0 ? path.moveTo(point.dx, point.dy) : path.lineTo(point.dx, point.dy);
      }
      canvas.drawPath(path..close(), mark);
    }
    canvas.restore();
  }
}

/// Ground ring marking the current target in two-enemy fights.
class TargetRing extends PositionComponent {
  final Color color;
  double ringWidth;
  bool visible = false;
  double _time = 0;

  TargetRing({required this.color, required this.ringWidth}) : super(anchor: Anchor.center, priority: 5);

  @override
  void update(double dt) => _time += dt;

  @override
  void render(Canvas canvas) {
    if (!visible) return;
    final pulse = 1 + math.sin(_time * 5) * 0.05;
    final rect = Rect.fromCenter(center: Offset.zero, width: ringWidth * pulse, height: ringWidth * 0.28 * pulse);
    canvas.drawOval(rect, _glow(color.withValues(alpha: 0.35), 6));
    canvas.drawOval(rect, Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color.withValues(alpha: 0.9));
  }
}

/// Little orbiting stars over a staggered enemy.
class StaggerStars extends PositionComponent {
  double _time = 0;
  double life;

  StaggerStars({required Vector2 position, this.life = 2.2}) : super(position: position, anchor: Anchor.center, priority: 27);

  @override
  void update(double dt) {
    _time += dt;
    if (_time > life) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()..color = const Color(0xFFFFD166).withValues(alpha: (1 - _time / life).clamp(0.0, 1.0));
    for (var i = 0; i < 3; i++) {
      final angle = _time * 4 + i * math.pi * 2 / 3;
      canvas.drawCircle(Offset(math.cos(angle) * 22, math.sin(angle) * 7), 4, paint);
    }
  }
}

// -----------------------------------------------------------------------------
// Enemy magic families: one parameterised projectile + impact instead of a
// bespoke pipeline per enemy. The family comes from `EnemyBehaviour.element`.
// -----------------------------------------------------------------------------

enum ElementStyle {
  slash,
  rock,
  arcane,
  ink,
  spark,
  smash,
  thorn,
  frost,
  steel,
  glint;

  static ElementStyle parse(String? raw) =>
      ElementStyle.values.firstWhere((value) => value.name == raw, orElse: () => ElementStyle.arcane);

  /// Projectile shape and impact character.
  bool get heavy => this == rock || this == smash;
  bool get fast => this == spark || this == glint || this == slash;

  /// Shake strength on a landed hit, before the critical multiplier.
  double get shake => switch (this) {
        rock || smash => 10,
        steel || slash => 6,
        thorn || frost => 5,
        _ => 4,
      };

  double get flightSeconds => switch (this) {
        rock || smash => 0.6,
        spark || glint || slash => 0.3,
        _ => 0.45,
      };

  double get arc => switch (this) {
        rock => 48,
        smash => 10,
        spark || glint => 6,
        _ => 26,
      };
}

/// Projectile whose look follows the caster's magic family.
class ElementBolt extends SpellOrb {
  final ElementStyle style;
  double _spin = 0;
  final double _spinSpeed;

  ElementBolt({
    required this.style,
    required super.color,
    required super.radius,
    super.label,
    required super.position,
  }) : _spinSpeed = style == ElementStyle.rock ? 6 : (style == ElementStyle.steel || style == ElementStyle.slash ? 14 : 3);

  @override
  void update(double dt) {
    super.update(dt);
    _spin += dt * _spinSpeed;
  }

  @override
  void render(Canvas canvas) {
    final center = Offset(size.x / 2, size.y / 2);
    switch (style) {
      case ElementStyle.rock:
        // Tumbling boulder with a dust trail.
        for (var i = 0; i < trailCount; i += 2) {
          final index = (trailHead - 1 - i) % trail.length;
          final point = trail[index < 0 ? index + trail.length : index];
          final local = Offset(point.x - position.x, point.y - position.y) + center;
          final fade = 1 - i / trail.length;
          canvas.drawCircle(local, radius * 0.5 * fade, Paint()..color = const Color(0xFF9C8B74).withValues(alpha: 0.25 * fade));
        }
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(_spin);
        final rock = Path();
        for (var k = 0; k < 7; k++) {
          final angle = k * math.pi * 2 / 7;
          final r = radius * (k.isEven ? 1.15 : 0.9);
          final p = Offset(math.cos(angle) * r, math.sin(angle) * r);
          k == 0 ? rock.moveTo(p.dx, p.dy) : rock.lineTo(p.dx, p.dy);
        }
        rock.close();
        canvas.drawPath(rock, Paint()..color = const Color(0xFF6E6257));
        canvas.drawPath(rock, Paint()..color = color.withValues(alpha: 0.35)..style = PaintingStyle.stroke..strokeWidth = 2);
        canvas.drawCircle(Offset(-radius * 0.3, -radius * 0.3), radius * 0.35, Paint()..color = const Color(0xFF8E8275));
        canvas.restore();
      case ElementStyle.slash:
      case ElementStyle.steel:
        // Crescent blade of light.
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(_spin);
        final blade = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = radius * 0.5
          ..strokeCap = StrokeCap.round
          ..color = color;
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: radius * 1.4), 0.4, 2.3, false,
            _glow(color.withValues(alpha: 0.6), radius * 0.5)..style = PaintingStyle.stroke..strokeWidth = radius);
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: radius * 1.4), 0.4, 2.3, false, blade);
        canvas.drawArc(Rect.fromCircle(center: Offset.zero, radius: radius * 1.4), 0.6, 1.9, false,
            blade..color = const Color(0xFFFFFFFF)..strokeWidth = radius * 0.2);
        canvas.restore();
      case ElementStyle.ink:
        // Wobbling blob that drips.
        final wobble = 1 + math.sin(_spin * 9) * 0.15;
        canvas.drawOval(Rect.fromCenter(center: center, width: radius * 2.4 * wobble, height: radius * 1.9 / wobble),
            _glow(color.withValues(alpha: 0.5), radius * 0.5));
        canvas.drawOval(Rect.fromCenter(center: center, width: radius * 2.2 * wobble, height: radius * 1.8 / wobble),
            Paint()..color = const Color(0xFF1C1B2E));
        canvas.drawCircle(center + Offset(radius * 0.5, radius * 0.9), radius * 0.35, Paint()..color = const Color(0xFF1C1B2E));
        canvas.drawCircle(center - Offset(radius * 0.4, radius * 0.3), radius * 0.3, Paint()..color = color.withValues(alpha: 0.7));
      case ElementStyle.spark:
      case ElementStyle.glint:
        // Jittery spark with a star flare.
        final jitter = Offset(math.sin(_spin * 31) * 2, math.cos(_spin * 27) * 2);
        canvas.save();
        canvas.translate(center.dx + jitter.dx, center.dy + jitter.dy);
        canvas.rotate(_spin * 4);
        final star = Path();
        for (var i = 0; i < 8; i++) {
          final r = i.isEven ? radius * 1.5 : radius * 0.45;
          final angle = i * math.pi / 4;
          final p = Offset(math.cos(angle) * r, math.sin(angle) * r);
          i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
        }
        star.close();
        canvas.drawPath(star, _glow(color.withValues(alpha: 0.6), radius * 0.6));
        canvas.drawPath(star, Paint()..color = color);
        canvas.drawCircle(Offset.zero, radius * 0.4, Paint()..color = const Color(0xFFFFFFFF));
        canvas.restore();
      case ElementStyle.smash:
        // Heavy fist-shaped shock.
        glowCircle(canvas, center, radius * 1.8, color.withValues(alpha: 0.5), radius);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: center, width: radius * 2.2, height: radius * 1.9), Radius.circular(radius * 0.5)),
            Paint()..color = color);
        canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: center - Offset(0, radius * 0.3), width: radius * 1.6, height: radius * 0.8), Radius.circular(radius * 0.3)),
            Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.6));
      case ElementStyle.thorn:
        // Spinning bramble ring.
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(_spin * 2);
        glowCircle(canvas, Offset.zero, radius * 1.6, color.withValues(alpha: 0.5), radius * 0.6);
        final thorn = Paint()..color = const Color(0xFF3F6B2A);
        for (var i = 0; i < 6; i++) {
          final angle = i * math.pi / 3;
          final path = Path()
            ..moveTo(math.cos(angle) * radius * 0.5, math.sin(angle) * radius * 0.5)
            ..lineTo(math.cos(angle + 0.3) * radius * 0.9, math.sin(angle + 0.3) * radius * 0.9)
            ..lineTo(math.cos(angle) * radius * 1.7, math.sin(angle) * radius * 1.7)
            ..close();
          canvas.drawPath(path, thorn);
        }
        canvas.drawCircle(Offset.zero, radius * 0.6, Paint()..color = color);
        canvas.restore();
      case ElementStyle.frost:
        // Ice shard with a cold halo.
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(_spin);
        glowCircle(canvas, Offset.zero, radius * 1.9, const Color(0xFF9FE8FF).withValues(alpha: 0.45), radius * 0.8);
        final shard = Path()
          ..moveTo(0, -radius * 1.8)
          ..lineTo(radius * 0.7, 0)
          ..lineTo(0, radius * 1.8)
          ..lineTo(-radius * 0.7, 0)
          ..close();
        canvas.drawPath(shard, Paint()..color = const Color(0xFFDFF8FF));
        canvas.drawPath(shard, Paint()..color = color.withValues(alpha: 0.8)..style = PaintingStyle.stroke..strokeWidth = 1.5);
        canvas.restore();
      case ElementStyle.arcane:
        super.render(canvas);
        return;
    }
    labelSprite?.draw(canvas, Offset(center.dx, center.dy - radius * 2.1), anchor: const Offset(0.5, 1));
  }
}

/// Impact matching the magic family: rock throws debris, smash sends a ground
/// shockwave, frost scatters shards, ink splashes, sparks crackle.
List<Component> elementImpact({
  required ElementStyle style,
  required Vector2 at,
  required Color color,
  required VfxConfig vfx,
  bool heavy = false,
}) {
  final scale = heavy ? 1.6 : 1.0;
  switch (style) {
    case ElementStyle.rock:
      return [
        debris(at: at, color: const Color(0xFF8E8275), count: vfx.particles((14 * scale).round())),
        burst(at: at, color: color, count: vfx.particles((10 * scale).round()), speed: 160, size: 2.5),
        Shockwave(position: at, color: const Color(0xFFC9B9A2), maxRadius: 110 * scale, duration: 0.45),
      ];
    case ElementStyle.smash:
      return [
        GroundShock(position: at + Vector2(0, 40), color: color, span: 220 * scale),
        debris(at: at, color: const Color(0xFF6E6257), count: vfx.particles((8 * scale).round())),
        burst(at: at, color: color, count: vfx.particles((14 * scale).round()), speed: 260),
      ];
    case ElementStyle.frost:
      return [
        shards(at: at, color: const Color(0xFFDFF8FF), count: vfx.particles((12 * scale).round())),
        Shockwave(position: at, color: const Color(0xFF9FE8FF), maxRadius: 100 * scale, duration: 0.5),
      ];
    case ElementStyle.ink:
      return [
        splash(at: at, color: const Color(0xFF1C1B2E), count: vfx.particles((16 * scale).round())),
        burst(at: at, color: color, count: vfx.particles((6 * scale).round()), speed: 120, size: 2),
      ];
    case ElementStyle.spark:
    case ElementStyle.glint:
      return [
        burst(at: at, color: color, count: vfx.particles((18 * scale).round()), speed: 340, lifespan: 0.35, size: 2),
        burst(at: at, color: const Color(0xFFFFFFFF), count: vfx.particles(6), speed: 200, lifespan: 0.25, size: 1.5),
      ];
    case ElementStyle.slash:
    case ElementStyle.steel:
      return [
        SlashMark(position: at, color: color, length: 90 * scale),
        burst(at: at, color: color, count: vfx.particles((12 * scale).round()), speed: 240, lifespan: 0.4, size: 2),
      ];
    case ElementStyle.thorn:
      return [
        shards(at: at, color: const Color(0xFF6FBF4A), count: vfx.particles((10 * scale).round())),
        burst(at: at, color: color, count: vfx.particles((10 * scale).round()), speed: 200),
      ];
    case ElementStyle.arcane:
      return [
        burst(at: at, color: color, count: vfx.particles((16 * scale).round()), speed: 220),
        Shockwave(position: at, color: color, maxRadius: 90 * scale),
      ];
  }
}

/// Tumbling rock chips that fall with gravity.
ParticleSystemComponent debris({required Vector2 at, required Color color, required int count}) {
  final random = math.Random();
  // One paint per system, mutated per particle: no allocation per frame.
  final paint = Paint();
  return ParticleSystemComponent(
    position: at,
    priority: 30,
    particle: Particle.generate(
      count: count,
      lifespan: 0.8,
      generator: (i) {
        final angle = -math.pi * (0.15 + random.nextDouble() * 0.7);
        final speed = 160 + random.nextDouble() * 220;
        final size = 3 + random.nextDouble() * 5;
        final spin = random.nextDouble() * 10 - 5;
        return AcceleratedParticle(
          speed: Vector2(math.cos(angle), math.sin(angle)) * speed,
          acceleration: Vector2(0, 560),
          child: ComputedParticle(
            renderer: (canvas, particle) {
              canvas.save();
              canvas.rotate(particle.progress * spin);
              canvas.drawRect(Rect.fromCenter(center: Offset.zero, width: size, height: size * 0.8),
                  paint..color = color.withValues(alpha: 1 - particle.progress * 0.6));
              canvas.restore();
            },
          ),
        );
      },
    ),
  );
}

/// Ice / thorn shards flying outwards.
ParticleSystemComponent shards({required Vector2 at, required Color color, required int count}) {
  final random = math.Random();
  // One paint per system, mutated per particle: no allocation per frame.
  final paint = Paint();
  return ParticleSystemComponent(
    position: at,
    priority: 30,
    particle: Particle.generate(
      count: count,
      lifespan: 0.55,
      generator: (i) {
        final angle = random.nextDouble() * math.pi * 2;
        final speed = 200 + random.nextDouble() * 200;
        final length = 6 + random.nextDouble() * 8;
        return AcceleratedParticle(
          speed: Vector2(math.cos(angle), math.sin(angle)) * speed,
          acceleration: Vector2(0, 300),
          child: ComputedParticle(
            renderer: (canvas, particle) {
              canvas.save();
              canvas.rotate(angle);
              canvas.drawPath(
                Path()
                  ..moveTo(-length, 0)
                  ..lineTo(0, -2.5)
                  ..lineTo(length, 0)
                  ..lineTo(0, 2.5)
                  ..close(),
                paint..color = color.withValues(alpha: 1 - particle.progress),
              );
              canvas.restore();
            },
          ),
        );
      },
    ),
  );
}

/// Heavy drops of ink that fall and stretch.
ParticleSystemComponent splash({required Vector2 at, required Color color, required int count}) {
  final random = math.Random();
  // One paint per system, mutated per particle: no allocation per frame.
  final paint = Paint();
  return ParticleSystemComponent(
    position: at,
    priority: 30,
    particle: Particle.generate(
      count: count,
      lifespan: 0.7,
      generator: (i) {
        final angle = -math.pi * (0.1 + random.nextDouble() * 0.8);
        final speed = 120 + random.nextDouble() * 180;
        final size = 3 + random.nextDouble() * 4;
        return AcceleratedParticle(
          speed: Vector2(math.cos(angle), math.sin(angle)) * speed,
          acceleration: Vector2(0, 500),
          child: ComputedParticle(
            renderer: (canvas, particle) => canvas.drawOval(
              Rect.fromCenter(center: Offset.zero, width: size, height: size * (1 + particle.progress)),
              paint..color = color.withValues(alpha: 1 - particle.progress * 0.7),
            ),
          ),
        );
      },
    ),
  );
}

/// Flat shockwave along the ground for smashes.
class GroundShock extends PositionComponent {
  final Color color;
  final double span;
  double _t = 0;

  GroundShock({required Vector2 position, required this.color, required this.span})
      : super(position: position, anchor: Anchor.center, priority: 24);

  @override
  void update(double dt) {
    _t += dt / 0.5;
    if (_t >= 1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = _t.clamp(0.0, 1.0);
    final w = span * (0.2 + 0.8 * t);
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: w, height: w * 0.22),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8 * (1 - t) + 1
        ..color = color.withValues(alpha: (1 - t) * 0.9),
    );
  }
}

/// Quick diagonal slash mark that fades.
class SlashMark extends PositionComponent {
  final Color color;
  final double length;
  double _t = 0;

  SlashMark({required Vector2 position, required this.color, required this.length})
      : super(position: position, anchor: Anchor.center, priority: 28);

  @override
  void update(double dt) {
    _t += dt / 0.3;
    if (_t >= 1) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final t = _t.clamp(0.0, 1.0);
    final grow = math.min(1.0, t * 3);
    final half = length / 2 * grow;
    final paint = Paint()
      ..strokeCap = StrokeCap.round
      ..strokeWidth = 6 * (1 - t) + 1
      ..color = color.withValues(alpha: 1 - t);
    canvas.drawLine(Offset(-half, half * 0.6), Offset(half, -half * 0.6), paint);
    canvas.drawLine(Offset(-half * 0.6, half * 0.9), Offset(half * 0.6, -half * 0.9),
        paint..strokeWidth = 3 * (1 - t) + 0.5..color = const Color(0xFFFFFFFF).withValues(alpha: 1 - t));
  }
}

/// Stone-and-light ring around the player while a Guardian Ward holds.
/// Segments show the hits it can still absorb.
class WardRing extends PositionComponent {
  final Color color;
  double radius;
  int charges = 0;
  double _level = 0;
  double _time = 0;
  double _pulse = 0;

  WardRing({required this.color, required this.radius}) : super(anchor: Anchor.center, priority: 9);

  void set(int value) {
    if (value > charges) _pulse = 1;
    charges = value;
  }

  void absorb() => _pulse = 1;

  @override
  void update(double dt) {
    _time += dt;
    _level = (_level + (charges > 0 ? dt * 4 : -dt * 4)).clamp(0.0, 1.0);
    _pulse = math.max(0, _pulse - dt * 2);
  }

  @override
  void render(Canvas canvas) {
    if (_level <= 0.01) return;
    final r = radius * (0.85 + 0.15 * _level) * (1 + _pulse * 0.1);
    canvas.save();
    canvas.scale(1, 0.4);
    canvas.drawCircle(Offset.zero, r, _glow(color.withValues(alpha: 0.35 * _level), 10)..style = PaintingStyle.stroke..strokeWidth = 10);
    final segments = math.max(1, charges);
    final sweep = math.pi * 2 / segments;
    for (var k = 0; k < segments; k++) {
      canvas.drawArc(
        Rect.fromCircle(center: Offset.zero, radius: r),
        -math.pi / 2 + k * sweep + 0.18 + _time * 0.6,
        sweep - 0.36,
        false,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4 + _pulse * 3
          ..strokeCap = StrokeCap.round
          ..color = color.withValues(alpha: 0.9 * _level),
      );
    }
    // Floating stone chips.
    canvas.restore();
    for (var i = 0; i < 5; i++) {
      final angle = _time * 1.2 + i * math.pi * 2 / 5;
      final p = Offset(math.cos(angle) * r * 1.05, math.sin(angle) * r * 0.42 - 30 - math.sin(_time * 3 + i) * 6);
      canvas.drawRect(Rect.fromCenter(center: p, width: 6, height: 6),
          Paint()..color = const Color(0xFFB9B2A6).withValues(alpha: 0.9 * _level));
    }
  }
}

/// Rune chains that lock around a bound enemy.
class BindChains extends PositionComponent {
  final Color color;
  final double radius;
  double _t = 0;

  BindChains({required Vector2 position, required this.color, required this.radius})
      : super(position: position, anchor: Anchor.center, priority: 26);

  @override
  void update(double dt) {
    _t += dt;
    if (_t > 1.4) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final close = math.min(1.0, _t / 0.35);
    final fade = _t > 1.0 ? (1.4 - _t) / 0.4 : 1.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.95 * fade);
    for (var i = 0; i < 3; i++) {
      final angle = -0.5 + i * 0.5;
      final span = radius * 1.3 * close;
      final a = Offset(-span * math.cos(angle), -span * math.sin(angle) - i * 6);
      final b = Offset(span * math.cos(angle), span * math.sin(angle) - i * 6);
      canvas.drawLine(a, b, paint);
      const links = 6;
      for (var k = 0; k <= links; k++) {
        final p = Offset.lerp(a, b, k / links)!;
        canvas.drawCircle(p, 3.5, Paint()..color = const Color(0xFFFFFFFF).withValues(alpha: 0.85 * fade));
      }
    }
    // Lock rune in the middle.
    glowCircle(canvas, Offset.zero, 12 * close, color.withValues(alpha: 0.6 * fade), 8);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: const Offset(0, 3), width: 14 * close, height: 11 * close), const Radius.circular(2)),
        Paint()..color = color.withValues(alpha: fade));
    canvas.drawArc(Rect.fromCenter(center: const Offset(0, -3), width: 10 * close, height: 10 * close), math.pi, math.pi, false,
        Paint()..style = PaintingStyle.stroke..strokeWidth = 2.5..color = color.withValues(alpha: fade));
  }
}

// ---------------------------------------------------------------------------
// Poison, telegraphs and reflect (pass 4)
// ---------------------------------------------------------------------------

/// Particles drifting upwards: rising dust, bubbles, embers, snow.
ParticleSystemComponent rise({
  required Vector2 at,
  required Color color,
  required int count,
  double spread = 60,
  double speed = 70,
  double lifespan = 0.9,
  double size = 3,
}) {
  final random = math.Random();
  // One paint per system, mutated per particle: no allocation per frame.
  final paint = Paint();
  return ParticleSystemComponent(
    position: at,
    priority: 30,
    particle: Particle.generate(
      count: count,
      lifespan: lifespan,
      generator: (i) {
        final dx = (random.nextDouble() - 0.5) * spread;
        final sway = random.nextDouble() * 6;
        return AcceleratedParticle(
          position: Vector2(dx, random.nextDouble() * 10),
          speed: Vector2((random.nextDouble() - 0.5) * 20, -speed * (0.6 + random.nextDouble() * 0.8)),
          acceleration: Vector2(0, -20),
          child: ComputedParticle(
            renderer: (canvas, particle) {
              final fade = 1 - particle.progress;
              canvas.drawCircle(Offset(math.sin(particle.progress * sway) * 4, 0), size * (0.6 + fade * 0.6),
                  paint..color = color.withValues(alpha: fade * 0.85));
            },
          ),
        );
      },
    ),
  );
}

/// Thorn Blight: a bubbling green-violet cloud that rolls from the caster to
/// the target, then bursts into drops.
class PoisonCloud extends PositionComponent {
  final Color color;
  final double radius;
  Vector2? _from;
  Vector2? _to;
  double _flight = 0;
  double _duration = 0.8;
  void Function()? _onArrive;
  double _time = 0;
  final List<Offset> _lobes;

  PoisonCloud({required this.color, required this.radius, required Vector2 position})
      : _lobes = List.generate(7, (i) {
          final random = math.Random(i * 97);
          return Offset((random.nextDouble() - 0.5) * 1.3, (random.nextDouble() - 0.5) * 0.8);
        }),
        super(position: position, anchor: Anchor.center, priority: 21);

  void launch(Vector2 target, {double duration = 0.8, void Function()? onArrive}) {
    _from = position.clone();
    _to = target.clone();
    _duration = duration;
    _onArrive = onArrive;
    _flight = 0;
  }

  @override
  void update(double dt) {
    _time += dt;
    final from = _from;
    final to = _to;
    if (from == null || to == null) return;
    _flight += dt / _duration;
    if (_flight >= 1) {
      position.setFrom(to);
      final callback = _onArrive;
      _onArrive = null;
      callback?.call();
      removeFromParent();
      return;
    }
    final eased = _easeInOut(_flight);
    position.setValues(from.x + (to.x - from.x) * eased, from.y + (to.y - from.y) * eased - math.sin(eased * math.pi) * 24);
  }

  static double _easeInOut(double t) => t < 0.5 ? 2 * t * t : 1 - math.pow(-2 * t + 2, 2) / 2;

  @override
  void render(Canvas canvas) {
    final grow = math.min(1.0, _time * 3);
    glowCircle(canvas, Offset.zero, radius * 1.6 * grow, color.withValues(alpha: 0.35), radius * 0.8);
    for (var i = 0; i < _lobes.length; i++) {
      final lobe = _lobes[i];
      final wobble = 1 + math.sin(_time * 6 + i) * 0.12;
      final center = Offset(lobe.dx * radius, lobe.dy * radius + math.sin(_time * 4 + i * 1.3) * 3);
      final tint = i.isEven ? color : const Color(0xFF7A4BD8);
      canvas.drawCircle(center, radius * 0.55 * wobble * grow, Paint()..color = tint.withValues(alpha: 0.75));
    }
    canvas.drawCircle(const Offset(-3, -4), radius * 0.3 * grow, Paint()..color = const Color(0xFFD7FFB0).withValues(alpha: 0.6));
  }
}

/// Status on a poisoned creature: faint green haze and rising bubbles.
class PoisonAura extends PositionComponent {
  final Color color;
  double radius;
  bool active = false;
  double _level = 0;
  double _time = 0;
  double _nextBubble = 0;
  final math.Random _random = math.Random();

  PoisonAura({required this.color, required this.radius}) : super(anchor: Anchor.center, priority: 11);

  @override
  void update(double dt) {
    _time += dt;
    _level = (_level + (active ? dt * 3 : -dt * 3)).clamp(0.0, 1.0);
    if (active && _level > 0.5) {
      _nextBubble -= dt;
      if (_nextBubble <= 0) {
        _nextBubble = 0.28 + _random.nextDouble() * 0.2;
        parent?.add(rise(
          at: position + Vector2((_random.nextDouble() - 0.5) * radius, radius * 0.4),
          color: color,
          count: 2,
          spread: 10,
          speed: 50,
          lifespan: 1.1,
          size: 2.5,
        ));
      }
    }
  }

  @override
  void render(Canvas canvas) {
    if (_level <= 0.01) return;
    final pulse = 1 + math.sin(_time * 3) * 0.05;
    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: radius * 1.5 * pulse, height: radius * 2.1 * pulse),
      Paint()
        ..shader = Gradient.radial(Offset.zero, radius * 1.1 * pulse, [
          color.withValues(alpha: 0.28 * _level),
          color.withValues(alpha: 0),
        ]),
    );
  }
}

/// Thorn Curse / Thorn Blight: brambles curling up around the victim.
class ThornVines extends PositionComponent {
  final Color color;
  final double reach;
  double _t = 0;

  ThornVines({required Vector2 position, required this.color, required this.reach})
      : super(position: position, anchor: Anchor.bottomCenter, priority: 27);

  @override
  void update(double dt) {
    _t += dt;
    if (_t > 1.5) removeFromParent();
  }

  @override
  void render(Canvas canvas) {
    final grow = math.min(1.0, _t / 0.5);
    final fade = _t > 1.1 ? (1.5 - _t) / 0.4 : 1.0;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: fade);
    for (var v = 0; v < 3; v++) {
      final sign = v.isEven ? 1 : -1;
      final x0 = (v - 1) * reach * 0.22;
      final path = Path()..moveTo(x0, 0);
      const steps = 8;
      for (var s = 1; s <= steps; s++) {
        final p = s / steps * grow;
        final y = -reach * p;
        final x = x0 + math.sin(p * math.pi * 2.2 + v) * reach * 0.14 * sign;
        path.lineTo(x, y);
        if (s.isEven && p > 0.1) {
          // Thorn.
          final tip = Offset(x + sign * 7, y - 4);
          canvas.drawLine(Offset(x, y), tip, paint..strokeWidth = 2.5);
          paint.strokeWidth = 4;
        }
      }
      canvas.drawPath(path, paint);
    }
  }
}

/// Wind-up before an enemy Special, in the voice of its magic family.
List<Component> elementTelegraph({
  required ElementStyle style,
  required Vector2 at,
  required Vector2 feet,
  required Color color,
  required VfxConfig vfx,
}) {
  switch (style) {
    case ElementStyle.rock:
      return [
        rise(at: feet, color: const Color(0xFFB9B2A6), count: vfx.particles(14), spread: 90, speed: 90, size: 3.5),
        GroundShock(position: feet, color: const Color(0xFFC9B9A2), span: 150),
      ];
    case ElementStyle.smash:
      return [
        GroundShock(position: feet, color: color, span: 190),
        debris(at: feet, color: const Color(0xFF6E6257), count: vfx.particles(10)),
      ];
    case ElementStyle.thorn:
      return [
        ThornVines(position: feet, color: const Color(0xFF6FBF4A), reach: 110),
        rise(at: feet, color: const Color(0xFF9CE26B), count: vfx.particles(10), spread: 70, speed: 60, size: 2.5),
      ];
    case ElementStyle.ink:
      return [
        rise(at: at + Vector2(0, 30), color: const Color(0xFF1C1B2E), count: vfx.particles(14), spread: 70, speed: 110, size: 4),
        Shockwave(position: at, color: color, maxRadius: 110, duration: 0.7),
      ];
    case ElementStyle.frost:
      return [
        shards(at: at, color: const Color(0xFFDFF8FF), count: vfx.particles(10)),
        rise(at: feet, color: const Color(0xFFDFF8FF), count: vfx.particles(12), spread: 90, speed: 40, lifespan: 1.2, size: 2),
        RuneCircle(color: const Color(0xFF9FE8FF), radius: 70, position: feet - Vector2(0, 4))..charge = 0.4,
      ];
    case ElementStyle.spark:
    case ElementStyle.glint:
      return [
        burst(at: at, color: color, count: vfx.particles(16), speed: 160, lifespan: 0.5, size: 2),
        burst(at: at, color: const Color(0xFFFFFFFF), count: vfx.particles(6), speed: 90, lifespan: 0.4, size: 1.5),
        Shockwave(position: at, color: color, maxRadius: 80, duration: 0.45),
      ];
    case ElementStyle.slash:
    case ElementStyle.steel:
      return [
        SlashMark(position: at + Vector2(-20, -10), color: color, length: 70),
        SlashMark(position: at + Vector2(16, 12), color: const Color(0xFFFFFFFF), length: 50),
        Shockwave(position: at, color: color, maxRadius: 90, duration: 0.5),
      ];
    case ElementStyle.arcane:
      return [
        RuneCircle(color: color, radius: 80, position: feet - Vector2(0, 4))..charge = 0.3,
        Shockwave(position: at, color: color, maxRadius: 150, duration: 0.8),
        burst(at: at, color: color, count: vfx.particles(16), speed: 70, lifespan: 1),
      ];
  }
}
