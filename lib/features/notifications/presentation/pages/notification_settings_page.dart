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

/// `/notifications/settings` (§7, contract §5): per type, receive it and —
/// where it carries an action — run that action automatically on arrival
/// (muted = auto ignored). Invites / requests are always on. Switches save
/// immediately and flip back on failure.
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
      appBar: AppTopBar(title: l.notifSettingsTitle, showBack: true),
      extendBodyBehindAppBar: true,
      body: BlocConsumer<NotificationSettingsCubit, SettingsState>(
        // Save failures only — a failed first load is the ErrorView below.
        listenWhen: (a, b) =>
            a.error != b.error && b.error != null && b.settings != null,
        listener: (ctx, _) =>
            showAppSnackBar(ctx, l.notifSettingsSaveFailed, tone: Tone.danger),
        builder: (ctx, state) {
          final s = state.settings;
          if (s == null) {
            return state.status == SettingsStatus.error
                ? ErrorView(
                    error: state.error!,
                    onRetry: ctx.read<NotificationSettingsCubit>().load,
                  )
                : const LoadingView();
          }
          final cubit = ctx.read<NotificationSettingsCubit>();

          final muted = s.mutedTypes;
          final auto = s.autoTypes;
          Set<String> toggled(Set<String> set, String v, bool add) =>
              add ? {...set, v} : (set.toSet()..remove(v));

          /// One type: "receive" switch, plus — when the type has an action
          /// — an indented "do it automatically" switch. Muted → the auto
          /// switch is disabled (and ignored by the server) but keeps its
          /// value for when the type is turned back on.
          List<Widget> typeRows(
            NotificationType t,
            String label, {
            String? autoLabel,
            Widget? extra,
          }) {
            final on = !s.isMuted(t);
            return [
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                ),
                title: Text(label),
                value: on,
                onChanged: (v) =>
                    cubit.update(mutedTypes: toggled(muted, t.wire, !v)),
              ),
              if (autoLabel != null)
                SwitchListTile(
                  contentPadding: const EdgeInsets.only(
                    left: AppSpacing.xxxl,
                    right: AppSpacing.lg,
                  ),
                  dense: true,
                  title: Text(autoLabel),
                  value: s.isAuto(t),
                  onChanged: on
                      ? (v) => cubit.update(autoTypes: toggled(auto, t.wire, v))
                      : null,
                ),
              ?extra,
            ];
          }

          Widget groupTitle(String t) => Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              0,
            ),
            child: Text(
              t,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );

          final accounts = ctx.watch<AccountsCubit>().state.accounts;
          final receiving = accounts
              .where((a) => a.id == s.defaultAccountId)
              .firstOrNull;
          final paidAuto =
              !s.isMuted(NotificationType.splitPaid) &&
              s.isAuto(NotificationType.splitPaid);

          return ListView(
            // Clear the floating top bar.
            padding: EdgeInsets.only(
              top: MediaQuery.paddingOf(ctx).top,
              bottom: AppSpacing.huge,
            ),
            children: [
              SectionCard(
                title: l.notifSettingsReceive,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    child: Text(
                      l.notifSettingsAutoHint,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  groupTitle(l.notifGroupSplits),
                  ...typeRows(
                    NotificationType.splitCreated,
                    l.notifTypeSplitCreated,
                    autoLabel: l.notifAutoAddDebt,
                  ),
                  ...typeRows(
                    NotificationType.splitPaid,
                    l.notifTypeSplitPaid,
                    autoLabel: l.notifAutoRecordPayment,
                    extra: LockedInEdit(
                      // The wallet only matters while auto-record is on.
                      locked: !paidAuto,
                      child: DetailRow(
                        leading: const Icon(AppIcons.bank),
                        label: l.notifDefaultAccount,
                        trailing: Text(
                          receiving?.name ?? l.notifDefaultAccountNone,
                        ),
                        showChevron: true,
                        onTap: () async {
                          final r = await showAccountPickerSheet(
                            context: ctx,
                            accounts: accounts,
                            selected: receiving,
                            title: l.notifDefaultAccount,
                            // "None" = record it without a wallet.
                            allowNone: true,
                          );
                          if (r is AccountPickerSelected) {
                            cubit.update(defaultAccountId: r.account.id);
                          } else if (r is AccountPickerCleared) {
                            cubit.update(clearDefaultAccount: true);
                          }
                        },
                      ),
                    ),
                  ),
                  groupTitle(l.notifGroupProjects),
                  ...typeRows(
                    NotificationType.projectTxRecordedForYou,
                    l.notifTypeProjectTxForYou,
                    autoLabel: l.notifAutoCopyToBook,
                  ),
                  ...typeRows(
                    NotificationType.projectTxChanged,
                    l.notifTypeProjectTxChanged,
                    autoLabel: l.notifAutoUpdateCopy,
                  ),
                  ...typeRows(
                    NotificationType.projectAdded,
                    l.notifTypeProjectAdded,
                  ),
                  groupTitle(l.notifGroupRequests),
                  DetailRow(
                    label: l.notifGroupRequests,
                    trailing: AppBadge(
                      label: l.notifTypeAlwaysOn,
                      icon: AppIcons.lock,
                    ),
                  ),
                ],
              ),
              SectionCard(
                title: l.notifGroupProjects,
                children: [
                  // Not a notification — I recorded it myself.
                  SwitchListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.lg,
                    ),
                    title: Text(l.notifAutoResolveProject),
                    value: s.autoResolveOwnInProjects,
                    onChanged: (v) => cubit.update(autoResolveOwnInProjects: v),
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
