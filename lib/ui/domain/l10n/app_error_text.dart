import 'package:flutter/widgets.dart' show BuildContext;

import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';

/// The ONE place an API error becomes Thai words (owner 2026-10-30).
///
/// Every code the BE registry can send (`apierr`, = the OpenAPI `Error`
/// enum) is either in [_specific] (its own sentence) or in [_groups] (one of
/// six shared sentences). A test fails when an OpenAPI code is in neither.
/// Presentation never shows `ApiException.message`: it is English, for logs.
enum ErrorGroup {
  /// The record is gone or was never yours.
  notFound,

  /// The caller may not do this.
  forbidden,

  /// The input is wrong; look at the fields.
  invalid,

  /// The record can't be edited or deleted.
  immutable,

  /// It already happened, or the state moved on; refresh.
  stale,

  /// The server failed; only retrying helps.
  server,
}

String _groupText(AppLocalizations l, ErrorGroup g) => switch (g) {
  ErrorGroup.notFound => l.errNotFound,
  ErrorGroup.forbidden => l.errForbidden,
  ErrorGroup.invalid => l.errorValidationMessage,
  ErrorGroup.immutable => l.errImmutable,
  ErrorGroup.stale => l.errStale,
  ErrorGroup.server => l.errorGenericMessage,
};

