import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell/main_shell.dart';
import '../../dev/dev_hub_screen.dart';
import '../../dev/logs_viewer_screen.dart';
import '../../dev/state_widgets_preview_screen.dart';
import '../../dev/theme_preview_screen.dart';
import '../../features/accounts/presentation/pages/account_detail_page.dart';
import '../../features/accounts/presentation/pages/account_form_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/categories/presentation/pages/category_form_page.dart';
import '../../features/contacts/presentation/pages/contact_detail_page.dart';
import '../../features/contacts/presentation/pages/contact_form_page.dart';
import '../../features/contacts/presentation/pages/contacts_page.dart';
import '../../features/notifications/presentation/pages/notification_settings_page.dart';
import '../../features/notifications/presentation/pages/notifications_inbox_page.dart';
import '../../features/personal_debts/presentation/pages/personal_debt_detail_page.dart';
import '../../features/personal_debts/presentation/pages/personal_debt_form_page.dart';
import '../../features/personal_debts/presentation/pages/personal_debts_page.dart';
import '../../features/projects/presentation/pages/project_detail_page.dart';
import '../../features/projects/presentation/pages/project_form_page.dart';
import '../../features/projects/presentation/pages/project_transaction_form_page.dart';
import '../../features/projects/presentation/pages/projects_page.dart';
import '../../features/tags/presentation/pages/tag_form_page.dart';
import '../../features/tags/presentation/pages/tags_page.dart';
import '../../features/transactions/presentation/pages/transaction_detail_page.dart';
import '../../features/transactions/presentation/pages/transaction_form_page.dart';
import '../../features/transactions/presentation/pages/transactions_list_page.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_page.dart';
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
  final transactionsNavigatorKey = GlobalKey<NavigatorState>();
  final accountsNavigatorKey = GlobalKey<NavigatorState>();

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
            navigatorKey: transactionsNavigatorKey,
            routes: [
              GoRoute(
                path: '/transactions',
                name: 'transactions',
                builder: (context, state) => const TransactionsListPage(),
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
        ],
      ),
      // Projects (Phase 1b.2). Outside the bottom-nav shell.
      GoRoute(
        path: '/projects',
        name: 'projects',
        builder: (context, state) => const ProjectsPage(),
      ),
      GoRoute(
        path: '/projects/new',
        name: 'project-new',
        builder: (context, state) => const ProjectFormPage(),
      ),
      GoRoute(
        path: '/projects/:id',
        name: 'project-detail',
        builder: (context, state) =>
            ProjectDetailPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/projects/:id/edit',
        name: 'project-edit',
        builder: (context, state) =>
            ProjectFormPage(editingId: state.pathParameters['id']),
      ),
      GoRoute(
        path: '/projects/:id/transactions/new',
        name: 'project-tx-new',
        builder: (context, state) => ProjectTransactionFormPage(
          projectId: state.pathParameters['id']!,
        ),
      ),
      // Notifications (Phase 1b.2)
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsInboxPage(),
      ),
      GoRoute(
        path: '/notifications/settings',
        name: 'notifications-settings',
        builder: (context, state) => const NotificationSettingsPage(),
      ),
      // Contacts (Phase 1b.1)
      GoRoute(
        path: '/contacts',
        name: 'contacts',
        builder: (context, state) => const ContactsPage(),
      ),
      GoRoute(
        path: '/contacts/new',
        name: 'contact-new',
        builder: (context, state) => const ContactFormPage(),
      ),
      GoRoute(
        path: '/contacts/:id',
        name: 'contact-detail',
        builder: (context, state) =>
            ContactDetailPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/contacts/:id/edit',
        name: 'contact-edit',
        builder: (context, state) =>
            ContactFormPage(editingId: state.pathParameters['id']),
      ),
      // Personal debts (bidirectional — replaces splits)
      GoRoute(
        path: '/personal-debts',
        name: 'personal-debts',
        builder: (context, state) => const PersonalDebtsPage(),
      ),
      GoRoute(
        path: '/personal-debts/new',
        name: 'personal-debt-new',
        builder: (context, state) => const PersonalDebtFormPage(),
      ),
      GoRoute(
        path: '/personal-debts/:id',
        name: 'personal-debt-detail',
        builder: (context, state) =>
            PersonalDebtDetailPage(id: state.pathParameters['id']!),
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
        path: '/accounts/:id/edit',
        name: 'account-edit',
        builder: (context, state) =>
            AccountFormPage(editingId: state.pathParameters['id']),
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
        path: '/tags',
        name: 'tags',
        builder: (context, state) => const TagsPage(),
      ),
      GoRoute(
        path: '/tags/new',
        name: 'tag-new',
        builder: (context, state) => const TagFormPage(),
      ),
      GoRoute(
        path: '/tags/:id/edit',
        name: 'tag-edit',
        builder: (context, state) =>
            TagFormPage(editingId: state.pathParameters['id']),
      ),
      // /transactions itself is a shell branch (bottom-nav slot 1); the
      // create / detail / edit routes below are top-level so they
      // present without the bottom nav.
      GoRoute(
        path: '/transactions/new',
        name: 'transaction-new',
        builder: (context, state) => const TransactionFormPage(),
      ),
      GoRoute(
        path: '/transactions/:id',
        name: 'transaction-detail',
        builder: (context, state) => TransactionDetailPage(
          transactionId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: '/transactions/:id/edit',
        name: 'transaction-edit',
        builder: (context, state) =>
            TransactionFormPage(editingId: state.pathParameters['id']),
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
          GoRoute(
            path: 'logs',
            name: 'dev-logs',
            builder: (context, state) => const LogsViewerScreen(),
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
