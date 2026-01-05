import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/features/auth/presentation/pages/login_page.dart';
import 'package:ustadia_user_app/features/auth/presentation/pages/otp_page.dart';
import 'package:ustadia_user_app/features/auth/presentation/pages/sign_up_page.dart';
import 'package:ustadia_user_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:ustadia_user_app/features/home/presentation/home_page.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/pages/intro_survey_page.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_unit_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_lesson_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_lessons_page.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_listening/learn_listening_page.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_units_page.dart';
import 'package:ustadia_user_app/features/notifications/presentation/pages/notifications_page.dart';
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
import 'package:ustadia_user_app/features/profile/presentation/pages/leaderboard_page.dart';
import 'package:ustadia_user_app/features/profile/presentation/pages/profile_page.dart';
import 'package:ustadia_user_app/features/profile/presentation/pages/settings_language_page.dart';
import 'package:ustadia_user_app/features/profile/presentation/pages/settings_notifications_page.dart';
import 'package:ustadia_user_app/features/profile/presentation/pages/settings_page.dart';
import 'package:ustadia_user_app/features/splash/presentation/pages/splash_page.dart';

/// --------------------
/// Authentication (absolute)
/// --------------------
const splashRoute = '/';
const onboardingRoute = '/onboarding';
const introSurveyRoute = '/intro-survey';
const loginRoute = '/login';
const otpRoute = '/otp';
const signUpRoute = '/sign-up';

/// --------------------
/// HOME Shell routes (absolute)
/// --------------------
const homeRoute = '/home';
const dashboardRoute = '$homeRoute/dashboard';
const learnUnitsRoute = '$homeRoute/learn_units';
const learnLessonsPath = 'lesson';
const learnLessonsRoute = '$learnUnitsRoute/$learnLessonsPath';
const learnListeningPath = 'listening';
const learnListeningRoute = '$learnUnitsRoute/$learnListeningPath';
const practiceRoute = '$homeRoute/practice';
const askAiRoute = '$homeRoute/ask-ai';
const profileRoute = '$homeRoute/profile';

/// --------------------
/// Relative paths INSIDE branches (no slashes)
/// --------------------

// Practice
const flashcardSprintPath = 'flashcard-sprint';
const flashcardSprintResultPath = 'result';
const wordMatchPath = 'word-match';
const buildSentencePath = 'build-sentence';
const writingAssessmentPath = 'writing-assessment';
const listenTapPath = 'listen-tap';
const vocabularyPath = 'vocabulary';

// SpeedMix (MUST be nested segments, not "speed-mix-play" etc.)
const speedMixPath = 'speed-mix';
const speedMixPlayPath = 'play';
const speedMixResultPath = 'result';

// Profile
const leaderboardPath = 'leaderboard';
const notificationsPath = 'notifications';
const settingsPath = 'settings';
const settingsNotificationsPath = 'notifications';
const settingsLanguagePath = 'language';

/// --------------------
/// Absolute helpers for pushing from anywhere (always start with '/')
/// --------------------
const flashcardSprintRoute = '$practiceRoute/$flashcardSprintPath';
const flashcardSprintResultRoute = '$flashcardSprintRoute/$flashcardSprintResultPath';
const wordMatchRoute = '$practiceRoute/$wordMatchPath';
const buildSentenceRoute = '$practiceRoute/$buildSentencePath';
const writingAssessmentRoute = '$practiceRoute/$writingAssessmentPath';
const listenTapRoute = '$practiceRoute/$listenTapPath';
const vocabularyRoute = '$practiceRoute/$vocabularyPath';

const speedMixRoute = '$practiceRoute/$speedMixPath';
const speedMixPlayRoute = '$speedMixRoute/$speedMixPlayPath';
const speedMixResultRoute = '$speedMixRoute/$speedMixResultPath';

const leaderboardRoute = '$profileRoute/$leaderboardPath';
const notificationsRoute = '$profileRoute/$notificationsPath';
const settingsRoute = '$profileRoute/$settingsPath';
const settingsNotificationsRoute = '$settingsRoute/$settingsNotificationsPath';
const settingsLanguageRoute = '$settingsRoute/$settingsLanguagePath';

/// --------------------
/// Navigator keys
/// --------------------
final _rootKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final _dashboardKey = GlobalKey<NavigatorState>(debugLabel: 'dashboard');
final _learnKey = GlobalKey<NavigatorState>(debugLabel: 'learn');
final _practiceKey = GlobalKey<NavigatorState>(debugLabel: 'practice');
final _askAiKey = GlobalKey<NavigatorState>(debugLabel: 'askAi');
final _profileKey = GlobalKey<NavigatorState>(debugLabel: 'profile');

