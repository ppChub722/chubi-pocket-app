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
  /// **'Debt collected'**
  String get categorySystemDebtReceived;

  /// No description provided for @categorySystemDebtPaid.
  ///
  /// In en, this message translates to:
  /// **'Debt repayment'**
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

  /// No description provided for @contactPickerEmpty.
  ///
  /// In en, this message translates to:
  /// **'No contacts yet — type a name above'**
  String get contactPickerEmpty;

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

  /// No description provided for @errorSlowTitle.
  ///
  /// In en, this message translates to:
  /// **'Slow connection'**
  String get errorSlowTitle;

  /// No description provided for @errorSlowMessage.
  ///
  /// In en, this message translates to:
  /// **'The server is taking too long. Please try again.'**
  String get errorSlowMessage;

  /// No description provided for @errorServerDownTitle.
  ///
  /// In en, this message translates to:
  /// **'Server unavailable'**
  String get errorServerDownTitle;

  /// No description provided for @errorServerDownMessage.
  ///
  /// In en, this message translates to:
  /// **'The service is down for a moment. Try again shortly.'**
  String get errorServerDownMessage;

  /// No description provided for @errFieldRequired.
  ///
  /// In en, this message translates to:
  /// **'This field is required'**
  String get errFieldRequired;

  /// No description provided for @errFieldTooLong.
  ///
  /// In en, this message translates to:
  /// **'Longer than {max} characters'**
  String errFieldTooLong(String max);

  /// No description provided for @errFieldTooShort.
  ///
  /// In en, this message translates to:
  /// **'At least {min} characters'**
  String errFieldTooShort(String min);

  /// No description provided for @errFieldTooMany.
  ///
  /// In en, this message translates to:
  /// **'At most {max} items'**
  String errFieldTooMany(String max);

  /// No description provided for @errFieldTooFew.
  ///
  /// In en, this message translates to:
  /// **'At least {min} items'**
  String errFieldTooFew(String min);

  /// No description provided for @errFieldOutOfRange.
  ///
  /// In en, this message translates to:
  /// **'This value is out of range'**
  String get errFieldOutOfRange;

  /// No description provided for @errFieldInvalid.
  ///
  /// In en, this message translates to:
  /// **'Not a valid value'**
  String get errFieldInvalid;

  /// No description provided for @errFieldTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The file is too large'**
  String get errFieldTooLarge;

  /// No description provided for @errorGenericTitle.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong'**
  String get errorGenericTitle;

  /// No description provided for @errorGenericMessage.
  ///
  /// In en, this message translates to:
  /// **'Please try again'**
  String get errorGenericMessage;

  /// No description provided for @errorValidationMessage.
  ///
  /// In en, this message translates to:
  /// **'Some fields aren’t valid — please check them'**
  String get errorValidationMessage;

  /// No description provided for @errNotFound.
  ///
  /// In en, this message translates to:
  /// **'This item wasn’t found — it may have been deleted'**
  String get errNotFound;

  /// No description provided for @errForbidden.
  ///
  /// In en, this message translates to:
  /// **'You don’t have permission to do this'**
  String get errForbidden;

  /// No description provided for @errImmutable.
  ///
  /// In en, this message translates to:
  /// **'This can’t be changed or deleted'**
  String get errImmutable;

  /// No description provided for @errStale.
  ///
  /// In en, this message translates to:
  /// **'This changed since you opened it — refresh and try again'**
  String get errStale;

  /// No description provided for @errSessionExpired.
  ///
  /// In en, this message translates to:
  /// **'Your session expired — please log in again'**
  String get errSessionExpired;

  /// No description provided for @errAppOutdated.
  ///
  /// In en, this message translates to:
  /// **'Update the app to keep using it'**
  String get errAppOutdated;

  /// No description provided for @errAccountInactive.
  ///
  /// In en, this message translates to:
  /// **'This account is deactivated — reactivate it to continue'**
  String get errAccountInactive;

  /// No description provided for @errRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many tries — wait a moment and try again'**
  String get errRateLimited;

  /// No description provided for @errLoginCodeInvalid.
  ///
  /// In en, this message translates to:
  /// **'The login link expired or was already used — start again'**
  String get errLoginCodeInvalid;

  /// No description provided for @errCategoryNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A category with this name already exists at this level'**
  String get errCategoryNameDuplicate;

  /// No description provided for @errCategoryCycle.
  ///
  /// In en, this message translates to:
  /// **'A category can’t move under itself or its own sub-categories'**
  String get errCategoryCycle;

  /// No description provided for @errTagExists.
  ///
  /// In en, this message translates to:
  /// **'A tag with this name already exists'**
  String get errTagExists;

  /// No description provided for @errPaidByExceeds.
  ///
  /// In en, this message translates to:
  /// **'What the payer covered is more than the bill'**
  String get errPaidByExceeds;

  /// No description provided for @errPayersSum.
  ///
  /// In en, this message translates to:
  /// **'The payers must add up to the bill'**
  String get errPayersSum;

  /// No description provided for @errInsufficientSaving.
  ///
  /// In en, this message translates to:
  /// **'There isn’t enough saved there'**
  String get errInsufficientSaving;

  /// No description provided for @errGoalNotActive.
  ///
  /// In en, this message translates to:
  /// **'This saving goal isn’t active'**
  String get errGoalNotActive;

  /// No description provided for @errGoalReached.
  ///
  /// In en, this message translates to:
  /// **'This saving goal already reached its target'**
  String get errGoalReached;

  /// No description provided for @errGoalHasSavings.
  ///
  /// In en, this message translates to:
  /// **'This saving goal still holds money — close it first'**
  String get errGoalHasSavings;

  /// No description provided for @errUnsupportedImage.
  ///
  /// In en, this message translates to:
  /// **'This picture can’t be used — use a PNG or JPEG'**
  String get errUnsupportedImage;

  /// No description provided for @errOcrUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Reading slips isn’t available right now'**
  String get errOcrUnavailable;

  /// No description provided for @errOcrTimeout.
  ///
  /// In en, this message translates to:
  /// **'Reading the slip took too long — try again'**
  String get errOcrTimeout;

  /// No description provided for @errProvider.
  ///
  /// In en, this message translates to:
  /// **'The linked app didn’t answer — try again'**
  String get errProvider;

  /// No description provided for @errNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'The linked app has no picture to use'**
  String get errNoPhoto;

  /// No description provided for @errAvatarSource.
  ///
  /// In en, this message translates to:
  /// **'This picture source has no picture any more'**
  String get errAvatarSource;

  /// No description provided for @errCurrencyLocked.
  ///
  /// In en, this message translates to:
  /// **'The currency can\'t be changed'**
  String get errCurrencyLocked;

  /// No description provided for @errPermissionUnavailable.
  ///
  /// In en, this message translates to:
  /// **'This permission can’t be turned on for this app'**
  String get errPermissionUnavailable;

  /// No description provided for @errCannotLinkSelf.
  ///
  /// In en, this message translates to:
  /// **'A contact can’t be linked to yourself'**
  String get errCannotLinkSelf;

  /// No description provided for @errEndTooFar.
  ///
  /// In en, this message translates to:
  /// **'The end must be within 2 years of the start'**
  String get errEndTooFar;

  /// No description provided for @errAmountRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount first'**
  String get errAmountRequired;

  /// No description provided for @errSaveInProgress.
  ///
  /// In en, this message translates to:
  /// **'Still saving — wait a moment and try again'**
  String get errSaveInProgress;

  /// No description provided for @errBillChanged.
  ///
  /// In en, this message translates to:
  /// **'This bill was edited — open it again'**
  String get errBillChanged;

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

  /// No description provided for @authRegisterIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Fill in every field correctly'**
  String get authRegisterIncomplete;

  /// No description provided for @authTelegramWaitTitle.
  ///
  /// In en, this message translates to:
  /// **'Waiting for Telegram'**
  String get authTelegramWaitTitle;

  /// No description provided for @authTelegramWaitBody.
  ///
  /// In en, this message translates to:
  /// **'Tap “Confirm” in the bot chat, then come back to this app'**
  String get authTelegramWaitBody;

  /// No description provided for @authTelegramReopen.
  ///
  /// In en, this message translates to:
  /// **'Open Telegram again'**
  String get authTelegramReopen;

  /// No description provided for @authTelegramCheck.
  ///
  /// In en, this message translates to:
  /// **'Check again'**
  String get authTelegramCheck;

  /// No description provided for @authTelegramExpired.
  ///
  /// In en, this message translates to:
  /// **'The link expired. Start signing in with Telegram again'**
  String get authTelegramExpired;

  /// No description provided for @authTelegramOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not open Telegram. Is the Telegram app installed?'**
  String get authTelegramOpenFailed;

  /// No description provided for @authTelegramSignupTitle.
  ///
  /// In en, this message translates to:
  /// **'Create an account with Telegram'**
  String get authTelegramSignupTitle;

  /// No description provided for @authTelegramSignupPhoto.
  ///
  /// In en, this message translates to:
  /// **'Your Telegram profile picture will be your picture'**
  String get authTelegramSignupPhoto;

  /// No description provided for @authTelegramUsernameTaken.
  ///
  /// In en, this message translates to:
  /// **'That username is taken. We filled in a free one'**
  String get authTelegramUsernameTaken;

  /// No description provided for @authTelegramAlreadyLinked.
  ///
  /// In en, this message translates to:
  /// **'This Telegram is already linked to an account. Try signing in with Telegram again'**
  String get authTelegramAlreadyLinked;

  /// No description provided for @authTelegramUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Telegram is not available right now'**
  String get authTelegramUnavailable;

  /// No description provided for @authRegistrationClosed.
  ///
  /// In en, this message translates to:
  /// **'Sign-up is closed right now'**
  String get authRegistrationClosed;

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

  /// No description provided for @accountFormPaymentDueLabel.
  ///
  /// In en, this message translates to:
  /// **'Payment due'**
  String get accountFormPaymentDueLabel;

  /// No description provided for @accountFormMinimumPaymentLabel.
  ///
  /// In en, this message translates to:
  /// **'Minimum payment'**
  String get accountFormMinimumPaymentLabel;

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

  /// No description provided for @debtsStatusAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get debtsStatusAll;

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

  /// No description provided for @debtPay.
  ///
  /// In en, this message translates to:
  /// **'Pay back'**
  String get debtPay;

  /// No description provided for @debtCounterpartyRequired.
  ///
  /// In en, this message translates to:
  /// **'Add the person first'**
  String get debtCounterpartyRequired;

  /// No description provided for @debtDirectionOwedToMe.
  ///
  /// In en, this message translates to:
  /// **'To receive'**
  String get debtDirectionOwedToMe;

  /// No description provided for @debtDirectionIOwe.
  ///
  /// In en, this message translates to:
  /// **'To pay'**
  String get debtDirectionIOwe;

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

  /// No description provided for @projectNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New event'**
  String get projectNewTitle;

  /// No description provided for @projectNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Name is required'**
  String get projectNameRequired;

  /// No description provided for @projectIconLabel.
  ///
  /// In en, this message translates to:
  /// **'Event icon'**
  String get projectIconLabel;

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

  /// No description provided for @projectDeleted.
  ///
  /// In en, this message translates to:
  /// **'Event deleted'**
  String get projectDeleted;

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

  /// No description provided for @projectMemberBindContact.
  ///
  /// In en, this message translates to:
  /// **'Link to my contact'**
  String get projectMemberBindContact;

  /// No description provided for @projectMemberAddContact.
  ///
  /// In en, this message translates to:
  /// **'Add to my contacts'**
  String get projectMemberAddContact;

  /// No description provided for @projectMemberUnbindContact.
  ///
  /// In en, this message translates to:
  /// **'Unlink from my contact'**
  String get projectMemberUnbindContact;

  /// No description provided for @projectMemberMyContact.
  ///
  /// In en, this message translates to:
  /// **'My contact'**
  String get projectMemberMyContact;

  /// No description provided for @projectMemberContactBound.
  ///
  /// In en, this message translates to:
  /// **'Linked to {name}'**
  String projectMemberContactBound(String name);

  /// No description provided for @projectMemberContactAdded.
  ///
  /// In en, this message translates to:
  /// **'Added {name} to contacts'**
  String projectMemberContactAdded(String name);

  /// No description provided for @projectMemberContactUnbound.
  ///
  /// In en, this message translates to:
  /// **'Unlinked'**
  String get projectMemberContactUnbound;

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

  /// No description provided for @projectTxPaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get projectTxPaidBy;

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

  /// No description provided for @projectTxSplitMember.
  ///
  /// In en, this message translates to:
  /// **'Who'**
  String get projectTxSplitMember;

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
  /// **'Someone shares a bill with me'**
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

  /// No description provided for @notifTypeProjectAdded.
  ///
  /// In en, this message translates to:
  /// **'Added to an event'**
  String get notifTypeProjectAdded;

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

  /// No description provided for @txDetailSourceProject.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get txDetailSourceProject;

  /// No description provided for @txDeleted.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted'**
  String get txDeleted;

  /// No description provided for @txSplitEqually.
  ///
  /// In en, this message translates to:
  /// **'Split equally'**
  String get txSplitEqually;

  /// No description provided for @txSplitAddPerson.
  ///
  /// In en, this message translates to:
  /// **'Add person'**
  String get txSplitAddPerson;

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

  /// No description provided for @projectDeleteThis.
  ///
  /// In en, this message translates to:
  /// **'Delete this event'**
  String get projectDeleteThis;

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

  /// No description provided for @tagDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get tagDeleteConfirmAction;

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

  /// No description provided for @settingsChangePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get settingsChangePassword;

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
  /// **'Back to the sign-in screen.'**
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

  /// No description provided for @editProfileEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get editProfileEmailInvalid;

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

  /// No description provided for @changePasswordSnackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get changePasswordSnackSuccess;

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

  /// No description provided for @amountLabel.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amountLabel;

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

  /// No description provided for @txDetailDeleteRepaymentBody.
  ///
  /// In en, this message translates to:
  /// **'The debt\'s repaid amount goes down by {amount}.'**
  String txDetailDeleteRepaymentBody(String amount);

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

  /// No description provided for @quickEventNameLabel.
  ///
  /// In en, this message translates to:
  /// **'Event name'**
  String get quickEventNameLabel;

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

  /// No description provided for @pendingSelectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get pendingSelectAll;

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

  /// No description provided for @savingGoalArchiveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Archive this goal?'**
  String get savingGoalArchiveConfirmTitle;

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

  /// No description provided for @budgetFormTitle.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get budgetFormTitle;

  /// No description provided for @budgetFormAmountInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive amount'**
  String get budgetFormAmountInvalid;

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

  /// No description provided for @projectFormPlannedInvalid.
  ///
  /// In en, this message translates to:
  /// **'Enter a positive amount'**
  String get projectFormPlannedInvalid;

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

  /// No description provided for @walletReportScopeTitle.
  ///
  /// In en, this message translates to:
  /// **'In my reports'**
  String get walletReportScopeTitle;

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

  /// No description provided for @transactionsSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Search description | note | category | wallet'**
  String get transactionsSearchHint;

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

  /// No description provided for @accountIdentifiersTitle.
  ///
  /// In en, this message translates to:
  /// **'Reference numbers'**
  String get accountIdentifiersTitle;

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

  /// No description provided for @accountsSummaryCardDebt.
  ///
  /// In en, this message translates to:
  /// **'Card debt'**
  String get accountsSummaryCardDebt;

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

  /// No description provided for @draftExtrasNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get draftExtrasNone;

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

  /// No description provided for @eventDatesInvalid.
  ///
  /// In en, this message translates to:
  /// **'The end date can\'t be before the start date'**
  String get eventDatesInvalid;

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

  /// No description provided for @debtCloseConfirm.
  ///
  /// In en, this message translates to:
  /// **'Pick {n} debts'**
  String debtCloseConfirm(int n);

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

  /// No description provided for @eventDeleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get eventDeleteConfirm;

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

  /// No description provided for @occurrenceRecordInTx.
  ///
  /// In en, this message translates to:
  /// **'Recorded as'**
  String get occurrenceRecordInTx;

  /// No description provided for @occurrenceLinkPick.
  ///
  /// In en, this message translates to:
  /// **'Link a transaction'**
  String get occurrenceLinkPick;

  /// No description provided for @occurrenceCreateNow.
  ///
  /// In en, this message translates to:
  /// **'Create it now'**
  String get occurrenceCreateNow;

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

  /// No description provided for @occurrenceDueTitle.
  ///
  /// In en, this message translates to:
  /// **'Needs action'**
  String get occurrenceDueTitle;

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

  /// No description provided for @occurrencePaidCount.
  ///
  /// In en, this message translates to:
  /// **'{n} marked paid'**
  String occurrencePaidCount(int n);

  /// No description provided for @occurrencePaidSelected.
  ///
  /// In en, this message translates to:
  /// **'Mark paid'**
  String get occurrencePaidSelected;

  /// No description provided for @occurrenceNeedsAmount.
  ///
  /// In en, this message translates to:
  /// **'Enter the amount first'**
  String get occurrenceNeedsAmount;

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

  /// No description provided for @sgv2DueOn.
  ///
  /// In en, this message translates to:
  /// **'Due {date}'**
  String sgv2DueOn(String date);

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

  /// No description provided for @sgEntryFrom.
  ///
  /// In en, this message translates to:
  /// **'from {name}'**
  String sgEntryFrom(String name);

  /// No description provided for @sgEntryTo.
  ///
  /// In en, this message translates to:
  /// **'to {name}'**
  String sgEntryTo(String name);

  /// No description provided for @sgv2SpareTitle.
  ///
  /// In en, this message translates to:
  /// **'Not allocated'**
  String get sgv2SpareTitle;

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

  /// No description provided for @bgPeriodAmountField.
  ///
  /// In en, this message translates to:
  /// **'Amount for this period'**
  String get bgPeriodAmountField;

  /// No description provided for @bgPeriodEditSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Only {period} | other periods stay'**
  String bgPeriodEditSubtitle(String period);

  /// No description provided for @bgPeriodBase.
  ///
  /// In en, this message translates to:
  /// **'Base amount'**
  String get bgPeriodBase;

  /// No description provided for @bgPeriodNoteHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. a wedding this month'**
  String get bgPeriodNoteHint;

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
  /// **'Plan {amount}'**
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

  /// No description provided for @pendingSavingNoWallet.
  ///
  /// In en, this message translates to:
  /// **'Pick a wallet before confirming'**
  String get pendingSavingNoWallet;

  /// No description provided for @walletSavingsSaved.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get walletSavingsSaved;

  /// No description provided for @quickModeSaving.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get quickModeSaving;

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

  /// No description provided for @savingEntrySaved.
  ///
  /// In en, this message translates to:
  /// **'Saving recorded'**
  String get savingEntrySaved;

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

  /// No description provided for @profileCurrencyChangeTitle.
  ///
  /// In en, this message translates to:
  /// **'Change currency?'**
  String get profileCurrencyChangeTitle;

  /// No description provided for @profileCurrencyChangeMessage.
  ///
  /// In en, this message translates to:
  /// **'100 stays 100'**
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

  /// No description provided for @fpDebtsDaysOutstanding.
  ///
  /// In en, this message translates to:
  /// **'Outstanding {count} days'**
  String fpDebtsDaysOutstanding(int count);

  /// No description provided for @fpDebtsCopy.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get fpDebtsCopy;

  /// No description provided for @fpDebtsCopied.
  ///
  /// In en, this message translates to:
  /// **'Message copied'**
  String get fpDebtsCopied;

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
  /// **'↺ Use the base amount ({amount})'**
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

  /// No description provided for @fpGoalsFactPeriodSaved.
  ///
  /// In en, this message translates to:
  /// **'This period'**
  String get fpGoalsFactPeriodSaved;

  /// No description provided for @fpGoalsFactPeriodTarget.
  ///
  /// In en, this message translates to:
  /// **'Period target'**
  String get fpGoalsFactPeriodTarget;

  /// No description provided for @fpGoalsFactPeriodEta.
  ///
  /// In en, this message translates to:
  /// **'Done by'**
  String get fpGoalsFactPeriodEta;

  /// No description provided for @fpGoalsChipPeriodShort.
  ///
  /// In en, this message translates to:
  /// **'Short {amount} this period | {days} days left'**
  String fpGoalsChipPeriodShort(String amount, int days);

  /// No description provided for @fpGoalsChipPeriodDone.
  ///
  /// In en, this message translates to:
  /// **'This period is done'**
  String get fpGoalsChipPeriodDone;

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
  /// **'When it\'s due, and what it starts with'**
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

  /// No description provided for @sgAutoAdd.
  ///
  /// In en, this message translates to:
  /// **'Add a saving'**
  String get sgAutoAdd;

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

  /// No description provided for @fpEventsTagAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get fpEventsTagAll;

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

  /// No description provided for @evbBookDebtLine.
  ///
  /// In en, this message translates to:
  /// **'I owe {name}'**
  String evbBookDebtLine(String name);

  /// No description provided for @evbPaybackBy.
  ///
  /// In en, this message translates to:
  /// **'Payback | by {name}'**
  String evbPaybackBy(String name);

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

  /// No description provided for @evbMembersTitle.
  ///
  /// In en, this message translates to:
  /// **'Members'**
  String get evbMembersTitle;

  /// No description provided for @evbManageMembers.
  ///
  /// In en, this message translates to:
  /// **'Manage members ›'**
  String get evbManageMembers;

  /// No description provided for @evbSettleSection.
  ///
  /// In en, this message translates to:
  /// **'Settle up'**
  String get evbSettleSection;

  /// No description provided for @evbSettleRecord.
  ///
  /// In en, this message translates to:
  /// **'Record as a debt'**
  String get evbSettleRecord;

  /// No description provided for @evbSettleRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded'**
  String get evbSettleRecorded;

  /// No description provided for @evbBookedDebt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get evbBookedDebt;

  /// No description provided for @evbBookedTx.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get evbBookedTx;

  /// No description provided for @evbBookMine.
  ///
  /// In en, this message translates to:
  /// **'Book it'**
  String get evbBookMine;

  /// No description provided for @evbSettleHint.
  ///
  /// In en, this message translates to:
  /// **'Tap a line to record the payback in the event (anyone can) | the inbox button records it as your debt'**
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

  /// No description provided for @notifTypeRecurringEnding.
  ///
  /// In en, this message translates to:
  /// **'A recurring is about to end'**
  String get notifTypeRecurringEnding;

  /// No description provided for @notifTypeRecurringAutoCreated.
  ///
  /// In en, this message translates to:
  /// **'Recorded automatically'**
  String get notifTypeRecurringAutoCreated;

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
  /// **'No sign'**
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
  /// **'Not set = the last wallet used'**
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
  /// **'Wallets, budgets, saving goals, recurring, events, contacts'**
  String get settingsArchivedHint;

  /// No description provided for @settingsExportCsv.
  ///
  /// In en, this message translates to:
  /// **'Export CSV'**
  String get settingsExportCsv;

  /// No description provided for @profileSectionSecurity.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get profileSectionSecurity;

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

  /// No description provided for @fpRecurringKindSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving'**
  String get fpRecurringKindSaving;

  /// No description provided for @recurringHomeMonthPayNoSaving.
  ///
  /// In en, this message translates to:
  /// **'Paid this month, savings not included'**
  String get recurringHomeMonthPayNoSaving;

  /// No description provided for @recurringHomeMonthSave.
  ///
  /// In en, this message translates to:
  /// **'Saved this month'**
  String get recurringHomeMonthSave;

  /// No description provided for @sgRecurringTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring saves'**
  String get sgRecurringTitle;

  /// No description provided for @sgPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Saving plan'**
  String get sgPlanTitle;

  /// No description provided for @sgRecurringLabel.
  ///
  /// In en, this message translates to:
  /// **'Recurring saves'**
  String get sgRecurringLabel;

  /// No description provided for @sgPeriodTarget.
  ///
  /// In en, this message translates to:
  /// **'Target per period'**
  String get sgPeriodTarget;

  /// No description provided for @sgPeriodTargetField.
  ///
  /// In en, this message translates to:
  /// **'Amount per period'**
  String get sgPeriodTargetField;

  /// No description provided for @sgPeriodNone.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get sgPeriodNone;

  /// No description provided for @sgPeriodClear.
  ///
  /// In en, this message translates to:
  /// **'No target per period'**
  String get sgPeriodClear;

  /// No description provided for @sgPeriodHelper.
  ///
  /// In en, this message translates to:
  /// **'The last period takes only what is left of the goal'**
  String get sgPeriodHelper;

  /// No description provided for @sgPeriodRule.
  ///
  /// In en, this message translates to:
  /// **'Period'**
  String get sgPeriodRule;

  /// No description provided for @sgPeriodPlanShort.
  ///
  /// In en, this message translates to:
  /// **'Recurring saves put in {plan} a period, short of the {target} target'**
  String sgPeriodPlanShort(String plan, String target);

  /// No description provided for @sgRecurringSpareCaption.
  ///
  /// In en, this message translates to:
  /// **'Saves into unallocated on the round you set'**
  String get sgRecurringSpareCaption;

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

  /// No description provided for @debtRepayReceive.
  ///
  /// In en, this message translates to:
  /// **'Got back'**
  String get debtRepayReceive;

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

  /// No description provided for @debtMarkPaidLabel.
  ///
  /// In en, this message translates to:
  /// **'Close debts'**
  String get debtMarkPaidLabel;

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

  /// No description provided for @txLinkTabSplit.
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get txLinkTabSplit;

  /// No description provided for @txLinkBillLabel.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get txLinkBillLabel;

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

  /// No description provided for @linkedMineOnly.
  ///
  /// In en, this message translates to:
  /// **'Only mine'**
  String get linkedMineOnly;

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

  /// No description provided for @debtSomeone.
  ///
  /// In en, this message translates to:
  /// **'them'**
  String get debtSomeone;

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

  /// No description provided for @debtPersonSince.
  ///
  /// In en, this message translates to:
  /// **'together since {month}'**
  String debtPersonSince(String month);

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

  /// No description provided for @debtTxNone.
  ///
  /// In en, this message translates to:
  /// **'No transaction linked'**
  String get debtTxNone;

  /// No description provided for @debtLinkedAmountDiffers.
  ///
  /// In en, this message translates to:
  /// **'The transaction is {amount}, not the debt\'s amount'**
  String debtLinkedAmountDiffers(String amount);

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

  /// No description provided for @evbReceives.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get evbReceives;

  /// No description provided for @txLinkWalletNotIn.
  ///
  /// In en, this message translates to:
  /// **'Not into this wallet'**
  String get txLinkWalletNotIn;

  /// No description provided for @txLinkWalletPartIn.
  ///
  /// In en, this message translates to:
  /// **'{amount} into this wallet'**
  String txLinkWalletPartIn(String amount);

  /// No description provided for @txLinkViewGotLabel.
  ///
  /// In en, this message translates to:
  /// **'Received by'**
  String get txLinkViewGotLabel;

  /// No description provided for @txLinkViewMyGot.
  ///
  /// In en, this message translates to:
  /// **'I got {amount}'**
  String txLinkViewMyGot(String amount);

  /// No description provided for @txLinkViewIGot.
  ///
  /// In en, this message translates to:
  /// **'I got it'**
  String get txLinkViewIGot;

  /// No description provided for @txLinkCardGotTitle.
  ///
  /// In en, this message translates to:
  /// **'Who got it, and how much'**
  String get txLinkCardGotTitle;

  /// No description provided for @txLinkCardMyGot.
  ///
  /// In en, this message translates to:
  /// **'I got it (into my wallet)'**
  String get txLinkCardMyGot;

  /// No description provided for @txLinkCardWhoGot.
  ///
  /// In en, this message translates to:
  /// **'Who got it'**
  String get txLinkCardWhoGot;

  /// No description provided for @txLinkCardGotOk.
  ///
  /// In en, this message translates to:
  /// **'✓ Fully received'**
  String get txLinkCardGotOk;

  /// No description provided for @txFutureHint.
  ///
  /// In en, this message translates to:
  /// **'{when} | counts in the balance from that day'**
  String txFutureHint(String when);

  /// No description provided for @categorySystemLoanGiven.
  ///
  /// In en, this message translates to:
  /// **'Loan given'**
  String get categorySystemLoanGiven;

  /// No description provided for @categorySystemLoanTaken.
  ///
  /// In en, this message translates to:
  /// **'Loan taken'**
  String get categorySystemLoanTaken;

  /// No description provided for @categorySystemLockedHelper.
  ///
  /// In en, this message translates to:
  /// **'System category: the name and \"count in reports\" can\'t change'**
  String get categorySystemLockedHelper;

  /// No description provided for @debtLinkExistingLabel.
  ///
  /// In en, this message translates to:
  /// **'Connect an existing transaction'**
  String get debtLinkExistingLabel;

  /// No description provided for @debtLinkedAmountNote.
  ///
  /// In en, this message translates to:
  /// **'Amount and date follow the connected transaction'**
  String get debtLinkedAmountNote;

  /// No description provided for @debtCloseAllHint.
  ///
  /// In en, this message translates to:
  /// **'Label every open debt with this person paid'**
  String get debtCloseAllHint;

  /// No description provided for @fpRecurringAutoCreateNeedsWallet.
  ///
  /// In en, this message translates to:
  /// **'Pick a wallet first'**
  String get fpRecurringAutoCreateNeedsWallet;

  /// No description provided for @fpRecurringAutoCreateZeroWarn.
  ///
  /// In en, this message translates to:
  /// **'No fixed amount: on the day it records 0 for you to fix. Not a good fit for an amount that changes every time (e.g. electricity)'**
  String get fpRecurringAutoCreateZeroWarn;

  /// No description provided for @txLinkDisconnect.
  ///
  /// In en, this message translates to:
  /// **'Disconnect'**
  String get txLinkDisconnect;

  /// No description provided for @txLinkDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect from the event?'**
  String get txLinkDisconnectTitle;

  /// No description provided for @txLinkDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected'**
  String get txLinkDisconnected;

  /// No description provided for @occurrenceSkipFilled.
  ///
  /// In en, this message translates to:
  /// **'This one is recorded. Disconnect its transaction first to skip it'**
  String get occurrenceSkipFilled;

  /// No description provided for @recurringPausedOverdue.
  ///
  /// In en, this message translates to:
  /// **'3 waiting: paused. Clear them and resume; it goes on from the current period'**
  String get recurringPausedOverdue;

  /// No description provided for @recurringPausedGoal.
  ///
  /// In en, this message translates to:
  /// **'The saving goal is closed: paused'**
  String get recurringPausedGoal;

  /// No description provided for @recurringOverdueLimitChip.
  ///
  /// In en, this message translates to:
  /// **'3 waiting'**
  String get recurringOverdueLimitChip;

  /// No description provided for @notifTypeDebtDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Someone disconnects a debt with me'**
  String get notifTypeDebtDisconnected;

  /// No description provided for @notifDebtDisconnected.
  ///
  /// In en, this message translates to:
  /// **'{who} disconnected the debt {amount}'**
  String notifDebtDisconnected(String who, String amount);

  /// No description provided for @debtDisconnectTitle.
  ///
  /// In en, this message translates to:
  /// **'Disconnect the debt with {name}?'**
  String debtDisconnectTitle(String name);

  /// No description provided for @debtDisconnectBody.
  ///
  /// In en, this message translates to:
  /// **'It becomes a plain debt in your book that you can edit. Their bill edits won\'t follow any more; they get a notice'**
  String get debtDisconnectBody;

  /// No description provided for @debtPartnerLinked.
  ///
  /// In en, this message translates to:
  /// **'Linked with {name}\'s book'**
  String debtPartnerLinked(String name);

  /// No description provided for @eventCompleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Complete this event for good?'**
  String get eventCompleteTitle;

  /// No description provided for @eventCompleteBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone. No more adding or editing bills, and everyone\'s books stop updating with this event at once (the links stay).'**
  String get eventCompleteBody;

  /// No description provided for @eventCompleteConfirm.
  ///
  /// In en, this message translates to:
  /// **'Complete event'**
  String get eventCompleteConfirm;

  /// No description provided for @eventCompleted.
  ///
  /// In en, this message translates to:
  /// **'Event completed'**
  String get eventCompleted;

  /// No description provided for @eventCompletedNotice.
  ///
  /// In en, this message translates to:
  /// **'This event is completed: bills can\'t be added or edited, and nobody\'s book updates with it any more.'**
  String get eventCompletedNotice;

  /// No description provided for @eventErrCompleted.
  ///
  /// In en, this message translates to:
  /// **'This event is completed and can\'t be changed'**
  String get eventErrCompleted;

  /// No description provided for @eventErrNotActive.
  ///
  /// In en, this message translates to:
  /// **'Only an active event can be completed'**
  String get eventErrNotActive;

  /// No description provided for @eventErrEmptyPerson.
  ///
  /// In en, this message translates to:
  /// **'A bill still has an empty person slot: fill it before completing the event'**
  String get eventErrEmptyPerson;

  /// No description provided for @settingsGroupSync.
  ///
  /// In en, this message translates to:
  /// **'Auto update'**
  String get settingsGroupSync;

  /// No description provided for @settingsGroupPagePrefs.
  ///
  /// In en, this message translates to:
  /// **'Filters and sorting'**
  String get settingsGroupPagePrefs;

  /// No description provided for @settingsComingSoon.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get settingsComingSoon;

  /// No description provided for @settingsFontThai.
  ///
  /// In en, this message translates to:
  /// **'Thai font'**
  String get settingsFontThai;

  /// No description provided for @settingsFontEnglish.
  ///
  /// In en, this message translates to:
  /// **'English font'**
  String get settingsFontEnglish;

  /// No description provided for @settingsPreview.
  ///
  /// In en, this message translates to:
  /// **'Preview'**
  String get settingsPreview;

  /// No description provided for @settingsSectionNumbers.
  ///
  /// In en, this message translates to:
  /// **'Number display'**
  String get settingsSectionNumbers;

  /// No description provided for @settingsSectionEntryDefaults.
  ///
  /// In en, this message translates to:
  /// **'Entry defaults'**
  String get settingsSectionEntryDefaults;

  /// No description provided for @settingsFeeCategory.
  ///
  /// In en, this message translates to:
  /// **'Fee category'**
  String get settingsFeeCategory;

  /// No description provided for @settingsFeeCategoryHint.
  ///
  /// In en, this message translates to:
  /// **'Used for transfers with a fee'**
  String get settingsFeeCategoryHint;

  /// No description provided for @settingsSyncFootnote.
  ///
  /// In en, this message translates to:
  /// **'The same auto switches as on the event page and the person page: change them anywhere, it\'s one value'**
  String get settingsSyncFootnote;

  /// No description provided for @notifSettingsOnOffLegend.
  ///
  /// In en, this message translates to:
  /// **'Notify = send me a notification about it\nAuto (Events / Splits) = don\'t ask, just do it\nBoth off = no notification and nothing happens'**
  String get notifSettingsOnOffLegend;

  /// No description provided for @notifGroupSharedBills.
  ///
  /// In en, this message translates to:
  /// **'Shared bills'**
  String get notifGroupSharedBills;

  /// No description provided for @notifSetSplitChanged.
  ///
  /// In en, this message translates to:
  /// **'Someone edited a bill shared with me'**
  String get notifSetSplitChanged;

  /// No description provided for @notifSetSharedBillDeleted.
  ///
  /// In en, this message translates to:
  /// **'Someone deleted a bill shared with me'**
  String get notifSetSharedBillDeleted;

  /// No description provided for @notifSetSharedBillDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Someone disconnected a bill shared with me'**
  String get notifSetSharedBillDisconnected;

  /// No description provided for @notifSetSharedBillDisconnectedHint.
  ///
  /// In en, this message translates to:
  /// **'My bill stays, just no longer connected'**
  String get notifSetSharedBillDisconnectedHint;

  /// No description provided for @notifSetDebtDisconnectedHint.
  ///
  /// In en, this message translates to:
  /// **'My debt stays, just no longer connected'**
  String get notifSetDebtDisconnectedHint;

  /// No description provided for @notifSetEventCompleted.
  ///
  /// In en, this message translates to:
  /// **'Event completed'**
  String get notifSetEventCompleted;

  /// No description provided for @notifSetEventInvite.
  ///
  /// In en, this message translates to:
  /// **'Event invites'**
  String get notifSetEventInvite;

  /// No description provided for @notifSetEventInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Auto = join the event at once'**
  String get notifSetEventInviteHint;

  /// No description provided for @notifSetContactLink.
  ///
  /// In en, this message translates to:
  /// **'Contact link requests'**
  String get notifSetContactLink;

  /// No description provided for @notifSetContactLinkHint.
  ///
  /// In en, this message translates to:
  /// **'Auto = link to their contact at once'**
  String get notifSetContactLinkHint;

  /// No description provided for @notifSetWalletInvite.
  ///
  /// In en, this message translates to:
  /// **'Wallet invites'**
  String get notifSetWalletInvite;

  /// No description provided for @notifSetWalletInviteHint.
  ///
  /// In en, this message translates to:
  /// **'Auto = join the wallet at once'**
  String get notifSetWalletInviteHint;

  /// No description provided for @notifSetEventCompletedHint.
  ///
  /// In en, this message translates to:
  /// **'Locked for good, no more updates, claim once'**
  String get notifSetEventCompletedHint;

  /// No description provided for @notifSetEventMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'Removed from an event'**
  String get notifSetEventMemberRemoved;

  /// No description provided for @notifSetEventMemberRemovedHint.
  ///
  /// In en, this message translates to:
  /// **'What I booked stays, just no longer connected'**
  String get notifSetEventMemberRemovedHint;

  /// No description provided for @notifSetRecurringAutoCreatedHint.
  ///
  /// In en, this message translates to:
  /// **'Entries recorded for me on schedule'**
  String get notifSetRecurringAutoCreatedHint;

  /// No description provided for @notifActionAddToBook.
  ///
  /// In en, this message translates to:
  /// **'Add to my book'**
  String get notifActionAddToBook;

  /// No description provided for @notifActionRemoveMine.
  ///
  /// In en, this message translates to:
  /// **'Remove mine too'**
  String get notifActionRemoveMine;

  /// No description provided for @notifActionKeepMine.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get notifActionKeepMine;

  /// No description provided for @notifSharedBillCreated.
  ///
  /// In en, this message translates to:
  /// **'{who} recorded {what}, a bill you\'re in'**
  String notifSharedBillCreated(String who, String what);

  /// No description provided for @notifSharedBillDeleted.
  ///
  /// In en, this message translates to:
  /// **'{who} deleted the bill {what}'**
  String notifSharedBillDeleted(String who, String what);

  /// No description provided for @notifSharedBillDisconnected.
  ///
  /// In en, this message translates to:
  /// **'{who} disconnected from the bill {what}'**
  String notifSharedBillDisconnected(String who, String what);

  /// No description provided for @notifEventCompleted.
  ///
  /// In en, this message translates to:
  /// **'{who} completed the event {name}'**
  String notifEventCompleted(String who, String name);

  /// No description provided for @notifEventMemberRemoved.
  ///
  /// In en, this message translates to:
  /// **'{who} removed you from the event {name}'**
  String notifEventMemberRemoved(String who, String name);

  /// No description provided for @notifBillRemovedMine.
  ///
  /// In en, this message translates to:
  /// **'This bill\'s records were removed from your book'**
  String get notifBillRemovedMine;

  /// No description provided for @notifBillGone.
  ///
  /// In en, this message translates to:
  /// **'This bill was deleted'**
  String get notifBillGone;

  /// No description provided for @notifBillDisconnectedMine.
  ///
  /// In en, this message translates to:
  /// **'You disconnected this bill; connect again from the bill'**
  String get notifBillDisconnectedMine;

  /// No description provided for @txLinkDisconnectBodyCopy.
  ///
  /// In en, this message translates to:
  /// **'This entry and your debts from this bill become plain records you edit freely. The bill doesn\'t change and its edits won\'t reach you any more.'**
  String get txLinkDisconnectBodyCopy;

  /// No description provided for @evbEmptyPerson.
  ///
  /// In en, this message translates to:
  /// **'No one yet'**
  String get evbEmptyPerson;

  /// No description provided for @evbAssignMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get evbAssignMe;

  /// No description provided for @evbAssignTitle.
  ///
  /// In en, this message translates to:
  /// **'Who takes this spot'**
  String get evbAssignTitle;

  /// No description provided for @evbAssignWhose.
  ///
  /// In en, this message translates to:
  /// **'Whose spots'**
  String get evbAssignWhose;

  /// No description provided for @evbAssignAction.
  ///
  /// In en, this message translates to:
  /// **'Fill in'**
  String get evbAssignAction;

  /// No description provided for @evbAssigned.
  ///
  /// In en, this message translates to:
  /// **'Spot filled'**
  String get evbAssigned;

  /// No description provided for @evbEmptyPersonsNotice.
  ///
  /// In en, this message translates to:
  /// **'{count} bills have an empty spot from a removed member: fill them before completing the event'**
  String evbEmptyPersonsNotice(int count);

  /// No description provided for @evbBillChanged.
  ///
  /// In en, this message translates to:
  /// **'This bill was changed meanwhile; reloaded'**
  String get evbBillChanged;

  /// No description provided for @evbSplitBill.
  ///
  /// In en, this message translates to:
  /// **'Split bill'**
  String get evbSplitBill;

  /// No description provided for @fpRecurringKindDebt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get fpRecurringKindDebt;

  /// No description provided for @pagePrefSort.
  ///
  /// In en, this message translates to:
  /// **'Sort'**
  String get pagePrefSort;

  /// No description provided for @pagePrefFilter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get pagePrefFilter;

  /// No description provided for @pagePrefStatus.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get pagePrefStatus;

  /// No description provided for @pagePrefKind.
  ///
  /// In en, this message translates to:
  /// **'Kind'**
  String get pagePrefKind;

  /// No description provided for @pagePrefLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get pagePrefLink;

  /// No description provided for @pagePrefCollapsed.
  ///
  /// In en, this message translates to:
  /// **'Collapsed parents'**
  String get pagePrefCollapsed;

  /// No description provided for @pagePrefAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get pagePrefAll;

  /// No description provided for @pagePrefPendingManual.
  ///
  /// In en, this message translates to:
  /// **'Added by me'**
  String get pagePrefPendingManual;

  /// No description provided for @pagePrefPendingOthers.
  ///
  /// In en, this message translates to:
  /// **'From others'**
  String get pagePrefPendingOthers;

  /// No description provided for @pagePrefNone.
  ///
  /// In en, this message translates to:
  /// **'none'**
  String get pagePrefNone;

  /// No description provided for @pagePrefsChanged.
  ///
  /// In en, this message translates to:
  /// **'Changed'**
  String get pagePrefsChanged;

  /// No description provided for @pagePrefsCaption.
  ///
  /// In en, this message translates to:
  /// **'Picking on a page changes it here too\nTap to set it yourself'**
  String get pagePrefsCaption;

  /// No description provided for @pagePrefsFootnote.
  ///
  /// In en, this message translates to:
  /// **'Tabs, date ranges and search start fresh every time a page opens'**
  String get pagePrefsFootnote;

  /// No description provided for @pagePrefsResetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset all to defaults'**
  String get pagePrefsResetAll;

  /// No description provided for @pagePrefsResetAllBody.
  ///
  /// In en, this message translates to:
  /// **'Every page goes back to its default filters and sorting'**
  String get pagePrefsResetAllBody;

  /// No description provided for @pagePrefsResetPage.
  ///
  /// In en, this message translates to:
  /// **'Reset this page'**
  String get pagePrefsResetPage;

  /// No description provided for @pagePrefsSetOnPage.
  ///
  /// In en, this message translates to:
  /// **'Set on the page itself'**
  String get pagePrefsSetOnPage;

  /// No description provided for @evbClaimTitle.
  ///
  /// In en, this message translates to:
  /// **'Into my book: {name}'**
  String evbClaimTitle(String name);

  /// No description provided for @evbClaimTheyOwe.
  ///
  /// In en, this message translates to:
  /// **'{name} owes me'**
  String evbClaimTheyOwe(String name);

  /// No description provided for @evbClaimIOwe.
  ///
  /// In en, this message translates to:
  /// **'I owe {name}'**
  String evbClaimIOwe(String name);

  /// No description provided for @evbClaimPaybacks.
  ///
  /// In en, this message translates to:
  /// **'Paybacks / loans'**
  String get evbClaimPaybacks;

  /// No description provided for @evbClaimUntitled.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get evbClaimUntitled;

  /// No description provided for @evbClaimDone.
  ///
  /// In en, this message translates to:
  /// **'In my book'**
  String get evbClaimDone;

  /// No description provided for @evbClaimNote.
  ///
  /// In en, this message translates to:
  /// **'The picked bills become one debt with this person; bills someone else paid get a \"paid by\" entry of my share'**
  String get evbClaimNote;

  /// No description provided for @evbClaimConfirm.
  ///
  /// In en, this message translates to:
  /// **'Book {count} bills'**
  String evbClaimConfirm(int count);

  /// No description provided for @evbClaimed.
  ///
  /// In en, this message translates to:
  /// **'Booked with {name}'**
  String evbClaimed(String name);

  /// No description provided for @evbClaimNothing.
  ///
  /// In en, this message translates to:
  /// **'No bills left to book'**
  String get evbClaimNothing;

  /// No description provided for @evbClaimMixed.
  ///
  /// In en, this message translates to:
  /// **'Pick one side at a time: they owe me, or I owe them'**
  String get evbClaimMixed;

  /// No description provided for @evbClaimAlready.
  ///
  /// In en, this message translates to:
  /// **'Some bills are already in your book'**
  String get evbClaimAlready;

  /// No description provided for @evbMyCopy.
  ///
  /// In en, this message translates to:
  /// **'My book'**
  String get evbMyCopy;

  /// No description provided for @evbPaidByName.
  ///
  /// In en, this message translates to:
  /// **'Paid by {name}'**
  String evbPaidByName(String name);

  /// No description provided for @evbPaidBackName.
  ///
  /// In en, this message translates to:
  /// **'Paid {name} back'**
  String evbPaidBackName(String name);

  /// No description provided for @evbPrivateNote.
  ///
  /// In en, this message translates to:
  /// **'Private note'**
  String get evbPrivateNote;

  /// No description provided for @evbPrivateNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Only you see it'**
  String get evbPrivateNoteHint;

  /// No description provided for @evbCopyDisconnected.
  ///
  /// In en, this message translates to:
  /// **'Disconnected: this bill doesn\'t reach my book'**
  String get evbCopyDisconnected;

  /// No description provided for @evbReconnect.
  ///
  /// In en, this message translates to:
  /// **'Connect again'**
  String get evbReconnect;

  /// No description provided for @evbCopyOutOfSync.
  ///
  /// In en, this message translates to:
  /// **'My book doesn\'t match the bill'**
  String get evbCopyOutOfSync;

  /// No description provided for @evbApplyBill.
  ///
  /// In en, this message translates to:
  /// **'Update to match'**
  String get evbApplyBill;

  /// No description provided for @debtBillsTitle.
  ///
  /// In en, this message translates to:
  /// **'Bills in this debt'**
  String get debtBillsTitle;

  /// No description provided for @debtBillSplit.
  ///
  /// In en, this message translates to:
  /// **'Split bill'**
  String get debtBillSplit;

  /// No description provided for @debtBillOutOfSync.
  ///
  /// In en, this message translates to:
  /// **'Out of sync'**
  String get debtBillOutOfSync;

  /// No description provided for @evbJoinTitle.
  ///
  /// In en, this message translates to:
  /// **'Join which bill'**
  String get evbJoinTitle;

  /// No description provided for @evbJoinPaidBy.
  ///
  /// In en, this message translates to:
  /// **'{name} paid'**
  String evbJoinPaidBy(String name);

  /// No description provided for @evbJoined.
  ///
  /// In en, this message translates to:
  /// **'Joined the bill'**
  String get evbJoined;

  /// No description provided for @evbSettlePairs.
  ///
  /// In en, this message translates to:
  /// **'Real pairs'**
  String get evbSettlePairs;

  /// No description provided for @evbSettleSimplified.
  ///
  /// In en, this message translates to:
  /// **'Fewest transfers'**
  String get evbSettleSimplified;

  /// No description provided for @evbSettleBook.
  ///
  /// In en, this message translates to:
  /// **'Into my book'**
  String get evbSettleBook;

  /// No description provided for @evbSettleBookTitle.
  ///
  /// In en, this message translates to:
  /// **'Book it into my book once?'**
  String get evbSettleBookTitle;

  /// No description provided for @evbSettleBookBody.
  ///
  /// In en, this message translates to:
  /// **'The money that moves becomes entries, the bill debts you already booked are cleared to zero, and real pairs can\'t be booked any more.'**
  String get evbSettleBookBody;

  /// No description provided for @evbSettleBooked.
  ///
  /// In en, this message translates to:
  /// **'Booked into my book'**
  String get evbSettleBooked;

  /// No description provided for @evbSettleBookedOn.
  ///
  /// In en, this message translates to:
  /// **'Booked into my book on {date}'**
  String evbSettleBookedOn(String date);

  /// No description provided for @evbSettleAlreadyBooked.
  ///
  /// In en, this message translates to:
  /// **'Already booked'**
  String get evbSettleAlreadyBooked;

  /// No description provided for @evbBookLinePay.
  ///
  /// In en, this message translates to:
  /// **'Pay {name} {amount}'**
  String evbBookLinePay(String name, String amount);

  /// No description provided for @evbBookLineGet.
  ///
  /// In en, this message translates to:
  /// **'Receive from {name} {amount}'**
  String evbBookLineGet(String name, String amount);

  /// No description provided for @occurrenceNothingOwed.
  ///
  /// In en, this message translates to:
  /// **'Nothing is owed with this person now'**
  String get occurrenceNothingOwed;

  /// No description provided for @recurringPausedNoBalance.
  ///
  /// In en, this message translates to:
  /// **'Paused: nothing owed for 3 rounds | it starts again by itself with a new debt with this person'**
  String get recurringPausedNoBalance;

  /// No description provided for @recurringNoBalanceChip.
  ///
  /// In en, this message translates to:
  /// **'Nothing owed'**
  String get recurringNoBalanceChip;

  /// No description provided for @debtsPersonAddRecurring.
  ///
  /// In en, this message translates to:
  /// **'Make it recurring'**
  String get debtsPersonAddRecurring;

  /// No description provided for @occurrenceDebtPickEmpty.
  ///
  /// In en, this message translates to:
  /// **'No entries with this person to link'**
  String get occurrenceDebtPickEmpty;

  /// No description provided for @debtFromEventLabel.
  ///
  /// In en, this message translates to:
  /// **'From event bills'**
  String get debtFromEventLabel;

  /// No description provided for @debtFromEventPick.
  ///
  /// In en, this message translates to:
  /// **'Pick bills'**
  String get debtFromEventPick;

  /// No description provided for @txJoinBill.
  ///
  /// In en, this message translates to:
  /// **'Join a bill in an event'**
  String get txJoinBill;

  /// No description provided for @settingsAcceptTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto-accept new bills'**
  String get settingsAcceptTitle;

  /// No description provided for @settingsAutoEventInvites.
  ///
  /// In en, this message translates to:
  /// **'Accept event invites automatically'**
  String get settingsAutoEventInvites;

  /// No description provided for @settingsAutoContactLinks.
  ///
  /// In en, this message translates to:
  /// **'Accept contact link requests automatically'**
  String get settingsAutoContactLinks;

  /// No description provided for @settingsAutoWalletInvites.
  ///
  /// In en, this message translates to:
  /// **'Accept wallet invites automatically'**
  String get settingsAutoWalletInvites;

  /// No description provided for @settingsAutoRequestCaption.
  ///
  /// In en, this message translates to:
  /// **'For every request; also in Settings › Notifications'**
  String get settingsAutoRequestCaption;

  /// No description provided for @eventDeleteKeepsBills.
  ///
  /// In en, this message translates to:
  /// **'Only the event goes. Its bills stay as split bills, everyone stays connected, and nothing in anyone\'s book is deleted.'**
  String get eventDeleteKeepsBills;

  /// No description provided for @eventDeleteKeepsBillsShort.
  ///
  /// In en, this message translates to:
  /// **'Its bills stay, as split bills'**
  String get eventDeleteKeepsBillsShort;

  /// No description provided for @evbPayersLabel.
  ///
  /// In en, this message translates to:
  /// **'Paid by'**
  String get evbPayersLabel;

  /// No description provided for @evbPayers.
  ///
  /// In en, this message translates to:
  /// **'Payers | {count}'**
  String evbPayers(int count);

  /// No description provided for @evbAddPayer.
  ///
  /// In en, this message translates to:
  /// **'Add a payer'**
  String get evbAddPayer;

  /// No description provided for @evbPayersLine.
  ///
  /// In en, this message translates to:
  /// **'Paid by {payers}'**
  String evbPayersLine(String payers);

  /// No description provided for @settingsSectionSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsSectionSettings;

  /// No description provided for @settingsSectionData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsSectionData;

  /// No description provided for @settingsNotificationsSummary.
  ///
  /// In en, this message translates to:
  /// **'Notify {on} of {total} | Auto {auto}'**
  String settingsNotificationsSummary(int on, int total, int auto);

  /// No description provided for @settingsPagePrefsChangedSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No changes} =1{1 page changed} other{{count} pages changed}}'**
  String settingsPagePrefsChangedSummary(int count);

  /// No description provided for @settingsSectionAppearance.
  ///
  /// In en, this message translates to:
  /// **'Look'**
  String get settingsSectionAppearance;

  /// No description provided for @settingsSectionLanguageFont.
  ///
  /// In en, this message translates to:
  /// **'Language and fonts'**
  String get settingsSectionLanguageFont;

  /// No description provided for @settingsMoneyStyleHint.
  ///
  /// In en, this message translates to:
  /// **'How income / expense amounts are signed'**
  String get settingsMoneyStyleHint;

  /// No description provided for @settingsMoneyDecimalsHint.
  ///
  /// In en, this message translates to:
  /// **'Show the cents or not'**
  String get settingsMoneyDecimalsHint;

  /// No description provided for @notifColumnNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get notifColumnNotify;

  /// No description provided for @notifColumnAuto.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get notifColumnAuto;

  /// No description provided for @notifAutoAcceptHint.
  ///
  /// In en, this message translates to:
  /// **'Auto = put it in my book at once'**
  String get notifAutoAcceptHint;

  /// No description provided for @notifAutoUpdateHint.
  ///
  /// In en, this message translates to:
  /// **'Auto = update mine at once'**
  String get notifAutoUpdateHint;

  /// No description provided for @notifAutoDeleteHint.
  ///
  /// In en, this message translates to:
  /// **'Events: follows the Events switch of \"Someone edited a shared bill\"\nSplits: my copy always becomes a plain record'**
  String get notifAutoDeleteHint;

  /// No description provided for @notifSetRecurringDueHint.
  ///
  /// In en, this message translates to:
  /// **'Payments to pay / receive today'**
  String get notifSetRecurringDueHint;

  /// No description provided for @notifSetRecurringEndingHint.
  ///
  /// In en, this message translates to:
  /// **'The last payment is left'**
  String get notifSetRecurringEndingHint;

  /// No description provided for @settingsAutoTitle.
  ///
  /// In en, this message translates to:
  /// **'Auto'**
  String get settingsAutoTitle;

  /// No description provided for @settingsAutoEventsDescription.
  ///
  /// In en, this message translates to:
  /// **'For every event; set it in Settings › Notifications'**
  String get settingsAutoEventsDescription;

  /// No description provided for @settingsAutoDebtsDescription.
  ///
  /// In en, this message translates to:
  /// **'For everyone; set it in Settings › Notifications'**
  String get settingsAutoDebtsDescription;

  /// No description provided for @profileSectionAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileSectionAccount;

  /// No description provided for @pagePrefsResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get pagePrefsResetTitle;

  /// No description provided for @pagePrefsResetAllHint.
  ///
  /// In en, this message translates to:
  /// **'Every page back to its defaults'**
  String get pagePrefsResetAllHint;

  /// No description provided for @pagePrefsResetPageBody.
  ///
  /// In en, this message translates to:
  /// **'This page goes back to the default filters and sort'**
  String get pagePrefsResetPageBody;

  /// No description provided for @pagePrefSetCount.
  ///
  /// In en, this message translates to:
  /// **'{title} {count}'**
  String pagePrefSetCount(String title, int count);

  /// No description provided for @settingsMainWalletUnsetSummary.
  ///
  /// In en, this message translates to:
  /// **'No main wallet'**
  String get settingsMainWalletUnsetSummary;

  /// No description provided for @pagePrefsSectionPages.
  ///
  /// In en, this message translates to:
  /// **'Pages'**
  String get pagePrefsSectionPages;

  /// No description provided for @connectionConnectingAttempt.
  ///
  /// In en, this message translates to:
  /// **'Connecting… {attempt}/{attempts}'**
  String connectionConnectingAttempt(int attempt, int attempts);

  /// No description provided for @connectionCantConnect.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server'**
  String get connectionCantConnect;

  /// No description provided for @connectionsNotLinked.
  ///
  /// In en, this message translates to:
  /// **'Not linked'**
  String get connectionsNotLinked;

  /// No description provided for @connectionsPermissionChat.
  ///
  /// In en, this message translates to:
  /// **'Log entries by chat'**
  String get connectionsPermissionChat;

  /// No description provided for @connectionsPermissionAsk.
  ///
  /// In en, this message translates to:
  /// **'Ask for balances'**
  String get connectionsPermissionAsk;

  /// No description provided for @connectionsPermissionSlip.
  ///
  /// In en, this message translates to:
  /// **'Send slips'**
  String get connectionsPermissionSlip;

  /// No description provided for @connectionsPermissionNotify.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get connectionsPermissionNotify;

  /// No description provided for @connectionsPermissionLogin.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Google'**
  String get connectionsPermissionLogin;

  /// No description provided for @connectionsPermissionSheets.
  ///
  /// In en, this message translates to:
  /// **'Send entries to Sheets'**
  String get connectionsPermissionSheets;

  /// No description provided for @connectionsPermissionCalendar.
  ///
  /// In en, this message translates to:
  /// **'Put due dates in Calendar'**
  String get connectionsPermissionCalendar;

  /// No description provided for @connectionsErrorNoPhoto.
  ///
  /// In en, this message translates to:
  /// **'{name} didn\'t send a picture'**
  String connectionsErrorNoPhoto(String name);

  /// No description provided for @connectionsErrorLastLoginMethod.
  ///
  /// In en, this message translates to:
  /// **'Set a password first, or you won\'t be able to sign in'**
  String get connectionsErrorLastLoginMethod;

  /// No description provided for @avatarColorsTitle.
  ///
  /// In en, this message translates to:
  /// **'Colours & ring'**
  String get avatarColorsTitle;

  /// No description provided for @avatarColorsSlot.
  ///
  /// In en, this message translates to:
  /// **'Colour {n}'**
  String avatarColorsSlot(int n);

  /// No description provided for @avatarColorsRingColor.
  ///
  /// In en, this message translates to:
  /// **'Ring'**
  String get avatarColorsRingColor;

  /// No description provided for @avatarColorsClear.
  ///
  /// In en, this message translates to:
  /// **'Clear this colour'**
  String get avatarColorsClear;

  /// No description provided for @avatarBorderNone.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get avatarBorderNone;

  /// No description provided for @avatarBorderThin.
  ///
  /// In en, this message translates to:
  /// **'Thin'**
  String get avatarBorderThin;

  /// No description provided for @avatarBorderThick.
  ///
  /// In en, this message translates to:
  /// **'Thick'**
  String get avatarBorderThick;

  /// No description provided for @avatarBorderDashed.
  ///
  /// In en, this message translates to:
  /// **'Dashed'**
  String get avatarBorderDashed;

  /// No description provided for @profileSectionConnections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get profileSectionConnections;

  /// No description provided for @profileSectionPicture.
  ///
  /// In en, this message translates to:
  /// **'Profile picture'**
  String get profileSectionPicture;

  /// No description provided for @profileSetPassword.
  ///
  /// In en, this message translates to:
  /// **'Set a password'**
  String get profileSetPassword;

  /// No description provided for @profileSetPasswordSnackSuccess.
  ///
  /// In en, this message translates to:
  /// **'Password set'**
  String get profileSetPasswordSnackSuccess;

  /// No description provided for @profileUsernameReadOnly.
  ///
  /// In en, this message translates to:
  /// **'@{username} (can\'t change)'**
  String profileUsernameReadOnly(String username);

  /// No description provided for @profilePictureIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get profilePictureIcon;

  /// No description provided for @profilePictureUpload.
  ///
  /// In en, this message translates to:
  /// **'Upload'**
  String get profilePictureUpload;

  /// No description provided for @profilePictureEdit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get profilePictureEdit;

  /// No description provided for @profilePictureImportedAt.
  ///
  /// In en, this message translates to:
  /// **'Imported {date}'**
  String profilePictureImportedAt(String date);

  /// No description provided for @profileColorsLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile colours 1–3'**
  String get profileColorsLabel;

  /// No description provided for @connectionsTapToLink.
  ///
  /// In en, this message translates to:
  /// **'Tap to link'**
  String get connectionsTapToLink;

  /// No description provided for @connectionsSectionPermissions.
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get connectionsSectionPermissions;

  /// No description provided for @connectionsPhotoFrom.
  ///
  /// In en, this message translates to:
  /// **'Picture from {name}'**
  String connectionsPhotoFrom(String name);

  /// No description provided for @connectionsPhotoNotImported.
  ///
  /// In en, this message translates to:
  /// **'Not imported yet'**
  String get connectionsPhotoNotImported;

  /// No description provided for @connectionsPhotoUpdate.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get connectionsPhotoUpdate;

  /// No description provided for @connectionsPhotoImport.
  ///
  /// In en, this message translates to:
  /// **'Import'**
  String get connectionsPhotoImport;

  /// No description provided for @connectionsPhotoDeleteTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete the picture from {name}?'**
  String connectionsPhotoDeleteTitle(String name);

  /// No description provided for @connectionsPhotoDeleteInUse.
  ///
  /// In en, this message translates to:
  /// **'It\'s your profile picture; your icon is used after deleting'**
  String get connectionsPhotoDeleteInUse;

  /// No description provided for @connectionsChangeAccount.
  ///
  /// In en, this message translates to:
  /// **'Change {name} account'**
  String connectionsChangeAccount(String name);

  /// No description provided for @connectionsUnlink.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get connectionsUnlink;

  /// No description provided for @connectionsUnlinkTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlink {name}?'**
  String connectionsUnlinkTitle(String name);

  /// No description provided for @connectionsLink.
  ///
  /// In en, this message translates to:
  /// **'Link {name}'**
  String connectionsLink(String name);

  /// No description provided for @connectionsLinkedAt.
  ///
  /// In en, this message translates to:
  /// **'Linked {date}'**
  String connectionsLinkedAt(String date);

  /// No description provided for @connectionsOpenFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open {name}'**
  String connectionsOpenFailed(String name);

  /// No description provided for @notifSetBillCreated.
  ///
  /// In en, this message translates to:
  /// **'A new bill shared with me'**
  String get notifSetBillCreated;

  /// No description provided for @notifColumnAutoEvents.
  ///
  /// In en, this message translates to:
  /// **'Events'**
  String get notifColumnAutoEvents;

  /// No description provided for @notifColumnAutoSplit.
  ///
  /// In en, this message translates to:
  /// **'Splits'**
  String get notifColumnAutoSplit;
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
