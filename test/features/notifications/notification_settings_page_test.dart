import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/notifications/data/notifications_repository.dart';
import 'package:chubi_pocket/features/notifications/domain/notification.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/pages/notification_settings_page.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

/// `getSettings` runs the REAL parsing on the BE's shape, or fails like the
/// network does; `updateSettings` records each call's arguments.
class _Repo extends Fake implements NotificationsRepository {
  bool down = true;
  int calls = 0;
  final puts = <Map<String, Object?>>[];

  @override
  Future<NotificationSettings> getSettings() async {
    calls++;
    if (down) {
      throw const ApiException(code: 'NETWORK_ERROR', message: 'no net');
    }
    return NotificationSettings.fromJson({
      'muted_types': ['split_changed', 'recurring_ending'],
      'auto_types': ['project_tx_changed'],
      'default_account': null,
      'auto_resolve_own_in_projects': false,
      'updated_at': '2026-10-17T08:00:00Z',
    });
  }

  @override
  Future<NotificationSettings> updateSettings({
    Set<String>? mutedTypes,
    Set<String>? autoTypes,
    String? defaultAccountId,
    bool clearDefaultAccount = false,
  }) async {
    puts.add({'muted': mutedTypes, 'auto': autoTypes});
    return NotificationSettings(
      mutedTypes: mutedTypes ?? {'split_changed', 'recurring_ending'},
      autoTypes: autoTypes ?? {'project_tx_changed'},
    );
  }
}

/// The settings page's first load is the template's (owner 2026-10-13: any
/// failure with no data → full-page error + retry, pullable; pull-to-refresh
/// on every page).
void main() {
  late _Repo repo;

  setUp(() => repo = _Repo());

  Future<void> pump(WidgetTester t) async {
    t.view.physicalSize = const Size(800, 4000);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    final accounts = _Accounts();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    when(() => accounts.state).thenReturn(const AccountsState());
    await t.pumpWidget(
      RepositoryProvider<NotificationsRepository>.value(
        value: repo,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
            BlocProvider<AccountsCubit>.value(value: accounts),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [sweetTheme.lightColors]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            builder: (context, child) => AppUiConfig(child: child!),
            home: const NotificationSettingsPage(),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump();
  }

  Finder seg(String type, String label) => find.descendant(
    of: find.byKey(ValueKey('mode-$type')),
    matching: find.text(label),
  );

  /// The list is lazy: scroll the segment into view, then tap it.
  Future<void> tapSeg(WidgetTester t, String type, String label) async {
    final f = seg(type, label);
    await t.scrollUntilVisible(
      f,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await t.tap(f);
  }

  testWidgets('failed first load: error + retry, pullable; retry loads', (
    t,
  ) async {
    await pump(t);
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    repo.down = false;
    await t.tap(
      find.descendant(
        of: find.byType(ErrorView),
        matching: find.bySubtype<ButtonStyleButton>(),
      ),
    );
    await t.pump();
    await t.pump();
    expect(find.byType(ErrorView), findsNothing);
    expect(find.byType(DetailPageBody), findsOneWidget);
    expect(find.byType(RefreshIndicator), findsOneWidget);
    expect(repo.calls, 2);
  });

  testWidgets('one call to open; retired split_paid rows and the own-rows '
      'switch are gone; recurring rows are 2-state', (t) async {
    repo.down = false;
    await pump(t);
    expect(repo.calls, 1);
    expect(find.byKey(const ValueKey('mode-split_paid')), findsNothing);
    expect(find.byKey(const ValueKey('mode-split_received')), findsNothing);
    expect(find.byType(AppSwitch), findsNothing);
    expect(find.byKey(const ValueKey('mode-recurring_due')), findsOneWidget);
    expect(seg('recurring_due', 'Auto'), findsNothing);
    expect(seg('split_created', 'Auto'), findsOneWidget);
  });

  testWidgets('a state change is ONE PUT with only the changed list', (
    t,
  ) async {
    repo.down = false;
    await pump(t);
    // notify -> auto: only auto_types changes.
    await tapSeg(t, 'split_created', 'Auto');
    await t.pump();
    expect(repo.puts, hasLength(1));
    expect(repo.puts.single['muted'], isNull);
    expect(repo.puts.single['auto'], {'project_tx_changed', 'split_created'});
    // off -> notify (recurring_ending): only muted_types changes.
    await tapSeg(t, 'recurring_ending', 'Notify');
    await t.pump();
    expect(repo.puts, hasLength(2));
    expect(repo.puts.last['muted'], {'split_changed'});
    expect(repo.puts.last['auto'], isNull);
    // notify -> off: muted gains the type.
    await tapSeg(t, 'recurring_due', 'Off');
    await t.pump();
    expect(repo.puts.last['muted'], contains('recurring_due'));
    // tapping the chosen state sends nothing.
    final n = repo.puts.length;
    await tapSeg(t, 'recurring_due', 'Off');
    await t.pump();
    expect(repo.puts, hasLength(n));
  });

  testWidgets('the wallet row shows only while its type is on auto', (t) async {
    repo.down = false;
    await pump(t);
    expect(find.byKey(const ValueKey('auto-wallet')), findsNothing);
    await tapSeg(t, 'project_tx_recorded_for_you', 'Auto');
    await t.pump();
    await t.pump();
    expect(find.byKey(const ValueKey('auto-wallet')), findsOneWidget);
    await tapSeg(t, 'project_tx_recorded_for_you', 'Notify');
    await t.pump();
    await t.pump();
    expect(find.byKey(const ValueKey('auto-wallet')), findsNothing);
  });
}
