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
import '../../personal_debts/presentation/debt_wiring.dart';
import '../../projects/data/projects_repository.dart';
import '../../recurring/data/recurring_repository.dart';
import '../../transactions/presentation/cubit/transactions_cubit.dart';
import '../domain/notification.dart';
import 'cubit/notifications_inbox_cubit.dart';
import 'notification_routes.dart';

abstract final class NotificationActions {
  static Future<void> tap(BuildContext ctx, AppNotification n) async {
    if (n.type == NotificationType.contactLinkRequest) {
      if (!n.isActioned) {
        // Pending row body tap is a no-op — Accept / Reject live as explicit
        // inline buttons on the tile, so accidental row taps don't accept the
        // link unintentionally.
        return;
      }
      await _onTapActionedLinkRequest(ctx, n);
      return;
    }
    if (n.type == NotificationType.accountInvite) {
      if (!n.isActioned) return; // buttons are the action
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
    if (n.isUnread) {
      ctx.read<NotificationsInboxCubit>().markRead(n.id);
    }
    final link = n.deepLink;
    if (link != null && link.isNotEmpty) {
      openPage(ctx, link);
    }
  }

  static Future<void> accept(BuildContext ctx, AppNotification n) =>
      switch (acceptRouteOf(n.type)) {
        AcceptRoute.walletInvite => _onAcceptWalletInvite(ctx, n.id),
        AcceptRoute.split => _onAcceptSplit(ctx, n.id),
        AcceptRoute.copyToBook => _onCopyToBook(ctx, n),
        AcceptRoute.updateCopy => _onUpdateCopy(ctx, n),
        AcceptRoute.splitChange => _onApplySplitChange(ctx, n),
        AcceptRoute.projectInvite => _onAcceptProjectInvite(ctx, n),
        AcceptRoute.extendRecurring => _onExtendRecurring(ctx, n),
        AcceptRoute.openDue => _onOpenDue(ctx, n),
        AcceptRoute.linkRequest => _onAcceptLinkRequest(ctx, n.id),
      };

  static Future<void> reject(BuildContext ctx, AppNotification n) =>
      switch (rejectRouteOf(n.type)) {
        RejectRoute.walletInvite => _onRejectWalletInvite(ctx, n.id),
        RejectRoute.linkRequest => _onRejectLinkRequest(ctx, n.id),
        RejectRoute.projectInvite => _onRejectProjectInvite(ctx, n.id),
        RejectRoute.markActioned =>
          ctx.read<NotificationsInboxCubit>().markActioned(n.id),
        RejectRoute.dismiss =>
          ctx.read<NotificationsInboxCubit>().markDismissed(n.id),
      };
}

Future<void> _reload(NotificationsInboxCubit cubit) => cubit.reload();

void _showError(ScaffoldMessengerState messenger, ApiException e) =>
    showAppSnackBarOn(messenger, e.message, tone: Tone.danger);

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

Future<void> _onAcceptSplit(BuildContext ctx, String id) async {
  final repo = ctx.read<PersonalDebtsRepository>();
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    final result = await repo.acceptSplit(id);
    await _reload(inboxCubit);
    if (ctx.mounted) openPage(ctx, debtPersonPath(result.balance.key));
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
}

Future<void> _onApplySplitChange(BuildContext ctx, AppNotification n) async {
  final l = AppLocalizations.of(ctx)!;
  final repo = ctx.read<PersonalDebtsRepository>();
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    final result = await repo.applySplit(n.id);
    await _reload(inboxCubit);
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
    if (known != null) unawaited(_reload(inboxCubit));
    showAppSnackBarOn(messenger, known ?? e.message, tone: Tone.danger);
  }
}

Future<void> _onAcceptProjectInvite(BuildContext ctx, AppNotification n) async {
  final repo = ctx.read<ProjectsRepository>();
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    final summary = await repo.acceptInvite(n.id);
    inboxCubit.applyInboxSummary(n.id, summary);
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
}

Future<void> _onRejectProjectInvite(BuildContext ctx, String id) async {
  final repo = ctx.read<ProjectsRepository>();
  final inboxCubit = ctx.read<NotificationsInboxCubit>();
  final messenger = ScaffoldMessenger.of(ctx);
  try {
    final summary = await repo.rejectInvite(id);
    inboxCubit.applyInboxSummary(id, summary);
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
}

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

/// The due notice's button: its deep link (ต้องจัดการ on the recurring page).
Future<void> _onOpenDue(BuildContext ctx, AppNotification n) async {
  if (n.isUnread) {
    unawaited(ctx.read<NotificationsInboxCubit>().markRead(n.id));
  }
  final link = n.deepLink;
  openPage(ctx, link == null || link.isEmpty ? '/recurring?focus=due' : link);
}

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
    if (ctx.mounted) openPage(ctx, '/transactions/$txId');
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
}

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
    accountsCubit.patchBalances(result.accountBalances);
    showAppSnackBarOn(messenger, l.notifCopyUpdated, tone: Tone.success);
  } on ApiException catch (e) {
    _showError(messenger, e);
  }
}

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

Future<void> _onTapActionedLinkRequest(
  BuildContext ctx,
  AppNotification n,
) async {
  final senderUserId = _senderUserIdOf(n);
  if (senderUserId == null) return;

  final contactsCubit = ctx.read<ContactsCubit>();
  final repo = ctx.read<ContactsRepository>();
  final messenger = ScaffoldMessenger.of(ctx);
  // Contacts are their own tab (captured up front because ctx may be gone after
  // the awaits below).
  final open = pageOpener(ctx);

  final linked = _firstWhere(
    contactsCubit.state.contacts,
    (c) => c.linkedUser?.id == senderUserId,
  );
  if (linked != null) {
    open('/contacts/${linked.id}');
    return;
  }

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
