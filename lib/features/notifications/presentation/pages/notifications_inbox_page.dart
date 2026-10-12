import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../ui/ui.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../data/notifications_repository.dart';
import '../cubit/notifications_inbox_cubit.dart';
import '../cubit/unread_badge_cubit.dart';
import '../notification_actions.dart';
import '../widgets/notification_tile.dart';

/// `/notifications` — the inbox page.
///
/// Two tabs: All / Unread. Taps and the tiles' accept / reject / one-tap
/// buttons go through [NotificationActions] (shared with the dashboard's
/// "ต้องจัดการ"): a pending link request or wallet invite is answered by
/// its inline buttons only; other types mark read + follow their link.
///
/// The inbox client-side hides only **dismissed** notifications.
/// Actioned link-request rows stay so the post-accept tap-flow remains
/// reachable indefinitely.
class NotificationsInboxPage extends StatelessWidget {
  const NotificationsInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => NotificationsInboxCubit(
        repository: ctx.read<NotificationsRepository>(),
        // Loads and writes already return the count: patch the bell, no poll.
        onUnreadChanged: ctx.read<UnreadBadgeCubit>().setCount,
      )..load(),
      child: const _InboxScaffold(),
    );
  }
}

class _InboxScaffold extends StatefulWidget {
  const _InboxScaffold();

  @override
  State<_InboxScaffold> createState() => _InboxScaffoldState();
}

class _InboxScaffoldState extends State<_InboxScaffold> {
  bool _unreadOnly = false;

  void _setTab(bool unreadOnly) {
    if (unreadOnly == _unreadOnly) return;
    setState(() => _unreadOnly = unreadOnly);
    context.read<NotificationsInboxCubit>().load(unreadOnly: unreadOnly);
  }

  /// The cubit has no in-flight flag: one next-page call at a time, here.
  bool _loadingMore = false;

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    _loadingMore = true;
    // Fired from a scroll notification, possibly mid-layout: repaint after it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() {});
    });
    await context.read<NotificationsInboxCubit>().loadMore();
    if (mounted) setState(() => _loadingMore = false);
  }

  String _dayLabel(BuildContext context, DateTime d) {
    final l = AppLocalizations.of(context)!;
    return DateFormatter.friendly(
      d,
      today: l.commonToday,
      yesterday: l.commonYesterday,
      locale: Localizations.localeOf(context).languageCode,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    void openSettings() => context.push('/notifications/settings');
    return Scaffold(
      appBar: AppTopBar(title: l.notificationsTitle),
      extendBodyBehindAppBar: true,
      // ListPageBody clears the floating bar itself (tabs start below it).
      body: TabSwitchBody(
        child: BlocConsumer<NotificationsInboxCubit, InboxState>(
          listenWhen: (a, b) => a.error != b.error,
          listener: (ctx, state) {
            // Row actions (accept / mark read …) fail without leaving
            // `loaded`; load failures are the template's.
            if (state.error != null && state.status != InboxStatus.error) {
              showAppSnackBar(ctx, state.errorMessage!, tone: Tone.danger);
            }
          },
          builder: (ctx, state) {
            final cubit = ctx.read<NotificationsInboxCubit>();
            // Dismissed rows are hidden for good; actioned requests
            // stay so the post-accept flow is still reachable.
            final visible = state.notifications
                .where((n) => !n.isDismissed)
                .toList();
            final rows = <Widget>[
              // Head of the list: only while something is unread.
              if (state.unreadCount > 0)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.sm,
                    ),
                    child: AppButton(
                      label: l.notificationsMarkAllRead,
                      icon: AppIcons.markAllRead,
                      variant: AppButtonVariant.text,
                      submits: true,
                      onPressed: cubit.markReadAll,
                    ),
                  ),
                ),
            ];
            String? lastDay;
            for (final n in visible) {
              final local = n.createdAt.toLocal();
              final day = '${local.year}-${local.month}-${local.day}';
              if (day != lastDay) {
                lastDay = day;
                rows.add(DateGroupHeader(label: _dayLabel(ctx, local)));
              }
              rows.add(
                Dismissible(
                  key: ValueKey('notif_${n.id}'),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: AppSpacing.xl),
                    color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                    child: const AppIcon(AppIcons.hidden),
                  ),
                  onDismissed: (_) {
                    cubit.markDismissed(n.id);
                    showAppSnackBar(ctx, l.notifHidden);
                  },
                  child: NotificationTile(
                    notification: n,
                    onTap: (notif) => NotificationActions.tap(ctx, notif),
                    onAccept: (_) => NotificationActions.accept(ctx, n),
                    onReject: (_) => NotificationActions.reject(ctx, n),
                  ),
                ),
              );
            }
            // Notification settings close the list.
            rows.add(
              DetailRow(
                leading: const AppIcon(AppIcons.settings),
                label: l.notifSettingsTitle,
                showChevron: true,
                onTap: openSettings,
              ),
            );
            return ListPageBody(
              loading:
                  state.status == InboxStatus.initial ||
                  state.status == InboxStatus.loading,
              error: state.status == InboxStatus.error ? state.error : null,
              isEmpty: visible.isEmpty,
              onRetry: () => cubit.load(unreadOnly: _unreadOnly),
              empty: EmptyView(
                icon: AppIcons.notifications,
                title: _unreadOnly
                    ? l.notificationsEmptyUnread
                    : l.notificationsEmptyTitle,
                message: _unreadOnly ? '' : l.notificationsEmptyMessage,
                // Settings stay reachable with an empty inbox.
                cta: AppButton(
                  label: l.notifSettingsTitle,
                  icon: AppIcons.settings,
                  variant: AppButtonVariant.text,
                  onPressed: openSettings,
                ),
              ),
              header: [
                AppTabBar<bool>(
                  selected: _unreadOnly,
                  onChanged: _setTab,
                  tabs: [
                    AppTab(value: false, label: l.notificationsTabAll),
                    AppTab(value: true, label: l.notificationsTabUnread),
                  ],
                ),
              ],
              // Rows run edge to edge.
              topInset: 0,
              sidePadding: 0,
              bottomInset: AppSpacing.huge,
              rowDividers: true,
              // Text starts past the 40 px avatar: 16 + 40 + 12.
              rowDividerIndent: 68,
              hasMore: state.hasMore,
              loadingMore: _loadingMore,
              onLoadMore: _loadMore,
              children: rows,
            );
          },
        ),
      ),
    );
  }
}