/// Codes with a sentence of their own.
final Map<String, String Function(AppLocalizations l)> _specific = {
  // auth / users
  'UNAUTHORIZED': (l) => l.errSessionExpired,
  'APP_OUTDATED': (l) => l.errAppOutdated,
  'INVALID_CREDENTIALS': (l) => l.authLoginInvalidCredentials,
  'WRONG_PASSWORD': (l) => l.changePasswordCurrentWrong,
  'EMAIL_EXISTS': (l) => l.authRegisterEmailTaken,
  'USERNAME_EXISTS': (l) => l.authRegisterUsernameTaken,
  'ACCOUNT_INACTIVE': (l) => l.errAccountInactive,
  'AVATAR_SOURCE_UNAVAILABLE': (l) => l.errAvatarSource,
  'CURRENCY_LOCKED': (l) => l.errCurrencyLocked,
  'REGISTRATION_CLOSED': (l) => l.authRegistrationClosed,
  'TELEGRAM_ALREADY_LINKED': (l) => l.authTelegramAlreadyLinked,
  'CONNECTION_UNAVAILABLE': (l) => l.authTelegramUnavailable,
  'LOGIN_CODE_INVALID': (l) => l.errLoginCodeInvalid,
  'RATE_LIMITED': (l) => l.errRateLimited,
  'IDEMPOTENCY_IN_PROGRESS': (l) => l.errSaveInProgress,
  'PERMISSION_UNAVAILABLE': (l) => l.errPermissionUnavailable,
  'NO_PHOTO': (l) => l.errNoPhoto,
  'LAST_LOGIN_METHOD': (l) => l.connectionsErrorLastLoginMethod,
  'PROVIDER_ERROR': (l) => l.errProvider,
  // wallets
  'ACCOUNT_HAS_MEMBERS': (l) => l.walletErrorHasMembers,
  'OWNER_MUST_TRANSFER': (l) => l.walletErrorOwnerMustTransfer,
  'USER_ALREADY_MEMBER': (l) => l.walletErrorAlreadyMember,
  'USER_NOT_FOUND': (l) => l.walletErrorUserNotFound,
  'NOT_OWNER': (l) => l.notOwnerError,
  'SCOPE_NOT_ALLOWED': (l) => l.walletErrorScopeNotAllowed,
  'INVALID_IDENTIFIER': (l) => l.walletErrorInvalidIdentifier,
  'BALANCE_NOT_TRACKED': (l) => l.walletErrorBalanceNotTracked,
  'WALLET_NOT_TRACKED': (l) => l.walletErrorBalanceNotTracked,
  'NO_OP': (l) => l.accountAdjustBalanceNoChange,
  'ROW_LOCKED': (l) => l.walletErrorRowLocked,
  'CONTACT_NOT_LINKED': (l) => l.walletErrorContactNotLinked,
  // categories / tags
  'CATEGORY_NAME_DUPLICATE': (l) => l.errCategoryNameDuplicate,
  'CYCLE_DETECTED': (l) => l.errCategoryCycle,
  'MAX_DEPTH_EXCEEDED': (l) => l.categoryErrorMaxDepth,
  'CATEGORY_AUTHOR_ONLY': (l) => l.walletErrorCategoryAuthorOnly,
  'CATEGORY_TYPE_MISMATCH': (l) => l.pendingErrCategory,
  'CATEGORY_NOT_FOUND': (l) => l.pendingErrCategory,
  'TAG_EXISTS': (l) => l.errTagExists,
  'TAG_NAME_TAKEN': (l) => l.eventErrTagTaken,
  // transactions
  'TRANSFER_SAME_ACCOUNT': (l) => l.txTransferSameWallet,
  'TRANSFER_NEEDS_WALLETS': (l) => l.txTransferNeedsTo,
  'SPLITS_AUTHOR_ONLY': (l) => l.txSplitAuthorOnly,
  'SPLITS_EXCEED_AMOUNT': (l) => l.txSplitExceeds,
  'SPLITS_EXCEED_SHARE': (l) => l.txSplitExceedsShare,
  'PAID_BY_EXCEEDS_AMOUNT': (l) => l.errPaidByExceeds,
  'TX_NOT_BILLABLE': (l) => l.quickCreateErrorNotBillable,
  'TX_ALREADY_IN_PROJECT': (l) => l.quickCreateErrorTxAlreadyInProject,
  'TX_SPLIT_PAID': (l) => l.txEventSplitRepaid,
  'TX_NOT_FOUND': (l) => l.quickCreateErrorTxNotFound,
  // debts / contacts
  'CONTACT_NOT_FOUND': (l) => l.walletErrorContactNotFound,
  'CONTACT_ARCHIVED': (l) => l.walletErrorContactArchived,
  'CANNOT_LINK_SELF': (l) => l.errCannotLinkSelf,
  'NOTHING_OWED': (l) => l.occurrenceNothingOwed,
  'ITEM_ALREADY_LINKED': (l) => l.recurringLinkAlreadyLinked,
  // events
  'PROJECT_LOCKED': (l) => l.eventErrLocked,
  'FORBIDDEN_ROLE': (l) => l.eventErrNotOwner,
  'INVALID_DATE_RANGE': (l) => l.eventDatesInvalid,
  'NO_SHARE_TO_COPY': (l) => l.eventErrNoShare,
  'NO_SHARE': (l) => l.eventErrNoShare,
  'OWNER_CANNOT_LEAVE': (l) => l.eventErrOwnerCannotLeave,
  'EVENT_COMPLETED': (l) => l.eventErrCompleted,
  'PROJECT_NOT_ACTIVE': (l) => l.eventErrNotActive,
  'EVENT_HAS_EMPTY_PERSON': (l) => l.eventErrEmptyPerson,
  'BILL_CHANGED': (l) => l.errBillChanged,
  'BILL_GONE': (l) => l.notifBillGone,
  'BILL_DISCONNECTED': (l) => l.notifBillDisconnectedMine,
  'PAYERS_SUM': (l) => l.errPayersSum,
  // recurring / budgets / saving goals
  'END_TOO_FAR': (l) => l.errEndTooFar,
  'AMOUNT_REQUIRED': (l) => l.errAmountRequired,
  'INSUFFICIENT_SAVING': (l) => l.errInsufficientSaving,
  'GOAL_NOT_ACTIVE': (l) => l.errGoalNotActive,
  'GOAL_REACHED': (l) => l.errGoalReached,
  'GOAL_HAS_SAVINGS': (l) => l.errGoalHasSavings,
  // imports / pending drafts
  'UNSUPPORTED_IMAGE': (l) => l.errUnsupportedImage,
  'OCR_UNAVAILABLE': (l) => l.errOcrUnavailable,
  'OCR_TIMEOUT': (l) => l.errOcrTimeout,
  'MISSING_TYPE': (l) => l.pendingErrMissingType,
  'MISSING_AMOUNT': (l) => l.pendingErrMissingAmount,
  'MISSING_DATE': (l) => l.pendingErrMissingDate,
  'MISSING_ACCOUNT': (l) => l.pendingErrAccount,
  'ACCOUNT_NOT_FOUND': (l) => l.pendingErrAccount,
  'INVALID_SPLIT': (l) => l.txSplitIncompleteTitle,
  'TRANSFER_CURRENCY_MISMATCH': (l) => l.pendingErrCurrency,
};

