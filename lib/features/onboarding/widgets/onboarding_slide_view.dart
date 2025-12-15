import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/onboarding/data/models/slide_model.dart';
import 'package:ustadia_user_app/features/onboarding/widgets/back_drop.dart';

class OnboardingSlideView extends StatelessWidget {
  const OnboardingSlideView({super.key, required this.slide});

  final SlideModel slide;

  /// --- Widgets ---

  Widget get image => Center(
      child: Hero(
          tag: slide.asset, child: Image.asset(slide.asset, fit: BoxFit.contain, height: 290)));

  Widget view(BuildContext context) => SafeArea(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const SizedBox(height: 16),
            image,
            const SizedBox(height: 8),
            Text(slide.title,
                textAlign: TextAlign.center,
                style: Style.headlinew7(context, color: TextColorRole.whiteColor)),
            const SizedBox(height: 8),
            Text(slide.description,
                textAlign: TextAlign.center,
                style: Style.bodyw5(context, color: TextColorRole.whiteColor)),
            const SizedBox(height: 96)
          ])));

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(child: Backdrop(background: slide.background, accent: slide.accent)),
        view(context)
      ]);
}
