import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer.dart';

class ShimmerBox extends StatefulWidget {
  final double height;
  final double? width;
  final BorderRadius borderRadius;
  final EdgeInsets? margin;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerBox(
      {super.key,
      required this.height,
      this.width,
      this.margin,
      this.borderRadius = BorderRadius.zero,
      this.baseColor = AppColors.gray200,
      this.highlightColor = AppColors.gray100});

  @override
  State<ShimmerBox> createState() => ShimmerBoxState();
}

class ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  AnimationController? animationController;
  Animation<double>? animation;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (animationController != null || Shimmer.progressOf(context) != null) return;
    animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700))
          ..repeat();
    animation = CurvedAnimation(parent: animationController!, curve: Curves.linear);
  }

  @override
  void dispose() {
    animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = Container(
        height: widget.height,
        width: widget.width,
        margin: widget.margin,
        decoration: BoxDecoration(color: widget.baseColor, borderRadius: widget.borderRadius));

    final progress = Shimmer.progressOf(context);
    if (progress != null) {
      return ShaderMask(
          shaderCallback: (rect) => LinearGradient(
                  begin: Alignment(-1 - progress, 0),
                  end: Alignment(1 + progress, 0),
                  colors: [widget.baseColor, widget.highlightColor, widget.baseColor],
                  stops: const [0.2, 0.5, 0.8])
              .createShader(rect),
          blendMode: BlendMode.srcATop,
          child: box);
    }

    final animated = animation;
    if (animated == null) return box;

    return AnimatedBuilder(
        animation: animated,
        builder: (context, child) {
          final value = animated.value;
          return ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                      begin: Alignment(-1 - value, 0),
                      end: Alignment(1 + value, 0),
                      colors: [widget.baseColor, widget.highlightColor, widget.baseColor],
                      stops: const [0.2, 0.5, 0.8])
                  .createShader(rect),
              blendMode: BlendMode.srcATop,
              child: child);
        },
        child: box);
  }
}
