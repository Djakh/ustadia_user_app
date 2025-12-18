import 'package:flutter/material.dart';

class PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int total;
  final Color? activeColor;
  final Color? inactiveColor;
  final double itemWidth;
  final double itemHeight;
  final double spacing;
  final BorderRadius borderRadius;

  const PageIndicator({
    super.key,
    required this.currentIndex,
    required this.total,
    this.activeColor,
    this.inactiveColor,
    this.itemWidth = 56,
    this.itemHeight = 4,
    this.spacing = 4,
    BorderRadius? borderRadius,
  }) : borderRadius = borderRadius ?? const BorderRadius.all(Radius.circular(12));

  Color _colorFor(int index) {
    if (index == currentIndex) return activeColor ?? Colors.white.withAlpha(230);
    return inactiveColor ?? Colors.white.withAlpha(140);
  }

  Widget itemAnimatedContainer(int index) => AnimatedContainer(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOut,
      margin: EdgeInsets.only(right: index == total - 1 ? 0 : spacing),
      height: itemHeight,
      width: itemWidth,
      decoration: BoxDecoration(
          color: _colorFor(index),
          borderRadius: borderRadius));

  @override
  Widget build(BuildContext context) => Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(total, (index) => itemAnimatedContainer(index)));
}
