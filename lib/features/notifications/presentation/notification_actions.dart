import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../app/shell/tab_nav.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../../../shared/widgets/ui.dart';
import '../../accounts/data/accounts_repository.dart';
import '../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../accounts/presentation/wallet_errors.dart';
import '../../contacts/data/contacts_repository.dart';
import '../../contacts/domain/contact.dart';
import '../../contacts/presentation/cubit/contacts_cubit.dart';
import '../../personal_debts/data/personal_debts_repository.dart';
import '../../personal_debts/presentation/cubit/personal_debts_cubit.dart';
import '../../personal_debts/presentation/widgets/debt_widgets.dart';
import '../../projects/data/projects_repository.dart';
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
        openPage(ctx, '/accounts/$accountId');
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
        NotificationType.splitPaid => _onRecordReceipt(ctx, n),
        NotificationType.projectTxRecordedForYou => _onCopyToBook(ctx, n),
        NotificationType.projectTxChanged => _onUpdateCopy(ctx, n),
        NotificationType.splitChanged => _onApplySplitChange(ctx, n),
        _ => _onAcceptLinkRequest(ctx, n.id),
      };

  /// The tile's reject / skip button.
  static Future<void> reject(BuildContext ctx, AppNotification n) =>
      switch (n.type) {
        NotificationType.accountInvite => _onRejectWalletInvite(ctx, n.id),
        NotificationType.contactLinkRequest => _onRejectLinkRequest(ctx, n.id),
        // One-tap actions: "skip" just hides the row.
        _ => ctx.read<NotificationsInboxCubit>().markDismissed(n.id),
      };
}

/// Reloads [cubit] keeping its All / Unread filter.
Future<void> _reload(NotificationsInboxCubit cubit) =>
    cubit.load(unreadOnly: cubit.state.filterUnreadOnly);

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
    await repo.acceptLinkRequest(id);
    await _reload(inboxCubit);
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
    await repo.rejectLinkRequest(id);
    await _reload(inboxCubit);
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
}

/// "Add to my debts" on a split someone shared with me (contract §5 — only
/// offered when my auto-add is off). Creates my side of the debt, then
/// opens it.
Future<void> _onAcceptSplit(BuildContext ctx, String id) async {
  final repo = ctx.read<PersonalDebtsRepository>();
  final debtsCubit = ctx.read<PersonalDebtsCubit>();
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    final debt = await repo.acceptSplitRequest(id);
    await _reload(inboxCubit);
    unawaited(debtsCubit.load());
    if (ctx.mounted) openPage(ctx, '/personal-debts/${debt.id}');
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
  final debtsCubit = ctx.read<PersonalDebtsCubit>();
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    final result = await repo.applySplitChange(n.id);
    await _reload(inboxCubit);
    unawaited(debtsCubit.load());
    showAppSnackBarOn(messenger, switch (result) {
      'deleted' => l.notifSplitChangeDeleted,
      'zeroed' => l.notifSplitChangeZeroed,
      _ => l.notifSplitChangeUpdated,
    }, tone: Tone.success);
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

/// "บันทึกรับเงิน" on split_paid — my settle sheet for my side of the debt,
/// pre-filled with what they paid. Saved → the row is actioned.
Future<void> _onRecordReceipt(BuildContext ctx, AppNotification n) async {
  final debtId = n.payload['recipient_debt_id'] as String?;
  if (debtId == null) return;
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    final debt = await ctx.read<PersonalDebtsRepository>().get(debtId);
    if (!ctx.mounted) return;
    final saved = await showSettleDebtSheet(
      ctx,
      debt,
      amount: (n.payload['amount'] as num?)?.toDouble(),
    );
    if (saved) await inboxCubit.markActioned(n.id);
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
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

/// "อัปเดตตาม" on project_tx_changed — write the suggested amount / date /
/// description / note onto my personal copy.
Future<void> _onUpdateCopy(BuildContext ctx, AppNotification n) async {
  final txId = n.payload['personal_transaction_id'] as String?;
  final s = n.payload['suggested'];
  if (txId == null || s is! Map) return;
  final l = AppLocalizations.of(ctx)!;
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final accountsCubit = ctx.read<AccountsCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    await ctx.read<TransactionsCubit>().updateTransaction(
      id: txId,
      amount: (s['amount'] as num?)?.toDouble(),
      date: s['date'] as String?,
      description: s['description'] as String?,
      note: s['note'] as String?,
    );
    await inboxCubit.markActioned(n.id);
    // A new amount moves the wallet's balance; every list re-fetches
    // (the copy may not be in the one on screen).
    unawaited(accountsCubit.load());
    unawaited(TransactionsCubit.bookChanged());
    showAppSnackBarOn(messenger, l.notifCopyUpdated, tone: Tone.success);
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
}

/// Shared-wallet invite accept (spec §14/4). Joins the wallet (membership
/// row activates), then refreshes the list and the accounts cache so the
/// wallet appears in the list immediately.
Future<void> _onAcceptWalletInvite(BuildContext ctx, String id) async {
  final l = AppLocalizations.of(ctx)!;
  final repo = ctx.read<AccountsRepository>();
  final accountsCubit = ctx.read<AccountsCubit>();
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    await repo.acceptInvite(id);
    await _reload(inboxCubit);
    await accountsCubit.load();
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
    await repo.rejectInvite(id);
    await _reload(inboxCubit);
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
          c.linkedUserId == null,
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
  return n.actorUserId;
}

T? _firstWhere<T>(Iterable<T> xs, bool Function(T) test) {
  for (final x in xs) {
    if (test(x)) return x;
  }
  return null;
}
