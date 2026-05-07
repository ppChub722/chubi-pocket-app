import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/network/api_exception.dart';
import '../../../contacts/data/contacts_repository.dart';
import '../../../contacts/domain/contact.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification.dart';
import '../cubit/notifications_inbox_cubit.dart';
import '../cubit/unread_badge_cubit.dart';
import '../widgets/notification_tile.dart';

/// `/notifications` — inbox page.
///
/// Two tabs: All / Unread. Tap routes by type + state:
///
/// - `contact_link_request` **pending** → tile renders inline Accept /
///   Reject buttons. Accept → link sender's side + mark actioned (row
///   stays). Reject → mark dismissed (row hidden). Row-body tap is a
///   no-op so accidental taps don't accept.
/// - `contact_link_request` **actioned** (= accepted) → 3-way tap
///   branch: linked match → /contacts/{id} | email match → edit
///   (link-existing) | no match → /contacts/new (link-create).
/// - Other types → mark read + follow [AppNotification.deepLink].
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
          // Hide-forever rule applies only to **dismissed** rows.
          // Actioned link-request rows stay so B can re-tap to navigate
          // to the linked contact / link-existing edit / link-create.
          final visible = state.notifications
              .where((n) => n.dismissedAt == null)
              .toList();
          if (visible.isEmpty) {
            return const Center(child: Text('No notifications'));
          }
          return RefreshIndicator(
            onRefresh: () => ctx
                .read<NotificationsInboxCubit>()
                .load(unreadOnly: state.filterUnreadOnly),
            child: NotificationListenerWidget(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: visible.length + (state.hasMore ? 1 : 0),
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, i) {
                  if (i >= visible.length) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final n = visible[i];
                  return NotificationTile(
                    notification: n,
                    onMarkRead: (id) =>
                        ctx.read<NotificationsInboxCubit>().markRead(id),
                    onDismiss: (id) =>
                        ctx.read<NotificationsInboxCubit>().markDismissed(id),
                    onTap: (notif) => _onTap(ctx, notif),
                    onAccept: (id) => _onAcceptLinkRequest(ctx, id),
                    onReject: (id) => _onRejectLinkRequest(ctx, id),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Tap routing ────────────────────────────────────────────────────

  Future<void> _onTap(BuildContext ctx, AppNotification n) async {
    if (n.type == NotificationType.contactLinkRequest) {
      if (n.actionedAt == null) {
        // Pending row body tap is a no-op — Accept / Reject live as
        // explicit inline buttons on the tile, so accidental row taps
        // don't accept the link unintentionally.
        return;
      }
      await _onTapActionedLinkRequest(ctx, n);
      return;
    }
    // Default: informational types — mark read + follow deep link.
    if (n.isUnread) {
      ctx.read<NotificationsInboxCubit>().markRead(n.id);
    }
    final link = n.deepLink;
    if (link != null && link.isNotEmpty) {
      ctx.push(link);
    }
  }

  /// Inline-button handler. Hits the BE's `accept` endpoint (links
  /// sender's side + marks the recipient's notification actioned). The
  /// row stays in the inbox post-action so the user can re-tap to reach
  /// the post-accept contact-flow (linked-detail / link-existing /
  /// link-create).
  Future<void> _onAcceptLinkRequest(BuildContext ctx, String id) async {
    final repo = ctx.read<ContactsRepository>();
    final inboxCubit = ctx.read<NotificationsInboxCubit>();
    final messenger = ScaffoldMessenger.of(ctx);
    try {
      await repo.acceptLinkRequest(id);
      await inboxCubit.load(unreadOnly: inboxCubit.state.filterUnreadOnly);
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Inline-button handler. Hits `reject` (marks dismissed; row
  /// vanishes from the inbox thanks to the dismissed-at filter above).
  /// Silent on the sender's side — A doesn't learn that B rejected.
  Future<void> _onRejectLinkRequest(BuildContext ctx, String id) async {
    final repo = ctx.read<ContactsRepository>();
    final inboxCubit = ctx.read<NotificationsInboxCubit>();
    final messenger = ScaffoldMessenger.of(ctx);
    try {
      await repo.rejectLinkRequest(id);
      await inboxCubit.load(unreadOnly: inboxCubit.state.filterUnreadOnly);
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  /// Actioned (= accepted) link-request → 3-way navigation:
  ///   1. linked contact already exists → /contacts/{id}
  ///   2. unlinked email-match exists → /contacts/{id}/edit (link-pending)
  ///   3. otherwise → /contacts/new (link-create) with locked prefill
  Future<void> _onTapActionedLinkRequest(
      BuildContext ctx, AppNotification n) async {
    final senderUserId = _senderUserIdOf(n);
    if (senderUserId == null) return;

    final contactsCubit = ctx.read<ContactsCubit>();
    final repo = ctx.read<ContactsRepository>();
    final messenger = ScaffoldMessenger.of(ctx);
    final router = GoRouter.of(ctx);

    // 1. Linked-contact match — navigate.
    final linked = _firstWhere(
      contactsCubit.state.contacts,
      (c) => c.linkedUserId == senderUserId,
    );
    if (linked != null) {
      router.push('/contacts/${linked.id}');
      return;
    }

    // Fetch sender profile (for email comparison + create-form prefill).
    String senderName = '';
    String? senderEmail;
    try {
      final profile = await repo.senderProfile(n.id);
      senderName = profile.displayName;
      senderEmail = profile.email;
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
      return;
    }

    // 2. Email-match (unlinked) — open the existing contact in
    //    link-existing mode (display fields locked, save links it).
    Contact? emailMatch;
    if (senderEmail != null && senderEmail.isNotEmpty) {
      final lower = senderEmail.toLowerCase();
      emailMatch = _firstWhere(
        contactsCubit.state.contacts,
        (c) =>
            c.email != null &&
            c.email!.toLowerCase() == lower &&
            c.linkedUserId == null,
      );
    }
    if (!ctx.mounted) return;
    if (emailMatch != null) {
      router.push('/contacts/${emailMatch.id}/edit', extra: <String, String?>{
        'linkRequestId': n.id,
      });
      return;
    }

    // 3. No match — create form in link-create mode with locked prefill.
    router.push('/contacts/new', extra: <String, String?>{
      'linkRequestId': n.id,
      'lockedDisplayName': senderName,
      'lockedEmail': senderEmail,
    });
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  static String? _senderUserIdOf(AppNotification n) {
    final fromPayload = n.payload['sender_user_id'];
    if (fromPayload is String && fromPayload.isNotEmpty) return fromPayload;
    return n.actorUserId;
  }

  static T? _firstWhere<T>(Iterable<T> xs, bool Function(T) test) {
    for (final x in xs) {
      if (test(x)) return x;
    }
    return null;
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
