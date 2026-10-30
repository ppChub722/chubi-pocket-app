import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../settings/presentation/pages/settings_money_page.dart'
    show signedInUser;
import '../../../users/data/users_repository.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification.dart';
import '../../domain/notification_rows.dart';
import '../cubit/notification_settings_cubit.dart';

/// Settings › การแจ้งเตือน (0.4.1-2; owner 2026-10-28): per type a [แจ้ง]
/// switch. A notice that asks something (a new / edited / deleted shared bill)
/// is ONE row in "บิลที่แชร์" with its auto switches beside it, one per bill
/// kind: อีเวนต์ | แบ่งจ่าย (the account's auto-accept / auto-update switches,
/// the same values the event and person pages show). Each request has its own
/// auto-accept switch. แจ้ง and อัตโนมัติ are independent (F1).
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

/// A row's label and helper; null = a type this build doesn't know (left
/// out).
({String label, String? helper})? _rowText(
  AppLocalizations l,
  NotificationRow r,
) => switch ((r.kind, r.group)) {
  (NotificationRowKind.billCreated, _) => (
    label: l.notifSetBillCreated,
    helper: l.notifAutoAcceptHint,
  ),
  (NotificationRowKind.billEdited, _) => (
    label: l.notifSetSplitChanged,
    helper: l.notifAutoUpdateHint,
  ),
  (NotificationRowKind.billDeleted, _) => (
    label: l.notifSetSharedBillDeleted,
    helper: l.notifAutoDeleteHint,
  ),
  _ => _typeText(l, r.type),
};

({String label, String? helper})? _typeText(AppLocalizations l, String type) =>
    switch (type) {
      'shared_bill_disconnected' => (
        label: l.notifSetSharedBillDisconnected,
        helper: l.notifSetSharedBillDisconnectedHint,
      ),
      'debt_disconnected' => (
        label: l.notifTypeDebtDisconnected,
        helper: l.notifSetDebtDisconnectedHint,
      ),
      'project_invite' => (
        label: l.notifSetEventInvite,
        helper: l.notifSetEventInviteHint,
      ),
      'contact_link_request' => (
        label: l.notifSetContactLink,
        helper: l.notifSetContactLinkHint,
      ),
      'account_invite' => (
        label: l.notifSetWalletInvite,
        helper: l.notifSetWalletInviteHint,
      ),
      'event_completed' => (
        label: l.notifSetEventCompleted,
        helper: l.notifSetEventCompletedHint,
      ),
      'event_member_removed' => (
        label: l.notifSetEventMemberRemoved,
        helper: l.notifSetEventMemberRemovedHint,
      ),
      'recurring_due' => (
        label: l.notifTypeRecurringDue,
        helper: l.notifSetRecurringDueHint,
      ),
      'recurring_ending' => (
        label: l.notifTypeRecurringEnding,
        helper: l.notifSetRecurringEndingHint,
      ),
      'recurring_auto_created' => (
        label: l.notifTypeRecurringAutoCreated,
        helper: l.notifSetRecurringAutoCreatedHint,
      ),
      _ => null,
    };

String _groupTitle(AppLocalizations l, NotificationGroup g) => switch (g) {
  NotificationGroup.sharedBill => l.notifGroupSharedBills,
  NotificationGroup.event => l.notifGroupProjects,
  NotificationGroup.recurring => l.notifGroupRecurring,
  NotificationGroup.request => l.notifGroupRequests,
};

AutoValues _autoOf(User u) => AutoValues(
  acceptDebts: u.autoAcceptDebts,
  acceptEvents: u.autoAcceptEvents,
  syncDebts: u.autoSyncDebts,
  syncEvents: u.autoSyncEvents,
  acceptEventInvites: u.autoAcceptEventInvites,
  acceptContactLinks: u.autoAcceptContactLinks,
  acceptWalletInvites: u.autoAcceptWalletInvites,
);

/// One `PUT /users/me` for an auto switch.
Future<User> _saveAuto(UsersRepository users, AutoSwitch s, bool on) =>
    switch (s) {
      AutoSwitch.acceptDebts => users.setAutoAccept(debts: on),
      AutoSwitch.acceptEvents => users.setAutoAccept(events: on),
      AutoSwitch.syncDebts => users.setAutoSync(debts: on),
      AutoSwitch.syncEvents => users.setAutoSync(events: on),
      AutoSwitch.acceptEventInvites => users.setAutoAcceptRequests(
        eventInvites: on,
      ),
      AutoSwitch.acceptContactLinks => users.setAutoAcceptRequests(
        contactLinks: on,
      ),
      AutoSwitch.acceptWalletInvites => users.setAutoAcceptRequests(
        walletInvites: on,
      ),
    };

