import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';

/// An event write's refusal in plain words; the BE message otherwise.
String eventErrorText(AppLocalizations l, ApiException e) => switch (e.code) {
  // 409: cancelled / archived (or completed for new bills).
  'PROJECT_LOCKED' => l.eventErrLocked,
  // 403: owner-only (edit, status, members, delete).
  'FORBIDDEN_ROLE' => l.eventErrNotOwner,
  'TAG_NAME_TAKEN' => l.eventErrTagTaken,
  'TAG_NOT_FOUND' => l.eventErrTagNotFound,
  'INVALID_DATE_RANGE' => l.eventDatesInvalid,
  // 422: copying a bill I have no share in.
  'NO_SHARE_TO_COPY' => l.eventErrNoShare,
  'OWNER_CANNOT_LEAVE' => l.eventErrOwnerCannotLeave,
  // 400: a linked amount below the splits on the board.
  'SPLITS_EXCEED_AMOUNT' => l.txSplitExceeds,
  _ => e.message,
};
