import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/wf_theme.dart';
import 'wf_glyph.dart';

/// Pressable surface with a gentle press-down scale; used by every game
/// button so touch feedback is consistent and never relies on hover.
class WfPressable extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;
  final String? semanticsLabel;

  const WfPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.95,
    this.semanticsLabel,
  });

  @override
  State<WfPressable> createState() => _WfPressableState();
}

class _WfPressableState extends State<WfPressable> {
  bool _pressed = false;

  void _set(bool value) {
    if (_pressed != value && mounted) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticsLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: enabled ? (_) => _set(true) : null,
        onTapUp: enabled ? (_) => _set(false) : null,
        onTapCancel: () => _set(false),
        onTap: enabled
            ? () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              }
            : null,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _pressed ? widget.pressedScale : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

enum WfButtonStyle { primary, gold, secondary, danger }

class WfButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final WfButtonStyle style;
  final WfGlyphType? glyph;
  final bool expand;

  const WfButton({
    super.key,
    required this.label,
    this.onTap,
    this.style = WfButtonStyle.primary,
    this.glyph,
    this.expand = true,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    final (List<Color> colors, Color text, Color border) = switch (style) {
      WfButtonStyle.primary => (const [Color(0xFF45EA97), WfColors.brand, WfColors.brandDeep], WfColors.night, const Color(0xFFB4F8D3)),
      WfButtonStyle.gold => (const [Color(0xFFFFDC8A), WfColors.gold, WfColors.goldDeep], WfColors.night, const Color(0xFFFFE9B5)),
      WfButtonStyle.secondary => (const [WfColors.panelHigh, WfColors.panel], WfColors.text, WfColors.strokeStrong),
      WfButtonStyle.danger => (const [Color(0xFFFF7A8E), WfColors.danger], WfColors.night, const Color(0xFFFFB3BE)),
    };
    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (glyph != null) ...[WfGlyph(glyph!, size: 18, color: text), const SizedBox(width: 8)],
        Flexible(
          child: Text(label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: WfText.label(15, color: text, spacing: 1.4)),
        ),
      ],
    );
    return WfPressable(
      onTap: onTap,
      semanticsLabel: label,
      child: AnimatedOpacity(
        opacity: enabled ? 1 : 0.45,
        duration: const Duration(milliseconds: 150),
        child: Container(
          constraints: const BoxConstraints(minHeight: WfShape.buttonHeight),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          decoration: BoxDecoration(
            gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: colors),
            borderRadius: BorderRadius.circular(WfShape.pill),
            border: Border.all(color: border, width: 1.2),
            boxShadow: (style == WfButtonStyle.primary || style == WfButtonStyle.gold) && enabled
                ? [...WfFx.shadow(colors[1].withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 6))]
                : null,
          ),
          child: content,
        ),
      ),
    );
  }
}

class WfRoundButton extends StatelessWidget {
  final WfGlyphType glyph;
  final VoidCallback? onTap;
  final String semanticsLabel;
  final double size;
  final Color color;

  const WfRoundButton({
    super.key,
    required this.glyph,
    required this.onTap,
    required this.semanticsLabel,
    this.size = 44,
    this.color = WfColors.text,
  });

  @override
  Widget build(BuildContext context) => WfPressable(
        onTap: onTap,
        semanticsLabel: semanticsLabel,
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: WfColors.panel.withValues(alpha: 0.85),
            border: Border.all(color: WfColors.stroke),
          ),
          child: WfGlyph(glyph, size: size * 0.45, color: color),
        ),
      );
}

/// Framed dark panel with a faint arcane edge.
class WfPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? glow;
  final double radius;

  const WfPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.glow,
    this.radius = WfShape.card,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: padding,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [WfColors.panelHigh.withValues(alpha: 0.92), WfColors.panel.withValues(alpha: 0.92)],
          ),
          border: Border.all(color: (glow ?? Colors.white).withValues(alpha: glow == null ? 0.12 : 0.45)),
          boxShadow: [
            if (glow != null) ...WfFx.shadow(glow!.withValues(alpha: 0.18), blurRadius: 24),
            ...WfFx.shadow(const Color(0x66000000), blurRadius: 16, offset: const Offset(0, 8)),
          ],
        ),
        child: child,
      );
}

class WfProgressBar extends StatelessWidget {
  final double value;
  final Color color;
  final double height;
  final Color? trackColor;

  const WfProgressBar({super.key, required this.value, this.color = WfColors.gold, this.height = 8, this.trackColor});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(end: value.clamp(0.0, 1.0)),
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOutCubic,
        builder: (context, animated, _) => Container(
          height: height,
          decoration: BoxDecoration(
            color: trackColor ?? Colors.black.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(height),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: animated,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(height),
                gradient: LinearGradient(colors: [Color.lerp(color, Colors.white, 0.25)!, color]),
                boxShadow: [...WfFx.shadow(color.withValues(alpha: 0.5), blurRadius: 8)],
              ),
            ),
          ),
        ),
      );
}

