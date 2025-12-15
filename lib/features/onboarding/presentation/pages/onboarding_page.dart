import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/onboarding/data/models/slide_model.dart';
import 'package:ustadia_user_app/features/onboarding/widgets/onboarding_slide_view.dart';
import 'package:ustadia_user_app/features/onboarding/widgets/page_indicator.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _pageIndex = 0;

  List<SlideModel> get slides => [
        const SlideModel(
            title: 'Speak Fearlessly',
            description: 'Chat with your AI tutor anytime, anywhere.\nNo judgment, just practice.',
            asset: AppImages.onboard1,
            background: AppColors.green49,
            accent: AppColors.green50),
        const SlideModel(
            title: 'Micro-learning',
            description:
                'Master new words and grammar with fun,\nbite-sized practices in just 5 minutes a day.',
            asset: AppImages.onboard2,
            background: AppColors.purplec3,
            accent: AppColors.purpled6),
        const SlideModel(
            title: 'See Your Growth',
            description:
                'Get instant feedback on your pronunciation\nand track your daily progress.',
            asset: AppImages.onboard3,
            background: AppColors.orange13,
            accent: AppColors.orange12)
      ];

  /// --- Life cycle ---

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// --- Methods ---

  void goToHome() => context.go(postsRoute);

  void onContinue() {
    if (_pageIndex < slides.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
      return;
    }
    goToHome();
  }

  /// --- Widgets ---

  Widget get header => Row(children: [
        Expanded(child: PageIndicator(currentIndex: _pageIndex, total: slides.length)),
        skipButton()
      ]);

  TextButton skipButton() => TextButton(
        onPressed: goToHome,
        child: Text('Skip', style: Style.small3w4(context, color: TextColorRole.whiteColor)),
      );

  Widget get pageView => PageView.builder(
      controller: _controller,
      itemCount: slides.length,
      onPageChanged: (value) => setState(() => _pageIndex = value),
      itemBuilder: (context, index) => OnboardingSlideView(slide: slides[index]));

  Widget get continueButton => Button.border(
        onTap: onContinue,
        text: _pageIndex == slides.length - 1 ? 'Get Started' : 'Continue',
      );

  @override
  Widget build(BuildContext context) => Scaffold(
          body: Stack(children: [
        pageView,
        Positioned(left: 24, right: 24, top: 12, child: SafeArea(bottom: false, child: header)),
        Positioned(
            left: 24, right: 24, bottom: 24, child: SafeArea(top: false, child: continueButton))
      ]));
}
