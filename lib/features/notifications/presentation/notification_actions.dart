import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/shell/tab_nav.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../accounts/presentation/wallet_errors.dart';
import '../../contacts/data/contacts_repository.dart';
import '../../contacts/domain/contact.dart';
import '../../contacts/presentation/cubit/contacts_cubit.dart';
import '../../personal_debts/data/personal_debts_repository.dart';
import '../../home/presentation/cubit/dashboard_cubit.dart';
import '../../personal_debts/presentation/debt_wiring.dart';
import '../../projects/data/projects_repository.dart';
import '../../recurring/data/recurring_repository.dart';
import '../../transactions/presentation/cubit/transactions_cubit.dart';
import '../domain/notification.dart';
import 'cubit/notifications_inbox_cubit.dart';

/// What a notification row does when tapped or answered — one place for
/// every list that shows [NotificationTile]s (the inbox, the dashboard's
/// "ต้องจัดการ"), so acting from either behaves the same: the row is
/// marked on the nearest [NotificationsInboxCubit], the snackbar shows and
/// the affected caches refresh.
///
/// Tap routing by type + state:
/// - `contact_link_request` **pending** → no-op (the inline Accept /
///   Reject buttons are the action, so a stray tap can't accept).
/// - `contact_link_request` **actioned** (= accepted) → 3-way: linked
///   match → /contacts/{id} | email match → edit (link-existing) | no
///   match → /contacts/new (link-create).
/// - `account_invite` → pending: no-op; accepted: the wallet.
/// - Other types → mark read + follow [AppNotification.deepLink].
abstract final class NotificationActions {
  /// Row-body tap.
  static Future<void> tap(BuildContext ctx, AppNotification n) async {
    if (n.type == NotificationType.contactLinkRequest) {
      if (!n.isActioned) {
        // Pending row body tap is a no-op — Accept / Reject live as
        // explicit inline buttons on the tile, so accidental row taps
        // don't accept the link unintentionally.
        return;
      }
      await _onTapActionedLinkRequest(ctx, n);
      return;
    }
    if (n.type == NotificationType.accountInvite) {
      if (!n.isActioned) return; // buttons are the action
      // Accepted wallet invite → jump to the wallet.
      final accountId = n.payload['account_id'] as String?;
      if (accountId != null && accountId.isNotEmpty) {
        openPage(ctx, '/accounts/$accountId');
      }
      return;
    }
    if (n.type == NotificationType.projectInvite) {
      if (!n.isActioned) return; // buttons are the action
      final projectId = n.payload['project_id'] as String?;
      if (projectId != null && projectId.isNotEmpty) {
        openPage(ctx, '/projects/$projectId');
      }
      return;
    }
    // Default: informational types — mark read + follow deep link.
    if (n.isUnread) {
      ctx.read<NotificationsInboxCubit>().markRead(n.id);
    }
    final link = n.deepLink;
    if (link != null && link.isNotEmpty) {
      openPage(ctx, link);
    }
  }

  /// The tile's accept / one-tap action button.
  static Future<void> accept(BuildContext ctx, AppNotification n) =>
      switch (n.type) {
        NotificationType.accountInvite => _onAcceptWalletInvite(ctx, n.id),
        NotificationType.splitCreated => _onAcceptSplit(ctx, n.id),
        NotificationType.projectTxRecordedForYou => _onCopyToBook(ctx, n),
        NotificationType.projectTxChanged => _onUpdateCopy(ctx, n),
        NotificationType.splitChanged => _onApplySplitChange(ctx, n),
        NotificationType.projectInvite => _onAcceptProjectInvite(ctx, n),
        NotificationType.recurringEnding => _onExtendRecurring(ctx, n),
        NotificationType.recurringDue => _onOpenPending(ctx, n),
        _ => _onAcceptLinkRequest(ctx, n.id),
      };

