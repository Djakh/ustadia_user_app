import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/progress_bars/circle_progress_badge.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_unit_model.dart';

class LearnUnitCard extends StatelessWidget {
  final LearnUnitModel unit;

  const LearnUnitCard({super.key, required this.unit});

  /// --- Getters ---
  Color get progressColor =>
      unit.progressState == LearnUnitProgressState.locked ? AppColors.gray200 : AppColors.primary;

  Color titleColor(BuildContext context) => unit.progressState == LearnUnitProgressState.locked
      ? context.cs.onTertiary
      : context.cs.onSurface;

  double get indicatorValue =>
      unit.progressState == LearnUnitProgressState.locked ? 0 : unit.progressPercent;

  String get percentProgress => '${(unit.progressPercent * 100).round()}%';

  /// --- Widgets ---
  Widget progressBadge(BuildContext context) => CircleProgressBadge(
      indicatorValue: indicatorValue,
      percentProgress: percentProgress,
      progressColor: progressColor);

  Widget unitLabel(BuildContext context) => Text('Unit ${unit.unitNumber}',
      style: Style.small3w4(context, color: TextColorRole.primaryColor));

  Row unitLabelAndProgressBadge(BuildContext context) => Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [unitLabel(context), progressBadge(context)]);

  Widget title(BuildContext context) => Text(unit.title,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Style.bodyw7(context).copyWith(color: titleColor(context)));

  Widget get imagePreview => Align(
      alignment: Alignment.bottomRight,
      child: Image.network(unit.imageUrl, height: 110, width: 110, fit: BoxFit.contain));

  Widget view(BuildContext context) => Stack(children: [
        Positioned(bottom: 0, right: 0, child: imagePreview),
        Positioned.fill(
            child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  unitLabelAndProgressBadge(context),
                  title(context),
                  const Spacer()
                ]))),
      ]);

  @override
  Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(
          color: context.cs.surface,
          borderRadius: Style.border20,
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 6))
          ]),
      child: view(context));
}
