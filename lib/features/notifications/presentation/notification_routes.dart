import '../domain/notification.dart';

enum AcceptRoute {
  walletInvite,

  /// bill_invite: join the split bill.
  joinBill,

  /// bill_new: the bill form, where "ลงรายการของฉัน" lives.
  claimBill,

  /// bill_changed: my tx and debts of it take the bill as it is now.
  syncBill,

  /// bill_removed: delete my (now plain) books of it.
  deleteBooks,

  /// debt_repaid: quick create, the repayment prefilled.
  recordRepayment,
  projectInvite,
  extendRecurring,
  openDue,
  linkRequest,
}

enum RejectRoute {
  walletInvite,
  linkRequest,
  projectInvite,

  /// bill_invite: decline the split bill.
  declineBill,
  markActioned,
  dismiss,
}

AcceptRoute acceptRouteOf(NotificationType type) => switch (type) {
  NotificationType.accountInvite => AcceptRoute.walletInvite,
  NotificationType.billInvite => AcceptRoute.joinBill,
  NotificationType.billNew => AcceptRoute.claimBill,
  NotificationType.billChanged => AcceptRoute.syncBill,
  NotificationType.billRemoved => AcceptRoute.deleteBooks,
  NotificationType.debtRepaid => AcceptRoute.recordRepayment,
  NotificationType.projectInvite => AcceptRoute.projectInvite,
  NotificationType.recurringEnding => AcceptRoute.extendRecurring,
  NotificationType.recurringDue => AcceptRoute.openDue,
  _ => AcceptRoute.linkRequest,
};

RejectRoute rejectRouteOf(NotificationType type) => switch (type) {
  NotificationType.accountInvite => RejectRoute.walletInvite,
  NotificationType.contactLinkRequest => RejectRoute.linkRequest,
  NotificationType.projectInvite => RejectRoute.projectInvite,
  NotificationType.billInvite => RejectRoute.declineBill,
  // Keep my books / skip: the notice is answered, nothing else changes.
  NotificationType.billNew ||
  NotificationType.billChanged ||
  NotificationType.billRemoved ||
  NotificationType.debtRepaid ||
  NotificationType.recurringEnding => RejectRoute.markActioned,
  _ => RejectRoute.dismiss,
};

/// A bill's deep link (`/projects/{pid}/bills/{id}` or `/split-bills/{id}`)
/// opens the bill form, not a route; null = the link is a page.
({String id, String? projectId})? billOfLink(AppNotification n) {
  final parts = (n.deepLink ?? '').split('?').first.split('/');
  if (parts.length == 5 &&
      parts[1] == 'projects' &&
      parts[3] == 'bills' &&
      parts[4].isNotEmpty) {
    return (id: parts[4], projectId: parts[2]);
  }
  if (parts.length == 3 && parts[1] == 'split-bills' && parts[2].isNotEmpty) {
    return (id: parts[2], projectId: null);
  }
  return null;
}
