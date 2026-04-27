import 'package:flutter/material.dart';

/// The five account types from
/// [`design/spec/03-accounts.md §3.1`](../../../../../chubi-pocket-docs/design/spec/03-accounts.md).
///
/// Loans and savings are intentionally NOT account types — see §3.11. Loans
/// live in `scheduled_transactions` (P1c); savings goals link to a `bank`.
enum AccountType {
  cash,
  bank,
  eWallet,
  creditCard,
  payLater;

  /// Glyph used for the type chip in the create / edit form. Outline style
  /// keeps the chip visually consistent with the M3 default.
  IconData get icon {
    switch (this) {
      case AccountType.cash:
        return Icons.payments_outlined;
      case AccountType.bank:
        return Icons.account_balance_outlined;
      case AccountType.eWallet:
        return Icons.qr_code_2_outlined;
      case AccountType.creditCard:
        return Icons.credit_card_outlined;
      case AccountType.payLater:
        return Icons.access_time_outlined;
    }
  }

  /// Server-side string representation. Snake_case to match the spec
  /// (`'cash' | 'bank' | 'e_wallet' | 'credit_card' | 'pay_later'`).
  String toJson() {
    switch (this) {
      case AccountType.cash:
        return 'cash';
      case AccountType.bank:
        return 'bank';
      case AccountType.eWallet:
        return 'e_wallet';
      case AccountType.creditCard:
        return 'credit_card';
      case AccountType.payLater:
        return 'pay_later';
    }
  }

  static AccountType fromJson(String raw) {
    switch (raw) {
      case 'cash':
        return AccountType.cash;
      case 'bank':
        return AccountType.bank;
      case 'e_wallet':
        return AccountType.eWallet;
      case 'credit_card':
        return AccountType.creditCard;
      case 'pay_later':
        return AccountType.payLater;
      default:
        throw ArgumentError('Unknown account type: $raw');
    }
  }

  /// Credit-style accounts that carry billing fields and behave as debt
  /// (negative balance is debt; carry a `credit_limit` and statement / due
  /// date columns).
  bool get isCredit =>
      this == AccountType.creditCard || this == AccountType.payLater;
}
