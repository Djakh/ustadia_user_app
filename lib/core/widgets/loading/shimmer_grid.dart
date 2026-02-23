import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_box.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer.dart';

class ShimmerGrid extends StatelessWidget {
  final int itemCount;
  final int crossAxisCount;
  final double crossAxisSpacing;
  final double mainAxisSpacing;
  final double childAspectRatio;
  final EdgeInsets? padding;
  final BorderRadius borderRadius;

  const ShimmerGrid(
      {super.key,
      required this.itemCount,
      required this.crossAxisCount,
      required this.childAspectRatio,
      this.crossAxisSpacing = 12,
      this.mainAxisSpacing = 12,
      this.padding,
      this.borderRadius = BorderRadius.zero});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
        child: GridView.builder(
            padding: padding ?? EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: itemCount,
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: crossAxisSpacing,
                mainAxisSpacing: mainAxisSpacing,
                childAspectRatio: childAspectRatio),
            itemBuilder: (context, index) =>
                ShimmerBox(height: double.infinity, borderRadius: borderRadius)));
  }
}
