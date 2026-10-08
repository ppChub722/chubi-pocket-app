import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/overlay_nav.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../accounts/data/accounts_repository.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../accounts/presentation/wallet_errors.dart';
import '../../../contacts/data/contacts_repository.dart';
import '../../../contacts/domain/contact.dart';
import '../../../contacts/presentation/cubit/contacts_cubit.dart';
import '../../../personal_debts/data/personal_debts_repository.dart';
import '../../../personal_debts/presentation/cubit/personal_debts_cubit.dart';
import '../../../personal_debts/presentation/widgets/debt_widgets.dart';
import '../../../projects/data/projects_repository.dart';
import '../../../transactions/presentation/cubit/transactions_cubit.dart';
import '../../data/notifications_repository.dart';
import '../../domain/notification.dart';
import '../cubit/notifications_inbox_cubit.dart';
import '../cubit/unread_badge_cubit.dart';
import '../widgets/notification_tile.dart';

/// `/notifications` — the inbox page.
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

class _InboxScaffoldState extends State<_InboxScaffold> {
  bool _unreadOnly = false;

  void _setTab(bool unreadOnly) {
    if (unreadOnly == _unreadOnly) return;
    setState(() => _unreadOnly = unreadOnly);
    context.read<NotificationsInboxCubit>().load(unreadOnly: unreadOnly);
  }

