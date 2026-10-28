import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/shell/main_shell.dart';
import '../../app/shell/more_page.dart';
import '../../app/shell/quick_create_context.dart';
import '../../app/shell/shell_chrome.dart';
import '../../app/shell/tab_nav.dart';
import '../../hub/hub_index_screen.dart';
import '../../hub/hub_page_frame.dart';
import '../../hub/hub_registry.dart';
import '../../ui/organisms/page_pop_observer.dart';
import '../../app/shell/fade_branch_container.dart';
import '../../features/app_version/presentation/cubit/app_version_cubit.dart';
import '../../features/app_version/presentation/pages/update_required_page.dart';
import '../../features/app_version/presentation/version_gate.dart';
import '../../features/accounts/presentation/pages/archived_accounts_page.dart';
import '../../features/transactions/data/transactions_repository.dart';
import '../../features/transactions/presentation/cubit/transactions_cubit.dart';
import '../../features/accounts/presentation/pages/account_detail_page.dart';
import '../../features/accounts/presentation/pages/accounts_page.dart';
import '../../features/categories/domain/category_type.dart';
import '../../features/categories/presentation/pages/categories_page.dart';
import '../../features/categories/presentation/pages/category_detail_page.dart';
import '../../features/contacts/presentation/pages/contact_detail_page.dart';
import '../../features/contacts/presentation/pages/contact_form_page.dart';
import '../../features/contacts/presentation/pages/contacts_page.dart';
import '../../features/notifications/presentation/pages/notification_settings_page.dart';
import '../../features/notifications/presentation/pages/notifications_inbox_page.dart';
import '../../features/pending/presentation/pages/pending_batch_add_page.dart';
import '../../features/pending/presentation/pages/pending_page.dart';
import '../../features/personal_debts/presentation/pages/debt_person_page.dart';
import '../../features/personal_debts/presentation/pages/personal_debts_page.dart';
import '../../features/projects/presentation/pages/project_detail_page.dart';
import '../../features/projects/presentation/pages/project_members_page.dart';
import '../../features/projects/presentation/pages/projects_page.dart';
import '../../features/saving_goals/presentation/pages/saving_goal_detail_page.dart';
import '../../features/saving_goals/presentation/pages/saving_goals_list_page.dart';
import '../../features/recurring/presentation/pages/recurring_home_page.dart';
import '../../features/recurring/presentation/pages/recurring_detail_page.dart';
import '../../features/recurring/presentation/recurring_draft.dart';
import '../../features/tags/presentation/pages/tags_page.dart';
import '../../features/transactions/presentation/pages/debt_entry_detail_page.dart';
import '../../features/transactions/presentation/pages/transaction_detail_page.dart';
import '../../features/transactions/presentation/pages/transactions_list_page.dart';
import '../../features/budgets/presentation/pages/budget_detail_page.dart';
import '../../features/budgets/presentation/pages/budgets_list_page.dart';
import '../../features/auth/presentation/cubit/auth_cubit.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/home/presentation/pages/home_coming_soon_page.dart';
import '../../features/settings/presentation/pages/change_password_page.dart';
import '../../features/settings/presentation/pages/edit_profile_page.dart';
import '../../features/archived/presentation/archived_page.dart';
import '../../features/settings/presentation/pages/settings_app_page.dart';
import '../../features/settings/presentation/pages/settings_money_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/settings/presentation/pages/settings_page_prefs_page.dart';

