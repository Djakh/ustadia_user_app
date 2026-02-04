import 'package:flutter/material.dart';

class PrimaryListView extends StatelessWidget {
  final List<dynamic> items;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final double separatorHeight;
  final Widget? separatorWidget;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final Widget Function(dynamic item) itemBuilder;
  final Future<void> Function()? onRefresh;
  const PrimaryListView(
      {super.key,
      required this.items,
      this.physics,
      this.shrinkWrap = false,
      this.separatorHeight = 8,
      this.separatorWidget,
      required this.itemBuilder,
      this.scrollDirection = Axis.vertical,
      this.padding,
      this.onRefresh});

  ScrollPhysics? get listPhysics {
    if (onRefresh == null || scrollDirection != Axis.vertical) return physics;
    if (physics == null) return const AlwaysScrollableScrollPhysics();
    return AlwaysScrollableScrollPhysics(parent: physics);
  }

  Widget get listView => ListView.separated(
      itemCount: items.length,
      physics: listPhysics,
      padding: padding,
      scrollDirection: scrollDirection,
      shrinkWrap: shrinkWrap,
      separatorBuilder: (_, index) => separatorWidget ?? SizedBox(height: separatorHeight),
      itemBuilder: (_, index) => itemBuilder(items[index]));

  @override
  Widget build(BuildContext context) {
    if (onRefresh == null || scrollDirection != Axis.vertical) return listView;
    return RefreshIndicator(onRefresh: onRefresh!, child: listView);
  }
}
