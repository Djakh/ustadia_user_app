import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ustadia_user_app/features/onboarding/data/models/slide_model.dart';
import 'package:ustadia_user_app/features/onboarding/widgets/onboarding_slide_view.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _controller = PageController();
  int _pageIndex = 0;
  bool didShowLanguagePicker = false;

  List<SlideModel> get slides => [
        SlideModel(
            title: 'Speak Fearlessly'.tr(),
            description: 'Chat with your AI tutor anytime, anywhere.\nNo judgment, just practice.',
            asset: AppImages.onboard1,
            background: AppColors.green49,
            accent: AppColors.green50),
        SlideModel(
            title: 'Micro-learning'.tr(),
            description:
                'Master new words and grammar with fun,\nbite-sized practices in just 5 minutes a day.',
            asset: AppImages.onboard2,
            background: AppColors.purpleC3,
            accent: AppColors.purpleD6),
        SlideModel(
            title: 'See Your Growth'.tr(),
            description:
                'Get instant feedback on your pronunciation\nand track your daily progress.',
            asset: AppImages.onboard3,
            background: AppColors.orange13,
            accent: AppColors.orange12)
      ];

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => showLanguagePicker());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// --- Methods ---

  Future<void> goToLogin() async {
    await sl<AuthLocalDataSource>().setIntroSeen(true);
    if (!mounted) return;
    context.go(loginRoute);
  }

  Future<void> showLanguagePicker() async {
    if (!mounted || didShowLanguagePicker) return;
    didShowLanguagePicker = true;
    await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: Style.border20),
            title: Text('Choose language'.tr(), style: Style.body2w7(dialogContext)),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              languageOption(dialogContext, title: 'English'.tr(), key: 'en'),
              const SizedBox(height: 10),
              languageOption(dialogContext, title: 'Russian'.tr(), key: 'ru'),
              const SizedBox(height: 10),
              languageOption(dialogContext, title: 'Uzbek'.tr(), key: 'uz'),
            ])));
  }

  void onContinue() {
    if (_pageIndex < slides.length - 1) {
      _controller.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeOutCubic);
      return;
    }
    goToLogin();
  }

  /// --- Widgets ---

  Widget languageOption(BuildContext dialogContext, {required String title, required String key}) =>
      Button.border(
          onTap: () async {
            await context.setLocale(Locale(key));
            if (!dialogContext.mounted) return;
            Navigator.of(dialogContext).pop();
            if (mounted) setState(() {});
          },
          color: context.locale.languageCode == key ? AppColors.greenE7 : AppColors.white,
          borderColor: context.locale.languageCode == key ? AppColors.primary : AppColors.grayF4,
          child: Row(children: [
            languageIcon(key),
            const SizedBox(width: 12),
            Expanded(child: Text(title, style: Style.bodyw6(dialogContext))),
            if (context.locale.languageCode == key)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary)
          ]));

  Widget languageIcon(String key) {
    final asset = switch (key) {
      'ru' => AppImages.settingsRussian,
      'uz' => AppImages.settingsUzbek,
      _ => AppImages.settingsEnglish
    };
    return SvgPicture.asset(asset, width: 28, height: 28);
  }

  Widget get header => Row(children: [
        Expanded(
            child: PageIndicator(
          currentIndex: _pageIndex,
          total: slides.length,
          activeColor: Colors.white.withAlpha(230),
          inactiveColor: Colors.white.withAlpha(140),
          isFilledIndicators: false,
        )),
        skipButton()
      ]);

  TextButton skipButton() => TextButton(
        onPressed: () => goToLogin(),
        child: Text('Skip'.tr(), style: Style.small3w4(context, color: TextColorRole.whiteColor)),
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
