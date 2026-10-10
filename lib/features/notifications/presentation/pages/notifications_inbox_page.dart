import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/ui.dart';
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
      // Pinned tabs clear the floating bar; the list below them must not
      // add the bar height again.
      body: TabSwitchBody(
        child: Builder(
          builder: (context) => MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: Column(
              children: [
                SizedBox(height: MediaQuery.paddingOf(context).top),
                AppTabBar<bool>(
                  selected: _unreadOnly,
                  onChanged: _setTab,
                  tabs: [
                    AppTab(value: false, label: l.notificationsTabAll),
                    AppTab(value: true, label: l.notificationsTabUnread),
                  ],
                ),
                Expanded(
                  child: BlocConsumer<NotificationsInboxCubit, InboxState>(
                    listenWhen: (a, b) =>
                        a.unreadCount != b.unreadCount || a.error != b.error,
                    listener: (ctx, state) {
                      ctx.read<UnreadBadgeCubit>().refresh();
                      // Row actions (accept / mark read …) fail without leaving
                      // `loaded`; load failures are AsyncStateView's.
                      if (state.error != null &&
                          state.status != InboxStatus.error) {
                        showAppSnackBar(
                          ctx,
                          state.errorMessage!,
                          tone: Tone.danger,
                        );
                      }
                    },
                    builder: (ctx, state) {
                      // Dismissed rows are hidden for good; actioned requests
                      // stay so the post-accept flow is still reachable.
                      final visible = state.notifications
                          .where((n) => n.dismissedAt == null)
                          .toList();
                      return AsyncStateView(
                        loading:
                            state.status == InboxStatus.initial ||
                            state.status == InboxStatus.loading,
                        error: state.status == InboxStatus.error
                            ? state.error
                            : null,
                        isEmpty: visible.isEmpty,
                        onRetry: () => ctx.read<NotificationsInboxCubit>().load(
                          unreadOnly: _unreadOnly,
                        ),
                        empty: EmptyView(
                          icon: AppIcons.notifications,
                          title: _unreadOnly
                              ? l.notificationsEmptyUnread
                              : l.notificationsEmptyTitle,
                          message: _unreadOnly
                              ? ''
                              : l.notificationsEmptyMessage,
                          // Settings stay reachable with an empty inbox.
                          cta: TextButton.icon(
                            onPressed: openSettings,
                            icon: const Icon(AppIcons.settings, size: 18),
                            label: Text(l.notifSettingsTitle),
                          ),
                        ),
                        builder: (context) {
                          final rows = <Widget>[
                            // Head of the list: only while something is unread.
                            if (state.unreadCount > 0)
                              Align(
                                alignment: Alignment.centerRight,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.sm,
                                  ),
                                  child: TextButton.icon(
                                    onPressed: () => ctx
                                        .read<NotificationsInboxCubit>()
                                        .markReadAll(),
                                    icon: const Icon(
                                      AppIcons.markAllRead,
                                      size: 18,
                                    ),
                                    label: Text(l.notificationsMarkAllRead),
                                  ),
                                ),
                              ),
                          ];
                          String? lastDay;
                          for (final n in visible) {
                            final local = n.createdAt.toLocal();
                            final day =
                                '${local.year}-${local.month}-${local.day}';
                            if (day != lastDay) {
                              lastDay = day;
                              rows.add(
                                DateGroupHeader(label: _dayLabel(ctx, local)),
                              );
                            }
                            rows.add(
                              Dismissible(
                                key: ValueKey('notif_${n.id}'),
                                direction: DismissDirection.endToStart,
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(
                                    right: AppSpacing.xl,
                                  ),
                                  color: Theme.of(
                                    ctx,
                                  ).colorScheme.surfaceContainerHighest,
                                  child: const Icon(AppIcons.hidden),
                                ),
                                onDismissed: (_) {
                                  ctx
                                      .read<NotificationsInboxCubit>()
                                      .markDismissed(n.id);
                                  showAppSnackBar(ctx, l.notifHidden);
                                },
                                child: NotificationTile(
                                  notification: n,
                                  onTap: (notif) =>
                                      NotificationActions.tap(ctx, notif),
                                  onAccept: (_) =>
                                      NotificationActions.accept(ctx, n),
                                  onReject: (_) =>
                                      NotificationActions.reject(ctx, n),
                                ),
                              ),
                            );
                          }
                          if (state.hasMore) {
                            // Load-more placeholder: skeleton rows, no spinner.
                            rows.addAll(const [
                              SkeletonListTile(),
                              SkeletonListTile(),
                            ]);
                          }
                          // Notification settings close the list.
                          rows.add(
                            DetailRow(
                              leading: const Icon(AppIcons.settings),
                              label: l.notifSettingsTitle,
                              showChevron: true,
                              onTap: openSettings,
                            ),
                          );
                          return PullToRefresh(
                            onRefresh: () => ctx
                                .read<NotificationsInboxCubit>()
                                .load(unreadOnly: _unreadOnly),
                            child: NotificationListenerWidget(
                              child: ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: EdgeInsets.only(
                                  bottom:
                                      AppSpacing.huge +
                                      MediaQuery.paddingOf(ctx).bottom,
                                ),
                                children: rows,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny helper so the list can request loadMore() at scroll bottom.
class NotificationListenerWidget extends StatelessWidget {
  const NotificationListenerWidget({required this.child, super.key});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notif) {
        if (notif.metrics.pixels >= notif.metrics.maxScrollExtent - 64) {
          context.read<NotificationsInboxCubit>().loadMore();
        }
        return false;
      },
      child: child,
    );
  }
}
