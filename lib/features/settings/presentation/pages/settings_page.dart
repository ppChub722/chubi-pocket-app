import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart'
    show kLanguageNames;
import '../../../preferences/presentation/cubit/font_id_cubit.dart';
import '../../../preferences/presentation/cubit/locale_cubit.dart';
import '../../../preferences/presentation/cubit/theme_id_cubit.dart';
import '../../../preferences/presentation/cubit/theme_mode_cubit.dart';
import '../../../transactions/presentation/widgets/account_picker_sheet.dart';
import '../../../users/data/users_repository.dart';
import '../../../users/presentation/refresh_me.dart';

/// `/settings` (its own tab, opened by the 👤 chip): profile card (→ the
/// profile page) → แอป (theme, appearance, language, font) → เงิน (currency,
/// main wallet) → การแจ้งเตือน → ข้อมูล (archive, CSV export) → เกี่ยวกับ →
/// ออกจากระบบ. Opens with the auth cubit's `GET /users/me`; pull = that call.
class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.settingsTitle),
      extendBodyBehindAppBar: true,
      body: TabSwitchBody(
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final user = _userOf(state);
            if (user == null) return const SizedBox.shrink();
            final inset = MediaQuery.paddingOf(context);
            return DetailPageBody(
              onRefresh: () => refreshMe(context),
              physics: const AlwaysScrollableScrollPhysics(),
              // Clear the floating top bar.
              topInset: inset.top + AppSpacing.sm,
              bottomInset: AppSpacing.huge + inset.bottom,
              hero: _profileCard(context, user),
              sections: [
                (first) => SectionCard(
                  first: first,
                  title: l.settingsSectionApp,
                  children: const [
                    _ThemeRow(),
                    _ThemeModeRow(),
                    _LanguageRow(),
                    _FontRow(),
                  ],
                ),
                (first) => SectionCard(
                  first: first,
                  title: l.settingsSectionMoney,
                  children: [
                    _CurrencyRow(user: user),
                    _MoneyStyleRow(user: user),
                    // Colour only is always coloured: no switch for it.
                    if (MoneyStyle.fromPreference(user.moneyStyle).sign !=
                        MoneySign.none)
                      _MoneyColorRow(user: user),
                    _MainWalletRow(user: user),
                  ],
                ),
                (first) => SectionCard(
                  first: first,
                  children: [
                    DetailRow(
                      leading: const AppIcon(AppIcons.notifications),
                      label: l.settingsNotifications,
                      helper: user.notificationSummary == null
                          ? l.settingsNotificationsHint
                          : l.settingsNotificationsSummary(
                              user.notificationSummary!.on,
                              user.notificationSummary!.auto,
                            ),
                      showChevron: true,
                      onTap: () => context.push('/settings/notifications'),
                    ),
                  ],
                ),
                (first) => SectionCard(
                  first: first,
                  title: l.settingsSectionData,
                  children: [
                    DetailRow(
                      leading: const AppIcon(AppIcons.archive),
                      label: l.settingsArchived,
                      helper: l.settingsArchivedHint,
                      showChevron: true,
                      onTap: () => openPage(context, '/archived'),
                    ),
                    LockedInEdit(
                      locked: true,
                      child: DetailRow(
                        leading: const AppIcon(AppIcons.share),
                        label: l.settingsExportCsv,
                        trailing: AppBadge(label: l.settingsComingIn04),
                      ),
                    ),
                  ],
                ),
                (first) => SectionCard(
                  first: first,
                  title: l.settingsSectionAbout,
                  children: const [_VersionRow()],
                ),
              ],
              manage: DangerRow(
                icon: AppIcons.logout,
                label: l.settingsLogout,
                onTap: () => _confirmLogout(context),
              ),
            );
          },
        ),
      ),
    );
  }

  /// The profile card: avatar · name · @username · email, › the profile page.
  Widget _profileCard(BuildContext context, User user) {
    final tint = user.iconCode.tintFor(
      Theme.of(context).extension<AppColors>()!,
      avatarName: user.displayName,
    );
    return HeroCard(
      style: HeroStyle.tinted(color: tint, glyph: AppIcons.profile),
      icon: UserAvatar(
        displayName: user.displayName,
        iconCode: user.iconCode,
        size: 40,
      ),
      name: Text(user.displayName),
      fact: Text(
        [
          '@${user.username}',
          if (user.email?.isNotEmpty ?? false) user.email!,
        ].join(' · '),
      ),
      onTap: () => context.push('/settings/profile'),
    );
  }

  Future<void> _confirmLogout(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.settingsLogoutDialogTitle,
      message: l.settingsLogoutDialogBody,
      confirmLabel: l.settingsLogout,
      destructive: true,
    );
    if (ok && context.mounted) await context.read<AuthCubit>().logout();
  }
}

