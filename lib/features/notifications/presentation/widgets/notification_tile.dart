import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../domain/notification.dart';

/// One inbox row. Type-aware: link-request types render Accept/Reject
/// inline; informational types route via [AppNotification.deepLink] when
/// tapped.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    required this.notification,
    required this.onMarkRead,
    required this.onDismiss,
    required this.onAccept,
    required this.onReject,
    super.key,
  });

  final AppNotification notification;
  final ValueChanged<String> onMarkRead;
  final ValueChanged<String> onDismiss;
  final ValueChanged<String> onAccept;
  final ValueChanged<String> onReject;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final theme = Theme.of(context);
    final isLinkRequest = n.type == NotificationType.contactLinkRequest ||
        n.type == NotificationType.projectInvite;
    final actionable = isLinkRequest && !n.isTerminal;

    return Material(
      color: n.isUnread
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.18)
          : theme.colorScheme.surface,
      child: InkWell(
        onTap: () => _onTap(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.secondaryContainer,
                child: Icon(_iconFor(n.type), size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _title(n),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight:
                            n.isUnread ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    if (_subtitle(n) case final sub?)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          sub,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    if (actionable)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Row(
                          children: [
                            FilledButton.tonal(
                              onPressed: () => onAccept(n.id),
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Accept'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => onReject(n.id),
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              child: const Text('Reject'),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 20),
                onSelected: (action) {
                  switch (action) {
                    case 'read':
                      onMarkRead(n.id);
                    case 'dismiss':
                      onDismiss(n.id);
                  }
                },
                itemBuilder: (context) => [
                  if (n.isUnread)
                    const PopupMenuItem(
                      value: 'read',
                      child: Text('Mark as read'),
                    ),
                  if (!n.isTerminal)
                    const PopupMenuItem(
                      value: 'dismiss',
                      child: Text('Dismiss'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    if (notification.isUnread) onMarkRead(notification.id);
    final link = notification.deepLink;
    if (link != null && link.isNotEmpty) {
      context.push(link);
    }
  }

  IconData _iconFor(NotificationType t) {
    switch (t) {
      case NotificationType.splitCreated:
      case NotificationType.splitPaid:
      case NotificationType.splitReceived:
        return Icons.receipt_long_outlined;
      case NotificationType.projectTxRecordedForYou:
      case NotificationType.projectTxChanged:
        return Icons.folder_shared_outlined;
      case NotificationType.projectInvite:
      case NotificationType.contactLinkRequest:
        return Icons.person_add_alt_1_outlined;
      case NotificationType.unknown:
        return Icons.notifications_outlined;
    }
  }

  String _title(AppNotification n) {
    final actor = n.actorDisplayName ?? 'Someone';
    switch (n.type) {
      case NotificationType.splitCreated:
        return '$actor split a bill with you';
      case NotificationType.splitPaid:
        return '$actor paid your split';
      case NotificationType.splitReceived:
        return '$actor confirmed receiving your payment';
      case NotificationType.projectTxRecordedForYou:
        return '$actor recorded a project transaction for you';
      case NotificationType.projectTxChanged:
        return '$actor edited a project transaction';
      case NotificationType.projectInvite:
        final projectName = n.payload['project_name'] as String? ?? 'a project';
        return '$actor invited you to $projectName';
      case NotificationType.contactLinkRequest:
        return '$actor wants to link as a contact';
      case NotificationType.unknown:
        return 'Notification';
    }
  }

  String? _subtitle(AppNotification n) {
    final amount = n.payload['amount'];
    if (amount is num) {
      final cur = (n.payload['currency'] as String?) ?? '';
      return '$cur ${amount.toStringAsFixed(2)}'.trim();
    }
    return null;
  }
}
