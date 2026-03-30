import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class DashboardGridCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color cardColor;
  final double height;
  final String backImage;
  final Function() onTap;
  final bool isEnabled;
  const DashboardGridCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.cardColor,
      required this.height,
      required this.backImage,
      required this.onTap,
      this.isEnabled = true});

  /// --- Widgets ---

  Widget arrowButton() => Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
          color: isEnabled ? AppColors.white : AppColors.gray200,
          borderRadius: BorderRadius.circular(999)),
      child: Icon(Icons.arrow_forward, size: 20, color: isEnabled ? AppColors.black : AppColors.gray500));

  Color titleColor() => isEnabled ? AppColors.black : AppColors.gray500;

  Color subtitleColor() => isEnabled ? AppColors.gray700 : AppColors.gray500;

  Widget view(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Style.body2w6(context).copyWith(color: titleColor())),
        const SizedBox(height: 4),
        Text(subtitle, style: Style.small2w4(context).copyWith(color: subtitleColor())),
        const Spacer(),
        Align(alignment: Alignment.bottomLeft, child: arrowButton())
      ]);

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      child: Container(
          height: height,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              borderRadius: Style.border16,
              color: isEnabled ? cardColor : AppColors.gray100,
              image: DecorationImage(
                  image: AssetImage(backImage),
                  fit: BoxFit.fill,
                  opacity: isEnabled ? 1 : 0.18)),
          child: view(context)));
}
