import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/features/auth/presentation/pages/login_page.dart';
import 'package:ustadia_user_app/features/auth/presentation/pages/otp_page.dart';
import 'package:ustadia_user_app/features/auth/presentation/pages/sign_up_page.dart';
import 'package:ustadia_user_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:ustadia_user_app/features/home/presentation/home_page.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/pages/intro_survey_page.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_page.dart';
import 'package:ustadia_user_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/build_sentence_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/flashcard_sprint/flashcard_sprint_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/flashcard_sprint/flashcard_sprint_result_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/listen_tap_pages/listen_tap_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/practice_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/speed_mix/speed_mix_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/speed_mix/speed_mix_result_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/speed_mix/speed_mix_start_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/vocabulary_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/word_match_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/writing_assessment_page.dart';
import 'package:ustadia_user_app/features/splash/presentation/pages/splash_page.dart';

/// --------------------
/// Authentication
/// --------------------
const splashRoute = '/';
const onboardingRoute = '/onboarding';
const introSurveyRoute = '/intro-survey';
const loginRoute = '/login';
const otpRoute = '/otp';
const signUpRoute = '/sign-up';

/// --------------------
/// HOME Shell routes
/// --------------------

const homeRoute = '/home';
const learnRoute = '$homeRoute/learn';

const dashboardRoute = '$homeRoute/dashboard';
const practiceRoute = '$homeRoute/practice';
const askAiRoute = '$homeRoute/ask-ai';
const profileRoute = '$homeRoute/profile';

/// --------------------
/// Practice routes
/// --------------------
const flashcardSprintRoute = 'flashcard-sprint';
const flashcardSprintResultRoute = 'flashcard-sprint/result';
const wordMatchRoute = 'word-match';
const buildSentenceRoute = 'build-sentence';
const writingAssessmentRoute = 'writing-assessment';
const listenTapRoute = 'listen-tap';
const vocabularyRoute = 'vocabulary';
const speedMixRoute = 'speed-mix';
const speedMixPracticeRoute = 'speed-mix/play';
const speedMixResultRoute = 'speed-mix/result';

/// Other

const postsRoute = '$homeRoute/posts';

final appRouter = GoRouter(initialLocation: splashRoute, routes: [
  /// ----------- NO-SHELL PAGES -----------
  GoRoute(path: splashRoute, builder: (context, state) => const SplashPage()),
  GoRoute(path: onboardingRoute, builder: (context, state) => const OnboardingPage()),
  GoRoute(path: introSurveyRoute, builder: (context, state) => const IntroSurveyPage()),
  GoRoute(path: loginRoute, builder: (context, state) => const LoginPage()),
  GoRoute(
    path: otpRoute,
    builder: (context, state) => OtpPage(contact: (state.extra as String?) ?? ''),
  ),
  GoRoute(path: signUpRoute, builder: (context, state) => const SignUpPage()),

  /// ----------- SHELL (BOTTOM NAV) -----------
  StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return HomePage(navigationShell: navigationShell);
      },
      branches: [
        /// 0) Dashboard
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: dashboardRoute,
              pageBuilder: (context, state) => const NoTransitionPage(child: DashboardPage()),
            ),
          ],
        ),

        /// 1) Posts
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: learnRoute,
              pageBuilder: (context, state) => const NoTransitionPage(child: LearnPage()),
            ),
          ],
        ),

        /// 2) Practice + nested flows
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: practiceRoute,
              pageBuilder: (context, state) => const NoTransitionPage(child: PracticePage()),
              routes: [
                GoRoute(
                  path: flashcardSprintRoute,
                  builder: (context, state) => const FlashcardSprintPage(),
                ),
                GoRoute(
                  path: flashcardSprintResultRoute,
                  builder: (context, state) => FlashcardSprintResultPage(
                    stats: state.extra as FlashcardSprintResultStats?,
                  ),
                ),
                GoRoute(
                  path: wordMatchRoute,
                  builder: (context, state) => const WordMatchPage(),
                ),
                GoRoute(
                  path: buildSentenceRoute,
                  builder: (context, state) => const BuildSentencePage(),
                ),
                GoRoute(
                  path: writingAssessmentRoute,
                  builder: (context, state) => const WritingAssessmentPage(),
                ),
                GoRoute(
                  path: listenTapRoute,
                  builder: (context, state) => const ListenTapPage(),
                ),
                GoRoute(
                  path: vocabularyRoute,
                  builder: (context, state) => const VocabularyPage(),
                ),
                GoRoute(
                  path: speedMixRoute,
                  builder: (context, state) => const SpeedMixStartPage(),
                ),
                GoRoute(
                  path: speedMixPracticeRoute,
                  builder: (context, state) => const SpeedMixPage(),
                ),
                GoRoute(
                  path: speedMixResultRoute,
                  builder: (context, state) => SpeedMixResultPage(
                    stats: state.extra as SpeedMixResultStats,
                  ),
                ),
              ],
            ),
          ],
        ),

        /// 3) Ask AI (поставь свою страницу)
        StatefulShellBranch(routes: [
          GoRoute(
              path: askAiRoute,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: Scaffold(body: Center(child: Text('Ask AI')))))
        ]),

        /// 4) Profile (поставь свою страницу)
        StatefulShellBranch(routes: [
          GoRoute(
              path: profileRoute,
              pageBuilder: (context, state) =>
                  const NoTransitionPage(child: Scaffold(body: Center(child: Text('Profile')))))
        ])
      ])
]);
