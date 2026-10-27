import 'package:flutter/material.dart';
import '../../../../core/utils/user_currency.dart';

import '../../../../core/utils/date_formatter.dart';
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

  bool get _hasAction => switch (notification.type) {
    NotificationType.splitCreated ||
    NotificationType.splitChanged ||
    NotificationType.projectTxRecordedForYou ||
    NotificationType.projectTxChanged ||
    NotificationType.recurringEnding => true,
    _ => false,
  };

  String _actionLabel(AppLocalizations l) => switch (notification.type) {
    NotificationType.splitCreated => l.notifActionAddDebt,
    NotificationType.projectTxRecordedForYou => l.notifActionCopyToBook,
    NotificationType.projectTxChanged => l.notifActionUpdateCopy,
    NotificationType.splitChanged => l.notifActionUpdateCopy,
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
    final accepted = (_isRequest || _hasAction) && n.isActioned;

    return NotificationTileView(
      actorName: actor,
      actorIconCode: n.actor?.iconCode,
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
        _ => _isRequest ? l.notificationReject : l.notifActionSkip,
      },
      rejectConfirm: _isRequest
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
    final a = notification.payload['amount'];
    if (a is! num) return null;
    return moneyString(context, a, symbol: context.readUserCurrencySymbol);
  }

  static IconData _iconFor(NotificationType t) => switch (t) {
    NotificationType.splitCreated ||
    NotificationType.splitChanged => AppIcons.split,
    NotificationType.debtDisconnected => AppIcons.link,
    NotificationType.projectTxRecordedForYou ||
    NotificationType.projectTxChanged ||
    NotificationType.projectInvite ||
    NotificationType.projectAdded => AppIcons.project,
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
    NotificationType.splitCreated => l.notifSplitCreated(actor),
    NotificationType.splitChanged => _splitChangeTitle(context, l, n),
    NotificationType.debtDisconnected => _debtDisconnectedTitle(context, l, n),
    NotificationType.projectTxRecordedForYou => l.notifProjectTxForYou(actor),
    NotificationType.projectTxChanged => l.notifProjectTxChanged(actor),
    NotificationType.projectInvite => l.notifProjectInvite(
      actor,
      (n.payload['project_name'] as String?) ?? '',
    ),
    NotificationType.contactLinkRequest => l.notifContactLink(actor),
    NotificationType.projectAdded => l.notifProjectAdded(
      actor,
      (n.payload['project_name'] as String?) ?? '',
    ),
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
    NotificationType.unknown => l.notifUnknown,
  };
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

String _splitChangeTitle(
  BuildContext context,
  AppLocalizations l,
  AppNotification n,
) {
  final p = n.payload;
  final who =
      (p['splitter_display_name'] as String?) ??
      n.actor?.displayName ??
      l.notificationsSomeone;
  final what = (p['description'] as String?)?.trim() ?? '';
  if (p['change'] == 'removed') return l.notifSplitRemovedYou(who, what);
  final symbol = context.readUserCurrencySymbol;
  String money(Object? v) =>
      v is num ? moneyString(context, v, symbol: symbol) : '—';
  return l.notifSplitAmountChanged(
    who,
    what,
    money(p['old_amount']),
    money(p['new_amount']),
  );
}
