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
/// network does.
class _Repo extends Fake implements NotificationsRepository {
  bool down = true;
  int calls = 0;

  @override
  Future<NotificationSettings> getSettings() async {
    calls++;
    if (down) {
      throw const ApiException(code: 'NETWORK_ERROR', message: 'no net');
    }
    return NotificationSettings.fromJson({
      'muted_types': ['split_changed'],
      'auto_types': <String>[],
      'default_account': null,
      'auto_resolve_own_in_projects': false,
    });
  }
}

/// The settings page's first load is the template's (owner 2026-10-13: any
/// failure with no data → full-page error + retry, pullable; pull-to-refresh
/// on every page).
void main() {
  late _Repo repo;

  setUp(() => repo = _Repo());

  Future<void> pump(WidgetTester t) async {
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
}
