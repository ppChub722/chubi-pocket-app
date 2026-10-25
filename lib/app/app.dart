import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'shell/keyboard_insets_guard.dart';
import '../core/data/data_changes.dart';
import '../core/data/sync_coordinator.dart';
import '../core/data/sync_changes.dart';
import '../core/data/sync_repository.dart';
import '../core/data/sync_store.dart';
import 'refresh/app_refresh.dart';
import '../core/network/api_client.dart';
import '../core/network/connectivity_cubit.dart';
import '../core/network/connection_cubit.dart';
import '../core/logger/breadcrumbs.dart';
import '../core/network/network_recorder.dart';
import '../core/router/app_router.dart';
import '../core/storage/secure_token_storage.dart';
import '../ui/tokens/app/theme/theme_builder.dart';
import '../features/accounts/data/accounts_repository.dart';
import '../features/accounts/presentation/cubit/accounts_cubit.dart';
import '../features/accounts/presentation/cubit/providers_cubit.dart';
import '../features/app_version/data/app_version_repository.dart';
import '../features/app_version/presentation/cubit/app_version_cubit.dart';
import 'connection_shell.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/budgets/data/budgets_repository.dart';
import '../features/budgets/presentation/cubit/budgets_cubit.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/categories/data/categories_repository.dart';
import '../features/categories/presentation/cubit/categories_cubit.dart';
import '../features/contacts/data/contacts_repository.dart';
import '../features/contacts/presentation/cubit/contacts_cubit.dart';
import '../features/home/data/dashboard_repository.dart';
import '../features/pending/data/pending_repository.dart';
import '../features/pending/presentation/cubit/pending_cubit.dart';
import '../features/home/presentation/cubit/dashboard_cubit.dart';
import '../features/notifications/data/notifications_repository.dart';
import '../features/notifications/presentation/cubit/unread_badge_cubit.dart';
import '../features/personal_debts/data/personal_debts_repository.dart';
import '../features/personal_debts/presentation/cubit/debt_directory_cubit.dart';
import '../features/projects/data/projects_repository.dart';
import '../features/projects/presentation/cubit/project_directory_cubit.dart';
import '../features/projects/presentation/cubit/projects_cubit.dart';
import '../features/saving_goals/data/saving_goals_repository.dart';
import '../features/saving_goals/presentation/cubit/saving_goals_cubit.dart';
import '../features/recurring/data/recurring_repository.dart';
import '../features/recurring/presentation/cubit/recurring_directory_cubit.dart';
import '../features/tags/data/tags_repository.dart';
import '../features/tags/presentation/cubit/tags_cubit.dart';
import '../features/transactions/data/transactions_repository.dart';
import '../features/transactions/presentation/cubit/form_defaults_cubit.dart';
import '../features/transactions/presentation/cubit/tx_form_options_cubit.dart';
import '../features/transactions/presentation/cubit/transactions_cubit.dart';
import '../features/users/data/users_repository.dart';
import '../features/preferences/presentation/cubit/font_id_cubit.dart';
import '../features/preferences/presentation/cubit/locale_cubit.dart';
import '../features/preferences/presentation/cubit/money_visibility_cubit.dart';
import '../features/preferences/presentation/cubit/theme_id_cubit.dart';
import '../features/preferences/presentation/cubit/theme_mode_cubit.dart';
import '../l10n/gen/app_localizations.dart';
import '../ui/ui.dart';

class ChubiPocketApp extends StatefulWidget {
  const ChubiPocketApp({required this.prefs, super.key});

  final SharedPreferences prefs;

  @override
  State<ChubiPocketApp> createState() => _ChubiPocketAppState();
}

