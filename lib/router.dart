import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:ustadia_user_app/features/posts/presentation/pages/post_page.dart';
import 'package:ustadia_user_app/features/splash/presentation/pages/splash_page.dart';

const splashRoute = '/';
const onboardingRoute = '/onboarding';
const postsRoute = '/posts';

final appRouter = GoRouter(initialLocation: splashRoute, routes: [
  GoRoute(path: splashRoute, builder: (context, state) => const SplashPage()),
  GoRoute(path: onboardingRoute, builder: (context, state) => const OnboardingPage()),
  GoRoute(path: postsRoute, builder: (context, state) => const PostPage())
]);