GoRouter buildAppRouter(AuthCubit authCubit, {AppVersionCubit? versionCubit}) {
  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: kDebugMode,
    observers: [PagePopObserver()],
    refreshListenable: Listenable.merge([
      _StreamToListenable(authCubit.stream),
      if (versionCubit != null) _StreamToListenable(versionCubit.stream),
    ]),
    redirect: (context, state) {
      final auth = authCubit.state;
      final loc = state.matchedLocation;
      final goingToAuth = loc.startsWith('/auth');
      final goingToDev = loc.startsWith('/dev');

      if (goingToDev) return null;
      final gate = versionGateRedirect(
        state.uri.path,
        blocked: versionCubit?.state.blocked ?? false,
      );
      if (gate != null || state.uri.path == updateRequiredPath) return gate;
      if (auth is AuthInitial) return null; // splash handled inside shell

      if (!auth.isAuthenticated && !goingToAuth) return '/auth/login';
      if (auth.isAuthenticated && goingToAuth) return '/';
      // A module that's off (AppModules) has no pages — a deep link or a
      // notification into one lands somewhere safe instead.
      return offModuleRedirect(state.uri.path);
    },
    routes: [
      StatefulShellRoute(
        navigatorContainerBuilder: (context, navigationShell, children) =>
            FadeBranchContainer(
              currentIndex: navigationShell.currentIndex,
              children: children,
            ),
        builder: (context, state, navigationShell) {
          final shell = BlocBuilder<AuthCubit, AuthState>(
            builder: (context, auth) {
              if (!auth.isAuthenticated) return const SplashPage();
              return MainShell(navigationShell: navigationShell);
            },
          );
          if (versionCubit == null) return shell;
          // The first version check holds the splash too (it times out fast),
          // so an outdated build never flashes the app first.
          return BlocBuilder<AppVersionCubit, AppVersionState>(
            bloc: versionCubit,
            buildWhen: (a, b) =>
                (a.status == AppVersionStatus.checking) !=
                (b.status == AppVersionStatus.checking),
            builder: (context, version) =>
                version.status == AppVersionStatus.checking
                ? const SplashPage()
                : shell,
          );
        },
        branches: [
          for (final tab in ShellTab.values)
            StatefulShellBranch(
              routes: _tabRoutes(tab),
              observers: [QuickCreateRouteObserver(), PagePopObserver()],
            ),
        ],
      ),
      GoRoute(
        path: updateRequiredPath,
        name: 'update-required',
        builder: (context, state) => const UpdateRequiredPage(),
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
        path: '/dev',
        name: 'dev-hub',
        builder: (context, state) => const HubIndexScreen(),
        routes: [
          GoRoute(
            path: 'ui/:level',
            name: 'hub-ui-level',
            builder: (context, state) {
              final level = HubLevel.values
                  .where(
                    (l) => l.isUi && l.name == state.pathParameters['level'],
                  )
                  .firstOrNull;
              return level == null
                  ? const HubIndexScreen()
                  : HubLevelScreen(level: level);
            },
            routes: [
              GoRoute(
                path: ':slug',
                name: 'hub-ui-page',
                builder: (context, state) => _hubPage(
                  context,
                  state.pathParameters['level']!,
                  state.pathParameters['slug']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: ':section',
            name: 'hub-section',
            builder: (context, state) {
              final section = HubSection.byName(
                state.pathParameters['section']!,
              );
              return section == null
                  ? const HubIndexScreen()
                  : HubSectionScreen(section: section);
            },
            routes: [
              GoRoute(
                path: ':slug',
                name: 'hub-page',
                builder: (context, state) => _hubPage(
                  context,
                  state.pathParameters['section']!,
                  state.pathParameters['slug']!,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

List<RouteBase> _tabRoutes(ShellTab tab) => switch (tab) {
  ShellTab.home => [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeComingSoonPage(),
      routes: [
        GoRoute(
          path: 'browse',
          name: 'dashboard-browse',
          builder: (context, state) {
            final p = state.uri.queryParameters;
            final month = p['month'];
            return BlocProvider(
              create: (ctx) => TransactionsCubit(
                repository: ctx.read<TransactionsRepository>(),
              ),
              child: TransactionsListPage(
                initialCategoryId: p['category'],
                initialCategoryName: p['category'] == null ? null : p['title'],
                initialCategoryType: p['category'] == null
                    ? null
                    : (p['type'] == 'income'
                          ? CategoryType.income
                          : CategoryType.expense),
                initialUncategorized: p['uncategorized'] == 'true',
                initialMonth: month == null
                    ? null
                    : DateTime.tryParse('$month-01'),
                title: p['title'] ?? '',
              ),
            );
          },
        ),
      ],
    ),
  ],
  ShellTab.transactions => [
    GoRoute(
      path: '/transactions',
      name: 'transactions',
      builder: (context, state) => const TransactionsListPage(),
    ),
    GoRoute(
      path: '/transactions/:id',
      name: 'transaction-detail',
      builder: (context, state) =>
          TransactionDetailPage(transactionId: state.pathParameters['id']!),
    ),
  ],
  ShellTab.accounts => [
    GoRoute(
      path: '/accounts',
      name: 'accounts',
      builder: (context, state) => const AccountsPage(),
    ),
    GoRoute(
      path: '/accounts/new',
      name: 'account-new',
      builder: (context, state) => const AccountDetailPage(),
    ),
    GoRoute(
      path: '/accounts/archived',
      name: 'accounts-archived',
      builder: (context, state) => const ArchivedAccountsPage(),
    ),
    GoRoute(
      path: '/accounts/:id',
      name: 'account-detail',
      builder: (context, state) =>
          AccountDetailPage(accountId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/accounts/:id/members',
      name: 'account-members',
      builder: (context, state) => AccountDetailPage(
        accountId: state.pathParameters['id']!,
        openMembers: true,
      ),
    ),
  ],
  ShellTab.more => [
    GoRoute(
      path: '/more',
      name: 'more',
      builder: (context, state) => const MorePage(),
    ),
  ],
  ShellTab.pending => [
    GoRoute(
      path: '/pending',
      name: 'pending',
      builder: (context, state) => const PendingPage(),
      routes: [
        GoRoute(
          path: 'new',
          name: 'pending-new',
          builder: (context, state) =>
              const ShellChromeHider(child: PendingBatchAddPage()),
        ),
      ],
    ),
  ],
  ShellTab.notifications => [
    GoRoute(
      path: '/notifications',
      name: 'notifications',
      builder: (context, state) => const NotificationsInboxPage(),
      routes: [
        GoRoute(
          path: 'settings',
          name: 'notifications-settings',
          builder: (context, state) => const NotificationSettingsPage(),
        ),
      ],
    ),
  ],
  ShellTab.settings => [
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsPage(),
      routes: [
        GoRoute(
          path: 'profile',
          name: 'settings-profile',
          builder: (context, state) => const EditProfilePage(),
        ),
        GoRoute(
          path: 'password',
          name: 'settings-password',
          builder: (context, state) =>
              const ShellChromeHider(child: ChangePasswordPage()),
        ),
        GoRoute(
          path: 'notifications',
          name: 'settings-notifications',
          builder: (context, state) => const NotificationSettingsPage(),
        ),
        GoRoute(
          path: 'app',
          name: 'settings-app',
          builder: (context, state) => const SettingsAppPage(),
        ),
        GoRoute(
          path: 'money',
          name: 'settings-money',
          builder: (context, state) => const SettingsMoneyPage(),
        ),
        GoRoute(
          path: 'sync',
          name: 'settings-sync',
          // The auto switches moved to the notification page (owner
          // 2026-10-28): an old link lands there.
          redirect: (context, state) => '/settings/notifications',
        ),
        GoRoute(
          path: 'page-prefs',
          name: 'settings-page-prefs',
          builder: (context, state) => const SettingsPagePrefsPage(),
          routes: [
            GoRoute(
              path: ':page',
              name: 'settings-page-pref',
              builder: (context, state) =>
                  SettingsPagePrefPage(pageId: state.pathParameters['page']!),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/archived',
      name: 'archived',
      builder: (context, state) => const ArchivedPage(),
    ),
  ],
  ShellTab.projects => [
    GoRoute(
      path: '/projects',
      name: 'projects',
      builder: (context, state) => const ProjectsPage(),
    ),
    GoRoute(
      path: '/projects/new',
      name: 'project-new',
      builder: (context, state) => const ProjectDetailPage(),
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
      builder: (context, state) => ProjectDetailPage(
        id: state.pathParameters['id']!,
        startEditing: true,
      ),
    ),
    GoRoute(
      path: '/projects/:id/members',
      name: 'project-members',
      builder: (context, state) =>
          ProjectMembersPage(projectId: state.pathParameters['id']!),
    ),
  ],
  ShellTab.contacts => [
    GoRoute(
      path: '/contacts',
      name: 'contacts',
      builder: (context, state) => const ContactsPage(),
    ),
    GoRoute(
      path: '/contacts/new',
      name: 'contact-new',
      builder: (context, state) {
        final extra = state.extra;
        if (extra is Map && extra['linkRequestId'] != null) {
          return ShellChromeHider(
            child: ContactFormPage(
              linkRequestId: extra['linkRequestId'] as String,
              lockedDisplayName: extra['lockedDisplayName'] as String?,
              lockedEmail: extra['lockedEmail'] as String?,
            ),
          );
        }
        return const ContactDetailPage();
      },
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
      builder: (context, state) {
        final extra = state.extra;
        final id = state.pathParameters['id']!;
        if (extra is Map && extra['linkRequestId'] != null) {
          return ShellChromeHider(
            child: ContactFormPage(
              editingId: id,
              linkRequestId: extra['linkRequestId'] as String,
            ),
          );
        }
        return ContactDetailPage(id: id, startEditing: true);
      },
    ),
  ],
  ShellTab.budgets => [
    GoRoute(
      path: '/budgets',
      name: 'budgets',
      builder: (context, state) => const BudgetsListPage(),
    ),
    GoRoute(
      path: '/budgets/new',
      name: 'budget-new',
      builder: (context, state) => const BudgetDetailPage(),
    ),
    GoRoute(
      path: '/budgets/:id',
      name: 'budget-detail',
      builder: (context, state) =>
          BudgetDetailPage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/budgets/:id/edit',
      name: 'budget-edit',
      builder: (context, state) =>
          BudgetDetailPage(id: state.pathParameters['id']!, startEditing: true),
    ),
  ],
  ShellTab.recurring => [
    GoRoute(
      path: '/recurring',
      name: 'recurring',
      builder: (context, state) => RecurringHomePage(
        initialTab: state.uri.queryParameters['tab'] == 'calendar'
            ? RecurringHomeTab.calendar
            : RecurringHomeTab.overview,
        focusDue: state.uri.queryParameters['focus'] == 'due',
      ),
    ),
    GoRoute(
      path: '/recurring/new',
      name: 'recurring-new',
      builder: (context, state) => RecurringDetailPage(
        preset: RecurringPreset.fromQuery(state.uri.queryParameters),
      ),
    ),
    GoRoute(
      path: '/recurring/:id',
      name: 'recurring-detail',
      builder: (context, state) =>
          RecurringDetailPage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/recurring/:id/settings',
      name: 'recurring-settings',
      builder: (context, state) => RecurringDetailPage(
        id: state.pathParameters['id']!,
        startEditing: true,
      ),
    ),
  ],
  ShellTab.savingGoals => [
    GoRoute(
      path: '/saving-goals',
      name: 'saving-goals',
      builder: (context, state) => const SavingGoalsListPage(),
    ),
    GoRoute(
      path: '/saving-goals/new',
      name: 'saving-goal-new',
      builder: (context, state) => const SavingGoalDetailPage(),
    ),
    GoRoute(
      path: '/saving-goals/:id',
      name: 'saving-goal-detail',
      builder: (context, state) =>
          SavingGoalDetailPage(id: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/saving-goals/:id/edit',
      name: 'saving-goal-edit',
      builder: (context, state) => SavingGoalDetailPage(
        id: state.pathParameters['id']!,
        startEditing: true,
      ),
    ),
  ],
  ShellTab.debts => [
    GoRoute(
      path: '/personal-debts',
      name: 'personal-debts',
      builder: (context, state) => const PersonalDebtsPage(),
    ),
    GoRoute(
      path: '/personal-debts/people/:key',
      name: 'personal-debt-person',
      builder: (context, state) => DebtPersonPage(
        personKey: state.pathParameters['key']!,
        name: state.extra is String ? state.extra as String : null,
      ),
    ),
    // A person-book entry (debt or repayment, with or without its own wallet
    // tx): the tx detail page in debt mode. Every statement line opens it
    // (0.4.1-1, D4).
    GoRoute(
      path: '/personal-debts/entries/:id',
      name: 'personal-debt-entry',
      builder: (context, state) =>
          DebtEntryDetailPage(entryId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/personal-debts/:id',
      name: 'personal-debt-entry-legacy',
      builder: (context, state) =>
          DebtEntryDetailPage(entryId: state.pathParameters['id']!),
    ),
  ],
  ShellTab.categories => [
    GoRoute(
      path: '/categories',
      name: 'categories',
      builder: (context, state) => const CategoriesPage(),
    ),
    GoRoute(
      path: '/categories/new',
      name: 'category-new',
      builder: (context, state) =>
          CategoryDetailPage.create(type: state.uri.queryParameters['type']),
    ),
    GoRoute(
      path: '/categories/:id',
      name: 'category-detail',
      builder: (context, state) =>
          CategoryDetailPage(editingId: state.pathParameters['id']),
    ),
  ],
  ShellTab.tags => [
    GoRoute(
      path: '/tags',
      name: 'tags',
      builder: (context, state) => const TagsPage(),
    ),
  ],
};

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

Widget _hubPage(BuildContext context, String group, String slug) {
  final page = hubPageFor(group, slug);
  if (page == null) return const HubIndexScreen();
  return page.screen?.call(context) ?? HubPageScreen(page: page);
}
