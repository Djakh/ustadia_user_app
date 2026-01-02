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
  const DashboardGridCard(
      {super.key,
      required this.title,
      required this.subtitle,
      required this.cardColor,
      required this.height,
      required this.backImage,
      required this.onTap});

  /// --- Widgets ---

  Widget _arrowButton() => Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(999)),
      child: const Icon(Icons.arrow_forward, size: 20));

  Widget view(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: Style.body2w6(context)),
        const SizedBox(height: 4),
        Text(subtitle, style: Style.small2w4(context, color: TextColorRole.greyColor)),
        const Spacer(),
        Align(alignment: Alignment.bottomLeft, child: _arrowButton())
      ]);

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      child: Container(
          height: height,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              borderRadius: Style.border16,
              color: cardColor,
              image: DecorationImage(image: AssetImage(backImage), fit: BoxFit.fill)),
          child: view(context)));
}
