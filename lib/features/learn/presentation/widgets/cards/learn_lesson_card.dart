import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_lesson_model.dart';

class LearnLessonCard extends StatelessWidget {
  final LearnLessonModel lesson;
  final VoidCallback onTap;

  const LearnLessonCard({super.key, required this.lesson, required this.onTap});

  Color get statusColor => lesson.progressState == LearnLessonProgressState.locked
      ? AppColors.gray300
      : AppColors.primary;

  String get statusText {
    if (lesson.progressState == LearnLessonProgressState.completed) return 'Completed';
    if (lesson.progressState == LearnLessonProgressState.inProgress) return 'In progress';
    return 'Locked';
  }

  Widget iconContainer(BuildContext context) =>
      Image.asset(lesson.iconAsset, height: 56, width: 56);

  Widget title(BuildContext context) => Text(lesson.title, style: Style.body2w5(context));

  Widget statusBadge(BuildContext context) => Row(children: [
        Icon(Icons.check_circle, size: 16, color: statusColor),
        const SizedBox(width: 4),
        Text(statusText, style: Style.small2w5(context).copyWith(color: statusColor))
      ]);
  Widget titleAndStatus(BuildContext context) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [title(context), statusBadge(context)]);

  Widget subtitle(BuildContext context) =>
      Text(lesson.subtitle, style: Style.small3w5(context, color: TextColorRole.greyColor));

  Widget cardInfo(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [titleAndStatus(context), const SizedBox(height: 2), subtitle(context)]);

  Widget view(BuildContext context) => Row(children: [
        iconContainer(context),
        const SizedBox(width: 12),
        Expanded(child: cardInfo(context)),
      ]);

  @override
  Widget build(BuildContext context) => Material(
      color: Colors.transparent,
      child: InkWell(
          onTap: onTap,
          borderRadius: Style.border20,
          child: Ink(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: context.cs.surface,
                  borderRadius: Style.border20,
                  boxShadow: const [
                    BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 6))
                  ]),
              child: view(context))));
}