  /// The tile's reject / skip button.
  static Future<void> reject(BuildContext ctx, AppNotification n) =>
      switch (n.type) {
        NotificationType.accountInvite => _onRejectWalletInvite(ctx, n.id),
        NotificationType.contactLinkRequest => _onRejectLinkRequest(ctx, n.id),
        NotificationType.projectInvite => _onRejectProjectInvite(ctx, n.id),
        // "ปล่อยให้จบ": nothing to do but mark the notice answered.
        NotificationType.recurringEnding =>
          ctx.read<NotificationsInboxCubit>().markActioned(n.id),
        // One-tap actions: "skip" just hides the row.
        _ => ctx.read<NotificationsInboxCubit>().markDismissed(n.id),
      };
}

/// The page's one re-fetch, keeping its filter.
Future<void> _reload(NotificationsInboxCubit cubit) => cubit.reload();

void _showError(ScaffoldMessengerState messenger, ApiException e) =>
    showAppSnackBarOn(messenger, e.message, tone: Tone.danger);

/// Inline-button handler. Hits the BE's `accept` endpoint (links sender's
/// side + marks the recipient's notification actioned). The row stays in
/// the inbox post-action so the user can re-tap to reach the post-accept
/// contact-flow (linked-detail / link-existing / link-create).
Future<void> _onAcceptLinkRequest(BuildContext ctx, String id) async {
  final repo = ctx.read<ContactsRepository>();
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    inboxCubit.applyAnswer((await repo.acceptLinkRequest(id)).answer);
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
}

/// Inline-button handler. Hits `reject` (marks dismissed; the row vanishes
/// thanks to the lists' dismissed-at filter). Silent on the sender's side
/// — A doesn't learn that B rejected.
Future<void> _onRejectLinkRequest(BuildContext ctx, String id) async {
  final repo = ctx.read<ContactsRepository>();
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    inboxCubit.applyAnswer((await repo.rejectLinkRequest(id)).answer);
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
}

/// "Add to my debts" on a split someone shared with me (contract §5 — only
/// offered when my auto-add is off). Creates my side (one entry), then
/// opens that person's page.
Future<void> _onAcceptSplit(BuildContext ctx, String id) async {
  final repo = ctx.read<PersonalDebtsRepository>();
  final dashboard = ctx.read<DashboardCubit>();
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    final result = await repo.acceptSplit(id);
    await _reload(inboxCubit);
    dashboard.markStale();
    if (ctx.mounted) openPage(ctx, debtPersonPath(result.balance.key));
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
}

/// "อัปเดตตาม" on split_changed — my mirror debt follows the splitter's
/// change (new amount; removed → deleted, or kept at 0 — overpaid — when
/// I'd recorded a repayment). One-shot; a stale or used one says so in
/// plain words and the row refreshes.
Future<void> _onApplySplitChange(BuildContext ctx, AppNotification n) async {
  final l = AppLocalizations.of(ctx)!;
  final repo = ctx.read<PersonalDebtsRepository>();
  final dashboard = ctx.read<DashboardCubit>();
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    final result = await repo.applySplit(n.id);
    await _reload(inboxCubit);
    dashboard.markStale();
    showAppSnackBarOn(
      messenger,
      result.deleted ? l.notifSplitChangeDeleted : l.notifSplitChangeUpdated,
      tone: Tone.success,
    );
  } on ApiException catch (e) {
    final known = switch (e.code) {
      'NOTIFICATION_ACTIONED' => l.notifSplitChangeUsed,
      'SPLIT_CHANGE_STALE' => l.notifSplitChangeStale,
      _ when e.statusCode == 404 => l.notifSplitChangeGone,
      _ => null,
    };
    // Used up or out of date: the row's button should go too.
    if (known != null) unawaited(_reload(inboxCubit));
    showAppSnackBarOn(messenger, known ?? e.message, tone: Tone.danger);
  }
}