class WfStarRow extends StatelessWidget {
  final int stars;
  final int max;
  final double size;

  const WfStarRow({super.key, required this.stars, this.max = 3, this.size = 16});

  @override
  Widget build(BuildContext context) => Semantics(
        label: '$stars / $max',
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < max; i++)
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size * 0.06),
                child: WfGlyph(WfGlyphType.star,
                    size: size, color: i < stars ? WfColors.gold : Colors.white.withValues(alpha: 0.18)),
              ),
          ],
        ),
      );
}

class WfTag extends StatelessWidget {
  final String text;
  final Color color;

  const WfTag(this.text, {super.key, this.color = WfColors.arcane});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.5)),
        ),
        child: Text(text.toUpperCase(), style: WfText.label(10.5, color: color, spacing: 1.2)),
      );
}

/// Animated night-sky backdrop with drifting embers, shared by menu screens.
class ForgeBackdrop extends StatefulWidget {
  final Widget child;
  final Color glow;
  final bool animate;

  const ForgeBackdrop({super.key, required this.child, this.glow = WfColors.gold, this.animate = true});

  @override
  State<ForgeBackdrop> createState() => _ForgeBackdropState();
}

class _ForgeBackdropState extends State<ForgeBackdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(seconds: 14));

  @override
  void initState() {
    super.initState();
    if (widget.animate) _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: CustomPaint(painter: _BackdropPainter(_controller, widget.glow)),
          ),
          widget.child,
        ],
      );
}

class _BackdropPainter extends CustomPainter {
  final Animation<double> animation;
  final Color glow;
  static final List<_Ember> _embers = List.generate(28, (i) => _Ember(math.Random(i * 97 + 11)));

  _BackdropPainter(this.animation, this.glow) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [WfColors.night, WfColors.deep, Color(0xFF1C1440)],
        ).createShader(rect),
    );
    canvas.drawCircle(
      Offset(size.width * 0.5, size.height * 0.18),
      size.width * 0.75,
      Paint()
        ..shader = RadialGradient(colors: [glow.withValues(alpha: 0.16), glow.withValues(alpha: 0)])
            .createShader(Rect.fromCircle(center: Offset(size.width * 0.5, size.height * 0.18), radius: size.width * 0.75)),
    );
    final t = animation.value;
    final paint = Paint();
    for (final ember in _embers) {
      final progress = (ember.offset + t * ember.speed) % 1.0;
      final x = size.width * (ember.x + math.sin((progress + ember.offset) * math.pi * 2) * 0.03);
      final y = size.height * (1.05 - progress * 1.1);
      final alpha = math.sin(progress * math.pi) * ember.alpha;
      paint.color = (ember.cool ? WfColors.arcane : glow).withValues(alpha: alpha);
      canvas.drawCircle(Offset(x, y), ember.radius, paint);
    }
  }

  @override
  bool shouldRepaint(_BackdropPainter oldDelegate) => oldDelegate.glow != glow;
}

class _Ember {
  final double x;
  final double offset;
  final double speed;
  final double radius;
  final double alpha;
  final bool cool;

  _Ember(math.Random random)
      : x = random.nextDouble(),
        offset = random.nextDouble(),
        speed = 0.4 + random.nextDouble() * 0.8,
        radius = 0.8 + random.nextDouble() * 1.8,
        alpha = 0.25 + random.nextDouble() * 0.5,
        cool = random.nextDouble() < 0.3;
}

/// Standard dark bottom sheet for Word Forge.
Future<T?> showWfSheet<T>(BuildContext context, {required WidgetBuilder builder}) =>
    showModalBottomSheet<T>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.86),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [WfColors.panelHigh, WfColors.deep],
            ),
            border: Border.all(color: WfColors.stroke),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: WfColors.strokeStrong, borderRadius: BorderRadius.circular(4)),
              ),
              Flexible(child: builder(sheetContext)),
            ],
          ),
        ),
      ),
    );

/// Confirmation dialog with the same structure as the host app's dialogs
/// (icon, bold title, grey subtitle, destructive pill, outlined cancel),
/// rendered in Word Forge colours.
Future<bool> showWfConfirm(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
  WfGlyphType glyph = WfGlyphType.mystery,
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.6),
    builder: (dialogContext) => Dialog(
      backgroundColor: WfColors.panel,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: WfColors.stroke),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            WfGlyph(glyph, size: 44, color: destructive ? WfColors.danger : WfColors.gold),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: WfText.title(18)),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center, style: WfText.body(14)),
            const SizedBox(height: 24),
            WfButton(
              label: confirmLabel,
              style: destructive ? WfButtonStyle.danger : WfButtonStyle.primary,
              onTap: () => Navigator.of(dialogContext).pop(true),
            ),
            const SizedBox(height: 12),
            WfButton(
              label: cancelLabel,
              style: WfButtonStyle.secondary,
              onTap: () => Navigator.of(dialogContext).pop(false),
            ),
          ],
        ),
      ),
    ),
  );
  return result ?? false;
}
