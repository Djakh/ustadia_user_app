import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/cached_images_primary/cached_image_primary.dart';
import 'package:ustadia_user_app/core/widgets/progress_bars/circle_progress_badge.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_unit_model.dart';

class LearnUnitCard extends StatelessWidget {
  final LearnUnitModel unit;
  final VoidCallback onTap;

  const LearnUnitCard({super.key, required this.unit, required this.onTap});

  /// --- Getters ---
  bool get isLocked => unit.progressState == LearnUnitProgressState.locked;

  Color titleColor(BuildContext context) => isLocked ? context.cs.onTertiary : context.cs.onSurface;

  String get percentProgress => '${(unit.progressPercent).round()}%';

  /// --- Widgets ---

  Widget progressBadge(BuildContext context) => CircleProgressBadge(
      indicatorValue: unit.progressPercent,
      percentProgress: percentProgress,
      size: isLocked ? 20 : 30,
      isLocked: isLocked);

  Widget unitLabel(BuildContext context) => Text('Unit {number}'.tr(
      namedArgs: {'number': unit.unitNumber.toString()}),
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
      child: CachedImagePrimary(imageUrl: unit.imageUrl, height: 110, width: 110));

  Widget view(BuildContext context) => Stack(children: [
        Positioned(bottom: 0, right: 0, child: imagePreview),
        Positioned.fill(
            child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  unitLabelAndProgressBadge(context),
                  title(context),
                  const Spacer()
                ]))),
      ]);

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: isLocked ? null : onTap,
      child: Container(
          decoration: BoxDecoration(
              color: context.cs.surface,
              borderRadius: Style.border20,
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 6))
              ]),
          child: view(context)));
}
