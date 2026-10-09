import '../../../l10n/gen/app_localizations.dart';
import '../domain/pending_transaction.dart';

/// A submit failure in words the user can act on; unknown codes fall back
/// to the server's message.
String pendingErrorText(AppLocalizations l, PendingError e) => switch (e.code) {
  'MISSING_TYPE' => l.pendingErrMissingType,
  'MISSING_AMOUNT' => l.pendingErrMissingAmount,
  'MISSING_DATE' => l.pendingErrMissingDate,
  'ACCOUNT_NOT_FOUND' => l.pendingErrAccount,
  'CATEGORY_NOT_FOUND' || 'CATEGORY_TYPE_MISMATCH' => l.pendingErrCategory,
  'TRANSFER_SAME_ACCOUNT' => l.txTransferSameWallet,
  'TRANSFER_NEEDS_WALLETS' => l.txTransferNeedsTo,
  'TRANSFER_CURRENCY_MISMATCH' => l.pendingErrCurrency,
  'TAG_NOT_FOUND' => l.pendingErrTag,
  'CONTACT_NOT_FOUND' => l.pendingErrContact,
  _ => e.message,
};
