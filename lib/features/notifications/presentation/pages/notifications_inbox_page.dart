import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification.dart';
import '../cubit/notifications_inbox_cubit.dart';
import '../cubit/unread_badge_cubit.dart';
import '../widgets/notification_tile.dart';

/// `/notifications` — inbox page.
///
/// Two tabs: All / Unread. Mark-read / dismiss / delete actions live in
/// each row's overflow menu. Link-request notifications render Accept /
/// Reject buttons inline, which call into `contacts.acceptLinkRequest` /
/// `projects.acceptLinkRequest` via repos kept in this page (no cross-
/// feature cubit subscription needed).
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

class _InboxScaffoldState extends State<_InboxScaffold>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this)
      ..addListener(_onTabChange);
  }

  void _onTabChange() {
    if (!_tabs.indexIsChanging) return;
    final unreadOnly = _tabs.index == 1;
    context.read<NotificationsInboxCubit>().load(unreadOnly: unreadOnly);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        bottom: TabBar(
          controller: _tabs,
          tabs: const [Tab(text: 'All'), Tab(text: 'Unread')],
        ),
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            icon: const Icon(Icons.done_all),
            onPressed: () =>
                context.read<NotificationsInboxCubit>().markReadAll(),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/notifications/settings'),
          ),
        ],
      ),
      body: BlocConsumer<NotificationsInboxCubit, InboxState>(
        listenWhen: (a, b) =>
            a.unreadCount != b.unreadCount ||
            a.errorMessage != b.errorMessage,
        listener: (ctx, state) {
          // Keep the bell badge in sync with the inbox view.
          ctx.read<UnreadBadgeCubit>().refresh();
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(ctx)
              ..hideCurrentSnackBar()
              ..showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        builder: (ctx, state) {
          if (state.status == InboxStatus.loading &&
              state.notifications.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.notifications.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return RefreshIndicator(
            onRefresh: () => ctx
                .read<NotificationsInboxCubit>()
                .load(unreadOnly: state.filterUnreadOnly),
            child: NotificationListenerWidget(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: state.notifications.length +
                    (state.hasMore ? 1 : 0),
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  if (i >= state.notifications.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final n = state.notifications[i];
                  return NotificationTile(
                    notification: n,
                    onMarkRead: (id) =>
                        ctx.read<NotificationsInboxCubit>().markRead(id),
                    onDismiss: (id) =>
                        ctx.read<NotificationsInboxCubit>().markDismissed(id),
                    onAccept: (id) => _accept(ctx, n),
                    onReject: (id) => _reject(ctx, n),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _accept(BuildContext ctx, AppNotification n) async {
    // Accept routes by type — contact and project both have their own
    // `/link-requests/:id/accept` endpoint owning different actions
    // (set linked_user_id vs set project_members.user_id). The inbox
    // dispatches via the shared ApiClient so it doesn't have to import
    // either feature's repos.
    final path = _acceptPath(n.type, n.id);
    if (path == null) {
      await ctx.read<NotificationsInboxCubit>().markActioned(n.id);
      return;
    }
    final api = ctx.read<ApiClient>();
    final cubit = ctx.read<NotificationsInboxCubit>();
    final unreadOnly = cubit.state.filterUnreadOnly;
    try {
      await api.dio.post<dynamic>(path);
      if (!ctx.mounted) return;
      await cubit.load(unreadOnly: unreadOnly);
    } on DioException catch (e) {
      if (!ctx.mounted) return;
      final msg = ApiException.fromDioException(e).message;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  Future<void> _reject(BuildContext ctx, AppNotification n) async {
    final path = _rejectPath(n.type, n.id);
    if (path == null) {
      await ctx.read<NotificationsInboxCubit>().markDismissed(n.id);
      return;
    }
    final api = ctx.read<ApiClient>();
    final cubit = ctx.read<NotificationsInboxCubit>();
    final unreadOnly = cubit.state.filterUnreadOnly;
    try {
      await api.dio.post<dynamic>(path);
      if (!ctx.mounted) return;
      await cubit.load(unreadOnly: unreadOnly);
    } on DioException catch (e) {
      if (!ctx.mounted) return;
      final msg = ApiException.fromDioException(e).message;
      ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  String? _acceptPath(NotificationType t, String notificationId) {
    switch (t) {
      case NotificationType.contactLinkRequest:
        return '/contacts/link-requests/$notificationId/accept';
      case NotificationType.projectInvite:
        return '/projects/link-requests/$notificationId/accept';
      default:
        return null;
    }
  }

  String? _rejectPath(NotificationType t, String notificationId) {
    switch (t) {
      case NotificationType.contactLinkRequest:
        return '/contacts/link-requests/$notificationId/reject';
      case NotificationType.projectInvite:
        return '/projects/link-requests/$notificationId/reject';
      default:
        return null;
    }
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
