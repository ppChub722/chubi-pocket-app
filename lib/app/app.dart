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
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/cubit/auth_cubit.dart';
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
  late final AuthCubit _authCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _tokenStorage = SecureTokenStorage();
    _apiClient = ApiClient(tokenStorage: _tokenStorage);
    _authRepository = AuthRepository(client: _apiClient);
    _usersRepository = UsersRepository(client: _apiClient);
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
