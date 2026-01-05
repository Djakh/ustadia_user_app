import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class PageIndicator extends StatelessWidget {
  final int currentIndex;
  final int total;
  final Color? activeColor;
  final Color? inactiveColor;
  final double itemWidth;
  final double itemHeight;
  final double spacing;
  final BorderRadius borderRadius;
  final bool isExpanded;
  final bool isFilledIndicators;
  const PageIndicator(
      {super.key,
      required this.currentIndex,
      required this.total,
      this.activeColor,
      this.inactiveColor,
      this.itemWidth = 56,
      this.itemHeight = 4,
      this.spacing = 4,
      BorderRadius? borderRadius,
      this.isExpanded = false,
      this.isFilledIndicators = true})
      : borderRadius = borderRadius ?? const BorderRadius.all(Radius.circular(12));

  Color _colorFor(int index, BuildContext context) {
    if (isFilledIndicators && index < currentIndex) return activeColor ?? context.cs.primary;

    if (index == currentIndex) return activeColor ?? context.cs.primary;

    return inactiveColor ?? context.cs.primary.withValues(alpha: 0.30);
  }

  Widget itemAnimatedContainer(int index) => Builder(
      builder: (context) => AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          margin: EdgeInsets.only(right: index == total - 1 ? 0 : spacing),
          height: itemHeight,
          width: itemWidth,
          decoration: BoxDecoration(color: _colorFor(index, context), borderRadius: borderRadius)));

  Widget checkIsExpandedIndicatior(int index) =>
      isExpanded ? Expanded(child: itemAnimatedContainer(index)) : itemAnimatedContainer(index);

  @override
  Widget build(BuildContext context) => Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: List.generate(total, (index) => checkIsExpandedIndicatior(index)));
}
