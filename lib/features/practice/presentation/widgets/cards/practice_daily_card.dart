import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';

class PracticeDailyCard extends StatelessWidget {
  const PracticeDailyCard({super.key});

  /// --- Widgets ---

  Widget title(BuildContext context) =>
      Text('Daily challenge'.tr(), style: Style.body3w7(context, color: TextColorRole.whiteColor));

  Widget subtitle(BuildContext context) => Text('Finish 3 mini games today'.tr(),
      style: Style.bodyw4(context, color: TextColorRole.whiteColor));

  Widget button(BuildContext context) => Button.border(
        onTap: () {},
        height: 46,
        text: 'Start challenge'.tr(),
        textStyle: Style.bodyw5(context).copyWith(color: AppColors.orange09),
      );

  Widget view(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          borderRadius: Style.border20,
          image: const DecorationImage(
              image: AssetImage(AppImages.dailyChallangeBackground), fit: BoxFit.cover)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        title(context),
        subtitle(context),
        const SizedBox(height: 20),
        button(context)
      ]));

  @override
  Widget build(BuildContext context) => view(context);
}
