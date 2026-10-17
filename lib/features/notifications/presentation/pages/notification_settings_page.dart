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

/// `/notifications/settings` (§7, contract §5): per type one 3-state control
/// ปิด / แจ้ง / อัตโนมัติ (2-state where nothing can be automated). Auto runs
/// the type's action on arrival; the wallet it records into shows inline under
/// the type that is on auto. Invites / requests are always on. A change saves
/// at once (one call) and flips back on failure.
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
          // A type that can't be muted says so; the control is already back.
          state.error?.code == 'TYPE_NOT_MUTABLE'
              ? state.error!.message
              : l.notifSettingsSaveFailed,
          tone: Tone.danger,
        ),
        builder: (ctx, state) {
          final s = state.settings;
          if (s == null) {
            // The template's first load: skeleton → error + retry (pull,
            // offline and slow loads included).
            final failed = state.status == SettingsStatus.error;
            return AsyncStateView.fallback(
              loading: !failed,
              error: failed ? state.error : null,
              onRetry: ctx.read<NotificationSettingsCubit>().load,
              notFound: const SizedBox.shrink(),
            );
          }
          final cubit = ctx.read<NotificationSettingsCubit>();

          /// One type: its label (+ what "auto" does) and the control, plus —
          /// only while it is on auto and records into a wallet — the wallet
          /// row inline.
          List<Widget> typeRow(
            NotificationType t,
            String label, {
            String? helper,
            bool canAuto = false,
            Widget? walletRow,
          }) {
            final mode = s.modeOf(t);
            return [
              DetailRow(label: label, helper: helper),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  0,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SegmentedChoice<NotifyMode>(
                    key: ValueKey('mode-${t.wire}'),
                    selected: mode,
                    onChanged: (m) => cubit.setMode(t, m),
                    segments: [
                      ChoiceSegment(NotifyMode.off, l.notifStateOff),
                      ChoiceSegment(NotifyMode.notify, l.notifStateNotify),
                      if (canAuto)
                        ChoiceSegment(NotifyMode.auto, l.notifStateAuto),
                    ],
                  ),
                ),
              ),
              if (mode == NotifyMode.auto && walletRow != null) walletRow,
            ];
          }

          // The cache only feeds the picker; the row's name comes from the
          // settings reply (`default_account`).
          final accounts = ctx.watch<AccountsCubit>().state.accounts;
          final receiving = s.defaultAccount;
          final selectedAccount = accounts
              .where((a) => a.id == receiving?.id)
              .firstOrNull;
          final walletRow = DetailRow(
            key: const ValueKey('auto-wallet'),
            leading: const AppIcon(AppIcons.bank),
            label: l.notifDefaultAccount,
            trailing: Text(receiving?.name ?? l.notifDefaultAccountNone),
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
          );

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
                    l.notifSettingsLegend,
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
                    helper: l.notifAutoAddDebt,
                    canAuto: true,
                  ),
                  // Off by default: auto = my debt follows each change.
                  ...typeRow(
                    NotificationType.splitChanged,
                    l.notifTypeSplitChanged,
                    helper: l.notifAutoApplySplitChange,
                    canAuto: true,
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
                    helper: l.notifAutoCopyToBook,
                    canAuto: true,
                    walletRow: walletRow,
                  ),
                  ...typeRow(
                    NotificationType.projectTxChanged,
                    l.notifTypeProjectTxChanged,
                    helper: l.notifAutoUpdateCopy,
                    canAuto: true,
                  ),
                  ...typeRow(
                    NotificationType.projectAdded,
                    l.notifTypeProjectAdded,
                  ),
                ],
              ),
              (first) => SectionCard(
                first: first,
                title: l.notifGroupRecurring,
                children: [
                  ...typeRow(
                    NotificationType.recurringDue,
                    l.notifTypeRecurringDue,
                    helper: l.notifTypeRecurringDueHint,
                  ),
                  ...typeRow(
                    NotificationType.recurringEnding,
                    l.notifTypeRecurringEnding,
                    helper: l.notifTypeRecurringEndingHint,
                  ),
                ],
              ),
              (first) => SectionCard(
                first: first,
                title: l.notifGroupRequests,
                children: [
                  DetailRow(
                    label: l.notifGroupRequests,
                    helper: l.notifTypeRequestsHint,
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
