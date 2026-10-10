import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Blur mask filters are expensive on many Android GPUs, and the battle
/// scene repaints every frame, so every glow is re-blurred 60 times a
/// second. On Android glows are drawn as radial gradients instead (a close
/// look-alike that costs almost nothing); iOS keeps true blurs.
final bool cheapGlows = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

final Paint _gradientPaint = Paint();

/// A soft glowing disk: like a circle blurred by [sigma].
void glowCircle(Canvas canvas, Offset center, double radius, Color color, double sigma) {
  if (!cheapGlows) {
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = color
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma),
    );
    return;
  }
  final outer = radius + sigma * 2;
  if (outer <= 0 || color.a <= 0) return;
  final solid = ((radius - sigma) / outer).clamp(0.0, 0.95);
  _gradientPaint.shader = Gradient.radial(
    center,
    outer,
    [color, color, color.withValues(alpha: 0)],
    [0, solid, 1],
  );
  canvas.drawCircle(center, outer, _gradientPaint);
}

/// Glow paint for strokes and shapes that are not circles: blurred on iOS,
/// a fainter plain paint on Android.
Paint glowPaint(Color color, double sigma) => cheapGlows
    ? (Paint()..color = color.withValues(alpha: color.a * 0.45))
    : (Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, sigma));
