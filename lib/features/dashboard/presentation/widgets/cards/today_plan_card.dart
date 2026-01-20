import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';

class TodayPlanCard extends StatelessWidget {
  const TodayPlanCard({super.key});

  Widget _planItem(String value, String label, BuildContext context) => Column(children: [
        Text(value, style: Style.headline3w7(context).copyWith(color: AppColors.white)),
        const SizedBox(height: 4),
        Text(label, style: Style.bodyw7(context, color: TextColorRole.whiteColor))
      ]);

  Widget _divider() =>
      Container(width: 1, height: 32, color: AppColors.white.withValues(alpha: 0.4));

  Row todaysPlanInfo(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        _planItem('2', 'Quick Lessons', context),
        _divider(),
        _planItem('3', 'Games', context),
        _divider(),
        _planItem('5mins', 'Live Tutor', context)
      ]);

  Widget get startPlanButton => Button.primary(
        onTap: () {},
        color: AppColors.white,
        textColor: AppColors.black,
        text: "Start today's plan",
      );

  Widget view(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Today's plan", style: Style.small3w4(context, color: TextColorRole.whiteColor)),
        const SizedBox(height: 22),
        todaysPlanInfo(context),
        const SizedBox(height: 22),
        startPlanButton
      ]);

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [AppColors.yellowE10.withValues(alpha: 0.5), AppColors.green6B],
              stops: const [0.0, 0.9]),
          borderRadius: Style.border24),
      child: view(context));
}
