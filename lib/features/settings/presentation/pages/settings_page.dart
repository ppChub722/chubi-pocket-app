import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../core/network/api_client.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../preferences/page_prefs.dart';
import '../../../users/presentation/refresh_me.dart';
import '../settings_labels.dart';
import 'settings_money_page.dart' show signedInUser;

/// The settings home (0.4.1-2 P7; owner 2026-10-28 mock): the profile card,
/// "ตั้งค่า" (the four groups, each with one line of its current values),
/// "ข้อมูล" (archive, CSV export, version), then logout.
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
            final user = signedInUser(state);
            if (user == null) return const SizedBox.shrink();
            final inset = MediaQuery.paddingOf(context);
            final changedPages = pagePrefPages
                .where((p) => p.changed(user.pagePref(p.id)))
                .length;
            return DetailPageBody(
              onRefresh: () => refreshMe(context),
              physics: const AlwaysScrollableScrollPhysics(),
              topInset: inset.top + AppSpacing.sm,
              bottomInset: AppSpacing.huge + inset.bottom,
              hero: _profileCard(context, user),
              sections: [
                (first) => SectionCard(
                  first: first,
                  title: l.settingsSectionSettings,
                  children: [
                    SettingsGroupRow(
                      icon: AppIcons.colorPicker,
                      label: l.settingsSectionApp,
                      summary: appSummary(context, l),
                      onTap: () => context.push('/settings/app'),
                    ),
                    SettingsGroupRow(
                      icon: AppIcons.currency,
                      label: l.settingsSectionMoney,
                      summary: moneySummary(l, user),
                      onTap: () => context.push('/settings/money'),
                    ),
                    SettingsGroupRow(
                      icon: AppIcons.notifications,
                      label: l.settingsNotifications,
                      summary: notificationsSummary(l, user),
                      onTap: () => context.push('/settings/notifications'),
                    ),
                    SettingsGroupRow(
                      icon: AppIcons.filter,
                      label: l.settingsGroupPagePrefs,
                      summary: l.settingsPagePrefsChangedSummary(changedPages),
                      onTap: () => context.push('/settings/page-prefs'),
                    ),
                  ],
                ),
                (first) => SectionCard(
                  first: first,
                  title: l.settingsSectionData,
                  children: [
                    AppDetailRow(
                      leading: const AppIcon(AppIcons.archive),
                      label: l.settingsArchived,
                      helper: l.settingsArchivedHint,
                      showChevron: true,
                      // Inside the settings tab, like the other groups.
                      onTap: () => context.push('/archived'),
                    ),
                    AppDetailRow(
                      leading: const AppIcon(AppIcons.download),
                      label: l.settingsExportCsv,
                      comingSoon: true,
                    ),
                    const _VersionRow(),
                  ],
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

  Widget _profileCard(BuildContext context, User user) {
    final tint = user.iconCode.tintFor(
      Theme.of(context).extension<AppColors>()!,
      avatarName: user.displayName,
    );
    return AppHeroCard(
      style: HeroStyle.tinted(color: tint, glyph: AppIcons.profile),
      onTap: () => context.push('/settings/profile'),
      content: [
        HeroIdentity(
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
            ].join(' | '),
          ),
        ),
      ],
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
            setState(
              () => _version =
                  '${info.version} (${ApiClient.releaseBuild(info.buildNumber)})',
            );
          }
        })
        .catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return AppDetailRow(
      leading: const AppIcon(AppIcons.info),
      label: l.settingsAppVersion,
      trailing: Text(_version),
      onTap: () {
        if (_counter.register()) context.push('/dev');
      },
    );
  }
}
