import 'package:flutter/material.dart';
import '../../../../core/utils/user_currency.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/notification.dart';

/// Thin wrapper over [NotificationTileView] (maps model + l10n).
/// One inbox row (§7): sender avatar with a type badge, the sentence, time,
/// ● when unread. Swipe left to hide (handled by the page). Pending
/// invites / link requests get big Accept / Decline buttons (decline asks
/// first); once accepted the row says so and stays tappable.
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

  /// Pending `contact_link_request` / `account_invite` only.
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onReject;

  /// A hidden (dismissed) row: shown without answer buttons.
  final bool hidden;

  /// Whether [n] still shows its answer buttons — the BE decides (the
  /// dashboard's "ต้องจัดการ" lists these).
  static bool awaitsAnswer(AppNotification n) => n.awaitsAnswer;

  /// Requests need an answer (accept / reject, with a confirm on reject).
  bool get _isRequest =>
      notification.type == NotificationType.contactLinkRequest ||
      notification.type == NotificationType.accountInvite ||
      notification.type == NotificationType.projectInvite;

  bool get _isRecurring =>
      notification.type == NotificationType.recurringDue ||
      notification.type == NotificationType.recurringEnding;

  /// Types that carry an action (request or one-tap, contract §5): once
  /// taken — or auto-run on arrival — the row says "ทำแล้ว".
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
    NotificationType.recurringDue => l.notifActionOpenPending,
    _ => l.notificationAccept,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final n = notification;
    // The recurring notices come from the app itself, not a person.
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

  /// Answer buttons: while the BE says the row waits, plus the one-tap
  /// "open pending" on an unread recurring_due notice.
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
    NotificationType.projectTxRecordedForYou ||
    NotificationType.projectTxChanged ||
    NotificationType.projectInvite ||
    NotificationType.projectAdded => AppIcons.project,
    NotificationType.contactLinkRequest => AppIcons.link,
    NotificationType.accountInvite => AppIcons.bank,
    NotificationType.recurringDue ||
    NotificationType.recurringEnding => AppIcons.recurring,
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
    NotificationType.unknown => l.notifUnknown,
  };
}

/// split_changed: "Poom แก้ยอดหาร Dinner: ฿150 → ฿120" / "Poom เอาคุณออกจาก
/// การหาร Dinner".
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