class _Body extends StatelessWidget {
  const _Body();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.settingsNotifications, showBack: true),
      extendBodyBehindAppBar: true,
      body: BlocConsumer<NotificationSettingsCubit, SettingsState>(
        listenWhen: (a, b) =>
            a.error != b.error && b.error != null && b.settings != null,
        // Never the raw error: the switch is already back.
        listener: (ctx, state) =>
            showAppSnackBar(ctx, l.notifSettingsSaveFailed, tone: Tone.danger),
        builder: (ctx, state) {
          final s = state.settings;
          final user = signedInUser(ctx.watch<AuthCubit>().state);
          if (s == null || user == null) {
            final failed = state.status == SettingsStatus.error;
            return AsyncStateView.fallback(
              loading: !failed,
              error: failed ? state.error : null,
              onRetry: ctx.read<NotificationSettingsCubit>().load,
              notFound: const SizedBox.shrink(),
            );
          }
          final cubit = ctx.read<NotificationSettingsCubit>();
          final saved = _autoOf(user);
          final groups = notificationRows(s);
          // A card's auto column labels: "บิลที่แชร์" has อีเวนต์ | แบ่งจ่าย
          // ([autoColumns] order), the requests card one อัตโนมัติ.
          List<String> autoLabelsOf(NotificationGroup g) =>
              g == NotificationGroup.request
              ? [l.notifColumnAuto]
              : [l.notifColumnAutoEvents, l.notifColumnAutoSplit];

          Widget row(NotificationRow r, ({String label, String? helper}) t) {
            final autoLabels = autoLabelsOf(r.group);
            Widget build(AutoValues a, Map<AutoSwitch, ValueChanged<bool>> on) {
              return SettingSwitchColumnsRow(
                key: ValueKey('notif-${r.key}'),
                label: t.label,
                helper: t.helper,
                cells: [
                  SettingSwitchCell(
                    value: r.notifyOn(s),
                    onChanged: r.mutable ? (v) => cubit.setOn(r.type, v) : null,
                    semanticLabel: '${l.notifColumnNotify} ${t.label}',
                  ),
                  for (final (i, auto) in r.autos.indexed)
                    // A mirrored auto (a delete follows the edit row) can't be
                    // flipped here: its cell stays blank.
                    if (auto != null && !r.autoMirror)
                      SettingSwitchCell(
                        value: a.of(auto),
                        onChanged: on[auto],
                        semanticLabel:
                            '${l.notifColumnAuto} ${autoLabels[i]} ${t.label}',
                      )
                    else
                      null,
                ],
              );
            }

            // Each auto switch saves at once; the แจ้ง lock follows the shown
            // values (back with the old one if a save fails). One LiveSetting
            // per switch, nested.
            final editable = r.autoMirror
                ? const <AutoSwitch>[]
                : [...r.shownAutos];
            Widget nest(
              int i,
              AutoValues a,
              Map<AutoSwitch, ValueChanged<bool>> on,
            ) {
              if (i == editable.length) return build(a, on);
              final auto = editable[i];
              return LiveSetting<bool>(
                key: ValueKey('auto-${r.key}-${auto.name}'),
                value: saved.of(auto),
                failedMessage: (_) => l.notifSettingsSaveFailed,
                save: (v) async {
                  final auth = ctx.read<AuthCubit>();
                  auth.updateUser(
                    await _saveAuto(ctx.read<UsersRepository>(), auto, v),
                  );
                  return true;
                },
                builder: (context, v, onChanged) => nest(
                  i + 1,
                  a.withSwitch(auto, v),
                  {...on, auto: ?onChanged},
                ),
              );
            }

            return nest(0, saved, const {});
          }

          return DetailPageBody(
            onRefresh: cubit.load,
            bottomInset: AppSpacing.huge + MediaQuery.paddingOf(ctx).bottom,
            sections: [
              for (final MapEntry(key: g, value: rows) in groups.entries)
                (first) {
                  final children = [
                    for (final r in rows)
                      if (_rowText(l, r) case final t?) row(r, t),
                  ];
                  if (children.isEmpty) return null;
                  final hasAuto = rows.any((r) => r.autos.isNotEmpty);
                  return SectionCard(
                    first: first,
                    title: _groupTitle(l, g),
                    trailing: SettingColumnLabels(
                      labels: [
                        l.notifColumnNotify,
                        if (hasAuto) ...autoLabelsOf(g),
                      ],
                    ),
                    children: children,
                  );
                },
            ],
            // The legend sits under the groups, with the sync note.
            footnote:
                '${l.notifSettingsOnOffLegend}\n\n${l.settingsSyncFootnote}',
          );
        },
      ),
    );
  }
}
