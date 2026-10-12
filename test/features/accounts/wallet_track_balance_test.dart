import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/features/accounts/data/accounts_repository.dart';
import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/domain/payment_provider.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/accounts/presentation/pages/account_detail_page.dart';
import 'package:chubi_pocket/features/accounts/presentation/widgets/account_card.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/ui/tokens/app/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _Pending extends MockCubit<PendingState> implements PendingCubit {}

class _Unread extends MockCubit<int> implements UnreadBadgeCubit {}

class _Auth extends MockCubit<AuthState> implements AuthCubit {}

/// Records what the page sends, in the wire shape the BE reads.
class _Repo extends Fake implements AccountsRepository {
  final creates = <Map<String, dynamic>>[];
  final updates = <Map<String, dynamic>>[];

  @override
  Future<List<PaymentProvider>> paymentProviders() =>
      Completer<List<PaymentProvider>>().future;

  @override
  Future<AccountDetail> getDetail(String id) =>
      Completer<AccountDetail>().future;

  @override
  Future<Account> create(Account draft) async {
    creates.add(draft.toCreateJson());
    return Account.fromJson({
      ..._json(track: draft.trackBalance),
      'id': 'w9',
      'name': draft.name,
    });
  }

  @override
  Future<Account> update(Account account, {double? currentBalance}) async {
    updates.add(account.toUpdateJson(currentBalance: currentBalance));
    return Account.fromJson({
      ..._json(track: account.trackBalance),
      'id': account.id,
      'name': account.name,
    });
  }
}

/// A wallet as the BE sends it.
Map<String, dynamic> _json({bool track = true, double balance = 1234.5}) => {
  'id': 'w1',
  'name': 'KBank',
  'type': 'bank',
  'group': 'asset',
  'balance': balance,
  'currency': 'THB',
  'icon_code': {'icon': 'bank', 'color': 'blue'},
  'status': 'active',
  'sort_order': 0,
  'my_role': 'owner',
  'can_edit': true,
  'is_shared': false,
  'track_balance': track,
};

Account _wallet({bool track = true}) => Account.fromJson(_json(track: track));

void main() {
  late _Repo repo;

  Future<void> pump(WidgetTester t, {Account? wallet, Widget? home}) async {
    t.view.physicalSize = const Size(800, 1800);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    repo = _Repo();
    final cubit = AccountsCubit(repository: repo);
    addTearDown(cubit.close);
    if (wallet != null) {
      cubit.emit(
        AccountsState(accounts: [wallet], status: AccountsStatus.loaded),
      );
    }
    final auth = _Auth();
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    final pending = _Pending();
    final unread = _Unread();
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    await t.pumpWidget(
      RepositoryProvider<AccountsRepository>.value(
        value: repo,
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AccountsCubit>.value(value: cubit),
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [sweetTheme.lightColors]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            builder: (context, child) => AppUiConfig(child: child!),
            home:
                home ??
                (wallet == null
                    ? const AccountDetailPage(popOnCreate: true)
                    : AccountDetailPage(accountId: wallet.id)),
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  Future<void> tapText(WidgetTester t, String text) async {
    await t.pump(const Duration(seconds: 1));
    await t.tap(find.text(text).last);
    await t.pump(const Duration(seconds: 1));
  }

  testWidgets('list card: a tracked wallet shows its balance', (t) async {
    await pump(
      t,
      home: Scaffold(body: AccountCard(account: _wallet(), horizontal: false)),
    );
    expect(find.textContaining('1,234.50'), findsOneWidget);
  });

  testWidgets('list card: an untracked wallet shows no balance', (t) async {
    for (final horizontal in [false, true]) {
      await pump(
        t,
        home: Scaffold(
          body: AccountCard(
            account: _wallet(track: false),
            horizontal: horizontal,
          ),
        ),
      );
      expect(find.text('KBank'), findsOneWidget);
      expect(find.textContaining('1,234.50'), findsNothing);
    }
  });

  testWidgets('hero: untracked hides the balance and the ปรับยอด action', (
    t,
  ) async {
    await pump(t, wallet: _wallet(track: false));
    expect(find.textContaining('1,234.50'), findsNothing);
    expect(find.text('Balance not tracked'), findsOneWidget);
    expect(find.text('Adjust balance'), findsNothing);
    // Transfers stay.
    expect(find.text('Transfer'), findsOneWidget);
  });

  testWidgets('hero: tracked shows the balance and the ปรับยอด action', (
    t,
  ) async {
    await pump(t, wallet: _wallet());
    expect(find.textContaining('1,234.50'), findsWidgets);
    expect(find.text('Adjust balance'), findsOneWidget);
  });

  testWidgets('create: switch off sends track_balance:false, no balance', (
    t,
  ) async {
    await pump(t);
    // Opening balance is asked while tracking is on.
    expect(find.text('Opening balance'), findsOneWidget);
    await t.enterText(find.byType(TextFormField).first, 'Pocket');
    await t.tap(find.byType(Switch));
    await t.pump(const Duration(milliseconds: 300));
    expect(find.text('Opening balance'), findsNothing);
    await tapText(t, 'Save');
    expect(repo.creates, hasLength(1));
    expect(repo.creates.single['track_balance'], false);
    expect(repo.creates.single.containsKey('balance'), isFalse);
  });

  testWidgets('edit: off → on asks the balance once, one PUT', (t) async {
    await pump(t, wallet: _wallet(track: false));
    await t.tap(find.byTooltip('Edit'));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.byType(Switch));
    await t.pump(const Duration(milliseconds: 300));
    await tapText(t, 'Save');
    // The balance sheet asks for the current balance; nothing sent yet.
    expect(find.text('Current balance'), findsOneWidget);
    expect(repo.updates, isEmpty);
    await t.enterText(find.byType(TextField).last, '500');
    await t.pump();
    await tapText(t, 'Set balance');
    expect(repo.updates, hasLength(1));
    expect(repo.updates.single['track_balance'], true);
    expect(repo.updates.single['current_balance'], 500);
  });

  testWidgets('edit: on → off just saves track_balance:false', (t) async {
    await pump(t, wallet: _wallet());
    await t.tap(find.byTooltip('Edit'));
    await t.pump(const Duration(milliseconds: 300));
    await t.tap(find.byType(Switch));
    await t.pump(const Duration(milliseconds: 300));
    await tapText(t, 'Save');
    expect(find.text('Current balance'), findsNothing);
    expect(repo.updates, hasLength(1));
    expect(repo.updates.single['track_balance'], false);
    expect(repo.updates.single.containsKey('current_balance'), isFalse);
  });

  test('untracked: no credit figures, showsBalance false', () {
    final a = Account.fromJson({
      ..._json(track: false, balance: -2000),
      'type': 'credit_card',
      'credit_limit': 10000,
    });
    expect(a.showsBalance, isFalse);
    expect(a.creditUsed, 0);
    expect(a.creditUtilization, isNull);
    expect(a.creditAvailable, isNull);
  });
}
