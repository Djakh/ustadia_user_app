import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/assignments/presentation/widgets/assignment_result_row.dart';

class AssignmentResultCard extends StatelessWidget {
  final VoidCallback onContinue;

  const AssignmentResultCard({super.key, required this.onContinue});

  @override
  Widget build(BuildContext context) => Center(
      child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: Style.border32,
              border: Border.all(color: AppColors.gray100),
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 8))
              ]),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(color: AppColors.greenE7, shape: BoxShape.circle),
                child: const Icon(Icons.check, size: 40, color: AppColors.success)),
            const SizedBox(height: 16),
            Text('Excellent!', style: Style.headlinew7(context)),
            const SizedBox(height: 8),
            Text('You passed the assignment with a high score.',
                textAlign: TextAlign.center,
                style: Style.bodyw4(context, color: TextColorRole.greyColor)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.gray50, borderRadius: Style.border20),
                      child: Column(children: [
                        Text('Score',
                            style: Style.smallw7(context, color: TextColorRole.greyColor)),
                        const SizedBox(height: 6),
                        Text('92/100', style: Style.body2w6(context))
                      ]))),
              const SizedBox(width: 12),
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.gray50, borderRadius: Style.border20),
                      child: Column(children: [
                        Text('Time', style: Style.smallw7(context, color: TextColorRole.greyColor)),
                        const SizedBox(height: 6),
                        Text('12m', style: Style.body2w6(context))
                      ])))
            ]),
            const SizedBox(height: 20),
            const Column(children: [
              AssignmentResultRow(text: 'Perfect pronunciation on key terms'),
              SizedBox(height: 8),
              AssignmentResultRow(text: 'Great use of vocabulary')
            ]),
            const SizedBox(height: 20),
            Button.primary(onTap: onContinue, text: 'Continue Learning')
          ])));
}
