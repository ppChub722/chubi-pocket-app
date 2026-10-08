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

  /// Requests need an answer (accept / reject, with a confirm on reject).
  bool get _isRequest =>
      notification.type == NotificationType.contactLinkRequest ||
      notification.type == NotificationType.accountInvite;

  /// One-tap actions (contract §5) — "skip" just hides the row. Auto-run
  /// ones arrive already actioned and show "ทำแล้ว".
  bool get _hasAction => switch (notification.type) {
        NotificationType.splitCreated ||
        NotificationType.splitPaid ||
        NotificationType.projectTxRecordedForYou =>
          true,
        // Only when I have a personal copy to update.
        NotificationType.projectTxChanged =>
          notification.payload['personal_transaction_id'] != null &&
              notification.payload['suggested'] != null,
        _ => false,
      };

  String _actionLabel(AppLocalizations l) => switch (notification.type) {
        NotificationType.splitCreated => l.notifActionAddDebt,
        NotificationType.splitPaid => l.notifActionRecordReceipt,
        NotificationType.projectTxRecordedForYou => l.notifActionCopyToBook,
        NotificationType.projectTxChanged => l.notifActionUpdateCopy,
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
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
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
                      _title(l, n, actor),
                      style: textTheme.bodyMedium?.copyWith(
                          fontWeight:
                              n.isUnread ? FontWeight.w600 : FontWeight.w400),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        DateFormatter.time(n.createdAt.toLocal(),
                            locale: Localizations.localeOf(context)
                                .toLanguageTag()),
                        ?amount,
                      ].join(' · '),
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    if (accepted) ...[
                      const SizedBox(height: AppSpacing.xs),
                      AppBadge(
                          label: _isRequest ? l.notifAccepted : l.notifActionDone,
                          icon: AppIcons.success,
                          tone: Tone.success),
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
                        color: scheme.primary, shape: BoxShape.circle),
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
        NotificationType.splitPaid ||
        NotificationType.splitReceived =>
          AppIcons.split,
        NotificationType.projectTxRecordedForYou ||
        NotificationType.projectTxChanged ||
        NotificationType.projectInvite ||
        NotificationType.projectAdded =>
          AppIcons.project,
        NotificationType.contactLinkRequest => AppIcons.link,
        NotificationType.accountInvite => AppIcons.bank,
        NotificationType.unknown => AppIcons.notifications,
      };

  static String _title(AppLocalizations l, AppNotification n, String actor) =>
      switch (n.type) {
        NotificationType.splitCreated => l.notifSplitCreated(actor),
        NotificationType.splitPaid => l.notifSplitPaid(actor),
        NotificationType.splitReceived => l.notifSplitReceived(actor),
        NotificationType.projectTxRecordedForYou => l.notifProjectTxForYou(actor),
        NotificationType.projectTxChanged => l.notifProjectTxChanged(actor),
        NotificationType.projectInvite => l.notifProjectInvite(
            actor, (n.payload['project_name'] as String?) ?? ''),
        NotificationType.contactLinkRequest => l.notifContactLink(actor),
        NotificationType.projectAdded => l.notifProjectAdded(
            actor, (n.payload['project_name'] as String?) ?? ''),
        NotificationType.accountInvite => l.notificationWalletInviteTitle(
            actor, (n.payload['account_name'] as String?) ?? ''),
        NotificationType.unknown => l.notifUnknown,
      };
}
