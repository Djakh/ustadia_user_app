import 'package:flutter/material.dart';

import '../../domain/characters/player_character.dart';
import '../../game/entities/apprentice_skin.dart';
import '../../game/entities/entity.dart';
import '../theme/wf_theme.dart';

/// Animated apprentice for menus. Uses the exact skin and animator of the
/// battle so menus and combat show the same character.
class CharacterPortrait extends StatefulWidget {
  final PlayerCharacterDefinition character;
  final int tier;
  final bool casting;
  final double size;

  const CharacterPortrait({
    super.key,
    required this.character,
    this.tier = 0,
    this.casting = false,
    this.size = 160,
  });

  @override
  State<CharacterPortrait> createState() => _CharacterPortraitState();
}

class _CharacterPortraitState extends State<CharacterPortrait> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))
    ..repeat();
  final EntityAnimator _animator = EntityAnimator();
  Duration _last = Duration.zero;
  final Stopwatch _clock = Stopwatch()..start();

  @override
  void didUpdateWidget(CharacterPortrait oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.casting && !oldWidget.casting) _animator.play(EntityState.cast, duration: 0.8);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox(
        width: widget.size * 0.8,
        height: widget.size,
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              final now = _clock.elapsed;
              final dt = ((now - _last).inMicroseconds / 1e6).clamp(0.0, 0.1);
              _last = now;
              _animator.update(dt, floats: false);
              return CustomPaint(
                painter: _PortraitPainter(
                  skin: ApprenticeSkin(character: widget.character, tier: widget.tier, magic: WfColors.brand),
                  pose: _animator.pose,
                ),
              );
            },
          ),
        ),
      );
}

class _PortraitPainter extends CustomPainter {
  final EntitySkin skin;
  final EntityPose pose;
  static const _palette = EntityPalette(primary: WfColors.brand, secondary: WfColors.gold, accent: WfColors.brand);

  _PortraitPainter({required this.skin, required this.pose});

  @override
  void paint(Canvas canvas, Size size) {
    final unit = size.height * 0.95;
    canvas.save();
    canvas.translate(size.width / 2, size.height * 0.98);
    canvas.scale(unit, unit);
    skin.shadow(canvas, pose);
    canvas.translate(0, -pose.bob);
    skin.render(canvas, pose, _palette);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_PortraitPainter oldDelegate) => true;
}
