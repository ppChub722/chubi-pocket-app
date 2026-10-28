import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/network/api_client.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../users/presentation/refresh_me.dart';
import '../settings_labels.dart';
import 'settings_money_page.dart' show signedInUser;

/// The settings home (0.4.1-2 P7, owner-approved mock): every user
/// preference, all kept on the account. Only the groups show here, each with
/// one line of its current values; a tap opens the group's page.
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
            final notif = user.notificationSummary;
            return DetailPageBody(
              onRefresh: () => refreshMe(context),
              physics: const AlwaysScrollableScrollPhysics(),
              topInset: inset.top + AppSpacing.sm,
              bottomInset: AppSpacing.huge + inset.bottom,
              hero: _profileCard(context, user),
              sections: [
                (first) => SectionCard(
                  first: first,
                  description: l.settingsHomeCaption,
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
                      icon: AppIcons.sync,
                      label: l.settingsGroupSync,
                      summary: syncSummary(l, user),
                      onTap: () => context.push('/settings/sync'),
                    ),
                    SettingsGroupRow(
                      icon: AppIcons.notifications,
                      label: l.settingsNotifications,
                      summary: notif == null
                          ? null
                          : l.settingsNotificationsOnSummary(
                              notif.on,
                              notif.total,
                            ),
                      onTap: () => context.push('/settings/notifications'),
                    ),
                    SettingsGroupRow(
                      icon: AppIcons.filter,
                      label: l.settingsGroupPagePrefs,
                      summary: l.settingsPagePrefsSummary(
                        PagePrefIds.all.length,
                      ),
                      onTap: () => context.push('/settings/page-prefs'),
                    ),
                  ],
                ),
                (first) => SectionCard(
                  first: first,
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
                        trailing: AppBadge(label: l.settingsComingSoon),
                      ),
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
