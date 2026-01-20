import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/cached_images_primary/cached_image_primary.dart';
import 'package:ustadia_user_app/core/widgets/progress_bars/circle_progress_badge.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_lesson_model.dart';

class LearnLessonCard extends StatelessWidget {
  final LearnLessonModel lessonModel;
  final VoidCallback onTap;

  const LearnLessonCard({super.key, required this.lessonModel, required this.onTap});

  String get fullImageUrl {
    final url = lessonModel.imageUrl;
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'https://backend.ustadia.findecor.io$url';
  }

  /// --- Getters ---

  String get percentProgress => '${(lessonModel.completionPercentage).round()}%';

  /// --- Widgets ---
  Widget progressBadge(BuildContext context) => CircleProgressBadge(
      indicatorValue: lessonModel.completionPercentage,
      percentProgress: percentProgress,
      isLocked: lessonModel.isLocked,
      progressColor: AppColors.primary);

  Widget title(BuildContext context) => Text(lessonModel.name,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Style.body2w5(context,
          color: lessonModel.isLocked ? TextColorRole.greyColor : TextColorRole.onSurface));

  Widget titleAndStatus(BuildContext context) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: title(context)),
            const SizedBox(width: 8),
            progressBadge(context)
          ]);

  Widget subtitle(BuildContext context) => Text(lessonModel.description,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Style.small3w5(context, color: TextColorRole.greyColor));

  Widget cardInfo(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [titleAndStatus(context), const SizedBox(height: 6), subtitle(context)]);

  Widget imagePreview() {
    if (fullImageUrl.isEmpty) {
      return Image.asset(AppImages.vocabulary, height: 80, width: 80, fit: BoxFit.cover);
    }
    return CachedImagePrimary(imageUrl: fullImageUrl, fit: BoxFit.cover);
  }

  Widget view(BuildContext context) =>
      Row(children: [imagePreview(), const SizedBox(width: 8), Expanded(child: cardInfo(context))]);

  @override
  Widget build(BuildContext context) => PrimaryBox(
      padding: const EdgeInsets.all(16),
      onTap: lessonModel.isLocked ? null : onTap,
      boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 6))],
      child: view(context));
}
