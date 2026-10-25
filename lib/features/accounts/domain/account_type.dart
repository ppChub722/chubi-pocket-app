import 'package:flutter/material.dart';
import '../../../ui/ui.dart';

enum AccountType {
  cash,
  bank,
  eWallet,
  creditCard,
  payLater;

  IconData get icon => iconDefault.icon;

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

  /// The wire value or the enum name; null when unknown.
  static AccountType? tryParse(String? raw) {
    for (final t in values) {
      if (t.toJson() == raw || t.name == raw) return t;
    }
    return null;
  }

  bool get isCredit =>
      this == AccountType.creditCard || this == AccountType.payLater;
}
