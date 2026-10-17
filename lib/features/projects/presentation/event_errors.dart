import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';

/// An event write's refusal in plain words; the BE message otherwise.
String eventErrorText(AppLocalizations l, ApiException e) => switch (e.code) {
  'PROJECT_LOCKED' => l.eventErrLocked,
  'FORBIDDEN_ROLE' => l.eventErrNotOwner,
  'TAG_NAME_TAKEN' => l.eventErrTagTaken,
  'TAG_NOT_FOUND' => l.eventErrTagNotFound,
  'INVALID_DATE_RANGE' => l.eventDatesInvalid,
  'NO_SHARE_TO_COPY' => l.eventErrNoShare,
  'OWNER_CANNOT_LEAVE' => l.eventErrOwnerCannotLeave,
  'SPLITS_EXCEED_AMOUNT' => l.txSplitExceeds,
  _ => e.message,
};
