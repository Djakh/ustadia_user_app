import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_model.dart';

class MockExamCard extends StatelessWidget {
  final MockExamModel exam;
  final VoidCallback onTap;

  const MockExamCard({super.key, required this.exam, required this.onTap});

  bool get isActive => exam.status.toLowerCase() == 'active' || exam.assignment?.isActive == true;

  bool get isFinished => exam.isFinished;

  Color get statusBackgroundColor => isFinished
      ? AppColors.greenE7
      : isActive
          ? AppColors.orangeEB
          : AppColors.gray100;

  Color get statusTextColor => isFinished
      ? AppColors.success
      : isActive
          ? AppColors.orange12
          : AppColors.gray500;

  String get statusLabel {
    if (exam.isFinished) return 'Completed';
    if (exam.isStarted) return 'In Progress';
    final assignmentStatus = exam.assignment?.status ?? '';
    if (assignmentStatus.isNotEmpty && assignmentStatus.toLowerCase() != 'started') {
      return assignmentStatus;
    }
    if (exam.status.isEmpty && exam.assign == null) return '';
    if (exam.assign != null) return 'In Progress';
    return exam.status[0].toUpperCase() + exam.status.substring(1);
  }

  bool get hasStatus => statusLabel.isNotEmpty;

  String get countdownLabel {
    final duration = exam.remainingDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  Widget statusBadge(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: statusBackgroundColor, borderRadius: Style.border8),
      child:
          Text(statusLabel.tr(), style: Style.small2w5(context).copyWith(color: statusTextColor)));

  Widget timerBadge(BuildContext context) {
    if (!exam.hasDeadline) return const SizedBox.shrink();
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: AppColors.blueFF, borderRadius: Style.border8),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.timer_outlined, size: 14, color: AppColors.blueD3),
          const SizedBox(width: 4),
          Text(countdownLabel, style: Style.small2w5(context).copyWith(color: AppColors.blueD3))
        ]));
  }

  Widget iconBox(BuildContext context) => Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(color: AppColors.orangeBE, borderRadius: Style.border16),
      child: const Center(child: Icon(Icons.school_rounded, color: AppColors.white, size: 28)));

  Widget content(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          iconBox(context),
          const SizedBox(width: 12),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(exam.title, style: Style.body2w6(context)),
            const SizedBox(height: 4),
            Text(exam.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Style.small3w4(context, color: TextColorRole.greyColor))
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (hasStatus) statusBadge(context),
            if (exam.hasDeadline) ...[const SizedBox(height: 6), timerBadge(context)]
          ])
        ])
      ]);

  @override
  Widget build(BuildContext context) => PrimaryBox(
      key: ValueKey('mock_exam_card_${exam.id}'),
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))],
      child: content(context));
}