User? _userOf(AuthState state) {
  if (state is AuthAuthenticated) return state.user;
  if (state is AuthLoading && state.previous is AuthAuthenticated) {
    return (state.previous as AuthAuthenticated).user;
  }
  return null;
}

/// Theme as ONE row: its swatches + name, › a sheet of the themes.
class _ThemeRow extends StatelessWidget {
  const _ThemeRow();

  static String _name(AppLocalizations l, AppTheme t) => switch (t.id) {
    'mint' => l.settingsThemeMint,
    'sweet' => l.settingsThemeSweet,
    _ => t.id,
  };

  static Widget _swatches(AppTheme t) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final c in t.previewSwatch.take(2))
        Icon(Icons.circle, size: AppSpacing.lg, color: c),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final selected = context.watch<ThemeIdCubit>().state;
    final current = ThemeRegistry.all
        .where((t) => t.id == selected)
        .firstOrNull;
    return DetailRow(
      leading: const AppIcon(AppIcons.colorPicker),
      label: l.settingsTheme,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (current != null) ...[
            _swatches(current),
            const SizedBox(width: AppSpacing.xs),
            Text(_name(l, current)),
          ],
        ],
      ),
      showChevron: true,
      onTap: () async {
        final picked = await showOptionSheet<String>(
          context,
          title: l.settingsTheme,
          selected: selected,
          options: [
            for (final t in ThemeRegistry.all)
              SheetOption(
                value: t.id,
                label: _name(l, t),
                leading: _swatches(t),
              ),
          ],
        );
        if (picked != null && context.mounted) {
          context.read<ThemeIdCubit>().set(picked);
        }
      },
    );
  }
}

class _ThemeModeRow extends StatelessWidget {
  const _ThemeModeRow();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final mode = context.watch<ThemeModeCubit>().state;
    return DetailStacked(
      label: l.settingsAppearance,
      child: ThemeModeChips(
        selected: mode,
        onChanged: (m) => context.read<ThemeModeCubit>().set(m),
        lightLabel: l.modeLight,
        darkLabel: l.modeDark,
        systemLabel: l.modeSystem,
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final code = context.watch<LocaleCubit>().state.languageCode;
    return OptionMenuAnchor<String>(
      selected: code,
      onSelected: (picked) => context.read<LocaleCubit>().set(Locale(picked)),
      options: [
        for (final e in kLanguageNames.entries)
          SheetOption(value: e.key, label: e.value),
      ],
      builder: (context, toggle) => DetailRow(
        leading: const AppIcon(AppIcons.language),
        label: l.settingsLanguage,
        trailing: Text(kLanguageNames[code] ?? code),
        showChevron: true,
        onTap: toggle,
      ),
    );
  }
}

/// Font sheet — each option previews itself in its own family.
class _FontRow extends StatelessWidget {
  const _FontRow();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final lang = context.watch<LocaleCubit>().state.languageCode;
    final fontId = context.watch<FontIdCubit>().state;
    final available = FontRegistry.availableFor(lang);
    final current =
        available.where((f) => f.id == fontId).firstOrNull ??
        (available.isNotEmpty ? available.first : null);
    return DetailRow(
      leading: const AppIcon(AppIcons.font),
      label: l.settingsFont,
      trailing: Text(current?.family ?? '—'),
      showChevron: available.length > 1,
      onTap: available.length < 2
          ? null
          : () async {
              final picked = await showOptionSheet<String>(
                context,
                title: l.settingsFont,
                selected: current?.id,
                options: [
                  for (final f in available)
                    SheetOption(
                      value: f.id,
                      label: f.family,
                      subtitle: l.settingsFontSample,
                      // The preview must show the font itself.
                      labelStyle: Theme.of(
                        context,
                      ).textTheme.bodyLarge?.copyWith(fontFamily: f.family),
                    ),
                ],
              );
              if (picked != null && context.mounted) {
                context.read<FontIdCubit>().set(picked);
              }
            },
    );
  }
}

/// Version row. Hidden dev entrance: 5 quick taps open `/dev`.
class _VersionRow extends StatefulWidget {
  const _VersionRow();

  @override
  State<_VersionRow> createState() => _VersionRowState();
}

class _VersionRowState extends State<_VersionRow> {
  final _counter = TapUnlockCounter();
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform()
        .then((info) {
          if (mounted) {
            setState(() => _version = '${info.version} (${info.buildNumber})');
          }
        })
        .catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return DetailRow(
      leading: const AppIcon(AppIcons.info),
      label: l.settingsAppVersion,
      trailing: Text(_version),
      onTap: () {
        if (_counter.register()) context.push('/dev');
      },
    );
  }
}

