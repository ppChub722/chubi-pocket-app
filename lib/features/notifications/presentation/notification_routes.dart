import '../domain/notification.dart';

enum AcceptRoute {
  walletInvite,

  /// A shared bill notice: my copy takes the bill as it is now (one call).
  applyBill,
  projectInvite,
  extendRecurring,
  openDue,
  linkRequest,
}

enum RejectRoute {
  walletInvite,
  linkRequest,
  projectInvite,
  markActioned,
  dismiss,
}

AcceptRoute acceptRouteOf(NotificationType type) => switch (type) {
  NotificationType.accountInvite => AcceptRoute.walletInvite,
  // split_created / split_changed are no longer sent (every split is a
  // shared bill, 0.4.1-2 S16); an old row has no bill id, so applyBill is a
  // no-op for it and its tile shows no button.
  NotificationType.sharedBillCreated ||
  NotificationType.sharedBillDeleted ||
  NotificationType.projectTxRecordedForYou ||
  NotificationType.projectTxChanged ||
  NotificationType.splitCreated ||
  NotificationType.splitChanged => AcceptRoute.applyBill,
  NotificationType.projectInvite => AcceptRoute.projectInvite,
  NotificationType.recurringEnding => AcceptRoute.extendRecurring,
  NotificationType.recurringDue => AcceptRoute.openDue,
  _ => AcceptRoute.linkRequest,
};

RejectRoute rejectRouteOf(NotificationType type) => switch (type) {
  NotificationType.accountInvite => RejectRoute.walletInvite,
  NotificationType.contactLinkRequest => RejectRoute.linkRequest,
  NotificationType.projectInvite => RejectRoute.projectInvite,
  NotificationType.recurringEnding => RejectRoute.markActioned,
  _ => RejectRoute.dismiss,
};

/// A shared bill's deep link `/event-bills/{id}` opens the one bill form
/// (not a route): its bill id, else null (the link is a page).
String? billOfLink(AppNotification n) {
  final link = n.deepLink;
  if (link == null || !link.startsWith('/event-bills/')) return null;
  final id = link.substring('/event-bills/'.length).split('?').first;
  return id.isEmpty ? null : id;
}
