import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/features/assignments/presentation/pages/assignment_details_phase.dart';

class AssignmentDetailsHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final AssignmentDetailsPhase phase;

  const AssignmentDetailsHeader(
      {super.key, required this.title, required this.subtitle, required this.phase});

  String get phaseLabel => phase == AssignmentDetailsPhase.quiz ? 'Quiz' : 'Question 1';

  @override
  Widget build(BuildContext context) => Column(children: [
        Row(children: [
          GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: const [
                        BoxShadow(color: AppColors.shadow, blurRadius: 8, offset: Offset(0, 4))
                      ]),
                  child: const Icon(Icons.chevron_left, color: AppColors.gray700))),
          Expanded(
              child: Column(children: [
            Text(title, style: Style.bodyw6(context)),
            const SizedBox(height: 2),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: Style.small2w4(context, color: TextColorRole.greyColor))
          ])),
          const SizedBox(width: 40)
        ]),
        const SizedBox(height: 16),
        const PageIndicator(
            currentIndex: 0,
            total: 5,
            itemHeight: 6,
            spacing: 6,
            isExpanded: true,
            activeColor: AppColors.primary,
            inactiveColor: AppColors.greenE7),
        const SizedBox(height: 6),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(phaseLabel, style: Style.smallw7(context, color: TextColorRole.greyColor)),
          Text('Total: 5'.tr(), style: Style.smallw7(context, color: TextColorRole.greyColor))
        ])
      ]);
}
