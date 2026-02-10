import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';

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
  late final AnimationController animationController;

  @override
  void initState() {
    super.initState();
    animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
          ..repeat();
  }

  @override
  void dispose() {
    animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final box = Container(
        height: widget.height,
        width: widget.width,
        margin: widget.margin,
        decoration: BoxDecoration(color: widget.baseColor, borderRadius: widget.borderRadius));

    return AnimatedBuilder(
        animation: animationController,
        builder: (context, child) {
          final value = animationController.value;
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
