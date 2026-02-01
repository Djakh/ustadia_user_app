import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/sections_types/speaking_section/speaking_section_page.dart';

class LearnSpeakingMicButton extends StatelessWidget {
  final SpeakingSectionStage stage;
  final Function() onTap;

  const LearnSpeakingMicButton({super.key, required this.stage, required this.onTap});

  bool get isActive => stage != SpeakingSectionStage.ready;

  Color backgroundColor(BuildContext context) => isActive ? context.cs.primary : context.cs.surface;

  Widget loadingWidget(BuildContext context) => PrimaryLoadingIndicator(
      width: 70,
      height: 70,
      strokeWidth: 4,
      valueColor: AlwaysStoppedAnimation(context.cs.onPrimary),
      backgroundColor: context.cs.onPrimary.withValues(alpha: 0.2));

  SvgPicture microphoneImage() => SvgPicture.asset(
      isActive ? AppImages.learnSpeakingListening : AppImages.learnSpeakingDefault);

  Widget icon(BuildContext context) {
    if (stage == SpeakingSectionStage.checking) return loadingWidget(context);

    return microphoneImage();
  }

  Widget view(BuildContext context) => PrimaryBox(
      onTap: onTap,
      backgroundColor: backgroundColor(context),
      shape: BoxShape.circle,
      padding: const EdgeInsets.all(20),
      borderRadius: BorderRadius.circular(60),
      boxShadow: const [BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 6))],
      child: Center(child: icon(context)));

  @override
  Widget build(BuildContext context) => view(context);
}
