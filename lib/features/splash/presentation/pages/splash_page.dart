import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    start();
  }

  /// --- Methods ---

  void goToOnboarding() => context.go(onboardingRoute);
  void goToIntroSurvey() => context.go(introSurveyRoute);
  void goToPractice() => context.go(practiceRoute);

  void start() => Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        goToPractice();
      });

  /// --- Widgets ---

  Widget get title =>
      Text('Ustadia', style: Style.headline9w7(context).copyWith(color: context.cs.primary));

  Widget get loader => SizedBox(
      width: 20,
      height: 20,
      child: CircularProgressIndicator(
          strokeWidth: 3,
          valueColor: AlwaysStoppedAnimation(context.cs.primary),
          backgroundColor: context.cs.primary.withOpacity(0.18)));

  Widget get footer => Text('Ustadia Mobile v1.0',
      textAlign: TextAlign.center, style: Style.bodyw6(context, color: TextColorRole.greyColor));

  Widget get view => Center(
        child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),
              title,
              const SizedBox(height: 24),
              loader,
              const Spacer(),
              footer
            ]),
      );

  @override
  Widget build(BuildContext context) =>
      Scaffold(backgroundColor: context.theme.scaffoldBackgroundColor, body: SafeArea(child: view));
}
