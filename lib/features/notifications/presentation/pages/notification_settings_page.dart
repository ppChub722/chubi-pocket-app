import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../transactions/presentation/widgets/account_picker_sheet.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification.dart';
import '../cubit/notification_settings_cubit.dart';

/// `/notifications/settings` (§7): what you get (per type; invites and
/// requests always on) and what happens automatically (bill splits ·
/// payments + receiving wallet · projects). Switches save immediately and
/// flip back on failure.
class NotificationSettingsPage extends StatelessWidget {
  const NotificationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => NotificationSettingsCubit(
        repository: ctx.read<NotificationsRepository>(),
      )..load(),
      child: const _Body(),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(
          title: l.notifSettingsTitle, showBack: true, showUniversal: false),
      body: BlocConsumer<NotificationSettingsCubit, SettingsState>(
        listenWhen: (a, b) =>
            a.errorMessage != b.errorMessage && b.errorMessage != null,
        listener: (ctx, _) =>
            showAppSnackBar(ctx, l.notifSettingsSaveFailed, tone: Tone.danger),
        builder: (ctx, state) {
          final s = state.settings;
          if (s == null) return const LoadingView();
          final cubit = ctx.read<NotificationSettingsCubit>();

          Widget muteSwitch(NotificationType t, String label) => SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                title: Text(label),
                value: !s.isMuted(t),
                onChanged: (on) => cubit.update(
                  mutedTypes: on
                      ? (s.mutedTypes.toSet()..remove(t.wire))
                      : {...s.mutedTypes, t.wire},
                ),
              );

          Widget autoSwitch(String label, bool value, ValueChanged<bool> set) =>
              SwitchListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                title: Text(label),
                value: value,
                onChanged: set,
              );

          Widget groupTitle(String t) => Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                child: Text(t,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant)),
              );

          final accounts = ctx.watch<AccountsCubit>().state.accounts;
          final receiving =
              accounts.where((a) => a.id == s.defaultAccountId).firstOrNull;

          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.huge),
            children: [
              SectionCard(
                title: l.notifSettingsReceive,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Text(l.notifSettingsReceiveHint,
                        style: Theme.of(context).textTheme.bodySmall),
                  ),
                  groupTitle(l.notifGroupSplits),
                  muteSwitch(NotificationType.splitCreated, l.notifTypeSplitCreated),
                  muteSwitch(NotificationType.splitPaid, l.notifTypeSplitPaid),
                  muteSwitch(NotificationType.splitReceived, l.notifTypeSplitReceived),
                  groupTitle(l.notifGroupProjects),
                  muteSwitch(NotificationType.projectTxRecordedForYou,
                      l.notifTypeProjectTxForYou),
                  muteSwitch(NotificationType.projectTxChanged,
                      l.notifTypeProjectTxChanged),
                  groupTitle(l.notifGroupRequests),
                  DetailRow(
                    label: l.notifGroupRequests,
                    trailing: AppBadge(label: l.notifTypeAlwaysOn, icon: AppIcons.lock),
                  ),
                ],
              ),
              SectionCard(
                title: l.notifSettingsAuto,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                    child: Row(
                      children: [
                        AppBadge(label: l.moreComingSoonBadge, tone: Tone.info),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(l.notifSettingsAutoPending,
                              style: Theme.of(context).textTheme.bodySmall),
                        ),
                      ],
                    ),
                  ),
                  groupTitle(l.notifGroupSplits),
                  autoSwitch(
                    l.notifAutoNotifySplit,
                    s.autoNotifyLinkedSplitContacts,
                    (v) => cubit.update(autoNotifyLinkedSplitContacts: v),
                  ),
                  autoSwitch(
                    l.notifAutoAddDebt,
                    s.autoAddToPersonalDebtOnSplitNotification,
                    (v) => cubit.update(autoAddToPersonalDebtOnSplitNotification: v),
                  ),
                  groupTitle(l.notifGroupPayments),
                  autoSwitch(
                    l.notifAutoRecordPayment,
                    s.autoRecordReceivedPayment,
                    (v) => cubit.update(autoRecordReceivedPayment: v),
                  ),
                  LockedInEdit(
                    // The wallet only matters while auto-record is on.
                    locked: !s.autoRecordReceivedPayment,
                    child: DetailRow(
                      leading: const Icon(AppIcons.bank),
                      label: l.notifDefaultAccount,
                      trailing: Text(receiving?.name ?? l.notifDefaultAccountNone),
                      showChevron: true,
                      onTap: () async {
                        final r = await showAccountPickerSheet(
                          context: ctx,
                          accounts: accounts,
                          selected: receiving,
                          title: l.notifDefaultAccount,
                        );
                        if (r is AccountPickerSelected) {
                          cubit.update(defaultAccountId: r.account.id);
                        }
                      },
                    ),
                  ),
                  groupTitle(l.notifGroupProjects),
                  autoSwitch(
                    l.notifAutoResolveProject,
                    s.autoResolveOwnInProjects,
                    (v) => cubit.update(autoResolveOwnInProjects: v),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}
