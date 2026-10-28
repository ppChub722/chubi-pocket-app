import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification.dart';
import '../cubit/notification_settings_cubit.dart';

/// Settings › การแจ้งเตือน (0.4.1-2): on / off per type, grouped as the BE
/// lists them (`types`, page order). Auto sync is its own setting now, so a
/// muted type still syncs quietly.
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

/// A type's label and helper on this page; null = a type this build doesn't
/// know (left out).
({String label, String? helper})? notificationTypeText(
  AppLocalizations l,
  String type,
) => switch (type) {
  'split_created' || 'shared_bill_created' => (
    label: l.notifTypeSplitCreated,
    helper: l.notifSetSplitCreatedHint,
  ),
  'split_changed' => (
    label: l.notifSetSplitChanged,
    helper: l.notifSetSplitChangedHint,
  ),
  'shared_bill_deleted' => (
    label: l.notifSetSharedBillDeleted,
    helper: l.notifSetSharedBillDeletedHint,
  ),
  'shared_bill_disconnected' => (
    label: l.notifSetSharedBillDisconnected,
    helper: l.notifSetSharedBillDisconnectedHint,
  ),
  'debt_disconnected' => (
    label: l.notifTypeDebtDisconnected,
    helper: l.notifSetDebtDisconnectedHint,
  ),
  'project_tx_recorded_for_you' => (
    label: l.notifTypeProjectTxForYou,
    helper: l.notifSetProjectTxForYouHint,
  ),
  'project_tx_changed' => (
    label: l.notifTypeProjectTxChanged,
    helper: l.notifSetProjectTxChangedHint,
  ),
  'project_added' => (label: l.notifTypeProjectAdded, helper: null),
  'event_completed' => (
    label: l.notifSetEventCompleted,
    helper: l.notifSetEventCompletedHint,
  ),
  'event_member_removed' => (
    label: l.notifSetEventMemberRemoved,
    helper: l.notifSetEventMemberRemovedHint,
  ),
  'recurring_due' => (label: l.notifTypeRecurringDue, helper: null),
  'recurring_ending' => (label: l.notifTypeRecurringEnding, helper: null),
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
            final failed = state.status == SettingsStatus.error;
            return AsyncStateView.fallback(
              loading: !failed,
              error: failed ? state.error : null,
              onRetry: ctx.read<NotificationSettingsCubit>().load,
              notFound: const SizedBox.shrink(),
            );
          }
          final cubit = ctx.read<NotificationSettingsCubit>();

          Widget? groupCard(NotificationGroup g, bool first) {
            final rows = s.ofGroup(g);
            if (rows.isEmpty) return null;
            // Requests can't be muted: one row, always on.
            if (g == NotificationGroup.request) {
              return SectionCard(
                first: first,
                title: _groupTitle(l, g),
                children: [
                  DetailRow(
                    label: l.notifSetRequests,
                    helper: l.notifTypeRequestsHint,
                    trailing: AppChip(
                      label: l.notifTypeAlwaysOn,
                      tone: AppChipTone.neutral,
                      selected: true,
                      size: ChipSize.chip,
                    ),
                  ),
                ],
              );
            }
            final children = <Widget>[
              for (final t in rows)
                if (notificationTypeText(l, t.type) case final text?)
                  SettingToggleRow(
                    key: ValueKey('notif-${t.type}'),
                    label: text.label,
                    caption: text.helper,
                    value: t.on,
                    onChanged: t.mutable
                        ? (on) => cubit.setOn(t.type, on)
                        : null,
                  ),
            ];
            if (children.isEmpty) return null;
            return SectionCard(
              first: first,
              title: _groupTitle(l, g),
              children: children,
            );
          }

          return DetailPageBody(
            onRefresh: cubit.load,
            topInset: MediaQuery.paddingOf(ctx).top + AppSpacing.lg,
            bottomInset: AppSpacing.huge + MediaQuery.paddingOf(ctx).bottom,
            // The legend above the groups (a heading-less description).
            hero: SectionCard(
              first: true,
              description: l.notifSettingsOnOffLegend,
              children: const [],
            ),
            sections: [
              for (final g in NotificationGroup.values)
                if (s.ofGroup(g).isNotEmpty)
                  (first) => groupCard(g, first) ?? const SizedBox.shrink(),
            ],
          );
        },
      ),
    );
  }
}
