import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:chubi_pocket/app/shell/quick_create_context.dart';
import 'package:chubi_pocket/features/accounts/data/accounts_repository.dart';
import 'package:chubi_pocket/features/accounts/domain/account.dart';
import 'package:chubi_pocket/features/accounts/domain/account_type.dart';
import 'package:chubi_pocket/features/accounts/domain/payment_provider.dart';
import 'package:chubi_pocket/features/accounts/presentation/cubit/accounts_cubit.dart';
import 'package:chubi_pocket/features/accounts/presentation/pages/account_detail_page.dart';
import 'package:chubi_pocket/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:chubi_pocket/features/categories/domain/category.dart';
import 'package:chubi_pocket/features/categories/domain/category_type.dart';
import 'package:chubi_pocket/features/categories/presentation/cubit/categories_cubit.dart';
import 'package:chubi_pocket/features/categories/presentation/pages/category_detail_page.dart';
import 'package:chubi_pocket/features/contacts/presentation/cubit/contacts_cubit.dart';
import 'package:chubi_pocket/features/notifications/presentation/cubit/unread_badge_cubit.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/data/personal_debts_repository.dart';
import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/pages/debt_person_page.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/pages/personal_debts_page.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
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

class _Categories extends MockCubit<CategoriesState>
    implements CategoriesCubit {}

/// The debts pages' one open call never answers (the preset is set before).
class _DebtsRepo extends Fake implements PersonalDebtsRepository {
  @override
  Future<DebtPeoplePage> listPeople({
    int page = 1,
    int perPage = 30,
    String? q,
    bool all = false,
    NetSide? side,
  }) => Completer<DebtPeoplePage>().future;

  @override
  Future<DebtPersonDetail> person(String key, {int perPage = 30}) =>
      Completer<DebtPersonDetail>().future;
}

class _Contacts extends MockCubit<ContactsState> implements ContactsCubit {}

class _Accounts extends MockCubit<AccountsState> implements AccountsCubit {}

/// Payment providers never answer (names fall back) — not under test.
class _AccountsRepo extends Fake implements AccountsRepository {
  @override
  Future<List<PaymentProvider>> paymentProviders() =>
      Completer<List<PaymentProvider>>().future;
}

const _wallet = Account(
  id: 'w1',
  name: 'KBank',
  type: AccountType.bank,
  currency: 'THB',
  balance: 0,
);

const _food = Category(id: 'cat1', name: 'Food', type: CategoryType.expense);

/// Each page tells the shell's + what it opens (owner 2026-10-12, quick
/// create per-page default): the real page, mounted under the shell's
/// registry, offers the right mode and preset. (The + colour follows the
/// mode — test/app/shell/quick_create_mode_test.dart.)
void main() {
  late QuickCreateContext registry;

  Future<void> pump(WidgetTester t, Widget page) async {
    registry = QuickCreateContext();
    addTearDown(registry.dispose);
    final auth = _Auth();
    final pending = _Pending();
    final unread = _Unread();
    final categories = _Categories();
    final contacts = _Contacts();
    final accounts = _Accounts();
    when(
      () => accounts.state,
    ).thenReturn(const AccountsState(accounts: [_wallet]));
    when(() => accounts.byId('w1')).thenReturn(_wallet);
    // The detail call stays in flight: the cached row is on screen.
    when(
      () => accounts.getDetail(any()),
    ).thenAnswer((_) => Completer<AccountDetail>().future);
    when(() => auth.state).thenReturn(const AuthUnauthenticated());
    when(() => pending.state).thenReturn(const PendingState());
    when(() => unread.state).thenReturn(0);
    when(() => categories.state).thenReturn(
      const CategoriesState(
        categories: [_food],
        status: CategoriesStatus.loaded,
      ),
    );
    when(() => categories.byId('cat1')).thenReturn(_food);
    when(() => categories.loadIfNeeded()).thenAnswer((_) async {});
    // The detail call stays in flight: the cached row is on screen.
    when(
      () => categories.fetchDetail(any()),
    ).thenAnswer((_) => Completer<CategoryDetail>().future);
    when(() => contacts.state).thenReturn(const ContactsState());
    when(() => contacts.load()).thenAnswer((_) async {});
    await t.pumpWidget(
      MultiRepositoryProvider(
        providers: [
          RepositoryProvider<AccountsRepository>.value(value: _AccountsRepo()),
          RepositoryProvider<PersonalDebtsRepository>.value(
            value: _DebtsRepo(),
          ),
        ],
        child: MultiBlocProvider(
          providers: [
            BlocProvider<AccountsCubit>.value(value: accounts),
            BlocProvider<AuthCubit>.value(value: auth),
            BlocProvider<PendingCubit>.value(value: pending),
            BlocProvider<UnreadBadgeCubit>.value(value: unread),
            BlocProvider<CategoriesCubit>.value(value: categories),
            BlocProvider<ContactsCubit>.value(value: contacts),
          ],
          child: MaterialApp(
            theme: ThemeData(extensions: [sweetTheme.lightColors]),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            builder: (context, child) => AppUiConfig(
              child: QuickCreateContextScope(registry: registry, child: child!),
            ),
            home: page,
          ),
        ),
      ),
    );
    await t.pump();
    await t.pump(const Duration(milliseconds: 100));
  }

  testWidgets('wallet detail → tx mode + that wallet', (t) async {
    await pump(t, const AccountDetailPage(accountId: 'w1'));
    expect(registry.active(), const QuickCreatePreset(account: _wallet));
    expect(registry.preset.mode, QuickCreateMode.tx);
  });

  testWidgets('category detail → tx mode + that category', (t) async {
    await pump(t, const CategoryDetailPage(editingId: 'cat1'));
    expect(registry.active(), const QuickCreatePreset(category: _food));
    expect(registry.preset.mode, QuickCreateMode.tx);
  });

  testWidgets('debts list → debt mode, no person', (t) async {
    await pump(t, const PersonalDebtsPage());
    expect(registry.active(), const QuickCreatePreset.debt());
    expect(registry.preset.mode, QuickCreateMode.debt);
  });

  testWidgets('debt person page → debt mode + that person', (t) async {
    await pump(t, const DebtPersonPage(personKey: 'c:c1', name: 'Mom'));
    expect(
      registry.active(),
      const QuickCreatePreset.debt(
        person: EmbeddedPerson(name: 'Mom', contactId: 'c1'),
      ),
    );
    expect(registry.preset.mode, QuickCreateMode.debt);
  });

  testWidgets('category create → no preset (tx mode)', (t) async {
    await pump(t, const CategoryDetailPage());
    expect(registry.active(), QuickCreatePreset.none);
    expect(registry.preset.mode, QuickCreateMode.tx);
  });
}
