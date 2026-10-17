import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification.dart';
import '../cubit/notifications_inbox_cubit.dart';
import '../cubit/unread_badge_cubit.dart';
import '../notification_actions.dart';
import '../widgets/notification_tile.dart';

/// `/notifications` — the inbox page.
///
/// A summary card on top ("ต้องตอบ n เรื่อง · ยังไม่อ่าน n") whose four tiles
/// ทั้งหมด / ต้องตอบ / ยังไม่อ่าน / ซ่อนไว้ are the filters (tap again to
/// clear); its action slot holds ✓✓ อ่านทั้งหมด and ⚙️ ตั้งค่า. Each filter is
/// ONE `GET /notifications`. Taps and the tiles' accept / reject buttons go
/// through [NotificationActions] (shared with the dashboard's "ต้องจัดการ").
/// Swipe left hides a row (undo in the snackbar); the ซ่อนไว้ tile lists the
/// hidden rows with กู้คืน.
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

  /// A tile tap: select it, or clear it back to ทั้งหมด (no call when the
  /// filter does not change).
  void _pick(InboxFilter f) {
    final cubit = context.read<NotificationsInboxCubit>();
    final next = cubit.state.filter == f ? InboxFilter.all : f;
    if (next == cubit.state.filter) return;
    cubit.load(filter: next);
  }

  Future<void> _hide(AppNotification n) async {
    final l = AppLocalizations.of(context)!;
    final cubit = context.read<NotificationsInboxCubit>();
    final messenger = ScaffoldMessenger.of(context);
    final ok = await cubit.hide(n.id);
    if (!ok) return;
    showAppSnackBarOn(
      messenger,
      l.notifHidden,
      actionLabel: l.notifUndo,
      onAction: () => cubit.restore(n.id),
    );
  }

  Widget _card(BuildContext ctx, AppLocalizations l, InboxState state) {
    final cubit = ctx.read<NotificationsInboxCubit>();
    final s = state.summary;
    SummaryTile tile(
      InboxFilter f,
      String label,
      String value, {
      SummaryTileTone tone = SummaryTileTone.neutral,
    }) => SummaryTile(
      label: label,
      value: value,
      tone: tone,
      selected: state.filter == f,
      onTap: () => _pick(f),
    );
    return ListSummaryCard(
      caption: l.notifCardCaption,
      showMoneyToggle: false,
      actions: [
        CardActionButton(
          icon: AppIcons.markAllRead,
          tooltip: l.notifReadAllTooltip,
          onTap: s.unread > 0 ? cubit.markReadAll : null,
        ),
        CardActionButton(
          icon: AppIcons.settings,
          tooltip: l.notifSettingsTooltip,
          onTap: () => openPage(ctx, '/notifications/settings'),
        ),
      ],
      main: AppText(l.notifCardMain(s.needsAnswer), role: AppTextRole.title),
      mainSuffix: l.notifCardUnread(s.unread),
      tiles: [
        tile(InboxFilter.all, l.notifTileAll, '${state.allTotal ?? '—'}'),
        tile(
          InboxFilter.needsAnswer,
          l.notifTileNeedsAnswer,
          '${s.needsAnswer}',
          tone: SummaryTileTone.amber,
        ),
        tile(InboxFilter.unread, l.notifTileUnread, '${s.unread}'),
        tile(InboxFilter.hidden, l.notifTileHidden, '${s.dismissed}'),
      ],
    );
  }

  EmptyView _empty(AppLocalizations l, InboxFilter f) => switch (f) {
    InboxFilter.needsAnswer => EmptyView(
      icon: AppIcons.notifications,
      title: l.notifEmptyNeedsAnswer,
      message: '',
    ),
    InboxFilter.unread => EmptyView(
      icon: AppIcons.notifications,
      title: l.notificationsEmptyUnread,
      message: '',
    ),
    InboxFilter.hidden => EmptyView(
      icon: AppIcons.hidden,
      title: l.notifEmptyHidden,
      message: '',
    ),
    InboxFilter.all => EmptyView(
      icon: AppIcons.notifications,
      title: l.notificationsEmptyTitle,
      message: l.notificationsEmptyMessage,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(title: l.notificationsTitle),
      extendBodyBehindAppBar: true,
      // ListPageBody clears the floating bar itself (the card starts below it).
      body: TabSwitchBody(
        child: BlocConsumer<NotificationsInboxCubit, InboxState>(
          listenWhen: (a, b) => a.error != b.error,
          listener: (ctx, state) {
            // A failed row action, or a failed reload with rows on screen
            // (a failed first load is the template's full-page error).
            if (state.error != null &&
                (state.status != InboxStatus.error ||
                    state.notifications.isNotEmpty)) {
              showAppSnackBar(ctx, state.errorMessage!, tone: Tone.danger);
            }
          },
          builder: (ctx, state) {
            final cubit = ctx.read<NotificationsInboxCubit>();
            final hiddenView = state.filter == InboxFilter.hidden;
            final visible = [
              for (final n in state.notifications)
                if (hiddenView
                    ? n.isDismissed
                    : (!n.isDismissed &&
                          (state.filter != InboxFilter.needsAnswer ||
                              n.awaitsAnswer)))
                  n,
            ];
            final rows = <Widget>[];
            String? lastDay;
            for (final n in visible) {
              final local = n.createdAt.toLocal();
              final day = '${local.year}-${local.month}-${local.day}';
              if (day != lastDay) {
                lastDay = day;
                rows.add(DateGroupHeader(label: _dayLabel(ctx, local)));
              }
              final tile = NotificationTile(
                notification: n,
                hidden: hiddenView,
                onTap: (notif) =>
                    hiddenView ? null : NotificationActions.tap(ctx, notif),
                onAccept: (_) => NotificationActions.accept(ctx, n),
                onReject: (_) => NotificationActions.reject(ctx, n),
              );
              rows.add(
                hiddenView
                    ? Column(
                        key: ValueKey('notif_${n.id}'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          tile,
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                right: AppSpacing.md,
                              ),
                              child: AppButton(
                                label: l.notifRestore,
                                icon: AppIcons.unarchive,
                                variant: AppButtonVariant.text,
                                submits: true,
                                onPressed: () => cubit.restore(n.id),
                              ),
                            ),
                          ),
                        ],
                      )
                    : Dismissible(
                        key: ValueKey('notif_${n.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: AppSpacing.xl),
                          color: Theme.of(
                            ctx,
                          ).colorScheme.surfaceContainerHighest,
                          child: const AppIcon(AppIcons.hidden),
                        ),
                        onDismissed: (_) => _hide(n),
                        child: tile,
                      ),
              );
            }
            return ListPageBody(
              // Rows on screen stay while it reloads or when a reload fails.
              loading:
                  (state.status == InboxStatus.initial ||
                      state.status == InboxStatus.loading) &&
                  state.notifications.isEmpty,
              error:
                  state.status == InboxStatus.error &&
                      state.notifications.isEmpty
                  ? state.error
                  : null,
              isEmpty: visible.isEmpty,
              onRetry: cubit.reload,
              empty: _empty(l, state.filter),
              header: [_card(ctx, l, state)],
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
