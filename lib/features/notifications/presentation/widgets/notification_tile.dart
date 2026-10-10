import 'package:flutter/material.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/currencies.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/notification.dart';

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
    super.key,
  });

  final AppNotification notification;
  final ValueChanged<AppNotification> onTap;

  /// Pending `contact_link_request` / `account_invite` only.
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onReject;

  /// Whether [n] still shows its answer buttons — a request or one-tap
  /// action not yet taken (the dashboard's "ต้องจัดการ" lists these).
  static bool awaitsAnswer(AppNotification n) =>
      (_isRequestOf(n) || _hasActionOf(n)) && n.actionedAt == null;

  /// Requests need an answer (accept / reject, with a confirm on reject).
  static bool _isRequestOf(AppNotification n) =>
      n.type == NotificationType.contactLinkRequest ||
      n.type == NotificationType.accountInvite;

  /// One-tap actions (contract §5) — "skip" just hides the row. Auto-run
  /// ones arrive already actioned and show "ทำแล้ว".
  static bool _hasActionOf(AppNotification n) => switch (n.type) {
    // A split that was removed / changed again since: nothing to do.
    NotificationType.splitCreated ||
    NotificationType.splitChanged => n.payload['superseded'] != true,
    NotificationType.splitPaid ||
    NotificationType.projectTxRecordedForYou => true,
    // Only when I have a personal copy to update.
    NotificationType.projectTxChanged =>
      n.payload['personal_transaction_id'] != null &&
          n.payload['suggested'] != null,
    _ => false,
  };

  bool get _isRequest => _isRequestOf(notification);
  bool get _hasAction => _hasActionOf(notification);

  String _actionLabel(AppLocalizations l) => switch (notification.type) {
    NotificationType.splitCreated => l.notifActionAddDebt,
    NotificationType.splitPaid => l.notifActionRecordReceipt,
    NotificationType.projectTxRecordedForYou => l.notifActionCopyToBook,
    NotificationType.projectTxChanged => l.notifActionUpdateCopy,
    NotificationType.splitChanged => l.notifActionUpdateCopy,
    _ => l.notificationAccept,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final n = notification;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final actionable = _isRequest || _hasAction;
    final pending = actionable && n.actionedAt == null;
    final accepted = actionable && n.actionedAt != null;
    final amount = _amount(context);
    final actor = n.actorDisplayName ?? l.notificationsSomeone;

    return Material(
      color: n.isUnread
          ? scheme.primary.withValues(alpha: 0.06)
          : Colors.transparent,
      child: InkWell(
        onTap: () => onTap(n),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CornerBadge(
                badge: Icon(_iconFor(n.type), size: 12),
                child: UserAvatar(displayName: actor, size: 40),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(context, l, n, actor),
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: n.isUnread
                            ? FontWeight.w600
                            : FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        DateFormatter.time(
                          n.createdAt.toLocal(),
                          locale: Localizations.localeOf(
                            context,
                          ).toLanguageTag(),
                        ),
                        ?amount,
                      ].join(' · '),
                      style: textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (accepted) ...[
                      const SizedBox(height: AppSpacing.xs),
                      AppBadge(
                        label: _isRequest ? l.notifAccepted : l.notifActionDone,
                        icon: AppIcons.success,
                        tone: Tone.success,
                      ),
                    ],
                    if (pending) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: _actionLabel(l),
                              icon: AppIcons.check,
                              onPressed: () => onAccept(n.id),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: AppButton(
                              label: _isRequest
                                  ? l.notificationReject
                                  : l.notifActionSkip,
                              variant: AppButtonVariant.outlined,
                              onPressed: _isRequest
                                  ? () => _confirmReject(context)
                                  : () => onReject(n.id),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (n.isUnread)
                Padding(
                  padding: const EdgeInsets.only(left: AppSpacing.sm, top: 6),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _confirmReject(BuildContext context) async {
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.notifRejectTitle,
      message: l.notifRejectBody,
      confirmLabel: l.notificationReject,
      destructive: true,
    );
    if (ok) onReject(notification.id);
  }

  String? _amount(BuildContext context) {
    final a = notification.payload['amount'];
    if (a is! num) return null;
    final cur = (notification.payload['currency'] as String?) ?? 'THB';
    return moneyString(context, a, symbol: Currencies.symbolOf(cur));
  }

  static IconData _iconFor(NotificationType t) => switch (t) {
    NotificationType.splitCreated ||
    NotificationType.splitChanged ||
    NotificationType.splitPaid ||
    NotificationType.splitReceived => AppIcons.split,
    NotificationType.projectTxRecordedForYou ||
    NotificationType.projectTxChanged ||
    NotificationType.projectInvite ||
    NotificationType.projectAdded => AppIcons.project,
    NotificationType.contactLinkRequest => AppIcons.link,
    NotificationType.accountInvite => AppIcons.bank,
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
    NotificationType.splitPaid => l.notifSplitPaid(actor),
    NotificationType.splitReceived => l.notifSplitReceived(actor),
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
      n.actorDisplayName ??
      l.notificationsSomeone;
  final what = (p['description'] as String?)?.trim() ?? '';
  if (p['change'] == 'removed') return l.notifSplitRemovedYou(who, what);
  final symbol = Currencies.symbolOf((p['currency'] as String?) ?? 'THB');
  String money(Object? v) =>
      v is num ? moneyString(context, v, symbol: symbol) : '—';
  return l.notifSplitAmountChanged(
    who,
    what,
    money(p['old_amount']),
    money(p['new_amount']),
  );
}