final appRouter = GoRouter(
  navigatorKey: _rootKey,
  initialLocation: splashRoute,
  routes: [
    /// ----------- NO-SHELL PAGES -----------
    GoRoute(path: splashRoute, builder: (_, __) => const SplashPage()),
    GoRoute(path: onboardingRoute, builder: (_, __) => const OnboardingPage()),
    GoRoute(path: introSurveyRoute, builder: (_, __) => const IntroSurveyPage()),
    GoRoute(path: loginRoute, builder: (_, __) => const LoginPage()),
    GoRoute(
      path: otpRoute,
      builder: (context, state) => OtpPage(contact: (state.extra as String?) ?? ''),
    ),
    GoRoute(path: signUpRoute, builder: (_, __) => const SignUpPage()),

    /// ----------- SHELL (BOTTOM NAV) -----------
    StatefulShellRoute.indexedStack(
      parentNavigatorKey: _rootKey,
      builder: (context, state, navigationShell) => HomePage(navigationShell: navigationShell),
      branches: [
        /// 0) Dashboard
        StatefulShellBranch(
          navigatorKey: _dashboardKey,
          routes: [
            GoRoute(
              path: dashboardRoute,
              pageBuilder: (_, __) => const NoTransitionPage(child: DashboardPage()),
            ),
          ],
        ),

        /// 1) Learn
        StatefulShellBranch(
          navigatorKey: _learnKey,
          routes: [
            GoRoute(
                path: learnUnitsRoute,
                pageBuilder: (_, __) => const NoTransitionPage(child: LearnUnitsPage()),
                routes: [
                  GoRoute(
                      path: learnLessonsPath,
                      parentNavigatorKey: _rootKey,
                      builder: (context, state) => LearnLessonsPage(
                          unit:
                              (state.extra as LearnUnitModel?) ?? LearnUnitModel.sampleUnits.first)),
                  GoRoute(
                      path: learnListeningPath,
                      parentNavigatorKey: _rootKey,
                      builder: (context, state) => LearnListeningPage(
                          lesson: (state.extra as LearnLessonModel?) ??
                              LearnLessonModel.sampleLessons.first))
                ]),
          ],
        ),

        /// 2) Practice (root has bottom bar; children open on root -> no bottom bar)
        StatefulShellBranch(
          navigatorKey: _practiceKey,
          routes: [
            GoRoute(
              path: practiceRoute,
              pageBuilder: (_, __) => const NoTransitionPage(child: PracticePage()),
              routes: [
                GoRoute(
                  path: flashcardSprintPath,
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => const FlashcardSprintPage(),
                  routes: [
                    GoRoute(
                      path: flashcardSprintResultPath,
                      parentNavigatorKey: _rootKey,
                      builder: (context, state) => FlashcardSprintResultPage(
                        stats: state.extra as FlashcardSprintResultStats?,
                      ),
                    ),
                  ],
                ),
                GoRoute(
                  path: wordMatchPath,
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => const WordMatchPage(),
                ),
                GoRoute(
                  path: buildSentencePath,
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => const BuildSentencePage(),
                ),
                GoRoute(
                  path: writingAssessmentPath,
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => const WritingAssessmentPage(),
                ),
                GoRoute(
                  path: listenTapPath,
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => const ListenTapPage(),
                ),
                GoRoute(
                  path: vocabularyPath,
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => const VocabularyPage(),
                ),

                /// SpeedMix: start -> play/result
                GoRoute(
                  path: speedMixPath,
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => const SpeedMixStartPage(),
                  routes: [
                    GoRoute(
                      path: speedMixPlayPath,
                      parentNavigatorKey: _rootKey,
                      builder: (_, __) => const SpeedMixPlayPage(),
                    ),
                    GoRoute(
                      path: speedMixResultPath,
                      parentNavigatorKey: _rootKey,
                      builder: (context, state) =>
                          SpeedMixResultPage(stats: state.extra as SpeedMixResultStats),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        /// 3) Ask AI
        StatefulShellBranch(
          navigatorKey: _askAiKey,
          routes: [
            GoRoute(
              path: askAiRoute,
              pageBuilder: (_, __) => const NoTransitionPage(
                child: Scaffold(body: Center(child: Text('Ask AI'))),
              ),
            ),
          ],
        ),

        /// 4) Profile (root has bottom bar; children open on root -> no bottom bar)
        StatefulShellBranch(
          navigatorKey: _profileKey,
          routes: [
            GoRoute(
              path: profileRoute,
              pageBuilder: (_, __) => const NoTransitionPage(child: ProfilePage()),
              routes: [
                GoRoute(
                  path: leaderboardPath,
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => const LeaderboardPage(),
                ),
                GoRoute(
                  path: notificationsPath,
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => const NotificationsPage(),
                ),
                GoRoute(
                  path: settingsPath,
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => const SettingsPage(),
                  routes: [
                    GoRoute(
                      path: settingsNotificationsPath,
                      parentNavigatorKey: _rootKey,
                      builder: (_, __) => const SettingsNotificationsPage(),
                    ),
                    GoRoute(
                      path: settingsLanguagePath,
                      parentNavigatorKey: _rootKey,
                      builder: (_, __) => const SettingsLanguagePage(),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);
