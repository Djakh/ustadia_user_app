import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/boxes/border_box.dart';

class LearnWritingMethodCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String image;

  final Function() onTap;
  const LearnWritingMethodCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.image,
    required this.onTap,
  });

  Expanded methodInfo(BuildContext context) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Style.bodyw5(context)),
        const SizedBox(height: 4),
        Text(subtitle, style: Style.small2w4(context, color: TextColorRole.greyColor))
      ]));

  Widget view(BuildContext context) =>
      Row(children: [SvgPicture.asset(image), const SizedBox(width: 12), methodInfo(context)]);

  @override
  Widget build(BuildContext context) =>
      PrimaryBox( onTap: onTap, child: view(context));
}
