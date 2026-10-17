import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';

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
    case 'NO_OP':
      return l.accountAdjustBalanceNoChange;
    case 'BALANCE_NOT_TRACKED':
      return l.walletErrorBalanceNotTracked;
    case 'NOT_OWNER':
      return l.notOwnerError;
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
