import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/features/meets/data/models/student_meet_model.dart';

class StudentMeetCard extends StatelessWidget {
  final StudentMeetModel meet;
  final VoidCallback onOpenLink;

  const StudentMeetCard({super.key, required this.meet, required this.onOpenLink});

  DateTime? get localScheduledAt => meet.scheduledAt?.toLocal();

  String get dateLabel {
    final date = localScheduledAt;
    if (date == null) return '-';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String get timeLabel {
    final date = localScheduledAt;
    if (date == null) return '-';
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  bool get hasLink => meet.link.trim().isNotEmpty;

  String get typeLabel {
    if (meet.type.trim().isEmpty) return 'Meeting';
    return meet.type[0].toUpperCase() + meet.type.substring(1);
  }

  Widget iconBox(BuildContext context) => Container(
      height: 54,
      width: 54,
      decoration: BoxDecoration(color: AppColors.greenE7, borderRadius: Style.border16),
      child:
          const Center(child: Icon(Icons.video_call_rounded, color: AppColors.green36, size: 30)));

  Widget metaItem(BuildContext context, IconData icon, String label) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: AppColors.gray500),
        const SizedBox(width: 4),
        Flexible(
            child: Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Style.small2w5(context).copyWith(color: AppColors.gray500)))
      ]);

  Widget typeBadge(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: AppColors.blueFF, borderRadius: Style.border8),
      child:
          Text(typeLabel.tr(), style: Style.small2w5(context).copyWith(color: AppColors.blueD3)));

  Widget linkButton(BuildContext context) => InkWell(
      onTap: hasLink ? onOpenLink : null,
      borderRadius: Style.border12,
      child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
              color: hasLink ? AppColors.primary : AppColors.gray200, borderRadius: Style.border12),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.open_in_new_rounded, size: 18, color: AppColors.white),
            const SizedBox(width: 6),
            Text('Open meet'.tr(), style: Style.small3w5(context, color: TextColorRole.whiteColor))
          ])));

  Widget content(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          iconBox(context),
          const SizedBox(width: 12),
          Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(meet.displayTitle,
                maxLines: 2, overflow: TextOverflow.ellipsis, style: Style.body2w6(context)),
            if (meet.displayDescription.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(meet.displayDescription,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Style.small3w4(context, color: TextColorRole.greyColor))
            ]
          ])),
          const SizedBox(width: 8),
          typeBadge(context)
        ]),
        const SizedBox(height: 14),
        Wrap(spacing: 12, runSpacing: 8, children: [
          metaItem(context, Icons.calendar_today_rounded, dateLabel),
          metaItem(context, Icons.schedule_rounded, timeLabel),
          metaItem(context, Icons.person_rounded, meet.teacherName),
          if (meet.className.isNotEmpty) metaItem(context, Icons.groups_rounded, meet.className)
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(
              child: Text(meet.link,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Style.small2w4(context).copyWith(color: AppColors.gray500))),
          const SizedBox(width: 12),
          linkButton(context)
        ])
      ]);

  @override
  Widget build(BuildContext context) => PrimaryBox(
      key: ValueKey('student_meet_card_${meet.id}'),
      isTappable: false,
      padding: const EdgeInsets.all(16),
      boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))],
      child: content(context));
}