class _ChubiPocketAppState extends State<ChubiPocketApp> {
  late final SecureTokenStorage _tokenStorage;
  late final ApiClient _apiClient;
  late final AuthRepository _authRepository;
  late final UsersRepository _usersRepository;
  late final AccountsRepository _accountsRepository;
  late final CategoriesRepository _categoriesRepository;
  late final TagsRepository _tagsRepository;
  late final TransactionsRepository _transactionsRepository;
  late final NotificationsRepository _notificationsRepository;
  late final ContactsRepository _contactsRepository;
  late final PersonalDebtsRepository _personalDebtsRepository;
  late final ProjectsRepository _projectsRepository;
  late final SavingGoalsRepository _savingGoalsRepository;
  late final BudgetsRepository _budgetsRepository;
  late final RecurringRepository _recurringRepository;
  late final DashboardRepository _dashboardRepository;
  late final PendingRepository _pendingRepository;
  late final SyncCoordinator _syncCoordinator;
  late final RefreshRegistry _refreshRegistry;
  late final AppRefresh _appRefresh;
  late final AuthCubit _authCubit;
  late final AppVersionCubit _versionCubit;
  late final AppLifecycleListener _lifecycle;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _tokenStorage = SecureTokenStorage();
    _apiClient = ApiClient(tokenStorage: _tokenStorage);
    _authRepository = AuthRepository(client: _apiClient);
    _usersRepository = UsersRepository(client: _apiClient);
    _accountsRepository = AccountsRepository(client: _apiClient);
    _categoriesRepository = CategoriesRepository(client: _apiClient);
    _tagsRepository = TagsRepository(client: _apiClient);
    _transactionsRepository = TransactionsRepository(client: _apiClient);
    _notificationsRepository = NotificationsRepository(client: _apiClient);
    _contactsRepository = ContactsRepository(client: _apiClient);
    _personalDebtsRepository = PersonalDebtsRepository(client: _apiClient);
    _projectsRepository = ProjectsRepository(client: _apiClient);
    _savingGoalsRepository = SavingGoalsRepository(client: _apiClient);
    _budgetsRepository = BudgetsRepository(client: _apiClient);
    _recurringRepository = RecurringRepository(client: _apiClient);
    _dashboardRepository = DashboardRepository(client: _apiClient);
    _pendingRepository = PendingRepository(client: _apiClient);
    _syncCoordinator = SyncCoordinator(
      repository: SyncRepository(client: _apiClient),
      store: SyncStore(),
    );
    _refreshRegistry = RefreshRegistry();
    _appRefresh = AppRefresh(
      coordinator: _syncCoordinator,
      registry: _refreshRegistry,
    );
    _apiClient.onSyncVersions = _syncCoordinator.onVersions;
    _syncCoordinator.onPageDataChanged = (keys) =>
        DataChanges.instance.changed(tablesForSync(keys: keys));
    _syncCoordinator.onDatasetsChanged = (sets) =>
        DataChanges.instance.changed(tablesForSync(sets: sets));
    _authCubit = AuthCubit(
      repository: _authRepository,
      tokenStorage: _tokenStorage,
      apiClient: _apiClient,
    );
    _versionCubit = AppVersionCubit(
      repository: AppVersionRepository(client: _apiClient),
      currentBuild: _apiClient.appBuild,
      outdated: _apiClient.onOutdated,
      prefs: widget.prefs,
    );
    _lifecycle = AppLifecycleListener(
      onHide: _appRefresh.onHidden,
      // Resume re-checks the version at most once a day (soft banner); a
      // forced update is a 426 on any call anyway.
      onResume: () {
        ShownTweenBuilder.replayAll.value++;
        unawaited(_versionCubit.checkIfDue());
        unawaited(
          _appRefresh.onResumed(
            signedIn: _authCubit.state is AuthAuthenticated,
          ),
        );
      },
    );
    _router = buildAppRouter(_authCubit, versionCubit: _versionCubit);
    _router.routerDelegate.addListener(() {
      final path = _router.routerDelegate.currentConfiguration.uri.path;
      NetworkRecorder.instance.noteRoute(path);
      Breadcrumbs.instance.page(path);
    });
    AppButton.tapObserver = Breadcrumbs.instance.tap;
    _versionCubit.check();

