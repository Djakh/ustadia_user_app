import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/features/auth/presentation/pages/login_page.dart';
import 'package:ustadia_user_app/features/auth/presentation/pages/otp_page.dart';
import 'package:ustadia_user_app/features/auth/presentation/pages/sign_up_page.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/pages/intro_survey_page.dart';
import 'package:ustadia_user_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:ustadia_user_app/features/posts/presentation/pages/post_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/practice_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/flashcard_sprint_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/flashcard_sprint_result_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/word_match_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/build_sentence_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/writing_assessment_page.dart';
import 'package:ustadia_user_app/features/splash/presentation/pages/splash_page.dart';

const splashRoute = '/';
const onboardingRoute = '/onboarding';
const introSurveyRoute = '/intro-survey';
const loginRoute = '/login';
const otpRoute = '/otp';
const signUpRoute = '/sign-up';
const postsRoute = '/posts';
const practiceRoute = '/practice';
const flashcardSprintRoute = '/practice/flashcard-sprint';
const flashcardSprintResultRoute = '/practice/flashcard-sprint/result';
const wordMatchRoute = '/practice/word-match';
const buildSentenceRoute = '/practice/build-sentence';
const writingAssessmentRoute = '/practice/writing-assessment';

final appRouter = GoRouter(initialLocation: splashRoute, routes: [
  GoRoute(path: splashRoute, builder: (context, state) => const SplashPage()),
  GoRoute(path: onboardingRoute, builder: (context, state) => const OnboardingPage()),
  GoRoute(path: introSurveyRoute, builder: (context, state) => const IntroSurveyPage()),
  GoRoute(path: loginRoute, builder: (context, state) => const LoginPage()),
  GoRoute(
      path: otpRoute,
      builder: (context, state) => OtpPage(contact: (state.extra as String?) ?? '')),
  GoRoute(path: signUpRoute, builder: (context, state) => const SignUpPage()),
  GoRoute(path: postsRoute, builder: (context, state) => const PostPage()),
  GoRoute(path: practiceRoute, builder: (context, state) => const PracticePage()),
  GoRoute(path: flashcardSprintRoute, builder: (context, state) => const FlashcardSprintPage()),
  GoRoute(
      path: flashcardSprintResultRoute,
      builder: (context, state) =>
          FlashcardSprintResultPage(stats: state.extra as FlashcardSprintResultStats?))
  ,
  GoRoute(path: wordMatchRoute, builder: (context, state) => const WordMatchPage())
  ,
  GoRoute(path: buildSentenceRoute, builder: (context, state) => const BuildSentencePage())
  ,
  GoRoute(path: writingAssessmentRoute, builder: (context, state) => const WritingAssessmentPage())
]);
