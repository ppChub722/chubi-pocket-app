import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/connection_shell.dart';
import 'package:chubi_pocket/core/network/connection_cubit.dart';
import 'package:chubi_pocket/features/auth/domain/user.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Conn extends MockCubit<ServerConnectionState>
    implements ConnectionCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

const _user = User(
  id: 'u-1',
  username: 'alice',
  displayName: 'Alice',
  currency: 'THB',
);

const _online = ServerConnectionState();
const _offline = ServerConnectionState(status: ConnectionStatus.offline);

/// The app's offline wiring (`MaterialApp.router`'s builder → ConnectionShell,
/// owner 2026-10-12): the banner shows while the server is unreachable and
/// takes the status-bar inset from the page; Retry polls now; coming back
/// shows "connected again" and the page reloads; on cold start the splash's
/// full-screen error speaks instead of the banner.
void main() {
  late _Conn conn;
  late _Auth auth;
  late StreamController<ServerConnectionState> states;
  late int loads;
  late BuildContext pageContext;

  setUp(() {
    conn = _Conn();
    auth = _Auth();
    states = StreamController<ServerConnectionState>.broadcast();
    loads = 0;
    whenListen(conn, states.stream, initialState: _online);
    when(() => conn.retryNow()).thenAnswer((_) async {});
  });

  tearDown(() => states.close());

  Future<void> pump(
    WidgetTester t, {
    AuthState authState = const AuthAuthenticated(_user),
  }) async {
    t.view.devicePixelRatio = 1;
    t.view.padding = const FakeViewPadding(top: 24);
    addTearDown(t.view.reset);
    when(() => auth.state).thenReturn(authState);
    await t.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<ConnectionCubit>.value(value: conn),
          BlocProvider<AuthCubit>.value(value: auth),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: [
              ThemeRegistry.byId(
                ThemeRegistry.defaultThemeId,
              ).colorsFor(Brightness.light),
            ],
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          builder: (context, child) =>
              AppUiConfig(child: ConnectionShell(child: child!)),
          home: Scaffold(
            body: Builder(
              builder: (context) {
                pageContext = context;
                return PullToRefresh(
                  onRefresh: () async => loads++,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [Text('row')],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Future<void> emit(WidgetTester t, ServerConnectionState s) async {
    states.add(s);
    await t.pump();
    await t.pump(const Duration(milliseconds: 300));
  }

  double pageTop() => MediaQuery.paddingOf(pageContext).top;

  const offlineText = "Can't reach the server · trying again…";

  testWidgets('online: no banner, the page keeps its status-bar inset', (
    t,
  ) async {
    await pump(t);
    expect(find.text(offlineText), findsNothing);
    expect(pageTop(), 24);
    expect(ConnectionScope.isOffline(pageContext), isFalse);
  });

  testWidgets('offline: banner on top, its inset removed from the page', (
    t,
  ) async {
    await pump(t);
    await emit(t, _offline);
    expect(find.text(offlineText), findsOneWidget);
    expect(pageTop(), 0);
    expect(ConnectionScope.isOffline(pageContext), isTrue);
    // A running app never swaps to a full-screen error: the page stays.
    expect(find.text('row'), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('Retry polls the server now', (t) async {
    await pump(t);
    await emit(t, _offline);
    await t.tap(find.text('Retry'));
    verify(() => conn.retryNow()).called(1);
  });

  testWidgets('back online: "connected again", the page reloads once', (
    t,
  ) async {
    await pump(t);
    await emit(t, _offline);
    expect(loads, 0);
    await emit(
      t,
      const ServerConnectionState(
        status: ConnectionStatus.backOnline,
        reconnects: 1,
      ),
    );
    expect(find.text('Connected again'), findsOneWidget);
    expect(loads, 1);
    expect(ConnectionScope.isOffline(pageContext), isFalse);
    // The notice settles away; the inset returns; no second reload.
    await emit(t, const ServerConnectionState(reconnects: 1));
    expect(find.text('Connected again'), findsNothing);
    expect(pageTop(), 24);
    expect(loads, 1);
  });

  testWidgets(
    'cold start: no banner over the splash, the scope still offline',
    (t) async {
      await pump(t, authState: const AuthInitial());
      await emit(t, _offline);
      expect(find.text(offlineText), findsNothing);
      expect(pageTop(), 24);
      expect(ConnectionScope.isOffline(pageContext), isTrue);
    },
  );
}
