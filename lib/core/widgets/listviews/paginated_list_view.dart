import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';

class PaginatedListView<T> extends StatefulWidget {
  final List<T> items;
  final Widget Function(T item) itemBuilder;
  final Future<void> Function()? onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;
  final double separatorHeight;
  final Widget? separatorWidget;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final Future<void> Function()? onRefresh;

  const PaginatedListView(
      {super.key,
      required this.items,
      required this.itemBuilder,
      this.onLoadMore,
      this.hasMore = false,
      this.isLoadingMore = false,
      this.separatorHeight = 8,
      this.separatorWidget,
      this.padding,
      this.physics,
      this.shrinkWrap = false,
      this.onRefresh});

  @override
  State<PaginatedListView<T>> createState() => _PaginatedListViewState<T>();
}

class _PaginatedListViewState<T> extends State<PaginatedListView<T>> {
  static const double _loadMoreOffset = 200;
  final ScrollController _controller = ScrollController();
  int _lastAutoLoadItemCount = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFillViewport());
  }

  @override
  void didUpdateWidget(covariant PaginatedListView<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length ||
        oldWidget.hasMore != widget.hasMore ||
        oldWidget.isLoadingMore != widget.isLoadingMore) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _maybeFillViewport());
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleScroll);
    _controller.dispose();
    super.dispose();
  }

  bool get _canLoadMore =>
      widget.hasMore && !widget.isLoadingMore && widget.onLoadMore != null;

  void _handleScroll() {
    if (!_canLoadMore) return;
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.maxScrollExtent - position.pixels <= _loadMoreOffset) {
      widget.onLoadMore?.call();
    }
  }

  void _maybeFillViewport() {
    if (!_canLoadMore) return;
    if (!_controller.hasClients) return;
    final position = _controller.position;
    if (position.maxScrollExtent <= 0 && _lastAutoLoadItemCount != widget.items.length) {
      _lastAutoLoadItemCount = widget.items.length;
      widget.onLoadMore?.call();
    }
  }

  Widget _footer() {
    if (!widget.isLoadingMore) return const SizedBox.shrink();
    return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: PrimaryLoadingIndicator(height: 24, width: 24));
  }

  ScrollPhysics? get listPhysics {
    if (widget.onRefresh == null) return widget.physics;
    if (widget.physics == null) return const AlwaysScrollableScrollPhysics();
    return AlwaysScrollableScrollPhysics(parent: widget.physics);
  }

  Widget get listView => ListView.separated(
      controller: _controller,
      itemCount: widget.items.length + (widget.isLoadingMore ? 1 : 0),
      physics: listPhysics,
      padding: widget.padding,
      shrinkWrap: widget.shrinkWrap,
      separatorBuilder: (_, index) =>
          widget.separatorWidget ?? SizedBox(height: widget.separatorHeight),
      itemBuilder: (_, index) {
        if (index >= widget.items.length) return _footer();
        return widget.itemBuilder(widget.items[index]);
      });

  @override
  Widget build(BuildContext context) {
    if (widget.onRefresh == null) return listView;
    return RefreshIndicator(onRefresh: widget.onRefresh!, child: listView);
  }
}
