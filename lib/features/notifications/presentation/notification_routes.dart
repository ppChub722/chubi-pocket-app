import '../domain/notification.dart';

enum AcceptRoute {
  walletInvite,
  split,
  copyToBook,
  updateCopy,
  splitChange,
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
  NotificationType.splitCreated => AcceptRoute.split,
  NotificationType.projectTxRecordedForYou => AcceptRoute.copyToBook,
  NotificationType.projectTxChanged => AcceptRoute.updateCopy,
  NotificationType.splitChanged => AcceptRoute.splitChange,
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
