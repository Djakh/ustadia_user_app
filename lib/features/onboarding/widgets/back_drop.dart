import 'package:flutter/material.dart';

class Backdrop extends StatelessWidget {
  const Backdrop({super.key, required this.background, required this.accent});

  final Color background;
  final Color accent;

  Widget circleLayer(double diameter, Color color) => Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [
            color,
            color.withValues(alpha: 0),
          ], center: Alignment.center, radius: 0.85)));

  @override
  Widget build(BuildContext context) => DecoratedBox(
      decoration: BoxDecoration(color: background),
      child: Stack(children: [
        Positioned(top: -160, left: -120, child: circleLayer(260, accent.withValues(alpha: 0.22))),
        Positioned(top: 120, right: -140, child: circleLayer(330, accent.withValues(alpha: 0.20))),
        Positioned(bottom: -140, left: -90, child: circleLayer(280, accent.withValues(alpha: 0.16)))
      ]));
}
