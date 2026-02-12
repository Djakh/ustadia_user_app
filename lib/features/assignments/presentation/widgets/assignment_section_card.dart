import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_theme_catalog.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_type_theme.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

class AssignmentSectionCard extends StatelessWidget {
  final SectionModel section;
  final VoidCallback onTap;

  const AssignmentSectionCard({super.key, required this.section, required this.onTap});

  String get sectionTypeLabel {
    if (section.sectionStringType == null || section.sectionStringType!.isEmpty) return 'Section';
    return section.sectionStringType![0].toUpperCase() + section.sectionStringType!.substring(1);
  }

  String get durationLabel =>
      section.timeLimit != null && section.timeLimit! > 0 ? '${section.timeLimit}m' : '-';

  AssignmentTypeTheme get theme =>
      AssignmentThemeCatalog.themeForType(section.sectionStringType ?? "");

  bool get isCompleted => section.progressState == SectionProgressState.completed;

  Widget iconBadge() => Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(color: theme.backgroundColor, borderRadius: Style.border16),
      child: Center(child: Text(theme.emoji, style: const TextStyle(fontSize: 22))));

  Widget tag(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: theme.backgroundColor, borderRadius: Style.border8),
      child:
          Text(sectionTypeLabel, style: Style.small2w5(context).copyWith(color: theme.textColor)));

  Widget playButton() => Container(
      width: 32,
      height: 32,
      decoration:
          BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.gray200)),
      child: const Icon(Icons.play_arrow, size: 16, color: AppColors.gray400));

  Widget completedLabel(BuildContext context) =>
      Text('Completed'.tr(), style: Style.small2w5(context).copyWith(color: AppColors.success));

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: isCompleted ? null : onTap,
      borderRadius: Style.border24,
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: Style.border24,
              border: Border.all(color: AppColors.gray100),
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))
              ]),
          child: Row(children: [
            iconBadge(),
            const SizedBox(width: 14),
            Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(section.title, style: Style.bodyw6(context)),
              const SizedBox(height: 6),
              Row(children: [
                tag(context),
                const SizedBox(width: 8),
                Row(children: [
                  const Icon(Icons.access_time, size: 12, color: AppColors.gray400),
                  const SizedBox(width: 4),
                  Text(durationLabel,
                      style: Style.small2w4(context, color: TextColorRole.greyColor))
                ]),
                const SizedBox(width: 8),
                Text('{count} Q'.tr(namedArgs: {'count': '${section.questions.length}'}),
                    style: Style.small2w5(context).copyWith(color: AppColors.gray400))
              ])
            ])),
            const SizedBox(width: 12),
            isCompleted ? completedLabel(context) : playButton()
          ])));
}
