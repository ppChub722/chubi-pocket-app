import 'package:equatable/equatable.dart';

import '../../../shared/icon_maker/icon_code.dart';
import 'account_type.dart';

/// One account — a place money lives. Cash wallet, bank account, e-wallet,
/// credit card, or pay-later service.
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
    IconCode? iconCode,
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
      iconCode: iconCode ?? this.iconCode,
      description: description ?? this.description,
      note: note ?? this.note,
      creditLimit: creditLimit ?? this.creditLimit,
      statementDate: statementDate ?? this.statementDate,
      paymentDueDate: paymentDueDate ?? this.paymentDueDate,
      minimumPayment: minimumPayment ?? this.minimumPayment,
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
      ];
}
