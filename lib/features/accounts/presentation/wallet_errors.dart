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
    case 'INVALID_IDENTIFIER':
      return l.walletErrorInvalidIdentifier;
    case 'USER_ALREADY_MEMBER':
      return l.walletErrorAlreadyMember;
    // adjust-balance to the balance it already has.
    case 'NO_OP':
      return l.accountAdjustBalanceNoChange;
    // adjust-balance on a wallet that does not track its balance.
    case 'BALANCE_NOT_TRACKED':
      return l.walletErrorBalanceNotTracked;
    case 'NOT_OWNER':
      return l.notOwnerError;
    // BALANCE_NOT_EDITABLE (400) has no localized copy yet — the BE's own
    // message shows.
    // The contact invite (POST /accounts/:id/members {contact_id}).
    case 'CONTACT_NOT_FOUND':
      return l.walletErrorContactNotFound;
    case 'CONTACT_ARCHIVED':
      return l.walletErrorContactArchived;
    case 'CONTACT_NOT_LINKED':
      return l.walletErrorContactNotLinked;
    default:
      return e.message;
  }
}
