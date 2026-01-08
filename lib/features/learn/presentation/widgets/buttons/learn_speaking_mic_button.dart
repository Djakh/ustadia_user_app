import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_speaking/learn_speaking_page.dart';

class LearnSpeakingMicButton extends StatelessWidget {
  final LearnSpeakingStage stage;
  final Function() onTap;

  const LearnSpeakingMicButton({super.key, required this.stage, required this.onTap});

  bool get isActive => stage != LearnSpeakingStage.ready;

  Color backgroundColor(BuildContext context) => isActive ? context.cs.primary : context.cs.surface;

  SizedBox loadingWidget(BuildContext context) => SizedBox(
      width: 80,
      height: 80,
      child: CircularProgressIndicator(
          strokeWidth: 4,
          valueColor: AlwaysStoppedAnimation(context.cs.onPrimary),
          backgroundColor: context.cs.onPrimary.withValues(alpha: 0.2)));

  SvgPicture microphoneImage() => SvgPicture.asset(
      isActive ? AppImages.learnSpeakingListening : AppImages.learnSpeakingDefault);

  Widget icon(BuildContext context) {
    if (stage == LearnSpeakingStage.checking) return loadingWidget(context);

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
