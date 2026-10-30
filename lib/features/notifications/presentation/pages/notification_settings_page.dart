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

/// Settings › การแจ้งเตือน (0.4.1-2; owner 2026-10-28 layout ก): per type a
/// [แจ้ง] switch, and for a notice that asks something an [อัตโนมัติ] switch
/// beside it (the account's auto-accept / auto-update switches, the same
/// values the event and person pages show). Auto off locks แจ้ง on: someone
/// must answer. Grouped as the BE lists the types.
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
  (NotificationRowKind.billCreated, NotificationGroup.event) => (
    label: l.notifTypeProjectTxForYou,
    helper: l.notifAutoAcceptHint,
  ),
  (NotificationRowKind.billCreated, _) => (
    label: l.notifTypeSplitCreated,
    helper: l.notifAutoAcceptHint,
  ),
  (NotificationRowKind.billEdited, NotificationGroup.event) => (
    label: l.notifTypeProjectTxChanged,
    helper: l.notifAutoUpdateHint,
  ),
  (NotificationRowKind.billEdited, _) => (
    label: l.notifSetSplitChanged,
    helper: l.notifAutoUpdateHint,
  ),
  (NotificationRowKind.billDeleted, _) => (
    label: l.notifSetSharedBillDeleted,
    helper: l.notifAutoDeleteHint,
  ),
  _ when r.group == NotificationGroup.request => (
    label: l.notifSetRequests,
    helper: l.notifTypeRequestsHint,
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
      'project_added' => (
        label: l.notifTypeProjectAdded,
        helper: l.notifSetProjectAddedHint,
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
);

/// [values] with [s] set to [on].
AutoValues _with(AutoValues v, AutoSwitch s, bool on) => AutoValues(
  acceptDebts: s == AutoSwitch.acceptDebts ? on : v.acceptDebts,
  acceptEvents: s == AutoSwitch.acceptEvents ? on : v.acceptEvents,
  syncDebts: s == AutoSwitch.syncDebts ? on : v.syncDebts,
  syncEvents: s == AutoSwitch.syncEvents ? on : v.syncEvents,
);

/// One `PUT /users/me` for an auto switch.
Future<User> _saveAuto(UsersRepository users, AutoSwitch s, bool on) =>
    switch (s) {
      AutoSwitch.acceptDebts => users.setAutoAccept(debts: on),
      AutoSwitch.acceptEvents => users.setAutoAccept(events: on),
      AutoSwitch.syncDebts => users.setAutoSync(debts: on),
      AutoSwitch.syncEvents => users.setAutoSync(events: on),
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
          final columns = [l.notifColumnNotify, l.notifColumnAuto];

          Widget row(NotificationRow r, ({String label, String? helper}) t) {
            Widget build(AutoValues a, ValueChanged<bool>? onAuto) {
              final locked = r.notifyLocked(a);
              final helper = [
                ?t.helper,
                if (locked && r.mutable) l.notifLockedByAutoHint,
              ].join('\n');
              return SettingSwitchColumnsRow(
                key: ValueKey('notif-${r.key}'),
                label: t.label,
                helper: helper.isEmpty ? null : helper,
                cells: [
                  SettingSwitchCell(
                    value: r.notifyOn(s, a),
                    onChanged: r.notifyEditable(a)
                        ? (on) => cubit.setOn(r.type, on)
                        : null,
                    semanticLabel: '${l.notifColumnNotify} ${t.label}',
                  ),
                  // A mirrored auto (a delete follows the edit row) can't be
                  // flipped here: its cell stays blank.
                  if (r.auto case final auto? when !r.autoMirror)
                    SettingSwitchCell(
                      value: a.of(auto),
                      onChanged: onAuto,
                      semanticLabel: '${l.notifColumnAuto} ${t.label}',
                    )
                  else
                    null,
                ],
              );
            }

            final auto = r.auto;
            if (auto == null || r.autoMirror) return build(saved, null);
            // The auto switch saves at once; the แจ้ง lock follows the shown
            // value (back with the old one if the save fails).
            return LiveSetting<bool>(
              key: ValueKey('auto-${r.key}'),
              value: saved.of(auto),
              failedMessage: (_) => l.notifSettingsSaveFailed,
              save: (on) async {
                final auth = ctx.read<AuthCubit>();
                auth.updateUser(
                  await _saveAuto(ctx.read<UsersRepository>(), auto, on),
                );
                return true;
              },
              builder: (context, on, onChanged) =>
                  build(_with(saved, auto, on), onChanged),
            );
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
                  final hasAuto = rows.any((r) => r.auto != null);
                  return SectionCard(
                    first: first,
                    title: _groupTitle(l, g),
                    trailing: SettingColumnLabels(
                      labels: [columns[0], hasAuto ? columns[1] : ''],
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
