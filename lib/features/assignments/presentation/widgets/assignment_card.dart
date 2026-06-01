import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_model.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_theme_catalog.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_type_theme.dart';

class AssignmentCard extends StatelessWidget {
  final AssignmentModel assignment;
  final VoidCallback? onTap;

  const AssignmentCard({super.key, required this.assignment, required this.onTap});

  AssignmentTypeTheme get theme =>
      AssignmentThemeCatalog.themeForType(assignment.firstSection?.sectionStringType ?? '');

  List<String?> get sectionTypes => assignment.sections
      .map((section) => section.sectionStringType?.trim().toLowerCase())
      .where((type) => type != null && type.isNotEmpty)
      .toList();

  List<String> get distinctSectionTypes {
    final set = <String>{};
    for (final type in sectionTypes) {
      if (type != null) set.add(type);
    }
    return set.toList();
  }

  String get timeLimitLabel => assignment.timeLimit > 0 ? '${assignment.timeLimit}m' : '-';

  String get sectionCountLabel =>
      assignment.sections.length == 1 ? '1 section' : '${assignment.sections.length} sections';

  bool get hasProgress => assignment.progress > 0;

  double get progressValue => assignment.progress.clamp(0, 100) / 100;

  String get statusLabel {
    if (assignment.isDeadlinePassed && !assignment.isCompleted) return 'Deadline Passed';
    if (assignment.status.isEmpty) return 'Status';
    return assignment.status[0].toUpperCase() + assignment.status.substring(1);
  }

  Color get statusBackgroundColor {
    if (assignment.isDeadlinePassed && !assignment.isCompleted) return AppColors.orangeEB;
    if (assignment.status == 'completed') return AppColors.greenE7;
    if (assignment.status == 'active') return AppColors.gray100;
    return AppColors.orangeEB;
  }

  Color get statusTextColor {
    if (assignment.isDeadlinePassed && !assignment.isCompleted) return AppColors.orange12;
    if (assignment.status == 'completed') return AppColors.success;
    if (assignment.status == 'active') return AppColors.gray500;
    return AppColors.orange12;
  }

  Widget statusBadge(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: statusBackgroundColor, borderRadius: Style.border8),
      child: Text(statusLabel, style: Style.small2w5(context).copyWith(color: statusTextColor)));

  String tagLabel(String type) => AssignmentThemeCatalog.themeForType(type).label;

  Widget typeTag(BuildContext context, String type) {
    final tagTheme = AssignmentThemeCatalog.themeForType(type);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: tagTheme.backgroundColor, borderRadius: Style.border8),
        child: Text(tagLabel(type),
            style: Style.small2w5(context).copyWith(color: tagTheme.textColor)));
  }

  Widget typeTags(BuildContext context) => Wrap(
      spacing: 8,
      runSpacing: 6,
      children: distinctSectionTypes.map((type) => typeTag(context, type)).toList());

  Widget progressRow(BuildContext context) => Column(children: [
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Progress'.tr(), style: Style.small2w4(context, color: TextColorRole.greyColor)),
          Text('${assignment.progress}%',
              style: Style.small2w5(context, color: TextColorRole.greyColor))
        ]),
        const SizedBox(height: 8),
        ClipRRect(
            borderRadius: Style.border8,
            child: LinearProgressIndicator(
                value: progressValue,
                minHeight: 8,
                backgroundColor: AppColors.gray100,
                color: AppColors.orange13))
      ]);

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: assignment.canOpen ? onTap : null,
      borderRadius: Style.border24,
      child: Opacity(
          opacity: assignment.canOpen || assignment.isCompleted ? 1 : 0.72,
          child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: Style.border24,
                  border: Border.all(color: AppColors.gray100),
                  boxShadow: const [
                    BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))
                  ]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                      width: 54,
                      height: 54,
                      decoration:
                          BoxDecoration(color: theme.backgroundColor, borderRadius: Style.border16),
                      child:
                          Center(child: Text(theme.emoji, style: const TextStyle(fontSize: 22)))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(assignment.title, style: Style.body2w6(context)),
                    const SizedBox(height: 4),
                    Text(assignment.description,
                        style: Style.small2w4(context, color: TextColorRole.greyColor))
                  ])),
                  statusBadge(context)
                ]),
                const SizedBox(height: 12),
                typeTags(context),
                const SizedBox(height: 12),
                Row(children: [
                  const Icon(Icons.timer, size: 12, color: AppColors.gray400),
                  const SizedBox(width: 4),
                  Text(timeLimitLabel,
                      style: Style.small2w4(context, color: TextColorRole.greyColor)),
                  const SizedBox(width: 8),
                  Text(sectionCountLabel,
                      style: Style.small2w4(context, color: TextColorRole.greyColor))
                ]),
                if (hasProgress) progressRow(context)
              ]))));
}
