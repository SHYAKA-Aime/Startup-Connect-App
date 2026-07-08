import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/applications/presentation/applicants_screen.dart';
import '../features/auth/presentation/screens/forgot_password_screen.dart';
import '../features/auth/presentation/screens/login_screen.dart';
import '../features/auth/presentation/screens/register_screen.dart';
import '../features/auth/presentation/screens/splash_screen.dart';
import '../features/opportunities/presentation/opportunity_detail_screen.dart';
import '../features/opportunities/presentation/post_opportunity_screen.dart';
import '../features/profile/presentation/edit_profile_screen.dart';
import '../features/shell/admin_shell.dart';
import '../features/shell/startup_shell.dart';
import '../features/shell/student_shell.dart';
import '../features/startups/presentation/admin_verification_screen.dart';
import '../features/startups/presentation/startup_setup_screen.dart';
import 'providers.dart';

/// Named route paths kept in one place so navigation calls are typo-proof.
class Routes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const forgot = '/forgot';
  static const home = '/home'; // student shell
  static const startup = '/startup'; // startup shell
  static const admin = '/admin'; // admin shell
  static const opportunity = '/opportunity'; // + /:id
  static const postOpportunity = '/startup/post'; // ?id= to edit
  static const startupSetup = '/startup/setup';
  static const applicants = '/startup/applicants'; // + /:oppId
  static const editProfile = '/profile/edit';
  static const adminVerify = '/admin/verify';
}

const _authRoutes = {Routes.login, Routes.register, Routes.forgot};

/// The single [GoRouter] for the app, exposed as a provider so its `redirect`
/// can read Riverpod state. `redirect` is the guard that:
///   • forces signed-out users into the auth flow, and
///   • routes signed-in users to the correct shell for their role.
/// A [ValueNotifier] bumped whenever auth/profile changes tells go_router to
/// re-run `redirect`, so navigation reacts to login/logout automatically.
final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(authStateProvider, (_, __) => refresh.value++);
  ref.listen(currentUserProvider, (_, __) => refresh.value++);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final auth = ref.read(authStateProvider);

      // Auth still being determined → hold on the splash screen.
      if (auth.isLoading) return loc == Routes.splash ? null : Routes.splash;

      final signedIn = auth.valueOrNull != null;
      final onAuthPage = _authRoutes.contains(loc);

      if (!signedIn) {
        return onAuthPage ? null : Routes.login;
      }

      // Signed in: we need the profile doc to know the role.
      final profile = ref.read(currentUserProvider);
      if (profile.isLoading) {
        return loc == Routes.splash ? null : Routes.splash;
      }
      final appUser = profile.valueOrNull;
      if (appUser == null) {
        // Profile doc not created yet (brief window during sign-up).
        return loc == Routes.splash ? null : Routes.splash;
      }

      // isAdmin takes precedence over the base role: an admin gets the admin
      // shell, not the student/startup one, so the views never mix.
      final target = appUser.isAdmin
          ? Routes.admin
          : appUser.isStartup
              ? Routes.startup
              : Routes.home;
      if (onAuthPage || loc == Routes.splash) return target;

      // Never let a user sit inside another role's shell (e.g. an admin landing
      // on the student Home). Sub-routes like /startup/post are unaffected.
      const shellRoots = {Routes.home, Routes.startup, Routes.admin};
      if (shellRoots.contains(loc) && loc != target) return target;
      return null; // already where they should be
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, __) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: Routes.register, builder: (_, __) => const RegisterScreen()),
      GoRoute(
          path: Routes.forgot,
          builder: (_, __) => const ForgotPasswordScreen()),

      // Student shell (Home / Explore / Applications / Profile)
      GoRoute(path: Routes.home, builder: (_, __) => const StudentShell()),

      // Startup shell (Dashboard / Post / Profile)
      GoRoute(path: Routes.startup, builder: (_, __) => const StartupShell()),

      // Admin shell (Verification / Account)
      GoRoute(path: Routes.admin, builder: (_, __) => const AdminShell()),

      GoRoute(
        path: '${Routes.opportunity}/:id',
        builder: (_, s) =>
            OpportunityDetailScreen(opportunityId: s.pathParameters['id']!),
      ),
      GoRoute(
        path: Routes.postOpportunity,
        builder: (_, s) =>
            PostOpportunityScreen(opportunityId: s.uri.queryParameters['id']),
      ),
      GoRoute(
        path: Routes.startupSetup,
        builder: (_, __) => const StartupSetupScreen(),
      ),
      GoRoute(
        path: '${Routes.applicants}/:oppId',
        builder: (_, s) =>
            ApplicantsScreen(opportunityId: s.pathParameters['oppId']!),
      ),
      GoRoute(
        path: Routes.editProfile,
        builder: (_, __) => const EditProfileScreen(),
      ),
      GoRoute(
        path: Routes.adminVerify,
        builder: (_, __) => const AdminVerificationScreen(),
      ),
    ],
  );
});
