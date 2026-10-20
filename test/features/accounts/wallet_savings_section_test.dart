import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/features/accounts/data/accounts_repository.dart';
import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/accounts/presentation/pages/account_detail_page.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../shared/fake_sync.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

class _Repo extends Fake implements AccountsRepository {
  @override
  @override
  Future<AccountDetail> getDetail(String id) =>
      Completer<AccountDetail>().future;
}

/// `Account.savings` as the BE sends it.
Map<String, dynamic> _savings({bool exceeds = false, bool tracked = true}) => {
  'balance': 1000.0,
  'saved': exceeds ? 1300.0 : 800.0,
  'spare': 200.0,
  'available': tracked ? (exceeds ? -300.0 : 200.0) : null,
  'saved_exceeds_balance': exceeds,
  'over_by': exceeds ? 300.0 : 0.0,
  'buckets': [
    {
      'type': 'goal',
      'id': 'g1',
      'name': 'Japan trip',
      'icon_code': {'icon': 'flag', 'color': 'blue'},
      'amount': 600.0,
    },
    {'type': 'spare', 'name': 'Spare', 'icon_code': null, 'amount': 200.0},
  ],
};

Account _wallet({
  Map<String, dynamic>? savings,
  bool track = true,
  bool withSavings = true,
}) => Account.fromJson({
  'id': 'w1',
  'name': 'KBank',
  'type': 'bank',
  'group': 'asset',
  'balance': 1000.0,
  'currency': 'THB',
  'icon_code': {'icon': 'bank', 'color': 'blue'},
  'status': 'active',
  'sort_order': 0,
  'my_role': 'owner',
  'can_edit': true,
  'is_shared': false,
  'track_balance': track,
  if (withSavings) 'savings': savings ?? _savings(tracked: track),
});

void main() {
  Future<void> pump(WidgetTester t, Account wallet) async {
    t.view.physicalSize = const Size(800, 2400);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final repo = _Repo();
    final cubit = AccountsCubit(
      repository: repo,
      coordinator: testCoordinator(),
    );
    addTearDown(cubit.close);
    cubit.emit(
      AccountsState(accounts: [wallet], status: AccountsStatus.loaded),
    );
    final auth = _Auth();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    final pending = _Pending();
    final unread = _Unread();
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, _) => AccountDetailPage(accountId: wallet.id),
        ),
      ],
    );
    await t.pumpWidget(
      RepositoryProvider<AccountsRepository>.value(
        value: repo,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AccountsCubit>.value(value: cubit),
            providersCubitProvider(),
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            theme: ThemeData(extensions: [sweetTheme.lightColors]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            builder: (context, child) => AppUiConfig(child: child!),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  test('Account.fromJson parses savings (and null when absent)', () {
    final s = _wallet(savings: _savings(exceeds: true)).savings!;
    expect(s.saved, 1300);
    expect(s.available, -300);
    expect(s.savedExceedsBalance, isTrue);
    expect(s.overBy, 300);
    expect(s.buckets, hasLength(2));
    expect(s.buckets.first.isGoal, isTrue);
    expect(s.buckets.first.id, 'g1');
    expect(s.buckets.last.isGoal, isFalse);
    expect(_wallet(withSavings: false).savings, isNull);
    expect(_wallet(track: false).savings!.available, isNull);
  });

  testWidgets('hero (bank): balance, split legend, actions', (t) async {
    await pump(t, _wallet().copyWith(monthIn: 400, monthOut: 200));
    expect(find.text('In the wallet'), findsOneWidget);
    // The split bar's facts: a label and its amount (the 200 is also the
    // spare bucket's amount in the overview below).
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Saved'), findsOneWidget);
    expect(find.text('฿800'), findsOneWidget);
    expect(find.text('฿200'), findsWidgets);
    expect(find.text('Adjust balance'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Pay card'), findsNothing);
  });

  testWidgets('hero (card): debt, limit bar, due alert, pay card', (t) async {
    final card = Account.fromJson({
      'id': 'c1',
      'name': 'Visa',
      'type': 'credit_card',
      'group': 'liability',
      'balance': -3858.0,
      'currency': 'THB',
      'icon_code': {'icon': 'credit_card', 'color': 'orange'},
      'status': 'active',
      'sort_order': 0,
      'my_role': 'owner',
      'can_edit': true,
      'is_shared': false,
      'track_balance': true,
      'credit_limit': 50000.0,
      'credit_used_pct': 8,
      'credit_available': 46142.0,
      'payment_due_date': 25,
      'due_date_next': '2026-10-25',
      'days_until_due': 8,
    });
    await pump(t, card);
    expect(find.text('Used on the card'), findsOneWidget);
    expect(find.text('Used 8%'), findsOneWidget);
    expect(find.textContaining('Available of the'), findsOneWidget);
    expect(find.textContaining('in 8 days'), findsOneWidget);
    expect(find.text('Pay card'), findsOneWidget);
  });
}
