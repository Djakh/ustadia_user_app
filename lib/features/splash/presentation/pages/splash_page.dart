import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_state.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  final UserBloc userBloc = sl<UserBloc>();
  bool isCheckingUser = false;

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    start();
  }

  /// --- Listeners ---

  void userListener(context, state) {
    if (!isCheckingUser) return;
    if (state.status == Status.success) {
      isCheckingUser = false;
      final profile = state.profile;
      if (profile != null && profile.introCompleted) {
        goToDashboard();
        return;
      }
      goToIntroSurvey();
    }
    if (state.status == Status.error) {
      isCheckingUser = false;
      goToLogin();
    }
  }

  /// --- Methods ---

  void goToOnboarding() => context.go(onboardingRoute);
  void goToLogin() => context.go(loginRoute);

  void goToIntroSurvey() => context.go(introSurveyRoute);
  void goToPractice() => context.go(practiceRoute);
  void goToDashboard() => context.go(dashboardRoute);

  void start() => Future.delayed(const Duration(seconds: 2), () {
        if (!mounted) return;
        final authLocal = sl<AuthLocalDataSource>();
        final hasToken = authLocal.hasAccessToken();
        if (hasToken) {
          isCheckingUser = true;
          userBloc.add(const UserProfileRequested());
          return;
        }
        if (!authLocal.isIntroSeen()) {
          goToOnboarding();
          return;
        }
        goToLogin();
      });

  /// --- Widgets ---

  Widget get title =>
      Text('Ustadia'.tr(), style: Style.headline9w7(context).copyWith(color: context.cs.primary));

  Widget get loader => PrimaryLoadingIndicator(
      strokeWidth: 3,
      valueColor: AlwaysStoppedAnimation(context.cs.primary),
      backgroundColor: context.cs.primary.withValues(alpha: 0.18));

  Widget get footer => Text('Ustadia Mobile v1.0'.tr(),
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
  Widget build(BuildContext context) => BlocListener<UserBloc, UserState>(
      bloc: userBloc,
      listener: userListener,
      child: Scaffold(
          backgroundColor: context.theme.scaffoldBackgroundColor, body: SafeArea(child: view)));
}
