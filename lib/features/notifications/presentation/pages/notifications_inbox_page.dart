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

class NotificationsInboxPage extends StatelessWidget {
  const NotificationsInboxPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => NotificationsInboxCubit(
        repository: ctx.read<NotificationsRepository>(),
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
  bool _loadingMore = false;

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    _loadingMore = true;
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

  void _pick(InboxFilter f) {
    context.read<NotificationsInboxCubit>().pick(f);
  }

  String _filterLabel(AppLocalizations l, InboxFilter f) => switch (f) {
    InboxFilter.all => l.notifTileAll,
    InboxFilter.needsAnswer => l.notifTileNeedsAnswer,
    InboxFilter.unread => l.notifTileUnread,
    InboxFilter.hidden => l.notifTileHidden,
  };

  int _filterCount(InboxSummary s, InboxFilter f) => switch (f) {
    InboxFilter.all => s.all,
    InboxFilter.needsAnswer => s.needsAnswer,
    InboxFilter.unread => s.unread,
    InboxFilter.hidden => s.dismissed,
  };

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

  Widget _topRow(BuildContext ctx, AppLocalizations l, InboxState state) {
    final cubit = ctx.read<NotificationsInboxCubit>();
    final s = state.summary;
    String label(InboxFilter f) =>
        '${_filterLabel(l, f)} | ${_filterCount(s, f)}';
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          OptionMenuAnchor<InboxFilter>(
            selected: state.filter,
            options: [
              for (final f in InboxFilter.values)
                SheetOption(value: f, label: label(f)),
            ],
            onSelected: _pick,
            builder: (context, toggle) => AppChip(
              label: label(state.filter),
              selected: state.filter != InboxFilter.all,
              trailing: AppChipTrailing.dropdown,
              onTap: toggle,
            ),
          ),
          const Spacer(),
          CardActionButton(
            icon: AppIcons.markAllRead,
            tooltip: l.notifReadAllTooltip,
            onTap: s.unread > 0 ? cubit.markReadAll : null,
          ),
          const SizedBox(width: AppSpacing.sm),
          CardActionButton(
            icon: AppIcons.settings,
            tooltip: l.notifSettingsTooltip,
            onTap: () => openPage(ctx, '/notifications/settings'),
          ),
        ],
      ),
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
      body: TabSwitchBody(
        child: BlocConsumer<NotificationsInboxCubit, InboxState>(
          listenWhen: (a, b) => a.error != b.error,
          listener: (ctx, state) {
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
                if (hiddenView ? n.isDismissed : !n.isDismissed) n,
            ];
            final rows = <Widget>[];
            String? lastDay;
            for (final n in visible) {
              final local = n.createdAt.toLocal();
              final day = '${local.year}-${local.month}-${local.day}';
              if (day != lastDay) {
                lastDay = day;
                rows.add(AppListHeader(title: _dayLabel(ctx, local)));
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
              header: [_topRow(ctx, l, state)],
              topInset: 0,
              sidePadding: 0,
              bottomInset: AppSpacing.huge,
              rowDividers: true,
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
