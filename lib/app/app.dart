import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/fonts/font_registry.dart';
import '../core/network/api_client.dart';
import '../core/network/connectivity_cubit.dart';
import '../core/router/app_router.dart';
import '../core/storage/secure_token_storage.dart';
import '../core/theme/theme_builder.dart';
import '../core/theme/theme_registry.dart';
import '../features/accounts/data/accounts_repository.dart';
import '../features/accounts/presentation/cubit/accounts_cubit.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
import '../features/categories/data/categories_repository.dart';
import '../features/categories/presentation/cubit/categories_cubit.dart';
import '../features/contacts/data/contacts_repository.dart';
import '../features/contacts/presentation/cubit/contacts_cubit.dart';
import '../features/notifications/data/notifications_repository.dart';
import '../features/notifications/presentation/cubit/unread_badge_cubit.dart';
import '../features/personal_debts/data/personal_debts_repository.dart';
import '../features/personal_debts/presentation/cubit/personal_debts_cubit.dart';
import '../features/projects/data/projects_repository.dart';
import '../features/projects/presentation/cubit/projects_cubit.dart';
import '../features/tags/data/tags_repository.dart';
import '../features/tags/presentation/cubit/tags_cubit.dart';
import '../features/transactions/data/transactions_repository.dart';
import '../features/transactions/presentation/cubit/transactions_cubit.dart';
import '../features/users/data/users_repository.dart';
import '../features/preferences/presentation/cubit/font_id_cubit.dart';
import '../features/preferences/presentation/cubit/locale_cubit.dart';
import '../features/preferences/presentation/cubit/theme_id_cubit.dart';
import '../features/preferences/presentation/cubit/theme_mode_cubit.dart';
import '../l10n/gen/app_localizations.dart';
import '../shared/widgets/offline_banner.dart';

/// Root widget. Owns the long-lived singletons (token storage, API client,
/// auth repo + cubit) and rebuilds [MaterialApp.router] when theme / locale
/// preferences change.
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
  late final AuthCubit _authCubit;
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
    _authCubit = AuthCubit(
      repository: _authRepository,
      tokenStorage: _tokenStorage,
      apiClient: _apiClient,
    );
    _router = buildAppRouter(_authCubit);

    // Resolve cold-start auth state.
    _authCubit.init();
  }

  @override
  void dispose() {
    _authCubit.close();
    _apiClient.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ApiClient>.value(value: _apiClient),
        RepositoryProvider<SecureTokenStorage>.value(value: _tokenStorage),
        RepositoryProvider<AuthRepository>.value(value: _authRepository),
        RepositoryProvider<UsersRepository>.value(value: _usersRepository),
        RepositoryProvider<AccountsRepository>.value(
            value: _accountsRepository),
        RepositoryProvider<CategoriesRepository>.value(
            value: _categoriesRepository),
        RepositoryProvider<TagsRepository>.value(value: _tagsRepository),
        RepositoryProvider<TransactionsRepository>.value(
            value: _transactionsRepository),
        RepositoryProvider<NotificationsRepository>.value(
            value: _notificationsRepository),
        RepositoryProvider<ContactsRepository>.value(
            value: _contactsRepository),
        RepositoryProvider<PersonalDebtsRepository>.value(
            value: _personalDebtsRepository),
        RepositoryProvider<ProjectsRepository>.value(
            value: _projectsRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: _authCubit),
          BlocProvider<ConnectivityCubit>(
            create: (_) => ConnectivityCubit(),
          ),
          BlocProvider<ThemeIdCubit>(
            create: (_) => ThemeIdCubit(widget.prefs),
          ),
          BlocProvider<ThemeModeCubit>(
            create: (_) => ThemeModeCubit(widget.prefs),
          ),
          BlocProvider<LocaleCubit>(
            create: (_) => LocaleCubit(widget.prefs),
          ),
          BlocProvider<FontIdCubit>(
            create: (ctx) => FontIdCubit(widget.prefs, ctx.read<LocaleCubit>()),
          ),
          BlocProvider<AccountsCubit>(
            create: (_) => AccountsCubit(repository: _accountsRepository),
          ),
          BlocProvider<CategoriesCubit>(
            create: (_) => CategoriesCubit(repository: _categoriesRepository),
          ),
          BlocProvider<TagsCubit>(
            create: (_) => TagsCubit(repository: _tagsRepository),
          ),
          BlocProvider<TransactionsCubit>(
            create: (_) =>
                TransactionsCubit(repository: _transactionsRepository),
          ),
          BlocProvider<UnreadBadgeCubit>(
            create: (_) => UnreadBadgeCubit(
              repository: _notificationsRepository,
            )..start(),
          ),
          BlocProvider<ContactsCubit>(
            create: (_) => ContactsCubit(repository: _contactsRepository),
          ),
          BlocProvider<PersonalDebtsCubit>(
            create: (_) =>
                PersonalDebtsCubit(repository: _personalDebtsRepository),
          ),
          BlocProvider<ProjectsCubit>(
            create: (_) => ProjectsCubit(repository: _projectsRepository),
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

            return MaterialApp.router(
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
              builder: (context, child) => Column(
                children: [
                  const OfflineBanner(),
                  Expanded(child: child ?? const SizedBox.shrink()),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
