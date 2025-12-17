import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/features/auth/presentation/pages/login_email_page.dart';
import 'package:ustadia_user_app/features/auth/presentation/pages/login_page.dart';
import 'package:ustadia_user_app/features/auth/presentation/pages/otp_page.dart';
import 'package:ustadia_user_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:ustadia_user_app/features/posts/presentation/pages/post_page.dart';
import 'package:ustadia_user_app/features/splash/presentation/pages/splash_page.dart';

const splashRoute = '/';
const onboardingRoute = '/onboarding';
const loginRoute = '/login';
const loginEmailRoute = '/login-email';
const otpRoute = '/otp';
const postsRoute = '/posts';

final appRouter = GoRouter(initialLocation: splashRoute, routes: [
  GoRoute(path: splashRoute, builder: (context, state) => const SplashPage()),
  GoRoute(path: onboardingRoute, builder: (context, state) => const OnboardingPage()),
  GoRoute(path: loginRoute, builder: (context, state) => const LoginPage()),
  GoRoute(path: loginEmailRoute, builder: (context, state) => const LoginEmailPage()),
  GoRoute(path: otpRoute, builder: (context, state) => const OtpPage()),
  GoRoute(path: postsRoute, builder: (context, state) => const PostPage())
]);
