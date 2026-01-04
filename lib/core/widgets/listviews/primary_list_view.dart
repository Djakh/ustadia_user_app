import 'package:flutter/material.dart';

class PrimaryListView extends StatelessWidget {
  final List<dynamic> items;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final double separatorHeight;
  final Widget? separatorWidget;
  final Axis scrollDirection;
  final Widget Function(dynamic item) itemBuilder;
  const PrimaryListView(
      {super.key,
      required this.items,
      this.physics,
      this.shrinkWrap = false,
      this.separatorHeight = 8,
      this.separatorWidget,
      required this.itemBuilder,
      this.scrollDirection = Axis.vertical});

  Widget get view => ListView.separated(
      itemCount: items.length,
      physics: physics,
      scrollDirection: scrollDirection,
      shrinkWrap: true,
      separatorBuilder: (_, index) => separatorWidget ?? SizedBox(height: separatorHeight),
      itemBuilder: (_, index) => itemBuilder(items[index]));

  @override
  Widget build(BuildContext context) => view;
}
