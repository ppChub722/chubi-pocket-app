import '../../l10n/gen/app_localizations.dart';

/// Currencies the app offers (register, profile, accounts, debts). One list
/// so every picker shows the same set in the same order.
abstract final class Currencies {
  static const codes = ['THB', 'USD', 'EUR', 'GBP', 'JPY'];

  static const symbols = {
    'THB': '฿',
    'USD': r'$',
    'EUR': '€',
    'GBP': '£',
    'JPY': '¥',
  };

  static String symbolOf(String code) => symbols[code] ?? code;

  static String nameOf(AppLocalizations l, String code) => switch (code) {
    'THB' => l.currencyNameTHB,
    'USD' => l.currencyNameUSD,
    'EUR' => l.currencyNameEUR,
    'GBP' => l.currencyNameGBP,
    'JPY' => l.currencyNameJPY,
    _ => code,
  };
}