  String _dayLabel(BuildContext context, DateTime d) {
    final l = AppLocalizations.of(context)!;
    return DateFormatter.friendly(d,
        today: l.commonToday,
        yesterday: l.commonYesterday,
        locale: Localizations.localeOf(context).languageCode);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppTopBar(
        title: l.notificationsTitle,
        showBack: true,
        showUniversal: false,
        actions: [
          AppBarAction(
            icon: AppIcons.markAllRead,
            tooltip: l.notificationsMarkAllRead,
            onPressed: () =>
                context.read<NotificationsInboxCubit>().markReadAll(),
          ),
          AppBarAction(
            icon: AppIcons.settings,
            tooltip: l.notificationsSettingsTooltip,
            onPressed: () => context.push('/notifications/settings'),
          ),
        ],
      ),
      body: Column(
        children: [
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
                  a.unreadCount != b.unreadCount ||
                  a.errorMessage != b.errorMessage,
              listener: (ctx, state) {
                ctx.read<UnreadBadgeCubit>().refresh();
                if (state.errorMessage != null) {
                  showAppSnackBar(ctx, state.errorMessage!, tone: Tone.danger);
                }
              },
              builder: (ctx, state) {
                if (state.status == InboxStatus.loading &&
                    state.notifications.isEmpty) {
                  return ListView(children: [
                    for (var i = 0; i < 6; i++) const SkeletonListTile(),
                  ]);
                }
                // Dismissed rows are hidden for good; actioned requests
                // stay so the post-accept flow is still reachable.
                final visible = state.notifications
                    .where((n) => n.dismissedAt == null)
                    .toList();
                if (visible.isEmpty) {
                  return EmptyView(
                    icon: AppIcons.notifications,
                    title: _unreadOnly
                        ? l.notificationsEmptyUnread
                        : l.notificationsEmptyTitle,
                    message: _unreadOnly ? '' : l.notificationsEmptyMessage,
                  );
                }
                final rows = <Widget>[];
                String? lastDay;
                for (final n in visible) {
                  final local = n.createdAt.toLocal();
                  final day = '${local.year}-${local.month}-${local.day}';
                  if (day != lastDay) {
                    lastDay = day;
                    rows.add(DateGroupHeader(label: _dayLabel(ctx, local)));
                  }
                  rows.add(Dismissible(
                    key: ValueKey('notif_${n.id}'),
                    direction: DismissDirection.endToStart,
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: AppSpacing.xl),
                      color: Theme.of(ctx).colorScheme.surfaceContainerHighest,
                      child: const Icon(AppIcons.hidden),
                    ),
                    onDismissed: (_) {
                      ctx.read<NotificationsInboxCubit>().markDismissed(n.id);
                      showAppSnackBar(ctx, l.notifHidden);
                    },
                    child: NotificationTile(
                      notification: n,
                      onTap: (notif) => _onTap(ctx, notif),
                      onAccept: (id) => switch (n.type) {
                        NotificationType.accountInvite =>
                          _onAcceptWalletInvite(ctx, id),
                        NotificationType.splitCreated =>
                          _onAcceptSplit(ctx, id),
                        NotificationType.splitPaid => _onRecordReceipt(ctx, n),
                        NotificationType.projectTxRecordedForYou =>
                          _onCopyToBook(ctx, n),
                        NotificationType.projectTxChanged =>
                          _onUpdateCopy(ctx, n),
                        _ => _onAcceptLinkRequest(ctx, id),
                      },
                      onReject: (id) => switch (n.type) {
                        NotificationType.accountInvite =>
                          _onRejectWalletInvite(ctx, id),
                        NotificationType.contactLinkRequest =>
                          _onRejectLinkRequest(ctx, id),
                        // One-tap actions: "skip" just hides the row.
                        _ => ctx.read<NotificationsInboxCubit>().markDismissed(id),
                      },
                    ),
                  ));
                }
                if (state.hasMore) {
                  rows.add(const Padding(
                    padding: EdgeInsets.all(AppSpacing.lg),
                    child: Center(child: CircularProgressIndicator()),
                  ));
                }
                return PullToRefresh(
                  onRefresh: () => ctx
                      .read<NotificationsInboxCubit>()
                      .load(unreadOnly: _unreadOnly),
                  child: NotificationListenerWidget(
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(bottom: AppSpacing.huge),
                      children: rows,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
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
    if (n.type == NotificationType.accountInvite) {
      if (n.actionedAt == null) return; // buttons are the action
      // Accepted wallet invite → jump to the wallet.
      final accountId = n.payload['account_id'] as String?;
      if (accountId != null && accountId.isNotEmpty) {
        pushFromOverlay(ctx, '/accounts/$accountId');
      }
      return;
    }
    // Default: informational types — mark read + follow deep link.
    if (n.isUnread) {
      ctx.read<NotificationsInboxCubit>().markRead(n.id);
    }
    final link = n.deepLink;
    if (link != null && link.isNotEmpty) {
      pushFromOverlay(ctx, link);
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

  /// "Add to my debts" on a split someone shared with me (contract §5 —
  /// only offered when my auto-add is off). Creates my side of the debt,
  /// then opens it.
  Future<void> _onAcceptSplit(BuildContext ctx, String id) async {
    final repo = ctx.read<PersonalDebtsRepository>();
    final debtsCubit = ctx.read<PersonalDebtsCubit>();
    final inboxCubit = ctx.read<NotificationsInboxCubit>();
    final messenger = ScaffoldMessenger.of(ctx);
    try {
      final debt = await repo.acceptSplitRequest(id);
      await inboxCubit.load(unreadOnly: inboxCubit.state.filterUnreadOnly);
      unawaited(debtsCubit.load());
      if (ctx.mounted) pushFromOverlay(ctx, '/personal-debts/${debt.id}');
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _showError(ScaffoldMessengerState messenger, ApiException e) => messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(e.message)));

  /// "บันทึกรับเงิน" on split_paid — my settle sheet for my side of the
  /// debt, pre-filled with what they paid. Saved → the row is actioned.
  Future<void> _onRecordReceipt(BuildContext ctx, AppNotification n) async {
    final debtId = n.payload['recipient_debt_id'] as String?;
    if (debtId == null) return;
    final inboxCubit = ctx.read<NotificationsInboxCubit>();
    final messenger = ScaffoldMessenger.of(ctx);
    try {
      final debt = await ctx.read<PersonalDebtsRepository>().get(debtId);
      if (!ctx.mounted) return;
      final saved = await showSettleDebtSheet(ctx, debt,
          amount: (n.payload['amount'] as num?)?.toDouble());
      if (saved) await inboxCubit.markActioned(n.id);
    } on ApiException catch (e) {
      _showError(messenger, e);
    }
  }

  /// "บันทึกเข้าบัญชีส่วนตัว" on project_tx_recorded_for_you — a floating
  /// copy in my book, then open it.
  Future<void> _onCopyToBook(BuildContext ctx, AppNotification n) async {
    final projectId = n.payload['project_id'] as String?;
    final ptId = n.payload['project_transaction_id'] as String?;
    if (projectId == null || ptId == null) return;
    final inboxCubit = ctx.read<NotificationsInboxCubit>();
    final txCubit = ctx.read<TransactionsCubit>();
    final messenger = ScaffoldMessenger.of(ctx);
    try {
      final txId = await ctx
          .read<ProjectsRepository>()
          .copyToPersonal(projectId, ptId);
      await inboxCubit.markActioned(n.id);
      unawaited(txCubit.load());
      if (ctx.mounted) pushFromOverlay(ctx, '/transactions/$txId');
    } on ApiException catch (e) {
      _showError(messenger, e);
    }
  }

  /// "อัปเดตตาม" on project_tx_changed — write the suggested amount / date /
  /// note onto my personal copy.
  Future<void> _onUpdateCopy(BuildContext ctx, AppNotification n) async {
    final txId = n.payload['personal_transaction_id'] as String?;
    final s = n.payload['suggested'];
    if (txId == null || s is! Map) return;
    final inboxCubit = ctx.read<NotificationsInboxCubit>();
    final messenger = ScaffoldMessenger.of(ctx);
    try {
      await ctx.read<TransactionsCubit>().updateTransaction(
            id: txId,
            amount: (s['amount'] as num?)?.toDouble(),
            date: s['date'] as String?,
            note: s['note'] as String?,
          );
      await inboxCubit.markActioned(n.id);
    } on ApiException catch (e) {
      _showError(messenger, e);
    }
  }

  /// Shared-wallet invite accept (spec §14/4). Joins the wallet
  /// (membership row activates), then refreshes the inbox and the
  /// accounts cache so the wallet appears in the list immediately.
  Future<void> _onAcceptWalletInvite(BuildContext ctx, String id) async {
    final l = AppLocalizations.of(ctx)!;
    final repo = ctx.read<AccountsRepository>();
    final accountsCubit = ctx.read<AccountsCubit>();
    final inboxCubit = ctx.read<NotificationsInboxCubit>();
    final messenger = ScaffoldMessenger.of(ctx);
    try {
      await repo.acceptInvite(id);
      await inboxCubit.load(unreadOnly: inboxCubit.state.filterUnreadOnly);
      await accountsCubit.load();
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(walletErrorMessage(l, e))));
    }
  }

  /// Shared-wallet invite reject — row dismissed, silent to the sender
  /// (mirrors the contact link-request reject).
  Future<void> _onRejectWalletInvite(BuildContext ctx, String id) async {
    final l = AppLocalizations.of(ctx)!;
    final repo = ctx.read<AccountsRepository>();
    final inboxCubit = ctx.read<NotificationsInboxCubit>();
    final messenger = ScaffoldMessenger.of(ctx);
    try {
      await repo.rejectInvite(id);
      await inboxCubit.load(unreadOnly: inboxCubit.state.filterUnreadOnly);
    } on ApiException catch (e) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(walletErrorMessage(l, e))));
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
    final rootNav = Navigator.of(ctx, rootNavigator: true);
    // Contacts live in the tab layer; close this overlay first (captured
    // up front because ctx may be gone after the awaits below).
    void open(String location, {Object? extra}) {
      rootNav.popUntil((r) => r.isFirst);
      router.push(location, extra: extra);
    }

    // 1. Linked-contact match — navigate.
    final linked = _firstWhere(
      contactsCubit.state.contacts,
      (c) => c.linkedUserId == senderUserId,
    );
    if (linked != null) {
      open('/contacts/${linked.id}');
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
      open('/contacts/${emailMatch.id}/edit', extra: <String, String?>{
        'linkRequestId': n.id,
      });
      return;
    }

    // 3. No match — create form in link-create mode with locked prefill.
    open('/contacts/new', extra: <String, String?>{
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
