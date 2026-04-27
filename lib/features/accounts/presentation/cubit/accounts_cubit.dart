import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/account.dart';
import '../../domain/account_icon_preset.dart';
import '../../domain/account_type.dart';

/// In-memory accounts store for Phase 0 / early P1a UI work.
///
/// State is the full list of accounts in display order. Sort order is local
/// only — when the backend ships its `sort_order` column (planned Phase 2,
/// see spec §3.5), we'll persist the same list ordering.
///
/// Phase 1a backend integration: replace seed data with a Repository call
/// (`GET /v1/accounts`) and surface async states (loading / error). The
/// public method shape (`add` / `remove` / `reorder` / `update`) stays
/// stable so the UI layer doesn't churn.
class AccountsCubit extends Cubit<List<Account>> {
  AccountsCubit() : super(_seed());

  void add(Account account) {
    emit([...state, account]);
  }

  void remove(String id) {
    emit(state.where((a) => a.id != id).toList());
  }

  void update(Account account) {
    emit([
      for (final a in state)
        if (a.id == account.id) account else a,
    ]);
  }

  /// Returns the account with [id], or `null` if it has been removed /
  /// archived since the caller looked it up. The detail page uses this to
  /// render a "not found" state when the user navigates to a stale id.
  Account? byId(String id) {
    for (final a in state) {
      if (a.id == id) return a;
    }
    return null;
  }

  void reorder(int oldIndex, int newIndex) {
    final list = [...state];
    final adjusted = newIndex > oldIndex ? newIndex - 1 : newIndex;
    final item = list.removeAt(oldIndex);
    list.insert(adjusted, item);
    emit(list);
  }

  static List<Account> _seed() => const [
        Account(
          id: 'seed-1',
          name: 'Cash wallet',
          type: AccountType.cash,
          balance: 1200,
          currency: 'THB',
          icon: AccountIconPreset.cash,
          color: AccountColor.green,
        ),
        Account(
          id: 'seed-2',
          name: 'KBank Savings',
          type: AccountType.bank,
          balance: 45300,
          currency: 'THB',
          icon: AccountIconPreset.bank,
          color: AccountColor.blue,
        ),
        Account(
          id: 'seed-3',
          name: 'TrueMoney',
          type: AccountType.eWallet,
          balance: 850,
          currency: 'THB',
          icon: AccountIconPreset.eWallet,
          color: AccountColor.orange,
        ),
        Account(
          id: 'seed-4',
          name: 'KTC Visa',
          type: AccountType.creditCard,
          balance: -12000,
          currency: 'THB',
          icon: AccountIconPreset.card,
          color: AccountColor.purple,
          creditLimit: 50000,
          statementDate: 25,
          paymentDueDate: 15,
          minimumPayment: 1000,
        ),
        Account(
          id: 'seed-5',
          name: 'ShopeePay',
          type: AccountType.eWallet,
          balance: 300,
          currency: 'THB',
          icon: AccountIconPreset.shopping,
          color: AccountColor.pink,
        ),
        Account(
          id: 'seed-6',
          name: 'Atome',
          type: AccountType.payLater,
          balance: -1800,
          currency: 'THB',
          icon: AccountIconPreset.contactlessCard,
          color: AccountColor.red,
          creditLimit: 8000,
          paymentDueDate: 5,
        ),
        Account(
          id: 'seed-7',
          name: 'SCB Future',
          type: AccountType.bank,
          balance: 15200,
          currency: 'THB',
          icon: AccountIconPreset.savings,
          color: AccountColor.cyan,
        ),
      ];
}
