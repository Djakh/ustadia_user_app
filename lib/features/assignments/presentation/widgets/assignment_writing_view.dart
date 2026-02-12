import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_theme_catalog.dart';
import 'package:ustadia_user_app/features/assignments/presentation/widgets/assignment_upload_card.dart';

class AssignmentWritingView extends StatelessWidget {
  final VoidCallback onSubmit;

  const AssignmentWritingView({super.key, required this.onSubmit});

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                  color: AppColors.orangeEB,
                  borderRadius: Style.border32,
                  border: Border.all(color: AppColors.orangeD4)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                          color: AppColors.orangeD4, shape: BoxShape.circle),
                      child: Center(
                          child: Text(AssignmentThemeCatalog.writing.emoji,
                              style: const TextStyle(fontSize: 18)))),
                  const SizedBox(width: 12),
                  Text('Topic'.tr(), style: Style.body2w6(context))
                ]),
                const SizedBox(height: 12),
                Text('"Describe a memorable trip you took recently and why it was special."'.tr(),
                    style: Style.bodyw4(context))
              ])),
          const SizedBox(height: 20),
          Text('Upload Handwriting'.tr(), style: Style.body2w6(context)),
          const SizedBox(height: 4),
          Text('Take a clear photo of your handwritten essay'.tr(),
              style: Style.small2w4(context, color: TextColorRole.greyColor)),
          const SizedBox(height: 16),
          Row(children: [
            Expanded(
                child: AssignmentUploadCard(
                    icon: Icons.camera_alt,
                    label: 'Take Photo'.tr(),
                    backgroundColor: AppColors.orangeEB,
                    iconColor: AppColors.orange12)),
            const SizedBox(width: 12),
            Expanded(
                child: AssignmentUploadCard(
                    icon: Icons.image,
                    label: 'Upload Image'.tr(),
                    backgroundColor: AppColors.gray50,
                    iconColor: AppColors.gray500))
          ]),
          const SizedBox(height: 24),
          Button.primary(onTap: onSubmit, text: 'Submit Essay'.tr())
        ]
      );
}
