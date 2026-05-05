import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('th'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'chubiPocket'**
  String get appName;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get commonRemove;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonBack.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get commonBack;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @errorNetworkTitle.
  ///
  /// In en, this message translates to:
  /// **'No connection'**
  String get errorNetworkTitle;

  /// No description provided for @errorNetworkMessage.
  ///
  /// In en, this message translates to:
  /// **'Check your internet and try again.'**
  String get errorNetworkMessage;

  /// No description provided for @errorServerTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorServerTitle;

  /// No description provided for @errorServerMessage.
  ///
  /// In en, this message translates to:
  /// **'Our servers had a hiccup. Please try again.'**
  String get errorServerMessage;

  /// No description provided for @errorUnknownTitle.
  ///
  /// In en, this message translates to:
  /// **'Unexpected error'**
  String get errorUnknownTitle;

  /// No description provided for @errorUnknownMessage.
  ///
  /// In en, this message translates to:
  /// **'Something we did not expect happened. Please try again.'**
  String get errorUnknownMessage;

  /// No description provided for @errorBannerNoConnection.
  ///
  /// In en, this message translates to:
  /// **'No connection. Check your internet.'**
  String get errorBannerNoConnection;

  /// No description provided for @errorBannerNoConnectionShort.
  ///
  /// In en, this message translates to:
  /// **'No connection. Try again.'**
  String get errorBannerNoConnectionShort;

  /// No description provided for @offlineBanner.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline'**
  String get offlineBanner;

  /// No description provided for @authLoginTitle.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLoginTitle;

  /// No description provided for @authLoginIdentifierLabel.
  ///
  /// In en, this message translates to:
  /// **'Username or email'**
  String get authLoginIdentifierLabel;

  /// No description provided for @authLoginPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authLoginPasswordLabel;

  /// No description provided for @authLoginSubmit.
  ///
  /// In en, this message translates to:
  /// **'Log in'**
  String get authLoginSubmit;

  /// No description provided for @authLoginInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Username or password incorrect'**
  String get authLoginInvalidCredentials;

  /// No description provided for @authLoginGoToRegister.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get authLoginGoToRegister;

  /// No description provided for @authRegisterTitle.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authRegisterTitle;

  /// No description provided for @authRegisterUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get authRegisterUsernameLabel;

  /// No description provided for @authRegisterUsernameInvalid.
  ///
  /// In en, this message translates to:
  /// **'3–50 chars; lowercase a–z, 0–9, _, -'**
  String get authRegisterUsernameInvalid;

  /// No description provided for @authRegisterDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get authRegisterDisplayNameLabel;

  /// No description provided for @authRegisterDisplayNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Max 100 characters'**
  String get authRegisterDisplayNameTooLong;

  /// No description provided for @authRegisterEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get authRegisterEmailLabel;

  /// No description provided for @authRegisterPasswordLabel.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authRegisterPasswordLabel;

  /// No description provided for @authRegisterPasswordTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authRegisterPasswordTooShort;

  /// No description provided for @authRegisterPasswordTooLong.
  ///
  /// In en, this message translates to:
  /// **'Max 128 characters'**
  String get authRegisterPasswordTooLong;

  /// No description provided for @authRegisterConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authRegisterConfirmLabel;

  /// No description provided for @authRegisterConfirmMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get authRegisterConfirmMismatch;

  /// No description provided for @authRegisterCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get authRegisterCurrencyLabel;

  /// No description provided for @authRegisterSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authRegisterSubmit;

  /// No description provided for @authRegisterGoToLogin.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Log in'**
  String get authRegisterGoToLogin;

  /// No description provided for @authRegisterUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'That username is already taken.'**
  String get authRegisterUsernameTaken;

  /// No description provided for @authRegisterEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'That email is already registered.'**
  String get authRegisterEmailTaken;

  /// No description provided for @authRegisterFixErrors.
  ///
  /// In en, this message translates to:
  /// **'Please fix the errors below.'**
  String get authRegisterFixErrors;

  /// No description provided for @authRegisterUsernameTakenInline.
  ///
  /// In en, this message translates to:
  /// **'Already taken'**
  String get authRegisterUsernameTakenInline;

  /// No description provided for @authRegisterEmailTakenInline.
  ///
  /// In en, this message translates to:
  /// **'Already registered'**
  String get authRegisterEmailTakenInline;

  /// No description provided for @homeEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet'**
  String get homeEmptyTitle;

  /// No description provided for @homeEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add an account from the Accounts tab, then tap the + button to log your first transaction.'**
  String get homeEmptyMessage;

  /// No description provided for @homeNetWorthLabel.
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get homeNetWorthLabel;

  /// No description provided for @homeNetWorthAccountCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 account} other{{count} accounts}}'**
  String homeNetWorthAccountCount(int count);

  /// No description provided for @homeRecentTitle.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get homeRecentTitle;

  /// No description provided for @homeRecentViewAll.
  ///
  /// In en, this message translates to:
  /// **'View all'**
  String get homeRecentViewAll;

  /// No description provided for @homeSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get homeSettingsTooltip;

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @navTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get navTransactions;

  /// No description provided for @navAccounts.
  ///
  /// In en, this message translates to:
  /// **'Accounts'**
  String get navAccounts;

  /// No description provided for @navAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get navAddTransaction;

  /// No description provided for @navProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get navProjects;

  /// No description provided for @navMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// No description provided for @navNotificationsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get navNotificationsTooltip;

  /// No description provided for @navProfileTooltip.
  ///
  /// In en, this message translates to:
  /// **'Profile & settings'**
  String get navProfileTooltip;

  /// No description provided for @addTransactionComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Logging transactions ships in Phase 1a'**
  String get addTransactionComingSoon;

  /// No description provided for @notificationsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'The notifications inbox ships in Phase 1b'**
  String get notificationsComingSoon;

  /// No description provided for @accountsPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'No accounts yet'**
  String get accountsPlaceholderTitle;

  /// No description provided for @accountsPlaceholderMessage.
  ///
  /// In en, this message translates to:
  /// **'Adding accounts ships in Phase 1a.'**
  String get accountsPlaceholderMessage;

  /// No description provided for @accountsAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add account'**
  String get accountsAddNew;

  /// No description provided for @accountTypeCash.
  ///
  /// In en, this message translates to:
  /// **'Cash'**
  String get accountTypeCash;

  /// No description provided for @accountTypeBank.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get accountTypeBank;

  /// No description provided for @accountTypeEWallet.
  ///
  /// In en, this message translates to:
  /// **'E-wallet'**
  String get accountTypeEWallet;

  /// No description provided for @accountTypeCreditCard.
  ///
  /// In en, this message translates to:
  /// **'Credit card'**
  String get accountTypeCreditCard;

  /// No description provided for @accountTypePayLater.
  ///
  /// In en, this message translates to:
  /// **'Pay later'**
  String get accountTypePayLater;

  /// No description provided for @accountCreditUsedPercent.
  ///
  /// In en, this message translates to:
  /// **'{percent}% used'**
  String accountCreditUsedPercent(int percent);

  /// No description provided for @accountDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Account not found'**
  String get accountDetailNotFound;

  /// No description provided for @accountDetailNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This account may have been archived or deleted.'**
  String get accountDetailNotFoundMessage;

  /// No description provided for @accountDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get accountDetailEdit;

  /// No description provided for @accountDetailAdjustBalance.
  ///
  /// In en, this message translates to:
  /// **'Adjust balance'**
  String get accountDetailAdjustBalance;

  /// No description provided for @accountDetailArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get accountDetailArchive;

  /// No description provided for @accountDetailActionComingSoon.
  ///
  /// In en, this message translates to:
  /// **'This action ships in Phase 1a'**
  String get accountDetailActionComingSoon;

  /// No description provided for @accountDetailCreditAvailable.
  ///
  /// In en, this message translates to:
  /// **'{available} available of {limit}'**
  String accountDetailCreditAvailable(String available, String limit);

  /// No description provided for @accountDetailSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get accountDetailSummaryTitle;

  /// No description provided for @accountDetailSummaryIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get accountDetailSummaryIncome;

  /// No description provided for @accountDetailSummaryExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get accountDetailSummaryExpense;

  /// No description provided for @accountDetailSummaryNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get accountDetailSummaryNet;

  /// No description provided for @accountDetailSummaryTransactions.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No transactions} =1{1 transaction} other{{count} transactions}}'**
  String accountDetailSummaryTransactions(int count);

  /// No description provided for @accountDetailBillingTitle.
  ///
  /// In en, this message translates to:
  /// **'Billing'**
  String get accountDetailBillingTitle;

  /// No description provided for @accountDetailStatementDate.
  ///
  /// In en, this message translates to:
  /// **'Statement date'**
  String get accountDetailStatementDate;

  /// No description provided for @accountDetailPaymentDue.
  ///
  /// In en, this message translates to:
  /// **'Payment due'**
  String get accountDetailPaymentDue;

  /// No description provided for @accountDetailMinimumPayment.
  ///
  /// In en, this message translates to:
  /// **'Minimum payment'**
  String get accountDetailMinimumPayment;

  /// No description provided for @accountDetailDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'{day} of every month'**
  String accountDetailDayOfMonth(int day);

  /// No description provided for @accountDetailTransactionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get accountDetailTransactionsTitle;

  /// No description provided for @accountDetailTransactionsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get accountDetailTransactionsEmptyTitle;

  /// No description provided for @accountDetailTransactionsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Logging transactions ships in Phase 1a.'**
  String get accountDetailTransactionsEmptyMessage;

  /// No description provided for @accountFormTitle.
  ///
  /// In en, this message translates to:
  /// **'New account'**
  String get accountFormTitle;

  /// No description provided for @accountFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit account'**
  String get accountFormTitleEdit;

  /// No description provided for @accountFormSaveEdit.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get accountFormSaveEdit;

  /// No description provided for @accountFormPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get accountFormPreviewLabel;

  /// No description provided for @accountFormTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get accountFormTypeLabel;

  /// No description provided for @accountFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Account name'**
  String get accountFormNameLabel;

  /// No description provided for @accountFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get accountFormNameRequired;

  /// No description provided for @accountFormNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Max 100 characters'**
  String get accountFormNameTooLong;

  /// No description provided for @accountFormIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get accountFormIconLabel;

  /// No description provided for @accountFormColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get accountFormColorLabel;

  /// No description provided for @accountFormUploadLogo.
  ///
  /// In en, this message translates to:
  /// **'Upload custom logo (Phase 2)'**
  String get accountFormUploadLogo;

  /// No description provided for @accountFormBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get accountFormBalanceLabel;

  /// No description provided for @accountFormBalanceHelper.
  ///
  /// In en, this message translates to:
  /// **'Money already in this account on the day you start tracking.'**
  String get accountFormBalanceHelper;

  /// No description provided for @accountFormCreditSection.
  ///
  /// In en, this message translates to:
  /// **'Credit details'**
  String get accountFormCreditSection;

  /// No description provided for @accountFormCreditLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Credit limit'**
  String get accountFormCreditLimitLabel;

  /// No description provided for @accountFormCreditLimitRequired.
  ///
  /// In en, this message translates to:
  /// **'Required for credit accounts'**
  String get accountFormCreditLimitRequired;

  /// No description provided for @accountFormStatementDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Statement date'**
  String get accountFormStatementDateLabel;

  /// No description provided for @accountFormStatementDateHelper.
  ///
  /// In en, this message translates to:
  /// **'Day of month (1–31)'**
  String get accountFormStatementDateHelper;

  /// No description provided for @accountFormPaymentDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment due'**
  String get accountFormPaymentDueLabel;

  /// No description provided for @accountFormPaymentDueHelper.
  ///
  /// In en, this message translates to:
  /// **'Day of month (1–31)'**
  String get accountFormPaymentDueHelper;

  /// No description provided for @accountFormMinimumPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum payment'**
  String get accountFormMinimumPaymentLabel;

  /// No description provided for @accountFormDayInvalid.
  ///
  /// In en, this message translates to:
  /// **'Must be 1–31'**
  String get accountFormDayInvalid;

  /// No description provided for @accountFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save account'**
  String get accountFormSave;

  /// No description provided for @accountFormDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard new account?'**
  String get accountFormDiscardTitle;

  /// No description provided for @accountFormDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your changes will be lost.'**
  String get accountFormDiscardBody;

  /// No description provided for @accountFormDiscardTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get accountFormDiscardTitleEdit;

  /// No description provided for @accountAdjustBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust balance'**
  String get accountAdjustBalanceTitle;

  /// No description provided for @accountAdjustBalanceBody.
  ///
  /// In en, this message translates to:
  /// **'Set a new balance. The difference will be recorded as an Adjustment transaction so the history stays consistent.'**
  String get accountAdjustBalanceBody;

  /// No description provided for @accountAdjustBalanceCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get accountAdjustBalanceCurrentLabel;

  /// No description provided for @accountAdjustBalanceNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New balance'**
  String get accountAdjustBalanceNewLabel;

  /// No description provided for @accountAdjustBalanceNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get accountAdjustBalanceNoteLabel;

  /// No description provided for @accountAdjustBalanceInvalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter a number'**
  String get accountAdjustBalanceInvalidAmount;

  /// No description provided for @accountAdjustBalanceNoChange.
  ///
  /// In en, this message translates to:
  /// **'New balance must differ from the current balance.'**
  String get accountAdjustBalanceNoChange;

  /// No description provided for @accountAdjustBalanceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Adjust'**
  String get accountAdjustBalanceConfirm;

  /// No description provided for @accountArchiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this account?'**
  String get accountArchiveConfirmTitle;

  /// No description provided for @accountArchiveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The account will be hidden from the active list. Its transactions stay intact and remain referenced.'**
  String get accountArchiveConfirmBody;

  /// No description provided for @accountArchiveConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get accountArchiveConfirmAction;

  /// No description provided for @accountFormCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get accountFormCurrencyLabel;

  /// No description provided for @accountFormCurrencyPhase2.
  ///
  /// In en, this message translates to:
  /// **'Multi-currency ships in Phase 2'**
  String get accountFormCurrencyPhase2;

  /// No description provided for @accountFormPhase2Badge.
  ///
  /// In en, this message translates to:
  /// **'Phase 2'**
  String get accountFormPhase2Badge;

  /// No description provided for @accountFormDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get accountFormDescriptionLabel;

  /// No description provided for @accountFormDescriptionHelper.
  ///
  /// In en, this message translates to:
  /// **'What this account is for. Visible to you only.'**
  String get accountFormDescriptionHelper;

  /// No description provided for @accountFormDescriptionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Max 200 characters'**
  String get accountFormDescriptionTooLong;

  /// No description provided for @accountFormNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get accountFormNoteLabel;

  /// No description provided for @accountFormNoteHelper.
  ///
  /// In en, this message translates to:
  /// **'Personal scratch note (e.g. \"Travel money for Japan trip\").'**
  String get accountFormNoteHelper;

  /// No description provided for @accountFormNoteTooLong.
  ///
  /// In en, this message translates to:
  /// **'Max 200 characters'**
  String get accountFormNoteTooLong;

  /// No description provided for @iconPickerSectionStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get iconPickerSectionStyle;

  /// No description provided for @iconPickerSectionColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get iconPickerSectionColor;

  /// No description provided for @iconPickerUseThis.
  ///
  /// In en, this message translates to:
  /// **'Use this'**
  String get iconPickerUseThis;

  /// No description provided for @iconPickerRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get iconPickerRemove;

  /// No description provided for @iconPickerUploadComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Upload (Phase 2)'**
  String get iconPickerUploadComingSoon;

  /// No description provided for @iconPickerCropComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Crop (Phase 2)'**
  String get iconPickerCropComingSoon;

  /// No description provided for @projectsPlaceholderTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get projectsPlaceholderTitle;

  /// No description provided for @projectsPlaceholderMessage.
  ///
  /// In en, this message translates to:
  /// **'Shared projects ship in Phase 1b.'**
  String get projectsPlaceholderMessage;

  /// No description provided for @moreSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get moreSheetTitle;

  /// No description provided for @morePhase1aHeader.
  ///
  /// In en, this message translates to:
  /// **'Phase 1a — coming soon'**
  String get morePhase1aHeader;

  /// No description provided for @morePhase1bHeader.
  ///
  /// In en, this message translates to:
  /// **'Phase 1b — coming soon'**
  String get morePhase1bHeader;

  /// No description provided for @morePhase1cHeader.
  ///
  /// In en, this message translates to:
  /// **'Phase 1c — coming soon'**
  String get morePhase1cHeader;

  /// No description provided for @moreTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get moreTransactions;

  /// No description provided for @moreCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get moreCategories;

  /// No description provided for @moreProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get moreProjects;

  /// No description provided for @moreTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get moreTags;

  /// No description provided for @moreContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get moreContacts;

  /// No description provided for @moreDebts.
  ///
  /// In en, this message translates to:
  /// **'Debts'**
  String get moreDebts;

  /// No description provided for @moreNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get moreNotifications;

  /// No description provided for @moreBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get moreBudgets;

  /// No description provided for @moreSavingGoals.
  ///
  /// In en, this message translates to:
  /// **'Saving goals'**
  String get moreSavingGoals;

  /// No description provided for @moreScheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled transactions'**
  String get moreScheduled;

  /// No description provided for @moreComingSoonBadge.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get moreComingSoonBadge;

  /// No description provided for @moreComingInPhase1a.
  ///
  /// In en, this message translates to:
  /// **'Ships in Phase 1a'**
  String get moreComingInPhase1a;

  /// No description provided for @moreComingInPhase1b.
  ///
  /// In en, this message translates to:
  /// **'Ships in Phase 1b'**
  String get moreComingInPhase1b;

  /// No description provided for @moreComingInPhase1c.
  ///
  /// In en, this message translates to:
  /// **'Ships in Phase 1c'**
  String get moreComingInPhase1c;

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

  /// No description provided for @categoriesSectionExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get categoriesSectionExpense;

  /// No description provided for @categoriesSectionIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get categoriesSectionIncome;

  /// No description provided for @categoriesEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No categories yet'**
  String get categoriesEmptyTitle;

  /// No description provided for @categoriesEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first category to start organizing transactions.'**
  String get categoriesEmptyMessage;

  /// No description provided for @categoriesLimitReached.
  ///
  /// In en, this message translates to:
  /// **'100-category limit reached. Archive or delete one to add another.'**
  String get categoriesLimitReached;

  /// No description provided for @categoryTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get categoryTypeExpense;

  /// No description provided for @categoryTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get categoryTypeIncome;

  /// No description provided for @categoryHiddenFromReport.
  ///
  /// In en, this message translates to:
  /// **'Hidden from reports'**
  String get categoryHiddenFromReport;

  /// No description provided for @categoryFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get categoryFormTitleNew;

  /// No description provided for @categoryFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get categoryFormTitleEdit;

  /// No description provided for @categoryFormBadge.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get categoryFormBadge;

  /// No description provided for @categoryFormPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get categoryFormPreviewLabel;

  /// No description provided for @categoryFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get categoryFormNameLabel;

  /// No description provided for @categoryFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get categoryFormNameRequired;

  /// No description provided for @categoryFormNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Max 100 characters'**
  String get categoryFormNameTooLong;

  /// No description provided for @categoryFormNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Another category at this level already uses this name'**
  String get categoryFormNameDuplicate;

  /// No description provided for @categoryFormTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get categoryFormTypeLabel;

  /// No description provided for @categoryFormTypeImmutableHelper.
  ///
  /// In en, this message translates to:
  /// **'Type can\'t be changed after creation. Delete and recreate to switch.'**
  String get categoryFormTypeImmutableHelper;

  /// No description provided for @categoryFormParentLabel.
  ///
  /// In en, this message translates to:
  /// **'Parent'**
  String get categoryFormParentLabel;

  /// No description provided for @categoryFormParentNone.
  ///
  /// In en, this message translates to:
  /// **'(None — top level)'**
  String get categoryFormParentNone;

  /// No description provided for @categoryFormParentDepthHint.
  ///
  /// In en, this message translates to:
  /// **'Categories can nest up to 3 levels deep.'**
  String get categoryFormParentDepthHint;

  /// No description provided for @categoryFormIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get categoryFormIconLabel;

  /// No description provided for @categoryFormColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get categoryFormColorLabel;

  /// No description provided for @categoryFormDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get categoryFormDescriptionLabel;

  /// No description provided for @categoryFormDescriptionHelper.
  ///
  /// In en, this message translates to:
  /// **'What this category is for. Visible to you only.'**
  String get categoryFormDescriptionHelper;

  /// No description provided for @categoryFormDescriptionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Max 200 characters'**
  String get categoryFormDescriptionTooLong;

  /// No description provided for @categoryFormNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get categoryFormNoteLabel;

  /// No description provided for @categoryFormNoteHelper.
  ///
  /// In en, this message translates to:
  /// **'Personal scratch note (e.g. \"Don\'t use for snacks\").'**
  String get categoryFormNoteHelper;

  /// No description provided for @categoryFormNoteTooLong.
  ///
  /// In en, this message translates to:
  /// **'Max 200 characters'**
  String get categoryFormNoteTooLong;

  /// No description provided for @categoryFormIncludeInReportLabel.
  ///
  /// In en, this message translates to:
  /// **'Include in reports'**
  String get categoryFormIncludeInReportLabel;

  /// No description provided for @categoryFormIncludeInReportHelper.
  ///
  /// In en, this message translates to:
  /// **'Off = transactions in this category are excluded from totals and charts.'**
  String get categoryFormIncludeInReportHelper;

  /// No description provided for @categoryFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save category'**
  String get categoryFormSave;

  /// No description provided for @categoryFormDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get categoryFormDiscardTitle;

  /// No description provided for @categoryFormDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits will be lost.'**
  String get categoryFormDiscardBody;

  /// No description provided for @categoriesAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add category'**
  String get categoriesAddNew;

  /// No description provided for @categoriesReorderEnter.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get categoriesReorderEnter;

  /// No description provided for @categoriesReorderSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get categoriesReorderSave;

  /// No description provided for @categoriesReorderDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get categoriesReorderDiscard;

  /// No description provided for @categoriesReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. Drop near another category to move under its parent.'**
  String get categoriesReorderHint;

  /// No description provided for @categoriesUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get categoriesUndo;

  /// No description provided for @categoriesReorderTooDeep.
  ///
  /// In en, this message translates to:
  /// **'That move would exceed the 3-level limit'**
  String get categoriesReorderTooDeep;

  /// No description provided for @categoriesReorderCycle.
  ///
  /// In en, this message translates to:
  /// **'Can\'t drop a category into its own descendant'**
  String get categoriesReorderCycle;

  /// No description provided for @categoriesReorderCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get categoriesReorderCancel;

  /// No description provided for @tagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tagsTitle;

  /// No description provided for @tagsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No tags yet'**
  String get tagsEmptyTitle;

  /// No description provided for @tagsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Tag transactions to slice your spending however you want.'**
  String get tagsEmptyMessage;

  /// No description provided for @tagsAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add tag'**
  String get tagsAddNew;

  /// No description provided for @tagsUsageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{} =1{×1} other{×{count}}}'**
  String tagsUsageCount(int count);

  /// No description provided for @tagDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete tag?'**
  String get tagDeleteConfirmTitle;

  /// No description provided for @tagDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Removes the tag from any transactions using it. This can\'t be undone.'**
  String get tagDeleteConfirmBody;

  /// No description provided for @tagDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tagDeleteConfirmAction;

  /// No description provided for @tagFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get tagFormTitleNew;

  /// No description provided for @tagFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get tagFormTitleEdit;

  /// No description provided for @tagFormPreviewLabel.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get tagFormPreviewLabel;

  /// No description provided for @tagFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get tagFormNameLabel;

  /// No description provided for @tagFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get tagFormNameRequired;

  /// No description provided for @tagFormNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Max 50 characters'**
  String get tagFormNameTooLong;

  /// No description provided for @tagFormNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Another tag already uses this name'**
  String get tagFormNameDuplicate;

  /// No description provided for @tagFormIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get tagFormIconLabel;

  /// No description provided for @tagFormColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get tagFormColorLabel;

  /// No description provided for @tagFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save tag'**
  String get tagFormSave;

  /// No description provided for @tagFormDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get tagFormDiscardTitle;

  /// No description provided for @tagFormDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits will be lost.'**
  String get tagFormDiscardBody;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsSectionAccount;

  /// No description provided for @settingsSectionPreferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get settingsSectionPreferences;

  /// No description provided for @settingsSectionAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get settingsSectionAbout;

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

  /// No description provided for @settingsDefaultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get settingsDefaultCurrency;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @settingsAppearance.
  ///
  /// In en, this message translates to:
  /// **'Appearance'**
  String get settingsAppearance;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get settingsFont;

  /// No description provided for @settingsAppVersion.
  ///
  /// In en, this message translates to:
  /// **'App version'**
  String get settingsAppVersion;

  /// No description provided for @settingsAppVersionValue.
  ///
  /// In en, this message translates to:
  /// **'Phase 0 (1.0.0+1)'**
  String get settingsAppVersionValue;

  /// No description provided for @settingsLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get settingsLogout;

  /// No description provided for @settingsLogoutDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out of ChubiPocket?'**
  String get settingsLogoutDialogTitle;

  /// No description provided for @settingsLogoutDialogBody.
  ///
  /// In en, this message translates to:
  /// **'You will be returned to the login screen.'**
  String get settingsLogoutDialogBody;

  /// No description provided for @editProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit profile'**
  String get editProfileTitle;

  /// No description provided for @editProfileDisplayNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get editProfileDisplayNameLabel;

  /// No description provided for @editProfileCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Default currency'**
  String get editProfileCurrencyLabel;

  /// No description provided for @editProfileCurrencyHelper.
  ///
  /// In en, this message translates to:
  /// **'Used as default for new transactions. Existing transactions keep their original currency.'**
  String get editProfileCurrencyHelper;

  /// No description provided for @editProfileAvatarUrlLabel.
  ///
  /// In en, this message translates to:
  /// **'Avatar URL (optional)'**
  String get editProfileAvatarUrlLabel;

  /// No description provided for @editProfileAvatarUrlHelper.
  ///
  /// In en, this message translates to:
  /// **'Phase 0: paste a URL or leave blank for initials.'**
  String get editProfileAvatarUrlHelper;

  /// No description provided for @editProfileUsernameLabel.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get editProfileUsernameLabel;

  /// No description provided for @editProfileEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get editProfileEmailLabel;

  /// No description provided for @editProfileEmailHelper.
  ///
  /// In en, this message translates to:
  /// **'Used as your account ID and as the matching key when other people send you a contact link request.'**
  String get editProfileEmailHelper;

  /// No description provided for @editProfileEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get editProfileEmailInvalid;

  /// No description provided for @editProfileEmailTooLong.
  ///
  /// In en, this message translates to:
  /// **'Email is too long.'**
  String get editProfileEmailTooLong;

  /// No description provided for @editProfileEmailTaken.
  ///
  /// In en, this message translates to:
  /// **'That email is already registered to another account.'**
  String get editProfileEmailTaken;

  /// No description provided for @editProfileReadOnlyHelper.
  ///
  /// In en, this message translates to:
  /// **'Cannot be changed in this version'**
  String get editProfileReadOnlyHelper;

  /// No description provided for @editProfileEmailNone.
  ///
  /// In en, this message translates to:
  /// **'—'**
  String get editProfileEmailNone;

  /// No description provided for @editProfileSnackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get editProfileSnackSuccess;

  /// No description provided for @editProfileDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get editProfileDiscardTitle;

  /// No description provided for @editProfileDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits will be lost.'**
  String get editProfileDiscardBody;

  /// No description provided for @editProfileDiscardKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get editProfileDiscardKeep;

  /// No description provided for @editProfileDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get editProfileDiscardConfirm;

  /// No description provided for @changePasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// No description provided for @changePasswordCurrentLabel.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get changePasswordCurrentLabel;

  /// No description provided for @changePasswordNewLabel.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get changePasswordNewLabel;

  /// No description provided for @changePasswordNewHelper.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get changePasswordNewHelper;

  /// No description provided for @changePasswordConfirmLabel.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get changePasswordConfirmLabel;

  /// No description provided for @changePasswordCurrentWrong.
  ///
  /// In en, this message translates to:
  /// **'Current password is incorrect'**
  String get changePasswordCurrentWrong;

  /// No description provided for @changePasswordNewMustDiffer.
  ///
  /// In en, this message translates to:
  /// **'Must differ from current password'**
  String get changePasswordNewMustDiffer;

  /// No description provided for @changePasswordConfirmMismatch.
  ///
  /// In en, this message translates to:
  /// **'Doesn\'t match new password'**
  String get changePasswordConfirmMismatch;

  /// No description provided for @changePasswordSubmit.
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get changePasswordSubmit;

  /// No description provided for @changePasswordSnackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get changePasswordSnackSuccess;

  /// No description provided for @avatarPickerStyleLabel.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get avatarPickerStyleLabel;

  /// No description provided for @avatarPickerColorLabel.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get avatarPickerColorLabel;

  /// No description provided for @avatarPickerUseThis.
  ///
  /// In en, this message translates to:
  /// **'Use this'**
  String get avatarPickerUseThis;

  /// No description provided for @avatarPickerUploadDisabled.
  ///
  /// In en, this message translates to:
  /// **'Upload (Phase 2)'**
  String get avatarPickerUploadDisabled;

  /// No description provided for @avatarPickerCropDisabled.
  ///
  /// In en, this message translates to:
  /// **'Crop (Phase 2)'**
  String get avatarPickerCropDisabled;

  /// No description provided for @avatarPresetInitials.
  ///
  /// In en, this message translates to:
  /// **'Initials'**
  String get avatarPresetInitials;

  /// No description provided for @avatarPresetMale.
  ///
  /// In en, this message translates to:
  /// **'Male'**
  String get avatarPresetMale;

  /// No description provided for @avatarPresetFemale.
  ///
  /// In en, this message translates to:
  /// **'Female'**
  String get avatarPresetFemale;

  /// No description provided for @avatarPresetChubby.
  ///
  /// In en, this message translates to:
  /// **'Chubby'**
  String get avatarPresetChubby;

  /// No description provided for @avatarPresetSnacker.
  ///
  /// In en, this message translates to:
  /// **'Snacker'**
  String get avatarPresetSnacker;

  /// No description provided for @avatarPresetStrong.
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get avatarPresetStrong;

  /// No description provided for @avatarColorRed.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get avatarColorRed;

  /// No description provided for @avatarColorGreen.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get avatarColorGreen;

  /// No description provided for @avatarColorBlue.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get avatarColorBlue;

  /// No description provided for @avatarColorTeal.
  ///
  /// In en, this message translates to:
  /// **'Teal'**
  String get avatarColorTeal;

  /// No description provided for @avatarColorPink.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get avatarColorPink;

  /// No description provided for @previewTitle.
  ///
  /// In en, this message translates to:
  /// **'Core Preview'**
  String get previewTitle;

  /// No description provided for @sectionTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get sectionTheme;

  /// No description provided for @sectionMode.
  ///
  /// In en, this message translates to:
  /// **'Mode'**
  String get sectionMode;

  /// No description provided for @sectionLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get sectionLanguage;

  /// No description provided for @sectionFont.
  ///
  /// In en, this message translates to:
  /// **'Font'**
  String get sectionFont;

  /// No description provided for @sectionCurrentSelection.
  ///
  /// In en, this message translates to:
  /// **'Current selection'**
  String get sectionCurrentSelection;

  /// No description provided for @sectionTypographySamples.
  ///
  /// In en, this message translates to:
  /// **'Typography samples'**
  String get sectionTypographySamples;

  /// No description provided for @sectionSemanticColors.
  ///
  /// In en, this message translates to:
  /// **'Semantic colors'**
  String get sectionSemanticColors;

  /// No description provided for @sectionFormatters.
  ///
  /// In en, this message translates to:
  /// **'Formatters'**
  String get sectionFormatters;

  /// No description provided for @sectionControls.
  ///
  /// In en, this message translates to:
  /// **'Controls'**
  String get sectionControls;

  /// No description provided for @sectionInput.
  ///
  /// In en, this message translates to:
  /// **'Input'**
  String get sectionInput;

  /// No description provided for @sectionCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get sectionCard;

  /// No description provided for @modeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get modeLight;

  /// No description provided for @modeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get modeDark;

  /// No description provided for @modeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get modeSystem;

  /// No description provided for @fontsAvailableFor.
  ///
  /// In en, this message translates to:
  /// **'{count} available for \"{lang}\"'**
  String fontsAvailableFor(int count, String lang);

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

  /// No description provided for @amountHint.
  ///
  /// In en, this message translates to:
  /// **'0.00'**
  String get amountHint;

  /// No description provided for @monthlyBalance.
  ///
  /// In en, this message translates to:
  /// **'Monthly balance'**
  String get monthlyBalance;

  /// No description provided for @transactionFormTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get transactionFormTitleNew;

  /// No description provided for @transactionFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get transactionFormTitleEdit;

  /// No description provided for @transactionTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get transactionTypeExpense;

  /// No description provided for @transactionTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get transactionTypeIncome;

  /// No description provided for @transactionTypeTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transactionTypeTransfer;

  /// No description provided for @transactionFormAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get transactionFormAccountLabel;

  /// No description provided for @transactionFormFromAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'From account'**
  String get transactionFormFromAccountLabel;

  /// No description provided for @transactionFormToAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'To account'**
  String get transactionFormToAccountLabel;

  /// No description provided for @transactionFormAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick an account'**
  String get transactionFormAccountRequired;

  /// No description provided for @transactionFormAccountSameError.
  ///
  /// In en, this message translates to:
  /// **'Source and destination must differ'**
  String get transactionFormAccountSameError;

  /// No description provided for @transactionFormCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get transactionFormCategoryLabel;

  /// No description provided for @transactionFormCategoryNone.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get transactionFormCategoryNone;

  /// No description provided for @transactionFormTransferCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Auto-set to Transfer In/Out'**
  String get transactionFormTransferCategoryHint;

  /// No description provided for @transactionFormDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get transactionFormDateLabel;

  /// No description provided for @transactionFormAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionFormAmountLabel;

  /// No description provided for @transactionFormAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get transactionFormAmountRequired;

  /// No description provided for @transactionFormAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid number'**
  String get transactionFormAmountInvalid;

  /// No description provided for @transactionFormAmountTooSmall.
  ///
  /// In en, this message translates to:
  /// **'Must be greater than 0'**
  String get transactionFormAmountTooSmall;

  /// No description provided for @transactionFormNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get transactionFormNoteLabel;

  /// No description provided for @transactionFormNoteAddLabel.
  ///
  /// In en, this message translates to:
  /// **'+ Add note'**
  String get transactionFormNoteAddLabel;

  /// No description provided for @transactionFormTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get transactionFormTagsLabel;

  /// No description provided for @transactionFormTagsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tags yet. Create one from the Tags page.'**
  String get transactionFormTagsEmpty;

  /// No description provided for @transactionFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get transactionFormSave;

  /// No description provided for @transactionFormSaveAndAddAnother.
  ///
  /// In en, this message translates to:
  /// **'Save & add another'**
  String get transactionFormSaveAndAddAnother;

  /// No description provided for @transactionFormSavedAddedAnother.
  ///
  /// In en, this message translates to:
  /// **'Saved. Add another below.'**
  String get transactionFormSavedAddedAnother;

  /// No description provided for @transactionFormAccountPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick an account'**
  String get transactionFormAccountPickerTitle;

  /// No description provided for @transactionFormAccountPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active accounts. Create one first.'**
  String get transactionFormAccountPickerEmpty;

  /// No description provided for @transactionFormCategoryPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get transactionFormCategoryPickerTitle;

  /// No description provided for @transactionFormCategoryPickerNoneOption.
  ///
  /// In en, this message translates to:
  /// **'Uncategorized'**
  String get transactionFormCategoryPickerNoneOption;

  /// No description provided for @transactionFormCategoryPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No categories of this type yet.'**
  String get transactionFormCategoryPickerEmpty;

  /// No description provided for @transactionFormDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard transaction?'**
  String get transactionFormDiscardTitle;

  /// No description provided for @transactionFormDiscardTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get transactionFormDiscardTitleEdit;

  /// No description provided for @transactionFormDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your changes will be lost.'**
  String get transactionFormDiscardBody;

  /// No description provided for @transactionDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get transactionDetailEdit;

  /// No description provided for @transactionDetailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get transactionDetailDelete;

  /// No description provided for @transactionDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Transaction not found'**
  String get transactionDetailNotFound;

  /// No description provided for @transactionDetailNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This transaction may have been deleted.'**
  String get transactionDetailNotFoundMessage;

  /// No description provided for @transactionDetailDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction?'**
  String get transactionDetailDeleteConfirmTitle;

  /// No description provided for @transactionDetailDeleteConfirmTitleTransfer.
  ///
  /// In en, this message translates to:
  /// **'Delete this transfer?'**
  String get transactionDetailDeleteConfirmTitleTransfer;

  /// No description provided for @transactionDetailDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This will reverse the balance change on the account.'**
  String get transactionDetailDeleteConfirmBody;

  /// No description provided for @transactionDetailDeleteConfirmBodyTransfer.
  ///
  /// In en, this message translates to:
  /// **'Both rows of the transfer will be deleted and balances on both accounts will reverse.'**
  String get transactionDetailDeleteConfirmBodyTransfer;

  /// No description provided for @transactionDetailDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get transactionDetailDeleteConfirmAction;

  /// No description provided for @transactionDetailTransferReadonlyHint.
  ///
  /// In en, this message translates to:
  /// **'To change accounts, delete and create a new transfer.'**
  String get transactionDetailTransferReadonlyHint;

  /// No description provided for @transactionDetailSystemRowBanner.
  ///
  /// In en, this message translates to:
  /// **'Auto-created — to change this, use the matching account-level action (account edit, or Adjust balance).'**
  String get transactionDetailSystemRowBanner;

  /// No description provided for @transactionsRangeWeek.
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get transactionsRangeWeek;

  /// No description provided for @transactionsRangeMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get transactionsRangeMonth;

  /// No description provided for @transactionsRangeYear.
  ///
  /// In en, this message translates to:
  /// **'This year'**
  String get transactionsRangeYear;

  /// No description provided for @transactionsRangeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get transactionsRangeAll;

  /// No description provided for @transactionsEmptyAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get transactionsEmptyAccountTitle;

  /// No description provided for @transactionsEmptyAccountMessage.
  ///
  /// In en, this message translates to:
  /// **'Tap the + button to add one.'**
  String get transactionsEmptyAccountMessage;

  /// No description provided for @transactionsListTitle.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsListTitle;

  /// No description provided for @transactionsListFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get transactionsListFilterAll;

  /// No description provided for @transactionsListFilterCategoryAll.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get transactionsListFilterCategoryAll;

  /// No description provided for @transactionsListEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'No transactions match these filters.'**
  String get transactionsListEmptyMessage;

  /// No description provided for @transactionsListRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get transactionsListRetry;

  /// No description provided for @transactionsListDateToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get transactionsListDateToday;

  /// No description provided for @transactionsListDateYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get transactionsListDateYesterday;

  /// No description provided for @accountAdjustBalanceViewTransaction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get accountAdjustBalanceViewTransaction;

  /// No description provided for @accountAdjustBalanceSuccess.
  ///
  /// In en, this message translates to:
  /// **'Balance adjusted'**
  String get accountAdjustBalanceSuccess;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
