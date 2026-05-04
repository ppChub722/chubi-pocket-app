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
    this.description,
    this.note,
    this.creditLimit,
    this.statementDate,
    this.paymentDueDate,
    this.minimumPayment,
  });

  final String id;
  final String name;
  final AccountType type;

  /// Optional one-line guidance ("Daily-spend account"). User-editable.
  /// Mirrors `categories.description` semantics — see spec §03/§2.1 and
  /// the §05 design notes. Capped at 200 chars in the form, 280 server-side.
  final String? description;

  /// Free-form scratch notes — e.g. "Old emergency fund — don't touch",
  /// "Travel money for Japan trip 2026". Same shape as
  /// `categories.note`.
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
    String? description,
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
      description: description ?? this.description,
      note: note ?? this.note,
      creditLimit: creditLimit ?? this.creditLimit,
      statementDate: statementDate ?? this.statementDate,
      paymentDueDate: paymentDueDate ?? this.paymentDueDate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
    );
  }

  /// Reconstructs an [Account] from the BE's `GET /v1/accounts` row.
  /// Parallels [Category.fromJson]:
  /// - `icon` and `color` are nullable strings; missing icon → fallback
  ///   `wallet`, missing color → fallback `blue`.
  /// - `color` is `#RRGGBB`; resolved against the local swatch palette.
  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AccountType.fromJson(json['type'] as String),
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String,
      icon: AccountIconPreset.byId((json['icon'] as String?) ?? 'wallet'),
      color: AccountColor.byHex((json['color'] as String?) ?? '#64B5F6'),
      description: json['description'] as String?,
      note: json['note'] as String?,
      creditLimit: (json['credit_limit'] as num?)?.toDouble(),
      statementDate: json['statement_date'] as int?,
      paymentDueDate: json['payment_due_date'] as int?,
      minimumPayment: (json['minimum_payment'] as num?)?.toDouble(),
    );
  }

  /// Body for `POST /v1/accounts`. Excludes id (server-assigned) and
  /// status (always "active" on create).
  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'name': name,
      'type': type.toJson(),
      'balance': balance,
      'currency': currency,
      'icon': icon.id,
      'color': color.hex,
      if (description != null) 'description': description,
      if (note != null) 'note': note,
      if (type.isCredit) ...{
        'credit_limit': creditLimit,
        if (statementDate != null) 'statement_date': statementDate,
        if (paymentDueDate != null) 'payment_due_date': paymentDueDate,
        if (minimumPayment != null) 'minimum_payment': minimumPayment,
      },
    };
  }

  /// Body for `PUT /v1/accounts/:id`. `description` and `note` are
  /// always included so the server can distinguish "leave alone" (don't
  /// call this method) from "explicitly clear" (caller passed null).
  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'name': name,
      'type': type.toJson(),
      'currency': currency,
      'icon': icon.id,
      'color': color.hex,
      'description': description,
      'note': note,
      if (type.isCredit) ...{
        'credit_limit': creditLimit,
        'statement_date': statementDate,
        'payment_due_date': paymentDueDate,
        'minimum_payment': minimumPayment,
      },
    };
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
        description,
        note,
        creditLimit,
        statementDate,
        paymentDueDate,
        minimumPayment,
      ];
}
