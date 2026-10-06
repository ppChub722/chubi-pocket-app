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

  /// No description provided for @commonEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get commonEdit;

  /// No description provided for @commonLongPressToEdit.
  ///
  /// In en, this message translates to:
  /// **'Long-press to edit'**
  String get commonLongPressToEdit;

  /// No description provided for @commonSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get commonSearch;

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get commonYesterday;

  /// No description provided for @commonInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get commonInvite;

  /// No description provided for @commonClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get commonClear;

  /// No description provided for @commonUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get commonUndo;

  /// No description provided for @commonDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get commonDiscard;

  /// No description provided for @commonDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard changes?'**
  String get commonDiscardTitle;

  /// No description provided for @commonDiscardBody.
  ///
  /// In en, this message translates to:
  /// **'Your edits will be lost.'**
  String get commonDiscardBody;

  /// No description provided for @commonCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get commonCurrency;

  /// No description provided for @currencyNameTHB.
  ///
  /// In en, this message translates to:
  /// **'Thai baht'**
  String get currencyNameTHB;

  /// No description provided for @currencyNameUSD.
  ///
  /// In en, this message translates to:
  /// **'US dollar'**
  String get currencyNameUSD;

  /// No description provided for @currencyNameEUR.
  ///
  /// In en, this message translates to:
  /// **'Euro'**
  String get currencyNameEUR;

  /// No description provided for @currencyNameGBP.
  ///
  /// In en, this message translates to:
  /// **'British pound'**
  String get currencyNameGBP;

  /// No description provided for @currencyNameJPY.
  ///
  /// In en, this message translates to:
  /// **'Japanese yen'**
  String get currencyNameJPY;

  /// No description provided for @contactPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Who?'**
  String get contactPickerTitle;

  /// No description provided for @contactPickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search contacts or type a name'**
  String get contactPickerSearchHint;

  /// No description provided for @contactPickerUseName.
  ///
  /// In en, this message translates to:
  /// **'Use \"{name}\"'**
  String contactPickerUseName(String name);

  /// No description provided for @contactPickerUseNameHint.
  ///
  /// In en, this message translates to:
  /// **'Not saved as a contact'**
  String get contactPickerUseNameHint;

  /// No description provided for @contactPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet — type a name above'**
  String get contactPickerEmpty;

  /// No description provided for @commonShowAmounts.
  ///
  /// In en, this message translates to:
  /// **'Show amounts'**
  String get commonShowAmounts;

  /// No description provided for @commonHideAmounts.
  ///
  /// In en, this message translates to:
  /// **'Hide amounts'**
  String get commonHideAmounts;

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
  /// **'Add a wallet from the Wallets tab, then tap the + button to log your first transaction.'**
  String get homeEmptyMessage;

  /// No description provided for @homeNetWorthLabel.
  ///
  /// In en, this message translates to:
  /// **'Net worth'**
  String get homeNetWorthLabel;

  /// No description provided for @homeNetWorthAccountCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 wallet} other{{count} wallets}}'**
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
  /// **'Wallets'**
  String get navAccounts;

  /// No description provided for @navAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get navAddTransaction;

  /// No description provided for @navProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects & Events'**
  String get navProjects;

  /// No description provided for @projectsCreateNew.
  ///
  /// In en, this message translates to:
  /// **'Create new'**
  String get projectsCreateNew;

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
  /// **'No wallets yet'**
  String get accountsPlaceholderTitle;

  /// No description provided for @accountsPlaceholderMessage.
  ///
  /// In en, this message translates to:
  /// **'Adding wallets ships in Phase 1a.'**
  String get accountsPlaceholderMessage;

  /// No description provided for @accountsAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add wallet'**
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
  /// **'Wallet not found'**
  String get accountDetailNotFound;

  /// No description provided for @accountDetailNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This wallet may have been archived or deleted.'**
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
  /// **'New wallet'**
  String get accountFormTitle;

  /// No description provided for @accountFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit wallet'**
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
  /// **'Wallet name'**
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
  /// **'Money already in this wallet on the day you start tracking.'**
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
  /// **'Required for credit wallets'**
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
  /// **'Save wallet'**
  String get accountFormSave;

  /// No description provided for @accountFormDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard new wallet?'**
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
  /// **'Archive this wallet?'**
  String get accountArchiveConfirmTitle;

  /// No description provided for @accountArchiveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The wallet will be hidden from the active list. Its transactions stay intact and remain referenced.'**
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
  /// **'What this wallet is for. Visible to you only.'**
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

  /// No description provided for @iconMakerRoleIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get iconMakerRoleIcon;

  /// No description provided for @iconMakerRoleBackground.
  ///
  /// In en, this message translates to:
  /// **'Background'**
  String get iconMakerRoleBackground;

  /// No description provided for @iconMakerRoleBorder.
  ///
  /// In en, this message translates to:
  /// **'Border'**
  String get iconMakerRoleBorder;

  /// No description provided for @iconMakerColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get iconMakerColor;

  /// No description provided for @iconMakerColorEditing.
  ///
  /// In en, this message translates to:
  /// **'Editing colour'**
  String get iconMakerColorEditing;

  /// No description provided for @iconMakerColorHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a colour below to change the selected slot'**
  String get iconMakerColorHint;

  /// No description provided for @iconMakerRecentCustom.
  ///
  /// In en, this message translates to:
  /// **'Recent · Custom'**
  String get iconMakerRecentCustom;

  /// No description provided for @iconMakerThemeColors.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get iconMakerThemeColors;

  /// No description provided for @iconMakerPresetColors.
  ///
  /// In en, this message translates to:
  /// **'Preset'**
  String get iconMakerPresetColors;

  /// No description provided for @iconMakerHex.
  ///
  /// In en, this message translates to:
  /// **'Hex'**
  String get iconMakerHex;

  /// No description provided for @iconMakerReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get iconMakerReset;

  /// No description provided for @iconMakerPresetLabel.
  ///
  /// In en, this message translates to:
  /// **'preset'**
  String get iconMakerPresetLabel;

  /// No description provided for @iconMakerTitle.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get iconMakerTitle;

  /// No description provided for @iconMakerTabStyle.
  ///
  /// In en, this message translates to:
  /// **'Style'**
  String get iconMakerTabStyle;

  /// No description provided for @iconMakerTabColor.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get iconMakerTabColor;

  /// No description provided for @iconMakerShape.
  ///
  /// In en, this message translates to:
  /// **'Shape'**
  String get iconMakerShape;

  /// No description provided for @iconMakerPattern.
  ///
  /// In en, this message translates to:
  /// **'Pattern'**
  String get iconMakerPattern;

  /// No description provided for @iconMakerNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get iconMakerNone;

  /// No description provided for @iconMakerCommonColors.
  ///
  /// In en, this message translates to:
  /// **'Common'**
  String get iconMakerCommonColors;

  /// No description provided for @iconMakerCustomColors.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get iconMakerCustomColors;

  /// No description provided for @iconMakerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search icons, e.g. car, home'**
  String get iconMakerSearchHint;

  /// No description provided for @iconMakerNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No icons match \"{query}\"'**
  String iconMakerNoMatch(String query);

  /// No description provided for @iconMakerLayerOff.
  ///
  /// In en, this message translates to:
  /// **'{layer}: none — pick a style first'**
  String iconMakerLayerOff(String layer);

  /// No description provided for @iconMakerNotRecolorable.
  ///
  /// In en, this message translates to:
  /// **'This style has fixed colors'**
  String get iconMakerNotRecolorable;

  /// No description provided for @iconMakerResetSlot.
  ///
  /// In en, this message translates to:
  /// **'Reset this color'**
  String get iconMakerResetSlot;

  /// No description provided for @iconMakerPickColor.
  ///
  /// In en, this message translates to:
  /// **'Pick a color'**
  String get iconMakerPickColor;

  /// No description provided for @iconMakerHexInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use #RRGGBB'**
  String get iconMakerHexInvalid;

  /// No description provided for @iconMakerResetConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset icon?'**
  String get iconMakerResetConfirmTitle;

  /// No description provided for @iconMakerResetConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Icon, colors, background and border go back to the defaults. You can undo it.'**
  String get iconMakerResetConfirmBody;

  /// No description provided for @iconMakerUseDefault.
  ///
  /// In en, this message translates to:
  /// **'Use the app\'s default icon'**
  String get iconMakerUseDefault;

  /// No description provided for @iconShapeCircle.
  ///
  /// In en, this message translates to:
  /// **'Circle'**
  String get iconShapeCircle;

  /// No description provided for @iconShapeSquircle.
  ///
  /// In en, this message translates to:
  /// **'Squircle'**
  String get iconShapeSquircle;

  /// No description provided for @iconShapeRounded.
  ///
  /// In en, this message translates to:
  /// **'Rounded'**
  String get iconShapeRounded;

  /// No description provided for @iconShapeSquare.
  ///
  /// In en, this message translates to:
  /// **'Square'**
  String get iconShapeSquare;

  /// No description provided for @iconShapeLeaf.
  ///
  /// In en, this message translates to:
  /// **'Leaf'**
  String get iconShapeLeaf;

  /// No description provided for @iconShapeDrop.
  ///
  /// In en, this message translates to:
  /// **'Drop'**
  String get iconShapeDrop;

  /// No description provided for @colorPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a colour'**
  String get colorPickerTitle;

  /// No description provided for @colorPickerUse.
  ///
  /// In en, this message translates to:
  /// **'Use colour'**
  String get colorPickerUse;

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
  /// **'Projects & Events'**
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

  /// No description provided for @contactsAddNew.
  ///
  /// In en, this message translates to:
  /// **'New contact'**
  String get contactsAddNew;

  /// No description provided for @contactsFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get contactsFilterActive;

  /// No description provided for @contactsFilterArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get contactsFilterArchived;

  /// No description provided for @contactsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get contactsFilterAll;

  /// No description provided for @contactsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get contactsEmptyTitle;

  /// No description provided for @contactsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'People you add appear here — link them to share transactions and debts.'**
  String get contactsEmptyMessage;

  /// No description provided for @contactsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name, email or phone'**
  String get contactsSearchHint;

  /// No description provided for @contactsStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get contactsStatusLabel;

  /// No description provided for @contactsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching contacts'**
  String get contactsNoMatch;

  /// No description provided for @contactTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New contact'**
  String get contactTitleNew;

  /// No description provided for @contactTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit contact'**
  String get contactTitleEdit;

  /// No description provided for @contactNotFound.
  ///
  /// In en, this message translates to:
  /// **'Contact not found'**
  String get contactNotFound;

  /// No description provided for @contactNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get contactNameLabel;

  /// No description provided for @contactNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get contactNameRequired;

  /// No description provided for @contactNameTooLong.
  ///
  /// In en, this message translates to:
  /// **'Up to 100 characters'**
  String get contactNameTooLong;

  /// No description provided for @contactEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmailLabel;

  /// No description provided for @contactEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email'**
  String get contactEmailInvalid;

  /// No description provided for @contactPhoneLabel.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get contactPhoneLabel;

  /// No description provided for @contactNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get contactNotesLabel;

  /// No description provided for @contactLinkedBadge.
  ///
  /// In en, this message translates to:
  /// **'Linked to an app account'**
  String get contactLinkedBadge;

  /// No description provided for @contactLinkedLockedHint.
  ///
  /// In en, this message translates to:
  /// **'Name and email come from their account'**
  String get contactLinkedLockedHint;

  /// No description provided for @contactArchivedBadge.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get contactArchivedBadge;

  /// No description provided for @contactSectionActions.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get contactSectionActions;

  /// No description provided for @contactLinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Link account'**
  String get contactLinkTitle;

  /// No description provided for @contactLinkLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked — name, email and icon follow their account'**
  String get contactLinkLinked;

  /// No description provided for @contactLinkRequest.
  ///
  /// In en, this message translates to:
  /// **'Send link request'**
  String get contactLinkRequest;

  /// No description provided for @contactLinkRequestHint.
  ///
  /// In en, this message translates to:
  /// **'If this email belongs to a user, they\'ll get a request'**
  String get contactLinkRequestHint;

  /// No description provided for @contactLinkNeedsEmail.
  ///
  /// In en, this message translates to:
  /// **'Add an email to send a link request'**
  String get contactLinkNeedsEmail;

  /// No description provided for @contactLinkRequested.
  ///
  /// In en, this message translates to:
  /// **'Link request sent'**
  String get contactLinkRequested;

  /// No description provided for @contactUnlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get contactUnlink;

  /// No description provided for @contactUnlinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlink {name}?'**
  String contactUnlinkTitle(String name);

  /// No description provided for @contactUnlinkBody.
  ///
  /// In en, this message translates to:
  /// **'The contact goes back to the name and email you saved.'**
  String get contactUnlinkBody;

  /// No description provided for @contactUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Unlinked'**
  String get contactUnlinked;

  /// No description provided for @contactWireTitle.
  ///
  /// In en, this message translates to:
  /// **'Match names in splits'**
  String get contactWireTitle;

  /// No description provided for @contactWireHint.
  ///
  /// In en, this message translates to:
  /// **'{names} names · {splits} splits not linked to a contact'**
  String contactWireHint(int names, int splits);

  /// No description provided for @contactWireNone.
  ///
  /// In en, this message translates to:
  /// **'No unlinked names'**
  String get contactWireNone;

  /// No description provided for @contactWireSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Link names to {name}'**
  String contactWireSheetTitle(String name);

  /// No description provided for @contactWireSheetBody.
  ///
  /// In en, this message translates to:
  /// **'Pick the typed names in your splits that are this person — their debts get linked to this contact.'**
  String get contactWireSheetBody;

  /// No description provided for @contactWireSearch.
  ///
  /// In en, this message translates to:
  /// **'Search names'**
  String get contactWireSearch;

  /// No description provided for @contactWireCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 split} other{{count} splits}}'**
  String contactWireCount(int count);

  /// No description provided for @contactWireSave.
  ///
  /// In en, this message translates to:
  /// **'Link {count}'**
  String contactWireSave(int count);

  /// No description provided for @contactWireDone.
  ///
  /// In en, this message translates to:
  /// **'Linked {count} splits to {name}'**
  String contactWireDone(int count, String name);

  /// No description provided for @contactArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get contactArchive;

  /// No description provided for @contactArchiveHint.
  ///
  /// In en, this message translates to:
  /// **'Hidden from pickers; history stays'**
  String get contactArchiveHint;

  /// No description provided for @contactRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get contactRestore;

  /// No description provided for @contactDebts.
  ///
  /// In en, this message translates to:
  /// **'Debts with this person'**
  String get contactDebts;

  /// No description provided for @contactDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String contactDeleteTitle(String name);

  /// No description provided for @contactDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Splits and debts that mention this person keep their name as text.'**
  String get contactDeleteBody;

  /// No description provided for @contactDeleted.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}'**
  String contactDeleted(String name);

  /// No description provided for @contactLinkCreateTitle.
  ///
  /// In en, this message translates to:
  /// **'Add linked contact'**
  String get contactLinkCreateTitle;

  /// No description provided for @contactLinkExistingTitle.
  ///
  /// In en, this message translates to:
  /// **'Link contact'**
  String get contactLinkExistingTitle;

  /// No description provided for @contactLinkSave.
  ///
  /// In en, this message translates to:
  /// **'Link & save'**
  String get contactLinkSave;

  /// No description provided for @contactLinkBannerNew.
  ///
  /// In en, this message translates to:
  /// **'Saving creates a new contact linked to {name}.'**
  String contactLinkBannerNew(String name);

  /// No description provided for @contactLinkBannerExisting.
  ///
  /// In en, this message translates to:
  /// **'Saving links this contact to {name}.'**
  String contactLinkBannerExisting(String name);

  /// No description provided for @debtsNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get debtsNet;

  /// No description provided for @debtsOwedToMe.
  ///
  /// In en, this message translates to:
  /// **'Owe you'**
  String get debtsOwedToMe;

  /// No description provided for @debtsIOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe'**
  String get debtsIOwe;

  /// No description provided for @debtsEven.
  ///
  /// In en, this message translates to:
  /// **'Settled up'**
  String get debtsEven;

  /// No description provided for @debtsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search name'**
  String get debtsSearchHint;

  /// No description provided for @debtsStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get debtsStatusLabel;

  /// No description provided for @debtsStatusOpen.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get debtsStatusOpen;

  /// No description provided for @debtsStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get debtsStatusAll;

  /// No description provided for @debtsOpenCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing outstanding} =1{1 outstanding} other{{count} outstanding}}'**
  String debtsOpenCount(int count);

  /// No description provided for @debtsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No debts yet'**
  String get debtsEmptyTitle;

  /// No description provided for @debtsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Record who owes you or whom you owe — or split a bill from a transaction.'**
  String get debtsEmptyMessage;

  /// No description provided for @debtsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching people'**
  String get debtsNoMatch;

  /// No description provided for @debtsAddNew.
  ///
  /// In en, this message translates to:
  /// **'Record a debt'**
  String get debtsAddNew;

  /// No description provided for @debtsPersonHistory.
  ///
  /// In en, this message translates to:
  /// **'History ({count})'**
  String debtsPersonHistory(int count);

  /// No description provided for @debtsPersonAdd.
  ///
  /// In en, this message translates to:
  /// **'Record a debt with this person'**
  String get debtsPersonAdd;

  /// No description provided for @debtsPersonLinkContact.
  ///
  /// In en, this message translates to:
  /// **'Link to a contact'**
  String get debtsPersonLinkContact;

  /// No description provided for @debtsPersonLinkContactHint.
  ///
  /// In en, this message translates to:
  /// **'Merge this name\'s debts into a contact'**
  String get debtsPersonLinkContactHint;

  /// No description provided for @debtsPersonLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked {count} debts to {name}'**
  String debtsPersonLinked(int count, String name);

  /// No description provided for @debtsPersonOpenContact.
  ///
  /// In en, this message translates to:
  /// **'View contact'**
  String get debtsPersonOpenContact;

  /// No description provided for @debtTheyOweYou.
  ///
  /// In en, this message translates to:
  /// **'{name} owes you'**
  String debtTheyOweYou(String name);

  /// No description provided for @debtYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe {name}'**
  String debtYouOwe(String name);

  /// No description provided for @debtStatusSettled.
  ///
  /// In en, this message translates to:
  /// **'Paid back'**
  String get debtStatusSettled;

  /// No description provided for @debtStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get debtStatusCancelled;

  /// No description provided for @debtOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding'**
  String get debtOutstanding;

  /// No description provided for @debtProgress.
  ///
  /// In en, this message translates to:
  /// **'Paid back {paid} of {total}'**
  String debtProgress(String paid, String total);

  /// No description provided for @debtReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive payment'**
  String get debtReceive;

  /// No description provided for @debtPay.
  ///
  /// In en, this message translates to:
  /// **'Pay back'**
  String get debtPay;

  /// No description provided for @debtAmount.
  ///
  /// In en, this message translates to:
  /// **'Full amount'**
  String get debtAmount;

  /// No description provided for @debtSettled.
  ///
  /// In en, this message translates to:
  /// **'Paid back'**
  String get debtSettled;

  /// No description provided for @debtSource.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get debtSource;

  /// No description provided for @debtSourceManual.
  ///
  /// In en, this message translates to:
  /// **'Recorded manually'**
  String get debtSourceManual;

  /// No description provided for @debtSourceTransaction.
  ///
  /// In en, this message translates to:
  /// **'Bill split'**
  String get debtSourceTransaction;

  /// No description provided for @debtSourceProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get debtSourceProject;

  /// No description provided for @debtNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get debtNote;

  /// No description provided for @debtCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Created'**
  String get debtCreatedAt;

  /// No description provided for @debtCounterparty.
  ///
  /// In en, this message translates to:
  /// **'With'**
  String get debtCounterparty;

  /// No description provided for @debtCounterpartyPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Pick a contact or type a name'**
  String get debtCounterpartyPlaceholder;

  /// No description provided for @debtCounterpartyRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick or type a name'**
  String get debtCounterpartyRequired;

  /// No description provided for @debtCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel this debt'**
  String get debtCancel;

  /// No description provided for @debtCancelTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this debt?'**
  String get debtCancelTitle;

  /// No description provided for @debtCancelBody.
  ///
  /// In en, this message translates to:
  /// **'No money moves. Use it when you forgive the debt or recorded it by mistake.'**
  String get debtCancelBody;

  /// No description provided for @debtCancelled.
  ///
  /// In en, this message translates to:
  /// **'Debt cancelled'**
  String get debtCancelled;

  /// No description provided for @debtDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this debt?'**
  String get debtDeleteTitle;

  /// No description provided for @debtDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Deleted for good — this can\'t be undone.'**
  String get debtDeleteBody;

  /// No description provided for @debtDeleted.
  ///
  /// In en, this message translates to:
  /// **'Debt deleted'**
  String get debtDeleted;

  /// No description provided for @debtNotFound.
  ///
  /// In en, this message translates to:
  /// **'Debt not found'**
  String get debtNotFound;

  /// No description provided for @debtNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Record a debt'**
  String get debtNewTitle;

  /// No description provided for @debtEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit debt'**
  String get debtEditTitle;

  /// No description provided for @debtDirectionOwedToMe.
  ///
  /// In en, this message translates to:
  /// **'They owe me'**
  String get debtDirectionOwedToMe;

  /// No description provided for @debtDirectionOwedToMeDesc.
  ///
  /// In en, this message translates to:
  /// **'I lent money or paid for them'**
  String get debtDirectionOwedToMeDesc;

  /// No description provided for @debtDirectionIOwe.
  ///
  /// In en, this message translates to:
  /// **'I owe them'**
  String get debtDirectionIOwe;

  /// No description provided for @debtDirectionIOweDesc.
  ///
  /// In en, this message translates to:
  /// **'I borrowed or they paid for me'**
  String get debtDirectionIOweDesc;

  /// No description provided for @debtAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above 0'**
  String get debtAmountRequired;

  /// No description provided for @debtAmountBelowSettled.
  ///
  /// In en, this message translates to:
  /// **'Can\'t be less than what\'s been paid back ({amount})'**
  String debtAmountBelowSettled(String amount);

  /// No description provided for @debtSettleTitleReceive.
  ///
  /// In en, this message translates to:
  /// **'Receive from {name}'**
  String debtSettleTitleReceive(String name);

  /// No description provided for @debtSettleTitlePay.
  ///
  /// In en, this message translates to:
  /// **'Pay back {name}'**
  String debtSettleTitlePay(String name);

  /// No description provided for @debtSettleAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get debtSettleAll;

  /// No description provided for @debtSettleHalf.
  ///
  /// In en, this message translates to:
  /// **'Half'**
  String get debtSettleHalf;

  /// No description provided for @debtSettleOver.
  ///
  /// In en, this message translates to:
  /// **'More than outstanding ({amount})'**
  String debtSettleOver(String amount);

  /// No description provided for @debtSettleRecordTx.
  ///
  /// In en, this message translates to:
  /// **'Record as a transaction'**
  String get debtSettleRecordTx;

  /// No description provided for @debtSettleRecordTxHint.
  ///
  /// In en, this message translates to:
  /// **'Adds income/expense and updates the wallet balance'**
  String get debtSettleRecordTxHint;

  /// No description provided for @debtSettleNoTxHint.
  ///
  /// In en, this message translates to:
  /// **'Only lowers the outstanding amount — no transaction'**
  String get debtSettleNoTxHint;

  /// No description provided for @debtSettleAccount.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get debtSettleAccount;

  /// No description provided for @debtSettleAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a wallet'**
  String get debtSettleAccountRequired;

  /// No description provided for @debtSettleDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get debtSettleDate;

  /// No description provided for @debtSettleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get debtSettleConfirm;

  /// No description provided for @debtSettleDone.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded'**
  String get debtSettleDone;

  /// No description provided for @projectStatusActive.
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get projectStatusActive;

  /// No description provided for @projectStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get projectStatusCompleted;

  /// No description provided for @projectStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get projectStatusCancelled;

  /// No description provided for @projectStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get projectStatusArchived;

  /// No description provided for @projectsStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get projectsStatusAll;

  /// No description provided for @projectsStatusLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get projectsStatusLabel;

  /// No description provided for @projectsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search projects'**
  String get projectsSearchHint;

  /// No description provided for @projectsSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get projectsSortRecent;

  /// No description provided for @projectsSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get projectsSortName;

  /// No description provided for @projectsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No projects yet'**
  String get projectsEmptyTitle;

  /// No description provided for @projectsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep a trip or a job\'s spending in one place, then settle up with friends at the end.'**
  String get projectsEmptyMessage;

  /// No description provided for @projectsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching projects'**
  String get projectsNoMatch;

  /// No description provided for @projectsMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String projectsMembersCount(int count);

  /// No description provided for @projectTabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get projectTabDashboard;

  /// No description provided for @projectTabTransactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get projectTabTransactions;

  /// No description provided for @projectTabResolve.
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get projectTabResolve;

  /// No description provided for @projectAddTransaction.
  ///
  /// In en, this message translates to:
  /// **'Add transaction'**
  String get projectAddTransaction;

  /// No description provided for @projectNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New project'**
  String get projectNewTitle;

  /// No description provided for @projectEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit project'**
  String get projectEditTitle;

  /// No description provided for @projectNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Project name'**
  String get projectNameLabel;

  /// No description provided for @projectNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get projectNameRequired;

  /// No description provided for @projectTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get projectTypeLabel;

  /// No description provided for @projectTypeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. trip, freelance'**
  String get projectTypeHint;

  /// No description provided for @projectDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get projectDescriptionLabel;

  /// No description provided for @projectIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Project icon'**
  String get projectIconLabel;

  /// No description provided for @projectStatusChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get projectStatusChangeTitle;

  /// No description provided for @projectStatusLockTitle.
  ///
  /// In en, this message translates to:
  /// **'Change to {status}?'**
  String projectStatusLockTitle(String status);

  /// No description provided for @projectStatusLockBody.
  ///
  /// In en, this message translates to:
  /// **'The project gets locked: no adding or editing transactions until it is reopened.'**
  String get projectStatusLockBody;

  /// No description provided for @projectStatusChanged.
  ///
  /// In en, this message translates to:
  /// **'Status changed to {status}'**
  String projectStatusChanged(String status);

  /// No description provided for @projectLockedCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed: no new transactions'**
  String get projectLockedCompleted;

  /// No description provided for @projectLockedCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled: transactions cannot be added, edited or deleted'**
  String get projectLockedCancelled;

  /// No description provided for @projectLockedArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived: read only'**
  String get projectLockedArchived;

  /// No description provided for @projectDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String projectDeleteTitle(String name);

  /// No description provided for @projectDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Only projects without transactions can be deleted. If it has some, archive it instead.'**
  String get projectDeleteBody;

  /// No description provided for @projectDeleted.
  ///
  /// In en, this message translates to:
  /// **'Project deleted'**
  String get projectDeleted;

  /// No description provided for @projectDashTotalExpense.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get projectDashTotalExpense;

  /// No description provided for @projectDashTotalIncome.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get projectDashTotalIncome;

  /// No description provided for @projectDashMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get projectDashMembers;

  /// No description provided for @projectDashWhoPaid.
  ///
  /// In en, this message translates to:
  /// **'Who paid'**
  String get projectDashWhoPaid;

  /// No description provided for @projectDashTopCategories.
  ///
  /// In en, this message translates to:
  /// **'Top categories'**
  String get projectDashTopCategories;

  /// No description provided for @projectDashRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get projectDashRecent;

  /// No description provided for @projectDashSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get projectDashSeeAll;

  /// No description provided for @projectDashTxCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No transactions} =1{1 transaction} other{{count} transactions}}'**
  String projectDashTxCount(int count);

  /// No description provided for @projectTxSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search transactions'**
  String get projectTxSearchHint;

  /// No description provided for @projectTxTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get projectTxTypeLabel;

  /// No description provided for @projectTxTypeAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get projectTxTypeAll;

  /// No description provided for @projectTxTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get projectTxTypeExpense;

  /// No description provided for @projectTxTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get projectTxTypeIncome;

  /// No description provided for @projectTxOnlyMine.
  ///
  /// In en, this message translates to:
  /// **'Only me'**
  String get projectTxOnlyMine;

  /// No description provided for @projectTxSortTime.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get projectTxSortTime;

  /// No description provided for @projectTxSortAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get projectTxSortAmount;

  /// No description provided for @projectTxSortMember.
  ///
  /// In en, this message translates to:
  /// **'Who paid'**
  String get projectTxSortMember;

  /// No description provided for @projectTxSortCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get projectTxSortCategory;

  /// No description provided for @projectTxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this project yet'**
  String get projectTxEmpty;

  /// No description provided for @projectTxNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions'**
  String get projectTxNoMatch;

  /// No description provided for @projectTxOwes.
  ///
  /// In en, this message translates to:
  /// **'owes {name}'**
  String projectTxOwes(String name);

  /// No description provided for @projectTxUnmark.
  ///
  /// In en, this message translates to:
  /// **'Unmark'**
  String get projectTxUnmark;

  /// No description provided for @projectTxResolve.
  ///
  /// In en, this message translates to:
  /// **'Record in my book'**
  String get projectTxResolve;

  /// No description provided for @projectTxResolveHint.
  ///
  /// In en, this message translates to:
  /// **'Create a transaction or a debt in your own book'**
  String get projectTxResolveHint;

  /// No description provided for @projectTxEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get projectTxEdit;

  /// No description provided for @projectTxDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction'**
  String get projectTxDelete;

  /// No description provided for @projectTxDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction?'**
  String get projectTxDeleteTitle;

  /// No description provided for @projectTxDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Its splits are deleted too.'**
  String get projectTxDeleteBody;

  /// No description provided for @projectTxDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get projectTxDeleted;

  /// No description provided for @projectResolveAsTx.
  ///
  /// In en, this message translates to:
  /// **'As transaction'**
  String get projectResolveAsTx;

  /// No description provided for @projectResolveAsDebt.
  ///
  /// In en, this message translates to:
  /// **'As debt'**
  String get projectResolveAsDebt;

  /// No description provided for @projectResolveShareOnly.
  ///
  /// In en, this message translates to:
  /// **'Only my share'**
  String get projectResolveShareOnly;

  /// No description provided for @projectResolveShareHint.
  ///
  /// In en, this message translates to:
  /// **'Full {full} · my share {share}'**
  String projectResolveShareHint(String full, String share);

  /// No description provided for @projectResolveAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get projectResolveAmount;

  /// No description provided for @projectResolveCategory.
  ///
  /// In en, this message translates to:
  /// **'Category (optional)'**
  String get projectResolveCategory;

  /// No description provided for @projectResolveCategoryNone.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get projectResolveCategoryNone;

  /// No description provided for @projectResolveDebtHint.
  ///
  /// In en, this message translates to:
  /// **'The person comes from the project member'**
  String get projectResolveDebtHint;

  /// No description provided for @projectResolveConfirm.
  ///
  /// In en, this message translates to:
  /// **'Record'**
  String get projectResolveConfirm;

  /// No description provided for @projectResolveDone.
  ///
  /// In en, this message translates to:
  /// **'Recorded in your book'**
  String get projectResolveDone;

  /// No description provided for @projectResolveComingSoon.
  ///
  /// In en, this message translates to:
  /// **'A settle-up summary is on the way. For now, tick rows in the Transactions tab.'**
  String get projectResolveComingSoon;

  /// No description provided for @projectMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get projectMembersTitle;

  /// No description provided for @projectMembersPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting to accept'**
  String get projectMembersPending;

  /// No description provided for @projectMembersLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get projectMembersLeft;

  /// No description provided for @projectRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get projectRoleOwner;

  /// No description provided for @projectRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get projectRoleMember;

  /// No description provided for @projectMemberLinked.
  ///
  /// In en, this message translates to:
  /// **'Has an app account'**
  String get projectMemberLinked;

  /// No description provided for @projectMemberAdHoc.
  ///
  /// In en, this message translates to:
  /// **'No app account'**
  String get projectMemberAdHoc;

  /// No description provided for @projectMembersInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite member'**
  String get projectMembersInvite;

  /// No description provided for @projectLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave project'**
  String get projectLeave;

  /// No description provided for @projectLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave {name}?'**
  String projectLeaveTitle(String name);

  /// No description provided for @projectLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You will not see this project again unless you are invited back.'**
  String get projectLeaveBody;

  /// No description provided for @projectLeft.
  ///
  /// In en, this message translates to:
  /// **'You left the project'**
  String get projectLeft;

  /// No description provided for @projectMemberRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from project'**
  String get projectMemberRemove;

  /// No description provided for @projectMemberRemoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String projectMemberRemoveTitle(String name);

  /// No description provided for @projectMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed'**
  String get projectMemberRemoved;

  /// No description provided for @projectMemberTransfer.
  ///
  /// In en, this message translates to:
  /// **'Make owner'**
  String get projectMemberTransfer;

  /// No description provided for @projectMemberTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Make {name} the owner?'**
  String projectMemberTransferTitle(String name);

  /// No description provided for @projectMemberTransferBody.
  ///
  /// In en, this message translates to:
  /// **'{name} becomes the owner; you become a regular member.'**
  String projectMemberTransferBody(String name);

  /// No description provided for @projectMemberTransferred.
  ///
  /// In en, this message translates to:
  /// **'Ownership transferred'**
  String get projectMemberTransferred;

  /// No description provided for @projectMemberTransferNeedsAccount.
  ///
  /// In en, this message translates to:
  /// **'Only members with an app account can own a project'**
  String get projectMemberTransferNeedsAccount;

  /// No description provided for @projectAddMemberName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get projectAddMemberName;

  /// No description provided for @projectAddMemberNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get projectAddMemberNameRequired;

  /// No description provided for @projectAddMemberEmail.
  ///
  /// In en, this message translates to:
  /// **'Email (optional)'**
  String get projectAddMemberEmail;

  /// No description provided for @projectAddMemberEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Add an email to invite an app user; leave it empty for someone without an account'**
  String get projectAddMemberEmailHint;

  /// No description provided for @projectAddMemberFromContacts.
  ///
  /// In en, this message translates to:
  /// **'Pick from contacts'**
  String get projectAddMemberFromContacts;

  /// No description provided for @projectAddMemberSubmit.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get projectAddMemberSubmit;

  /// No description provided for @projectAddMemberAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {name}'**
  String projectAddMemberAdded(String name);

  /// No description provided for @projectTxNewTitle.
  ///
  /// In en, this message translates to:
  /// **'Add project transaction'**
  String get projectTxNewTitle;

  /// No description provided for @projectTxEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get projectTxEditTitle;

  /// No description provided for @projectTxPaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get projectTxPaidBy;

  /// No description provided for @projectTxReceivedBy.
  ///
  /// In en, this message translates to:
  /// **'Received by'**
  String get projectTxReceivedBy;

  /// No description provided for @projectTxDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get projectTxDescription;

  /// No description provided for @projectTxDescriptionRequired.
  ///
  /// In en, this message translates to:
  /// **'Description is required'**
  String get projectTxDescriptionRequired;

  /// No description provided for @projectTxDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get projectTxDate;

  /// No description provided for @projectTxNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get projectTxNote;

  /// No description provided for @projectTxCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get projectTxCategory;

  /// No description provided for @projectTxCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Name the category and pick an icon'**
  String get projectTxCategoryRequired;

  /// No description provided for @projectTxCategoryName.
  ///
  /// In en, this message translates to:
  /// **'Category name'**
  String get projectTxCategoryName;

  /// No description provided for @projectTxSplits.
  ///
  /// In en, this message translates to:
  /// **'Split with'**
  String get projectTxSplits;

  /// No description provided for @projectTxSplitsHint.
  ///
  /// In en, this message translates to:
  /// **'How much each person owes the payer; the payer keeps the rest'**
  String get projectTxSplitsHint;

  /// No description provided for @projectTxAddSplit.
  ///
  /// In en, this message translates to:
  /// **'Add a split'**
  String get projectTxAddSplit;

  /// No description provided for @projectTxSplitEqual.
  ///
  /// In en, this message translates to:
  /// **'Split equally'**
  String get projectTxSplitEqual;

  /// No description provided for @projectTxSplitsOver.
  ///
  /// In en, this message translates to:
  /// **'Splits ({sum}) are more than the total'**
  String projectTxSplitsOver(String sum);

  /// No description provided for @projectTxPayerKeeps.
  ///
  /// In en, this message translates to:
  /// **'Payer\'s own share {amount}'**
  String projectTxPayerKeeps(String amount);

  /// No description provided for @projectTxAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above 0'**
  String get projectTxAmountRequired;

  /// No description provided for @settingsThemeMint.
  ///
  /// In en, this message translates to:
  /// **'Mint'**
  String get settingsThemeMint;

  /// No description provided for @settingsThemeSweet.
  ///
  /// In en, this message translates to:
  /// **'Sweet'**
  String get settingsThemeSweet;

  /// No description provided for @settingsNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get settingsNotifications;

  /// No description provided for @settingsNotificationsHint.
  ///
  /// In en, this message translates to:
  /// **'What you get and what happens automatically'**
  String get settingsNotificationsHint;

  /// No description provided for @settingsDefaultCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'Used when you create wallets and debts'**
  String get settingsDefaultCurrencyHint;

  /// No description provided for @settingsCurrencySaved.
  ///
  /// In en, this message translates to:
  /// **'Default currency updated'**
  String get settingsCurrencySaved;

  /// No description provided for @settingsFontSample.
  ///
  /// In en, this message translates to:
  /// **'Sample ภาษาไทย 123'**
  String get settingsFontSample;

  /// No description provided for @notificationsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// No description provided for @notificationsTabAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notificationsTabAll;

  /// No description provided for @notificationsTabUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsTabUnread;

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

  /// No description provided for @notificationsSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notificationsSettingsTooltip;

  /// No description provided for @notificationsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'You are all caught up'**
  String get notificationsEmptyTitle;

  /// No description provided for @notificationsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Activity from people you share with shows up here'**
  String get notificationsEmptyMessage;

  /// No description provided for @notificationsEmptyUnread.
  ///
  /// In en, this message translates to:
  /// **'Nothing unread'**
  String get notificationsEmptyUnread;

  /// No description provided for @notificationsSomeone.
  ///
  /// In en, this message translates to:
  /// **'Someone'**
  String get notificationsSomeone;

  /// No description provided for @notifSplitCreated.
  ///
  /// In en, this message translates to:
  /// **'{actor} split a bill with you'**
  String notifSplitCreated(String actor);

  /// No description provided for @notifSplitPaid.
  ///
  /// In en, this message translates to:
  /// **'{actor} paid back their share'**
  String notifSplitPaid(String actor);

  /// No description provided for @notifSplitReceived.
  ///
  /// In en, this message translates to:
  /// **'{actor} confirmed your payment'**
  String notifSplitReceived(String actor);

  /// No description provided for @notifProjectTxForYou.
  ///
  /// In en, this message translates to:
  /// **'{actor} recorded a project transaction for you'**
  String notifProjectTxForYou(String actor);

  /// No description provided for @notifProjectTxChanged.
  ///
  /// In en, this message translates to:
  /// **'{actor} edited a project transaction'**
  String notifProjectTxChanged(String actor);

  /// No description provided for @notifProjectInvite.
  ///
  /// In en, this message translates to:
  /// **'{actor} invited you to {project}'**
  String notifProjectInvite(String actor, String project);

  /// No description provided for @notifContactLink.
  ///
  /// In en, this message translates to:
  /// **'{actor} wants to link as contacts'**
  String notifContactLink(String actor);

  /// No description provided for @notifUnknown.
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notifUnknown;

  /// No description provided for @notifAccepted.
  ///
  /// In en, this message translates to:
  /// **'Accepted · tap to open'**
  String get notifAccepted;

  /// No description provided for @notifRejectTitle.
  ///
  /// In en, this message translates to:
  /// **'Decline this request?'**
  String get notifRejectTitle;

  /// No description provided for @notifRejectBody.
  ///
  /// In en, this message translates to:
  /// **'They will not be told that you declined.'**
  String get notifRejectBody;

  /// No description provided for @notifHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get notifHidden;

  /// No description provided for @notifSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notifSettingsTitle;

  /// No description provided for @notifSettingsReceive.
  ///
  /// In en, this message translates to:
  /// **'Notifications you get'**
  String get notifSettingsReceive;

  /// No description provided for @notifSettingsReceiveHint.
  ///
  /// In en, this message translates to:
  /// **'Turn off what you do not need. Invites and requests always come through because they need an answer.'**
  String get notifSettingsReceiveHint;

  /// No description provided for @notifGroupSplits.
  ///
  /// In en, this message translates to:
  /// **'Bill splits'**
  String get notifGroupSplits;

  /// No description provided for @notifGroupProjects.
  ///
  /// In en, this message translates to:
  /// **'Projects'**
  String get notifGroupProjects;

  /// No description provided for @notifGroupRequests.
  ///
  /// In en, this message translates to:
  /// **'Invites and requests'**
  String get notifGroupRequests;

  /// No description provided for @notifGroupPayments.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get notifGroupPayments;

  /// No description provided for @notifTypeSplitCreated.
  ///
  /// In en, this message translates to:
  /// **'Someone splits a bill with me'**
  String get notifTypeSplitCreated;

  /// No description provided for @notifTypeSplitPaid.
  ///
  /// In en, this message translates to:
  /// **'Someone pays back their share'**
  String get notifTypeSplitPaid;

  /// No description provided for @notifTypeSplitReceived.
  ///
  /// In en, this message translates to:
  /// **'Someone confirms my payment'**
  String get notifTypeSplitReceived;

  /// No description provided for @notifTypeProjectTxForYou.
  ///
  /// In en, this message translates to:
  /// **'A project transaction is recorded for me'**
  String get notifTypeProjectTxForYou;

  /// No description provided for @notifTypeProjectTxChanged.
  ///
  /// In en, this message translates to:
  /// **'A project transaction is edited'**
  String get notifTypeProjectTxChanged;

  /// No description provided for @notifTypeAlwaysOn.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get notifTypeAlwaysOn;

  /// No description provided for @notifSettingsAuto.
  ///
  /// In en, this message translates to:
  /// **'Automatic actions'**
  String get notifSettingsAuto;

  /// No description provided for @notifSettingsAutoPending.
  ///
  /// In en, this message translates to:
  /// **'Saved now; starts working once the server supports it'**
  String get notifSettingsAutoPending;

  /// No description provided for @notifAutoNotifySplit.
  ///
  /// In en, this message translates to:
  /// **'Tell linked contacts when I split a bill'**
  String get notifAutoNotifySplit;

  /// No description provided for @notifAutoAddDebt.
  ///
  /// In en, this message translates to:
  /// **'Track bills split with me as debts'**
  String get notifAutoAddDebt;

  /// No description provided for @notifAutoRecordPayment.
  ///
  /// In en, this message translates to:
  /// **'Record payments people send me'**
  String get notifAutoRecordPayment;

  /// No description provided for @notifDefaultAccount.
  ///
  /// In en, this message translates to:
  /// **'Receiving wallet'**
  String get notifDefaultAccount;

  /// No description provided for @notifDefaultAccountNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get notifDefaultAccountNone;

  /// No description provided for @notifAutoResolveProject.
  ///
  /// In en, this message translates to:
  /// **'Record my own project transactions in my book'**
  String get notifAutoResolveProject;

  /// No description provided for @notifSettingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save, changed back'**
  String get notifSettingsSaveFailed;

  /// No description provided for @profileUsernameLocked.
  ///
  /// In en, this message translates to:
  /// **'Username cannot be changed'**
  String get profileUsernameLocked;

  /// No description provided for @homeUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Coming up (7 days)'**
  String get homeUpcoming;

  /// No description provided for @homeUpcomingInDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Today} =1{Tomorrow} other{In {days} days}}'**
  String homeUpcomingInDays(int days);

  /// No description provided for @homeByCategory.
  ///
  /// In en, this message translates to:
  /// **'Spending by category (this month)'**
  String get homeByCategory;

  /// No description provided for @homeBudgetLine.
  ///
  /// In en, this message translates to:
  /// **'{spent} of {amount}'**
  String homeBudgetLine(String spent, String amount);

  /// No description provided for @homeGoalLine.
  ///
  /// In en, this message translates to:
  /// **'{current} of {target}'**
  String homeGoalLine(String current, String target);

  /// No description provided for @homeNoTxYet.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet'**
  String get homeNoTxYet;

  /// No description provided for @homeAddFirstTx.
  ///
  /// In en, this message translates to:
  /// **'Add your first transaction'**
  String get homeAddFirstTx;

  /// No description provided for @transactionsFilterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get transactionsFilterType;

  /// No description provided for @transactionsFilterRange.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get transactionsFilterRange;

  /// No description provided for @transactionsFilterAccount.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get transactionsFilterAccount;

  /// No description provided for @transactionsFilterCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get transactionsFilterCategory;

  /// No description provided for @transactionsSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get transactionsSortNewest;

  /// No description provided for @transactionsSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get transactionsSortOldest;

  /// No description provided for @transactionsSortAmountHigh.
  ///
  /// In en, this message translates to:
  /// **'Largest'**
  String get transactionsSortAmountHigh;

  /// No description provided for @transactionsSortAmountLow.
  ///
  /// In en, this message translates to:
  /// **'Smallest'**
  String get transactionsSortAmountLow;

  /// No description provided for @transactionsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No transactions match these filters'**
  String get transactionsNoMatch;

  /// No description provided for @transactionsClearFilters.
  ///
  /// In en, this message translates to:
  /// **'Clear filters'**
  String get transactionsClearFilters;

  /// No description provided for @txDetailDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get txDetailDate;

  /// No description provided for @txDetailAccount.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get txDetailAccount;

  /// No description provided for @txDetailCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get txDetailCategory;

  /// No description provided for @txDetailTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get txDetailTags;

  /// No description provided for @txDetailNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get txDetailNote;

  /// No description provided for @txDetailSplits.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get txDetailSplits;

  /// No description provided for @txDetailHasSplits.
  ///
  /// In en, this message translates to:
  /// **'Split with others'**
  String get txDetailHasSplits;

  /// No description provided for @txDetailRecordedBy.
  ///
  /// In en, this message translates to:
  /// **'Recorded by'**
  String get txDetailRecordedBy;

  /// No description provided for @txDetailSource.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get txDetailSource;

  /// No description provided for @txDetailSourceDebt.
  ///
  /// In en, this message translates to:
  /// **'Debt payment'**
  String get txDetailSourceDebt;

  /// No description provided for @txDetailSourceProject.
  ///
  /// In en, this message translates to:
  /// **'Project'**
  String get txDetailSourceProject;

  /// No description provided for @txDetailSystemLocked.
  ///
  /// In en, this message translates to:
  /// **'System transaction: cannot be edited or deleted'**
  String get txDetailSystemLocked;

  /// No description provided for @txDetailTransferTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get txDetailTransferTo;

  /// No description provided for @txDetailBalanceAfter.
  ///
  /// In en, this message translates to:
  /// **'Balance after'**
  String get txDetailBalanceAfter;

  /// No description provided for @txDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction?'**
  String get txDeleteTitle;

  /// No description provided for @txDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'The wallet balance is adjusted back.'**
  String get txDeleteBody;

  /// No description provided for @txDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get txDeleted;

  /// No description provided for @txSplitAdd.
  ///
  /// In en, this message translates to:
  /// **'Split with others'**
  String get txSplitAdd;

  /// No description provided for @txSplitWith.
  ///
  /// In en, this message translates to:
  /// **'Split with'**
  String get txSplitWith;

  /// No description provided for @txSplitEqually.
  ///
  /// In en, this message translates to:
  /// **'Split equally'**
  String get txSplitEqually;

  /// No description provided for @txSplitCollapse.
  ///
  /// In en, this message translates to:
  /// **'Remove split'**
  String get txSplitCollapse;

  /// No description provided for @txSplitAddPerson.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get txSplitAddPerson;

  /// No description provided for @txSplitRemaining.
  ///
  /// In en, this message translates to:
  /// **'Your share {amount}'**
  String txSplitRemaining(String amount);

  /// No description provided for @txSplitWiredContact.
  ///
  /// In en, this message translates to:
  /// **'Linked to a contact'**
  String get txSplitWiredContact;

  /// No description provided for @txSplitName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get txSplitName;

  /// No description provided for @txSplitOwes.
  ///
  /// In en, this message translates to:
  /// **'Owes'**
  String get txSplitOwes;

  /// No description provided for @txSplitRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get txSplitRemove;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Track income and spending, split bills with friends'**
  String get authTagline;

  /// No description provided for @authOr.
  ///
  /// In en, this message translates to:
  /// **'or'**
  String get authOr;

  /// No description provided for @authContinueWithGoogle.
  ///
  /// In en, this message translates to:
  /// **'Continue with Google'**
  String get authContinueWithGoogle;

  /// No description provided for @authComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get authComingSoon;

  /// No description provided for @authRegisterSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Sign-in details'**
  String get authRegisterSectionAccount;

  /// No description provided for @authRegisterSectionProfile.
  ///
  /// In en, this message translates to:
  /// **'About you'**
  String get authRegisterSectionProfile;

  /// No description provided for @authRegisterUsernameHint.
  ///
  /// In en, this message translates to:
  /// **'a-z 0-9 _ -, 3 to 50 characters'**
  String get authRegisterUsernameHint;

  /// No description provided for @authRegisterPasswordHint.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authRegisterPasswordHint;

  /// No description provided for @authRegisterEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Lets friends link their account with yours'**
  String get authRegisterEmailHint;

  /// No description provided for @authLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get authLanguage;

  /// No description provided for @accountsTotalMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get accountsTotalMine;

  /// No description provided for @accountsTotalShared.
  ///
  /// In en, this message translates to:
  /// **'Shared pot'**
  String get accountsTotalShared;

  /// No description provided for @accountsArchivedLink.
  ///
  /// In en, this message translates to:
  /// **'Archived wallets ({count})'**
  String accountsArchivedLink(int count);

  /// No description provided for @accountsArchivedTitle.
  ///
  /// In en, this message translates to:
  /// **'Archived wallets'**
  String get accountsArchivedTitle;

  /// No description provided for @accountsArchivedEmpty.
  ///
  /// In en, this message translates to:
  /// **'No archived wallets'**
  String get accountsArchivedEmpty;

  /// No description provided for @accountRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get accountRestore;

  /// No description provided for @accountRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored {name}'**
  String accountRestored(String name);

  /// No description provided for @accountDetailSeeAll.
  ///
  /// In en, this message translates to:
  /// **'See all'**
  String get accountDetailSeeAll;

  /// No description provided for @accountDetailDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get accountDetailDescription;

  /// No description provided for @accountDetailNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get accountDetailNote;

  /// No description provided for @accountDetailMembers.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get accountDetailMembers;

  /// No description provided for @accountArchiveHasMembers.
  ///
  /// In en, this message translates to:
  /// **'A wallet with other members cannot be archived. Remove them first.'**
  String get accountArchiveHasMembers;

  /// No description provided for @accountArchived.
  ///
  /// In en, this message translates to:
  /// **'Wallet archived'**
  String get accountArchived;

  /// No description provided for @txSplitOver.
  ///
  /// In en, this message translates to:
  /// **'Splits are more than the transaction amount'**
  String get txSplitOver;

  /// No description provided for @txSplitFreeText.
  ///
  /// In en, this message translates to:
  /// **'Typed name: pick a contact from the suggestions to link it'**
  String get txSplitFreeText;

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

  /// No description provided for @moreGroupLibrary.
  ///
  /// In en, this message translates to:
  /// **'Library'**
  String get moreGroupLibrary;

  /// No description provided for @moreGroupPeople.
  ///
  /// In en, this message translates to:
  /// **'People & shared money'**
  String get moreGroupPeople;

  /// No description provided for @moreGroupPlanning.
  ///
  /// In en, this message translates to:
  /// **'Planning'**
  String get moreGroupPlanning;

  /// No description provided for @moreCategoriesDesc.
  ///
  /// In en, this message translates to:
  /// **'Group income & spending'**
  String get moreCategoriesDesc;

  /// No description provided for @moreTagsDesc.
  ///
  /// In en, this message translates to:
  /// **'Labels for quick search'**
  String get moreTagsDesc;

  /// No description provided for @moreContactsDesc.
  ///
  /// In en, this message translates to:
  /// **'People you split bills with'**
  String get moreContactsDesc;

  /// No description provided for @moreProjectsDesc.
  ///
  /// In en, this message translates to:
  /// **'Trips & shared budgets'**
  String get moreProjectsDesc;

  /// No description provided for @moreDebtsDesc.
  ///
  /// In en, this message translates to:
  /// **'Who owes whom'**
  String get moreDebtsDesc;

  /// No description provided for @moreBudgetsDesc.
  ///
  /// In en, this message translates to:
  /// **'Spending limits'**
  String get moreBudgetsDesc;

  /// No description provided for @moreSavingGoalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Save towards a target'**
  String get moreSavingGoalsDesc;

  /// No description provided for @moreScheduledDesc.
  ///
  /// In en, this message translates to:
  /// **'Recurring & upcoming bills'**
  String get moreScheduledDesc;

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
  /// **'None'**
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

  /// No description provided for @categoriesSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get categoriesSearchHint;

  /// No description provided for @categoriesSearchNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching categories'**
  String get categoriesSearchNoMatch;

  /// No description provided for @categoryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete category'**
  String get categoryDelete;

  /// No description provided for @categoryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete \"{name}\"?'**
  String categoryDeleteTitle(String name);

  /// No description provided for @categoryDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Subcategories move up under the parent.'**
  String get categoryDeleteBody;

  /// No description provided for @categoryDeleteTxImpact.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction} other{{count} transactions}} will become uncategorised.'**
  String categoryDeleteTxImpact(int count);

  /// No description provided for @categoryDeleteBudgetImpact.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 budget} other{{count} budgets}} for this category will be deleted.'**
  String categoryDeleteBudgetImpact(int count);

  /// No description provided for @categoryDeletedResult.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{name}\"'**
  String categoryDeletedResult(String name);

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

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

  /// No description provided for @tagsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search tags'**
  String get tagsSearchHint;

  /// No description provided for @tagsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching tags'**
  String get tagsNoMatch;

  /// No description provided for @tagsSortUsage.
  ///
  /// In en, this message translates to:
  /// **'Most used'**
  String get tagsSortUsage;

  /// No description provided for @tagsSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all shown'**
  String get tagsSelectAll;

  /// No description provided for @tagsBulkColor.
  ///
  /// In en, this message translates to:
  /// **'Change colour'**
  String get tagsBulkColor;

  /// No description provided for @tagsBulkIcon.
  ///
  /// In en, this message translates to:
  /// **'Change icon'**
  String get tagsBulkIcon;

  /// No description provided for @tagsDeleteSelected.
  ///
  /// In en, this message translates to:
  /// **'Delete selected'**
  String get tagsDeleteSelected;

  /// No description provided for @tagsFiltersClearedForError.
  ///
  /// In en, this message translates to:
  /// **'Filters cleared to show a tag that needs fixing'**
  String get tagsFiltersClearedForError;

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
  /// **'1.0.0 (1)'**
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
  /// **'Wallet'**
  String get transactionFormAccountLabel;

  /// No description provided for @transactionFormFromAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'From wallet'**
  String get transactionFormFromAccountLabel;

  /// No description provided for @transactionFormToAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'To wallet'**
  String get transactionFormToAccountLabel;

  /// No description provided for @transactionFormAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a wallet'**
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

  /// No description provided for @transactionFormAccountNone.
  ///
  /// In en, this message translates to:
  /// **'No wallet'**
  String get transactionFormAccountNone;

  /// No description provided for @transactionFormMoveTransferTitle.
  ///
  /// In en, this message translates to:
  /// **'Move wallets'**
  String get transactionFormMoveTransferTitle;

  /// No description provided for @transactionFormAccountPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a wallet'**
  String get transactionFormAccountPickerTitle;

  /// No description provided for @transactionFormAccountPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No active wallets. Create one first.'**
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
  /// **'This will reverse the balance change on the wallet.'**
  String get transactionDetailDeleteConfirmBody;

  /// No description provided for @transactionDetailDeleteConfirmBodyTransfer.
  ///
  /// In en, this message translates to:
  /// **'Both rows of the transfer will be deleted and balances on both wallets will reverse.'**
  String get transactionDetailDeleteConfirmBodyTransfer;

  /// No description provided for @transactionDetailDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get transactionDetailDeleteConfirmAction;

  /// No description provided for @transactionDetailTransferReadonlyHint.
  ///
  /// In en, this message translates to:
  /// **'To change wallets, delete and create a new transfer.'**
  String get transactionDetailTransferReadonlyHint;

  /// No description provided for @transactionDetailSystemRowBanner.
  ///
  /// In en, this message translates to:
  /// **'Auto-created — to change this, use the matching wallet-level action (wallet edit, or Adjust balance).'**
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

  /// No description provided for @savingGoalsTitle.
  ///
  /// In en, this message translates to:
  /// **'Saving goals'**
  String get savingGoalsTitle;

  /// No description provided for @savingGoalsAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add saving goal'**
  String get savingGoalsAddNew;

  /// No description provided for @savingGoalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No saving goals yet'**
  String get savingGoalsEmptyTitle;

  /// No description provided for @savingGoalsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Set a target on top of a wallet and track your progress as the balance grows.'**
  String get savingGoalsEmptyMessage;

  /// No description provided for @savingGoalProgressLine.
  ///
  /// In en, this message translates to:
  /// **'{current} of {target}'**
  String savingGoalProgressLine(String current, String target);

  /// No description provided for @savingGoalCompletedLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal reached'**
  String get savingGoalCompletedLabel;

  /// No description provided for @savingGoalFormTitle.
  ///
  /// In en, this message translates to:
  /// **'New saving goal'**
  String get savingGoalFormTitle;

  /// No description provided for @savingGoalFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit saving goal'**
  String get savingGoalFormTitleEdit;

  /// No description provided for @savingGoalFormSave.
  ///
  /// In en, this message translates to:
  /// **'Create goal'**
  String get savingGoalFormSave;

  /// No description provided for @savingGoalFormSaveEdit.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get savingGoalFormSaveEdit;

  /// No description provided for @savingGoalFormIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get savingGoalFormIconLabel;

  /// No description provided for @savingGoalFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get savingGoalFormNameLabel;

  /// No description provided for @savingGoalFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get savingGoalFormNameRequired;

  /// No description provided for @savingGoalFormLinkedAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Linked wallet'**
  String get savingGoalFormLinkedAccountLabel;

  /// No description provided for @savingGoalFormLinkedAccountHelper.
  ///
  /// In en, this message translates to:
  /// **'Progress = wallet balance × allocation %'**
  String get savingGoalFormLinkedAccountHelper;

  /// No description provided for @savingGoalFormLinkedAccountLockedHelper.
  ///
  /// In en, this message translates to:
  /// **'Linked wallet can\'t be changed. Delete and recreate to switch wallets.'**
  String get savingGoalFormLinkedAccountLockedHelper;

  /// No description provided for @savingGoalFormAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a linked wallet'**
  String get savingGoalFormAccountRequired;

  /// No description provided for @savingGoalFormTargetLabel.
  ///
  /// In en, this message translates to:
  /// **'Target amount'**
  String get savingGoalFormTargetLabel;

  /// No description provided for @savingGoalFormTargetInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive amount'**
  String get savingGoalFormTargetInvalid;

  /// No description provided for @savingGoalFormAllocationLabel.
  ///
  /// In en, this message translates to:
  /// **'Allocation'**
  String get savingGoalFormAllocationLabel;

  /// No description provided for @savingGoalFormAllocationHelper.
  ///
  /// In en, this message translates to:
  /// **'Leave blank to let the server suggest a default. Total per wallet ≤ 100%.'**
  String get savingGoalFormAllocationHelper;

  /// No description provided for @savingGoalFormAllocationInvalid.
  ///
  /// In en, this message translates to:
  /// **'Must be between 0 and 100'**
  String get savingGoalFormAllocationInvalid;

  /// No description provided for @savingGoalFormDeadlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get savingGoalFormDeadlineLabel;

  /// No description provided for @savingGoalFormDeadlinePlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get savingGoalFormDeadlinePlaceholder;

  /// No description provided for @savingGoalFormNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get savingGoalFormNoteLabel;

  /// No description provided for @savingGoalDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Goal not found'**
  String get savingGoalDetailNotFound;

  /// No description provided for @savingGoalDetailNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This saving goal may have been deleted or archived.'**
  String get savingGoalDetailNotFoundMessage;

  /// No description provided for @savingGoalDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get savingGoalDetailEdit;

  /// No description provided for @savingGoalDetailArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get savingGoalDetailArchive;

  /// No description provided for @savingGoalDetailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get savingGoalDetailDelete;

  /// No description provided for @savingGoalDetailOfTarget.
  ///
  /// In en, this message translates to:
  /// **'of {target}'**
  String savingGoalDetailOfTarget(String target);

  /// No description provided for @savingGoalDetailAllocation.
  ///
  /// In en, this message translates to:
  /// **'Allocation'**
  String get savingGoalDetailAllocation;

  /// No description provided for @savingGoalDetailRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get savingGoalDetailRemaining;

  /// No description provided for @savingGoalDetailDeadline.
  ///
  /// In en, this message translates to:
  /// **'Deadline'**
  String get savingGoalDetailDeadline;

  /// No description provided for @savingGoalDetailDaysRemaining.
  ///
  /// In en, this message translates to:
  /// **'Days remaining'**
  String get savingGoalDetailDaysRemaining;

  /// No description provided for @savingGoalDetailDaysValue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day} other{{count} days}}'**
  String savingGoalDetailDaysValue(int count);

  /// No description provided for @savingGoalDetailRequiredMonthly.
  ///
  /// In en, this message translates to:
  /// **'Suggested monthly'**
  String get savingGoalDetailRequiredMonthly;

  /// No description provided for @savingGoalArchiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this goal?'**
  String get savingGoalArchiveConfirmTitle;

  /// No description provided for @savingGoalArchiveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Archiving frees its allocation slot on the linked wallet. You can restore it later if capacity is available.'**
  String get savingGoalArchiveConfirmBody;

  /// No description provided for @savingGoalArchiveConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get savingGoalArchiveConfirmAction;

  /// No description provided for @savingGoalDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this goal?'**
  String get savingGoalDeleteConfirmTitle;

  /// No description provided for @savingGoalDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the goal. The linked wallet and its transactions are unaffected.'**
  String get savingGoalDeleteConfirmBody;

  /// No description provided for @savingGoalDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get savingGoalDeleteConfirmAction;

  /// No description provided for @budgetsTitle.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgetsTitle;

  /// No description provided for @budgetsAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add budget'**
  String get budgetsAddNew;

  /// No description provided for @budgetsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get budgetsEmptyTitle;

  /// No description provided for @budgetsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Set a per-category limit and we\'ll track your spending against it each period.'**
  String get budgetsEmptyMessage;

  /// No description provided for @budgetPeriodWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get budgetPeriodWeekly;

  /// No description provided for @budgetPeriodMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get budgetPeriodMonthly;

  /// No description provided for @budgetPeriodYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get budgetPeriodYearly;

  /// No description provided for @budgetSpentLine.
  ///
  /// In en, this message translates to:
  /// **'{spent} of {limit}'**
  String budgetSpentLine(String spent, String limit);

  /// No description provided for @budgetFormTitle.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get budgetFormTitle;

  /// No description provided for @budgetFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit budget'**
  String get budgetFormTitleEdit;

  /// No description provided for @budgetFormSave.
  ///
  /// In en, this message translates to:
  /// **'Create budget'**
  String get budgetFormSave;

  /// No description provided for @budgetFormSaveEdit.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get budgetFormSaveEdit;

  /// No description provided for @budgetFormCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get budgetFormCategoryLabel;

  /// No description provided for @budgetFormCategoryPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get budgetFormCategoryPlaceholder;

  /// No description provided for @budgetFormCategoryHelper.
  ///
  /// In en, this message translates to:
  /// **'Only expense categories. Picking a parent tracks all its sub-categories.'**
  String get budgetFormCategoryHelper;

  /// No description provided for @budgetFormCategoryLockedHelper.
  ///
  /// In en, this message translates to:
  /// **'Category can\'t be changed. Delete and recreate to switch categories.'**
  String get budgetFormCategoryLockedHelper;

  /// No description provided for @budgetFormCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get budgetFormCategoryRequired;

  /// No description provided for @budgetFormDescriptionLabel.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get budgetFormDescriptionLabel;

  /// No description provided for @budgetFormDescriptionHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. Shown as the budget\'s title; falls back to the category name when blank.'**
  String get budgetFormDescriptionHelper;

  /// No description provided for @budgetFormDescriptionTooLong.
  ///
  /// In en, this message translates to:
  /// **'Max 200 characters'**
  String get budgetFormDescriptionTooLong;

  /// No description provided for @budgetFormAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Limit per period'**
  String get budgetFormAmountLabel;

  /// No description provided for @budgetFormAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive amount'**
  String get budgetFormAmountInvalid;

  /// No description provided for @budgetFormPeriodLabel.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get budgetFormPeriodLabel;

  /// No description provided for @budgetFormNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get budgetFormNoteLabel;

  /// No description provided for @budgetFormNoteHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional. Longer free-form note shown on the detail page.'**
  String get budgetFormNoteHelper;

  /// No description provided for @budgetDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Budget not found'**
  String get budgetDetailNotFound;

  /// No description provided for @budgetDetailNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This budget may have been deleted or archived.'**
  String get budgetDetailNotFoundMessage;

  /// No description provided for @budgetDetailFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgetDetailFallbackTitle;

  /// No description provided for @budgetDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get budgetDetailEdit;

  /// No description provided for @budgetDetailArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get budgetDetailArchive;

  /// No description provided for @budgetDetailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get budgetDetailDelete;

  /// No description provided for @budgetDetailOfLimit.
  ///
  /// In en, this message translates to:
  /// **'of {limit}'**
  String budgetDetailOfLimit(String limit);

  /// No description provided for @budgetDetailRemainingLine.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String budgetDetailRemainingLine(String amount);

  /// No description provided for @budgetDetailPeriodRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String budgetDetailPeriodRange(String start, String end);

  /// No description provided for @budgetDetailOverLimitWarning.
  ///
  /// In en, this message translates to:
  /// **'You\'ve gone over the limit for this period.'**
  String get budgetDetailOverLimitWarning;

  /// No description provided for @budgetDetailBreakdownTitle.
  ///
  /// In en, this message translates to:
  /// **'Spend by category'**
  String get budgetDetailBreakdownTitle;

  /// No description provided for @budgetArchiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this budget?'**
  String get budgetArchiveConfirmTitle;

  /// No description provided for @budgetArchiveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Archiving hides the budget from your active list. You can restore it later.'**
  String get budgetArchiveConfirmBody;

  /// No description provided for @budgetArchiveConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get budgetArchiveConfirmAction;

  /// No description provided for @budgetDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this budget?'**
  String get budgetDeleteConfirmTitle;

  /// No description provided for @budgetDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently removes the budget. Your transactions are unaffected.'**
  String get budgetDeleteConfirmBody;

  /// No description provided for @budgetDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get budgetDeleteConfirmAction;

  /// No description provided for @scheduledTitle.
  ///
  /// In en, this message translates to:
  /// **'Scheduled transactions'**
  String get scheduledTitle;

  /// No description provided for @scheduledAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add scheduled'**
  String get scheduledAddNew;

  /// No description provided for @scheduledEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No scheduled transactions'**
  String get scheduledEmptyTitle;

  /// No description provided for @scheduledEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Set up subscriptions, installments, or loans and we\'ll generate the transactions for you.'**
  String get scheduledEmptyMessage;

  /// No description provided for @scheduledVariantRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get scheduledVariantRecurring;

  /// No description provided for @scheduledVariantInstallment.
  ///
  /// In en, this message translates to:
  /// **'Installment'**
  String get scheduledVariantInstallment;

  /// No description provided for @scheduledVariantLoan.
  ///
  /// In en, this message translates to:
  /// **'Loan'**
  String get scheduledVariantLoan;

  /// No description provided for @scheduledTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get scheduledTypeExpense;

  /// No description provided for @scheduledTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get scheduledTypeIncome;

  /// No description provided for @scheduledCycleDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get scheduledCycleDaily;

  /// No description provided for @scheduledCycleWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get scheduledCycleWeekly;

  /// No description provided for @scheduledCycleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get scheduledCycleMonthly;

  /// No description provided for @scheduledCycleYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get scheduledCycleYearly;

  /// No description provided for @scheduledStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get scheduledStatusActive;

  /// No description provided for @scheduledStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get scheduledStatusPaused;

  /// No description provided for @scheduledStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get scheduledStatusCompleted;

  /// No description provided for @scheduledStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get scheduledStatusCancelled;

  /// No description provided for @scheduledNextDue.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String scheduledNextDue(String date);

  /// No description provided for @scheduledInstallmentsLeft.
  ///
  /// In en, this message translates to:
  /// **'{remaining}/{total} left'**
  String scheduledInstallmentsLeft(int remaining, int total);

  /// No description provided for @scheduledFormTitle.
  ///
  /// In en, this message translates to:
  /// **'New scheduled'**
  String get scheduledFormTitle;

  /// No description provided for @scheduledFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit scheduled'**
  String get scheduledFormTitleEdit;

  /// No description provided for @scheduledFormSave.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get scheduledFormSave;

  /// No description provided for @scheduledFormSaveEdit.
  ///
  /// In en, this message translates to:
  /// **'Save changes'**
  String get scheduledFormSaveEdit;

  /// No description provided for @scheduledFormIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get scheduledFormIconLabel;

  /// No description provided for @scheduledFormVariantLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get scheduledFormVariantLabel;

  /// No description provided for @scheduledFormTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Direction'**
  String get scheduledFormTypeLabel;

  /// No description provided for @scheduledFormNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get scheduledFormNameLabel;

  /// No description provided for @scheduledFormNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get scheduledFormNameRequired;

  /// No description provided for @scheduledFormAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount per cycle'**
  String get scheduledFormAmountLabel;

  /// No description provided for @scheduledFormPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment per cycle'**
  String get scheduledFormPaymentLabel;

  /// No description provided for @scheduledFormAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive amount'**
  String get scheduledFormAmountInvalid;

  /// No description provided for @scheduledFormAccountLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get scheduledFormAccountLabel;

  /// No description provided for @scheduledFormAccountRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a wallet'**
  String get scheduledFormAccountRequired;

  /// No description provided for @scheduledFormCategoryLabel.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get scheduledFormCategoryLabel;

  /// No description provided for @scheduledFormCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get scheduledFormCategoryRequired;

  /// No description provided for @scheduledFormCycleLabel.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get scheduledFormCycleLabel;

  /// No description provided for @scheduledFormNextBillingLabel.
  ///
  /// In en, this message translates to:
  /// **'Next billing date'**
  String get scheduledFormNextBillingLabel;

  /// No description provided for @scheduledFormInstallmentSection.
  ///
  /// In en, this message translates to:
  /// **'Installment details'**
  String get scheduledFormInstallmentSection;

  /// No description provided for @scheduledFormTotalAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get scheduledFormTotalAmountLabel;

  /// No description provided for @scheduledFormTotalAmountHelper.
  ///
  /// In en, this message translates to:
  /// **'Sum of all installments + down payment.'**
  String get scheduledFormTotalAmountHelper;

  /// No description provided for @scheduledFormTotalAmountHelperLoan.
  ///
  /// In en, this message translates to:
  /// **'Lifetime total: principal + interest combined.'**
  String get scheduledFormTotalAmountHelperLoan;

  /// No description provided for @scheduledFormDownPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Down payment'**
  String get scheduledFormDownPaymentLabel;

  /// No description provided for @scheduledFormTotalInstallmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Total installments'**
  String get scheduledFormTotalInstallmentsLabel;

  /// No description provided for @scheduledFormRemainingInstallmentsLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get scheduledFormRemainingInstallmentsLabel;

  /// No description provided for @scheduledFormInstallmentsInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid count'**
  String get scheduledFormInstallmentsInvalid;

  /// No description provided for @scheduledFormRemainingExceeds.
  ///
  /// In en, this message translates to:
  /// **'Cannot exceed total'**
  String get scheduledFormRemainingExceeds;

  /// No description provided for @scheduledFormInterestRateLabel.
  ///
  /// In en, this message translates to:
  /// **'Interest rate (APR)'**
  String get scheduledFormInterestRateLabel;

  /// No description provided for @scheduledFormInterestInvalid.
  ///
  /// In en, this message translates to:
  /// **'Must be between 0 and 99.99'**
  String get scheduledFormInterestInvalid;

  /// No description provided for @scheduledFormNoteLabel.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get scheduledFormNoteLabel;

  /// No description provided for @scheduledDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Schedule not found'**
  String get scheduledDetailNotFound;

  /// No description provided for @scheduledDetailNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This scheduled entry may have been deleted or cancelled.'**
  String get scheduledDetailNotFoundMessage;

  /// No description provided for @scheduledDetailEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get scheduledDetailEdit;

  /// No description provided for @scheduledDetailPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get scheduledDetailPause;

  /// No description provided for @scheduledDetailResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get scheduledDetailResume;

  /// No description provided for @scheduledDetailCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get scheduledDetailCancel;

  /// No description provided for @scheduledDetailDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get scheduledDetailDelete;

  /// No description provided for @scheduledDetailNextDue.
  ///
  /// In en, this message translates to:
  /// **'Next due {date}'**
  String scheduledDetailNextDue(String date);

  /// No description provided for @scheduledDetailAccount.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get scheduledDetailAccount;

  /// No description provided for @scheduledDetailCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get scheduledDetailCategory;

  /// No description provided for @scheduledDetailCycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get scheduledDetailCycle;

  /// No description provided for @scheduledDetailTotalAmount.
  ///
  /// In en, this message translates to:
  /// **'Total amount'**
  String get scheduledDetailTotalAmount;

  /// No description provided for @scheduledDetailDownPayment.
  ///
  /// In en, this message translates to:
  /// **'Down payment'**
  String get scheduledDetailDownPayment;

  /// No description provided for @scheduledDetailInstallments.
  ///
  /// In en, this message translates to:
  /// **'Installments'**
  String get scheduledDetailInstallments;

  /// No description provided for @scheduledDetailInterestRate.
  ///
  /// In en, this message translates to:
  /// **'Interest rate'**
  String get scheduledDetailInterestRate;

  /// No description provided for @scheduledDetailNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get scheduledDetailNote;

  /// No description provided for @scheduledGenerateNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate now'**
  String get scheduledGenerateNowTitle;

  /// No description provided for @scheduledGenerateNowBody.
  ///
  /// In en, this message translates to:
  /// **'Manually create the next transaction and advance the schedule. Phase 1c only — Phase 3 adds an automatic scheduler.'**
  String get scheduledGenerateNowBody;

  /// No description provided for @scheduledGenerateNowAction.
  ///
  /// In en, this message translates to:
  /// **'Generate'**
  String get scheduledGenerateNowAction;

  /// No description provided for @scheduledGenerateNowSuccess.
  ///
  /// In en, this message translates to:
  /// **'Transaction generated'**
  String get scheduledGenerateNowSuccess;

  /// No description provided for @scheduledGenerateNowViewTransaction.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get scheduledGenerateNowViewTransaction;

  /// No description provided for @scheduledDetailHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Generated transactions'**
  String get scheduledDetailHistoryTitle;

  /// No description provided for @scheduledDetailHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions have been generated yet.'**
  String get scheduledDetailHistoryEmpty;

  /// No description provided for @scheduledDetailHistoryTotal.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction} other{{count} transactions}}'**
  String scheduledDetailHistoryTotal(int count);

  /// No description provided for @scheduledCancelConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Cancel this schedule?'**
  String get scheduledCancelConfirmTitle;

  /// No description provided for @scheduledCancelConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Cancelling is final — you\'ll need to create a new entry to schedule again.'**
  String get scheduledCancelConfirmBody;

  /// No description provided for @scheduledCancelConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Cancel schedule'**
  String get scheduledCancelConfirmAction;

  /// No description provided for @scheduledDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this schedule?'**
  String get scheduledDeleteConfirmTitle;

  /// No description provided for @scheduledStatusChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change status'**
  String get scheduledStatusChangeTitle;

  /// No description provided for @scheduledDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Past generated transactions stay; only the schedule is removed.'**
  String get scheduledDeleteConfirmBody;

  /// No description provided for @scheduledDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get scheduledDeleteConfirmAction;

  /// No description provided for @projectFormPlannedLabel.
  ///
  /// In en, this message translates to:
  /// **'Planned budget'**
  String get projectFormPlannedLabel;

  /// No description provided for @projectFormPlannedHelper.
  ///
  /// In en, this message translates to:
  /// **'Optional — the total you plan to spend. Clear to turn the plan display off.'**
  String get projectFormPlannedHelper;

  /// No description provided for @projectFormPlannedInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive amount'**
  String get projectFormPlannedInvalid;

  /// No description provided for @projectFormPlannedClearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get projectFormPlannedClearTooltip;

  /// No description provided for @projectMetaPlanned.
  ///
  /// In en, this message translates to:
  /// **'Budget {amount}'**
  String projectMetaPlanned(String amount);

  /// No description provided for @projectPlannedRemainingCardLabel.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get projectPlannedRemainingCardLabel;

  /// No description provided for @projectPlannedLine.
  ///
  /// In en, this message translates to:
  /// **'Planned {planned} · {remaining} left'**
  String projectPlannedLine(String planned, String remaining);

  /// No description provided for @projectPlannedOverLine.
  ///
  /// In en, this message translates to:
  /// **'🔴 Over budget by {over}'**
  String projectPlannedOverLine(String over);

  /// No description provided for @projectSummaryPlannedLabel.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get projectSummaryPlannedLabel;

  /// No description provided for @projectSummarySpentLabel.
  ///
  /// In en, this message translates to:
  /// **'Spent (net)'**
  String get projectSummarySpentLabel;

  /// No description provided for @projectSummaryRemainingLabel.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get projectSummaryRemainingLabel;

  /// No description provided for @projectSummaryOverLabel.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get projectSummaryOverLabel;

  /// No description provided for @walletsHeaderMine.
  ///
  /// In en, this message translates to:
  /// **'Mine {amount}'**
  String walletsHeaderMine(String amount);

  /// No description provided for @walletsHeaderShared.
  ///
  /// In en, this message translates to:
  /// **'Shared {amount}'**
  String walletsHeaderShared(String amount);

  /// No description provided for @walletSharedLabel.
  ///
  /// In en, this message translates to:
  /// **'Shared wallet'**
  String get walletSharedLabel;

  /// No description provided for @walletMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get walletMembersTitle;

  /// No description provided for @walletMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String walletMembersCount(int count);

  /// No description provided for @walletMembersHistoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Past members'**
  String get walletMembersHistoryTitle;

  /// No description provided for @walletMemberRoleOwner.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get walletMemberRoleOwner;

  /// No description provided for @walletMemberRoleMember.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get walletMemberRoleMember;

  /// No description provided for @walletMemberPending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get walletMemberPending;

  /// No description provided for @walletMemberYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get walletMemberYou;

  /// No description provided for @walletMemberJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined {date}'**
  String walletMemberJoined(String date);

  /// No description provided for @walletMemberLeft.
  ///
  /// In en, this message translates to:
  /// **'Left {date}'**
  String walletMemberLeft(String date);

  /// No description provided for @walletMembersInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite by email'**
  String get walletMembersInvite;

  /// No description provided for @walletInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite member'**
  String get walletInviteTitle;

  /// No description provided for @walletInviteEmailLabel.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get walletInviteEmailLabel;

  /// No description provided for @walletInviteEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get walletInviteEmailInvalid;

  /// No description provided for @walletInviteSend.
  ///
  /// In en, this message translates to:
  /// **'Send invite'**
  String get walletInviteSend;

  /// No description provided for @walletInviteSent.
  ///
  /// In en, this message translates to:
  /// **'Invite sent'**
  String get walletInviteSent;

  /// No description provided for @walletConvertWarnTitle.
  ///
  /// In en, this message translates to:
  /// **'⚠️ Invite \"{name}\" to this wallet?'**
  String walletConvertWarnTitle(String name);

  /// No description provided for @walletConvertWarnBody.
  ///
  /// In en, this message translates to:
  /// **'Wallet {wallet} will become a shared wallet:\n• {name} will see this wallet\'s entire history (every past entry)\n• Both of you can add, edit and delete entries\n• This wallet will automatically be removed from your personal reports (you can turn it back on in settings)'**
  String walletConvertWarnBody(String wallet, String name);

  /// No description provided for @walletLeave.
  ///
  /// In en, this message translates to:
  /// **'Leave wallet'**
  String get walletLeave;

  /// No description provided for @walletLeaveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave this wallet?'**
  String get walletLeaveConfirmTitle;

  /// No description provided for @walletLeaveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your entries stay on the wallet but become read-only for you. Remaining members can still manage them.'**
  String get walletLeaveConfirmBody;

  /// No description provided for @walletLeaveAction.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get walletLeaveAction;

  /// No description provided for @walletRemoveMemberAction.
  ///
  /// In en, this message translates to:
  /// **'Remove from wallet'**
  String get walletRemoveMemberAction;

  /// No description provided for @walletRemoveMemberConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove {name}?'**
  String walletRemoveMemberConfirmTitle(String name);

  /// No description provided for @walletRemoveMemberConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Their entries stay on the wallet and become read-only for them.'**
  String get walletRemoveMemberConfirmBody;

  /// No description provided for @walletTransferOwnershipAction.
  ///
  /// In en, this message translates to:
  /// **'Make owner'**
  String get walletTransferOwnershipAction;

  /// No description provided for @walletTransferOwnershipConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership to {name}?'**
  String walletTransferOwnershipConfirmTitle(String name);

  /// No description provided for @walletTransferOwnershipConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'They will own this wallet. You stay on as a member.'**
  String get walletTransferOwnershipConfirmBody;

  /// No description provided for @walletTransferOwnershipConfirm.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get walletTransferOwnershipConfirm;

  /// No description provided for @walletTransferOwnershipSuccess.
  ///
  /// In en, this message translates to:
  /// **'Ownership transferred'**
  String get walletTransferOwnershipSuccess;

  /// No description provided for @walletSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Wallet settings'**
  String get walletSettingsTitle;

  /// No description provided for @walletSettingsMembersSubtitlePersonal.
  ///
  /// In en, this message translates to:
  /// **'Invite someone to share this wallet'**
  String get walletSettingsMembersSubtitlePersonal;

  /// No description provided for @walletReportScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'In my reports'**
  String get walletReportScopeTitle;

  /// No description provided for @walletReportScopeHelper.
  ///
  /// In en, this message translates to:
  /// **'Controls how this wallet\'s entries count in your personal summaries and budgets. The wallet page itself always shows everything.'**
  String get walletReportScopeHelper;

  /// No description provided for @walletReportScopeNone.
  ///
  /// In en, this message translates to:
  /// **'Not in reports'**
  String get walletReportScopeNone;

  /// No description provided for @walletReportScopeOwn.
  ///
  /// In en, this message translates to:
  /// **'Only my entries'**
  String get walletReportScopeOwn;

  /// No description provided for @walletReportScopeAll.
  ///
  /// In en, this message translates to:
  /// **'Whole wallet'**
  String get walletReportScopeAll;

  /// No description provided for @walletReportScopeSaved.
  ///
  /// In en, this message translates to:
  /// **'Report setting saved'**
  String get walletReportScopeSaved;

  /// No description provided for @transactionFormCategoryAuthorOnlyHint.
  ///
  /// In en, this message translates to:
  /// **'Only the author can change the category'**
  String get transactionFormCategoryAuthorOnlyHint;

  /// No description provided for @transactionFormLockedBanner.
  ///
  /// In en, this message translates to:
  /// **'Read-only — you\'re no longer a member of this wallet, so this entry can\'t be changed.'**
  String get transactionFormLockedBanner;

  /// No description provided for @notificationWalletInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'{actor} invited you to wallet \"{wallet}\"'**
  String notificationWalletInviteTitle(String actor, String wallet);

  /// No description provided for @notificationAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get notificationAccept;

  /// No description provided for @notificationReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get notificationReject;

  /// No description provided for @walletErrorNotMember.
  ///
  /// In en, this message translates to:
  /// **'You\'re not a member of this wallet.'**
  String get walletErrorNotMember;

  /// No description provided for @walletErrorOwnerMustTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer ownership first — this wallet still has other members.'**
  String get walletErrorOwnerMustTransfer;

  /// No description provided for @walletErrorHasMembers.
  ///
  /// In en, this message translates to:
  /// **'This wallet still has other members, so it can\'t be archived or deleted.'**
  String get walletErrorHasMembers;

  /// No description provided for @walletErrorCategoryAuthorOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the entry\'s author can change its category.'**
  String get walletErrorCategoryAuthorOnly;

  /// No description provided for @walletErrorRowLocked.
  ///
  /// In en, this message translates to:
  /// **'This entry is locked — you\'ve left this wallet.'**
  String get walletErrorRowLocked;

  /// No description provided for @walletErrorScopeNotAllowed.
  ///
  /// In en, this message translates to:
  /// **'Past members can only use \"Not in reports\" or \"Only my entries\".'**
  String get walletErrorScopeNotAllowed;

  /// No description provided for @walletErrorUserNotFound.
  ///
  /// In en, this message translates to:
  /// **'No user found with that email.'**
  String get walletErrorUserNotFound;

  /// No description provided for @walletErrorAlreadyMember.
  ///
  /// In en, this message translates to:
  /// **'That user is already a member of this wallet.'**
  String get walletErrorAlreadyMember;

  /// No description provided for @quickCreateToggle.
  ///
  /// In en, this message translates to:
  /// **'Create an event from this bill...'**
  String get quickCreateToggle;

  /// No description provided for @transactionSplitWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Split with…'**
  String get transactionSplitWithTitle;

  /// No description provided for @transactionSplitShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share with… (I owe them their part)'**
  String get transactionSplitShareTitle;

  /// No description provided for @quickCreateOldBillsSection.
  ///
  /// In en, this message translates to:
  /// **'Add past bills to this event (optional)'**
  String get quickCreateOldBillsSection;

  /// No description provided for @quickCreateOldBillsHint.
  ///
  /// In en, this message translates to:
  /// **'Your loose bills from the last 90 days — tick any to bring them onto the event board.'**
  String get quickCreateOldBillsHint;

  /// No description provided for @quickCreateSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search past bills'**
  String get quickCreateSearchHint;

  /// No description provided for @quickCreateOldBillsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No loose bills from the last 90 days.'**
  String get quickCreateOldBillsEmpty;

  /// No description provided for @quickCreateOldBillsSearchEmpty.
  ///
  /// In en, this message translates to:
  /// **'No bills match your search.'**
  String get quickCreateOldBillsSearchEmpty;

  /// No description provided for @quickCreateOldBillsLoadMore.
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get quickCreateOldBillsLoadMore;

  /// No description provided for @quickCreateOldBillsRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get quickCreateOldBillsRetry;

  /// No description provided for @quickCreateSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String quickCreateSelectedCount(int count);

  /// No description provided for @quickCreateNameSection.
  ///
  /// In en, this message translates to:
  /// **'Event name'**
  String get quickCreateNameSection;

  /// No description provided for @quickCreateNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Event name'**
  String get quickCreateNameLabel;

  /// No description provided for @quickCreateNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter an event name'**
  String get quickCreateNameRequired;

  /// No description provided for @quickCreateDefaultName.
  ///
  /// In en, this message translates to:
  /// **'{members} · {date}'**
  String quickCreateDefaultName(String members, String date);

  /// No description provided for @quickCreateDefaultNameSolo.
  ///
  /// In en, this message translates to:
  /// **'Event · {date}'**
  String quickCreateDefaultNameSolo(String date);

  /// No description provided for @quickCreateSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get quickCreateSubmit;

  /// No description provided for @quickCreateErrorTxNotFound.
  ///
  /// In en, this message translates to:
  /// **'Some selected bills no longer exist — refresh and try again.'**
  String get quickCreateErrorTxNotFound;

  /// No description provided for @quickCreateErrorTxAlreadyInProject.
  ///
  /// In en, this message translates to:
  /// **'Some selected bills already belong to another event — refresh and try again.'**
  String get quickCreateErrorTxAlreadyInProject;

  /// No description provided for @quickCreateErrorValidation.
  ///
  /// In en, this message translates to:
  /// **'Something\'s not right — check the form and try again.'**
  String get quickCreateErrorValidation;
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
