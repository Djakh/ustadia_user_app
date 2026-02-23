import 'package:flutter/material.dart';

class Shimmer extends StatefulWidget {
  final Widget child;
  final Duration duration;

  const Shimmer({super.key, required this.child, this.duration = const Duration(milliseconds: 400)});

  static double? progressOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_ShimmerData>()?.progress;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(vsync: this, duration: widget.duration)..repeat();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: controller,
      builder: (context, child) =>
          _ShimmerData(progress: controller.value, child: child ?? const SizedBox.shrink()),
      child: widget.child);
}

class _ShimmerData extends InheritedWidget {
  final double progress;

  const _ShimmerData({required this.progress, required super.child});

  @override
  bool updateShouldNotify(_ShimmerData oldWidget) => oldWidget.progress != progress;
}
