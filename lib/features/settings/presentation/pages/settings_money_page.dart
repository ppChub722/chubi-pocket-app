import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/widgets/account_picker.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/widgets/category_picker.dart';
import '../../../users/data/users_repository.dart';
import '../../../users/presentation/refresh_me.dart';
import '../settings_labels.dart';

/// Settings › เงิน: how amounts show (currency, sign, colour, decimals) and
/// the entry defaults (main wallet, fee category). Every row is one
/// `PUT /users/me`; the answer updates the signed-in user.
class SettingsMoneyPage extends StatelessWidget {
  const SettingsMoneyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final inset = MediaQuery.paddingOf(context);
    return Scaffold(
      appBar: AppTopBar(title: l.settingsSectionMoney, showBack: true),
      extendBodyBehindAppBar: true,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = signedInUser(state);
          if (user == null) return const SizedBox.shrink();
          return DetailPageBody(
            onRefresh: () => refreshMe(context),
            topInset: inset.top + AppSpacing.lg,
            bottomInset: AppSpacing.huge + inset.bottom,
            sections: [
              (first) => SectionCard(
                first: first,
                title: l.settingsSectionNumbers,
                children: [
                  _CurrencyRow(user: user),
                  _MoneyStyleRow(user: user),
                  if (MoneyStyle.fromPreference(user.moneyStyle).sign !=
                      MoneySign.none)
                    _MoneyColorRow(user: user),
                  _MoneyDecimalsRow(user: user),
                ],
              ),
              (first) => SectionCard(
                first: first,
                title: l.settingsSectionEntryDefaults,
                children: [
                  _MainWalletRow(user: user),
                  _FeeCategoryRow(user: user),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The signed-in user (also while a refresh runs), else null.
User? signedInUser(AuthState state) {
  if (state is AuthAuthenticated) return state.user;
  if (state is AuthLoading && state.previous is AuthAuthenticated) {
    return (state.previous as AuthAuthenticated).user;
  }
  return null;
}

/// Runs one `/users/me` write and hands the answer to [AuthCubit]; a failure
/// shows a snackbar and leaves the user as it was.
Future<void> saveMe(
  BuildContext context,
  Future<User> Function(UsersRepository users) write,
) async {
  final auth = context.read<AuthCubit>();
  final users = context.read<UsersRepository>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    auth.updateUser(await write(users));
  } on ApiException catch (e) {
    showErrorSnackBarOn(messenger, e);
  }
}

/// Currency: a label, never converted.
class _CurrencyRow extends StatefulWidget {
  const _CurrencyRow({required this.user});

  final User user;

  @override
  State<_CurrencyRow> createState() => _CurrencyRowState();
}

class _CurrencyRowState extends State<_CurrencyRow> {
  bool _busy = false;

  Future<void> _change(String code) async {
    if (code == widget.user.currency || _busy) return;
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.profileCurrencyChangeTitle,
      message: l.profileCurrencyChangeMessage,
      confirmLabel: l.profileCurrencyChangeConfirm,
    );
    if (!ok || !mounted) return;
    setState(() => _busy = true);
    await saveMe(context, (u) => u.updateMe(currency: code));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final value = widget.user.currency;
    return SettingDropdownRow<String>(
      leading: const AppIcon(AppIcons.currency),
      label: l.profileCurrencyLabel,
      helper: l.settingsCurrencyHint,
      value: '${Currencies.symbolOf(value)} $value',
      selected: value,
      onSelected: _busy ? null : _change,
      options: [
        for (final c in Currencies.codes)
          SheetOption(
            value: c,
            label: '$c | ${Currencies.nameOf(l, c)}',
            leading: SizedBox(
              width: 24,
              child: Text(Currencies.symbolOf(c), textAlign: TextAlign.center),
            ),
          ),
      ],
    );
  }
}

class _MoneyStyleRow extends StatefulWidget {
  const _MoneyStyleRow({required this.user});

  final User user;

  @override
  State<_MoneyStyleRow> createState() => _MoneyStyleRowState();
}

class _MoneyStyleRowState extends State<_MoneyStyleRow> {
  bool _busy = false;

  Future<void> _change(MoneySign sign) async {
    final current = MoneyStyle.fromPreference(widget.user.moneyStyle);
    if (sign == current.sign || _busy) return;
    setState(() => _busy = true);
    await saveMe(
      context,
      (u) => u.setMoneyStyle(current.copyWith(sign: sign).preference),
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final current = MoneyStyle.fromPreference(widget.user.moneyStyle);
    String example(MoneySign sign) {
      final s = current.copyWith(sign: sign);
      final income = moneyString(context, 1000);
      final expense = moneyString(context, 540);
      return '${s.apply(income, negative: false)} | '
          '${s.apply(expense, negative: true)}';
    }

    return SettingDropdownRow<MoneySign>(
      leading: const AppIcon(AppIcons.moneyStyle),
      label: l.settingsMoneyStyle,
      helper: example(current.sign),
      value: moneySignLabel(l, current.sign),
      selected: current.sign,
      onSelected: _busy ? null : _change,
      options: [
        for (final sign in MoneySign.values)
          SheetOption(
            value: sign,
            label: moneySignLabel(l, sign),
            subtitle: example(sign),
          ),
      ],
    );
  }
}

/// Decimals: always / never (rounded) / hide .00 only — each option shows
/// ฿1,000 and ฿99.50 its way.
class _MoneyDecimalsRow extends StatefulWidget {
  const _MoneyDecimalsRow({required this.user});

  final User user;

  @override
  State<_MoneyDecimalsRow> createState() => _MoneyDecimalsRowState();
}

class _MoneyDecimalsRowState extends State<_MoneyDecimalsRow> {
  bool _busy = false;

  Future<void> _change(MoneyDecimals d) async {
    if (_busy || d == MoneyDecimals.fromPreference(widget.user.moneyDecimals)) {
      return;
    }
    setState(() => _busy = true);
    await saveMe(context, (u) => u.setMoneyDecimals(d.preference));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final current = MoneyDecimals.fromPreference(widget.user.moneyDecimals);
    final symbol = UiConfig.stringsOf(context).currencySymbol;
    String example(MoneyDecimals d) {
      final s = MoneyStyle(decimals: d);
      return '${formatMoneyWith(s, 1000, symbol: symbol)} | '
          '${formatMoneyWith(s, 99.5, symbol: symbol)}';
    }

    return SettingDropdownRow<MoneyDecimals>(
      leading: const AppIcon(AppIcons.moneyDecimals),
      label: l.settingsMoneyDecimals,
      helper: example(current),
      value: moneyDecimalsLabel(l, current),
      selected: current,
      onSelected: _busy ? null : _change,
      options: [
        for (final d in MoneyDecimals.values)
          SheetOption(
            value: d,
            label: moneyDecimalsLabel(l, d),
            subtitle: example(d),
          ),
      ],
    );
  }
}

class _MoneyColorRow extends StatefulWidget {
  const _MoneyColorRow({required this.user});

  final User user;

  @override
  State<_MoneyColorRow> createState() => _MoneyColorRowState();
}

class _MoneyColorRowState extends State<_MoneyColorRow> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final current = MoneyStyle.fromPreference(widget.user.moneyStyle);
    return SettingToggleRow(
      label: l.settingsMoneyColor,
      caption: l.settingsMoneyColorHint,
      value: current.colored,
      onChanged: _busy
          ? null
          : (on) async {
              setState(() => _busy = true);
              await saveMe(
                context,
                (u) =>
                    u.setMoneyStyle(current.copyWith(colored: on).preference),
              );
              if (mounted) setState(() => _busy = false);
            },
    );
  }
}

/// กระเป๋าหลัก: quick create starts with it; none = the last wallet used.
class _MainWalletRow extends StatefulWidget {
  const _MainWalletRow({required this.user});

  final User user;

  @override
  State<_MainWalletRow> createState() => _MainWalletRowState();
}

class _MainWalletRowState extends State<_MainWalletRow> {
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy) return;
    final l = AppLocalizations.of(context)!;
    await context.read<AccountsCubit>().loadIfNeeded();
    if (!mounted) return;
    final currentId = widget.user.defaultAccount?.id;
    final r = await AccountPicker.one(
      context,
      selectedId: currentId,
      title: l.settingsMainWallet,
      allowNone: true,
    );
    if (r == null || !mounted) return;
    final newId = r is AccountPicked ? r.account.id : null;
    if (newId == currentId) return;
    setState(() => _busy = true);
    await saveMe(
      context,
      (u) => u.updateMe(
        defaultAccountId: newId,
        clearDefaultAccount: newId == null,
      ),
    );
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DetailRow(
      leading: const AppIcon(AppIcons.wallet),
      label: l.settingsMainWallet,
      helper: l.settingsMainWalletHint,
      trailing: Text(
        widget.user.defaultAccount?.name ?? l.settingsMainWalletNone,
      ),
      showChevron: true,
      onTap: _busy ? null : _pick,
    );
  }
}

/// หมวดค่าธรรมเนียม (moved here from the category page): the category a
/// transfer fee is booked to.
class _FeeCategoryRow extends StatefulWidget {
  const _FeeCategoryRow({required this.user});

  final User user;

  @override
  State<_FeeCategoryRow> createState() => _FeeCategoryRowState();
}

class _FeeCategoryRowState extends State<_FeeCategoryRow> {
  bool _busy = false;

  Future<void> _pick() async {
    if (_busy) return;
    final l = AppLocalizations.of(context)!;
    final currentId = widget.user.feeCategoryId;
    final r = await CategoryPicker.one(
      context,
      types: const {CategoryType.expense},
      selectedId: currentId,
      allowNone: true,
      title: l.settingsFeeCategory,
    );
    if (r == null || !mounted) return;
    final newId = r is CategoryPicked ? r.category.id : null;
    if (newId == currentId) return;
    setState(() => _busy = true);
    await saveMe(context, (u) => u.setFeeCategory(newId));
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final fee = widget.user.feeCategory;
    return DetailRow(
      leading: const AppIcon(AppIcons.category),
      label: l.settingsFeeCategory,
      helper: l.settingsFeeCategoryHint,
      trailing: Text(fee?.name ?? l.settingsMainWalletNone),
      showChevron: true,
      onTap: _busy ? null : _pick,
    );
  }
}