/// "ตอบรับ" on project_invite: `POST /projects/link-requests/:id/accept`.
/// NOTE: the project invite answers return the event (no inbox `summary`),
/// so this one keeps the page's re-fetch (the row turns "ทำแล้ว") and the event opens.
Future<void> _onAcceptProjectInvite(BuildContext ctx, AppNotification n) async {
  final repo = ctx.read<ProjectsRepository>();
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    await repo.acceptInvite(n.id);
    await _reload(inboxCubit);
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
}

/// "ปฏิเสธ" on project_invite: `POST /projects/link-requests/:id/reject`.
Future<void> _onRejectProjectInvite(BuildContext ctx, String id) async {
  final repo = ctx.read<ProjectsRepository>();
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    await repo.rejectInvite(id);
    await _reload(inboxCubit);
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
}

/// The `end` body of "ต่ออีก": the SAME length again, from the notice's own
/// payload (`end {kind, date|count}`, `start_date`) — no extra GET.
/// count → ×2; date → end + (end − start), or +1 year without a start;
/// no end (or no data) → null, nothing is sent.
Map<String, dynamic>? extendedEnd(Map<String, dynamic> payload) {
  final end = payload['end'];
  if (end is! Map) return null;
  switch (end['kind']) {
    case 'count':
      final c = end['count'];
      return c is num && c > 0
          ? {'kind': 'count', 'count': c.toInt() * 2}
          : null;
    case 'date':
      final e = DateTime.tryParse('${end['date']}');
      if (e == null) return null;
      final s = DateTime.tryParse('${payload['start_date']}');
      final span = s == null ? null : e.difference(s);
      final next = span == null || span.inDays <= 0
          ? DateTime(e.year + 1, e.month, e.day)
          : DateTime.utc(e.year, e.month, e.day + span.inDays);
      String two(int v) => v.toString().padLeft(2, '0');
      return {
        'kind': 'date',
        'date': '${next.year}-${two(next.month)}-${two(next.day)}',
      };
  }
  return null;
}

/// "ต่ออีก" on recurring_ending: `POST /recurring/:id/extend`, then the
/// BE marks the notice actioned, so the page only re-fetches.
Future<void> _onExtendRecurring(BuildContext ctx, AppNotification n) async {
  final id = n.payload['recurring_id'] as String?;
  if (id == null) return;
  final repo = ctx.read<RecurringRepository>();
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    await repo.extend(id, end: extendedEnd(n.payload));
    await _reload(inboxCubit);
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
}

/// "เปิดรอยืนยัน" on recurring_due: read + open the pending page.
Future<void> _onOpenPending(BuildContext ctx, AppNotification n) async {
  if (n.isUnread) {
    unawaited(ctx.read<NotificationsInboxCubit>().markRead(n.id));
  }
  openPage(ctx, '/pending');
}

/// "บันทึกเข้าบัญชีส่วนตัว" on project_tx_recorded_for_you — a floating copy
/// in my book, then open it.
Future<void> _onCopyToBook(BuildContext ctx, AppNotification n) async {
  final projectId = n.payload['project_id'] as String?;
  final ptId = n.payload['project_transaction_id'] as String?;
  if (projectId == null || ptId == null) return;
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    final txId = await ctx.read<ProjectsRepository>().copyToPersonal(
      projectId,
      ptId,
    );
    await inboxCubit.markActioned(n.id);
    unawaited(TransactionsCubit.bookChanged());
    if (ctx.mounted) openPage(ctx, '/transactions/$txId');
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
}

