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

  /// No description provided for @commonName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get commonName;

  /// No description provided for @commonDescription.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get commonDescription;

  /// No description provided for @commonNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get commonNote;

  /// No description provided for @editDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard your changes?'**
  String get editDiscardTitle;

  /// No description provided for @editDiscardMessage.
  ///
  /// In en, this message translates to:
  /// **'What you changed won\'t be saved.'**
  String get editDiscardMessage;

  /// No description provided for @editKeepEditing.
  ///
  /// In en, this message translates to:
  /// **'Keep editing'**
  String get editKeepEditing;

  /// No description provided for @editDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard changes'**
  String get editDiscardConfirm;

  /// No description provided for @categorySystemOpening.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get categorySystemOpening;

  /// No description provided for @categorySystemAdjustment.
  ///
  /// In en, this message translates to:
  /// **'Balance adjustment'**
  String get categorySystemAdjustment;

  /// No description provided for @categorySystemTransferIn.
  ///
  /// In en, this message translates to:
  /// **'Transfer in'**
  String get categorySystemTransferIn;

  /// No description provided for @categorySystemTransferOut.
  ///
  /// In en, this message translates to:
  /// **'Transfer out'**
  String get categorySystemTransferOut;

  /// No description provided for @categorySystemDebtReceived.
  ///
  /// In en, this message translates to:
  /// **'Debt received'**
  String get categorySystemDebtReceived;

  /// No description provided for @categorySystemDebtPaid.
  ///
  /// In en, this message translates to:
  /// **'Debt paid'**
  String get categorySystemDebtPaid;

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

  /// No description provided for @commonCustomValue.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get commonCustomValue;

  /// No description provided for @uiPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date'**
  String get uiPickDate;

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

  /// No description provided for @errorValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Some fields aren’t valid — please check them'**
  String get errorValidationMessage;

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

  /// No description provided for @navDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// No description provided for @homeComingSoonTitle.
  ///
  /// In en, this message translates to:
  /// **'Coming Soon'**
  String get homeComingSoonTitle;

  /// No description provided for @homeComingSoonMessage.
  ///
  /// In en, this message translates to:
  /// **'The overview is being reworked. Use the tabs below in the meantime.'**
  String get homeComingSoonMessage;

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

  /// No description provided for @appExitTitle.
  ///
  /// In en, this message translates to:
  /// **'Close the app?'**
  String get appExitTitle;

  /// No description provided for @appExitConfirm.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get appExitConfirm;

  /// No description provided for @navProjects.
  ///
  /// In en, this message translates to:
  /// **'Events'**
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

  /// No description provided for @accountsAddNew.
  ///
  /// In en, this message translates to:
  /// **'Add wallet'**
  String get accountsAddNew;

  /// No description provided for @accountsReorderHint.
  ///
  /// In en, this message translates to:
  /// **'Drag ≡ to reorder. This order is yours only — it never moves wallets for other members.'**
  String get accountsReorderHint;

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

  /// No description provided for @accountDetailTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get accountDetailTabOverview;

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

  /// No description provided for @accountFormTypeLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get accountFormTypeLabel;

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

  /// No description provided for @accountAdjustBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust balance'**
  String get accountAdjustBalanceTitle;

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

  /// No description provided for @accountAdjustBalanceNoChange.
  ///
  /// In en, this message translates to:
  /// **'New balance must differ from the current balance.'**
  String get accountAdjustBalanceNoChange;

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

  /// No description provided for @accountFormNoteHelper.
  ///
  /// In en, this message translates to:
  /// **'Anything you want to jot down. The wallet\'s members see it too.'**
  String get accountFormNoteHelper;

  /// No description provided for @iconPickerUseThis.
  ///
  /// In en, this message translates to:
  /// **'Use this'**
  String get iconPickerUseThis;

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

  /// No description provided for @iconMakerThemeColors.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get iconMakerThemeColors;

  /// No description provided for @iconMakerReset.
  ///
  /// In en, this message translates to:
  /// **'Reset to default'**
  String get iconMakerReset;

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
  /// **'No events yet'**
  String get projectsPlaceholderTitle;

  /// No description provided for @projectsPlaceholderMessage.
  ///
  /// In en, this message translates to:
  /// **'Create an event to track costs you share with others.'**
  String get projectsPlaceholderMessage;

  /// No description provided for @moreCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get moreCategories;

  /// No description provided for @moreProjects.
  ///
  /// In en, this message translates to:
  /// **'Events'**
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

  /// No description provided for @contactsNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another search or change the status filter'**
  String get contactsNoMatchMessage;

  /// No description provided for @contactsArchivedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No archived contacts'**
  String get contactsArchivedEmptyTitle;

  /// No description provided for @contactsArchivedEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Archived contacts show up here — hidden from pickers, history kept'**
  String get contactsArchivedEmptyMessage;

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

  /// No description provided for @contactNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name (required)'**
  String get contactNameHint;

  /// No description provided for @contactEmailHint.
  ///
  /// In en, this message translates to:
  /// **'Optional | name@example.com'**
  String get contactEmailHint;

  /// No description provided for @contactPhoneHint.
  ///
  /// In en, this message translates to:
  /// **'Optional | 081-234-5678'**
  String get contactPhoneHint;

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

  /// No description provided for @contactDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Optional | e.g. a work friend'**
  String get contactDescriptionHint;

  /// No description provided for @contactNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Optional | e.g. prefers PromptPay'**
  String get contactNoteHint;

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

  /// No description provided for @contactEmailFromAccount.
  ///
  /// In en, this message translates to:
  /// **'From their account'**
  String get contactEmailFromAccount;

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
  /// **'Link names you typed before'**
  String get contactWireTitle;

  /// No description provided for @contactWireHint.
  ///
  /// In en, this message translates to:
  /// **'{names} names | {splits} entries not linked to anyone'**
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
  /// **'Owes me'**
  String get debtsOwedToMe;

  /// No description provided for @debtsIOwe.
  ///
  /// In en, this message translates to:
  /// **'I owe'**
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

  /// No description provided for @debtsPersonAddContact.
  ///
  /// In en, this message translates to:
  /// **'Add to contacts'**
  String get debtsPersonAddContact;

  /// No description provided for @debtsPersonAddContactHint.
  ///
  /// In en, this message translates to:
  /// **'Add this name to an existing contact or create a new one'**
  String get debtsPersonAddContactHint;

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
  /// **'Event'**
  String get debtSourceProject;

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
  /// **'Add the person first'**
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
  /// **'To receive'**
  String get debtDirectionOwedToMe;

  /// No description provided for @debtDirectionOwedToMeDesc.
  ///
  /// In en, this message translates to:
  /// **'I lent money or paid for them'**
  String get debtDirectionOwedToMeDesc;

  /// No description provided for @debtDirectionIOwe.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
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
  /// **'Search events'**
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
  /// **'No events yet'**
  String get projectsEmptyTitle;

  /// No description provided for @projectsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Keep a trip or a job\'s spending in one place, then settle up with friends at the end.'**
  String get projectsEmptyMessage;

  /// No description provided for @projectsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching events'**
  String get projectsNoMatch;

  /// No description provided for @projectsMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String projectsMembersCount(int count);

  /// No description provided for @projectTabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
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
  /// **'New event'**
  String get projectNewTitle;

  /// No description provided for @projectEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit event'**
  String get projectEditTitle;

  /// No description provided for @projectNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Event name'**
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

  /// No description provided for @projectIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Event icon'**
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
  /// **'The event gets locked: no adding or editing transactions until it is reopened.'**
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
  /// **'Only events without transactions can be deleted. If it has some, archive it instead.'**
  String get projectDeleteBody;

  /// No description provided for @projectDeleted.
  ///
  /// In en, this message translates to:
  /// **'Event deleted'**
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

  /// No description provided for @projectDashTopTags.
  ///
  /// In en, this message translates to:
  /// **'Top tags'**
  String get projectDashTopTags;

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

  /// No description provided for @projectTxSortTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get projectTxSortTag;

  /// No description provided for @projectTxEmpty.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this event yet'**
  String get projectTxEmpty;

  /// No description provided for @projectTxNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching transactions'**
  String get projectTxNoMatch;

  /// No description provided for @projectTxOwes.
  ///
  /// In en, this message translates to:
  /// **'I owe {name}'**
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
  /// **'Full {full} | my share {share}'**
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
  /// **'The person comes from the event member'**
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

  /// No description provided for @projectRoleViewer.
  ///
  /// In en, this message translates to:
  /// **'View only'**
  String get projectRoleViewer;

  /// No description provided for @projectMemberMakeViewer.
  ///
  /// In en, this message translates to:
  /// **'Make view-only'**
  String get projectMemberMakeViewer;

  /// No description provided for @projectMemberMakeContributor.
  ///
  /// In en, this message translates to:
  /// **'Allow editing (member)'**
  String get projectMemberMakeContributor;

  /// No description provided for @projectMemberRoleChanged.
  ///
  /// In en, this message translates to:
  /// **'Access updated'**
  String get projectMemberRoleChanged;

  /// No description provided for @projectMyPosition.
  ///
  /// In en, this message translates to:
  /// **'Me: paid {paid} | my share {share}'**
  String projectMyPosition(String paid, String share);

  /// No description provided for @projectMyNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get projectMyNet;

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
  /// **'Leave event'**
  String get projectLeave;

  /// No description provided for @projectLeaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave {name}?'**
  String projectLeaveTitle(String name);

  /// No description provided for @projectLeaveBody.
  ///
  /// In en, this message translates to:
  /// **'You will not see this event again unless you are invited back.'**
  String get projectLeaveBody;

  /// No description provided for @projectLeft.
  ///
  /// In en, this message translates to:
  /// **'You left the event'**
  String get projectLeft;

  /// No description provided for @projectMemberRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove from event'**
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
  /// **'Only members with an app account can own an event'**
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
  /// **'Add event transaction'**
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

  /// No description provided for @projectTxTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get projectTxTags;

  /// No description provided for @projectTxAddTag.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get projectTxAddTag;

  /// No description provided for @projectTxTagHint.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get projectTxTagHint;

  /// No description provided for @projectTxDescriptionHint.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get projectTxDescriptionHint;

  /// No description provided for @projectTxDescriptionUse.
  ///
  /// In en, this message translates to:
  /// **'Use \"{text}\"'**
  String projectTxDescriptionUse(String text);

  /// No description provided for @projectTxDescriptionPast.
  ///
  /// In en, this message translates to:
  /// **'Used before in this event'**
  String get projectTxDescriptionPast;

  /// No description provided for @projectTxSplitMember.
  ///
  /// In en, this message translates to:
  /// **'Who'**
  String get projectTxSplitMember;

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

  /// No description provided for @settingsNotificationsSummary.
  ///
  /// In en, this message translates to:
  /// **'{on} on | {auto} automatic'**
  String settingsNotificationsSummary(int on, int auto);

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

  /// No description provided for @notificationsMarkAllRead.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAllRead;

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

  /// No description provided for @notifProjectTxForYou.
  ///
  /// In en, this message translates to:
  /// **'{actor} recorded an event transaction for you'**
  String notifProjectTxForYou(String actor);

  /// No description provided for @notifProjectTxChanged.
  ///
  /// In en, this message translates to:
  /// **'{actor} edited an event transaction'**
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
  /// **'Accepted | tap to open'**
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

  /// No description provided for @notifGroupSplits.
  ///
  /// In en, this message translates to:
  /// **'Bill splits'**
  String get notifGroupSplits;

  /// No description provided for @notifGroupProjects.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get notifGroupProjects;

  /// No description provided for @notifGroupRequests.
  ///
  /// In en, this message translates to:
  /// **'Invites and requests'**
  String get notifGroupRequests;

  /// No description provided for @notifTypeSplitCreated.
  ///
  /// In en, this message translates to:
  /// **'Someone splits a bill with me'**
  String get notifTypeSplitCreated;

  /// No description provided for @notifTypeProjectTxForYou.
  ///
  /// In en, this message translates to:
  /// **'An event transaction is recorded for me'**
  String get notifTypeProjectTxForYou;

  /// No description provided for @notifTypeProjectTxChanged.
  ///
  /// In en, this message translates to:
  /// **'An event transaction is edited'**
  String get notifTypeProjectTxChanged;

  /// No description provided for @notifTypeAlwaysOn.
  ///
  /// In en, this message translates to:
  /// **'Always on'**
  String get notifTypeAlwaysOn;

  /// No description provided for @notifTypeProjectAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to an event'**
  String get notifTypeProjectAdded;

  /// No description provided for @notifAutoAddDebt.
  ///
  /// In en, this message translates to:
  /// **'Auto: add to my debts'**
  String get notifAutoAddDebt;

  /// No description provided for @notifAutoCopyToBook.
  ///
  /// In en, this message translates to:
  /// **'Auto: add to my book'**
  String get notifAutoCopyToBook;

  /// No description provided for @notifAutoUpdateCopy.
  ///
  /// In en, this message translates to:
  /// **'Auto: update my copy to match'**
  String get notifAutoUpdateCopy;

  /// No description provided for @notifActionAddDebt.
  ///
  /// In en, this message translates to:
  /// **'Add to my debts'**
  String get notifActionAddDebt;

  /// No description provided for @notifActionCopyToBook.
  ///
  /// In en, this message translates to:
  /// **'Add to my book'**
  String get notifActionCopyToBook;

  /// No description provided for @notifActionUpdateCopy.
  ///
  /// In en, this message translates to:
  /// **'Update to match'**
  String get notifActionUpdateCopy;

  /// No description provided for @notifActionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get notifActionSkip;

  /// No description provided for @notifActionDone.
  ///
  /// In en, this message translates to:
  /// **'Done | tap to open'**
  String get notifActionDone;

  /// No description provided for @notifProjectAdded.
  ///
  /// In en, this message translates to:
  /// **'{actor} added you to {project}'**
  String notifProjectAdded(String actor, String project);

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

  /// No description provided for @homeUpcomingInDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =0{Today} =1{Tomorrow} other{In {days} days}}'**
  String homeUpcomingInDays(int days);

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

  /// No description provided for @homeAssets.
  ///
  /// In en, this message translates to:
  /// **'Assets'**
  String get homeAssets;

  /// No description provided for @homeLiabilities.
  ///
  /// In en, this message translates to:
  /// **'Liabilities'**
  String get homeLiabilities;

  /// No description provided for @homeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get homeIncome;

  /// No description provided for @homeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get homeExpense;

  /// No description provided for @homeLeftOver.
  ///
  /// In en, this message translates to:
  /// **'Left over'**
  String get homeLeftOver;

  /// No description provided for @homeVsPrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Spending vs last month'**
  String get homeVsPrevMonth;

  /// No description provided for @homeComingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get homeComingUp;

  /// No description provided for @homeComingUpWindow.
  ///
  /// In en, this message translates to:
  /// **'{days} days'**
  String homeComingUpWindow(int days);

  /// No description provided for @homeOverdueDays.
  ///
  /// In en, this message translates to:
  /// **'{days, plural, =1{1 day late} other{{days} days late}}'**
  String homeOverdueDays(int days);

  /// No description provided for @homeCardDue.
  ///
  /// In en, this message translates to:
  /// **'Card payment'**
  String get homeCardDue;

  /// No description provided for @homeWhereMoneyWent.
  ///
  /// In en, this message translates to:
  /// **'Where it went'**
  String get homeWhereMoneyWent;

  /// No description provided for @homeOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get homeOther;

  /// No description provided for @homeUncategorized.
  ///
  /// In en, this message translates to:
  /// **'No category'**
  String get homeUncategorized;

  /// No description provided for @homeNoExpense.
  ///
  /// In en, this message translates to:
  /// **'No spending this month yet'**
  String get homeNoExpense;

  /// No description provided for @homeTrend.
  ///
  /// In en, this message translates to:
  /// **'Income vs expense, 6 months'**
  String get homeTrend;

  /// No description provided for @homeBudgetsUsed.
  ///
  /// In en, this message translates to:
  /// **'{pct}% used'**
  String homeBudgetsUsed(String pct);

  /// No description provided for @homeBudgetsOver.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 over budget} other{{count} over budget}}'**
  String homeBudgetsOver(int count);

  /// No description provided for @homeBudgetsNone.
  ///
  /// In en, this message translates to:
  /// **'No budgets yet'**
  String get homeBudgetsNone;

  /// No description provided for @homeDebtsOpen.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 open} other{{count} open}}'**
  String homeDebtsOpen(int count);

  /// No description provided for @homeDebtsNone.
  ///
  /// In en, this message translates to:
  /// **'All settled'**
  String get homeDebtsNone;

  /// No description provided for @homeGoalsCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 goal} other{{count} goals}}'**
  String homeGoalsCount(int count);

  /// No description provided for @homeGoalsNone.
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get homeGoalsNone;

  /// No description provided for @homeLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load the dashboard'**
  String get homeLoadError;

  /// No description provided for @homePrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get homePrevMonth;

  /// No description provided for @homeNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get homeNextMonth;

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

  /// No description provided for @transactionsFilterTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get transactionsFilterTag;

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

  /// No description provided for @txDetailSplits.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get txDetailSplits;

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

  /// No description provided for @txDetailSourceProject.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get txDetailSourceProject;

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

  /// No description provided for @txDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get txDeleted;

  /// No description provided for @txDeleteRecurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction?'**
  String get txDeleteRecurringTitle;

  /// No description provided for @txDeleteRecurringBody.
  ///
  /// In en, this message translates to:
  /// **'Linked to {name}'**
  String txDeleteRecurringBody(String name);

  /// No description provided for @txDeleteRecurringOnly.
  ///
  /// In en, this message translates to:
  /// **'Delete only (the occurrence is due again)'**
  String get txDeleteRecurringOnly;

  /// No description provided for @txDeleteRecurringSkip.
  ///
  /// In en, this message translates to:
  /// **'Delete and skip the occurrence'**
  String get txDeleteRecurringSkip;

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
  /// **'To pay'**
  String get txSplitOwes;

  /// No description provided for @txSplitRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get txSplitRemove;

  /// No description provided for @txSplitExceeds.
  ///
  /// In en, this message translates to:
  /// **'Split total is more than the transaction amount'**
  String get txSplitExceeds;

  /// No description provided for @txSavedTagsFailed.
  ///
  /// In en, this message translates to:
  /// **'Saved, but the tags didn\'t stick — edit them on the transaction'**
  String get txSavedTagsFailed;

  /// No description provided for @txTransferNeedsTo.
  ///
  /// In en, this message translates to:
  /// **'Pick the destination wallet'**
  String get txTransferNeedsTo;

  /// No description provided for @txTransferSameWallet.
  ///
  /// In en, this message translates to:
  /// **'Source and destination must be different wallets'**
  String get txTransferSameWallet;

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

  /// No description provided for @accountsTotalShared.
  ///
  /// In en, this message translates to:
  /// **'Shared pot'**
  String get accountsTotalShared;

  /// No description provided for @accountsSummaryNet.
  ///
  /// In en, this message translates to:
  /// **'My net balance'**
  String get accountsSummaryNet;

  /// No description provided for @accountsSummaryWalletCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 wallet} other{{count} wallets}}'**
  String accountsSummaryWalletCount(int count);

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
  /// **'Group your entries'**
  String get moreCategoriesDesc;

  /// No description provided for @moreTagsDesc.
  ///
  /// In en, this message translates to:
  /// **'Labels for quick search'**
  String get moreTagsDesc;

  /// No description provided for @moreContactsDesc.
  ///
  /// In en, this message translates to:
  /// **'People in your bills and debts'**
  String get moreContactsDesc;

  /// No description provided for @moreProjectsDesc.
  ///
  /// In en, this message translates to:
  /// **'Trips and shared-cost activities'**
  String get moreProjectsDesc;

  /// No description provided for @moreDebtsDesc.
  ///
  /// In en, this message translates to:
  /// **'Loans and money owed'**
  String get moreDebtsDesc;

  /// No description provided for @moreBudgetsDesc.
  ///
  /// In en, this message translates to:
  /// **'Keep monthly spending in check'**
  String get moreBudgetsDesc;

  /// No description provided for @moreSavingGoalsDesc.
  ///
  /// In en, this message translates to:
  /// **'Save for what you want'**
  String get moreSavingGoalsDesc;

  /// No description provided for @moreScheduledDesc.
  ///
  /// In en, this message translates to:
  /// **'Recurring & upcoming bills'**
  String get moreScheduledDesc;

  /// No description provided for @moreChipOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get moreChipOverBudget;

  /// No description provided for @moreChipNearBudget.
  ///
  /// In en, this message translates to:
  /// **'Near limit'**
  String get moreChipNearBudget;

  /// No description provided for @moreChipGoalReached.
  ///
  /// In en, this message translates to:
  /// **'Goal reached'**
  String get moreChipGoalReached;

  /// No description provided for @moreChipNearGoal.
  ///
  /// In en, this message translates to:
  /// **'Near goal'**
  String get moreChipNearGoal;

  /// No description provided for @moreChipDueSoon.
  ///
  /// In en, this message translates to:
  /// **'{count} due soon'**
  String moreChipDueSoon(int count);

  /// No description provided for @moreChipReceivable.
  ///
  /// In en, this message translates to:
  /// **'To receive {amount}'**
  String moreChipReceivable(String amount);

  /// No description provided for @moreChipPayable.
  ///
  /// In en, this message translates to:
  /// **'To pay {amount}'**
  String moreChipPayable(String amount);

  /// No description provided for @moreChipOpenEvents.
  ///
  /// In en, this message translates to:
  /// **'{count} open'**
  String moreChipOpenEvents(int count);

  /// No description provided for @moreChipPending.
  ///
  /// In en, this message translates to:
  /// **'{count} to confirm'**
  String moreChipPending(int count);

  /// No description provided for @moreChipUnread.
  ///
  /// In en, this message translates to:
  /// **'{count} unread'**
  String moreChipUnread(int count);

  /// No description provided for @categoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get categoriesTitle;

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

  /// No description provided for @categoryDetailNotFound.
  ///
  /// In en, this message translates to:
  /// **'Category not found'**
  String get categoryDetailNotFound;

  /// No description provided for @categoryDetailNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'This category may have been deleted.'**
  String get categoryDetailNotFoundMessage;

  /// No description provided for @categoriesLimitReached.
  ///
  /// In en, this message translates to:
  /// **'100-category limit reached. Delete one to add another.'**
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

  /// No description provided for @budgetDeleteThis.
  ///
  /// In en, this message translates to:
  /// **'Delete this budget'**
  String get budgetDeleteThis;

  /// No description provided for @savingGoalDeleteThis.
  ///
  /// In en, this message translates to:
  /// **'Delete this goal'**
  String get savingGoalDeleteThis;

  /// No description provided for @contactDeleteThis.
  ///
  /// In en, this message translates to:
  /// **'Delete this contact'**
  String get contactDeleteThis;

  /// No description provided for @debtDeleteThis.
  ///
  /// In en, this message translates to:
  /// **'Delete this debt'**
  String get debtDeleteThis;

  /// No description provided for @projectDeleteThis.
  ///
  /// In en, this message translates to:
  /// **'Delete this event'**
  String get projectDeleteThis;

  /// No description provided for @scheduledDeleteThis.
  ///
  /// In en, this message translates to:
  /// **'Delete this schedule'**
  String get scheduledDeleteThis;

  /// No description provided for @transactionDeleteThis.
  ///
  /// In en, this message translates to:
  /// **'Delete this transaction'**
  String get transactionDeleteThis;

  /// No description provided for @transactionDeleteConsequence.
  ///
  /// In en, this message translates to:
  /// **'Deleted for good | the wallet balance goes back to before it was saved'**
  String get transactionDeleteConsequence;

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

  /// No description provided for @categoriesUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get categoriesUndo;

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

  /// No description provided for @tagFormTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit tag'**
  String get tagFormTitleEdit;

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

  /// No description provided for @editProfileSnackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Profile updated'**
  String get editProfileSnackSuccess;

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

  /// No description provided for @quickSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get quickSave;

  /// No description provided for @quickSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get quickSaved;

  /// No description provided for @txHeroTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s it for?'**
  String get txHeroTitleHint;

  /// No description provided for @txDetailRepaymentBanner.
  ///
  /// In en, this message translates to:
  /// **'Recorded from a debt repayment — it can\'t be edited, but it can be deleted (the debt\'s repaid amount goes down).'**
  String get txDetailRepaymentBanner;

  /// No description provided for @debtOverpaid.
  ///
  /// In en, this message translates to:
  /// **'Overpaid'**
  String get debtOverpaid;

  /// No description provided for @debtOverpaidIOwe.
  ///
  /// In en, this message translates to:
  /// **'Overpaid | I owe them back'**
  String get debtOverpaidIOwe;

  /// No description provided for @debtOverpaidTheyOwe.
  ///
  /// In en, this message translates to:
  /// **'Overpaid | they owe me back'**
  String get debtOverpaidTheyOwe;

  /// No description provided for @debtOverpaidCantSettle.
  ///
  /// In en, this message translates to:
  /// **'This debt is already overpaid — nothing more to record'**
  String get debtOverpaidCantSettle;

  /// No description provided for @txDetailDeleteRepaymentBody.
  ///
  /// In en, this message translates to:
  /// **'The debt\'s repaid amount goes down by {amount}.'**
  String txDetailDeleteRepaymentBody(String amount);

  /// No description provided for @notifTypeSplitChanged.
  ///
  /// In en, this message translates to:
  /// **'Someone changes a split with me'**
  String get notifTypeSplitChanged;

  /// No description provided for @notifAutoApplySplitChange.
  ///
  /// In en, this message translates to:
  /// **'Auto: update my debt to match'**
  String get notifAutoApplySplitChange;

  /// No description provided for @notifSplitAmountChanged.
  ///
  /// In en, this message translates to:
  /// **'{who} changed the split {what}: {from} → {to}'**
  String notifSplitAmountChanged(
    String who,
    String what,
    String from,
    String to,
  );

  /// No description provided for @notifSplitRemovedYou.
  ///
  /// In en, this message translates to:
  /// **'{who} removed you from the split {what}'**
  String notifSplitRemovedYou(String who, String what);

  /// No description provided for @notifSplitChangeUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your debt was updated'**
  String get notifSplitChangeUpdated;

  /// No description provided for @notifSplitChangeDeleted.
  ///
  /// In en, this message translates to:
  /// **'That debt was removed'**
  String get notifSplitChangeDeleted;

  /// No description provided for @notifSplitChangeZeroed.
  ///
  /// In en, this message translates to:
  /// **'Your share is now 0 — what you paid counts as overpaid'**
  String get notifSplitChangeZeroed;

  /// No description provided for @notifSplitChangeUsed.
  ///
  /// In en, this message translates to:
  /// **'Already updated'**
  String get notifSplitChangeUsed;

  /// No description provided for @notifSplitChangeStale.
  ///
  /// In en, this message translates to:
  /// **'Can\'t update any more — there\'s a newer change'**
  String get notifSplitChangeStale;

  /// No description provided for @notifSplitChangeGone.
  ///
  /// In en, this message translates to:
  /// **'That debt was deleted'**
  String get notifSplitChangeGone;

  /// No description provided for @txSplitStatusOverpaidToThem.
  ///
  /// In en, this message translates to:
  /// **'Overpaid {amount} | you owe it back'**
  String txSplitStatusOverpaidToThem(String amount);

  /// No description provided for @txSplitStatusOverpaidByMe.
  ///
  /// In en, this message translates to:
  /// **'Overpaid {amount} | they owe it back'**
  String txSplitStatusOverpaidByMe(String amount);

  /// No description provided for @txSplitRepaidSoFar.
  ///
  /// In en, this message translates to:
  /// **'Paid back {amount}'**
  String txSplitRepaidSoFar(String amount);

  /// No description provided for @txSplitErrorContact.
  ///
  /// In en, this message translates to:
  /// **'That contact can\'t be used any more'**
  String get txSplitErrorContact;

  /// No description provided for @txSplitEditOnDebts.
  ///
  /// In en, this message translates to:
  /// **'Edit on the debts page'**
  String get txSplitEditOnDebts;

  /// No description provided for @txSplitStatusPaid.
  ///
  /// In en, this message translates to:
  /// **'✓ Paid'**
  String get txSplitStatusPaid;

  /// No description provided for @txSplitStatusRepaid.
  ///
  /// In en, this message translates to:
  /// **'✓ Repaid'**
  String get txSplitStatusRepaid;

  /// No description provided for @txSplitStatusAwaiting.
  ///
  /// In en, this message translates to:
  /// **'Owes you {amount}'**
  String txSplitStatusAwaiting(String amount);

  /// No description provided for @txSplitStatusToPay.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount}'**
  String txSplitStatusToPay(String amount);

  /// No description provided for @txSplitStatusPartPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid {paid} of {total}'**
  String txSplitStatusPartPaid(String paid, String total);

  /// No description provided for @txSplitStatusPartRepaid.
  ///
  /// In en, this message translates to:
  /// **'Repaid {paid} of {total}'**
  String txSplitStatusPartRepaid(String paid, String total);

  /// No description provided for @txSplitStatusCancelled.
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get txSplitStatusCancelled;

  /// No description provided for @txDetailMetaRecordedBy.
  ///
  /// In en, this message translates to:
  /// **'Recorded by {name}'**
  String txDetailMetaRecordedBy(String name);

  /// No description provided for @txTypeLockedHint.
  ///
  /// In en, this message translates to:
  /// **'The type can\'t change after saving'**
  String get txTypeLockedHint;

  /// No description provided for @txDetailSplitEditElsewhere.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 person} other{{count} people}} | edit on the debts page'**
  String txDetailSplitEditElsewhere(int count);

  /// No description provided for @txDetailCreatedAt.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get txDetailCreatedAt;

  /// No description provided for @txDetailUpdatedAt.
  ///
  /// In en, this message translates to:
  /// **'Last edited'**
  String get txDetailUpdatedAt;

  /// No description provided for @txSplitShareShort.
  ///
  /// In en, this message translates to:
  /// **'Share with'**
  String get txSplitShareShort;

  /// No description provided for @tagPickerCreateNamed.
  ///
  /// In en, this message translates to:
  /// **'Create “{name}”'**
  String tagPickerCreateNamed(String name);

  /// No description provided for @txNoteAddHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. where, with whom'**
  String get txNoteAddHint;

  /// No description provided for @bgNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. why this limit, or what you want to spend less on'**
  String get bgNoteHint;

  /// No description provided for @projectNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. where you stay, group rules, or the account to pay into'**
  String get projectNoteHint;

  /// No description provided for @recurringNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. contract number, billing day, or how you pay'**
  String get recurringNoteHint;

  /// No description provided for @fpGoalsNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. what it is for, or how you plan to save'**
  String get fpGoalsNoteHint;

  /// No description provided for @categoryNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. which spending belongs here'**
  String get categoryNoteHint;

  /// No description provided for @debtNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. what it was for'**
  String get debtNoteHint;

  /// No description provided for @quickEventNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get quickEventNone;

  /// No description provided for @quickUnsavedTitle.
  ///
  /// In en, this message translates to:
  /// **'Not saved yet'**
  String get quickUnsavedTitle;

  /// No description provided for @quickUnsavedMessage.
  ///
  /// In en, this message translates to:
  /// **'Close now and this entry is lost.'**
  String get quickUnsavedMessage;

  /// No description provided for @quickDiscardEntry.
  ///
  /// In en, this message translates to:
  /// **'Discard this entry'**
  String get quickDiscardEntry;

  /// No description provided for @txSplitIncompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Some split rows aren\'t complete'**
  String get txSplitIncompleteTitle;

  /// No description provided for @txSplitIncompleteNoName.
  ///
  /// In en, this message translates to:
  /// **'{amount} — no name yet'**
  String txSplitIncompleteNoName(String amount);

  /// No description provided for @txSplitIncompleteNoAmount.
  ///
  /// In en, this message translates to:
  /// **'{name} — no amount yet'**
  String txSplitIncompleteNoAmount(String name);

  /// No description provided for @txSplitSkipIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Save without these rows'**
  String get txSplitSkipIncomplete;

  /// No description provided for @txTagCreateFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t create the tag'**
  String get txTagCreateFailed;

  /// No description provided for @quickEventUseName.
  ///
  /// In en, this message translates to:
  /// **'Use this name'**
  String get quickEventUseName;

  /// No description provided for @quickEventCreatedOnSave.
  ///
  /// In en, this message translates to:
  /// **'The event is created when you save.'**
  String get quickEventCreatedOnSave;

  /// No description provided for @projectTxPayerRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a member first'**
  String get projectTxPayerRequired;

  /// No description provided for @scheduledHeroNameHint.
  ///
  /// In en, this message translates to:
  /// **'What\'s it for, e.g. Netflix'**
  String get scheduledHeroNameHint;

  /// No description provided for @quickFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get quickFrom;

  /// No description provided for @quickTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get quickTo;

  /// No description provided for @quickSwap.
  ///
  /// In en, this message translates to:
  /// **'Swap source and destination'**
  String get quickSwap;

  /// No description provided for @quickPickWallet.
  ///
  /// In en, this message translates to:
  /// **'Pick a wallet'**
  String get quickPickWallet;

  /// No description provided for @quickAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount first'**
  String get quickAmountRequired;

  /// No description provided for @quickDiscardConfirm.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get quickDiscardConfirm;

  /// No description provided for @quickAddToEvent.
  ///
  /// In en, this message translates to:
  /// **'Add to an event'**
  String get quickAddToEvent;

  /// No description provided for @quickEventLabel.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get quickEventLabel;

  /// No description provided for @quickEventNewNamed.
  ///
  /// In en, this message translates to:
  /// **'New: {name}'**
  String quickEventNewNamed(String name);

  /// No description provided for @quickEventRemove.
  ///
  /// In en, this message translates to:
  /// **'Don\'t add to an event'**
  String get quickEventRemove;

  /// No description provided for @quickEventNew.
  ///
  /// In en, this message translates to:
  /// **'Create a new event'**
  String get quickEventNew;

  /// No description provided for @quickEventNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Event name'**
  String get quickEventNameLabel;

  /// No description provided for @quickEventExisting.
  ///
  /// In en, this message translates to:
  /// **'Or add to an existing event'**
  String get quickEventExisting;

  /// No description provided for @quickEventNoneYet.
  ///
  /// In en, this message translates to:
  /// **'No open events yet'**
  String get quickEventNoneYet;

  /// No description provided for @quickEventDefaultName.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get quickEventDefaultName;

  /// No description provided for @quickEventNeedsWallet.
  ///
  /// In en, this message translates to:
  /// **'Adding to an event needs a wallet'**
  String get quickEventNeedsWallet;

  /// No description provided for @pendingTitle.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingTitle;

  /// No description provided for @pendingTooltip.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pendingTooltip;

  /// No description provided for @pendingImportSlip.
  ///
  /// In en, this message translates to:
  /// **'Import slips'**
  String get pendingImportSlip;

  /// No description provided for @pendingTypeIt.
  ///
  /// In en, this message translates to:
  /// **'Type a draft'**
  String get pendingTypeIt;

  /// No description provided for @pendingChatHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. coffee 65'**
  String get pendingChatHint;

  /// No description provided for @pendingChatSend.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get pendingChatSend;

  /// No description provided for @pendingChatClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get pendingChatClose;

  /// No description provided for @pendingScanning.
  ///
  /// In en, this message translates to:
  /// **'Reading slips…'**
  String get pendingScanning;

  /// No description provided for @pendingScanDone.
  ///
  /// In en, this message translates to:
  /// **'Slips imported'**
  String get pendingScanDone;

  /// No description provided for @pendingSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get pendingSelectAll;

  /// No description provided for @pendingSelectNone.
  ///
  /// In en, this message translates to:
  /// **'Select none'**
  String get pendingSelectNone;

  /// No description provided for @pendingSelectOne.
  ///
  /// In en, this message translates to:
  /// **'Select this one'**
  String get pendingSelectOne;

  /// No description provided for @pendingFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All {count}'**
  String pendingFilterAll(int count);

  /// No description provided for @pendingFilterManual.
  ///
  /// In en, this message translates to:
  /// **'Mine {count}'**
  String pendingFilterManual(int count);

  /// No description provided for @pendingFilterOthers.
  ///
  /// In en, this message translates to:
  /// **'From others {count}'**
  String pendingFilterOthers(int count);

  /// No description provided for @pendingResult.
  ///
  /// In en, this message translates to:
  /// **'Saved {done} | {failed} left'**
  String pendingResult(int done, int failed);

  /// No description provided for @pendingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing pending'**
  String get pendingEmptyTitle;

  /// No description provided for @pendingEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Jot things down now and confirm them here later'**
  String get pendingEmptyMessage;

  /// No description provided for @pendingAdd.
  ///
  /// In en, this message translates to:
  /// **'Add drafts'**
  String get pendingAdd;

  /// No description provided for @pendingSubmitSelected.
  ///
  /// In en, this message translates to:
  /// **'Confirm selected ({count})'**
  String pendingSubmitSelected(int count);

  /// No description provided for @pendingSubmittedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 transaction saved} other{{count} transactions saved}}'**
  String pendingSubmittedCount(int count);

  /// No description provided for @pendingSeeTransactions.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get pendingSeeTransactions;

  /// No description provided for @pendingUntitled.
  ///
  /// In en, this message translates to:
  /// **'No description'**
  String get pendingUntitled;

  /// No description provided for @pendingSourceManual.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get pendingSourceManual;

  /// No description provided for @pendingSourceSplitPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid back'**
  String get pendingSourceSplitPaid;

  /// No description provided for @pendingSourceProject.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get pendingSourceProject;

  /// No description provided for @pendingSourceOcr.
  ///
  /// In en, this message translates to:
  /// **'Scan'**
  String get pendingSourceOcr;

  /// No description provided for @pendingSourceChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get pendingSourceChat;

  /// No description provided for @pendingSourceOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get pendingSourceOther;

  /// No description provided for @pendingSavedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 draft saved} other{{count} drafts saved}}'**
  String pendingSavedCount(int count);

  /// No description provided for @pendingBatchHint.
  ///
  /// In en, this message translates to:
  /// **'An amount is enough — fill in the rest on the Pending page'**
  String get pendingBatchHint;

  /// No description provided for @pendingAddRow.
  ///
  /// In en, this message translates to:
  /// **'Add a row'**
  String get pendingAddRow;

  /// No description provided for @pendingSaveAsDrafts.
  ///
  /// In en, this message translates to:
  /// **'Save {count} as drafts'**
  String pendingSaveAsDrafts(int count);

  /// No description provided for @pendingSubmitAllNow.
  ///
  /// In en, this message translates to:
  /// **'Confirm all {count} now'**
  String pendingSubmitAllNow(int count);

  /// No description provided for @pendingRemoveRow.
  ///
  /// In en, this message translates to:
  /// **'Remove this row'**
  String get pendingRemoveRow;

  /// No description provided for @pendingSavedAsDraft.
  ///
  /// In en, this message translates to:
  /// **'Saved as a draft | it\'s in Pending'**
  String get pendingSavedAsDraft;

  /// No description provided for @pendingSaveDraft.
  ///
  /// In en, this message translates to:
  /// **'Save draft'**
  String get pendingSaveDraft;

  /// No description provided for @pendingSubmitThis.
  ///
  /// In en, this message translates to:
  /// **'Confirm this one'**
  String get pendingSubmitThis;

  /// No description provided for @pendingEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit draft'**
  String get pendingEditTitle;

  /// No description provided for @pendingDiscardTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this draft?'**
  String get pendingDiscardTitle;

  /// No description provided for @pendingDiscardSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Discard 1 draft?} other{Discard {count} drafts?}}'**
  String pendingDiscardSelectedTitle(int count);

  /// No description provided for @pendingKeepAsDraft.
  ///
  /// In en, this message translates to:
  /// **'Keep as a draft'**
  String get pendingKeepAsDraft;

  /// No description provided for @pendingBlockTitle.
  ///
  /// In en, this message translates to:
  /// **'{count} pending'**
  String pendingBlockTitle(int count);

  /// No description provided for @pendingBlockMore.
  ///
  /// In en, this message translates to:
  /// **'+ {count} more'**
  String pendingBlockMore(int count);

  /// No description provided for @pendingNotCounted.
  ///
  /// In en, this message translates to:
  /// **'Not counted in the totals below yet'**
  String get pendingNotCounted;

  /// No description provided for @pendingErrMissingType.
  ///
  /// In en, this message translates to:
  /// **'Pick a type before confirming'**
  String get pendingErrMissingType;

  /// No description provided for @pendingErrMissingAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount before confirming'**
  String get pendingErrMissingAmount;

  /// No description provided for @pendingErrMissingDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date before confirming'**
  String get pendingErrMissingDate;

  /// No description provided for @pendingErrAccount.
  ///
  /// In en, this message translates to:
  /// **'This wallet can\'t be used any more — pick another or none'**
  String get pendingErrAccount;

  /// No description provided for @pendingErrCategory.
  ///
  /// In en, this message translates to:
  /// **'This category can\'t be used — pick another'**
  String get pendingErrCategory;

  /// No description provided for @pendingErrCurrency.
  ///
  /// In en, this message translates to:
  /// **'Can\'t transfer between currencies'**
  String get pendingErrCurrency;

  /// No description provided for @pendingErrTag.
  ///
  /// In en, this message translates to:
  /// **'A tag on it was deleted'**
  String get pendingErrTag;

  /// No description provided for @pendingErrContact.
  ///
  /// In en, this message translates to:
  /// **'A contact in the split was deleted'**
  String get pendingErrContact;

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

  /// No description provided for @transactionFormAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get transactionFormAmountLabel;

  /// No description provided for @transactionFormTagsLabel.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get transactionFormTagsLabel;

  /// No description provided for @transactionFormSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get transactionFormSave;

  /// No description provided for @transactionFormAccountNone.
  ///
  /// In en, this message translates to:
  /// **'Unspecified wallet'**
  String get transactionFormAccountNone;

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

  /// No description provided for @transactionsListFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get transactionsListFilterAll;

  /// No description provided for @transactionsListEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Record the first income or expense of the month.'**
  String get transactionsListEmptyMessage;

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

  /// No description provided for @savingGoalFormIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get savingGoalFormIconLabel;

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

  /// No description provided for @savingGoalDetailArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get savingGoalDetailArchive;

  /// No description provided for @savingGoalDetailOfTarget.
  ///
  /// In en, this message translates to:
  /// **'of {target}'**
  String savingGoalDetailOfTarget(String target);

  /// No description provided for @savingGoalDetailRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get savingGoalDetailRemaining;

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

  /// No description provided for @budgetFormCategoryRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get budgetFormCategoryRequired;

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

  /// No description provided for @budgetDetailArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get budgetDetailArchive;

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

  /// No description provided for @scheduledFormSave.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get scheduledFormSave;

  /// No description provided for @scheduledFormIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get scheduledFormIconLabel;

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

  /// No description provided for @scheduledGenerateNowTitle.
  ///
  /// In en, this message translates to:
  /// **'Generate now'**
  String get scheduledGenerateNowTitle;

  /// No description provided for @scheduledGenerateNowBody.
  ///
  /// In en, this message translates to:
  /// **'Record the next payment now and move the due date to the next period.'**
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

  /// No description provided for @projectMetaPlanned.
  ///
  /// In en, this message translates to:
  /// **'Budget {amount}'**
  String projectMetaPlanned(String amount);

  /// No description provided for @projectPlannedLine.
  ///
  /// In en, this message translates to:
  /// **'Planned {planned} | {remaining} left'**
  String projectPlannedLine(String planned, String remaining);

  /// No description provided for @projectPlannedOverLine.
  ///
  /// In en, this message translates to:
  /// **'🔴 Over budget by {over}'**
  String projectPlannedOverLine(String over);

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
  /// **'In reports'**
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

  /// No description provided for @transactionSplitWithTitle.
  ///
  /// In en, this message translates to:
  /// **'Split with…'**
  String get transactionSplitWithTitle;

  /// No description provided for @transactionSplitShareTitle.
  ///
  /// In en, this message translates to:
  /// **'Share with… (I pay them their part)'**
  String get transactionSplitShareTitle;

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

  /// No description provided for @budgetsOverviewSpent.
  ///
  /// In en, this message translates to:
  /// **'Spent {spent} of {total}'**
  String budgetsOverviewSpent(String spent, String total);

  /// No description provided for @budgetsOverviewOverCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 budget over} other{{count} budgets over}}'**
  String budgetsOverviewOverCount(int count);

  /// No description provided for @transactionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search description | note | category | wallet'**
  String get transactionsSearchHint;

  /// No description provided for @savingGoalAllocationAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get savingGoalAllocationAuto;

  /// No description provided for @accountSharingSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Sharing & reports'**
  String get accountSharingSectionTitle;

  /// No description provided for @accountFormOpeningDebtLabel.
  ///
  /// In en, this message translates to:
  /// **'Opening outstanding balance'**
  String get accountFormOpeningDebtLabel;

  /// No description provided for @accountFormOpeningDebtHelper.
  ///
  /// In en, this message translates to:
  /// **'What you still owe on it on the day you start tracking (0 if nothing)'**
  String get accountFormOpeningDebtHelper;

  /// No description provided for @accountAdjustBalanceNewDebtLabel.
  ///
  /// In en, this message translates to:
  /// **'New outstanding balance'**
  String get accountAdjustBalanceNewDebtLabel;

  /// No description provided for @accountAdjustBalanceDiffLabel.
  ///
  /// In en, this message translates to:
  /// **'Difference'**
  String get accountAdjustBalanceDiffLabel;

  /// No description provided for @accountAdjustBalanceWillCreate.
  ///
  /// In en, this message translates to:
  /// **'This adds an \"Adjust balance\" transaction of {amount}, dated today.'**
  String accountAdjustBalanceWillCreate(String amount);

  /// No description provided for @scheduledSheetTitleNew.
  ///
  /// In en, this message translates to:
  /// **'New scheduled entry'**
  String get scheduledSheetTitleNew;

  /// No description provided for @scheduledSheetTitleEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit scheduled entry'**
  String get scheduledSheetTitleEdit;

  /// No description provided for @accountIdentifiersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reference numbers'**
  String get accountIdentifiersTitle;

  /// No description provided for @accountIdentifiersHelper.
  ///
  /// In en, this message translates to:
  /// **'Matches bank slips to this wallet'**
  String get accountIdentifiersHelper;

  /// No description provided for @accountIdentifiersEmpty.
  ///
  /// In en, this message translates to:
  /// **'No numbers yet'**
  String get accountIdentifiersEmpty;

  /// No description provided for @accountIdentifiersAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a number'**
  String get accountIdentifiersAdd;

  /// No description provided for @identifierKindBankAccount.
  ///
  /// In en, this message translates to:
  /// **'Bank account'**
  String get identifierKindBankAccount;

  /// No description provided for @identifierKindPromptPay.
  ///
  /// In en, this message translates to:
  /// **'PromptPay'**
  String get identifierKindPromptPay;

  /// No description provided for @identifierKindCard.
  ///
  /// In en, this message translates to:
  /// **'Card'**
  String get identifierKindCard;

  /// No description provided for @identifierKindOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get identifierKindOther;

  /// No description provided for @identifierSheetAddTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a number'**
  String get identifierSheetAddTitle;

  /// No description provided for @identifierSheetEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit number'**
  String get identifierSheetEditTitle;

  /// No description provided for @identifierKindLabel.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get identifierKindLabel;

  /// No description provided for @identifierBankLabel.
  ///
  /// In en, this message translates to:
  /// **'Bank'**
  String get identifierBankLabel;

  /// No description provided for @identifierBankNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get identifierBankNone;

  /// No description provided for @identifierValueLabel.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get identifierValueLabel;

  /// No description provided for @identifierValueHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 123-4-56789-0 or xxx-x-x2780-x'**
  String get identifierValueHint;

  /// No description provided for @identifierValueHelperPromptPay.
  ///
  /// In en, this message translates to:
  /// **'Phone or national ID number'**
  String get identifierValueHelperPromptPay;

  /// No description provided for @identifierValueInvalid.
  ///
  /// In en, this message translates to:
  /// **'Digits, x and dashes only'**
  String get identifierValueInvalid;

  /// No description provided for @identifierValueTooShort.
  ///
  /// In en, this message translates to:
  /// **'Needs at least 4 digits'**
  String get identifierValueTooShort;

  /// No description provided for @identifierValueTooLong.
  ///
  /// In en, this message translates to:
  /// **'Too long'**
  String get identifierValueTooLong;

  /// No description provided for @identifierDelete.
  ///
  /// In en, this message translates to:
  /// **'Remove this number'**
  String get identifierDelete;

  /// No description provided for @walletErrorInvalidIdentifier.
  ///
  /// In en, this message translates to:
  /// **'That account number isn’t valid'**
  String get walletErrorInvalidIdentifier;

  /// No description provided for @categoryFeeSwitchLabel.
  ///
  /// In en, this message translates to:
  /// **'Use for fees'**
  String get categoryFeeSwitchLabel;

  /// No description provided for @categoryFeeSwitchHelper.
  ///
  /// In en, this message translates to:
  /// **'Fees from bank slips go here | one category at a time'**
  String get categoryFeeSwitchHelper;

  /// No description provided for @categoryFeeSwitchFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn’t set the fee category'**
  String get categoryFeeSwitchFailed;

  /// No description provided for @monthPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a month'**
  String get monthPickerTitle;

  /// No description provided for @monthPickerThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get monthPickerThisMonth;

  /// No description provided for @monthPickerPrevYear.
  ///
  /// In en, this message translates to:
  /// **'Previous year'**
  String get monthPickerPrevYear;

  /// No description provided for @monthPickerNextYear.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get monthPickerNextYear;

  /// No description provided for @monthPickerPrevMonth.
  ///
  /// In en, this message translates to:
  /// **'Previous month'**
  String get monthPickerPrevMonth;

  /// No description provided for @monthPickerNextMonth.
  ///
  /// In en, this message translates to:
  /// **'Next month'**
  String get monthPickerNextMonth;

  /// No description provided for @appUpdateRequiredTitle.
  ///
  /// In en, this message translates to:
  /// **'Update required'**
  String get appUpdateRequiredTitle;

  /// No description provided for @appUpdateRequiredBody.
  ///
  /// In en, this message translates to:
  /// **'This version of the app is too old. Download the new version to keep using it.'**
  String get appUpdateRequiredBody;

  /// No description provided for @appUpdateDownload.
  ///
  /// In en, this message translates to:
  /// **'Download the new version'**
  String get appUpdateDownload;

  /// No description provided for @appUpdateNoLink.
  ///
  /// In en, this message translates to:
  /// **'No download link yet — contact the admin'**
  String get appUpdateNoLink;

  /// No description provided for @appUpdateOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open the download link'**
  String get appUpdateOpenFailed;

  /// No description provided for @appUpdateBuildLine.
  ///
  /// In en, this message translates to:
  /// **'This is build {current} | {required} or newer is needed'**
  String appUpdateBuildLine(int current, int required);

  /// No description provided for @appUpdateAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version is available'**
  String get appUpdateAvailable;

  /// No description provided for @appUpdateAvailableAction.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get appUpdateAvailableAction;

  /// No description provided for @appUpdateLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get appUpdateLater;

  /// No description provided for @transactionsEmptyMonthTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions this month yet'**
  String get transactionsEmptyMonthTitle;

  /// No description provided for @transactionsNoMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Try other filters, or clear them to see everything.'**
  String get transactionsNoMatchMessage;

  /// No description provided for @notifCopyUpdated.
  ///
  /// In en, this message translates to:
  /// **'Your copy is updated'**
  String get notifCopyUpdated;

  /// No description provided for @homeTodoTitle.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get homeTodoTitle;

  /// No description provided for @homeTodoPending.
  ///
  /// In en, this message translates to:
  /// **'To confirm'**
  String get homeTodoPending;

  /// No description provided for @homeTodoComingUp.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get homeTodoComingUp;

  /// No description provided for @transactionsFiltersTitle.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get transactionsFiltersTitle;

  /// No description provided for @transactionsFiltersApply.
  ///
  /// In en, this message translates to:
  /// **'Apply filters'**
  String get transactionsFiltersApply;

  /// No description provided for @transactionsSortBy.
  ///
  /// In en, this message translates to:
  /// **'Sort by'**
  String get transactionsSortBy;

  /// No description provided for @txPeriodMonth.
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get txPeriodMonth;

  /// No description provided for @txPeriodWeek.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get txPeriodWeek;

  /// No description provided for @txPeriodYear.
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get txPeriodYear;

  /// No description provided for @txPeriodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get txPeriodCustom;

  /// No description provided for @txPeriodPrev.
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get txPeriodPrev;

  /// No description provided for @txPeriodNext.
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get txPeriodNext;

  /// No description provided for @transactionsEmptyPeriodTitle.
  ///
  /// In en, this message translates to:
  /// **'No transactions in this period'**
  String get transactionsEmptyPeriodTitle;

  /// No description provided for @transactionsFilterRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove this filter'**
  String get transactionsFilterRemove;

  /// No description provided for @commonMore.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get commonMore;

  /// No description provided for @txShareMine.
  ///
  /// In en, this message translates to:
  /// **'Your share'**
  String get txShareMine;

  /// No description provided for @txShareOthersOwe.
  ///
  /// In en, this message translates to:
  /// **'to receive from others {amount}'**
  String txShareOthersOwe(String amount);

  /// No description provided for @txShareOthers.
  ///
  /// In en, this message translates to:
  /// **'others\' share {amount}'**
  String txShareOthers(String amount);

  /// No description provided for @txSplitAuthorOnly.
  ///
  /// In en, this message translates to:
  /// **'Only whoever recorded this transaction can change its splits'**
  String get txSplitAuthorOnly;

  /// No description provided for @quickCreateErrorNotBillable.
  ///
  /// In en, this message translates to:
  /// **'Opening-balance and adjustment rows can\'t go into an event'**
  String get quickCreateErrorNotBillable;

  /// No description provided for @txEventRemove.
  ///
  /// In en, this message translates to:
  /// **'Take out of the event'**
  String get txEventRemove;

  /// No description provided for @txEventSplitRepaid.
  ///
  /// In en, this message translates to:
  /// **'Someone already paid their share back — this can\'t go into an event'**
  String get txEventSplitRepaid;

  /// No description provided for @txEventFailedAfterSave.
  ///
  /// In en, this message translates to:
  /// **'Saved — but the event didn\'t change: {reason}'**
  String txEventFailedAfterSave(String reason);

  /// No description provided for @txEventSplitCancelled.
  ///
  /// In en, this message translates to:
  /// **'A split on this was forgiven — it can\'t go into an event'**
  String get txEventSplitCancelled;

  /// No description provided for @txSplitExceedsShare.
  ///
  /// In en, this message translates to:
  /// **'More than your share'**
  String get txSplitExceedsShare;

  /// No description provided for @accountsGroupMine.
  ///
  /// In en, this message translates to:
  /// **'Mine'**
  String get accountsGroupMine;

  /// No description provided for @accountsReorder.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get accountsReorder;

  /// No description provided for @accountsReorderSave.
  ///
  /// In en, this message translates to:
  /// **'Save order'**
  String get accountsReorderSave;

  /// No description provided for @accountsReorderDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get accountsReorderDiscard;

  /// No description provided for @accountsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No wallets yet'**
  String get accountsEmptyTitle;

  /// No description provided for @accountsEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Add your first one — cash, a bank account or a card'**
  String get accountsEmptyMessage;

  /// No description provided for @accountsArchivedEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Archived wallets wait here — restore one any time'**
  String get accountsArchivedEmptyMessage;

  /// No description provided for @accountDetailAddTx.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get accountDetailAddTx;

  /// No description provided for @accountDetailTransfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get accountDetailTransfer;

  /// No description provided for @accountDayNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get accountDayNone;

  /// No description provided for @txPeriodDay.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get txPeriodDay;

  /// No description provided for @txPeriodWeekHint.
  ///
  /// In en, this message translates to:
  /// **'Tap any day — its whole week (Monday to Sunday)'**
  String get txPeriodWeekHint;

  /// No description provided for @quickEventOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'Open events'**
  String get quickEventOpenTitle;

  /// No description provided for @quickEventNewRow.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get quickEventNewRow;

  /// No description provided for @quickEventCreateNamed.
  ///
  /// In en, this message translates to:
  /// **'Create \"{name}\"'**
  String quickEventCreateNamed(String name);

  /// No description provided for @quickEventMembersInfo.
  ///
  /// In en, this message translates to:
  /// **'The people you split with join the event as members'**
  String get quickEventMembersInfo;

  /// No description provided for @eventPickerTabOpen.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get eventPickerTabOpen;

  /// No description provided for @eventPickerTabClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get eventPickerTabClosed;

  /// No description provided for @txSplitInEvent.
  ///
  /// In en, this message translates to:
  /// **'Split in the event'**
  String get txSplitInEvent;

  /// No description provided for @txSplitInEventHelper.
  ///
  /// In en, this message translates to:
  /// **'This split will live in the event — change it on the event page'**
  String get txSplitInEventHelper;

  /// No description provided for @txSplitFromMyShare.
  ///
  /// In en, this message translates to:
  /// **'Split from your share'**
  String get txSplitFromMyShare;

  /// No description provided for @categoryPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get categoryPickerTitle;

  /// No description provided for @categoryPickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search categories'**
  String get categoryPickerSearchHint;

  /// No description provided for @categoryPickerNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No category matches'**
  String get categoryPickerNoMatch;

  /// No description provided for @tagPickerSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search or name a new tag'**
  String get tagPickerSearchHint;

  /// No description provided for @tagPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No tags yet — make them on the tags page'**
  String get tagPickerEmpty;

  /// No description provided for @tagPickerNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No tag matches'**
  String get tagPickerNoMatch;

  /// No description provided for @contactsSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Recently used'**
  String get contactsSortRecent;

  /// No description provided for @contactsSortNameAsc.
  ///
  /// In en, this message translates to:
  /// **'Name A→Z'**
  String get contactsSortNameAsc;

  /// No description provided for @contactsSortNameDesc.
  ///
  /// In en, this message translates to:
  /// **'Name Z→A'**
  String get contactsSortNameDesc;

  /// No description provided for @contactArchiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this contact?'**
  String get contactArchiveConfirmTitle;

  /// No description provided for @tagsBulkDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The selected tags are deleted when you save, and removed from any transactions using them.'**
  String get tagsBulkDeleteConfirmBody;

  /// No description provided for @contactLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked'**
  String get contactLinked;

  /// No description provided for @contactsLinkLabel.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get contactsLinkLabel;

  /// No description provided for @contactsLinkUnlinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get contactsLinkUnlinked;

  /// No description provided for @contactsNoFilterMatch.
  ///
  /// In en, this message translates to:
  /// **'No contacts match this filter'**
  String get contactsNoFilterMatch;

  /// No description provided for @contactsNoFilterMatchMessage.
  ///
  /// In en, this message translates to:
  /// **'Try changing the filter'**
  String get contactsNoFilterMatchMessage;

  /// No description provided for @contactsNoMatchFilterMessage.
  ///
  /// In en, this message translates to:
  /// **'Try another search or change the filters'**
  String get contactsNoMatchFilterMessage;

  /// No description provided for @walletInviteFromContacts.
  ///
  /// In en, this message translates to:
  /// **'Invite from contacts'**
  String get walletInviteFromContacts;

  /// No description provided for @walletInvitePickTitle.
  ///
  /// In en, this message translates to:
  /// **'Invite to this wallet'**
  String get walletInvitePickTitle;

  /// No description provided for @walletInvitePickHint.
  ///
  /// In en, this message translates to:
  /// **'Only contacts linked to an app account can be invited.'**
  String get walletInvitePickHint;

  /// No description provided for @walletInvitePickEmpty.
  ///
  /// In en, this message translates to:
  /// **'No linked contacts left to invite. Link a contact to their app account first (Contacts).'**
  String get walletInvitePickEmpty;

  /// No description provided for @walletErrorContactNotFound.
  ///
  /// In en, this message translates to:
  /// **'That contact no longer exists.'**
  String get walletErrorContactNotFound;

  /// No description provided for @walletErrorContactArchived.
  ///
  /// In en, this message translates to:
  /// **'That contact is archived. Restore it to invite them.'**
  String get walletErrorContactArchived;

  /// No description provided for @walletErrorContactNotLinked.
  ///
  /// In en, this message translates to:
  /// **'That contact isn\'t linked to an app account yet.'**
  String get walletErrorContactNotLinked;

  /// No description provided for @walletErrorInviteInvalid.
  ///
  /// In en, this message translates to:
  /// **'The invite couldn\'t be sent. Please try again.'**
  String get walletErrorInviteInvalid;

  /// No description provided for @reorderMoveUp.
  ///
  /// In en, this message translates to:
  /// **'Move up'**
  String get reorderMoveUp;

  /// No description provided for @reorderMoveDown.
  ///
  /// In en, this message translates to:
  /// **'Move down'**
  String get reorderMoveDown;

  /// No description provided for @reorderOutdent.
  ///
  /// In en, this message translates to:
  /// **'Move out a level'**
  String get reorderOutdent;

  /// No description provided for @reorderIndent.
  ///
  /// In en, this message translates to:
  /// **'Move in a level'**
  String get reorderIndent;

  /// No description provided for @categoriesReorderUnder.
  ///
  /// In en, this message translates to:
  /// **'Under {name}'**
  String categoriesReorderUnder(String name);

  /// No description provided for @categoriesReorderTopLevel.
  ///
  /// In en, this message translates to:
  /// **'Top level'**
  String get categoriesReorderTopLevel;

  /// No description provided for @categoriesReorderTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a row and use the arrows, or drag ⠿'**
  String get categoriesReorderTapHint;

  /// No description provided for @categoryErrorMaxDepth.
  ///
  /// In en, this message translates to:
  /// **'Categories nest up to 3 levels (counting this one\'s sub-categories)'**
  String get categoryErrorMaxDepth;

  /// No description provided for @accountsReorderTapHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to select and use the arrows, or drag ⠿. This order is yours alone; shared-wallet members aren\'t affected.'**
  String get accountsReorderTapHint;

  /// No description provided for @categorySectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get categorySectionSettings;

  /// No description provided for @dayPickerLastDay.
  ///
  /// In en, this message translates to:
  /// **'Last day of the month'**
  String get dayPickerLastDay;

  /// No description provided for @dayPickerNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get dayPickerNone;

  /// No description provided for @dayPickerEveryMonth.
  ///
  /// In en, this message translates to:
  /// **'{day} of every month'**
  String dayPickerEveryMonth(int day);

  /// No description provided for @txSplitMe.
  ///
  /// In en, this message translates to:
  /// **'My share'**
  String get txSplitMe;

  /// No description provided for @txSplitLeft.
  ///
  /// In en, this message translates to:
  /// **'Not split yet {amount}'**
  String txSplitLeft(String amount);

  /// No description provided for @txSplitBalanced.
  ///
  /// In en, this message translates to:
  /// **'All split'**
  String get txSplitBalanced;

  /// No description provided for @txSplitOverBy.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String txSplitOverBy(String amount);

  /// No description provided for @txSplitUnbalanced.
  ///
  /// In en, this message translates to:
  /// **'The split doesn\'t add up yet — make your share and theirs total the amount before saving.'**
  String get txSplitUnbalanced;

  /// No description provided for @txShareOthersOweYou.
  ///
  /// In en, this message translates to:
  /// **'others owe you {amount}'**
  String txShareOthersOweYou(String amount);

  /// No description provided for @txShareYouOweOthers.
  ///
  /// In en, this message translates to:
  /// **'you owe others {amount}'**
  String txShareYouOweOthers(String amount);

  /// No description provided for @txSplitNoContact.
  ///
  /// In en, this message translates to:
  /// **'Unspecified contact'**
  String get txSplitNoContact;

  /// No description provided for @txSplitNoContactHint.
  ///
  /// In en, this message translates to:
  /// **'Keep the name, still editable'**
  String get txSplitNoContactHint;

  /// No description provided for @accountFormNameExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. Salary account'**
  String get accountFormNameExample;

  /// No description provided for @accountFormDescriptionExample.
  ///
  /// In en, this message translates to:
  /// **'e.g. For household spending'**
  String get accountFormDescriptionExample;

  /// No description provided for @accountsSortCustom.
  ///
  /// In en, this message translates to:
  /// **'My order'**
  String get accountsSortCustom;

  /// No description provided for @accountsSortBalance.
  ///
  /// In en, this message translates to:
  /// **'Balance, high to low'**
  String get accountsSortBalance;

  /// No description provided for @accountsSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get accountsSortName;

  /// No description provided for @accountsSortType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get accountsSortType;

  /// No description provided for @accountsSummaryCardDebt.
  ///
  /// In en, this message translates to:
  /// **'Card debt'**
  String get accountsSummaryCardDebt;

  /// No description provided for @accountReportSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Reports'**
  String get accountReportSectionTitle;

  /// No description provided for @accountOpeningSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Opening balance'**
  String get accountOpeningSectionTitle;

  /// No description provided for @accountCreditSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Card / credit limit'**
  String get accountCreditSectionTitle;

  /// No description provided for @accountMinPaymentOverLimit.
  ///
  /// In en, this message translates to:
  /// **'The minimum payment is more than the credit limit. Check it.'**
  String get accountMinPaymentOverLimit;

  /// No description provided for @identifierHintBankAccount.
  ///
  /// In en, this message translates to:
  /// **'e.g. 123-4-56789-0'**
  String get identifierHintBankAccount;

  /// No description provided for @identifierHintPromptPay.
  ///
  /// In en, this message translates to:
  /// **'10-digit phone or 13-digit ID'**
  String get identifierHintPromptPay;

  /// No description provided for @identifierHintCard.
  ///
  /// In en, this message translates to:
  /// **'Last 4 digits of the card'**
  String get identifierHintCard;

  /// No description provided for @identifierPromptPayLength.
  ///
  /// In en, this message translates to:
  /// **'PromptPay is a 10-digit phone or a 13-digit ID number'**
  String get identifierPromptPayLength;

  /// No description provided for @identifierCardLength.
  ///
  /// In en, this message translates to:
  /// **'Enter the card\'s last 4 digits'**
  String get identifierCardLength;

  /// No description provided for @txSplitAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get txSplitAuto;

  /// No description provided for @contactPickerCreateNew.
  ///
  /// In en, this message translates to:
  /// **'New contact'**
  String get contactPickerCreateNew;

  /// No description provided for @contactPickerEmptyPlain.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet'**
  String get contactPickerEmptyPlain;

  /// No description provided for @contactPickerFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get contactPickerFilterAll;

  /// No description provided for @contactPickerFilterContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get contactPickerFilterContacts;

  /// No description provided for @contactPickerFilterNotInContacts.
  ///
  /// In en, this message translates to:
  /// **'Not in contacts'**
  String get contactPickerFilterNotInContacts;

  /// No description provided for @contactPickerFilterOwing.
  ///
  /// In en, this message translates to:
  /// **'Owing'**
  String get contactPickerFilterOwing;

  /// No description provided for @contactPickerFilterNoDebt.
  ///
  /// In en, this message translates to:
  /// **'No debt'**
  String get contactPickerFilterNoDebt;

  /// No description provided for @contactPickerNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No one matches'**
  String get contactPickerNoMatch;

  /// No description provided for @contactPickerTypeName.
  ///
  /// In en, this message translates to:
  /// **'New name'**
  String get contactPickerTypeName;

  /// No description provided for @contactPickerUseName.
  ///
  /// In en, this message translates to:
  /// **'Use the name \"{name}\"'**
  String contactPickerUseName(Object name);

  /// No description provided for @txSplitNameHint.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get txSplitNameHint;

  /// No description provided for @accountIdentifiersHint.
  ///
  /// In en, this message translates to:
  /// **'Only used to match accounts when scanning slips'**
  String get accountIdentifiersHint;

  /// No description provided for @detailManageTitle.
  ///
  /// In en, this message translates to:
  /// **'Manage'**
  String get detailManageTitle;

  /// No description provided for @draftPickWalletFrom.
  ///
  /// In en, this message translates to:
  /// **'Pick the source wallet'**
  String get draftPickWalletFrom;

  /// No description provided for @draftPickWalletTo.
  ///
  /// In en, this message translates to:
  /// **'Pick the destination wallet'**
  String get draftPickWalletTo;

  /// No description provided for @draftPickCategory.
  ///
  /// In en, this message translates to:
  /// **'Pick a category'**
  String get draftPickCategory;

  /// No description provided for @draftExtrasTitle.
  ///
  /// In en, this message translates to:
  /// **'Split with / Event'**
  String get draftExtrasTitle;

  /// No description provided for @draftExtrasSplits.
  ///
  /// In en, this message translates to:
  /// **'Split with {count}'**
  String draftExtrasSplits(int count);

  /// No description provided for @draftExtrasNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get draftExtrasNone;

  /// No description provided for @pendingErrInvalidSplit.
  ///
  /// In en, this message translates to:
  /// **'A split row is incomplete — it needs a name and an amount above 0'**
  String get pendingErrInvalidSplit;

  /// No description provided for @pendingErrSplitsExceed.
  ///
  /// In en, this message translates to:
  /// **'The split adds up to more than the amount'**
  String get pendingErrSplitsExceed;

  /// No description provided for @pendingErrProjectGone.
  ///
  /// In en, this message translates to:
  /// **'That event no longer exists — pick another or remove it'**
  String get pendingErrProjectGone;

  /// No description provided for @pendingErrProjectClosed.
  ///
  /// In en, this message translates to:
  /// **'That event is closed or locked — nothing can be added'**
  String get pendingErrProjectClosed;

  /// No description provided for @pendingErrProjectMember.
  ///
  /// In en, this message translates to:
  /// **'You\'re not a member of that event'**
  String get pendingErrProjectMember;

  /// No description provided for @pendingErrProjectReadOnly.
  ///
  /// In en, this message translates to:
  /// **'You can only view that event — nothing can be added'**
  String get pendingErrProjectReadOnly;

  /// No description provided for @accountReportSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Choose how much of this wallet counts in your reports'**
  String get accountReportSectionDescription;

  /// No description provided for @accountMembersSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'People who share this wallet with you'**
  String get accountMembersSectionDescription;

  /// No description provided for @accountCreditSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Statement day, due day and minimum payment for this card'**
  String get accountCreditSectionDescription;

  /// No description provided for @accountOpeningSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'The wallet\'s starting balance; after creating, change it with Adjust balance'**
  String get accountOpeningSectionDescription;

  /// No description provided for @accountTypeSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'What kind of wallet this is'**
  String get accountTypeSectionDescription;

  /// No description provided for @walletMembersHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'People who were in this wallet and have left'**
  String get walletMembersHistoryDescription;

  /// No description provided for @categorySettingsSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Whether this category counts in reports and is used for fees'**
  String get categorySettingsSectionDescription;

  /// No description provided for @contactActionsSectionDescription.
  ///
  /// In en, this message translates to:
  /// **'Link to a user account, match split names and see this person\'s debts'**
  String get contactActionsSectionDescription;

  /// No description provided for @budgetDetailBreakdownDescription.
  ///
  /// In en, this message translates to:
  /// **'Spending split by sub-category this period'**
  String get budgetDetailBreakdownDescription;

  /// No description provided for @scheduledDetailHistoryDescription.
  ///
  /// In en, this message translates to:
  /// **'Transactions already created from this schedule'**
  String get scheduledDetailHistoryDescription;

  /// No description provided for @projectMembersDescription.
  ///
  /// In en, this message translates to:
  /// **'People currently taking part in this event'**
  String get projectMembersDescription;

  /// No description provided for @projectMembersPendingDescription.
  ///
  /// In en, this message translates to:
  /// **'Invited and waiting to accept'**
  String get projectMembersPendingDescription;

  /// No description provided for @projectMembersLeftDescription.
  ///
  /// In en, this message translates to:
  /// **'People who have left this event'**
  String get projectMembersLeftDescription;

  /// No description provided for @contactFieldNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get contactFieldNotSet;

  /// No description provided for @txSplitSectionTitle.
  ///
  /// In en, this message translates to:
  /// **'Linked to'**
  String get txSplitSectionTitle;

  /// No description provided for @txSplitSectionHint.
  ///
  /// In en, this message translates to:
  /// **'Split the amount, put it in an event, or link a recurring'**
  String get txSplitSectionHint;

  /// No description provided for @txSplitRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get txSplitRowLabel;

  /// No description provided for @txSplitPeopleLabel.
  ///
  /// In en, this message translates to:
  /// **'Split with people'**
  String get txSplitPeopleLabel;

  /// No description provided for @quickEventAdd.
  ///
  /// In en, this message translates to:
  /// **'Add event'**
  String get quickEventAdd;

  /// No description provided for @dayPickerLastShort.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get dayPickerLastShort;

  /// No description provided for @profileCurrencyLabel.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get profileCurrencyLabel;

  /// No description provided for @contactNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get contactNicknameLabel;

  /// No description provided for @contactNicknameHint.
  ///
  /// In en, this message translates to:
  /// **'Optional | e.g. Mum'**
  String get contactNicknameHint;

  /// No description provided for @contactShowNicknameLabel.
  ///
  /// In en, this message translates to:
  /// **'Show nickname'**
  String get contactShowNicknameLabel;

  /// No description provided for @contactShowNicknameHelper.
  ///
  /// In en, this message translates to:
  /// **'On = use the nickname instead of the name everywhere'**
  String get contactShowNicknameHelper;

  /// No description provided for @notOwnerError.
  ///
  /// In en, this message translates to:
  /// **'Only the wallet owner can do this'**
  String get notOwnerError;

  /// No description provided for @profileTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// No description provided for @profileEmailCannotClear.
  ///
  /// In en, this message translates to:
  /// **'Once set, the email can\'t be removed'**
  String get profileEmailCannotClear;

  /// No description provided for @connectionOffline.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server | trying again…'**
  String get connectionOffline;

  /// No description provided for @connectionReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Reconnecting…'**
  String get connectionReconnecting;

  /// No description provided for @connectionBack.
  ///
  /// In en, this message translates to:
  /// **'Connected again'**
  String get connectionBack;

  /// No description provided for @connectionRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get connectionRetry;

  /// No description provided for @uiLoadMoreFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load more'**
  String get uiLoadMoreFailed;

  /// No description provided for @debtsTabEntries.
  ///
  /// In en, this message translates to:
  /// **'Entries'**
  String get debtsTabEntries;

  /// No description provided for @debtsTabMoney.
  ///
  /// In en, this message translates to:
  /// **'Payments'**
  String get debtsTabMoney;

  /// No description provided for @debtsAddEntry.
  ///
  /// In en, this message translates to:
  /// **'Add entry'**
  String get debtsAddEntry;

  /// No description provided for @debtsSortLabel.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get debtsSortLabel;

  /// No description provided for @debtsSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get debtsSortNewest;

  /// No description provided for @debtsSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get debtsSortOldest;

  /// No description provided for @debtsSortAmountDesc.
  ///
  /// In en, this message translates to:
  /// **'Largest amount'**
  String get debtsSortAmountDesc;

  /// No description provided for @debtsSortAmountAsc.
  ///
  /// In en, this message translates to:
  /// **'Smallest amount'**
  String get debtsSortAmountAsc;

  /// No description provided for @debtsDirLabel.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get debtsDirLabel;

  /// No description provided for @debtsDirPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get debtsDirPaid;

  /// No description provided for @debtsDirReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get debtsDirReceived;

  /// No description provided for @debtsPaidChip.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get debtsPaidChip;

  /// No description provided for @debtsTimelineEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries yet'**
  String get debtsTimelineEmpty;

  /// No description provided for @debtsMoneyEmpty.
  ///
  /// In en, this message translates to:
  /// **'No payments yet'**
  String get debtsMoneyEmpty;

  /// No description provided for @debtsEntriesNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching entries'**
  String get debtsEntriesNoMatch;

  /// No description provided for @debtsEntrySearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search entries'**
  String get debtsEntrySearchHint;

  /// No description provided for @debtEntryPaidTo.
  ///
  /// In en, this message translates to:
  /// **'Paid {name}'**
  String debtEntryPaidTo(String name);

  /// No description provided for @debtEntryReceivedFrom.
  ///
  /// In en, this message translates to:
  /// **'Received from {name}'**
  String debtEntryReceivedFrom(String name);

  /// No description provided for @eventStartDateLabel.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get eventStartDateLabel;

  /// No description provided for @eventEndDateLabel.
  ///
  /// In en, this message translates to:
  /// **'End date'**
  String get eventEndDateLabel;

  /// No description provided for @eventDatesInvalid.
  ///
  /// In en, this message translates to:
  /// **'The end date can\'t be before the start date'**
  String get eventDatesInvalid;

  /// No description provided for @eventDateNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get eventDateNone;

  /// No description provided for @eventTagShowBills.
  ///
  /// In en, this message translates to:
  /// **'Show bills with this tag'**
  String get eventTagShowBills;

  /// No description provided for @eventTagAddToMine.
  ///
  /// In en, this message translates to:
  /// **'Add to my tags'**
  String get eventTagAddToMine;

  /// No description provided for @eventTagsImportAll.
  ///
  /// In en, this message translates to:
  /// **'Import all'**
  String get eventTagsImportAll;

  /// No description provided for @eventTagFilter.
  ///
  /// In en, this message translates to:
  /// **'Tag: {name}'**
  String eventTagFilter(String name);

  /// No description provided for @quickModeTx.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get quickModeTx;

  /// No description provided for @quickModeDebt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get quickModeDebt;

  /// No description provided for @debtNoWallet.
  ///
  /// In en, this message translates to:
  /// **'Unspecified wallet'**
  String get debtNoWallet;

  /// No description provided for @debtPickPerson.
  ///
  /// In en, this message translates to:
  /// **'Pick a person'**
  String get debtPickPerson;

  /// No description provided for @debtPersonPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'With whom?'**
  String get debtPersonPickerTitle;

  /// No description provided for @debtSettledLabel.
  ///
  /// In en, this message translates to:
  /// **'Settled up'**
  String get debtSettledLabel;

  /// No description provided for @debtResultAfter.
  ///
  /// In en, this message translates to:
  /// **'After saving: {result}'**
  String debtResultAfter(Object result);

  /// No description provided for @debtMarkPaidTitle.
  ///
  /// In en, this message translates to:
  /// **'Mark entries as paid'**
  String get debtMarkPaidTitle;

  /// No description provided for @debtMarkPaidNone.
  ///
  /// In en, this message translates to:
  /// **'Nothing open'**
  String get debtMarkPaidNone;

  /// No description provided for @debtCloseLabel.
  ///
  /// In en, this message translates to:
  /// **'Close debts'**
  String get debtCloseLabel;

  /// No description provided for @debtClosePick.
  ///
  /// In en, this message translates to:
  /// **'Pick debts'**
  String get debtClosePick;

  /// No description provided for @debtCloseChosen.
  ///
  /// In en, this message translates to:
  /// **'{n} debts picked'**
  String debtCloseChosen(int n);

  /// No description provided for @debtCloseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Pick {n} debts'**
  String debtCloseConfirm(int n);

  /// No description provided for @debtCreateTxLabel.
  ///
  /// In en, this message translates to:
  /// **'Also create a transaction'**
  String get debtCreateTxLabel;

  /// No description provided for @debtCreateTxHint.
  ///
  /// In en, this message translates to:
  /// **'Off = only noted in the debt book, not counted in income or expenses'**
  String get debtCreateTxHint;

  /// No description provided for @txFilterNoWallet.
  ///
  /// In en, this message translates to:
  /// **'Unspecified wallet'**
  String get txFilterNoWallet;

  /// No description provided for @txFilterNoCategory.
  ///
  /// In en, this message translates to:
  /// **'Unspecified category'**
  String get txFilterNoCategory;

  /// No description provided for @txFilterNoTag.
  ///
  /// In en, this message translates to:
  /// **'Unspecified tag'**
  String get txFilterNoTag;

  /// No description provided for @txSummaryNet.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get txSummaryNet;

  /// No description provided for @txFilterAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get txFilterAmount;

  /// No description provided for @txFilterAmountMin.
  ///
  /// In en, this message translates to:
  /// **'Min'**
  String get txFilterAmountMin;

  /// No description provided for @txFilterAmountMax.
  ///
  /// In en, this message translates to:
  /// **'Max'**
  String get txFilterAmountMax;

  /// No description provided for @txTitleHintExpense.
  ///
  /// In en, this message translates to:
  /// **'What did you pay for?'**
  String get txTitleHintExpense;

  /// No description provided for @txTitleHintIncome.
  ///
  /// In en, this message translates to:
  /// **'What is the money for?'**
  String get txTitleHintIncome;

  /// No description provided for @debtTitleHintPaid.
  ///
  /// In en, this message translates to:
  /// **'What did you pay for them?'**
  String get debtTitleHintPaid;

  /// No description provided for @debtTitleHintReceived.
  ///
  /// In en, this message translates to:
  /// **'What are they paying back?'**
  String get debtTitleHintReceived;

  /// No description provided for @savingTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Saving for what?'**
  String get savingTitleHint;

  /// No description provided for @savingEntryGoalLabel.
  ///
  /// In en, this message translates to:
  /// **'Saving goal'**
  String get savingEntryGoalLabel;

  /// No description provided for @debtEntrySaved.
  ///
  /// In en, this message translates to:
  /// **'Debt saved'**
  String get debtEntrySaved;

  /// No description provided for @eventSourceTx.
  ///
  /// In en, this message translates to:
  /// **'Source transaction'**
  String get eventSourceTx;

  /// No description provided for @eventLinkedHint.
  ///
  /// In en, this message translates to:
  /// **'Amount, date and payer are linked to the source transaction: edits change both'**
  String get eventLinkedHint;

  /// No description provided for @eventTagsImported.
  ///
  /// In en, this message translates to:
  /// **'Added {count} tags to my tags'**
  String eventTagsImported(int count);

  /// No description provided for @debtEntryTitle.
  ///
  /// In en, this message translates to:
  /// **'Debt entry'**
  String get debtEntryTitle;

  /// No description provided for @debtEntryNotFound.
  ///
  /// In en, this message translates to:
  /// **'This debt entry doesn\'t exist'**
  String get debtEntryNotFound;

  /// No description provided for @debtEntryDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry'**
  String get debtEntryDelete;

  /// No description provided for @debtEntryDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this debt entry?'**
  String get debtEntryDeleteTitle;

  /// No description provided for @debtDeleteBothMessage.
  ///
  /// In en, this message translates to:
  /// **'Its transaction in “{wallet}” goes too — the money returns to the wallet.'**
  String debtDeleteBothMessage(Object wallet);

  /// No description provided for @debtDeleteLedgerMessage.
  ///
  /// In en, this message translates to:
  /// **'The balance with {name} changes accordingly.'**
  String debtDeleteLedgerMessage(Object name);

  /// No description provided for @debtSourceHint.
  ///
  /// In en, this message translates to:
  /// **'From {source}: only the description, note and paid label can change.'**
  String debtSourceHint(Object source);

  /// No description provided for @debtSourceRowLabel.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get debtSourceRowLabel;

  /// No description provided for @debtBalanceNow.
  ///
  /// In en, this message translates to:
  /// **'Now: {result}'**
  String debtBalanceNow(Object result);

  /// No description provided for @txInEventRow.
  ///
  /// In en, this message translates to:
  /// **'In the event {name}'**
  String txInEventRow(Object name);

  /// No description provided for @txLinkedMoneyHint.
  ///
  /// In en, this message translates to:
  /// **'Amount and date are shared with the event bill: an edit changes both.'**
  String get txLinkedMoneyHint;

  /// No description provided for @eventBillLinkedMoneyHint.
  ///
  /// In en, this message translates to:
  /// **'Amount and date are shared with the source transaction: an edit changes both.'**
  String get eventBillLinkedMoneyHint;

  /// No description provided for @eventErrLocked.
  ///
  /// In en, this message translates to:
  /// **'This event is locked: it can\'t be edited'**
  String get eventErrLocked;

  /// No description provided for @eventErrNotOwner.
  ///
  /// In en, this message translates to:
  /// **'Only the event owner can do this'**
  String get eventErrNotOwner;

  /// No description provided for @eventErrMoneyLinked.
  ///
  /// In en, this message translates to:
  /// **'Amount and date are linked to a member\'s transaction: its owner edits them'**
  String get eventErrMoneyLinked;

  /// No description provided for @eventErrTagTaken.
  ///
  /// In en, this message translates to:
  /// **'This event already has a tag with that name'**
  String get eventErrTagTaken;

  /// No description provided for @eventErrTagNotFound.
  ///
  /// In en, this message translates to:
  /// **'That tag isn\'t in this event'**
  String get eventErrTagNotFound;

  /// No description provided for @eventErrNoShare.
  ///
  /// In en, this message translates to:
  /// **'You have no share in this bill'**
  String get eventErrNoShare;

  /// No description provided for @eventErrOwnerCannotLeave.
  ///
  /// In en, this message translates to:
  /// **'The owner must transfer ownership before leaving'**
  String get eventErrOwnerCannotLeave;

  /// No description provided for @eventDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Every bill in the event is deleted | your transactions linked to it can stay or be deleted too'**
  String get eventDeleteBody;

  /// No description provided for @eventDeleteKeepTxs.
  ///
  /// In en, this message translates to:
  /// **'Delete, keep my transactions'**
  String get eventDeleteKeepTxs;

  /// No description provided for @eventDeleteWithTxs.
  ///
  /// In en, this message translates to:
  /// **'Delete and remove {count} transactions'**
  String eventDeleteWithTxs(int count);

  /// No description provided for @eventDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get eventDeleteConfirm;

  /// No description provided for @eventDeleteNotYet.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get eventDeleteNotYet;

  /// No description provided for @occurrenceStateUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get occurrenceStateUpcoming;

  /// No description provided for @occurrenceStateNotCreated.
  ///
  /// In en, this message translates to:
  /// **'To confirm'**
  String get occurrenceStateNotCreated;

  /// No description provided for @occurrenceStatePending.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get occurrenceStatePending;

  /// No description provided for @occurrenceStateDone.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get occurrenceStateDone;

  /// No description provided for @occurrenceStatePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get occurrenceStatePaid;

  /// No description provided for @occurrenceStateArchived.
  ///
  /// In en, this message translates to:
  /// **'Skipped'**
  String get occurrenceStateArchived;

  /// No description provided for @occurrenceEditOnly.
  ///
  /// In en, this message translates to:
  /// **'This occurrence only'**
  String get occurrenceEditOnly;

  /// No description provided for @occurrenceConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get occurrenceConfirm;

  /// No description provided for @occurrenceEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get occurrenceEnterAmount;

  /// No description provided for @occurrenceMarkPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get occurrenceMarkPaid;

  /// No description provided for @occurrenceUnmarkPaid.
  ///
  /// In en, this message translates to:
  /// **'Not paid'**
  String get occurrenceUnmarkPaid;

  /// No description provided for @occurrenceSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get occurrenceSkip;

  /// No description provided for @occurrenceRestore.
  ///
  /// In en, this message translates to:
  /// **'Un-skip'**
  String get occurrenceRestore;

  /// No description provided for @occurrenceLinkExisting.
  ///
  /// In en, this message translates to:
  /// **'Link an existing transaction'**
  String get occurrenceLinkExisting;

  /// No description provided for @occurrenceConfirmAll.
  ///
  /// In en, this message translates to:
  /// **'Confirm all'**
  String get occurrenceConfirmAll;

  /// No description provided for @occurrencePaidAll.
  ///
  /// In en, this message translates to:
  /// **'All paid'**
  String get occurrencePaidAll;

  /// No description provided for @occurrenceSkipAll.
  ///
  /// In en, this message translates to:
  /// **'Skip all'**
  String get occurrenceSkipAll;

  /// No description provided for @occurrenceLeftOut.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 left without an amount} other{{count} left without an amount}}'**
  String occurrenceLeftOut(int count);

  /// No description provided for @occurrenceLeftOutRefused.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 couldn\'t be recorded} other{{count} couldn\'t be recorded}}'**
  String occurrenceLeftOutRefused(int count);

  /// No description provided for @occurrenceSkipLinkedTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip this occurrence?'**
  String get occurrenceSkipLinkedTitle;

  /// No description provided for @occurrenceSkipKeepTx.
  ///
  /// In en, this message translates to:
  /// **'Skip, keep the transaction'**
  String get occurrenceSkipKeepTx;

  /// No description provided for @occurrenceSkipDeleteTx.
  ///
  /// In en, this message translates to:
  /// **'Skip and delete the transaction'**
  String get occurrenceSkipDeleteTx;

  /// No description provided for @occurrenceDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs action'**
  String get occurrenceDueTitle;

  /// No description provided for @occurrenceDueSince.
  ///
  /// In en, this message translates to:
  /// **'Due since {date}'**
  String occurrenceDueSince(String date);

  /// No description provided for @occurrenceDueMore.
  ///
  /// In en, this message translates to:
  /// **'See all {n}'**
  String occurrenceDueMore(int n);

  /// No description provided for @occurrenceSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get occurrenceSelectAll;

  /// No description provided for @occurrenceSelectedCount.
  ///
  /// In en, this message translates to:
  /// **'{n} selected'**
  String occurrenceSelectedCount(int n);

  /// No description provided for @occurrenceSkipSelected.
  ///
  /// In en, this message translates to:
  /// **'Skip selected'**
  String get occurrenceSkipSelected;

  /// No description provided for @occurrenceConfirmSelected.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, =0{Confirm selected} other{Confirm selected ({n})}}'**
  String occurrenceConfirmSelected(int n);

  /// No description provided for @occurrenceSkipSelectedTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip the {n} selected?'**
  String occurrenceSkipSelectedTitle(int n);

  /// No description provided for @occurrenceSkippedCount.
  ///
  /// In en, this message translates to:
  /// **'{n} skipped'**
  String occurrenceSkippedCount(int n);

  /// No description provided for @occurrenceSavedCount.
  ///
  /// In en, this message translates to:
  /// **'{n} recorded'**
  String occurrenceSavedCount(int n);

  /// No description provided for @recurringWholeMonth.
  ///
  /// In en, this message translates to:
  /// **'Whole month'**
  String get recurringWholeMonth;

  /// No description provided for @occurrenceZeroTitle.
  ///
  /// In en, this message translates to:
  /// **'{n, plural, one{1 has no amount yet} other{{n} have no amount yet}}'**
  String occurrenceZeroTitle(int n);

  /// No description provided for @occurrenceZeroBody.
  ///
  /// In en, this message translates to:
  /// **'They\'ll be recorded as 0 for now. You can fix the amount later. Go ahead?'**
  String get occurrenceZeroBody;

  /// No description provided for @recurringSortDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get recurringSortDate;

  /// No description provided for @recurringSortAmount.
  ///
  /// In en, this message translates to:
  /// **'Largest amount'**
  String get recurringSortAmount;

  /// No description provided for @recurringSortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get recurringSortTooltip;

  /// No description provided for @recurringFilterAllStatus.
  ///
  /// In en, this message translates to:
  /// **'Any status'**
  String get recurringFilterAllStatus;

  /// No description provided for @recurringFilterAllKinds.
  ///
  /// In en, this message translates to:
  /// **'Any type'**
  String get recurringFilterAllKinds;

  /// No description provided for @recurringMonthNoMatch.
  ///
  /// In en, this message translates to:
  /// **'Nothing matches these filters'**
  String get recurringMonthNoMatch;

  /// No description provided for @occurrenceShowLess.
  ///
  /// In en, this message translates to:
  /// **'Show less'**
  String get occurrenceShowLess;

  /// No description provided for @recurringAheadForever.
  ///
  /// In en, this message translates to:
  /// **'keeps going'**
  String get recurringAheadForever;

  /// No description provided for @recurringAheadLeft.
  ///
  /// In en, this message translates to:
  /// **'{n} more'**
  String recurringAheadLeft(int n);

  /// No description provided for @recurringAheadTotal.
  ///
  /// In en, this message translates to:
  /// **'{amount} in all'**
  String recurringAheadTotal(String amount);

  /// No description provided for @recurringAheadUntil.
  ///
  /// In en, this message translates to:
  /// **'until {date}'**
  String recurringAheadUntil(String date);

  /// No description provided for @recurringAheadEdited.
  ///
  /// In en, this message translates to:
  /// **'Changed ahead'**
  String get recurringAheadEdited;

  /// No description provided for @recurringAheadCustomize.
  ///
  /// In en, this message translates to:
  /// **'Change ahead'**
  String get recurringAheadCustomize;

  /// No description provided for @recurringAheadCustomizeHint.
  ///
  /// In en, this message translates to:
  /// **'Change the amount, move or skip the ones ahead'**
  String get recurringAheadCustomizeHint;

  /// No description provided for @recurringAheadNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get recurringAheadNext;

  /// No description provided for @recurringAheadSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get recurringAheadSummary;

  /// No description provided for @recurringTileMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get recurringTileMoved;

  /// No description provided for @recurringTileEdited.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get recurringTileEdited;

  /// No description provided for @recurringFieldKind.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get recurringFieldKind;

  /// No description provided for @recurringFieldDates.
  ///
  /// In en, this message translates to:
  /// **'Pick dates'**
  String get recurringFieldDates;

  /// No description provided for @recurringSectionPeriod.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get recurringSectionPeriod;

  /// No description provided for @recurringHomeTabOverview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get recurringHomeTabOverview;

  /// No description provided for @recurringHomeMonthPay.
  ///
  /// In en, this message translates to:
  /// **'Paid out this month'**
  String get recurringHomeMonthPay;

  /// No description provided for @recurringHomeMonthIncome.
  ///
  /// In en, this message translates to:
  /// **'Income {amount}'**
  String recurringHomeMonthIncome(String amount);

  /// No description provided for @recurringHomeMonthCount.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get recurringHomeMonthCount;

  /// No description provided for @recurringHomeItemCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{1 item} other{{count} items}}'**
  String recurringHomeItemCount(int count);

  /// No description provided for @recurringHomeToday.
  ///
  /// In en, this message translates to:
  /// **'Today {date}'**
  String recurringHomeToday(String date);

  /// No description provided for @recurringDayEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing on {date}'**
  String recurringDayEmpty(String date);

  /// No description provided for @recurringHomeAllTitle.
  ///
  /// In en, this message translates to:
  /// **'All recurring'**
  String get recurringHomeAllTitle;

  /// No description provided for @recurringHomePerMonthYear.
  ///
  /// In en, this message translates to:
  /// **'{month}/mo | {year}/yr'**
  String recurringHomePerMonthYear(String month, String year);

  /// No description provided for @recurringHomePerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount}/mo'**
  String recurringHomePerMonth(String amount);

  /// No description provided for @recurringHomeAvgPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Avg {amount}/mo'**
  String recurringHomeAvgPerMonth(String amount);

  /// No description provided for @recurringHomeLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String recurringHomeLeft(String amount);

  /// No description provided for @txPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick a transaction'**
  String get txPickerTitle;

  /// No description provided for @txPickerGroupNear.
  ///
  /// In en, this message translates to:
  /// **'Near the date'**
  String get txPickerGroupNear;

  /// No description provided for @quickUpcomingHintTitle.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get quickUpcomingHintTitle;

  /// No description provided for @linkedSaveTitle.
  ///
  /// In en, this message translates to:
  /// **'Update the other side too?'**
  String get linkedSaveTitle;

  /// No description provided for @linkedCancel.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get linkedCancel;

  /// No description provided for @linkedSaveThisOnly.
  ///
  /// In en, this message translates to:
  /// **'Save this side only'**
  String get linkedSaveThisOnly;

  /// No description provided for @linkedSaveBoth.
  ///
  /// In en, this message translates to:
  /// **'Save and update the other side'**
  String get linkedSaveBoth;

  /// No description provided for @linkedDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the linked item too?'**
  String get linkedDeleteTitle;

  /// No description provided for @linkedDeleteThisOnly.
  ///
  /// In en, this message translates to:
  /// **'Delete this side only'**
  String get linkedDeleteThisOnly;

  /// No description provided for @linkedDeleteBoth.
  ///
  /// In en, this message translates to:
  /// **'Delete both'**
  String get linkedDeleteBoth;

  /// No description provided for @dueToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get dueToday;

  /// No description provided for @dueTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get dueTomorrow;

  /// No description provided for @dueYesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get dueYesterday;

  /// No description provided for @dueInDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{in 1 day} other{in {count} days}}'**
  String dueInDays(int count);

  /// No description provided for @dueOverdueDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 day overdue} other{{count} days overdue}}'**
  String dueOverdueDays(int count);

  /// No description provided for @recurEveryDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every day} other{Every {count} days}}'**
  String recurEveryDays(int count);

  /// No description provided for @recurEveryWeeks.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every week} other{Every {count} weeks}}'**
  String recurEveryWeeks(int count);

  /// No description provided for @recurWeekday1.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get recurWeekday1;

  /// No description provided for @recurWeekday2.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get recurWeekday2;

  /// No description provided for @recurWeekday3.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get recurWeekday3;

  /// No description provided for @recurWeekday4.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get recurWeekday4;

  /// No description provided for @recurWeekday5.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get recurWeekday5;

  /// No description provided for @recurWeekday6.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get recurWeekday6;

  /// No description provided for @recurWeekday7.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get recurWeekday7;

  /// No description provided for @recurWeekdayPair.
  ///
  /// In en, this message translates to:
  /// **'{a} and {b}'**
  String recurWeekdayPair(String a, String b);

  /// No description provided for @recurWeekdayList.
  ///
  /// In en, this message translates to:
  /// **'{list} and {last}'**
  String recurWeekdayList(String list, String last);

  /// No description provided for @recurWeekdayListSep.
  ///
  /// In en, this message translates to:
  /// **', '**
  String get recurWeekdayListSep;

  /// No description provided for @recurEveryWeekdays.
  ///
  /// In en, this message translates to:
  /// **'Every {weekdays}'**
  String recurEveryWeekdays(String weekdays);

  /// No description provided for @recurOnWeekdays.
  ///
  /// In en, this message translates to:
  /// **'{weekdays}'**
  String recurOnWeekdays(String weekdays);

  /// No description provided for @recurEveryMonths.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every month} other{Every {count} months}}'**
  String recurEveryMonths(int count);

  /// No description provided for @recurMonthlyOnDay.
  ///
  /// In en, this message translates to:
  /// **'Monthly on day {day}'**
  String recurMonthlyOnDay(int day);

  /// No description provided for @recurMonthlyLastDay.
  ///
  /// In en, this message translates to:
  /// **'Monthly on the last day'**
  String get recurMonthlyLastDay;

  /// No description provided for @recurOnDay.
  ///
  /// In en, this message translates to:
  /// **'day {day}'**
  String recurOnDay(int day);

  /// No description provided for @recurLastDay.
  ///
  /// In en, this message translates to:
  /// **'last day'**
  String get recurLastDay;

  /// No description provided for @recurMonthlyNthWeekday.
  ///
  /// In en, this message translates to:
  /// **'{ord, select, first{Monthly on the first {weekday}} second{Monthly on the second {weekday}} third{Monthly on the third {weekday}} fourth{Monthly on the fourth {weekday}} other{Monthly on the fifth {weekday}}}'**
  String recurMonthlyNthWeekday(String ord, int nth, String weekday);

  /// No description provided for @recurMonthlyLastWeekday.
  ///
  /// In en, this message translates to:
  /// **'Monthly on the last {weekday}'**
  String recurMonthlyLastWeekday(String weekday);

  /// No description provided for @recurOnNthWeekday.
  ///
  /// In en, this message translates to:
  /// **'{ord, select, first{the first {weekday}} second{the second {weekday}} third{the third {weekday}} fourth{the fourth {weekday}} other{the fifth {weekday}}}'**
  String recurOnNthWeekday(String ord, int nth, String weekday);

  /// No description provided for @recurOnLastWeekday.
  ///
  /// In en, this message translates to:
  /// **'the last {weekday}'**
  String recurOnLastWeekday(String weekday);

  /// No description provided for @recurEveryYears.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Every year} other{Every {count} years}}'**
  String recurEveryYears(int count);

  /// No description provided for @recurYearlyOn.
  ///
  /// In en, this message translates to:
  /// **'Every year on {date}'**
  String recurYearlyOn(String date);

  /// No description provided for @recurCustomDates.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Custom} =1{Custom | 1 date} other{Custom | {count} dates}}'**
  String recurCustomDates(int count);

  /// No description provided for @recurEndCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 time} other{{count} times}}'**
  String recurEndCount(int count);

  /// No description provided for @recurEndUntil.
  ///
  /// In en, this message translates to:
  /// **'until {date}'**
  String recurEndUntil(String date);

  /// No description provided for @uiPickDatesHint.
  ///
  /// In en, this message translates to:
  /// **'Tap the days to pick them'**
  String get uiPickDatesHint;

  /// No description provided for @txRecurringRowLabel.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get txRecurringRowLabel;

  /// No description provided for @recurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringTitle;

  /// No description provided for @recurringAdd.
  ///
  /// In en, this message translates to:
  /// **'Add recurring'**
  String get recurringAdd;

  /// No description provided for @recurringEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No recurring yet'**
  String get recurringEmptyTitle;

  /// No description provided for @recurringEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Set up repeating items like rent or internet. When the day comes, they wait in Pending.'**
  String get recurringEmptyMessage;

  /// No description provided for @upcomingEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing upcoming'**
  String get upcomingEmptyTitle;

  /// No description provided for @upcomingEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Future-dated items and upcoming recurring items show here.'**
  String get upcomingEmptyMessage;

  /// No description provided for @recurringNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New recurring'**
  String get recurringNewTitle;

  /// No description provided for @recurringNotFound.
  ///
  /// In en, this message translates to:
  /// **'Recurring not found'**
  String get recurringNotFound;

  /// No description provided for @recurringNotFoundMessage.
  ///
  /// In en, this message translates to:
  /// **'It may have been deleted.'**
  String get recurringNotFoundMessage;

  /// No description provided for @recurringFieldIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get recurringFieldIcon;

  /// No description provided for @recurringFieldToWallet.
  ///
  /// In en, this message translates to:
  /// **'To wallet'**
  String get recurringFieldToWallet;

  /// No description provided for @recurringFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get recurringFieldCategory;

  /// No description provided for @recurringFieldRepeat.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get recurringFieldRepeat;

  /// No description provided for @recurringFieldStart.
  ///
  /// In en, this message translates to:
  /// **'Starts'**
  String get recurringFieldStart;

  /// No description provided for @recurringFieldEnd.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get recurringFieldEnd;

  /// No description provided for @recurringNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get recurringNameRequired;

  /// No description provided for @recurringAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above 0'**
  String get recurringAmountInvalid;

  /// No description provided for @recurringWalletRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a wallet'**
  String get recurringWalletRequired;

  /// No description provided for @recurringRepeatDates.
  ///
  /// In en, this message translates to:
  /// **'Pick dates…'**
  String get recurringRepeatDates;

  /// No description provided for @recurringRepeatDatesTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick dates'**
  String get recurringRepeatDatesTitle;

  /// No description provided for @recurringRepeatDatesConfirm.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Pick 1 day} other{Pick {count} days}}'**
  String recurringRepeatDatesConfirm(int count);

  /// No description provided for @recurringEndNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get recurringEndNever;

  /// No description provided for @recurringEndOnDateOption.
  ///
  /// In en, this message translates to:
  /// **'On a date…'**
  String get recurringEndOnDateOption;

  /// No description provided for @recurringEndAfterCountOption.
  ///
  /// In en, this message translates to:
  /// **'After a number of times…'**
  String get recurringEndAfterCountOption;

  /// No description provided for @recurringStatusActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get recurringStatusActive;

  /// No description provided for @recurringStatusPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get recurringStatusPaused;

  /// No description provided for @recurringStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get recurringStatusArchived;

  /// No description provided for @recurringStatusEndingSoon.
  ///
  /// In en, this message translates to:
  /// **'Ending soon'**
  String get recurringStatusEndingSoon;

  /// No description provided for @recurringPause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get recurringPause;

  /// No description provided for @recurringResume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get recurringResume;

  /// No description provided for @recurringArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get recurringArchive;

  /// No description provided for @recurringRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get recurringRestore;

  /// No description provided for @recurringDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete recurring'**
  String get recurringDelete;

  /// No description provided for @recurringArchiveTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this recurring?'**
  String get recurringArchiveTitle;

  /// No description provided for @recurringArchiveBody.
  ///
  /// In en, this message translates to:
  /// **'It stops producing items and is hidden. You can restore it later.'**
  String get recurringArchiveBody;

  /// No description provided for @recurringDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this recurring?'**
  String get recurringDeleteTitle;

  /// No description provided for @recurringDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Deletes the setting and the items not created yet.'**
  String get recurringDeleteBody;

  /// No description provided for @recurringDeleteKeepTxs.
  ///
  /// In en, this message translates to:
  /// **'Delete, keep the transactions'**
  String get recurringDeleteKeepTxs;

  /// No description provided for @recurringDeleteWithTxs.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Delete with 1 transaction} other{Delete with {count} transactions}}'**
  String recurringDeleteWithTxs(int count);

  /// No description provided for @recurringScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply to'**
  String get recurringScopeTitle;

  /// No description provided for @recurringScopeUpcoming.
  ///
  /// In en, this message translates to:
  /// **'All upcoming items'**
  String get recurringScopeUpcoming;

  /// No description provided for @recurringScopeAll.
  ///
  /// In en, this message translates to:
  /// **'All items'**
  String get recurringScopeAll;

  /// No description provided for @recurringEndingSoon.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Ending soon: 1 item left} other{Ending soon: {count} items left}}'**
  String recurringEndingSoon(int count);

  /// No description provided for @recurringExtend.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get recurringExtend;

  /// No description provided for @recurringPausedNotice.
  ///
  /// In en, this message translates to:
  /// **'Paused: dates that pass while paused produce nothing.'**
  String get recurringPausedNotice;

  /// No description provided for @recurringItemsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing due yet'**
  String get recurringItemsEmpty;

  /// No description provided for @recurringUpcomingEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing upcoming'**
  String get recurringUpcomingEmpty;

  /// No description provided for @recurringUpcomingEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Extend it or edit the setting to produce more.'**
  String get recurringUpcomingEmptyMessage;

  /// No description provided for @recurringItemRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get recurringItemRestore;

  /// No description provided for @recurringScopeThis.
  ///
  /// In en, this message translates to:
  /// **'This item only'**
  String get recurringScopeThis;

  /// No description provided for @recurringScopeFollowing.
  ///
  /// In en, this message translates to:
  /// **'This and following'**
  String get recurringScopeFollowing;

  /// No description provided for @recurringScopePast.
  ///
  /// In en, this message translates to:
  /// **'All past items'**
  String get recurringScopePast;

  /// No description provided for @recurringItemEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit item'**
  String get recurringItemEditTitle;

  /// No description provided for @moreRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get moreRecurring;

  /// No description provided for @moreRecurringDesc.
  ///
  /// In en, this message translates to:
  /// **'Bills and repeating entries'**
  String get moreRecurringDesc;

  /// No description provided for @notifRecurringDue.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 recurring payment is due} other{{count} recurring payments are due}}'**
  String notifRecurringDue(int count);

  /// No description provided for @notifRecurringAutoCreated.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Recorded 1 automatically} other{Recorded {count} automatically}}'**
  String notifRecurringAutoCreated(int count);

  /// No description provided for @notifRecurringEnding.
  ///
  /// In en, this message translates to:
  /// **'{name} has {left} items left — extend it?'**
  String notifRecurringEnding(String name, int left);

  /// No description provided for @recurSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Custom repeat'**
  String get recurSheetTitle;

  /// No description provided for @recurSheetEvery.
  ///
  /// In en, this message translates to:
  /// **'Every'**
  String get recurSheetEvery;

  /// No description provided for @recurSheetUnitDay.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{day} other{days}}'**
  String recurSheetUnitDay(int count);

  /// No description provided for @recurSheetUnitWeek.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{week} other{weeks}}'**
  String recurSheetUnitWeek(int count);

  /// No description provided for @recurSheetUnitMonth.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{month} other{months}}'**
  String recurSheetUnitMonth(int count);

  /// No description provided for @recurSheetUnitYear.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{year} other{years}}'**
  String recurSheetUnitYear(int count);

  /// No description provided for @recurSheetRepeatOn.
  ///
  /// In en, this message translates to:
  /// **'Repeat on'**
  String get recurSheetRepeatOn;

  /// No description provided for @recurSheetMonthlyOn.
  ///
  /// In en, this message translates to:
  /// **'Monthly on'**
  String get recurSheetMonthlyOn;

  /// No description provided for @recurSheetLastDayOfMonth.
  ///
  /// In en, this message translates to:
  /// **'the last day of the month'**
  String get recurSheetLastDayOfMonth;

  /// No description provided for @recurSheetEnds.
  ///
  /// In en, this message translates to:
  /// **'Ends'**
  String get recurSheetEnds;

  /// No description provided for @recurSheetEndNever.
  ///
  /// In en, this message translates to:
  /// **'Never'**
  String get recurSheetEndNever;

  /// No description provided for @recurSheetEndOnDate.
  ///
  /// In en, this message translates to:
  /// **'On a date'**
  String get recurSheetEndOnDate;

  /// No description provided for @recurSheetEndAfter.
  ///
  /// In en, this message translates to:
  /// **'After'**
  String get recurSheetEndAfter;

  /// No description provided for @recurSheetOccurrences.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{time} other{times}}'**
  String recurSheetOccurrences(int count);

  /// No description provided for @recurSheetPeriodStart.
  ///
  /// In en, this message translates to:
  /// **'Each period starts on'**
  String get recurSheetPeriodStart;

  /// No description provided for @recurSheetYearlyOn.
  ///
  /// In en, this message translates to:
  /// **'Every year on'**
  String get recurSheetYearlyOn;

  /// No description provided for @recurSheetByDay.
  ///
  /// In en, this message translates to:
  /// **'On a date'**
  String get recurSheetByDay;

  /// No description provided for @recurSheetByWeekday.
  ///
  /// In en, this message translates to:
  /// **'On a weekday'**
  String get recurSheetByWeekday;

  /// No description provided for @recurSheetNth.
  ///
  /// In en, this message translates to:
  /// **'{ord, select, first{1st} second{2nd} third{3rd} other{4th}}'**
  String recurSheetNth(String ord, int nth);

  /// No description provided for @recurSheetStartMoves.
  ///
  /// In en, this message translates to:
  /// **'The start moves to {date}'**
  String recurSheetStartMoves(String date);

  /// No description provided for @recurringRepeatCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom…'**
  String get recurringRepeatCustom;

  /// No description provided for @moreGroupPlan.
  ///
  /// In en, this message translates to:
  /// **'Money plans'**
  String get moreGroupPlan;

  /// No description provided for @moreGroupOthers.
  ///
  /// In en, this message translates to:
  /// **'Money with others'**
  String get moreGroupOthers;

  /// No description provided for @moreGroupSetup.
  ///
  /// In en, this message translates to:
  /// **'Setup data'**
  String get moreGroupSetup;

  /// No description provided for @moreGroupMain.
  ///
  /// In en, this message translates to:
  /// **'Main menu'**
  String get moreGroupMain;

  /// No description provided for @moreSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile & settings'**
  String get moreSettings;

  /// No description provided for @moreDashboardDesc.
  ///
  /// In en, this message translates to:
  /// **'This month\'s overview'**
  String get moreDashboardDesc;

  /// No description provided for @moreTransactionsDesc.
  ///
  /// In en, this message translates to:
  /// **'All income and expenses'**
  String get moreTransactionsDesc;

  /// No description provided for @moreWalletsDesc.
  ///
  /// In en, this message translates to:
  /// **'Cash, accounts and cards'**
  String get moreWalletsDesc;

  /// No description provided for @morePendingDesc.
  ///
  /// In en, this message translates to:
  /// **'Drafts waiting for you to confirm'**
  String get morePendingDesc;

  /// No description provided for @moreNotificationsDesc.
  ///
  /// In en, this message translates to:
  /// **'News and reminders'**
  String get moreNotificationsDesc;

  /// No description provided for @moreSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Account, theme and notifications'**
  String get moreSettingsDesc;

  /// No description provided for @sgv2SavedTotal.
  ///
  /// In en, this message translates to:
  /// **'Saved in total'**
  String get sgv2SavedTotal;

  /// No description provided for @sgv2InGoals.
  ///
  /// In en, this message translates to:
  /// **'In goals'**
  String get sgv2InGoals;

  /// No description provided for @sgv2Spare.
  ///
  /// In en, this message translates to:
  /// **'Not allocated'**
  String get sgv2Spare;

  /// No description provided for @sgv2SpareHint.
  ///
  /// In en, this message translates to:
  /// **'Savings without a goal'**
  String get sgv2SpareHint;

  /// No description provided for @sgv2FilterActive.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get sgv2FilterActive;

  /// No description provided for @sgv2FilterCompleted.
  ///
  /// In en, this message translates to:
  /// **'Reached'**
  String get sgv2FilterCompleted;

  /// No description provided for @sgv2FilterArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get sgv2FilterArchived;

  /// No description provided for @sgv2EmptyFilteredTitle.
  ///
  /// In en, this message translates to:
  /// **'No goals here'**
  String get sgv2EmptyFilteredTitle;

  /// No description provided for @sgv2PaceLate.
  ///
  /// In en, this message translates to:
  /// **'{n} months late'**
  String sgv2PaceLate(int n);

  /// No description provided for @sgv2PaceOnTrack.
  ///
  /// In en, this message translates to:
  /// **'On track'**
  String get sgv2PaceOnTrack;

  /// No description provided for @sgv2PaceLine.
  ///
  /// In en, this message translates to:
  /// **'Need {needed}/mo | saving {pace}'**
  String sgv2PaceLine(String needed, String pace);

  /// No description provided for @sgv2DueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String sgv2DueOn(String date);

  /// No description provided for @sgv2NoDeadline.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get sgv2NoDeadline;

  /// No description provided for @sgv2ActionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add savings'**
  String get sgv2ActionAdd;

  /// No description provided for @sgv2ActionWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get sgv2ActionWithdraw;

  /// No description provided for @sgv2ActionMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get sgv2ActionMove;

  /// No description provided for @sgv2Overview.
  ///
  /// In en, this message translates to:
  /// **'Overview'**
  String get sgv2Overview;

  /// No description provided for @sgv2NeededMonthly.
  ///
  /// In en, this message translates to:
  /// **'Needed per month'**
  String get sgv2NeededMonthly;

  /// No description provided for @sgv2PaceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Actual (3-month average)'**
  String get sgv2PaceMonthly;

  /// No description provided for @sgv2Eta.
  ///
  /// In en, this message translates to:
  /// **'At this pace, done'**
  String get sgv2Eta;

  /// No description provided for @sgv2TimeLeft.
  ///
  /// In en, this message translates to:
  /// **'Time left'**
  String get sgv2TimeLeft;

  /// No description provided for @sgv2ByWallet.
  ///
  /// In en, this message translates to:
  /// **'By wallet'**
  String get sgv2ByWallet;

  /// No description provided for @sgv2ByWalletHint.
  ///
  /// In en, this message translates to:
  /// **'Saved money remembers its wallet'**
  String get sgv2ByWalletHint;

  /// No description provided for @sgv2Entries.
  ///
  /// In en, this message translates to:
  /// **'Saving entries'**
  String get sgv2Entries;

  /// No description provided for @sgv2EntriesEmpty.
  ///
  /// In en, this message translates to:
  /// **'No saving entries yet'**
  String get sgv2EntriesEmpty;

  /// No description provided for @sgv2EntriesMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get sgv2EntriesMore;

  /// No description provided for @sgv2AutoSave.
  ///
  /// In en, this message translates to:
  /// **'Auto-save'**
  String get sgv2AutoSave;

  /// No description provided for @sgv2AutoSaveNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get sgv2AutoSaveNone;

  /// No description provided for @sgv2CloseGoal.
  ///
  /// In en, this message translates to:
  /// **'Close goal'**
  String get sgv2CloseGoal;

  /// No description provided for @sgv2CloseTitle.
  ///
  /// In en, this message translates to:
  /// **'Close “{name}”'**
  String sgv2CloseTitle(String name);

  /// No description provided for @sgv2CloseBody.
  ///
  /// In en, this message translates to:
  /// **'Where should the {amount} go?'**
  String sgv2CloseBody(String amount);

  /// No description provided for @sgv2CloseToSpare.
  ///
  /// In en, this message translates to:
  /// **'Into not allocated'**
  String get sgv2CloseToSpare;

  /// No description provided for @sgv2CloseToWallets.
  ///
  /// In en, this message translates to:
  /// **'Back to the wallets'**
  String get sgv2CloseToWallets;

  /// No description provided for @sgv2Restore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get sgv2Restore;

  /// No description provided for @sgv2KindSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get sgv2KindSave;

  /// No description provided for @sgv2KindWithdraw.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get sgv2KindWithdraw;

  /// No description provided for @sgv2KindMove.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get sgv2KindMove;

  /// No description provided for @sgv2SpareTitle.
  ///
  /// In en, this message translates to:
  /// **'Not allocated'**
  String get sgv2SpareTitle;

  /// No description provided for @sgv2Milestone.
  ///
  /// In en, this message translates to:
  /// **'Reached {pct}%'**
  String sgv2Milestone(int pct);

  /// No description provided for @walletTrackLabel.
  ///
  /// In en, this message translates to:
  /// **'Track balance'**
  String get walletTrackLabel;

  /// No description provided for @walletTrackHelper.
  ///
  /// In en, this message translates to:
  /// **'Turn off if you do not want a balance for this wallet (you can still log and transfer)'**
  String get walletTrackHelper;

  /// No description provided for @walletTrackSetBalanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Current balance'**
  String get walletTrackSetBalanceTitle;

  /// No description provided for @walletTrackSetBalanceAction.
  ///
  /// In en, this message translates to:
  /// **'Set balance'**
  String get walletTrackSetBalanceAction;

  /// No description provided for @walletErrorBalanceNotTracked.
  ///
  /// In en, this message translates to:
  /// **'This wallet does not track its balance - turn tracking on to adjust it'**
  String get walletErrorBalanceNotTracked;

  /// No description provided for @multiPickCategoriesTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose categories'**
  String get multiPickCategoriesTitle;

  /// No description provided for @multiPickWalletsTitle.
  ///
  /// In en, this message translates to:
  /// **'Choose wallets'**
  String get multiPickWalletsTitle;

  /// No description provided for @multiPickSearch.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get multiPickSearch;

  /// No description provided for @multiPickIncludeChildren.
  ///
  /// In en, this message translates to:
  /// **'Include subcategories'**
  String get multiPickIncludeChildren;

  /// No description provided for @multiPickEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet'**
  String get multiPickEmpty;

  /// No description provided for @multiPickNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No match'**
  String get multiPickNoMatch;

  /// No description provided for @multiPickConfirm.
  ///
  /// In en, this message translates to:
  /// **'Done ({count})'**
  String multiPickConfirm(int count);

  /// No description provided for @bgFilterActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get bgFilterActive;

  /// No description provided for @bgFilterEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get bgFilterEnded;

  /// No description provided for @bgFilterArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get bgFilterArchived;

  /// No description provided for @bgSortRisk.
  ///
  /// In en, this message translates to:
  /// **'Closest to the limit'**
  String get bgSortRisk;

  /// No description provided for @bgSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get bgSortName;

  /// No description provided for @bgSortNewest.
  ///
  /// In en, this message translates to:
  /// **'Newest'**
  String get bgSortNewest;

  /// No description provided for @bgSortChip.
  ///
  /// In en, this message translates to:
  /// **'Sort: {sort}'**
  String bgSortChip(String sort);

  /// No description provided for @bgStatOver.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get bgStatOver;

  /// No description provided for @bgStatWarn.
  ///
  /// In en, this message translates to:
  /// **'Near the limit'**
  String get bgStatWarn;

  /// No description provided for @bgStatusOver.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get bgStatusOver;

  /// No description provided for @bgStatusWarn.
  ///
  /// In en, this message translates to:
  /// **'Near limit'**
  String get bgStatusWarn;

  /// No description provided for @bgStatusPace.
  ///
  /// In en, this message translates to:
  /// **'On pace to exceed'**
  String get bgStatusPace;

  /// No description provided for @bgStatusEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get bgStatusEnded;

  /// No description provided for @bgStatusArchived.
  ///
  /// In en, this message translates to:
  /// **'Archived'**
  String get bgStatusArchived;

  /// No description provided for @bgStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Not started'**
  String get bgStatusUpcoming;

  /// No description provided for @bgListEmptyEnded.
  ///
  /// In en, this message translates to:
  /// **'No ended budgets yet'**
  String get bgListEmptyEnded;

  /// No description provided for @bgListEmptyArchived.
  ///
  /// In en, this message translates to:
  /// **'No archived budgets'**
  String get bgListEmptyArchived;

  /// No description provided for @bgRuleDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get bgRuleDaily;

  /// No description provided for @bgRuleWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get bgRuleWeekly;

  /// No description provided for @bgRuleMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get bgRuleMonthly;

  /// No description provided for @bgRuleYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get bgRuleYearly;

  /// No description provided for @bgRowRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String bgRowRange(String start, String end);

  /// No description provided for @bgRowOpenEnded.
  ///
  /// In en, this message translates to:
  /// **'No end date'**
  String get bgRowOpenEnded;

  /// No description provided for @bgRowSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String bgRowSince(String date);

  /// No description provided for @bgRowDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String bgRowDaysLeft(int count);

  /// No description provided for @bgRowUsed.
  ///
  /// In en, this message translates to:
  /// **'Used {used} of {amount}'**
  String bgRowUsed(String used, String amount);

  /// No description provided for @bgPeriodNow.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get bgPeriodNow;

  /// No description provided for @bgPeriodOverridden.
  ///
  /// In en, this message translates to:
  /// **'This period only'**
  String get bgPeriodOverridden;

  /// No description provided for @bgSourceNormal.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get bgSourceNormal;

  /// No description provided for @bgSourceRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get bgSourceRecurring;

  /// No description provided for @bgSourceEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get bgSourceEvent;

  /// No description provided for @bgSourceUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Recurring | upcoming'**
  String get bgSourceUpcoming;

  /// No description provided for @bgSourcePending.
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get bgSourcePending;

  /// No description provided for @bgSourceFutureTx.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get bgSourceFutureTx;

  /// No description provided for @bgPeriodsAll.
  ///
  /// In en, this message translates to:
  /// **'All earlier periods'**
  String get bgPeriodsAll;

  /// No description provided for @bgItemsMore.
  ///
  /// In en, this message translates to:
  /// **'Show more'**
  String get bgItemsMore;

  /// No description provided for @bgItemsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing counted in this period yet'**
  String get bgItemsEmpty;

  /// No description provided for @bgPeriodEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit this period only'**
  String get bgPeriodEditTitle;

  /// No description provided for @bgPeriodAmountField.
  ///
  /// In en, this message translates to:
  /// **'Amount for this period'**
  String get bgPeriodAmountField;

  /// No description provided for @bgSectionScope.
  ///
  /// In en, this message translates to:
  /// **'Which spending counts'**
  String get bgSectionScope;

  /// No description provided for @bgScopeAll.
  ///
  /// In en, this message translates to:
  /// **'Every expense'**
  String get bgScopeAll;

  /// No description provided for @bgScopeCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get bgScopeCategories;

  /// No description provided for @bgScopeTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get bgScopeTags;

  /// No description provided for @bgScopeWallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get bgScopeWallets;

  /// No description provided for @bgScopeChildren.
  ///
  /// In en, this message translates to:
  /// **'All {name}'**
  String bgScopeChildren(String name);

  /// No description provided for @bgScopeRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick what to count, or turn on \"Every expense\"'**
  String get bgScopeRequired;

  /// No description provided for @bgSectionPeriod.
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get bgSectionPeriod;

  /// No description provided for @bgFieldRepeat.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get bgFieldRepeat;

  /// No description provided for @bgFieldRepeatToggle.
  ///
  /// In en, this message translates to:
  /// **'Repeat'**
  String get bgFieldRepeatToggle;

  /// No description provided for @bgFieldStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get bgFieldStart;

  /// No description provided for @bgFieldEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get bgFieldEnd;

  /// No description provided for @bgSectionPeriodDesc.
  ///
  /// In en, this message translates to:
  /// **'When it starts and how it repeats'**
  String get bgSectionPeriodDesc;

  /// No description provided for @bgScopeChoose.
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get bgScopeChoose;

  /// No description provided for @bgScopeAndHint.
  ///
  /// In en, this message translates to:
  /// **'Counts spending that matches every row you pick (any item within a row)'**
  String get bgScopeAndHint;

  /// No description provided for @bgScopePickTags.
  ///
  /// In en, this message translates to:
  /// **'Choose tags'**
  String get bgScopePickTags;

  /// No description provided for @bgStatusOnPlan.
  ///
  /// In en, this message translates to:
  /// **'On plan'**
  String get bgStatusOnPlan;

  /// No description provided for @bgStatusAhead.
  ///
  /// In en, this message translates to:
  /// **'{amount} ahead of plan'**
  String bgStatusAhead(String amount);

  /// No description provided for @bgStatusOverBy.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String bgStatusOverBy(String amount);

  /// No description provided for @bgRingOf.
  ///
  /// In en, this message translates to:
  /// **'of {amount}'**
  String bgRingOf(String amount);

  /// No description provided for @bgFactUsed.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get bgFactUsed;

  /// No description provided for @bgFactPending.
  ///
  /// In en, this message translates to:
  /// **'Coming up'**
  String get bgFactPending;

  /// No description provided for @bgFactPlanToday.
  ///
  /// In en, this message translates to:
  /// **'Plan to date'**
  String get bgFactPlanToday;

  /// No description provided for @bgPaceBubble.
  ///
  /// In en, this message translates to:
  /// **'Plan to date {amount}'**
  String bgPaceBubble(String amount);

  /// No description provided for @bgRingTotalLeft.
  ///
  /// In en, this message translates to:
  /// **'Left in total'**
  String get bgRingTotalLeft;

  /// No description provided for @bgFactUsedTotal.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get bgFactUsedTotal;

  /// No description provided for @bgFactUsedPct.
  ///
  /// In en, this message translates to:
  /// **'Used'**
  String get bgFactUsedPct;

  /// No description provided for @bgFactBudgetCount.
  ///
  /// In en, this message translates to:
  /// **'Budgets this period'**
  String get bgFactBudgetCount;

  /// No description provided for @bgCountBudgets.
  ///
  /// In en, this message translates to:
  /// **'{count} budgets'**
  String bgCountBudgets(int count);

  /// No description provided for @bgFactNextRound.
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get bgFactNextRound;

  /// No description provided for @bgFieldStartHelp.
  ///
  /// In en, this message translates to:
  /// **'Spending counts from this day'**
  String get bgFieldStartHelp;

  /// No description provided for @bgEndNone.
  ///
  /// In en, this message translates to:
  /// **'No end'**
  String get bgEndNone;

  /// No description provided for @bgEndOnDate.
  ///
  /// In en, this message translates to:
  /// **'ends {date}'**
  String bgEndOnDate(Object date);

  /// No description provided for @bgEndPickDate.
  ///
  /// In en, this message translates to:
  /// **'Pick a date…'**
  String get bgEndPickDate;

  /// No description provided for @bgEndPeriods.
  ///
  /// In en, this message translates to:
  /// **'{count} periods'**
  String bgEndPeriods(int count);

  /// No description provided for @bgWarnOff.
  ///
  /// In en, this message translates to:
  /// **'No warning'**
  String get bgWarnOff;

  /// No description provided for @bgWarnPct.
  ///
  /// In en, this message translates to:
  /// **'{pct}%'**
  String bgWarnPct(int pct);

  /// No description provided for @bgScopeChoiceTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply the new setup to'**
  String get bgScopeChoiceTitle;

  /// No description provided for @bgScopeFollowing.
  ///
  /// In en, this message translates to:
  /// **'This and following periods'**
  String get bgScopeFollowing;

  /// No description provided for @bgScopeAllPeriods.
  ///
  /// In en, this message translates to:
  /// **'Every period (past ones too)'**
  String get bgScopeAllPeriods;

  /// No description provided for @bgClose.
  ///
  /// In en, this message translates to:
  /// **'Close the budget'**
  String get bgClose;

  /// No description provided for @bgCloseConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Close this budget?'**
  String get bgCloseConfirmTitle;

  /// No description provided for @bgCloseConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'It stops counting from today and moves to \"Ended\".'**
  String get bgCloseConfirmBody;

  /// No description provided for @bgRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get bgRestore;

  /// No description provided for @bgNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get bgNameRequired;

  /// No description provided for @pendingSavingConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Confirm as saving?'**
  String get pendingSavingConfirmTitle;

  /// No description provided for @pendingSavingConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get pendingSavingConfirm;

  /// No description provided for @pendingSavingNoWallet.
  ///
  /// In en, this message translates to:
  /// **'Pick a wallet before confirming'**
  String get pendingSavingNoWallet;

  /// No description provided for @walletSavingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get walletSavingsTitle;

  /// No description provided for @walletSavingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Money you have set aside in this wallet'**
  String get walletSavingsDescription;

  /// No description provided for @walletSavingsBalance.
  ///
  /// In en, this message translates to:
  /// **'Real balance'**
  String get walletSavingsBalance;

  /// No description provided for @walletSavingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get walletSavingsSaved;

  /// No description provided for @walletSavingsAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available to spend'**
  String get walletSavingsAvailable;

  /// No description provided for @walletSavingsOver.
  ///
  /// In en, this message translates to:
  /// **'Saved more than the real balance {amount}'**
  String walletSavingsOver(String amount);

  /// No description provided for @quickModeSaving.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get quickModeSaving;

  /// No description provided for @savingEntryTitleHint.
  ///
  /// In en, this message translates to:
  /// **'Note (optional)'**
  String get savingEntryTitleHint;

  /// No description provided for @savingEntryTarget.
  ///
  /// In en, this message translates to:
  /// **'Save into'**
  String get savingEntryTarget;

  /// No description provided for @savingEntrySpare.
  ///
  /// In en, this message translates to:
  /// **'Not allocated'**
  String get savingEntrySpare;

  /// No description provided for @savingEntryPickGoal.
  ///
  /// In en, this message translates to:
  /// **'Pick a saving goal'**
  String get savingEntryPickGoal;

  /// No description provided for @savingEntryAvailable.
  ///
  /// In en, this message translates to:
  /// **'{amount} free to save'**
  String savingEntryAvailable(String amount);

  /// No description provided for @savingEntryOverAvailable.
  ///
  /// In en, this message translates to:
  /// **'{amount} more than is free (still allowed)'**
  String savingEntryOverAvailable(String amount);

  /// No description provided for @savingEntryWalletRequired.
  ///
  /// In en, this message translates to:
  /// **'Pick a wallet'**
  String get savingEntryWalletRequired;

  /// No description provided for @savingEntrySaved.
  ///
  /// In en, this message translates to:
  /// **'Saving recorded'**
  String get savingEntrySaved;

  /// No description provided for @walletSavingsAdd.
  ///
  /// In en, this message translates to:
  /// **'Add savings'**
  String get walletSavingsAdd;

  /// No description provided for @sgv2MoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move savings'**
  String get sgv2MoveTitle;

  /// No description provided for @sgv2WithdrawTitle.
  ///
  /// In en, this message translates to:
  /// **'Withdraw savings'**
  String get sgv2WithdrawTitle;

  /// No description provided for @sgv2MoveFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get sgv2MoveFrom;

  /// No description provided for @sgv2MoveTo.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get sgv2MoveTo;

  /// No description provided for @sgv2WalletsCard.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get sgv2WalletsCard;

  /// No description provided for @sgv2AmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get sgv2AmountLabel;

  /// No description provided for @sgv2SplitTitle.
  ///
  /// In en, this message translates to:
  /// **'By wallet (automatic)'**
  String get sgv2SplitTitle;

  /// No description provided for @sgv2SplitEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get sgv2SplitEdit;

  /// No description provided for @sgv2SplitHas.
  ///
  /// In en, this message translates to:
  /// **'Has {amount}'**
  String sgv2SplitHas(String amount);

  /// No description provided for @sgv2SumOk.
  ///
  /// In en, this message translates to:
  /// **'Total {sum} ✓'**
  String sgv2SumOk(String sum);

  /// No description provided for @sgv2SumOff.
  ///
  /// In en, this message translates to:
  /// **'Total {sum} does not match {amount}'**
  String sgv2SumOff(String sum, String amount);

  /// No description provided for @sgv2ReturnsTitle.
  ///
  /// In en, this message translates to:
  /// **'If it goes back'**
  String get sgv2ReturnsTitle;

  /// No description provided for @sgv2Cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get sgv2Cancel;

  /// No description provided for @sgv2MovePick.
  ///
  /// In en, this message translates to:
  /// **'Move to where?'**
  String get sgv2MovePick;

  /// No description provided for @sgv2MoveSave.
  ///
  /// In en, this message translates to:
  /// **'Move'**
  String get sgv2MoveSave;

  /// No description provided for @sgv2WithdrawSave.
  ///
  /// In en, this message translates to:
  /// **'Withdraw'**
  String get sgv2WithdrawSave;

  /// No description provided for @sgv2ChartCaption.
  ///
  /// In en, this message translates to:
  /// **'Saved so far'**
  String get sgv2ChartCaption;

  /// No description provided for @sgv2ChartActual.
  ///
  /// In en, this message translates to:
  /// **'Saved / at this pace'**
  String get sgv2ChartActual;

  /// No description provided for @sgv2ChartNeeded.
  ///
  /// In en, this message translates to:
  /// **'Line needed'**
  String get sgv2ChartNeeded;

  /// No description provided for @sgv2ChartTarget.
  ///
  /// In en, this message translates to:
  /// **'Goal {amount}'**
  String sgv2ChartTarget(String amount);

  /// No description provided for @sgv2SpareName.
  ///
  /// In en, this message translates to:
  /// **'Not allocated'**
  String get sgv2SpareName;

  /// No description provided for @sgv2NoOtherGoal.
  ///
  /// In en, this message translates to:
  /// **'No other goal to move to'**
  String get sgv2NoOtherGoal;

  /// No description provided for @sgv2EntryDeleted.
  ///
  /// In en, this message translates to:
  /// **'Saving entry deleted'**
  String get sgv2EntryDeleted;

  /// No description provided for @profileCurrencyChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change currency?'**
  String get profileCurrencyChangeTitle;

  /// No description provided for @profileCurrencyChangeMessage.
  ///
  /// In en, this message translates to:
  /// **'Only the label changes. Your amounts are NOT converted: 100 stays 100.'**
  String get profileCurrencyChangeMessage;

  /// No description provided for @profileCurrencyChangeConfirm.
  ///
  /// In en, this message translates to:
  /// **'Change currency'**
  String get profileCurrencyChangeConfirm;

  /// No description provided for @bgSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search budgets'**
  String get bgSearchHint;

  /// No description provided for @bgNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching budgets'**
  String get bgNoMatch;

  /// No description provided for @sgv2SearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search goals'**
  String get sgv2SearchHint;

  /// No description provided for @recurringSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search recurring'**
  String get recurringSearchHint;

  /// No description provided for @recurringNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching recurring'**
  String get recurringNoMatch;

  /// No description provided for @accountsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search wallets'**
  String get accountsSearchHint;

  /// No description provided for @accountsNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching wallets'**
  String get accountsNoMatch;

  /// No description provided for @bgTileAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get bgTileAll;

  /// No description provided for @bgTileOk.
  ///
  /// In en, this message translates to:
  /// **'Normal'**
  String get bgTileOk;

  /// No description provided for @bgStatusFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get bgStatusFieldLabel;

  /// No description provided for @bgRowLeft.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get bgRowLeft;

  /// No description provided for @bgRowOverAmount.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get bgRowOverAmount;

  /// No description provided for @bgRowOneOff.
  ///
  /// In en, this message translates to:
  /// **'One-off'**
  String get bgRowOneOff;

  /// No description provided for @fpWalletsTileAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get fpWalletsTileAvailable;

  /// No description provided for @fpWalletsCreditUsedPct.
  ///
  /// In en, this message translates to:
  /// **'{pct}% of limit used'**
  String fpWalletsCreditUsedPct(int pct);

  /// No description provided for @fpWalletsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get fpWalletsFilterAll;

  /// No description provided for @fpWalletsFilterCash.
  ///
  /// In en, this message translates to:
  /// **'Cash / bank'**
  String get fpWalletsFilterCash;

  /// No description provided for @fpWalletsFilterCard.
  ///
  /// In en, this message translates to:
  /// **'Credit cards'**
  String get fpWalletsFilterCard;

  /// No description provided for @fpWalletsSharedTooltip.
  ///
  /// In en, this message translates to:
  /// **'{count} shared'**
  String fpWalletsSharedTooltip(int count);

  /// No description provided for @fpWalletsSortByType.
  ///
  /// In en, this message translates to:
  /// **'By type'**
  String get fpWalletsSortByType;

  /// No description provided for @fpWalletsReorderChip.
  ///
  /// In en, this message translates to:
  /// **'Reorder'**
  String get fpWalletsReorderChip;

  /// No description provided for @fpWalletBalanceLabel.
  ///
  /// In en, this message translates to:
  /// **'In the wallet'**
  String get fpWalletBalanceLabel;

  /// No description provided for @fpWalletSavedLegend.
  ///
  /// In en, this message translates to:
  /// **'Saved {amount}'**
  String fpWalletSavedLegend(String amount);

  /// No description provided for @fpWalletSavedInTitle.
  ///
  /// In en, this message translates to:
  /// **'Saved in'**
  String get fpWalletSavedInTitle;

  /// No description provided for @fpWalletSavedInDesc.
  ///
  /// In en, this message translates to:
  /// **'Money in this wallet set aside for goals'**
  String get fpWalletSavedInDesc;

  /// No description provided for @fpWalletAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get fpWalletAvailableLabel;

  /// No description provided for @fpWalletSavedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get fpWalletSavedLabel;

  /// No description provided for @fpWalletSavedOverAlert.
  ///
  /// In en, this message translates to:
  /// **'Saved {amount} more than the wallet holds'**
  String fpWalletSavedOverAlert(String amount);

  /// No description provided for @fpWalletCreditUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Used on the card'**
  String get fpWalletCreditUsedLabel;

  /// No description provided for @fpWalletCardUsedLabel.
  ///
  /// In en, this message translates to:
  /// **'Used {pct}%'**
  String fpWalletCardUsedLabel(int pct);

  /// No description provided for @fpWalletCardAvailableLabel.
  ///
  /// In en, this message translates to:
  /// **'Available of the {limit} limit'**
  String fpWalletCardAvailableLabel(String limit);

  /// No description provided for @fpWalletScopeOwnChip.
  ///
  /// In en, this message translates to:
  /// **'Mine only'**
  String get fpWalletScopeOwnChip;

  /// No description provided for @fpWalletFlowIn.
  ///
  /// In en, this message translates to:
  /// **'In {month}'**
  String fpWalletFlowIn(String month);

  /// No description provided for @fpWalletFlowOut.
  ///
  /// In en, this message translates to:
  /// **'Out {month}'**
  String fpWalletFlowOut(String month);

  /// No description provided for @fpWalletCardLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String fpWalletCardLeft(String amount);

  /// No description provided for @fpWalletDueAlert.
  ///
  /// In en, this message translates to:
  /// **'Payment due {date} | in {days} days'**
  String fpWalletDueAlert(String date, int days);

  /// No description provided for @accountCardDueIn.
  ///
  /// In en, this message translates to:
  /// **'Due in {days} days'**
  String accountCardDueIn(int days);

  /// No description provided for @accountCardDueToday.
  ///
  /// In en, this message translates to:
  /// **'Due today'**
  String get accountCardDueToday;

  /// No description provided for @fpWalletPayCard.
  ///
  /// In en, this message translates to:
  /// **'Pay card'**
  String get fpWalletPayCard;

  /// No description provided for @fpWalletSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get fpWalletSave;

  /// No description provided for @fpWalletSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'How this wallet counts in totals and reports'**
  String get fpWalletSettingsDesc;

  /// No description provided for @fpWalletCardSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'How this card counts in reports'**
  String get fpWalletCardSettingsDesc;

  /// No description provided for @fpWalletArchiveConsequence.
  ///
  /// In en, this message translates to:
  /// **'Counted nowhere, read-only, restorable'**
  String get fpWalletArchiveConsequence;

  /// No description provided for @fpWalletInviteLabel.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get fpWalletInviteLabel;

  /// No description provided for @fpWalletOwnerCaption.
  ///
  /// In en, this message translates to:
  /// **'Owner'**
  String get fpWalletOwnerCaption;

  /// No description provided for @fpWalletMemberCaption.
  ///
  /// In en, this message translates to:
  /// **'Member'**
  String get fpWalletMemberCaption;

  /// No description provided for @fpTxAvgDaily.
  ///
  /// In en, this message translates to:
  /// **'Avg spend {amount}/day'**
  String fpTxAvgDaily(String amount);

  /// No description provided for @fpWalletDeleteLabel.
  ///
  /// In en, this message translates to:
  /// **'Delete this wallet'**
  String get fpWalletDeleteLabel;

  /// No description provided for @fpWalletDeleteConsequence.
  ///
  /// In en, this message translates to:
  /// **'See what is attached first | saved money stays, just unlinked from the wallet'**
  String get fpWalletDeleteConsequence;

  /// No description provided for @fpWalletDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this wallet?'**
  String get fpWalletDeleteTitle;

  /// No description provided for @fpWalletDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'{transactions} transactions stay with no wallet ({transfers} transfers) | {system} opening / adjustment rows are deleted | {recurring} recurring settings keep running | {savings} saving entries ({amount}) stay, unlinked from the wallet'**
  String fpWalletDeleteBody(
    int transactions,
    int transfers,
    int system,
    int recurring,
    int savings,
    String amount,
  );

  /// No description provided for @fpWalletDeleted.
  ///
  /// In en, this message translates to:
  /// **'Wallet deleted'**
  String get fpWalletDeleted;

  /// No description provided for @fpContactsNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked to an app user'**
  String get fpContactsNotLinked;

  /// No description provided for @fpContactsLinkedWith.
  ///
  /// In en, this message translates to:
  /// **'Linked with {user}'**
  String fpContactsLinkedWith(String user);

  /// No description provided for @fpContactsSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'The name used for this person across the app'**
  String get fpContactsSettingsDesc;

  /// No description provided for @fpContactsLinkSection.
  ///
  /// In en, this message translates to:
  /// **'App account'**
  String get fpContactsLinkSection;

  /// No description provided for @fpContactsLinkSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'Tie this person to the account they use in the app (their name, email and icon), and merge names typed in splits'**
  String get fpContactsLinkSectionDesc;

  /// No description provided for @contactLinkedAccount.
  ///
  /// In en, this message translates to:
  /// **'Linked to {name}\'s account'**
  String contactLinkedAccount(String name);

  /// No description provided for @fpContactsArchiveConsequence.
  ///
  /// In en, this message translates to:
  /// **'Hidden from the list and person pickers; debts unchanged'**
  String get fpContactsArchiveConsequence;

  /// No description provided for @fpContactsDeleteConsequence.
  ///
  /// In en, this message translates to:
  /// **'Old records keep just the name; amounts unchanged'**
  String get fpContactsDeleteConsequence;

  /// No description provided for @fpDebtsTotalCaption.
  ///
  /// In en, this message translates to:
  /// **'Total outstanding'**
  String get fpDebtsTotalCaption;

  /// No description provided for @fpDebtsOwedToMeTile.
  ///
  /// In en, this message translates to:
  /// **'Owe me | {count} people'**
  String fpDebtsOwedToMeTile(int count);

  /// No description provided for @fpDebtsIOweTile.
  ///
  /// In en, this message translates to:
  /// **'I owe | {count} people'**
  String fpDebtsIOweTile(int count);

  /// No description provided for @fpDebtsOver30.
  ///
  /// In en, this message translates to:
  /// **'Over 30 days: {count} people'**
  String fpDebtsOver30(int count);

  /// No description provided for @fpDebtsDaysOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding {count} days'**
  String fpDebtsDaysOutstanding(int count);

  /// No description provided for @fpDebtsIncludeCleared.
  ///
  /// In en, this message translates to:
  /// **'Show cleared'**
  String get fpDebtsIncludeCleared;

  /// No description provided for @fpDebtsSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Longest owed'**
  String get fpDebtsSortOldest;

  /// No description provided for @fpDebtsSortAmount.
  ///
  /// In en, this message translates to:
  /// **'Largest'**
  String get fpDebtsSortAmount;

  /// No description provided for @fpDebtsSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get fpDebtsSortRecent;

  /// No description provided for @fpDebtsMessageLabel.
  ///
  /// In en, this message translates to:
  /// **'Summary message | editable before sending'**
  String get fpDebtsMessageLabel;

  /// No description provided for @fpDebtsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get fpDebtsCopy;

  /// No description provided for @fpDebtsShare.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get fpDebtsShare;

  /// No description provided for @fpDebtsCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get fpDebtsCopied;

  /// No description provided for @fpDebtsCycleHeader.
  ///
  /// In en, this message translates to:
  /// **'Where the balance comes from'**
  String get fpDebtsCycleHeader;

  /// No description provided for @fpDebtsCycleHeaderSince.
  ///
  /// In en, this message translates to:
  /// **'Where the balance comes from | since cleared {date}'**
  String fpDebtsCycleHeaderSince(String date);

  /// No description provided for @fpDebtsEarlierHeader.
  ///
  /// In en, this message translates to:
  /// **'Earlier cycle | cleared'**
  String get fpDebtsEarlierHeader;

  /// No description provided for @fpDebtsEarlierLink.
  ///
  /// In en, this message translates to:
  /// **'Earlier cycles'**
  String get fpDebtsEarlierLink;

  /// No description provided for @fpBudgetsLeftLabel.
  ///
  /// In en, this message translates to:
  /// **'Still available'**
  String get fpBudgetsLeftLabel;

  /// No description provided for @fpBudgetsOverLabel.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get fpBudgetsOverLabel;

  /// No description provided for @fpBudgetsTileDaily.
  ///
  /// In en, this message translates to:
  /// **'Can spend per day'**
  String get fpBudgetsTileDaily;

  /// No description provided for @fpBudgetsWarnAt.
  ///
  /// In en, this message translates to:
  /// **'Warn at'**
  String get fpBudgetsWarnAt;

  /// No description provided for @fpBudgetsTabItems.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get fpBudgetsTabItems;

  /// No description provided for @fpBudgetsTabPeriods.
  ///
  /// In en, this message translates to:
  /// **'All periods'**
  String get fpBudgetsTabPeriods;

  /// No description provided for @fpBudgetsLimitLabel.
  ///
  /// In en, this message translates to:
  /// **'Budget limit'**
  String get fpBudgetsLimitLabel;

  /// No description provided for @fpBudgetsPeriodReset.
  ///
  /// In en, this message translates to:
  /// **'Back to the base amount ({amount})'**
  String fpBudgetsPeriodReset(String amount);

  /// No description provided for @fpBudgetsCloseConsequence.
  ///
  /// In en, this message translates to:
  /// **'Ends this budget, no new periods, old ones stay visible'**
  String get fpBudgetsCloseConsequence;

  /// No description provided for @fpBudgetsArchiveConsequence.
  ///
  /// In en, this message translates to:
  /// **'Hidden, not counted in totals, restorable'**
  String get fpBudgetsArchiveConsequence;

  /// No description provided for @fpBudgetsRestoreConsequence.
  ///
  /// In en, this message translates to:
  /// **'Back in the list and counted again'**
  String get fpBudgetsRestoreConsequence;

  /// No description provided for @fpBudgetsDeleteConsequence.
  ///
  /// In en, this message translates to:
  /// **'Deleted for good, every period'**
  String get fpBudgetsDeleteConsequence;

  /// No description provided for @fpGoalsStatusChip.
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String fpGoalsStatusChip(String status);

  /// No description provided for @fpGoalsRowShort.
  ///
  /// In en, this message translates to:
  /// **'Short {amount}'**
  String fpGoalsRowShort(String amount);

  /// No description provided for @fpGoalsEtaOn.
  ///
  /// In en, this message translates to:
  /// **'Goal {date}'**
  String fpGoalsEtaOn(String date);

  /// No description provided for @fpGoalsEtaBehind.
  ///
  /// In en, this message translates to:
  /// **'Goal {date} | {n} months late'**
  String fpGoalsEtaBehind(String date, int n);

  /// No description provided for @fpGoalsDueBy.
  ///
  /// In en, this message translates to:
  /// **'By {date}'**
  String fpGoalsDueBy(String date);

  /// No description provided for @fpGoalsBehind.
  ///
  /// In en, this message translates to:
  /// **'Behind plan'**
  String get fpGoalsBehind;

  /// No description provided for @fpGoalsReached.
  ///
  /// In en, this message translates to:
  /// **'Reached'**
  String get fpGoalsReached;

  /// No description provided for @fpGoalsClosed.
  ///
  /// In en, this message translates to:
  /// **'Closed'**
  String get fpGoalsClosed;

  /// No description provided for @fpGoalsSavedLabel.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get fpGoalsSavedLabel;

  /// No description provided for @fpGoalsDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'{count} days left'**
  String fpGoalsDaysLeft(int count);

  /// No description provided for @fpGoalsTileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved this month'**
  String get fpGoalsTileSaved;

  /// No description provided for @fpGoalsActionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get fpGoalsActionSave;

  /// No description provided for @fpGoalsActionRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get fpGoalsActionRestore;

  /// No description provided for @fpGoalsSettingsDesc.
  ///
  /// In en, this message translates to:
  /// **'Save automatically'**
  String get fpGoalsSettingsDesc;

  /// No description provided for @fpGoalsAutoCaption.
  ///
  /// In en, this message translates to:
  /// **'{day} | {amount} from {wallet}'**
  String fpGoalsAutoCaption(String day, String amount, String wallet);

  /// No description provided for @fpGoalsAutoOffHint.
  ///
  /// In en, this message translates to:
  /// **'Turn on to get a saving to confirm every month'**
  String get fpGoalsAutoOffHint;

  /// No description provided for @fpGoalsAutoEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit amount, day and wallet'**
  String get fpGoalsAutoEdit;

  /// No description provided for @fpGoalsAutoSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-saving'**
  String get fpGoalsAutoSheetTitle;

  /// No description provided for @fpGoalsAutoDay.
  ///
  /// In en, this message translates to:
  /// **'Day of the month'**
  String get fpGoalsAutoDay;

  /// No description provided for @fpGoalsAutoFrom.
  ///
  /// In en, this message translates to:
  /// **'Take from'**
  String get fpGoalsAutoFrom;

  /// No description provided for @fpGoalsNoWallet.
  ///
  /// In en, this message translates to:
  /// **'Unspecified wallet'**
  String get fpGoalsNoWallet;

  /// No description provided for @fpGoalsChartActual.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get fpGoalsChartActual;

  /// No description provided for @fpGoalsAutoTag.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get fpGoalsAutoTag;

  /// No description provided for @fpGoalsCloseConsequence.
  ///
  /// In en, this message translates to:
  /// **'Move the money to “Not allocated” or back to its wallets'**
  String get fpGoalsCloseConsequence;

  /// No description provided for @fpGoalsArchiveConsequence.
  ///
  /// In en, this message translates to:
  /// **'Hidden, not counted, can be restored'**
  String get fpGoalsArchiveConsequence;

  /// No description provided for @fpGoalsArchiveNeedsClose.
  ///
  /// In en, this message translates to:
  /// **'Close the goal first'**
  String get fpGoalsArchiveNeedsClose;

  /// No description provided for @fpGoalsDeleteConsequence.
  ///
  /// In en, this message translates to:
  /// **'Deleted for good, with its saving history'**
  String get fpGoalsDeleteConsequence;

  /// No description provided for @fpGoalsArchiveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Hide this goal. It is not counted and can be restored later.'**
  String get fpGoalsArchiveConfirmBody;

  /// No description provided for @fpGoalsDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Delete this goal for good, with its saving history.'**
  String get fpGoalsDeleteConfirmBody;

  /// No description provided for @fpGoalsGroupOngoing.
  ///
  /// In en, this message translates to:
  /// **'Ongoing'**
  String get fpGoalsGroupOngoing;

  /// No description provided for @fpGoalsTileAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto-saving'**
  String get fpGoalsTileAuto;

  /// No description provided for @fpGoalsPerMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount}/mo'**
  String fpGoalsPerMonth(String amount);

  /// No description provided for @fpGoalsRingShortLabel.
  ///
  /// In en, this message translates to:
  /// **'Still short'**
  String get fpGoalsRingShortLabel;

  /// No description provided for @fpGoalsRingOfPlan.
  ///
  /// In en, this message translates to:
  /// **'Goal {amount}'**
  String fpGoalsRingOfPlan(String amount);

  /// No description provided for @fpGoalsRingOf.
  ///
  /// In en, this message translates to:
  /// **'of {target} | {pct}%'**
  String fpGoalsRingOf(String target, int pct);

  /// No description provided for @fpGoalsFactTotal.
  ///
  /// In en, this message translates to:
  /// **'Total saved'**
  String get fpGoalsFactTotal;

  /// No description provided for @fpGoalsFactGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get fpGoalsFactGoals;

  /// No description provided for @fpGoalsFactTarget.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get fpGoalsFactTarget;

  /// No description provided for @fpGoalsFactStillShort.
  ///
  /// In en, this message translates to:
  /// **'Short this month'**
  String get fpGoalsFactStillShort;

  /// No description provided for @fpGoalsFactShouldHave.
  ///
  /// In en, this message translates to:
  /// **'Should have by now'**
  String get fpGoalsFactShouldHave;

  /// No description provided for @fpGoalsFactLeft.
  ///
  /// In en, this message translates to:
  /// **'Left to go'**
  String get fpGoalsFactLeft;

  /// No description provided for @fpGoalsFactReachedOn.
  ///
  /// In en, this message translates to:
  /// **'Reached on'**
  String get fpGoalsFactReachedOn;

  /// No description provided for @fpGoalsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get fpGoalsFilterAll;

  /// No description provided for @fpGoalsFilterShort.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get fpGoalsFilterShort;

  /// No description provided for @fpGoalsFilterFree.
  ///
  /// In en, this message translates to:
  /// **'No deadline'**
  String get fpGoalsFilterFree;

  /// No description provided for @fpGoalsSortNeed.
  ///
  /// In en, this message translates to:
  /// **'Needs saving first'**
  String get fpGoalsSortNeed;

  /// No description provided for @fpGoalsRowDone.
  ///
  /// In en, this message translates to:
  /// **'Done ✓'**
  String get fpGoalsRowDone;

  /// No description provided for @fpGoalsRowLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String fpGoalsRowLeft(String amount);

  /// No description provided for @fpGoalsRowMonth.
  ///
  /// In en, this message translates to:
  /// **'{month} {saved} / {plan}'**
  String fpGoalsRowMonth(String month, String saved, String plan);

  /// No description provided for @fpGoalsRowMonthOnly.
  ///
  /// In en, this message translates to:
  /// **'{month} {amount}'**
  String fpGoalsRowMonthOnly(String month, String amount);

  /// No description provided for @fpGoalsThisMonth.
  ///
  /// In en, this message translates to:
  /// **'This month'**
  String get fpGoalsThisMonth;

  /// No description provided for @fpGoalsPlanTitleNow.
  ///
  /// In en, this message translates to:
  /// **'This month’s saving plan'**
  String get fpGoalsPlanTitleNow;

  /// No description provided for @fpGoalsPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Saving plan'**
  String get fpGoalsPlanTitle;

  /// No description provided for @fpGoalsMarkerBubble.
  ///
  /// In en, this message translates to:
  /// **'Should have {amount} by now'**
  String fpGoalsMarkerBubble(String amount);

  /// No description provided for @fpGoalsChipShort.
  ///
  /// In en, this message translates to:
  /// **'Short {amount} this month'**
  String fpGoalsChipShort(String amount);

  /// No description provided for @fpGoalsChipLate.
  ///
  /// In en, this message translates to:
  /// **'{n} months behind schedule'**
  String fpGoalsChipLate(int n);

  /// No description provided for @fpGoalsArchiveConsequenceMoney.
  ///
  /// In en, this message translates to:
  /// **'Hidden | {amount} not counted in savings | can be restored'**
  String fpGoalsArchiveConsequenceMoney(String amount);

  /// No description provided for @fpGoalsArchiveConfirmBodyMoney.
  ///
  /// In en, this message translates to:
  /// **'Hide this goal. The {amount} saved in it won’t count in your savings. You can restore it later.'**
  String fpGoalsArchiveConfirmBodyMoney(String amount);

  /// No description provided for @savingGoalFormTargetOptionalHint.
  ///
  /// In en, this message translates to:
  /// **'Leave empty for an ongoing goal with no target'**
  String get savingGoalFormTargetOptionalHint;

  /// No description provided for @sgPlanSection.
  ///
  /// In en, this message translates to:
  /// **'Saving plan'**
  String get sgPlanSection;

  /// No description provided for @sgPlanSectionDesc.
  ///
  /// In en, this message translates to:
  /// **'When it\'s due, what it starts with, and saving on its own'**
  String get sgPlanSectionDesc;

  /// No description provided for @sgOpeningLabel.
  ///
  /// In en, this message translates to:
  /// **'Starting amount'**
  String get sgOpeningLabel;

  /// No description provided for @sgOpeningHelp.
  ///
  /// In en, this message translates to:
  /// **'Money you already have, saved as the first entry'**
  String get sgOpeningHelp;

  /// No description provided for @sgAutoOnCaption.
  ///
  /// In en, this message translates to:
  /// **'Each one has its own wallet, amount and round'**
  String get sgAutoOnCaption;

  /// No description provided for @sgAutoOffCaption.
  ///
  /// In en, this message translates to:
  /// **'Turn on to get savings to confirm on a schedule'**
  String get sgAutoOffCaption;

  /// No description provided for @sgAutoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a saving'**
  String get sgAutoAdd;

  /// No description provided for @sgAutoFirst.
  ///
  /// In en, this message translates to:
  /// **'First {date}'**
  String sgAutoFirst(String date);

  /// No description provided for @sgAutoNext.
  ///
  /// In en, this message translates to:
  /// **'Next {date}'**
  String sgAutoNext(String date);

  /// No description provided for @sgAutoAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter more than 0'**
  String get sgAutoAmountInvalid;

  /// No description provided for @sgCreatedPartly.
  ///
  /// In en, this message translates to:
  /// **'The goal was created, but part of it didn\'t save: {error}'**
  String sgCreatedPartly(String error);

  /// No description provided for @fpGoalsRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed, showing the latest data'**
  String get fpGoalsRefreshFailed;

  /// No description provided for @fpEventsHeroNet.
  ///
  /// In en, this message translates to:
  /// **'Net owed | {count} events'**
  String fpEventsHeroNet(int count);

  /// No description provided for @fpEventsOwedFact.
  ///
  /// In en, this message translates to:
  /// **'Gets back | {count} events'**
  String fpEventsOwedFact(int count);

  /// No description provided for @fpEventsOweFact.
  ///
  /// In en, this message translates to:
  /// **'To pay | {count} events'**
  String fpEventsOweFact(int count);

  /// No description provided for @fpEventsShareFact.
  ///
  /// In en, this message translates to:
  /// **'My share | {count} active'**
  String fpEventsShareFact(int count);

  /// No description provided for @fpEventsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get fpEventsFilterAll;

  /// No description provided for @fpEventsOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Over budget'**
  String get fpEventsOverBudget;

  /// No description provided for @fpEventsTileActive.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get fpEventsTileActive;

  /// No description provided for @fpEventsTileUnsettled.
  ///
  /// In en, this message translates to:
  /// **'Not settled'**
  String get fpEventsTileUnsettled;

  /// No description provided for @fpEventsTileEnded.
  ///
  /// In en, this message translates to:
  /// **'Ended'**
  String get fpEventsTileEnded;

  /// No description provided for @fpEventsSortRecent.
  ///
  /// In en, this message translates to:
  /// **'Latest first'**
  String get fpEventsSortRecent;

  /// No description provided for @fpEventsSortOldest.
  ///
  /// In en, this message translates to:
  /// **'Oldest first'**
  String get fpEventsSortOldest;

  /// No description provided for @fpEventsSortAmount.
  ///
  /// In en, this message translates to:
  /// **'Biggest first'**
  String get fpEventsSortAmount;

  /// No description provided for @fpEventsCreate.
  ///
  /// In en, this message translates to:
  /// **'Create event'**
  String get fpEventsCreate;

  /// No description provided for @fpEventsRowShare.
  ///
  /// In en, this message translates to:
  /// **'My share {amount}'**
  String fpEventsRowShare(String amount);

  /// No description provided for @fpEventsOwed.
  ///
  /// In en, this message translates to:
  /// **'Gets back'**
  String get fpEventsOwed;

  /// No description provided for @fpEventsOwe.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get fpEventsOwe;

  /// No description provided for @fpEventsSpentTotal.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get fpEventsSpentTotal;

  /// No description provided for @fpEventsBudgetUsed.
  ///
  /// In en, this message translates to:
  /// **'Spent {spent} of {planned} budget'**
  String fpEventsBudgetUsed(String spent, String planned);

  /// No description provided for @fpEventsBudgetLeft.
  ///
  /// In en, this message translates to:
  /// **'{amount} left'**
  String fpEventsBudgetLeft(String amount);

  /// No description provided for @fpEventsBudgetOver.
  ///
  /// In en, this message translates to:
  /// **'Over by {amount}'**
  String fpEventsBudgetOver(String amount);

  /// No description provided for @fpEventsMyShare.
  ///
  /// In en, this message translates to:
  /// **'My share'**
  String get fpEventsMyShare;

  /// No description provided for @fpEventsIncomeTotal.
  ///
  /// In en, this message translates to:
  /// **'Total income'**
  String get fpEventsIncomeTotal;

  /// No description provided for @fpEventsMyTags.
  ///
  /// In en, this message translates to:
  /// **'My tags'**
  String get fpEventsMyTags;

  /// No description provided for @fpEventsTagPick.
  ///
  /// In en, this message translates to:
  /// **'Pick'**
  String get fpEventsTagPick;

  /// No description provided for @fpEventsMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members | who paid / who owes'**
  String get fpEventsMembersTitle;

  /// No description provided for @fpEventsManage.
  ///
  /// In en, this message translates to:
  /// **'Manage ›'**
  String get fpEventsManage;

  /// No description provided for @fpEventsMemberPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid {amount}'**
  String fpEventsMemberPaid(String amount);

  /// No description provided for @fpEventsMemberOwed.
  ///
  /// In en, this message translates to:
  /// **'Gets back {amount}'**
  String fpEventsMemberOwed(String amount);

  /// No description provided for @fpEventsMemberOwe.
  ///
  /// In en, this message translates to:
  /// **'Owes {amount}'**
  String fpEventsMemberOwe(String amount);

  /// No description provided for @fpEventsInvite.
  ///
  /// In en, this message translates to:
  /// **'Invite'**
  String get fpEventsInvite;

  /// No description provided for @fpEventsBillsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search bills in this event'**
  String get fpEventsBillsSearchHint;

  /// No description provided for @fpEventsPayerFilter.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get fpEventsPayerFilter;

  /// No description provided for @fpEventsPayerAll.
  ///
  /// In en, this message translates to:
  /// **'Everyone'**
  String get fpEventsPayerAll;

  /// No description provided for @fpEventsTagsFilterLabel.
  ///
  /// In en, this message translates to:
  /// **'Event tags'**
  String get fpEventsTagsFilterLabel;

  /// No description provided for @fpEventsTagAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get fpEventsTagAll;

  /// No description provided for @fpEventsSplitCount.
  ///
  /// In en, this message translates to:
  /// **'Split {count}'**
  String fpEventsSplitCount(int count);

  /// No description provided for @fpEventsPaidBy.
  ///
  /// In en, this message translates to:
  /// **'{name} paid'**
  String fpEventsPaidBy(String name);

  /// No description provided for @fpEventsBudgetLabel.
  ///
  /// In en, this message translates to:
  /// **'Planned budget (optional)'**
  String get fpEventsBudgetLabel;

  /// No description provided for @fpEventsBudgetHelper.
  ///
  /// In en, this message translates to:
  /// **'What you intend to spend | clear to hide the plan'**
  String get fpEventsBudgetHelper;

  /// No description provided for @fpEventsDatesLabel.
  ///
  /// In en, this message translates to:
  /// **'Start – end'**
  String get fpEventsDatesLabel;

  /// No description provided for @fpEventsManageTags.
  ///
  /// In en, this message translates to:
  /// **'Manage event tags'**
  String get fpEventsManageTags;

  /// No description provided for @fpEventsTagsCount.
  ///
  /// In en, this message translates to:
  /// **'{count} tags'**
  String fpEventsTagsCount(int count);

  /// No description provided for @fpEventsArchiveConsequence.
  ///
  /// In en, this message translates to:
  /// **'Hidden, not counted, can be restored'**
  String get fpEventsArchiveConsequence;

  /// No description provided for @fpEventsDeleteConsequence.
  ///
  /// In en, this message translates to:
  /// **'You choose whether its bills go too'**
  String get fpEventsDeleteConsequence;

  /// No description provided for @fpEventsRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore event'**
  String get fpEventsRestore;

  /// No description provided for @fpEventsRestoreConsequence.
  ///
  /// In en, this message translates to:
  /// **'Back to in progress'**
  String get fpEventsRestoreConsequence;

  /// No description provided for @fpEventsArchived.
  ///
  /// In en, this message translates to:
  /// **'Event archived'**
  String get fpEventsArchived;

  /// No description provided for @fpEventsRestored.
  ///
  /// In en, this message translates to:
  /// **'Event restored'**
  String get fpEventsRestored;

  /// No description provided for @fpEventsArchiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this event?'**
  String get fpEventsArchiveConfirmTitle;

  /// No description provided for @fpEventsArchiveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Hidden, not counted and read-only. You can restore it any time.'**
  String get fpEventsArchiveConfirmBody;

  /// No description provided for @fpEventsTagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Event tags | shared with members'**
  String get fpEventsTagsTitle;

  /// No description provided for @fpEventsTagAdd.
  ///
  /// In en, this message translates to:
  /// **'Add event tag'**
  String get fpEventsTagAdd;

  /// No description provided for @fpEventsTagsImportAll.
  ///
  /// In en, this message translates to:
  /// **'Import all to my tags'**
  String get fpEventsTagsImportAll;

  /// No description provided for @fpEventsTagRename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get fpEventsTagRename;

  /// No description provided for @fpEventsTagRestyle.
  ///
  /// In en, this message translates to:
  /// **'Change icon / colour'**
  String get fpEventsTagRestyle;

  /// No description provided for @fpEventsTagImportOne.
  ///
  /// In en, this message translates to:
  /// **'Import to my tags'**
  String get fpEventsTagImportOne;

  /// No description provided for @fpEventsTagNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get fpEventsTagNameLabel;

  /// No description provided for @fpEventsTagNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a tag name'**
  String get fpEventsTagNameRequired;

  /// No description provided for @fpEventsTagNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New event tag'**
  String get fpEventsTagNewTitle;

  /// No description provided for @fpEventsTagRenameTitle.
  ///
  /// In en, this message translates to:
  /// **'Rename tag'**
  String get fpEventsTagRenameTitle;

  /// No description provided for @fpEventsTagIconTitle.
  ///
  /// In en, this message translates to:
  /// **'Tag icon'**
  String get fpEventsTagIconTitle;

  /// No description provided for @fpEventsTagDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete tag {name}?'**
  String fpEventsTagDeleteTitle(String name);

  /// No description provided for @fpEventsTagDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Bills using it lose the tag.'**
  String get fpEventsTagDeleteBody;

  /// No description provided for @fpEventsTagsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No event tags yet'**
  String get fpEventsTagsEmpty;

  /// No description provided for @fpEventsTagBills.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 bill} other{{count} bills}}'**
  String fpEventsTagBills(int count);

  /// No description provided for @fpEventsTagInMine.
  ///
  /// In en, this message translates to:
  /// **'In my tags already'**
  String get fpEventsTagInMine;

  /// No description provided for @fpEventsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t refresh | showing the last data'**
  String get fpEventsLoadFailed;

  /// No description provided for @evbNewBill.
  ///
  /// In en, this message translates to:
  /// **'Add bill'**
  String get evbNewBill;

  /// No description provided for @evbEditBill.
  ///
  /// In en, this message translates to:
  /// **'Edit bill'**
  String get evbEditBill;

  /// No description provided for @evbNewPayback.
  ///
  /// In en, this message translates to:
  /// **'Payback'**
  String get evbNewPayback;

  /// No description provided for @evbEditPayback.
  ///
  /// In en, this message translates to:
  /// **'Edit payback'**
  String get evbEditPayback;

  /// No description provided for @evbTypePayback.
  ///
  /// In en, this message translates to:
  /// **'Payback'**
  String get evbTypePayback;

  /// No description provided for @evbPeople.
  ///
  /// In en, this message translates to:
  /// **'In the bill | {count}'**
  String evbPeople(int count);

  /// No description provided for @evbPays.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get evbPays;

  /// No description provided for @evbPaidBack.
  ///
  /// In en, this message translates to:
  /// **'Paid back'**
  String get evbPaidBack;

  /// No description provided for @evbMembersSection.
  ///
  /// In en, this message translates to:
  /// **'In this event'**
  String get evbMembersSection;

  /// No description provided for @evbAddPeopleConfirm.
  ///
  /// In en, this message translates to:
  /// **'Add {count}'**
  String evbAddPeopleConfirm(int count);

  /// No description provided for @evbMyBooks.
  ///
  /// In en, this message translates to:
  /// **'Add to my books'**
  String get evbMyBooks;

  /// No description provided for @evbBooked.
  ///
  /// In en, this message translates to:
  /// **'In my books'**
  String get evbBooked;

  /// No description provided for @evbBookDebt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get evbBookDebt;

  /// No description provided for @evbBookDebtLine.
  ///
  /// In en, this message translates to:
  /// **'I owe {name}'**
  String evbBookDebtLine(String name);

  /// No description provided for @evbBookTx.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get evbBookTx;

  /// No description provided for @evbBookTxLine.
  ///
  /// In en, this message translates to:
  /// **'My share as an expense'**
  String get evbBookTxLine;

  /// No description provided for @evbNotBooked.
  ///
  /// In en, this message translates to:
  /// **'Not in my books'**
  String get evbNotBooked;

  /// No description provided for @evbOwesHint.
  ///
  /// In en, this message translates to:
  /// **'{from} owes {to} {amount}'**
  String evbOwesHint(String from, String to, String amount);

  /// No description provided for @evbUseAmount.
  ///
  /// In en, this message translates to:
  /// **'Use this'**
  String get evbUseAmount;

  /// No description provided for @evbPaybackBy.
  ///
  /// In en, this message translates to:
  /// **'Payback | by {name}'**
  String evbPaybackBy(String name);

  /// No description provided for @evbPaidFrom.
  ///
  /// In en, this message translates to:
  /// **'Paid from {wallet}'**
  String evbPaidFrom(String wallet);

  /// No description provided for @evbBackFrom.
  ///
  /// In en, this message translates to:
  /// **'Back from {name}'**
  String evbBackFrom(String name);

  /// No description provided for @evbNoWallet.
  ///
  /// In en, this message translates to:
  /// **'No wallet'**
  String get evbNoWallet;

  /// No description provided for @evbTabBills.
  ///
  /// In en, this message translates to:
  /// **'Bills'**
  String get evbTabBills;

  /// No description provided for @evbTabSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get evbTabSummary;

  /// No description provided for @evbNets.
  ///
  /// In en, this message translates to:
  /// **'Each person'**
  String get evbNets;

  /// No description provided for @evbSettleTitle.
  ///
  /// In en, this message translates to:
  /// **'Who pays whom'**
  String get evbSettleTitle;

  /// No description provided for @evbSettlePairs.
  ///
  /// In en, this message translates to:
  /// **'Pair by pair'**
  String get evbSettlePairs;

  /// No description provided for @evbSettleFewest.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get evbSettleFewest;

  /// No description provided for @evbSettlePaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get evbSettlePaid;

  /// No description provided for @evbSettleHint.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Paid\" to record the payback in the event; anyone can'**
  String get evbSettleHint;

  /// No description provided for @evbAllSettled.
  ///
  /// In en, this message translates to:
  /// **'Everyone is even'**
  String get evbAllSettled;

  /// No description provided for @evbOnlyMine.
  ///
  /// In en, this message translates to:
  /// **'Only mine'**
  String get evbOnlyMine;

  /// No description provided for @evbDebtorsLine.
  ///
  /// In en, this message translates to:
  /// **'{count} owe me'**
  String evbDebtorsLine(int count);

  /// No description provided for @evbNoDebt.
  ///
  /// In en, this message translates to:
  /// **'No debt'**
  String get evbNoDebt;

  /// No description provided for @evbRecordDebt.
  ///
  /// In en, this message translates to:
  /// **'Record the debt'**
  String get evbRecordDebt;

  /// No description provided for @evbIPaid.
  ///
  /// In en, this message translates to:
  /// **'I paid'**
  String get evbIPaid;

  /// No description provided for @evbBackReceived.
  ///
  /// In en, this message translates to:
  /// **'Got back'**
  String get evbBackReceived;

  /// No description provided for @evbBackSent.
  ///
  /// In en, this message translates to:
  /// **'Paid back'**
  String get evbBackSent;

  /// No description provided for @evbTheyOweMe.
  ///
  /// In en, this message translates to:
  /// **'{name} owes me'**
  String evbTheyOweMe(String name);

  /// No description provided for @evbDebtUp.
  ///
  /// In en, this message translates to:
  /// **'Debt up'**
  String get evbDebtUp;

  /// No description provided for @evbDebtDown.
  ///
  /// In en, this message translates to:
  /// **'Debt down'**
  String get evbDebtDown;

  /// No description provided for @categoryDeleteConsequence.
  ///
  /// In en, this message translates to:
  /// **'Deleted for good | its transactions will have no category'**
  String get categoryDeleteConsequence;

  /// No description provided for @categoryMonthSpentLabel.
  ///
  /// In en, this message translates to:
  /// **'{month} spent | {count} transactions ›'**
  String categoryMonthSpentLabel(String month, int count);

  /// No description provided for @categoryMonthEarnedLabel.
  ///
  /// In en, this message translates to:
  /// **'{month} received | {count} transactions ›'**
  String categoryMonthEarnedLabel(String month, int count);

  /// No description provided for @notifSettingsLegend.
  ///
  /// In en, this message translates to:
  /// **'Off: no notice | Notify: a notice with a one-tap button | Auto: done for you, then you are told what was done'**
  String get notifSettingsLegend;

  /// No description provided for @notifStateOff.
  ///
  /// In en, this message translates to:
  /// **'Off'**
  String get notifStateOff;

  /// No description provided for @notifStateNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get notifStateNotify;

  /// No description provided for @notifStateAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get notifStateAuto;

  /// No description provided for @notifGroupRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get notifGroupRecurring;

  /// No description provided for @notifTypeRecurringDue.
  ///
  /// In en, this message translates to:
  /// **'Recurring items are due'**
  String get notifTypeRecurringDue;

  /// No description provided for @notifTypeRecurringDueHint.
  ///
  /// In en, this message translates to:
  /// **'Always listed under To do on the recurring page | Off = no notice'**
  String get notifTypeRecurringDueHint;

  /// No description provided for @notifTypeRecurringEnding.
  ///
  /// In en, this message translates to:
  /// **'A recurring is about to end'**
  String get notifTypeRecurringEnding;

  /// No description provided for @notifTypeRecurringEndingHint.
  ///
  /// In en, this message translates to:
  /// **'A few items left | extend it?'**
  String get notifTypeRecurringEndingHint;

  /// No description provided for @notifTypeRecurringAutoCreated.
  ///
  /// In en, this message translates to:
  /// **'Recorded automatically'**
  String get notifTypeRecurringAutoCreated;

  /// No description provided for @notifTypeRecurringAutoCreatedHint.
  ///
  /// In en, this message translates to:
  /// **'Once a day, how many were recorded | Off = no notice'**
  String get notifTypeRecurringAutoCreatedHint;

  /// No description provided for @notifTypeRequestsHint.
  ///
  /// In en, this message translates to:
  /// **'Needs an answer, so it can\'t be turned off'**
  String get notifTypeRequestsHint;

  /// No description provided for @settingsSectionApp.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get settingsSectionApp;

  /// No description provided for @settingsSectionMoney.
  ///
  /// In en, this message translates to:
  /// **'Money'**
  String get settingsSectionMoney;

  /// No description provided for @settingsSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsSectionData;

  /// No description provided for @settingsCurrencyHint.
  ///
  /// In en, this message translates to:
  /// **'Changes the label only, amounts are not converted'**
  String get settingsCurrencyHint;

  /// No description provided for @settingsMainWallet.
  ///
  /// In en, this message translates to:
  /// **'Main wallet'**
  String get settingsMainWallet;

  /// No description provided for @settingsMoneyStyle.
  ///
  /// In en, this message translates to:
  /// **'Money format'**
  String get settingsMoneyStyle;

  /// No description provided for @settingsMoneySignPlusMinus.
  ///
  /// In en, this message translates to:
  /// **'+ / −'**
  String get settingsMoneySignPlusMinus;

  /// No description provided for @settingsMoneySignParentheses.
  ///
  /// In en, this message translates to:
  /// **'Parentheses ( )'**
  String get settingsMoneySignParentheses;

  /// No description provided for @settingsMoneySignNone.
  ///
  /// In en, this message translates to:
  /// **'Colour only'**
  String get settingsMoneySignNone;

  /// No description provided for @settingsMoneyColor.
  ///
  /// In en, this message translates to:
  /// **'Red / green colours'**
  String get settingsMoneyColor;

  /// No description provided for @settingsMoneyColorHint.
  ///
  /// In en, this message translates to:
  /// **'Income in green, expenses in red'**
  String get settingsMoneyColorHint;

  /// No description provided for @settingsMoneyDecimals.
  ///
  /// In en, this message translates to:
  /// **'Decimals'**
  String get settingsMoneyDecimals;

  /// No description provided for @settingsMoneyDecimalsAlways.
  ///
  /// In en, this message translates to:
  /// **'Always'**
  String get settingsMoneyDecimalsAlways;

  /// No description provided for @settingsMoneyDecimalsNever.
  ///
  /// In en, this message translates to:
  /// **'Never (rounded)'**
  String get settingsMoneyDecimalsNever;

  /// No description provided for @settingsMoneyDecimalsAuto.
  ///
  /// In en, this message translates to:
  /// **'Hide .00 only'**
  String get settingsMoneyDecimalsAuto;

  /// No description provided for @settingsMainWalletHint.
  ///
  /// In en, this message translates to:
  /// **'Used as the default when recording'**
  String get settingsMainWalletHint;

  /// No description provided for @settingsMainWalletNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get settingsMainWalletNone;

  /// No description provided for @settingsArchived.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get settingsArchived;

  /// No description provided for @settingsArchivedHint.
  ///
  /// In en, this message translates to:
  /// **'Wallets, budgets, goals, events, contacts'**
  String get settingsArchivedHint;

  /// No description provided for @settingsExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get settingsExportCsv;

  /// No description provided for @settingsComingIn04.
  ///
  /// In en, this message translates to:
  /// **'0.4'**
  String get settingsComingIn04;

  /// No description provided for @profileSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get profileSectionSecurity;

  /// No description provided for @settingsSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save, try again'**
  String get settingsSaveFailed;

  /// No description provided for @notifTileAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get notifTileAll;

  /// No description provided for @notifTileNeedsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Needs answer'**
  String get notifTileNeedsAnswer;

  /// No description provided for @notifTileUnread.
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notifTileUnread;

  /// No description provided for @notifTileHidden.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get notifTileHidden;

  /// No description provided for @notifCardCaption.
  ///
  /// In en, this message translates to:
  /// **'Needs answer'**
  String get notifCardCaption;

  /// No description provided for @notifCardMain.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{Nothing} other{{count} items}}'**
  String notifCardMain(int count);

  /// No description provided for @notifCardUnread.
  ///
  /// In en, this message translates to:
  /// **'| unread {count}'**
  String notifCardUnread(int count);

  /// No description provided for @notifReadAllTooltip.
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notifReadAllTooltip;

  /// No description provided for @notifSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Notification settings'**
  String get notifSettingsTooltip;

  /// No description provided for @notifRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get notifRestore;

  /// No description provided for @notifUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get notifUndo;

  /// No description provided for @notifEmptyNeedsAnswer.
  ///
  /// In en, this message translates to:
  /// **'Nothing waiting for an answer'**
  String get notifEmptyNeedsAnswer;

  /// No description provided for @notifEmptyHidden.
  ///
  /// In en, this message translates to:
  /// **'No hidden notifications'**
  String get notifEmptyHidden;

  /// No description provided for @notifActionExtend.
  ///
  /// In en, this message translates to:
  /// **'Extend'**
  String get notifActionExtend;

  /// No description provided for @notifActionLetEnd.
  ///
  /// In en, this message translates to:
  /// **'Let it end'**
  String get notifActionLetEnd;

  /// No description provided for @notifActionOpenDue.
  ///
  /// In en, this message translates to:
  /// **'Open ›'**
  String get notifActionOpenDue;

  /// No description provided for @archivedGroupWallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get archivedGroupWallets;

  /// No description provided for @archivedGroupBudgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get archivedGroupBudgets;

  /// No description provided for @archivedGroupGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get archivedGroupGoals;

  /// No description provided for @archivedGroupEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get archivedGroupEvents;

  /// No description provided for @archivedGroupContacts.
  ///
  /// In en, this message translates to:
  /// **'Contacts'**
  String get archivedGroupContacts;

  /// No description provided for @archivedGroupRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get archivedGroupRecurring;

  /// No description provided for @archivedOn.
  ///
  /// In en, this message translates to:
  /// **'Archived {date}'**
  String archivedOn(String date);

  /// No description provided for @archivedRestore.
  ///
  /// In en, this message translates to:
  /// **'Restore'**
  String get archivedRestore;

  /// No description provided for @archivedSecondaryBalance.
  ///
  /// In en, this message translates to:
  /// **'Left {amount}'**
  String archivedSecondaryBalance(String amount);

  /// No description provided for @archivedSecondaryLimit.
  ///
  /// In en, this message translates to:
  /// **'Limit {amount}'**
  String archivedSecondaryLimit(String amount);

  /// No description provided for @archivedSecondaryTarget.
  ///
  /// In en, this message translates to:
  /// **'Goal {amount}'**
  String archivedSecondaryTarget(String amount);

  /// No description provided for @archivedSecondaryPlanned.
  ///
  /// In en, this message translates to:
  /// **'Budget {amount}'**
  String archivedSecondaryPlanned(String amount);

  /// No description provided for @archivedSecondaryAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount {amount}'**
  String archivedSecondaryAmount(String amount);

  /// No description provided for @archivedRestored.
  ///
  /// In en, this message translates to:
  /// **'Restored {name}'**
  String archivedRestored(String name);

  /// No description provided for @archivedEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing archived'**
  String get archivedEmpty;

  /// No description provided for @archivedEmptyMessage.
  ///
  /// In en, this message translates to:
  /// **'Archived items show here. Restore them any time.'**
  String get archivedEmptyMessage;

  /// No description provided for @txRecurringPick.
  ///
  /// In en, this message translates to:
  /// **'Pick a recurring'**
  String get txRecurringPick;

  /// No description provided for @txRecurringUnlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get txRecurringUnlink;

  /// No description provided for @recurringPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Link to a recurring'**
  String get recurringPickerTitle;

  /// No description provided for @recurringPickerGroupLikely.
  ///
  /// In en, this message translates to:
  /// **'Likely'**
  String get recurringPickerGroupLikely;

  /// No description provided for @recurringPickerGroupRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurringPickerGroupRecurring;

  /// No description provided for @recurringPickerGroupReminders.
  ///
  /// In en, this message translates to:
  /// **'Payment reminders'**
  String get recurringPickerGroupReminders;

  /// No description provided for @recurringPickerAwaitingAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount pending'**
  String get recurringPickerAwaitingAmount;

  /// No description provided for @recurringPickerCreate.
  ///
  /// In en, this message translates to:
  /// **'Create a recurring from this transaction'**
  String get recurringPickerCreate;

  /// No description provided for @recurringPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No recurring to link to'**
  String get recurringPickerEmpty;

  /// No description provided for @recurringPickerPeriod.
  ///
  /// In en, this message translates to:
  /// **'Period {date}'**
  String recurringPickerPeriod(String date);

  /// No description provided for @recurringPickerStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'not yet due'**
  String get recurringPickerStatusUpcoming;

  /// No description provided for @recurringPickerStatusPending.
  ///
  /// In en, this message translates to:
  /// **'awaiting confirmation'**
  String get recurringPickerStatusPending;

  /// No description provided for @recurringPickerStatusNotCreated.
  ///
  /// In en, this message translates to:
  /// **'not paid yet'**
  String get recurringPickerStatusNotCreated;

  /// No description provided for @recurringPickerStatusReminder.
  ///
  /// In en, this message translates to:
  /// **'enter the amount'**
  String get recurringPickerStatusReminder;

  /// No description provided for @recurringLinkAskAmount.
  ///
  /// In en, this message translates to:
  /// **'The amount differs from the recurring ({rule} → {tx}). Update the recurring\'s amount too?'**
  String recurringLinkAskAmount(String rule, String tx);

  /// No description provided for @recurringLinkAskNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get recurringLinkAskNo;

  /// No description provided for @recurringLinkAskYes.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get recurringLinkAskYes;

  /// No description provided for @recurringLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked to the recurring'**
  String get recurringLinked;

  /// No description provided for @recurringLinkedAmountUpdated.
  ///
  /// In en, this message translates to:
  /// **'Recurring amount updated'**
  String get recurringLinkedAmountUpdated;

  /// No description provided for @recurringLinkAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'That period is already linked (or this transaction is linked already)'**
  String get recurringLinkAlreadyLinked;

  /// No description provided for @recurringPickerGroupNearest.
  ///
  /// In en, this message translates to:
  /// **'Nearest'**
  String get recurringPickerGroupNearest;

  /// No description provided for @recurringPickerGroupNext.
  ///
  /// In en, this message translates to:
  /// **'Coming'**
  String get recurringPickerGroupNext;

  /// No description provided for @recurringPickerGroupPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get recurringPickerGroupPast;

  /// No description provided for @recurringPickerOtherRule.
  ///
  /// In en, this message translates to:
  /// **'Pick another recurring'**
  String get recurringPickerOtherRule;

  /// No description provided for @recurringLinkSwapTitle.
  ///
  /// In en, this message translates to:
  /// **'Swap the linked transaction?'**
  String get recurringLinkSwapTitle;

  /// No description provided for @recurringLinkSwapBody.
  ///
  /// In en, this message translates to:
  /// **'This period is linked to {name}. Link this transaction instead? {name} stays, just unlinked.'**
  String recurringLinkSwapBody(String name);

  /// No description provided for @recurringLinkMoveBody.
  ///
  /// In en, this message translates to:
  /// **'This transaction is linked to another period. Move it here? That period goes back to due.'**
  String get recurringLinkMoveBody;

  /// No description provided for @recurringLinkSwapYes.
  ///
  /// In en, this message translates to:
  /// **'Swap'**
  String get recurringLinkSwapYes;

  /// No description provided for @fpRecurringTabCalendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get fpRecurringTabCalendar;

  /// No description provided for @fpRecurringPausedGroup.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get fpRecurringPausedGroup;

  /// No description provided for @fpRecurringAwaitingAmount.
  ///
  /// In en, this message translates to:
  /// **'No amount yet'**
  String get fpRecurringAwaitingAmount;

  /// No description provided for @fpRecurringKindSubscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get fpRecurringKindSubscription;

  /// No description provided for @fpRecurringKindInstallment.
  ///
  /// In en, this message translates to:
  /// **'Installment'**
  String get fpRecurringKindInstallment;

  /// No description provided for @fpRecurringKindIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get fpRecurringKindIncome;

  /// No description provided for @fpRecurringKindReminder.
  ///
  /// In en, this message translates to:
  /// **'Reminder'**
  String get fpRecurringKindReminder;

  /// No description provided for @fpRecurringRefreshFailed.
  ///
  /// In en, this message translates to:
  /// **'Refresh failed, showing the latest data'**
  String get fpRecurringRefreshFailed;

  /// No description provided for @fpRecurringAwaitingValue.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get fpRecurringAwaitingValue;

  /// No description provided for @fpRecurringTileYearly.
  ///
  /// In en, this message translates to:
  /// **'Per year'**
  String get fpRecurringTileYearly;

  /// No description provided for @fpRecurringTileSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get fpRecurringTileSaved;

  /// No description provided for @fpRecurringCountUnit.
  ///
  /// In en, this message translates to:
  /// **'{n} times'**
  String fpRecurringCountUnit(int n);

  /// No description provided for @fpRecurringTrialUntil.
  ///
  /// In en, this message translates to:
  /// **'Free trial until'**
  String get fpRecurringTrialUntil;

  /// No description provided for @fpRecurringTabPast.
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get fpRecurringTabPast;

  /// No description provided for @fpRecurringTabUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get fpRecurringTabUpcoming;

  /// No description provided for @fpRecurringEditedChip.
  ///
  /// In en, this message translates to:
  /// **'Edited'**
  String get fpRecurringEditedChip;

  /// No description provided for @fpRecurringActEditAmount.
  ///
  /// In en, this message translates to:
  /// **'Edit amount'**
  String get fpRecurringActEditAmount;

  /// No description provided for @fpRecurringActMove.
  ///
  /// In en, this message translates to:
  /// **'Move date'**
  String get fpRecurringActMove;

  /// No description provided for @fpRecurringActSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get fpRecurringActSkip;

  /// No description provided for @fpRecurringActEnterAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter amount'**
  String get fpRecurringActEnterAmount;

  /// No description provided for @fpRecurringOccEditTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit this occurrence'**
  String get fpRecurringOccEditTitle;

  /// No description provided for @fpRecurringOccMoveTitle.
  ///
  /// In en, this message translates to:
  /// **'Move this occurrence'**
  String get fpRecurringOccMoveTitle;

  /// No description provided for @fpRecurringOccEnterTitle.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount'**
  String get fpRecurringOccEnterTitle;

  /// No description provided for @fpRecurringOccDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get fpRecurringOccDate;

  /// No description provided for @fpRecurringOccAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get fpRecurringOccAmount;

  /// No description provided for @fpRecurringSkipTitle.
  ///
  /// In en, this message translates to:
  /// **'Skip this occurrence?'**
  String get fpRecurringSkipTitle;

  /// No description provided for @fpRecurringSkipBody.
  ///
  /// In en, this message translates to:
  /// **'It will not become a draft in pending. You can restore it later.'**
  String get fpRecurringSkipBody;

  /// No description provided for @fpRecurringAmountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount / time'**
  String get fpRecurringAmountLabel;

  /// No description provided for @fpRecurringAmountOptional.
  ///
  /// In en, this message translates to:
  /// **'Amount / time (optional)'**
  String get fpRecurringAmountOptional;

  /// No description provided for @fpRecurringReminderHint.
  ///
  /// In en, this message translates to:
  /// **'No amount needed. On the day, enter the real amount in the draft.'**
  String get fpRecurringReminderHint;

  /// No description provided for @fpRecurringFieldCount.
  ///
  /// In en, this message translates to:
  /// **'Number of payments'**
  String get fpRecurringFieldCount;

  /// No description provided for @fpRecurringCountValue.
  ///
  /// In en, this message translates to:
  /// **'{n} payments'**
  String fpRecurringCountValue(int n);

  /// No description provided for @fpRecurringCountRequired.
  ///
  /// In en, this message translates to:
  /// **'An installment needs a number of payments'**
  String get fpRecurringCountRequired;

  /// No description provided for @fpRecurringFieldMode.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fpRecurringFieldMode;

  /// No description provided for @fpRecurringFieldPayFrom.
  ///
  /// In en, this message translates to:
  /// **'Pay from'**
  String get fpRecurringFieldPayFrom;

  /// No description provided for @fpRecurringFieldIntoWallet.
  ///
  /// In en, this message translates to:
  /// **'Into wallet'**
  String get fpRecurringFieldIntoWallet;

  /// No description provided for @fpRecurringFieldFromWallet.
  ///
  /// In en, this message translates to:
  /// **'From wallet'**
  String get fpRecurringFieldFromWallet;

  /// No description provided for @fpRecurringArchiveConsequence.
  ///
  /// In en, this message translates to:
  /// **'Stops making new occurrences. Hidden, can be restored.'**
  String get fpRecurringArchiveConsequence;

  /// No description provided for @fpRecurringRestoreConsequence.
  ///
  /// In en, this message translates to:
  /// **'Active again, making occurrences'**
  String get fpRecurringRestoreConsequence;

  /// No description provided for @fpRecurringDeleteConsequence.
  ///
  /// In en, this message translates to:
  /// **'Deletes this recurring with its unsaved occurrences'**
  String get fpRecurringDeleteConsequence;

  /// No description provided for @fpRecurringDuplicate.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get fpRecurringDuplicate;

  /// No description provided for @fpRecurringDuplicateConsequence.
  ///
  /// In en, this message translates to:
  /// **'Creates the same recurring, starting today'**
  String get fpRecurringDuplicateConsequence;

  /// No description provided for @fpM5ContactDeleteDebts.
  ///
  /// In en, this message translates to:
  /// **'{n} debt records keep only the name'**
  String fpM5ContactDeleteDebts(int n);

  /// No description provided for @fpM5ContactDeleteMembers.
  ///
  /// In en, this message translates to:
  /// **'Member of {n} events'**
  String fpM5ContactDeleteMembers(int n);

  /// No description provided for @fpM5ContactDeleteLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked to an account, the link is removed'**
  String get fpM5ContactDeleteLinked;

  /// No description provided for @fpM5BudgetDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Deletes {periods} periods ({overridden} adjusted) | {categories} categories | {wallets} wallets. Transactions are not affected.'**
  String fpM5BudgetDeleteBody(
    int periods,
    int overridden,
    int categories,
    int wallets,
  );

  /// No description provided for @fpM5GoalDeleteBody.
  ///
  /// In en, this message translates to:
  /// **'Deletes this goal for good. {n} saving entries stay, detached from it.'**
  String fpM5GoalDeleteBody(int n);

  /// No description provided for @fpM5GoalsSortTooltip.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get fpM5GoalsSortTooltip;

  /// No description provided for @fpM5GoalsSortCreated.
  ///
  /// In en, this message translates to:
  /// **'By created'**
  String get fpM5GoalsSortCreated;

  /// No description provided for @fpM5GoalsSortDeadline.
  ///
  /// In en, this message translates to:
  /// **'Nearest deadline'**
  String get fpM5GoalsSortDeadline;

  /// No description provided for @fpM5GoalsSortProgress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get fpM5GoalsSortProgress;

  /// No description provided for @fpM5GoalsSortRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get fpM5GoalsSortRemaining;

  /// No description provided for @fpM5GoalsSortName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get fpM5GoalsSortName;

  /// No description provided for @fpM5GoalsChartPlan.
  ///
  /// In en, this message translates to:
  /// **'On plan'**
  String get fpM5GoalsChartPlan;

  /// No description provided for @fpRecurringSince.
  ///
  /// In en, this message translates to:
  /// **'Since {date}'**
  String fpRecurringSince(String date);

  /// No description provided for @fpRecurringNextOnce.
  ///
  /// In en, this message translates to:
  /// **'Next | {due}'**
  String fpRecurringNextOnce(String due);

  /// No description provided for @fpRecurringNextInstallment.
  ///
  /// In en, this message translates to:
  /// **'Next installment ({n}/{total}) | {due}'**
  String fpRecurringNextInstallment(int n, int total, String due);

  /// No description provided for @fpRecurringStatPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get fpRecurringStatPaid;

  /// No description provided for @fpRecurringStatRemaining.
  ///
  /// In en, this message translates to:
  /// **'Left'**
  String get fpRecurringStatRemaining;

  /// No description provided for @fpRecurringStatLast.
  ///
  /// In en, this message translates to:
  /// **'Last one'**
  String get fpRecurringStatLast;

  /// No description provided for @fpRecurringStatAvg.
  ///
  /// In en, this message translates to:
  /// **'Average'**
  String get fpRecurringStatAvg;

  /// No description provided for @fpRecurringStatPrev.
  ///
  /// In en, this message translates to:
  /// **'Last time'**
  String get fpRecurringStatPrev;

  /// No description provided for @fpRecurringStatMax.
  ///
  /// In en, this message translates to:
  /// **'Highest'**
  String get fpRecurringStatMax;

  /// No description provided for @fpRecurringAvgLine.
  ///
  /// In en, this message translates to:
  /// **'Avg {amount}'**
  String fpRecurringAvgLine(String amount);

  /// No description provided for @fpRecurringChainLabel.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total} paid'**
  String fpRecurringChainLabel(int done, int total);

  /// No description provided for @fpRecurringChartLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount each time'**
  String get fpRecurringChartLabel;

  /// No description provided for @fpRecurringAutoChip.
  ///
  /// In en, this message translates to:
  /// **'Auto-record'**
  String get fpRecurringAutoChip;

  /// No description provided for @fpRecurringNextYear.
  ///
  /// In en, this message translates to:
  /// **'Next year'**
  String get fpRecurringNextYear;

  /// No description provided for @fpRecurringGoToMonth.
  ///
  /// In en, this message translates to:
  /// **'Go to month'**
  String get fpRecurringGoToMonth;

  /// No description provided for @fpRecurringTagNext.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get fpRecurringTagNext;

  /// No description provided for @fpRecurringTagMoved.
  ///
  /// In en, this message translates to:
  /// **'Moved'**
  String get fpRecurringTagMoved;

  /// No description provided for @fpRecurringTagLast.
  ///
  /// In en, this message translates to:
  /// **'Last'**
  String get fpRecurringTagLast;

  /// No description provided for @fpRecurringUsualAmount.
  ///
  /// In en, this message translates to:
  /// **'Usually {amount}'**
  String fpRecurringUsualAmount(String amount);

  /// No description provided for @fpRecurringMovedFrom.
  ///
  /// In en, this message translates to:
  /// **'From {date}'**
  String fpRecurringMovedFrom(String date);

  /// No description provided for @fpRecurringTapToConfirm.
  ///
  /// In en, this message translates to:
  /// **'Tap to confirm'**
  String get fpRecurringTapToConfirm;

  /// No description provided for @fpRecurringTapToEnter.
  ///
  /// In en, this message translates to:
  /// **'Tap to enter the amount'**
  String get fpRecurringTapToEnter;

  /// No description provided for @fpRecurringTapToRestore.
  ///
  /// In en, this message translates to:
  /// **'Tap to undo the skip'**
  String get fpRecurringTapToRestore;

  /// No description provided for @fpRecurringAutoCreate.
  ///
  /// In en, this message translates to:
  /// **'Record automatically on the day'**
  String get fpRecurringAutoCreate;

  /// No description provided for @fpRecurringAutoCreateHint.
  ///
  /// In en, this message translates to:
  /// **'On the day it\'s recorded for you, no confirm needed'**
  String get fpRecurringAutoCreateHint;

  /// No description provided for @fpRecurringAutoCreateNeeds.
  ///
  /// In en, this message translates to:
  /// **'Needs a fixed amount and a wallet first'**
  String get fpRecurringAutoCreateNeeds;

  /// No description provided for @fpRecurringTxScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'Apply this to the {n} recorded transactions too?'**
  String fpRecurringTxScopeTitle(int n);

  /// No description provided for @fpRecurringTxScopeFuture.
  ///
  /// In en, this message translates to:
  /// **'Only from now on'**
  String get fpRecurringTxScopeFuture;

  /// No description provided for @fpRecurringTxScopeAll.
  ///
  /// In en, this message translates to:
  /// **'Recorded ones too (amount and date stay)'**
  String get fpRecurringTxScopeAll;

  /// No description provided for @fpRecurringTxUpdateFailed.
  ///
  /// In en, this message translates to:
  /// **'{n} recorded transactions couldn\'t be updated'**
  String fpRecurringTxUpdateFailed(int n);

  /// No description provided for @fpM5bRecurringPerMonth.
  ///
  /// In en, this message translates to:
  /// **'Per month'**
  String get fpM5bRecurringPerMonth;

  /// No description provided for @fpM5bRecurringDeleteNumbers.
  ///
  /// In en, this message translates to:
  /// **'This deletes {items} occurrences, {drafts} waiting drafts and touches {linked} saved records.'**
  String fpM5bRecurringDeleteNumbers(int items, int drafts, int linked);

  /// No description provided for @fpM5bEventDeleteNumbers.
  ///
  /// In en, this message translates to:
  /// **'This deletes {bills} bills and {members} members.'**
  String fpM5bEventDeleteNumbers(int bills, int members);

  /// No description provided for @fpGoalsPlanHeadMonth.
  ///
  /// In en, this message translates to:
  /// **'This month’s saving plan | {month}'**
  String fpGoalsPlanHeadMonth(String month);

  /// No description provided for @fpGoalsRingSavedPct.
  ///
  /// In en, this message translates to:
  /// **'Saved {pct}%'**
  String fpGoalsRingSavedPct(int pct);

  /// No description provided for @fpGoalsFactTargetShort.
  ///
  /// In en, this message translates to:
  /// **'Short of the targets'**
  String get fpGoalsFactTargetShort;

  /// No description provided for @fpGoalsFactMonthToSave.
  ///
  /// In en, this message translates to:
  /// **'To save this month'**
  String get fpGoalsFactMonthToSave;

  /// No description provided for @debtSubRecord.
  ///
  /// In en, this message translates to:
  /// **'Record a debt'**
  String get debtSubRecord;

  /// No description provided for @debtSubRepay.
  ///
  /// In en, this message translates to:
  /// **'Repay'**
  String get debtSubRepay;

  /// No description provided for @debtRepayReceive.
  ///
  /// In en, this message translates to:
  /// **'Got back'**
  String get debtRepayReceive;

  /// No description provided for @debtMoneyMovedLabel.
  ///
  /// In en, this message translates to:
  /// **'Money in / out of a wallet'**
  String get debtMoneyMovedLabel;

  /// No description provided for @debtTitleHintOwedToMe.
  ///
  /// In en, this message translates to:
  /// **'What for? e.g. paid for their lunch, a loan'**
  String get debtTitleHintOwedToMe;

  /// No description provided for @debtTitleHintIOwe.
  ///
  /// In en, this message translates to:
  /// **'What for? e.g. they paid for my lunch, borrowed money'**
  String get debtTitleHintIOwe;

  /// No description provided for @debtRepayTitleHint.
  ///
  /// In en, this message translates to:
  /// **'What for?'**
  String get debtRepayTitleHint;

  /// No description provided for @debtRecordChip.
  ///
  /// In en, this message translates to:
  /// **'Log a debt'**
  String get debtRecordChip;

  /// No description provided for @debtSettleChip.
  ///
  /// In en, this message translates to:
  /// **'Pay a debt'**
  String get debtSettleChip;

  /// No description provided for @debtOriginFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Origin'**
  String get debtOriginFieldLabel;

  /// No description provided for @debtOriginPickFirst.
  ///
  /// In en, this message translates to:
  /// **'Pick a person first'**
  String get debtOriginPickFirst;

  /// No description provided for @debtOriginLend.
  ///
  /// In en, this message translates to:
  /// **'Lent to {name}'**
  String debtOriginLend(String name);

  /// No description provided for @debtOriginBorrow.
  ///
  /// In en, this message translates to:
  /// **'Borrowed from {name}'**
  String debtOriginBorrow(String name);

  /// No description provided for @debtRoleDebtor.
  ///
  /// In en, this message translates to:
  /// **'Owes me'**
  String get debtRoleDebtor;

  /// No description provided for @debtRoleCreditor.
  ///
  /// In en, this message translates to:
  /// **'I owe'**
  String get debtRoleCreditor;

  /// No description provided for @debtSummaryDebtor.
  ///
  /// In en, this message translates to:
  /// **'{name} owes me'**
  String debtSummaryDebtor(String name);

  /// No description provided for @debtSummaryCreditor.
  ///
  /// In en, this message translates to:
  /// **'I owe {name}'**
  String debtSummaryCreditor(String name);

  /// No description provided for @debtSummaryBecomesDebtor.
  ///
  /// In en, this message translates to:
  /// **'{name} now owes me'**
  String debtSummaryBecomesDebtor(String name);

  /// No description provided for @debtSummaryBecomesCreditor.
  ///
  /// In en, this message translates to:
  /// **'Now I owe {name}'**
  String debtSummaryBecomesCreditor(String name);

  /// No description provided for @debtSummaryCleared.
  ///
  /// In en, this message translates to:
  /// **'Settled up with {name}'**
  String debtSummaryCleared(String name);

  /// No description provided for @debtRepayTo.
  ///
  /// In en, this message translates to:
  /// **'Pay back to'**
  String get debtRepayTo;

  /// No description provided for @debtRepayFrom.
  ///
  /// In en, this message translates to:
  /// **'Got back from'**
  String get debtRepayFrom;

  /// No description provided for @debtRepayDescPay.
  ///
  /// In en, this message translates to:
  /// **'Paid back {name}'**
  String debtRepayDescPay(String name);

  /// No description provided for @debtRepayDescReceive.
  ///
  /// In en, this message translates to:
  /// **'Got back from {name}'**
  String debtRepayDescReceive(String name);

  /// No description provided for @debtMarkPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Close debts'**
  String get debtMarkPaidLabel;

  /// No description provided for @debtRepayLeft.
  ///
  /// In en, this message translates to:
  /// **'After saving: {amount} left'**
  String debtRepayLeft(String amount);

  /// No description provided for @debtRepayCleared.
  ///
  /// In en, this message translates to:
  /// **'Settled up'**
  String get debtRepayCleared;

  /// No description provided for @debtRepayPickTitle.
  ///
  /// In en, this message translates to:
  /// **'People with an open balance'**
  String get debtRepayPickTitle;

  /// No description provided for @debtRepayNoOpen.
  ///
  /// In en, this message translates to:
  /// **'No one owes or is owed right now'**
  String get debtRepayNoOpen;

  /// No description provided for @txRepaymentCategoryLocked.
  ///
  /// In en, this message translates to:
  /// **'A repayment keeps its system category'**
  String get txRepaymentCategoryLocked;

  /// No description provided for @txLinkModeNeedsPayer.
  ///
  /// In en, this message translates to:
  /// **'Pick who paid first'**
  String get txLinkModeNeedsPayer;

  /// No description provided for @txLinkModeNeedsEvent.
  ///
  /// In en, this message translates to:
  /// **'Pick an event first'**
  String get txLinkModeNeedsEvent;

  /// No description provided for @txLinkModeUnbalanced.
  ///
  /// In en, this message translates to:
  /// **'The amounts don\'t add up to the bill yet. See the card\'s status line.'**
  String get txLinkModeUnbalanced;

  /// No description provided for @txLinkTabLabel.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get txLinkTabLabel;

  /// No description provided for @txLinkTabPersonal.
  ///
  /// In en, this message translates to:
  /// **'Just me'**
  String get txLinkTabPersonal;

  /// No description provided for @txLinkTabSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get txLinkTabSplit;

  /// No description provided for @txLinkTabPaid.
  ///
  /// In en, this message translates to:
  /// **'Paid for me'**
  String get txLinkTabPaid;

  /// No description provided for @txLinkTabEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get txLinkTabEvent;

  /// No description provided for @txLinkBillLabel.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get txLinkBillLabel;

  /// No description provided for @txLinkCardSplitTitle.
  ///
  /// In en, this message translates to:
  /// **'Split with'**
  String get txLinkCardSplitTitle;

  /// No description provided for @txLinkCardPaidTitle.
  ///
  /// In en, this message translates to:
  /// **'Who paid, and how much'**
  String get txLinkCardPaidTitle;

  /// No description provided for @txLinkCardMyPaid.
  ///
  /// In en, this message translates to:
  /// **'I paid (from my wallet)'**
  String get txLinkCardMyPaid;

  /// No description provided for @txLinkCardPickPayer.
  ///
  /// In en, this message translates to:
  /// **'Pick who paid'**
  String get txLinkCardPickPayer;

  /// No description provided for @txLinkCardWhoPaid.
  ///
  /// In en, this message translates to:
  /// **'Who paid'**
  String get txLinkCardWhoPaid;

  /// No description provided for @txLinkCardWhoInBill.
  ///
  /// In en, this message translates to:
  /// **'Who\'s in the bill'**
  String get txLinkCardWhoInBill;

  /// No description provided for @txLinkCardMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get txLinkCardMe;

  /// No description provided for @txLinkCardSplitOk.
  ///
  /// In en, this message translates to:
  /// **'✓ All split'**
  String get txLinkCardSplitOk;

  /// No description provided for @txLinkCardPaidOk.
  ///
  /// In en, this message translates to:
  /// **'✓ Fully paid'**
  String get txLinkCardPaidOk;

  /// No description provided for @txLinkCardShort.
  ///
  /// In en, this message translates to:
  /// **'{amount} short'**
  String txLinkCardShort(String amount);

  /// No description provided for @txLinkCardOver.
  ///
  /// In en, this message translates to:
  /// **'{amount} over'**
  String txLinkCardOver(String amount);

  /// No description provided for @txLinkCardNewToEvent.
  ///
  /// In en, this message translates to:
  /// **'New · joins the event'**
  String get txLinkCardNewToEvent;

  /// No description provided for @txLinkAddToEvent.
  ///
  /// In en, this message translates to:
  /// **'Add to event'**
  String get txLinkAddToEvent;

  /// No description provided for @txPaidBackNeedsWallet.
  ///
  /// In en, this message translates to:
  /// **'Paid back needs the wallet the money went into'**
  String get txPaidBackNeedsWallet;

  /// No description provided for @txLinkBookDebt.
  ///
  /// In en, this message translates to:
  /// **'Record the debts too'**
  String get txLinkBookDebt;

  /// No description provided for @txLinkWalletNotOut.
  ///
  /// In en, this message translates to:
  /// **'Not from your wallet'**
  String get txLinkWalletNotOut;

  /// No description provided for @txLinkWalletPart.
  ///
  /// In en, this message translates to:
  /// **'{amount} from this wallet'**
  String txLinkWalletPart(String amount);

  /// No description provided for @txLinkShareIOwe.
  ///
  /// In en, this message translates to:
  /// **'I owe {name} {amount}'**
  String txLinkShareIOwe(String name, String amount);

  /// No description provided for @txLinkViewPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get txLinkViewPaidLabel;

  /// No description provided for @txLinkViewMyPaid.
  ///
  /// In en, this message translates to:
  /// **'I paid {amount}'**
  String txLinkViewMyPaid(String amount);

  /// No description provided for @txLinkViewEventLabel.
  ///
  /// In en, this message translates to:
  /// **'Event bill'**
  String get txLinkViewEventLabel;

  /// No description provided for @txLinkViewIPaid.
  ///
  /// In en, this message translates to:
  /// **'I paid'**
  String get txLinkViewIPaid;

  /// No description provided for @txLinkViewTheyPaid.
  ///
  /// In en, this message translates to:
  /// **'{name} paid'**
  String txLinkViewTheyPaid(String name);

  /// No description provided for @txLinkViewPeople.
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String txLinkViewPeople(int count);

  /// No description provided for @debtDirectionOwedToMeSub.
  ///
  /// In en, this message translates to:
  /// **'they pay me back'**
  String get debtDirectionOwedToMeSub;

  /// No description provided for @debtDirectionIOweSub.
  ///
  /// In en, this message translates to:
  /// **'I pay them back'**
  String get debtDirectionIOweSub;

  /// No description provided for @txLinkPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'What will change'**
  String get txLinkPreviewTitle;

  /// No description provided for @txLinkPreviewLine.
  ///
  /// In en, this message translates to:
  /// **'{name}: {before} → {after}'**
  String txLinkPreviewLine(String name, String before, String after);

  /// No description provided for @txLinkPreviewNone.
  ///
  /// In en, this message translates to:
  /// **'No one\'s balance changes'**
  String get txLinkPreviewNone;

  /// No description provided for @txLinkOutOfSyncLabel.
  ///
  /// In en, this message translates to:
  /// **'The event bill changed'**
  String get txLinkOutOfSyncLabel;

  /// No description provided for @txLinkApplyEvent.
  ///
  /// In en, this message translates to:
  /// **'Update from the event'**
  String get txLinkApplyEvent;

  /// No description provided for @txLinkApplied.
  ///
  /// In en, this message translates to:
  /// **'Updated from the event'**
  String get txLinkApplied;

  /// No description provided for @linkedEventAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Change it in the event too?'**
  String get linkedEventAskTitle;

  /// No description provided for @linkedBookAskTitle.
  ///
  /// In en, this message translates to:
  /// **'Change it in my book too?'**
  String get linkedBookAskTitle;

  /// No description provided for @linkedMineOnly.
  ///
  /// In en, this message translates to:
  /// **'Only mine'**
  String get linkedMineOnly;

  /// No description provided for @linkedEventOnly.
  ///
  /// In en, this message translates to:
  /// **'Only the event'**
  String get linkedEventOnly;

  /// No description provided for @linkedBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get linkedBoth;

  /// No description provided for @txLinkDraftNeedsExistingEvent.
  ///
  /// In en, this message translates to:
  /// **'A draft can only go to an existing event'**
  String get txLinkDraftNeedsExistingEvent;

  /// No description provided for @debtQuickCreateTxLabel.
  ///
  /// In en, this message translates to:
  /// **'Also save as a transaction'**
  String get debtQuickCreateTxLabel;

  /// No description provided for @debtResultNow.
  ///
  /// In en, this message translates to:
  /// **'{name} now'**
  String debtResultNow(String name);

  /// No description provided for @debtResultAfterSave.
  ///
  /// In en, this message translates to:
  /// **'After saving'**
  String get debtResultAfterSave;

  /// No description provided for @debtResultWallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet {wallet}'**
  String debtResultWallet(String wallet);

  /// No description provided for @debtWalletNotUsed.
  ///
  /// In en, this message translates to:
  /// **'No change'**
  String get debtWalletNotUsed;

  /// No description provided for @debtOverpayWarn.
  ///
  /// In en, this message translates to:
  /// **'More than what\'s open — after saving: {after}'**
  String debtOverpayWarn(String after);

  /// No description provided for @debtOverpayTitle.
  ///
  /// In en, this message translates to:
  /// **'More than what\'s open'**
  String get debtOverpayTitle;

  /// No description provided for @debtOverpayConfirm.
  ///
  /// In en, this message translates to:
  /// **'Save anyway'**
  String get debtOverpayConfirm;

  /// No description provided for @debtOverpayEdit.
  ///
  /// In en, this message translates to:
  /// **'Change the amount'**
  String get debtOverpayEdit;

  /// No description provided for @debtWalletUnusedLabel.
  ///
  /// In en, this message translates to:
  /// **'Wallet (not used)'**
  String get debtWalletUnusedLabel;

  /// No description provided for @debtSomeone.
  ///
  /// In en, this message translates to:
  /// **'them'**
  String get debtSomeone;

  /// No description provided for @debtSentenceRecordIn.
  ///
  /// In en, this message translates to:
  /// **'Note that {name} owes me'**
  String debtSentenceRecordIn(String name);

  /// No description provided for @debtSentenceLendTx.
  ///
  /// In en, this message translates to:
  /// **'(I lend {name} money from my wallet)'**
  String debtSentenceLendTx(String name);

  /// No description provided for @debtSentenceRecordOut.
  ///
  /// In en, this message translates to:
  /// **'Note that I owe {name}'**
  String debtSentenceRecordOut(String name);

  /// No description provided for @debtSentenceBorrowTx.
  ///
  /// In en, this message translates to:
  /// **'(I borrow from {name} into my wallet)'**
  String debtSentenceBorrowTx(String name);

  /// No description provided for @debtSentenceSettleIn.
  ///
  /// In en, this message translates to:
  /// **'{name} pays me back, into my wallet'**
  String debtSentenceSettleIn(String name);

  /// No description provided for @debtSentenceSettleOut.
  ///
  /// In en, this message translates to:
  /// **'I pay {name} back, from my wallet'**
  String debtSentenceSettleOut(String name);

  /// No description provided for @debtTxHintLend.
  ///
  /// In en, this message translates to:
  /// **'Adds an expense to the wallet'**
  String get debtTxHintLend;

  /// No description provided for @debtTxHintBorrow.
  ///
  /// In en, this message translates to:
  /// **'Adds income to the wallet'**
  String get debtTxHintBorrow;

  /// No description provided for @debtTxHintOff.
  ///
  /// In en, this message translates to:
  /// **'Wallet balance unchanged'**
  String get debtTxHintOff;

  /// No description provided for @debtsHeroNet.
  ///
  /// In en, this message translates to:
  /// **'Net debts | {count} people'**
  String debtsHeroNet(int count);

  /// No description provided for @debtsFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get debtsFilterAll;

  /// No description provided for @debtsOver30Label.
  ///
  /// In en, this message translates to:
  /// **'Open over 30 days'**
  String get debtsOver30Label;

  /// No description provided for @debtsPeopleCount.
  ///
  /// In en, this message translates to:
  /// **'{count} people'**
  String debtsPeopleCount(int count);

  /// No description provided for @debtsLastIPaidBack.
  ///
  /// In en, this message translates to:
  /// **'You paid back {amount}'**
  String debtsLastIPaidBack(String amount);

  /// No description provided for @debtsLastTheyPaidBack.
  ///
  /// In en, this message translates to:
  /// **'{name} paid back {amount}'**
  String debtsLastTheyPaidBack(String name, String amount);

  /// No description provided for @debtsLastLine.
  ///
  /// In en, this message translates to:
  /// **'{what} | {date}'**
  String debtsLastLine(String what, String date);

  /// No description provided for @debtPersonSince.
  ///
  /// In en, this message translates to:
  /// **'together since {month}'**
  String debtPersonSince(String month);

  /// No description provided for @debtPersonOweTo.
  ///
  /// In en, this message translates to:
  /// **'I owe {name}'**
  String debtPersonOweTo(String name);

  /// No description provided for @debtPersonOwedFrom.
  ///
  /// In en, this message translates to:
  /// **'{name} owes me'**
  String debtPersonOwedFrom(String name);

  /// No description provided for @debtPersonSettlePay.
  ///
  /// In en, this message translates to:
  /// **'Pay back {amount}'**
  String debtPersonSettlePay(String amount);

  /// No description provided for @debtPersonSettleReceive.
  ///
  /// In en, this message translates to:
  /// **'Got back {amount}'**
  String debtPersonSettleReceive(String amount);

  /// No description provided for @debtPersonSummary.
  ///
  /// In en, this message translates to:
  /// **'Summary'**
  String get debtPersonSummary;

  /// No description provided for @debtPersonChase.
  ///
  /// In en, this message translates to:
  /// **'Remind'**
  String get debtPersonChase;

  /// No description provided for @debtPersonSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Summary with {name}'**
  String debtPersonSummaryTitle(String name);

  /// No description provided for @debtPersonChaseTitle.
  ///
  /// In en, this message translates to:
  /// **'Remind {name}'**
  String debtPersonChaseTitle(String name);

  /// No description provided for @debtShareThisCycle.
  ///
  /// In en, this message translates to:
  /// **'This cycle'**
  String get debtShareThisCycle;

  /// No description provided for @debtShareBalanceOnly.
  ///
  /// In en, this message translates to:
  /// **'Balance only'**
  String get debtShareBalanceOnly;

  /// No description provided for @debtShareFieldLabel.
  ///
  /// In en, this message translates to:
  /// **'Message (edit before sending)'**
  String get debtShareFieldLabel;

  /// No description provided for @debtShareSend.
  ///
  /// In en, this message translates to:
  /// **'Share to LINE / other apps'**
  String get debtShareSend;

  /// No description provided for @debtDayUp.
  ///
  /// In en, this message translates to:
  /// **'up {amount}'**
  String debtDayUp(String amount);

  /// No description provided for @debtDayDown.
  ///
  /// In en, this message translates to:
  /// **'down {amount}'**
  String debtDayDown(String amount);

  /// No description provided for @debtEarlierShow.
  ///
  /// In en, this message translates to:
  /// **'Settled up {date} | Earlier ▾'**
  String debtEarlierShow(String date);

  /// No description provided for @debtEarlierShowPlain.
  ///
  /// In en, this message translates to:
  /// **'Earlier ▾'**
  String get debtEarlierShowPlain;

  /// No description provided for @debtEarlierHide.
  ///
  /// In en, this message translates to:
  /// **'Hide earlier ▴'**
  String get debtEarlierHide;

  /// No description provided for @debtRowFromWallet.
  ///
  /// In en, this message translates to:
  /// **'from wallet {name}'**
  String debtRowFromWallet(String name);

  /// No description provided for @debtRowIntoWallet.
  ///
  /// In en, this message translates to:
  /// **'into wallet {name}'**
  String debtRowIntoWallet(String name);

  /// No description provided for @debtRowNoWallet.
  ///
  /// In en, this message translates to:
  /// **'no wallet'**
  String get debtRowNoWallet;

  /// No description provided for @debtRowTheyPaid.
  ///
  /// In en, this message translates to:
  /// **'{name} paid for me'**
  String debtRowTheyPaid(String name);

  /// No description provided for @debtRowIPaid.
  ///
  /// In en, this message translates to:
  /// **'you paid for them'**
  String get debtRowIPaid;

  /// No description provided for @debtRowSplitBill.
  ///
  /// In en, this message translates to:
  /// **'split bill {amount}'**
  String debtRowSplitBill(String amount);

  /// No description provided for @debtRowEvent.
  ///
  /// In en, this message translates to:
  /// **'event {name}'**
  String debtRowEvent(String name);

  /// No description provided for @debtRowIPaidBack.
  ///
  /// In en, this message translates to:
  /// **'You paid {name} back'**
  String debtRowIPaidBack(String name);

  /// No description provided for @debtRowTheyPaidBack.
  ///
  /// In en, this message translates to:
  /// **'{name} paid back'**
  String debtRowTheyPaidBack(String name);

  /// No description provided for @debtPaidPill.
  ///
  /// In en, this message translates to:
  /// **'✓ Paid'**
  String get debtPaidPill;

  /// No description provided for @debtUnpaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Not paid'**
  String get debtUnpaidLabel;

  /// No description provided for @debtDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Due'**
  String get debtDueLabel;

  /// No description provided for @debtsSectionTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get debtsSectionTotal;

  /// No description provided for @debtDuePick.
  ///
  /// In en, this message translates to:
  /// **'Pick a due date'**
  String get debtDuePick;

  /// No description provided for @debtDueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String debtDueOn(String date);

  /// No description provided for @debtOverdueDays.
  ///
  /// In en, this message translates to:
  /// **'{days} days overdue'**
  String debtOverdueDays(int days);

  /// No description provided for @debtsOwingDays.
  ///
  /// In en, this message translates to:
  /// **'Owing for {days} days'**
  String debtsOwingDays(int days);

  /// No description provided for @debtLinkTx.
  ///
  /// In en, this message translates to:
  /// **'Create a transaction from this debt'**
  String get debtLinkTx;

  /// No description provided for @debtPaidHelper.
  ///
  /// In en, this message translates to:
  /// **'Only a label; it never changes a number'**
  String get debtPaidHelper;

  /// No description provided for @debtOriginLabel.
  ///
  /// In en, this message translates to:
  /// **'From ({kind})'**
  String debtOriginLabel(String kind);

  /// No description provided for @debtOriginSplit.
  ///
  /// In en, this message translates to:
  /// **'split bill'**
  String get debtOriginSplit;

  /// No description provided for @debtOriginPaidBy.
  ///
  /// In en, this message translates to:
  /// **'paid for me'**
  String get debtOriginPaidBy;

  /// No description provided for @debtOriginPartner.
  ///
  /// In en, this message translates to:
  /// **'their split'**
  String get debtOriginPartner;

  /// No description provided for @debtOriginEvent.
  ///
  /// In en, this message translates to:
  /// **'event'**
  String get debtOriginEvent;

  /// No description provided for @debtOriginCash.
  ///
  /// In en, this message translates to:
  /// **'a loan'**
  String get debtOriginCash;

  /// No description provided for @debtOriginLocked.
  ///
  /// In en, this message translates to:
  /// **'can\'t change it here'**
  String get debtOriginLocked;

  /// No description provided for @debtEditWalletLend.
  ///
  /// In en, this message translates to:
  /// **'Money leaves the wallet (a loan / paid for them)'**
  String get debtEditWalletLend;

  /// No description provided for @debtEditWalletBorrow.
  ///
  /// In en, this message translates to:
  /// **'Money comes into the wallet (borrowed)'**
  String get debtEditWalletBorrow;

  /// No description provided for @debtEditWalletOff.
  ///
  /// In en, this message translates to:
  /// **'Only the debt, no money moves'**
  String get debtEditWalletOff;

  /// No description provided for @quickCreateBtnTx.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get quickCreateBtnTx;

  /// No description provided for @quickCreateBtnDebt.
  ///
  /// In en, this message translates to:
  /// **'Add debt'**
  String get quickCreateBtnDebt;

  /// No description provided for @quickCreateBtnSaving.
  ///
  /// In en, this message translates to:
  /// **'Save money'**
  String get quickCreateBtnSaving;

  /// No description provided for @debtsEmptyOpenTitle.
  ///
  /// In en, this message translates to:
  /// **'No open debts'**
  String get debtsEmptyOpenTitle;

  /// No description provided for @debtsEmptyOpenMessage.
  ///
  /// In en, this message translates to:
  /// **'Note who borrowed and who paid for whom, so you never forget to ask'**
  String get debtsEmptyOpenMessage;
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
