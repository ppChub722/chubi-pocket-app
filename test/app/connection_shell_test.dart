import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/connection_shell.dart';
import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/connection_cubit.dart';
import 'package:chubi_pocket/core/router/dev_hub_path.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Api extends Fake implements ApiClient {
  @override
  final Dio dio = Dio();
  final unreachable = StreamController<void>.broadcast();

  @override
  Stream<void> get onUnreachable => unreachable.stream;
  @override
  Stream<void> get onReachable => const Stream.empty();
}

/// The dev hub shows no app-wide connection UI: no banner, no offline
/// gating, while every other page does.
void main() {
  for (final devHub in [false, true]) {
    testWidgets('server unreachable, devHub: $devHub', (t) async {
      final auth = _Auth();
      when(() => auth.state).thenReturn(const AuthUnauthenticated());
      whenListen(auth, const Stream<AuthState>.empty());
      final api = _Api();
      final conn = ConnectionCubit(client: api);
      var offline = false;
      await t.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          theme: ThemeData(extensions: [sweetTheme.lightColors]),
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>.value(value: auth),
              BlocProvider<ConnectionCubit>.value(value: conn),
            ],
            child: ConnectionShell(
              devHub: devHub,
              child: Scaffold(
                body: Builder(
                  builder: (context) {
                    offline = ConnectionScope.isOffline(context);
                    return const SizedBox.expand();
                  },
                ),
              ),
            ),
          ),
        ),
      );
      api.unreachable.add(null);
      await t.pump(const Duration(milliseconds: 500));
      // The snack is set after the frame, shown on the next one.
      await t.pump(const Duration(milliseconds: 300));
      expect(conn.state.isOffline, isTrue);
      expect(find.byType(ConnectionBanner), devHub ? findsNothing : findsOne);
      expect(offline, !devHub);
      unawaited(conn.close());
      await t.pump();
    });
  }

  testWidgets('can\'t connect on login, then push /dev: the banner goes', (
    t,
  ) async {
    final auth = _Auth();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    whenListen(auth, const Stream<AuthState>.empty());
    final api = _Api()..dio.httpClientAdapter = _Down();
    final devHub = ValueNotifier(false);
    final conn = ConnectionCubit(client: api, devHub: devHub);
    final router = GoRouter(
      initialLocation: '/auth/login',
      routes: [
        GoRoute(
          path: '/auth/login',
          builder: (context, _) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => context.push('/dev'),
                child: const Text('unlock'),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/dev',
          builder: (_, _) => const Scaffold(body: Text('hub')),
        ),
      ],
    );
    void follow() => devHub.value = routerOnDevHub(router);
    router.routerDelegate.addListener(follow);
    await t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: auth),
          BlocProvider<ConnectionCubit>.value(value: conn),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          theme: ThemeData(extensions: [sweetTheme.lightColors]),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          builder: (context, child) => ValueListenableBuilder<bool>(
            valueListenable: devHub,
            builder: (context, dev, page) =>
                ConnectionShell(devHub: dev, child: page!),
            child: child,
          ),
        ),
      ),
    );
    api.unreachable.add(null);
    for (var i = 0; i < 70; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    expect(conn.state.status, ConnectionStatus.offline);
    expect(find.text("Can't reach the server"), findsOne);

    await t.tap(find.text('unlock'));
    await t.pumpAndSettle();
    expect(find.text('hub'), findsOne);
    // The pushed page leaves currentConfiguration.uri on login: the cause.
    expect(router.routerDelegate.currentConfiguration.uri.path, '/auth/login');
    expect(routerOnDevHub(router), isTrue);
    expect(find.byType(ConnectionBanner), findsNothing);

    router.routerDelegate.removeListener(follow);
    unawaited(conn.close());
    await t.pump();
    devHub.dispose();
  });

  Future<void> settle(WidgetTester t) async {
    // after-frame sync, then the bar's in / out animation
    for (var i = 0; i < 3; i++) {
      await t.pump(const Duration(milliseconds: 300));
    }
  }

  testWidgets('the X hides the snack until the state changes', (t) async {
    var state = const ServerConnectionState(
      status: ConnectionStatus.offline,
      attempt: 6,
      attempts: 6,
    );
    late StateSetter set;
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [sweetTheme.lightColors]),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, s) {
              set = s;
              return ConnectionSnack(state: state, onRetry: () {});
            },
          ),
        ),
      ),
    );
    await settle(t);
    await settle(t);
    expect(find.byType(ConnectionBanner), findsOne);
    await t.tap(find.byTooltip('Close'));
    await settle(t);
    await settle(t);
    expect(find.byType(ConnectionBanner), findsNothing);
    // A new cycle (connecting… again) brings it back.
    set(
      () => state = const ServerConnectionState(
        status: ConnectionStatus.reconnecting,
        attempts: 6,
      ),
    );
    await settle(t);
    await settle(t);
    expect(find.byType(ConnectionBanner), findsOne);
    // Closed while connecting: the next retry keeps it hidden, the end
    // (can't connect) shows it again.
    await t.tap(find.byTooltip('Close'));
    await settle(t);
    set(
      () => state = const ServerConnectionState(
        status: ConnectionStatus.reconnecting,
        attempt: 1,
        attempts: 6,
      ),
    );
    await settle(t);
    await settle(t);
    expect(find.byType(ConnectionBanner), findsNothing);
    set(
      () => state = const ServerConnectionState(
        status: ConnectionStatus.offline,
        attempt: 6,
        attempts: 6,
      ),
    );
    await settle(t);
    await settle(t);
    expect(find.byType(ConnectionBanner), findsOne);
  });
}

class _Down implements HttpClientAdapter {
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<void>? cancelFuture,
  ) async => throw DioException(
    requestOptions: options,
    type: DioExceptionType.connectionError,
  );

  @override
  void close({bool force = false}) {}
}
