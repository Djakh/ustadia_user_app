import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_box.dart';

class ShimmerList extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final double separatorHeight;
  final EdgeInsets? padding;
  final BorderRadius borderRadius;

  const ShimmerList(
      {super.key,
      required this.itemCount,
      required this.itemHeight,
      this.separatorHeight = 12,
      this.padding,
      this.borderRadius = BorderRadius.zero});

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];
    for (var i = 0; i < itemCount; i++) {
      items.add(ShimmerBox(height: itemHeight, borderRadius: borderRadius));
      if (i != itemCount - 1) items.add(SizedBox(height: separatorHeight));
    }
    return Padding(padding: padding ?? EdgeInsets.zero, child: Column(children: items));
  }
}