/// "อัปเดตตาม" on project_tx_changed — another member edited the bill made
/// from my transaction (owner 2026-10-13: linked by prompt, not sync):
/// write the suggested amount / date / description / note onto my
/// transaction only — the bill already has them.
Future<void> _onUpdateCopy(BuildContext ctx, AppNotification n) async {
  final txId = n.payload['personal_transaction_id'] as String?;
  final s = n.payload['suggested'];
  if (txId == null || s is! Map) return;
  final l = AppLocalizations.of(ctx)!;
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final accountsCubit = ctx.read<AccountsCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    final result = await ctx.read<TransactionsCubit>().updateTransaction(
      id: txId,
      amount: (s['amount'] as num?)?.toDouble(),
      date: s['date'] as String?,
      description: s['description'] as String?,
      note: s['note'] as String?,
      alsoUpdateLink: false,
    );
    await inboxCubit.markActioned(n.id);
    // A new amount moves the wallet's balance (the answer carries it);
    // every list re-fetches (the copy may not be in the one on screen).
    accountsCubit.patchBalances(result.accountBalances);
    unawaited(TransactionsCubit.bookChanged());
    showAppSnackBarOn(
      messenger,
      result.isUpcoming ? l.txMovedToUpcoming : l.notifCopyUpdated,
      tone: Tone.success,
    );
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
}

/// Shared-wallet invite accept (spec §14/4). Joins the wallet (membership
/// row activates); the wallet joins the accounts cache and the inbox takes
/// the answer (no re-fetch).
Future<void> _onAcceptWalletInvite(BuildContext ctx, String id) async {
  final l = AppLocalizations.of(ctx)!;
  final accountsCubit = ctx.read<AccountsCubit>();
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    inboxCubit.applyAnswer((await accountsCubit.acceptInvite(id)).answer);
  } on ApiException catch (e) {
    showAppSnackBarOn(messenger, walletErrorMessage(l, e), tone: Tone.danger);
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
    inboxCubit.applyAnswer(await repo.rejectInvite(id));
  } on ApiException catch (e) {
    showAppSnackBarOn(messenger, walletErrorMessage(l, e), tone: Tone.danger);
  }
}

/// Actioned (= accepted) link-request → 3-way navigation:
///   1. linked contact already exists → /contacts/{id}
///   2. unlinked email-match exists → /contacts/{id}/edit (link-pending)
///   3. otherwise → /contacts/new (link-create) with locked prefill
Future<void> _onTapActionedLinkRequest(
  BuildContext ctx,
  AppNotification n,
) async {
  final senderUserId = _senderUserIdOf(n);
  if (senderUserId == null) return;

  final contactsCubit = ctx.read<ContactsCubit>();
  final repo = ctx.read<ContactsRepository>();
  final messenger = ScaffoldMessenger.of(ctx);
  // Contacts are their own tab (captured up front because ctx may be gone
  // after the awaits below).
  final open = pageOpener(ctx);

  // 1. Linked-contact match — navigate.
  final linked = _firstWhere(
    contactsCubit.state.contacts,
    (c) => c.linkedUser?.id == senderUserId,
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
    _showError(messenger, e);
    return;
  }

  // 2. Email-match (unlinked) — open the existing contact in link-existing
  //    mode (display fields locked, save links it).
  Contact? emailMatch;
  if (senderEmail != null && senderEmail.isNotEmpty) {
    final lower = senderEmail.toLowerCase();
    emailMatch = _firstWhere(
      contactsCubit.state.contacts,
      (c) =>
          c.email != null &&
          c.email!.toLowerCase() == lower &&
          c.linkedUser == null,
    );
  }
  if (!ctx.mounted) return;
  if (emailMatch != null) {
    open(
      '/contacts/${emailMatch.id}/edit',
      extra: <String, String?>{'linkRequestId': n.id},
    );
    return;
  }

  // 3. No match — create form in link-create mode with locked prefill.
  open(
    '/contacts/new',
    extra: <String, String?>{
      'linkRequestId': n.id,
      'lockedDisplayName': senderName,
      'lockedEmail': senderEmail,
    },
  );
}

String? _senderUserIdOf(AppNotification n) {
  final fromPayload = n.payload['sender_user_id'];
  if (fromPayload is String && fromPayload.isNotEmpty) return fromPayload;
  return n.actor?.userId;
}

T? _firstWhere<T>(Iterable<T> xs, bool Function(T) test) {
  for (final x in xs) {
    if (test(x)) return x;
  }
  return null;
}