/// Codes that share a sentence.
const Map<String, ErrorGroup> _groups = {
  // general
  'VALIDATION_ERROR': ErrorGroup.invalid,
  'FORBIDDEN': ErrorGroup.forbidden,
  'NOT_FOUND': ErrorGroup.notFound,
  'INTERNAL_SERVER_ERROR': ErrorGroup.server,
  'INTERNAL_ERROR': ErrorGroup.server,
  'SUBMIT_FAILED': ErrorGroup.server,
  // not found
  'TRANSACTION_NOT_FOUND': ErrorGroup.notFound,
  'TAG_NOT_FOUND': ErrorGroup.notFound,
  'SOURCE_PT_NOT_FOUND': ErrorGroup.notFound,
  'ENTRY_NOT_FOUND': ErrorGroup.notFound,
  'BILL_NOT_FOUND': ErrorGroup.notFound,
  'DEBT_NOT_FOUND': ErrorGroup.notFound,
  'PROJECT_NOT_FOUND': ErrorGroup.notFound,
  'TX_NOT_IN_PROJECT': ErrorGroup.notFound,
  'MEMBER_NOT_IN_PROJECT': ErrorGroup.notFound,
  'NOT_IN_BILL': ErrorGroup.notFound,
  // forbidden
  'NOT_MEMBER': ErrorGroup.forbidden,
  'DEBT_TX_AUTHOR_ONLY': ErrorGroup.forbidden,
  'SOURCE_PT_NOT_FOR_USER': ErrorGroup.forbidden,
  'NOT_FOR_YOU': ErrorGroup.forbidden,
  'PROJECT_NOT_MEMBER': ErrorGroup.forbidden,
  'PROJECT_READ_ONLY': ErrorGroup.forbidden,
  // invalid input
  'INVALID_PARENT': ErrorGroup.invalid,
  'INVALID_CATEGORY': ErrorGroup.invalid,
  'INVALID_PAID_BY': ErrorGroup.invalid,
  'INVALID_PERSON_KEY': ErrorGroup.invalid,
  'INVALID_BILL_PEOPLE': ErrorGroup.invalid,
  'INVALID_RULE': ErrorGroup.invalid,
  'SYSTEM_CATEGORY_NOT_ALLOWED': ErrorGroup.invalid,
  'SPLITS_NOT_SUPPORTED_YET': ErrorGroup.invalid,
  'SPLITS_ON_TRANSFER': ErrorGroup.invalid,
  'SPLIT_MISMATCH': ErrorGroup.invalid,
  'PAID_BY_EXPENSE_ONLY': ErrorGroup.invalid,
  'LINK_MODE_CONFLICT': ErrorGroup.invalid,
  'LINK_MODE_INPUT': ErrorGroup.invalid,
  'PRIVATE_NOTE_NOT_SHARED': ErrorGroup.invalid,
  'BALANCE_NOT_EDITABLE': ErrorGroup.invalid,
  'USE_CLAIM': ErrorGroup.invalid,
  'USE_COMPLETE_ENDPOINT': ErrorGroup.invalid,
  'MOVE_TARGET': ErrorGroup.invalid,
  'PAYER_FIXED': ErrorGroup.invalid,
  'BAD_PAYBACK': ErrorGroup.invalid,
  'PAYBACK_NOT_COPYABLE': ErrorGroup.invalid,
  'SELF_SPLIT': ErrorGroup.invalid,
  'CLAIM_MIXED_DIRECTION': ErrorGroup.invalid,
  'SETTLE_LINES': ErrorGroup.invalid,
  'SAVING_NEEDS_WALLET': ErrorGroup.invalid,
  'LEDGER_ONLY_NO_WALLET': ErrorGroup.invalid,
  'TAGS_NEED_WALLET': ErrorGroup.invalid,
  'DEBT_TX_NEEDS_WALLET': ErrorGroup.invalid,
  'TX_NOT_LINKABLE': ErrorGroup.invalid,
  'NOT_PROJECT_INVITE': ErrorGroup.invalid,
  'TYPE_NOT_MUTABLE': ErrorGroup.invalid,
  'OVERPAYMENT': ErrorGroup.invalid,
  'IDEMPOTENCY_KEY_REUSED': ErrorGroup.invalid,
  // can't be edited or deleted
  'ACCOUNT_ARCHIVED': ErrorGroup.immutable,
  'SYSTEM_CATEGORY_IMMUTABLE': ErrorGroup.immutable,
  'SYSTEM_TRANSACTION_IMMUTABLE': ErrorGroup.immutable,
  'ENTRY_MANAGED_BY_SOURCE': ErrorGroup.immutable,
  'ENTRY_HAS_TRANSACTION': ErrorGroup.immutable,
  'DEBT_MANAGED_BY_TX': ErrorGroup.immutable,
  'SHARED_BILL_FIELD': ErrorGroup.immutable,
  'TX_NOT_DISCONNECTABLE': ErrorGroup.immutable,
  'CANNOT_CHANGE_OWNER': ErrorGroup.immutable,
  'CANNOT_REMOVE_OWNER': ErrorGroup.immutable,
  'PT_IS_CHILD': ErrorGroup.immutable,
  // already done / state moved on
  'ALREADY_ACTIVE': ErrorGroup.stale,
  'ALREADY_ARCHIVED': ErrorGroup.stale,
  'NOT_ARCHIVED': ErrorGroup.stale,
  'ALREADY_LINKED': ErrorGroup.stale,
  'NOT_LINKED': ErrorGroup.stale,
  'REQUEST_REJECTED': ErrorGroup.stale,
  'NOT_ACCEPTED': ErrorGroup.stale,
  'STATE_CONFLICT': ErrorGroup.stale,
  'NOTIFICATION_STATE_CONFLICT': ErrorGroup.stale,
  'DEBT_NOT_LINKED': ErrorGroup.stale,
  'DEBT_TX_ALREADY_LINKED': ErrorGroup.stale,
  'EVENT_NOT_COMPLETED': ErrorGroup.stale,
  'ALREADY_MEMBER': ErrorGroup.stale,
  'MEMBER_NOT_REMOVED': ErrorGroup.stale,
  'NOT_PENDING': ErrorGroup.stale,
  'BILL_ALREADY_BOOKED': ErrorGroup.stale,
  'SETTLE_BOOKED': ErrorGroup.stale,
  'ALREADY_RECORDED': ErrorGroup.stale,
  'INVALID_TRANSITION': ErrorGroup.stale,
  'DEBT_ALREADY_SETTLED': ErrorGroup.stale,
  // client-side codes (ApiException.fromDioException / from)
  'REQUEST_CANCELLED': ErrorGroup.server,
  'UNKNOWN_ERROR': ErrorGroup.server,
  'UNEXPECTED_ERROR': ErrorGroup.server,
};

