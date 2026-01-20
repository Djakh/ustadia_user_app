import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_model.dart';

class LearnSectionCard extends StatelessWidget {
  final LearnSectionModel sectionModel;
  final VoidCallback onTap;

  const LearnSectionCard({super.key, required this.sectionModel, required this.onTap});

  /// --- Getters ---

  bool get isLocked => sectionModel.progressState == LearnSectionProgressState.locked;

  bool get isInProgress => sectionModel.progressState == LearnSectionProgressState.inProgress;

  bool get isCompleted => sectionModel.progressState == LearnSectionProgressState.completed;

  Color get statusColor => isLocked ? AppColors.gray300 : AppColors.primary;

  String get statusText {
    if (isCompleted) return 'Completed';
    if (isInProgress) return 'In progress';
    return 'Locked';
  }

  Widget title(BuildContext context) => Text(sectionModel.title,
      maxLines: 1, overflow: TextOverflow.ellipsis, style: Style.body2w5(context));

  Widget subtitle(BuildContext context) => Text(sectionModel.content,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Style.small3w5(context, color: TextColorRole.greyColor));

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
      onTap: isLocked || isCompleted ? null : onTap,
      boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 6))],
      child: view(context));
}
