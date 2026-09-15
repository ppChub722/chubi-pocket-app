import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';

/// Maps the shared-wallet error codes (API §14) to friendly localized
/// messages. Falls back to the backend's own message for unmapped codes
/// so nothing is ever swallowed.
///
/// One helper, every caller — members page, report-scope control,
/// archive flow, transaction form — so a code is never mapped twice
/// with two different wordings.
String walletErrorMessage(AppLocalizations l, ApiException e) {
  switch (e.code) {
    case 'NOT_MEMBER':
      return l.walletErrorNotMember;
    case 'OWNER_MUST_TRANSFER':
      return l.walletErrorOwnerMustTransfer;
    case 'ACCOUNT_HAS_MEMBERS':
      return l.walletErrorHasMembers;
    case 'CATEGORY_AUTHOR_ONLY':
      return l.walletErrorCategoryAuthorOnly;
    case 'ROW_LOCKED':
      return l.walletErrorRowLocked;
    case 'SCOPE_NOT_ALLOWED':
      return l.walletErrorScopeNotAllowed;
    case 'USER_NOT_FOUND':
      return l.walletErrorUserNotFound;
    case 'USER_ALREADY_MEMBER':
      return l.walletErrorAlreadyMember;
    default:
      return e.message;
  }
}
