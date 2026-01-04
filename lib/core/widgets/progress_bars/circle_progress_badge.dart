import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class CircleProgressBadge extends StatelessWidget {
  final double? indicatorValue;
  final String percentProgress;
  final Color? progressColor;
  final double? size;
  const CircleProgressBadge(
      {super.key,
      this.indicatorValue,
      required this.percentProgress,
      this.progressColor,
      this.size});

  Widget view(BuildContext context) => Stack(alignment: Alignment.center, children: [
        SizedBox(
            width: size ?? 36,
            height: size ?? 36,
            child: CircularProgressIndicator(
                value: indicatorValue,
                strokeWidth: 3,
                backgroundColor: AppColors.gray100,
                valueColor: AlwaysStoppedAnimation(progressColor ?? AppColors.primary))),
        Text(percentProgress,
            style: Style.smallw7(context).copyWith(color: progressColor ?? AppColors.primary))
      ]);

  @override
  Widget build(BuildContext context) => view(context);
}
