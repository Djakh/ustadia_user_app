import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_box.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer.dart';

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
    return LayoutBuilder(builder: (context, constraints) {
      final hasBoundedHeight = constraints.maxHeight.isFinite;
      final listView = ListView.separated(
          padding: padding ?? EdgeInsets.zero,
          itemCount: itemCount,
          itemBuilder: (context, index) =>
              ShimmerBox(height: itemHeight, borderRadius: borderRadius),
          separatorBuilder: (context, index) => SizedBox(height: separatorHeight));
      if (hasBoundedHeight) {
        return Shimmer(child: SizedBox(height: constraints.maxHeight, child: listView));
      }
      final items = <Widget>[];
      for (var i = 0; i < itemCount; i++) {
        items.add(ShimmerBox(height: itemHeight, borderRadius: borderRadius));
        if (i != itemCount - 1) items.add(SizedBox(height: separatorHeight));
      }
      return Shimmer(
          child: Padding(padding: padding ?? EdgeInsets.zero, child: Column(children: items)));
    });
  }
}
