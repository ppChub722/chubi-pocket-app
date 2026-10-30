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
/// the entry defaults (main wallet, fee category). Every row saves at once
/// with one `PUT /users/me` whose answer updates the signed-in user; a
/// failure puts the old value back and says so (owner 2026-10-28: the same
/// instant save + rollback as every setting). Read-only while offline.
class SettingsMoneyPage extends StatelessWidget {
  const SettingsMoneyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.settingsSectionMoney, showBack: true),
      extendBodyBehindAppBar: true,
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final user = signedInUser(state);
          if (user == null) return const SizedBox.shrink();
          // Inside the Scaffold body: the inset includes the floating top bar.
          final inset = MediaQuery.paddingOf(context);
          final style = MoneyStyle.fromPreference(user.moneyStyle);
          return DetailPageBody(
            onRefresh: () => refreshMe(context),
            bottomInset: AppSpacing.huge + inset.bottom,
            sections: [
              (first) => SectionCard(
                first: first,
                title: l.settingsSectionNumbers,
                children: [
                  _CurrencyRow(user: user),
                  _MoneyStyleRow(user: user),
                  // No sign = the colour is the only cue: always on.
                  if (style.sign != MoneySign.none) _MoneyColorRow(user: user),
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

/// A money setting that saves at once: [write] is the one `/users/me` call;
/// its answer updates the signed-in user. A failure (or [confirm] answering
/// no) puts the old value back; a failure says "บันทึกไม่ได้ — เปลี่ยนกลับแล้ว".
Widget _liveMe<T>(
  BuildContext context, {
  required T value,
  required Future<User> Function(UsersRepository users, T value) write,
  required Widget Function(
    BuildContext context,
    T value,
    ValueChanged<T>? onChanged,
  )
  builder,
  Future<bool> Function(T value)? confirm,
}) {
  final l = AppLocalizations.of(context)!;
  final auth = context.read<AuthCubit>();
  final users = context.read<UsersRepository>();
  return LiveSetting<T>(
    value: value,
    failedMessage: (_) => l.notifSettingsSaveFailed,
    save: (v) async {
      if (confirm != null && !await confirm(v)) return false;
      auth.updateUser(await write(users, v));
      return true;
    },
    builder: builder,
  );
}

/// Currency: shown, not editable for now (changing it later would leave every
/// amount in the old currency).
class _CurrencyRow extends StatelessWidget {
  const _CurrencyRow({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final code = user.currency;
    final display =
        '${Currencies.symbolOf(code)}  $code | ${Currencies.nameOf(l, code)}';
    return AppDetailRow.pick(
      leading: const AppIcon(AppIcons.currency),
      label: l.profileCurrencyLabel,
      value: display,
      emptyText: display,
      locked: true,
    );
  }
}

/// The sign: the helper says what the row is for; each option shows its own
/// example (owner 2026-10-28).
class _MoneyStyleRow extends StatelessWidget {
  const _MoneyStyleRow({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final current = MoneyStyle.fromPreference(user.moneyStyle);
    String example(MoneySign sign) {
      final s = current.copyWith(sign: sign);
      final income = moneyString(context, 1000);
      final expense = moneyString(context, 540);
      return '${s.apply(income, negative: false)} | '
          '${s.apply(expense, negative: true)}';
    }

    return _liveMe<MoneySign>(
      context,
      value: current.sign,
      write: (u, sign) =>
          u.setMoneyStyle(current.copyWith(sign: sign).preference),
      builder: (context, sign, onChanged) => SettingDropdownRow<MoneySign>(
        leading: const AppIcon(AppIcons.moneyStyle),
        label: l.settingsMoneyStyle,
        helper: l.settingsMoneyStyleHint,
        value: moneySignLabel(l, sign),
        selected: sign,
        onSelected: onChanged,
        options: [
          for (final s in MoneySign.values)
            SheetOption(
              value: s,
              label: moneySignLabel(l, s),
              subtitle: example(s),
            ),
        ],
      ),
    );
  }
}

/// Decimals: always / never (rounded) / hide .00 only; each option shows
/// ฿1,000 and ฿99.50 its way.
class _MoneyDecimalsRow extends StatelessWidget {
  const _MoneyDecimalsRow({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final symbol = UiConfig.stringsOf(context).currencySymbol;
    String example(MoneyDecimals d) {
      final s = MoneyStyle(decimals: d);
      return '${formatMoneyWith(s, 1000, symbol: symbol)} | '
          '${formatMoneyWith(s, 99.5, symbol: symbol)}';
    }

    return _liveMe<MoneyDecimals>(
      context,
      value: MoneyDecimals.fromPreference(user.moneyDecimals),
      write: (u, d) => u.setMoneyDecimals(d.preference),
      builder: (context, current, onChanged) =>
          SettingDropdownRow<MoneyDecimals>(
            leading: const AppIcon(AppIcons.moneyDecimals),
            label: l.settingsMoneyDecimals,
            helper: l.settingsMoneyDecimalsHint,
            value: moneyDecimalsLabel(l, current),
            selected: current,
            onSelected: onChanged,
            options: [
              for (final d in MoneyDecimals.values)
                SheetOption(
                  value: d,
                  label: moneyDecimalsLabel(l, d),
                  subtitle: example(d),
                ),
            ],
          ),
    );
  }
}

class _MoneyColorRow extends StatelessWidget {
  const _MoneyColorRow({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final current = MoneyStyle.fromPreference(user.moneyStyle);
    return _liveMe<bool>(
      context,
      value: current.colored,
      write: (u, on) =>
          u.setMoneyStyle(current.copyWith(colored: on).preference),
      builder: (context, value, onChanged) => SettingToggleRow(
        leading: const AppIcon(AppIcons.moneyColor),
        label: l.settingsMoneyColor,
        caption: l.settingsMoneyColorHint,
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}

/// A picked record shown by name ([id] null = none).
typedef _Ref = ({String? id, String? name});

/// กระเป๋าหลัก: quick create starts with it; none = the last wallet used.
class _MainWalletRow extends StatelessWidget {
  const _MainWalletRow({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final wallet = user.defaultAccount;
    return _liveMe<_Ref>(
      context,
      value: (id: wallet?.id, name: wallet?.name),
      write: (u, r) =>
          u.updateMe(defaultAccountId: r.id, clearDefaultAccount: r.id == null),
      builder: (context, value, onChanged) => SettingPickRow(
        leading: const AppIcon(AppIcons.wallet),
        label: l.settingsMainWallet,
        helper: l.settingsMainWalletHint,
        value: Text(value.name ?? l.settingsMainWalletNone),
        onTap: onChanged == null
            ? null
            : () async {
                await context.read<AccountsCubit>().loadIfNeeded();
                if (!context.mounted) return;
                final r = await AccountPicker.one(
                  context,
                  selectedId: value.id,
                  title: l.settingsMainWallet,
                  allowNone: true,
                );
                if (r == null) return;
                onChanged(
                  r is AccountPicked
                      ? (id: r.account.id, name: r.account.name)
                      : (id: null, name: null),
                );
              },
      ),
    );
  }
}

/// หมวดค่าธรรมเนียม: the category a transfer fee is booked to.
class _FeeCategoryRow extends StatelessWidget {
  const _FeeCategoryRow({required this.user});

  final User user;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return _liveMe<_Ref>(
      context,
      value: (id: user.feeCategoryId, name: user.feeCategory?.name),
      write: (u, r) => u.setFeeCategory(r.id),
      builder: (context, value, onChanged) => SettingPickRow(
        leading: const AppIcon(AppIcons.receipt),
        label: l.settingsFeeCategory,
        helper: l.settingsFeeCategoryHint,
        value: Text(value.name ?? l.settingsMainWalletNone),
        onTap: onChanged == null
            ? null
            : () async {
                final r = await CategoryPicker.one(
                  context,
                  types: const {CategoryType.expense},
                  selectedId: value.id,
                  allowNone: true,
                  title: l.settingsFeeCategory,
                );
                if (r == null) return;
                onChanged(
                  r is CategoryPicked
                      ? (id: r.category.id, name: r.category.name)
                      : (id: null, name: null),
                );
              },
      ),
    );
  }
}
