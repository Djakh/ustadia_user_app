import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/pages/ask_ai_page.dart';
import 'package:ustadia_user_app/features/auth/data/models/otp_verification_params.dart';
import 'package:ustadia_user_app/features/auth/presentation/pages/login_page.dart';
import 'package:ustadia_user_app/features/auth/presentation/pages/otp_page.dart';
import 'package:ustadia_user_app/features/auth/presentation/pages/sign_up_page.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_set_model.dart';
import 'package:ustadia_user_app/features/common/data/models/user_profile_model.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/flashcard_sprint/flashcard_sprint_page.dart';
import 'package:ustadia_user_app/features/dashboard/presentation/pages/dashboard_page.dart';
import 'package:ustadia_user_app/features/home/presentation/home_page.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/pages/intro_survey_page.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_lesson_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_unit_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_grammar_section/learn_grammar_section_page.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_lessons_page.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_listening_section/learn_listening_section_page.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_reading_section/learn_reading_section_page.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_sections_page.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_speaking_section/learn_speaking_section_page.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_units_page.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_writing_section/learn_writing_section_page.dart';
import 'package:ustadia_user_app/features/notifications/presentation/pages/notifications_page.dart';
import 'package:ustadia_user_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_listen_tap_set_model.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_sentence_builder_set_model.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_word_match_set_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/listen_tap_pages/practice_listen_tap_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/build_sentence/practice_build_sentence_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/build_sentence/practice_build_sentence_sets_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/flashcards/practice_flashcard_sets_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/listen_tap_pages/practice_listen_tap_sets_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/practice_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/vocabulary/practice_vocabulary_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/word_match/practice_word_match_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/word_match/practice_word_match_sets_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/writing_assesment/practice_writing_assessment_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/speed_mix/practice_speed_mix_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/speed_mix/practice_speed_mix_result_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/speed_mix/practice_speed_mix_start_page.dart';
import 'package:ustadia_user_app/features/profile/presentation/pages/edit_account_page.dart';
import 'package:ustadia_user_app/features/profile/presentation/pages/leaderboard_page.dart';
import 'package:ustadia_user_app/features/profile/presentation/pages/profile_image_view_page.dart';
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
const learnLessonsRoute = '$homeRoute/learn_lessons';

const learnUnitsPath = 'learn_units';
const learnUnitsRoute = '$learnLessonsRoute/$learnUnitsPath';
const learnSectionsPath = 'sections';
const learnSectionsRoute = '$learnUnitsRoute/$learnSectionsPath';
const learnListeningPath = 'listening';

const learnListeningRoute = '$learnUnitsRoute/$learnListeningPath';
const learnReadingPath = 'reading';
const learnReadingRoute = '$learnUnitsRoute/$learnReadingPath';
const learnSpeakingPath = 'speaking';
const learnSpeakingRoute = '$learnUnitsRoute/$learnSpeakingPath';

const learnGrammarPath = 'grammar';
const learnGrammarRoute = '$learnUnitsRoute/$learnGrammarPath';

const learnWritingPath = 'writing';
const learnWritingRoute = '$learnUnitsRoute/$learnWritingPath';

const flashcardSprintPath = 'flashcard-sprint';

const practiceRoute = '$homeRoute/practice';
const askAiRoute = '$homeRoute/ask-ai';
const profileRoute = '$homeRoute/profile';

/// --------------------
/// Relative paths INSIDE branches (no slashes)
/// --------------------

// Practice
const wordMatchPath = 'word-match';
const buildSentencePath = 'build-sentence';
const writingAssessmentPath = 'writing-assessment';
const listenTapSetsPath = 'listen-tap-sets';

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
const editAccountPath = 'edit-account';

