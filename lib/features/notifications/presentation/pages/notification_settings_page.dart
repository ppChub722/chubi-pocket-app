import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
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
        listener: (ctx, state) => showAppSnackBar(
          ctx,
          // A type that can't be muted says so; the switch is already back.
          state.error?.code == 'TYPE_NOT_MUTABLE'
              ? state.error!.message
              : l.notifSettingsSaveFailed,
          tone: Tone.danger,
        ),
        builder: (ctx, state) {
          final s = state.settings;
          if (s == null) {
            return state.status == SettingsStatus.error
                ? ErrorView(
                    error: state.error!,
                    onRetry: ctx.read<NotificationSettingsCubit>().load,
                  )
                : const DetailPageSkeleton();
          }
          final cubit = ctx.read<NotificationSettingsCubit>();

          final muted = s.mutedTypes;
          final auto = s.autoTypes;
          Set<String> toggled(Set<String> set, String v, bool add) =>
              add ? {...set, v} : (set.toSet()..remove(v));

          /// One type, as rows: "receive" switch, plus — when it has an action
          /// — an indented "do it automatically" switch. Muted → the auto
          /// switch is disabled (and ignored by the server) but keeps its
          /// value for when the type is turned back on.
          List<Widget> typeRow(
            NotificationType t,
            String label, {
            String? autoLabel,
            Widget? extra,
          }) {
            final on = !s.isMuted(t);
            return [
              DetailRow(
                label: label,
                trailing: AppSwitch(
                  value: on,
                  onChanged: (v) =>
                      cubit.update(mutedTypes: toggled(muted, t.wire, !v)),
                ),
                onTap: () =>
                    cubit.update(mutedTypes: toggled(muted, t.wire, on)),
              ),
              if (autoLabel != null)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.xl),
                  child: DetailRow(
                    label: autoLabel,
                    trailing: AppSwitch(
                      value: s.isAuto(t),
                      onChanged: on
                          ? (v) => cubit.update(
                              autoTypes: toggled(auto, t.wire, v),
                            )
                          : null,
                    ),
                    onTap: on
                        ? () => cubit.update(
                            autoTypes: toggled(auto, t.wire, !s.isAuto(t)),
                          )
                        : null,
                  ),
                ),
              ?extra,
            ];
          }

          // The cache only feeds the picker; the row's name comes from the
          // settings reply (`default_account`).
          final accounts = ctx.watch<AccountsCubit>().state.accounts;
          final receiving = s.defaultAccount;
          final selectedAccount = accounts
              .where((a) => a.id == receiving?.id)
              .firstOrNull;
          final paidAuto =
              !s.isMuted(NotificationType.splitPaid) &&
              s.isAuto(NotificationType.splitPaid);

          return DetailPageBody(
            onRefresh: ctx.read<NotificationSettingsCubit>().load,
            // Clear the floating top bar and nav.
            topInset: MediaQuery.paddingOf(ctx).top + AppSpacing.lg,
            bottomInset: AppSpacing.huge + MediaQuery.paddingOf(ctx).bottom,
            hero: SectionCard(
              first: true,
              title: l.notifSettingsReceive,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                  child: AppText(
                    l.notifSettingsAutoHint,
                    role: AppTextRole.caption,
                  ),
                ),
              ],
            ),
            sections: [
              (first) => SectionCard(
                first: first,
                title: l.notifGroupSplits,
                children: [
                  ...typeRow(
                    NotificationType.splitCreated,
                    l.notifTypeSplitCreated,
                    autoLabel: l.notifAutoAddDebt,
                  ),
                  // Off by default: auto = my debt follows each change.
                  ...typeRow(
                    NotificationType.splitChanged,
                    l.notifTypeSplitChanged,
                    autoLabel: l.notifAutoApplySplitChange,
                  ),
                  ...typeRow(
                    NotificationType.splitPaid,
                    l.notifTypeSplitPaid,
                    autoLabel: l.notifAutoRecordPayment,
                    extra: LockedInEdit(
                      // The wallet only matters while auto-record is on.
                      locked: !paidAuto,
                      child: DetailRow(
                        leading: const AppIcon(AppIcons.bank),
                        label: l.notifDefaultAccount,
                        trailing: Text(
                          receiving?.name ?? l.notifDefaultAccountNone,
                        ),
                        showChevron: true,
                        onTap: () async {
                          final r = await showAccountPickerSheet(
                            context: ctx,
                            accounts: accounts,
                            selected: selectedAccount,
                            title: l.notifDefaultAccount,
                            // "None" = record it without a wallet.
                            allowNone: true,
                          );
                          if (r is AccountPickerSelected) {
                            cubit.update(
                              defaultAccount: DefaultAccountRef(
                                id: r.account.id,
                                name: r.account.name,
                                iconCode: r.account.iconCode,
                              ),
                            );
                          } else if (r is AccountPickerCleared) {
                            cubit.update(clearDefaultAccount: true);
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
              (first) => SectionCard(
                first: first,
                title: l.notifGroupProjects,
                children: [
                  ...typeRow(
                    NotificationType.projectTxRecordedForYou,
                    l.notifTypeProjectTxForYou,
                    autoLabel: l.notifAutoCopyToBook,
                  ),
                  ...typeRow(
                    NotificationType.projectTxChanged,
                    l.notifTypeProjectTxChanged,
                    autoLabel: l.notifAutoUpdateCopy,
                  ),
                  ...typeRow(
                    NotificationType.projectAdded,
                    l.notifTypeProjectAdded,
                  ),
                  // Not a notification — I recorded it myself. Lives with
                  // the project types rather than a second "โปรเจกต์"
                  // section.
                  DetailRow(
                    label: l.notifAutoResolveProject,
                    trailing: AppSwitch(
                      value: s.autoResolveOwnInProjects,
                      onChanged: (v) =>
                          cubit.update(autoResolveOwnInProjects: v),
                    ),
                    onTap: () => cubit.update(
                      autoResolveOwnInProjects: !s.autoResolveOwnInProjects,
                    ),
                  ),
                ],
              ),
              (first) => SectionCard(
                first: first,
                title: l.notifGroupRequests,
                children: [
                  DetailRow(
                    label: l.notifGroupRequests,
                    trailing: AppChip(
                      label: l.notifTypeAlwaysOn,
                      icon: AppIcons.lock,
                      tone: AppChipTone.neutral,
                      selected: true,
                      size: ChipSize.chip,
                    ),
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
