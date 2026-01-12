import 'package:flutter/material.dart';

class PrimaryCircularProgressIndicator extends StatelessWidget {
  final double height;
  final double width;
  final bool isCenter;
  final double strokeWidth;
  final Animation<Color?>? valueColor;
  final Color? backgroundColor;
  const PrimaryCircularProgressIndicator(
      {super.key,
      this.isCenter = true,
      this.height = 20,
      this.width = 20,
      this.strokeWidth = 2,
      this.valueColor,
      this.backgroundColor});

  Widget get circleProgreccIndicator => SizedBox(
      height: height,
      width: width,
      child: CircularProgressIndicator(
          strokeWidth: strokeWidth, valueColor: valueColor, backgroundColor: backgroundColor));

  Widget get view => isCenter ? Center(child: circleProgreccIndicator) : circleProgreccIndicator;

  @override
  Widget build(BuildContext context) => view;
}
