import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell/main_shell.dart';
import '../../dev/dev_hub_screen.dart';
import '../../dev/state_widgets_preview_screen.dart';
import '../../dev/theme_preview_screen.dart';
import '../../features/accounts/presentation/pages/account_detail_page.dart';
import '../../features/accounts/presentation/pages/account_form_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/categories/presentation/pages/category_form_page.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
import '../../features/projects/presentation/pages/projects_placeholder_page.dart';
import '../../features/settings/presentation/pages/change_password_page.dart';
import '../../features/settings/presentation/pages/edit_profile_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';

/// Returns the app's [GoRouter].
///
/// Auth-aware:
/// - While [AuthCubit] is in [AuthInitial], the shell is replaced with
///   [SplashPage] (no chrome). Once auth resolves, the shell appears.
/// - When unauthenticated, any non-`/auth/*`, non-`/dev/*` route redirects to
///   `/auth/login`.
/// - When authenticated, visiting any `/auth/*` route redirects to `/`.
/// - `/dev/*` is always accessible (debug hub).
///
/// Top-level routing:
/// - **Inside the shell** — `/`, `/accounts`, `/projects` (the three primary
///   tab destinations). The shell owns the top app bar, the bottom nav, and
///   the centered `+` FAB.
/// - **Outside the shell** — `/auth/*`, `/settings/*`, `/dev/*`, and any
///   future detail routes (e.g. `/accounts/:id`) that should NOT show the
///   bottom nav. They supply their own [Scaffold] + [AppBar] with a back
///   button.
GoRouter buildAppRouter(AuthCubit authCubit) {
  final dashboardNavigatorKey = GlobalKey<NavigatorState>();
  final accountsNavigatorKey = GlobalKey<NavigatorState>();
  final projectsNavigatorKey = GlobalKey<NavigatorState>();

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    refreshListenable: _StreamToListenable(authCubit.stream),
    redirect: (context, state) {
      final auth = authCubit.state;
      final loc = state.matchedLocation;
      final goingToAuth = loc.startsWith('/auth');
      final goingToDev = loc.startsWith('/dev');

      if (goingToDev) return null;
      if (auth is AuthInitial) return null; // splash handled inside shell

      if (!auth.isAuthenticated && !goingToAuth) return '/auth/login';
      if (auth.isAuthenticated && goingToAuth) return '/';
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          // BlocBuilder is essential here: when state transitions
          // AuthInitial → AuthAuthenticated, the router redirect returns
          // null (no nav change), so without a Bloc subscription the builder
          // would not re-run and the splash would stay on screen.
          return BlocBuilder<AuthCubit, AuthState>(
            builder: (context, auth) {
              if (auth is AuthInitial) return const SplashPage();
              return MainShell(navigationShell: navigationShell);
            },
          );
        },
        branches: [
          StatefulShellBranch(
            navigatorKey: dashboardNavigatorKey,
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const HomePage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: accountsNavigatorKey,
            routes: [
              GoRoute(
                path: '/accounts',
                name: 'accounts',
                builder: (context, state) => const AccountsPage(),
              ),
            ],
          ),
          StatefulShellBranch(
            navigatorKey: projectsNavigatorKey,
            routes: [
              GoRoute(
                path: '/projects',
                name: 'projects',
                builder: (context, state) => const ProjectsPlaceholderPage(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/auth/login',
        name: 'auth-login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/auth/register',
        name: 'auth-register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/accounts/new',
        name: 'account-new',
        builder: (context, state) => const AccountFormPage(),
      ),
      GoRoute(
        path: '/accounts/:id',
        name: 'account-detail',
        builder: (context, state) => AccountDetailPage(
          accountId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/categories',
        name: 'categories',
        builder: (context, state) => const CategoriesPage(),
      ),
      GoRoute(
        path: '/categories/new',
        name: 'category-new',
        builder: (context, state) => const CategoryFormPage(),
      ),
      GoRoute(
        path: '/categories/:id/edit',
        name: 'category-edit',
        builder: (context, state) =>
            CategoryFormPage(editingId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsPage(),
      ),
      GoRoute(
        path: '/settings/profile',
        name: 'settings-profile',
        builder: (context, state) => const EditProfilePage(),
      ),
      GoRoute(
        path: '/settings/password',
        name: 'settings-password',
        builder: (context, state) => const ChangePasswordPage(),
      ),
      GoRoute(
        path: '/dev',
        name: 'dev-hub',
        builder: (context, state) => const DevHubScreen(),
        routes: [
          GoRoute(
            path: 'theme-preview',
            name: 'dev-theme-preview',
            builder: (context, state) => const ThemePreviewScreen(),
          ),
          GoRoute(
            path: 'state-widgets',
            name: 'dev-state-widgets',
            builder: (context, state) => const StateWidgetsPreviewScreen(),
          ),
        ],
      ),
    ],
  );
}

/// Adapts a [Stream] to a [Listenable] so [GoRouter.refreshListenable] can
/// rebuild the router whenever [AuthCubit] emits.
class _StreamToListenable extends ChangeNotifier {
  _StreamToListenable(Stream<dynamic> stream) {
    notifyListeners();
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
