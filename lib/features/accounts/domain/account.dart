import 'package:equatable/equatable.dart';

import 'account_icon_preset.dart';
import 'account_type.dart';

/// One account — a place money lives. Cash wallet, bank account, e-wallet,
/// credit card, or pay-later service.
///
/// Mirror of the spec at
/// [`design/spec/03-accounts.md`](../../../../../chubi-pocket-docs/design/spec/03-accounts.md)
/// trimmed to fields the UI actually reads.
///
/// Phase 0 ships an in-memory mock store; Phase 1a wires this to
/// `GET /v1/accounts` against the real backend.
class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    required this.icon,
    required this.color,
    this.note,
    this.creditLimit,
    this.statementDate,
    this.paymentDueDate,
    this.minimumPayment,
  });

  final String id;
  final String name;
  final AccountType type;

  /// Free-text user-supplied context — e.g. "Old emergency fund — don't
  /// touch", "Travel money for Japan trip 2026". Optional. ~500-char advisory
  /// limit (no DB CHECK). Spec bump pending — schema needs `accounts.note
  /// TEXT NULLABLE` added when P1a backend ships.
  final String? note;

  /// Cached sum of transactions in account currency. Read-only via the
  /// account API — see spec §3.2.
  final double balance;
  final String currency;

  final AccountIconPreset icon;
  final AccountColor color;

  // Credit-only fields. Required when `type.isCredit` per the API-layer rule
  // in schema §03 (`credit_limit` required if `type IN ('credit_card',
  // 'pay_later')`); always null otherwise.
  final double? creditLimit;
  final int? statementDate;
  final int? paymentDueDate;
  final double? minimumPayment;

  /// Fraction of the credit limit currently in use, in the range `0..1`.
  /// Returns `null` for non-credit accounts. Negative balance = debt; the
  /// fraction uses `abs(balance) / creditLimit`.
  double? get creditUtilization {
    if (!type.isCredit) return null;
    if (creditLimit == null || creditLimit! <= 0) return null;
    return (balance.abs() / creditLimit!).clamp(0.0, 1.0);
  }

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    AccountIconPreset? icon,
    AccountColor? color,
    String? note,
    double? creditLimit,
    int? statementDate,
    int? paymentDueDate,
    double? minimumPayment,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      note: note ?? this.note,
      creditLimit: creditLimit ?? this.creditLimit,
      statementDate: statementDate ?? this.statementDate,
      paymentDueDate: paymentDueDate ?? this.paymentDueDate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        balance,
        currency,
        icon,
        color,
        note,
        creditLimit,
        statementDate,
        paymentDueDate,
        minimumPayment,
      ];
}