    _authCubit.init();
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    _versionCubit.close();
    _authCubit.close();
    _appRefresh.dispose();
    _syncCoordinator.dispose();
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>.value(value: _apiClient),
        RepositoryProvider<SyncCoordinator>.value(value: _syncCoordinator),
        RepositoryProvider<AppRefresh>.value(value: _appRefresh),
        RepositoryProvider<SecureTokenStorage>.value(value: _tokenStorage),
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<UsersRepository>.value(value: _usersRepository),
        RepositoryProvider<AccountsRepository>.value(
          value: _accountsRepository,
        ),
        RepositoryProvider<CategoriesRepository>.value(
          value: _categoriesRepository,
        ),
        RepositoryProvider<TagsRepository>.value(value: _tagsRepository),
        RepositoryProvider<TransactionsRepository>.value(
          value: _transactionsRepository,
        ),
        RepositoryProvider<NotificationsRepository>.value(
          value: _notificationsRepository,
        ),
        RepositoryProvider<ContactsRepository>.value(
          value: _contactsRepository,
        ),
        RepositoryProvider<PersonalDebtsRepository>.value(
          value: _personalDebtsRepository,
        ),
        RepositoryProvider<ProjectsRepository>.value(
          value: _projectsRepository,
        ),
        RepositoryProvider<SavingGoalsRepository>.value(
          value: _savingGoalsRepository,
        ),
        RepositoryProvider<BudgetsRepository>.value(value: _budgetsRepository),
        RepositoryProvider<RecurringRepository>.value(
          value: _recurringRepository,
        ),
        RepositoryProvider<DashboardRepository>.value(
          value: _dashboardRepository,
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: _authCubit),
          BlocProvider<ConnectivityCubit>(create: (_) => ConnectivityCubit()),
          BlocProvider<ConnectionCubit>(
            create: (ctx) => ConnectionCubit(
              client: _apiClient,
              deviceOnline: ctx.read<ConnectivityCubit>().stream,
            ),
          ),
          BlocProvider<AppVersionCubit>.value(value: _versionCubit),
          BlocProvider<ThemeIdCubit>(create: (_) => ThemeIdCubit(widget.prefs)),
          BlocProvider<ThemeModeCubit>(
            create: (_) => ThemeModeCubit(widget.prefs),
          ),
          BlocProvider<LocaleCubit>(create: (_) => LocaleCubit(widget.prefs)),
          BlocProvider<MoneyVisibilityCubit>(
            create: (_) => MoneyVisibilityCubit(widget.prefs),
          ),
          BlocProvider<FontIdCubit>(
            create: (ctx) => FontIdCubit(widget.prefs, ctx.read<LocaleCubit>()),
          ),
          BlocProvider<AccountsCubit>(
            create: (_) => AccountsCubit(
              repository: _accountsRepository,
              coordinator: _syncCoordinator,
            ),
          ),
          BlocProvider<CategoriesCubit>(
            create: (_) => CategoriesCubit(
              repository: _categoriesRepository,
              coordinator: _syncCoordinator,
            ),
          ),
          BlocProvider<TagsCubit>(
            create: (_) => TagsCubit(
              repository: _tagsRepository,
              coordinator: _syncCoordinator,
            ),
          ),
          BlocProvider<TransactionsCubit>(
            create: (_) =>
                TransactionsCubit(repository: _transactionsRepository),
          ),
          // Started by the auth listener below (once per sign-in), not here:
          // starting in both made two badge calls at every sign-in.
          BlocProvider<UnreadBadgeCubit>(
            create: (ctx) =>
                UnreadBadgeCubit(repository: _notificationsRepository),
          ),
          BlocProvider<ContactsCubit>(
            create: (_) => ContactsCubit(
              repository: _contactsRepository,
              coordinator: _syncCoordinator,
            ),
          ),
          BlocProvider<ProjectsCubit>(
            create: (_) => ProjectsCubit(repository: _projectsRepository),
          ),
          BlocProvider<SavingGoalsCubit>(
            create: (_) => SavingGoalsCubit(repository: _savingGoalsRepository),
          ),
          BlocProvider<BudgetsCubit>(
            create: (_) => BudgetsCubit(repository: _budgetsRepository),
          ),
          BlocProvider<DashboardCubit>(
            create: (_) => DashboardCubit(repository: _dashboardRepository),
          ),
          BlocProvider<PendingCubit>(
            create: (_) => PendingCubit(repository: _pendingRepository),
          ),
          BlocProvider<ProvidersCubit>(
            create: (_) => ProvidersCubit(coordinator: _syncCoordinator),
          ),
          BlocProvider<DebtDirectoryCubit>(
            create: (_) => DebtDirectoryCubit(coordinator: _syncCoordinator),
          ),
          BlocProvider<ProjectDirectoryCubit>(
            create: (_) => ProjectDirectoryCubit(coordinator: _syncCoordinator),
          ),
          BlocProvider<RecurringDirectoryCubit>(
            create: (_) =>
                RecurringDirectoryCubit(coordinator: _syncCoordinator),
          ),
          BlocProvider<FormDefaultsCubit>(
            create: (_) => FormDefaultsCubit(coordinator: _syncCoordinator),
          ),
          BlocProvider<TxFormOptionsCubit>(
            create: (ctx) => TxFormOptionsCubit(
              accounts: ctx.read<AccountsCubit>(),
              categories: ctx.read<CategoriesCubit>(),
              tags: ctx.read<TagsCubit>(),
              projects: ctx.read<ProjectDirectoryCubit>(),
              defaults: ctx.read<FormDefaultsCubit>(),
            ),
          ),
        ],
        child: Builder(
          builder: (context) {
            final themeId = context.watch<ThemeIdCubit>().state;
            final themeMode = context.watch<ThemeModeCubit>().state;
            final fontId = context.watch<FontIdCubit>().state;
            final locale = context.watch<LocaleCubit>().state;

            final theme = ThemeRegistry.byId(themeId);
            final font = FontRegistry.byId(fontId);

            return BlocListener<AuthCubit, AuthState>(
              listenWhen: _authIdentityChanged,
              listener: (ctx, state) {
                _clearPerUserCubits(ctx);
                _restartSync(state);
                if (state is AuthAuthenticated) {
                  ctx.read<UnreadBadgeCubit>().start();
                }
              },
              child: MaterialApp.router(
                debugShowCheckedModeBanner: false,
                title: 'chubiPocket',
                theme: ThemeBuilder.build(
                  theme: theme,
                  font: font,
                  brightness: Brightness.light,
                ),
                darkTheme: ThemeBuilder.build(
                  theme: theme,
                  font: font,
                  brightness: Brightness.dark,
                ),
                themeMode: themeMode,
                locale: locale,
                supportedLocales: supportedLocales,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                onGenerateTitle: (ctx) => AppLocalizations.of(ctx)!.appName,
                routerConfig: _router,
                // Same status-bar style on screens without an AppTopBar.
                builder: (context, child) => AppUiConfig(
                  child: AnnotatedRegion<SystemUiOverlayStyle>(
                    value: ThemeBuilder.systemBarsStyle(
                      Theme.of(context).scaffoldBackgroundColor,
                    ),
                    child: KeyboardInsetsGuard(
                      child: ValueListenableBuilder<bool>(
                        valueListenable: _appRefresh.busy,
                        builder: (context, busy, shell) =>
                            SavingOverlay(saving: busy, child: shell!),
                        child: ConnectionShell(
                          child: RefreshScope(
                            registry: _refreshRegistry,
                            child: child ?? const SizedBox.shrink(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  bool _authIdentityChanged(AuthState prev, AuthState curr) {
    final prevId = _identityOf(prev);
    final currId = _identityOf(curr);
    return prevId != currId;
  }

  String? _identityOf(AuthState s) {
    if (s is AuthAuthenticated) return s.user.id;
    if (s is AuthLoading && s.previous is AuthAuthenticated) {
      return (s.previous as AuthAuthenticated).user.id;
    }
    if (s is AuthFailure && s.previous is AuthAuthenticated) {
      return (s.previous as AuthAuthenticated).user.id;
    }
    return null; // AuthInitial / AuthUnauthenticated / failure-of-unauth
  }

  Future<void> _restartSync(AuthState state) async {
    await _syncCoordinator.clear();
    if (state is AuthAuthenticated) {
      unawaited(_appRefresh.start(state.user.id));
    }
  }

  void _clearPerUserCubits(BuildContext ctx) {
    ctx.read<AccountsCubit>().clear();
    ctx.read<CategoriesCubit>().clear();
    ctx.read<TagsCubit>().clear();
    ctx.read<TransactionsCubit>().clear();
    ctx.read<ContactsCubit>().clear();
    ctx.read<ProjectsCubit>().clear();
    ctx.read<SavingGoalsCubit>().clear();
    ctx.read<BudgetsCubit>().clear();
    ctx.read<DashboardCubit>().clear();
    ctx.read<PendingCubit>().clear();
    ctx.read<UnreadBadgeCubit>().clear();
    ctx.read<ProvidersCubit>().clear();
    ctx.read<DebtDirectoryCubit>().clear();
    ctx.read<ProjectDirectoryCubit>().clear();
    ctx.read<RecurringDirectoryCubit>().clear();
    ctx.read<FormDefaultsCubit>().clear();
  }
}
