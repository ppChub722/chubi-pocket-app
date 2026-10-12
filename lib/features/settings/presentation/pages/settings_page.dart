import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../users/presentation/refresh_me.dart';
import '../../../auth/presentation/widgets/auth_widgets.dart'
    show kLanguageNames;
import '../../../preferences/presentation/cubit/font_id_cubit.dart';
import '../../../preferences/presentation/cubit/locale_cubit.dart';
import '../../../preferences/presentation/cubit/theme_id_cubit.dart';
import '../../../preferences/presentation/cubit/theme_mode_cubit.dart';

/// `/settings` (its own tab, opened by the 👤 chip): profile card (→ the profile
/// page: password, locked currency) → การแจ้งเตือน →
/// การตั้งค่าส่วนตัว (theme cards, mode, language & font sheets) →
/// เกี่ยวกับ → ออกจากระบบ.
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
              // Clear the floating top bar.
              topInset: inset.top + AppSpacing.sm,
              bottomInset: AppSpacing.huge + inset.bottom,
              hero: HeaderCard(
                // The avatar's own colour (icon colour, else the initials colour).
                accent: user.iconCode.tintFor(
                  Theme.of(context).extension<AppColors>()!,
                  avatarName: user.displayName,
                ),
                leading: UserAvatar(
                  displayName: user.displayName,
                  iconCode: user.iconCode,
                  size: 52,
                ),
                title: Text(user.displayName),
                subtitle: Text(
                  [
                    '@${user.username}',
                    if (user.email?.isNotEmpty ?? false) user.email!,
                  ].join(' · '),
                ),
                trailing: const AppIcon(AppIcons.chevronRight),
                onTap: () => context.push('/settings/profile'),
              ),
              sections: [
                (first) => SectionCard(
                  first: first,
                  title: l.settingsNotifications,
                  children: [
                    DetailRow(
                      leading: const AppIcon(AppIcons.notifications),
                      label: l.settingsNotifications,
                      helper: l.settingsNotificationsHint,
                      showChevron: true,
                      onTap: () => context.push('/settings/notifications'),
                    ),
                  ],
                ),
                (first) => SectionCard(
                  first: first,
                  title: l.settingsSectionPreferences,
                  children: const [
                    _ThemeCards(),
                    _ThemeModeRow(),
                    _LanguageRow(),
                    _FontRow(),
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

/// Themes as colour-swatch cards with their translated names.
class _ThemeCards extends StatelessWidget {
  const _ThemeCards();

  static String _name(AppLocalizations l, AppTheme t) => switch (t.id) {
    'mint' => l.settingsThemeMint,
    'sweet' => l.settingsThemeSweet,
    _ => t.id,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final selected = context.watch<ThemeIdCubit>().state;
    return DetailStacked(
      label: l.settingsTheme,
      child: Row(
        children: [
          for (final t in ThemeRegistry.all) ...[
            Expanded(
              child: SelectableFrame(
                selected: t.id == selected,
                radius: AppRadius.md,
                child: AppCard(
                  style: AppCardStyle.bordered,
                  onTap: () => context.read<ThemeIdCubit>().set(t.id),
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          for (final c in t.previewSwatch.take(4))
                            Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.xs,
                              ),
                              child: Icon(
                                Icons.circle,
                                size: AppSpacing.lg,
                                color: c,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        _name(l, t),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (t != ThemeRegistry.all.last)
              const SizedBox(width: AppSpacing.sm),
          ],
        ],
      ),
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
