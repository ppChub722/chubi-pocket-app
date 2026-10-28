import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../auth/domain/user.dart';
import '../../auth/presentation/widgets/auth_widgets.dart' show kLanguageNames;
import '../../preferences/presentation/cubit/font_id_cubit.dart';
import '../../preferences/presentation/cubit/locale_cubit.dart';
import '../../preferences/presentation/cubit/theme_id_cubit.dart';
import '../../preferences/presentation/cubit/theme_mode_cubit.dart';

/// Names of the settings values, shared by the settings home summaries and
/// the group pages, so a value reads the same in both.
String themeName(AppLocalizations l, AppTheme t) => switch (t.id) {
  'mint' => l.settingsThemeMint,
  'sweet' => l.settingsThemeSweet,
  _ => t.id,
};

String themeModeLabel(AppLocalizations l, ThemeMode m) => switch (m) {
  ThemeMode.light => l.modeLight,
  ThemeMode.dark => l.modeDark,
  ThemeMode.system => l.modeSystem,
};

String moneySignLabel(AppLocalizations l, MoneySign s) => switch (s) {
  MoneySign.plusMinus => l.settingsMoneySignPlusMinus,
  MoneySign.parentheses => l.settingsMoneySignParentheses,
  MoneySign.none => l.settingsMoneySignNone,
};

String moneyDecimalsLabel(AppLocalizations l, MoneyDecimals d) => switch (d) {
  MoneyDecimals.always => l.settingsMoneyDecimalsAlways,
  MoneyDecimals.never => l.settingsMoneyDecimalsNever,
  MoneyDecimals.auto => l.settingsMoneyDecimalsAuto,
};

String onOffLabel(AppLocalizations l, bool on) =>
    on ? l.settingsSummaryOn : l.settingsSummaryOff;

/// "แอป": theme | mode | language | the current language's font.
String appSummary(BuildContext context, AppLocalizations l) {
  final theme = ThemeRegistry.byId(context.watch<ThemeIdCubit>().state);
  final mode = context.watch<ThemeModeCubit>().state;
  final lang = context.watch<LocaleCubit>().state.languageCode;
  final font = FontRegistry.byId(context.watch<FontIdCubit>().state);
  return [
    themeName(l, theme),
    themeModeLabel(l, mode),
    kLanguageNames[lang] ?? lang,
    font.family,
  ].join(' | ');
}

/// "เงิน": currency | sign | decimals | main wallet.
String moneySummary(AppLocalizations l, User u) {
  final style = MoneyStyle.fromPreference(u.moneyStyle);
  return [
    u.currency,
    moneySignLabel(l, style.sign),
    moneyDecimalsLabel(l, MoneyDecimals.fromPreference(u.moneyDecimals)),
    l.settingsMainWalletSummary(
      u.defaultAccount?.name ?? l.settingsMainWalletNone,
    ),
  ].join(' | ');
}

/// "ซิงก์อัตโนมัติ": both switches.
String syncSummary(AppLocalizations l, User u) => l.settingsSyncSummary(
  onOffLabel(l, u.autoSyncEvents),
  onOffLabel(l, u.autoSyncDebts),
);
