import 'package:flutter/material.dart';
import '../../../../core/utils/user_currency.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/notification.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.notification,
    required this.onTap,
    required this.onAccept,
    required this.onReject,
    this.hidden = false,
    super.key,
  });

  final AppNotification notification;
  final ValueChanged<AppNotification> onTap;

  final ValueChanged<String> onAccept;
  final ValueChanged<String> onReject;

  /// A hidden (dismissed) row: shown without answer buttons.
  final bool hidden;

  static bool awaitsAnswer(AppNotification n) => n.awaitsAnswer;

  bool get _isRequest =>
      notification.type == NotificationType.contactLinkRequest ||
      notification.type == NotificationType.accountInvite ||
      notification.type == NotificationType.projectInvite;

  bool get _isRecurring =>
      notification.type == NotificationType.recurringDue ||
      notification.type == NotificationType.recurringEnding ||
      notification.type == NotificationType.recurringAutoCreated;

  bool get _isBillInvite => notification.type == NotificationType.billInvite;

  bool get _hasAction => switch (notification.type) {
    NotificationType.billNew ||
    NotificationType.billChanged ||
    NotificationType.billRemoved ||
    NotificationType.debtRepaid ||
    NotificationType.recurringEnding => true,
    _ => false,
  };

  String _actionLabel(AppLocalizations l) => switch (notification.type) {
    NotificationType.billInvite => l.notifActionJoin,
    NotificationType.billNew => l.notifActionClaim,
    NotificationType.billChanged => l.notifActionUpdateCopy,
    NotificationType.billRemoved => l.notifActionDeleteMine,
    NotificationType.debtRepaid =>
      notification.payload['direction'] == 'paid'
          ? l.notifActionRecordPaid
          : l.notifActionRecordReceived,
    NotificationType.recurringEnding => l.notifActionExtend,
    NotificationType.recurringDue => l.notifActionOpenDue,
    _ => l.notificationAccept,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final n = notification;
    final actor =
        n.actor?.displayName ??
        (_isRecurring ? l.moreRecurring : l.notificationsSomeone);
    final accepted =
        (_isRequest || _isBillInvite || _hasAction) && n.isActioned;

    return NotificationTileView(
      actorName: actor,
      actorAvatar: n.actor?.avatar ?? AvatarData.forName(actor),
      title: _title(context, l, n, actor),
      timeText: DateFormatter.time(
        n.createdAt.toLocal(),
        locale: Localizations.localeOf(context).toLanguageTag(),
      ),
      amountText: _amount(context),
      typeIcon: _iconFor(n.type),
      unread: n.isUnread,
      system: n.actor == null && _isRecurring,
      pending: !hidden && _shows(n),
      acceptedLabel: accepted
          ? (_isRequest ? l.notifAccepted : l.notifActionDone)
          : null,
      acceptLabel: _actionLabel(l),
      rejectLabel: switch (n.type) {
        NotificationType.recurringDue => null,
        NotificationType.recurringEnding => l.notifActionLetEnd,
        NotificationType.billRemoved => l.notifActionKeepMine,
        _ =>
          _isRequest || _isBillInvite
              ? l.notificationReject
              : l.notifActionSkip,
      },
      rejectConfirm: _isRequest || _isBillInvite
          ? NotificationRejectConfirm(
              title: l.notifRejectTitle,
              message: l.notifRejectBody,
              confirmLabel: l.notificationReject,
            )
          : null,
      onTap: () => onTap(n),
      onAccept: () => onAccept(n.id),
      onReject: () => onReject(n.id),
    );
  }

  bool _shows(AppNotification n) =>
      n.awaitsAnswer || (n.type == NotificationType.recurringDue && n.isUnread);

  String? _amount(BuildContext context) {
    // A bill shows my share of it.
    final a =
        notification.payload['my_share'] ?? notification.payload['amount'];
    if (a is! num) return null;
    return moneyString(context, a, symbol: context.readUserCurrencySymbol);
  }

  static IconData _iconFor(NotificationType t) => switch (t) {
    NotificationType.billInvite ||
    NotificationType.billNew ||
    NotificationType.billChanged ||
    NotificationType.billRemoved ||
    NotificationType.billOwnerChanged ||
    NotificationType.billMoved => AppIcons.receipt,
    NotificationType.debtRepaid => AppIcons.split,
    NotificationType.debtDisconnected => AppIcons.link,
    NotificationType.projectInvite ||
    NotificationType.eventCompleted ||
    NotificationType.eventMemberRemoved ||
    NotificationType.eventDeleted => AppIcons.project,
    NotificationType.contactLinkRequest => AppIcons.link,
    NotificationType.accountInvite => AppIcons.bank,
    NotificationType.recurringDue ||
    NotificationType.recurringEnding ||
    NotificationType.recurringAutoCreated => AppIcons.recurring,
    NotificationType.unknown => AppIcons.notifications,
  };

  String _title(
    BuildContext context,
    AppLocalizations l,
    AppNotification n,
    String actor,
  ) => switch (n.type) {
    NotificationType.billInvite => l.notifBillInvite(actor, _billName(n)),
    NotificationType.billNew => l.notifSharedBillCreated(actor, _billName(n)),
    NotificationType.billChanged => l.notifBillChanged(actor, _billName(n)),
    NotificationType.billRemoved => l.notifBillRemoved(actor, _billName(n)),
    NotificationType.billOwnerChanged => l.notifBillOwnerChanged(_billName(n)),
    NotificationType.billMoved => switch (n.payload['project_name']) {
      final String event when event.isNotEmpty => l.notifBillMovedIn(
        actor,
        _billName(n),
        event,
      ),
      _ => l.notifBillMovedOut(actor, _billName(n)),
    },
    NotificationType.debtRepaid => _debtRepaidTitle(l, n, actor),
    NotificationType.debtDisconnected => _debtDisconnectedTitle(context, l, n),
    NotificationType.projectInvite => l.notifProjectInvite(
      actor,
      (n.payload['project_name'] as String?) ?? '',
    ),
    NotificationType.contactLinkRequest => l.notifContactLink(actor),
    NotificationType.accountInvite => l.notificationWalletInviteTitle(
      actor,
      (n.payload['account_name'] as String?) ?? '',
    ),
    NotificationType.recurringDue => l.notifRecurringDue(
      (n.payload['count'] as num?)?.toInt() ?? 1,
    ),
    NotificationType.recurringEnding => l.notifRecurringEnding(
      (n.payload['name'] as String?) ?? '',
      (n.payload['left'] as num?)?.toInt() ?? 0,
    ),
    NotificationType.recurringAutoCreated => l.notifRecurringAutoCreated(
      (n.payload['count'] as num?)?.toInt() ?? 1,
    ),
    NotificationType.eventCompleted => l.notifEventCompleted(
      n.actor?.displayName ?? (n.payload['owner_name'] as String?) ?? actor,
      (n.payload['project_name'] as String?) ?? '',
    ),
    NotificationType.eventMemberRemoved => l.notifEventMemberRemoved(
      actor,
      (n.payload['project_name'] as String?) ?? '',
    ),
    NotificationType.eventDeleted => l.notifEventDeleted(
      actor,
      (n.payload['project_name'] as String?) ?? '',
    ),
    NotificationType.unknown => l.notifUnknown,
  };

  /// `direction` is as my repayment row would be: received = they paid me.
  static String _debtRepaidTitle(
    AppLocalizations l,
    AppNotification n,
    String actor,
  ) {
    final who = (n.payload['person_name'] as String?) ?? actor;
    return n.payload['direction'] == 'paid'
        ? l.notifDebtRepaidByMe(who)
        : l.notifDebtRepaidToMe(who);
  }

  /// A bill in a title: its description, else its event's name.
  static String _billName(AppNotification n) {
    final d = (n.payload['description'] as String?)?.trim() ?? '';
    return d.isNotEmpty ? d : (n.payload['project_name'] as String?) ?? '';
  }
}

/// "ลี ตัดการเชื่อมหนี้ ฿300 แล้ว" (D9); a tap opens my entry (deep link).
String _debtDisconnectedTitle(
  BuildContext context,
  AppLocalizations l,
  AppNotification n,
) {
  final p = n.payload;
  final who =
      n.actor?.displayName ??
      (p['person_name'] as String?) ??
      l.notificationsSomeone;
  final amount = p['amount'];
  return l.notifDebtDisconnected(
    who,
    amount is num
        ? moneyString(context, amount, symbol: context.readUserCurrencySymbol)
        : '—',
  );
}
