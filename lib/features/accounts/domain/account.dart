import 'package:equatable/equatable.dart';

import '../../../shared/icon_maker/icon_code.dart';
import 'account_identifier.dart';
import 'account_type.dart';
import 'wallet_member.dart';

/// One account — a place where money lives. Cash wallet, bank account, e-wallet,
/// credit card, or pay-later service. User-facing surfaces call this a
/// **wallet** (spec §14 naming rule); code and API keep `account`.
class Account extends Equatable {
  const Account({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.currency,
    this.iconCode,
    this.description,
    this.note,
    this.creditLimit,
    this.statementDate,
    this.paymentDueDate,
    this.minimumPayment,
    this.members = const [],
    this.myReportScope,
    this.isShared = false,
    this.identifiers = const [],
  });

  final String id;
  final String name;
  final AccountType type;
  final String? description;
  final String? note;
  final double balance;
  final String currency;
  final IconCode? iconCode;

  final double? creditLimit;
  final int? statementDate;
  final int? paymentDueDate;
  final double? minimumPayment;

  /// Shared-wallet surface (API §14 pinned contract on `GET /v1/accounts`):
  /// active members (always including the caller), the caller's own
  /// report scope, and `is_shared` = active member count > 1.
  final List<WalletMember> members;
  final WalletReportScope? myReportScope;
  final bool isShared;

  /// Numbers this wallet is known by on bank slips (spec 15 §5) — the
  /// owner edits them; slip import matches against them.
  final List<AccountIdentifier> identifiers;

  /// Active members other than [selfUserId] — for the "other members"
  /// avatar stack on cards / detail (spec B2: exclude self).
  List<WalletMember> otherMembers(String? selfUserId) =>
      members.where((m) => m.userId != selfUserId).toList();

  /// A card / pay-later's used credit — what's owed on it. A positive
  /// balance (overpaid) uses none; 0 for other types.
  double get creditUsed => type.isCredit && balance < 0 ? -balance : 0;

  /// Credit left to spend: limit − [creditUsed] (null without a limit).
  /// Overpaid → the whole limit (the overpaid part is money of mine, not
  /// credit).
  double? get creditAvailable {
    final limit = creditLimit;
    if (!type.isCredit || limit == null || limit <= 0) return null;
    return limit - creditUsed;
  }

  /// [creditUsed] / limit, 0..1 (null: not credit, or no limit).
  double? get creditUtilization {
    final limit = creditLimit;
    if (!type.isCredit || limit == null || limit <= 0) return null;
    return (creditUsed / limit).clamp(0.0, 1.0);
  }

  /// Money I owe through this wallet: a card's used credit, or a wallet
  /// that isn't credit gone below zero (overdrawn). 0 otherwise.
  double get debt => balance < 0 ? -balance : 0;

  /// Money I have in it — any positive balance (an overpaid card too).
  double get asset => balance > 0 ? balance : 0;

  Account copyWith({
    String? id,
    String? name,
    AccountType? type,
    double? balance,
    String? currency,
    IconCode? iconCode,
    String? description,
    String? note,
    double? creditLimit,
    int? statementDate,
    int? paymentDueDate,
    double? minimumPayment,
    List<WalletMember>? members,
    WalletReportScope? myReportScope,
    bool? isShared,
    List<AccountIdentifier>? identifiers,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      currency: currency ?? this.currency,
      iconCode: iconCode ?? this.iconCode,
      description: description ?? this.description,
      note: note ?? this.note,
      creditLimit: creditLimit ?? this.creditLimit,
      statementDate: statementDate ?? this.statementDate,
      paymentDueDate: paymentDueDate ?? this.paymentDueDate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
      members: members ?? this.members,
      myReportScope: myReportScope ?? this.myReportScope,
      isShared: isShared ?? this.isShared,
      identifiers: identifiers ?? this.identifiers,
    );
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      name: json['name'] as String,
      type: AccountType.fromJson(json['type'] as String),
      balance: (json['balance'] as num).toDouble(),
      currency: json['currency'] as String,
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
      description: json['description'] as String?,
      note: json['note'] as String?,
      creditLimit: (json['credit_limit'] as num?)?.toDouble(),
      statementDate: json['statement_date'] as int?,
      paymentDueDate: json['payment_due_date'] as int?,
      minimumPayment: (json['minimum_payment'] as num?)?.toDouble(),
      members: json['members'] is List
          ? (json['members'] as List)
                .cast<Map<String, dynamic>>()
                .map(WalletMember.fromJson)
                .toList()
          : const [],
      myReportScope: json['my_report_scope'] != null
          ? WalletReportScopeWire.parse(json['my_report_scope'] as String)
          : null,
      isShared: (json['is_shared'] as bool?) ?? false,
      identifiers: json['identifiers'] is List
          ? (json['identifiers'] as List)
                .cast<Map<String, dynamic>>()
                .map(AccountIdentifier.fromJson)
                .toList()
          : const [],
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'name': name,
      'type': type.toJson(),
      'balance': balance,
      'currency': currency,
      if (iconCode != null) 'icon_code': iconCode!.toJson(),
      if (description != null) 'description': description,
      if (note != null) 'note': note,
      if (type.isCredit) ...{
        'credit_limit': creditLimit,
        if (statementDate != null) 'statement_date': statementDate,
        if (paymentDueDate != null) 'payment_due_date': paymentDueDate,
        if (minimumPayment != null) 'minimum_payment': minimumPayment,
      },
      if (identifiers.isNotEmpty)
        'identifiers': [for (final i in identifiers) i.toJson()],
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'name': name,
      'type': type.toJson(),
      'currency': currency,
      'icon_code': iconCode?.toJson(),
      'description': description,
      'note': note,
      if (type.isCredit) ...{
        'credit_limit': creditLimit,
        'statement_date': statementDate,
        'payment_due_date': paymentDueDate,
        'minimum_payment': minimumPayment,
      },
      // The whole list — the BE replaces the stored one ([] clears it).
      'identifiers': [for (final i in identifiers) i.toJson()],
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    type,
    balance,
    currency,
    iconCode,
    description,
    note,
    creditLimit,
    statementDate,
    paymentDueDate,
    minimumPayment,
    members,
    identifiers,
    myReportScope,
    isShared,
  ];
}