/// Client-side network codes: worded by [AppLocalizations.errorNetworkMessage].
const _networkCodes = {'NETWORK_ERROR', 'NETWORK_TIMEOUT'};

/// Every code this mapper words; the OpenAPI `Error` enum must be inside
/// (test/ui/app_error_text_test.dart).
Set<String> get mappedErrorCodes => {
  ..._specific.keys,
  ..._groups.keys,
  ..._networkCodes,
};

/// The sentence for an error code. An unknown code falls back on the HTTP
/// status class, then on the generic "try again".
String errorTextForCode(AppLocalizations l, String code, {int? statusCode}) {
  if (_networkCodes.contains(code)) return l.errorNetworkMessage;
  final specific = _specific[code];
  if (specific != null) return specific(l);
  final group = _groups[code] ?? _groupOfStatus(statusCode);
  return _groupText(l, group);
}

ErrorGroup _groupOfStatus(int? status) => switch (status) {
  404 || 410 => ErrorGroup.notFound,
  401 || 403 => ErrorGroup.forbidden,
  400 || 422 => ErrorGroup.invalid,
  409 => ErrorGroup.stale,
  _ => ErrorGroup.server,
};

/// The sentence for any thrown value: an [ApiException] by code, a network
/// failure or timeout as "no connection", anything else as "try again".
String errorText(AppLocalizations l, Object error) {
  if (isNetworkError(error)) return l.errorNetworkMessage;
  if (error is ApiException) {
    return errorTextForCode(l, error.code, statusCode: error.statusCode);
  }
  return l.errorGenericMessage;
}

/// [errorText] for a build context (page code that has no messages handy).
String errorTextOf(BuildContext context, Object error) =>
    errorText(AppLocalizations.of(context)!, error);
