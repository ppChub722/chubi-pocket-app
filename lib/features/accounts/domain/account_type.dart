import 'package:flutter/material.dart';
import '../../../ui/ui.dart';

enum AccountType {
  cash,
  bank,
  eWallet,
  creditCard,
  payLater;

  IconData get icon {
    switch (this) {
      case AccountType.cash:
        return AppIcons.cash;
      case AccountType.bank:
        return AppIcons.bank;
      case AccountType.eWallet:
        return AppIcons.eWallet;
      case AccountType.creditCard:
        return AppIcons.creditCard;
      case AccountType.payLater:
        return AppIcons.payLater;
    }
  }

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

  bool get isCredit =>
      this == AccountType.creditCard || this == AccountType.payLater;

  Color colorOf(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return isCredit ? palette.walletLiability : palette.walletAsset;
  }
}
