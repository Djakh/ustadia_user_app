import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/core/widgets/text/html_text.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

class LearnSectionCard extends StatelessWidget {
  final SectionModel sectionModel;
  final VoidCallback onTap;

  const LearnSectionCard({super.key, required this.sectionModel, required this.onTap});

  /// --- Getters ---

  bool get isLocked => sectionModel.progressState == SectionProgressState.locked;

  bool get isInProgress => sectionModel.progressState == SectionProgressState.inProgress;

  bool get isCompleted => sectionModel.progressState == SectionProgressState.completed;

  Color get statusColor => isLocked ? AppColors.gray300 : AppColors.primary;

  String get statusText {
    if (isCompleted) return 'Completed';
    if (isInProgress) return 'In progress';
    return 'Locked';
  }

  Widget title(BuildContext context) => Text(sectionModel.title,
      maxLines: 1, overflow: TextOverflow.ellipsis, style: Style.body2w5(context));

  Widget subtitle(BuildContext context) => HtmlText(
      data: sectionModel.content,
      maxLines: 2,
      textStyle: Style.small3w5(context, color: TextColorRole.greyColor));

  Widget progressBadge(BuildContext context) => Row(children: [
        if (isCompleted) Icon(Icons.check_circle, size: 16, color: statusColor),
        const SizedBox(width: 4),
        Text(statusText, style: Style.small2w5(context).copyWith(color: statusColor))
      ]);

  Widget iconImage(BuildContext context) =>
      Image.asset(sectionModel.iconAsset, height: 56, width: 56);

  Widget statusBadge(BuildContext context) => Row(children: [
        Icon(Icons.check_circle, size: 16, color: statusColor),
        const SizedBox(width: 4),
        Text(statusText, style: Style.small2w5(context).copyWith(color: statusColor))
      ]);
  Widget titleAndStatus(BuildContext context) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title(context)),
            const SizedBox(width: 8),
            progressBadge(context)
          ]);

  Widget cardInfo(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [titleAndStatus(context), const SizedBox(height: 6), subtitle(context)]);

  Widget view(BuildContext context) => Row(children: [
        Image.asset(sectionModel.iconAsset, height: 56, width: 56),
        const SizedBox(width: 8),
        Expanded(child: cardInfo(context))
      ]);

  @override
  Widget build(BuildContext context) => PrimaryBox(
      padding: const EdgeInsets.all(16),
      //onTap:  onTap,
       onTap: isLocked || isCompleted ? null : onTap,
      boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 6))],
      child: view(context));
}