/// --------------------
/// Absolute helpers for pushing from anywhere (always start with '/')
/// --------------------
const flashcardSprintRoute = '/$flashcardSprintPath';
const wordMatchRoute = '$practiceRoute/$wordMatchPath';
const buildSentenceRoute = '$practiceRoute/$buildSentencePath';
const writingAssessmentRoute = '$practiceRoute/$writingAssessmentPath';
const listenTapSetsRoute = '$practiceRoute/$listenTapSetsPath';

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
const editAccountRoute = '$settingsRoute/$editAccountPath';
const profileImageViewRoute = '/profile-image-view';

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
      builder: (context, state) {
        final extra = state.extra;
        if (extra is OtpVerificationParams) {
          return OtpPage(contact: extra.email, verificationParams: extra);
        }
        return OtpPage(contact: (extra as String?) ?? '');
      },
    ),
    GoRoute(path: signUpRoute, builder: (_, __) => const SignUpPage()),
    GoRoute(
        path: profileImageViewRoute,
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final extra = state.extra;
          final params = extra is ProfileImageViewParams ? extra : const ProfileImageViewParams();
          return ProfileImageViewPage(params: params);
        }),
    GoRoute(
        path: flashcardSprintRoute,
        parentNavigatorKey: _rootKey,
        builder: (context, state) {
          final extra = state.extra;
          if (extra is FlashcardSprintParams) {
            return FlashcardSprintPage(flashcardSetModel: extra.set, isPractice: extra.isPractice);
          }
          if (extra is LearnFlashcardSetModel) {
            return FlashcardSprintPage(flashcardSetModel: extra);
          }
          return const PracticeFlashcardSetsPage();
        }),

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
                path: learnLessonsRoute,
                pageBuilder: (_, __) => const NoTransitionPage(child: LearnLessonsPage()),
                routes: [
                  GoRoute(
                      path: learnUnitsPath,
                      parentNavigatorKey: _rootKey,
                      builder: (context, state) {
                        final extra = state.extra;
                        final lesson =
                            extra is LearnLessonModel ? extra : const LearnLessonModel.empty();
                        return LearnUnitsPage(learnLessonModel: lesson);
                      },
                      routes: [
                        GoRoute(
                            path: learnSectionsPath,
                            parentNavigatorKey: _rootKey,
                            builder: (context, state) => LearnSectionsPage(
                                unit: (state.extra as LearnUnitModel?) ??
                                    const LearnUnitModel.empty())),
                        GoRoute(
                            path: learnListeningPath,
                            parentNavigatorKey: _rootKey,
                            builder: (context, state) =>
                                LearnListeningPage(sectionModel: state.extra as LearnSectionModel)),
                        GoRoute(
                            path: learnReadingPath,
                            parentNavigatorKey: _rootKey,
                            builder: (context, state) =>
                                LearnReadingPage(sectionModel: state.extra as LearnSectionModel)),
                        GoRoute(
                            path: learnSpeakingPath,
                            parentNavigatorKey: _rootKey,
                            builder: (context, state) =>
                                LearnSpeakingPage(sectionModel: state.extra as LearnSectionModel)),
                        GoRoute(
                            path: learnGrammarPath,
                            parentNavigatorKey: _rootKey,
                            builder: (context, state) =>
                                LearnGrammarPage(sectionModel: state.extra as LearnSectionModel)),
                        GoRoute(
                            path: learnWritingPath,
                            parentNavigatorKey: _rootKey,
                            builder: (context, state) =>
                                LearnWritingPage(sectionModel: state.extra as LearnSectionModel)),
                      ]),
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
                  path: wordMatchPath,
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) {
                    final extra = state.extra;
                    if (extra is PracticeWordMatchSetModel) {
                      return PracticeWordMatchPage(set: extra);
                    }
                    return const PracticeWordMatchSetsPage();
                  },
                ),
                GoRoute(
                  path: buildSentencePath,
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) {
                    final extra = state.extra;
                    if (extra is PracticeSentenceBuilderSetModel) {
                      return PracticeBuildSentencePage(set: extra);
                    }
                    return const PracticeBuildSentenceSetsPage();
                  },
                ),
                GoRoute(
                  path: writingAssessmentPath,
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => const PracticeWritingAssessmentPage(),
                ),
                GoRoute(
                  path: listenTapSetsPath,
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) {
                    return const PracticeListenTapSetsPage();
                  },
                ),
                GoRoute(
                  path: listenTapPath,
                  parentNavigatorKey: _rootKey,
                  builder: (context, state) {
                    return PracticeListenTapPage(set: state.extra as PracticeListenTapSetModel);
                  },
                ),
                GoRoute(
                  path: vocabularyPath,
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => const PracticeVocabularyPage(),
                ),

                /// SpeedMix: start -> play/result
                GoRoute(
                  path: speedMixPath,
                  parentNavigatorKey: _rootKey,
                  builder: (_, __) => const PracticeSpeedMixStartPage(),
                  routes: [
                    GoRoute(
                      path: speedMixPlayPath,
                      parentNavigatorKey: _rootKey,
                      builder: (_, __) => const PracticeSpeedMixPlayPage(),
                    ),
                    GoRoute(
                      path: speedMixResultPath,
                      parentNavigatorKey: _rootKey,
                      builder: (context, state) => PracticeSpeedMixResultPage(
                          stats: state.extra as PracticeSpeedMixResultStats),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),

        /// 3) Ask AI
        StatefulShellBranch(navigatorKey: _askAiKey, routes: [
          GoRoute(
              path: askAiRoute, pageBuilder: (_, __) => const NoTransitionPage(child: AskAiPage()))
        ]),

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
                      path: editAccountPath,
                      parentNavigatorKey: _rootKey,
                      builder: (_, __) => const EditAccountPage(),
                    ),
                    GoRoute(
                      path: settingsNotificationsPath,
                      parentNavigatorKey: _rootKey,
                      builder: (_, __) => const SettingsNotificationsPage(),
                    ),
                    GoRoute(
                      path: settingsLanguagePath,
                      parentNavigatorKey: _rootKey,
                      builder: (_, state) =>
                          SettingsLanguagePage(userProfileModel: state.extra as UserProfileModel),
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