/// Currency: a label, never converted. Pick → the "not converted" dialog →
/// ONE `PUT /users/me`.
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
    final auth = context.read<AuthCubit>();
    final users = context.read<UsersRepository>();
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      auth.updateUser(await users.updateMe(currency: code));
    } on ApiException catch (e) {
      if (mounted) showAppSnackBarOn(messenger, e.message, tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final value = widget.user.currency;
    return OptionMenuAnchor<String>(
      selected: value,
      onSelected: _change,
      options: [
        for (final c in Currencies.codes)
          SheetOption(
            value: c,
            label: '$c · ${Currencies.nameOf(l, c)}',
            leading: SizedBox(
              width: 24,
              child: Text(Currencies.symbolOf(c), textAlign: TextAlign.center),
            ),
          ),
      ],
      builder: (context, toggle) => DetailRow(
        leading: const AppIcon(AppIcons.currency),
        label: l.profileCurrencyLabel,
        helper: l.settingsCurrencyHint,
        trailing: Text('${Currencies.symbolOf(value)} $value'),
        showChevron: true,
        onTap: _busy ? null : toggle,
      ),
    );
  }
}

/// Saves the money style (ONE `PUT /users/me`, preference `money_style`);
/// the whole app re-draws its amounts from the answer.
Future<void> _saveMoneyStyle(BuildContext context, MoneyStyle style) async {
  final auth = context.read<AuthCubit>();
  final users = context.read<UsersRepository>();
  final messenger = ScaffoldMessenger.of(context);
  try {
    auth.updateUser(await users.setMoneyStyle(style.preference));
  } on ApiException catch (e) {
    showErrorSnackBarOn(messenger, e);
  }
}

/// Money format (owner 2026-10-17): + / −, ( ) or colour only — each option
/// and the row's helper show an example in that style.
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
    await _saveMoneyStyle(context, current.copyWith(sign: sign));
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
      return '${s.apply(income, negative: false)} · '
          '${s.apply(expense, negative: true)}';
    }

    return OptionMenuAnchor<MoneySign>(
      selected: current.sign,
      onSelected: _change,
      options: [
        for (final (sign, label) in [
          (MoneySign.plusMinus, l.settingsMoneySignPlusMinus),
          (MoneySign.parentheses, l.settingsMoneySignParentheses),
          (MoneySign.none, l.settingsMoneySignNone),
        ])
          SheetOption(value: sign, label: label, subtitle: example(sign)),
      ],
      builder: (context, toggle) => DetailRow(
        leading: const AppIcon(AppIcons.moneyStyle),
        label: l.settingsMoneyStyle,
        helper: example(current.sign),
        trailing: Text(switch (current.sign) {
          MoneySign.plusMinus => l.settingsMoneySignPlusMinus,
          MoneySign.parentheses => l.settingsMoneySignParentheses,
          MoneySign.none => l.settingsMoneySignNone,
        }),
        showChevron: true,
        onTap: _busy ? null : toggle,
      ),
    );
  }
}

/// Red / green on or off, for + / − and ( ) (colour only is always on).
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
              await _saveMoneyStyle(context, current.copyWith(colored: on));
              if (mounted) setState(() => _busy = false);
            },
    );
  }
}

/// Main wallet (`default_account`): the default when recording. Pick → ONE
/// `PUT /users/me` with `default_account_id`.
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
    final accounts = context.read<AccountsCubit>();
    final users = context.read<UsersRepository>();
    final auth = context.read<AuthCubit>();
    final messenger = ScaffoldMessenger.of(context);
    await accounts.loadIfNeeded();
    if (!mounted) return;
    final all = accounts.state.accounts;
    final currentId = widget.user.defaultAccount?.id;
    final r = await showAccountPickerSheet(
      context: context,
      accounts: all,
      selected: all.where((a) => a.id == currentId).firstOrNull,
      title: l.settingsMainWallet,
      allowNone: true,
    );
    if (r == null || !mounted) return;
    final newId = r is AccountPickerSelected ? r.account.id : null;
    if (newId == currentId) return;
    setState(() => _busy = true);
    try {
      auth.updateUser(
        await users.updateMe(
          defaultAccountId: newId,
          clearDefaultAccount: newId == null,
        ),
      );
    } on ApiException catch (e) {
      if (mounted) showAppSnackBarOn(messenger, e.message, tone: Tone.danger);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final wallet = widget.user.defaultAccount;
    return DetailRow(
      leading: const AppIcon(AppIcons.wallet),
      label: l.settingsMainWallet,
      helper: l.settingsMainWalletHint,
      trailing: Text(wallet?.name ?? l.settingsMainWalletNone),
      showChevron: true,
      onTap: _busy ? null : _pick,
    );
  }
}
