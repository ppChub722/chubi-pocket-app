// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'chubiPocket';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonSave => 'Save';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonRemove => 'Remove';

  @override
  String get commonOk => 'OK';

  @override
  String get commonBack => 'Back';

  @override
  String get commonClose => 'Close';

  @override
  String get errorNetworkTitle => 'No connection';

  @override
  String get errorNetworkMessage => 'Check your internet and try again.';

  @override
  String get errorServerTitle => 'Something went wrong';

  @override
  String get errorServerMessage =>
      'Our servers had a hiccup. Please try again.';

  @override
  String get errorUnknownTitle => 'Unexpected error';

  @override
  String get errorUnknownMessage =>
      'Something we did not expect happened. Please try again.';

  @override
  String get errorBannerNoConnection => 'No connection. Check your internet.';

  @override
  String get errorBannerNoConnectionShort => 'No connection. Try again.';

  @override
  String get offlineBanner => 'You\'re offline';

  @override
  String get authLoginTitle => 'Log in';

  @override
  String get authLoginIdentifierLabel => 'Username or email';

  @override
  String get authLoginPasswordLabel => 'Password';

  @override
  String get authLoginSubmit => 'Log in';

  @override
  String get authLoginInvalidCredentials => 'Username or password incorrect';

  @override
  String get authLoginGoToRegister => 'Don\'t have an account? Register';

  @override
  String get authRegisterTitle => 'Create account';

  @override
  String get authRegisterUsernameLabel => 'Username';

  @override
  String get authRegisterUsernameInvalid =>
      '3–50 chars; lowercase a–z, 0–9, _, -';

  @override
  String get authRegisterDisplayNameLabel => 'Display name';

  @override
  String get authRegisterDisplayNameTooLong => 'Max 100 characters';

  @override
  String get authRegisterEmailLabel => 'Email (optional)';

  @override
  String get authRegisterPasswordLabel => 'Password';

  @override
  String get authRegisterPasswordTooShort => 'At least 8 characters';

  @override
  String get authRegisterPasswordTooLong => 'Max 128 characters';

  @override
  String get authRegisterConfirmLabel => 'Confirm password';

  @override
  String get authRegisterConfirmMismatch => 'Passwords don\'t match';

  @override
  String get authRegisterCurrencyLabel => 'Currency';

  @override
  String get authRegisterSubmit => 'Create account';

  @override
  String get authRegisterGoToLogin => 'Already have an account? Log in';

  @override
  String get authRegisterUsernameTaken => 'That username is already taken.';

  @override
  String get authRegisterEmailTaken => 'That email is already registered.';

  @override
  String get authRegisterFixErrors => 'Please fix the errors below.';

  @override
  String get authRegisterUsernameTakenInline => 'Already taken';

  @override
  String get authRegisterEmailTakenInline => 'Already registered';

  @override
  String get homeEmptyTitle => 'Nothing to show yet';

  @override
  String get homeEmptyMessage =>
      'Phase 0 home — feature modules (accounts, transactions, budgets) land in Phase 1.';

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navAccounts => 'Accounts';

  @override
  String get navAddTransaction => 'Add transaction';

  @override
  String get navProjects => 'Projects';

  @override
  String get navMore => 'More';

  @override
  String get navNotificationsTooltip => 'Notifications';

  @override
  String get navProfileTooltip => 'Profile & settings';

  @override
  String get addTransactionComingSoon =>
      'Logging transactions ships in Phase 1a';

  @override
  String get notificationsComingSoon =>
      'The notifications inbox ships in Phase 1b';

  @override
  String get accountsPlaceholderTitle => 'No accounts yet';

  @override
  String get accountsPlaceholderMessage => 'Adding accounts ships in Phase 1a.';

  @override
  String get accountsAddNew => 'Add account';

  @override
  String get accountTypeCash => 'Cash';

  @override
  String get accountTypeBank => 'Bank';

  @override
  String get accountTypeEWallet => 'E-wallet';

  @override
  String get accountTypeCreditCard => 'Credit card';

  @override
  String get accountTypePayLater => 'Pay later';

  @override
  String accountCreditUsedPercent(int percent) {
    return '$percent% used';
  }

  @override
  String get accountDetailNotFound => 'Account not found';

  @override
  String get accountDetailNotFoundMessage =>
      'This account may have been archived or deleted.';

  @override
  String get accountDetailEdit => 'Edit';

  @override
  String get accountDetailAdjustBalance => 'Adjust balance';

  @override
  String get accountDetailArchive => 'Archive';

  @override
  String get accountDetailActionComingSoon => 'This action ships in Phase 1a';

  @override
  String accountDetailCreditAvailable(String available, String limit) {
    return '$available available of $limit';
  }

  @override
  String get accountDetailSummaryTitle => 'Last 30 days';

  @override
  String get accountDetailSummaryIncome => 'Income';

  @override
  String get accountDetailSummaryExpense => 'Expense';

  @override
  String get accountDetailSummaryNet => 'Net';

  @override
  String accountDetailSummaryTransactions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
      zero: 'No transactions',
    );
    return '$_temp0';
  }

  @override
  String get accountDetailBillingTitle => 'Billing';

  @override
  String get accountDetailStatementDate => 'Statement date';

  @override
  String get accountDetailPaymentDue => 'Payment due';

  @override
  String get accountDetailMinimumPayment => 'Minimum payment';

  @override
  String accountDetailDayOfMonth(int day) {
    return '$day of every month';
  }

  @override
  String get accountDetailTransactionsTitle => 'Transactions';

  @override
  String get accountDetailTransactionsEmptyTitle => 'No transactions yet';

  @override
  String get accountDetailTransactionsEmptyMessage =>
      'Logging transactions ships in Phase 1a.';

  @override
  String get accountFormTitle => 'New account';

  @override
  String get accountFormPreviewLabel => 'Preview';

  @override
  String get accountFormTypeLabel => 'Type';

  @override
  String get accountFormNameLabel => 'Account name';

  @override
  String get accountFormNameRequired => 'Required';

  @override
  String get accountFormNameTooLong => 'Max 100 characters';

  @override
  String get accountFormIconLabel => 'Icon';

  @override
  String get accountFormColorLabel => 'Color';

  @override
  String get accountFormUploadLogo => 'Upload custom logo (Phase 2)';

  @override
  String get accountFormBalanceLabel => 'Opening balance';

  @override
  String get accountFormBalanceHelper =>
      'Money already in this account on the day you start tracking.';

  @override
  String get accountFormCreditSection => 'Credit details';

  @override
  String get accountFormCreditLimitLabel => 'Credit limit';

  @override
  String get accountFormCreditLimitRequired => 'Required for credit accounts';

  @override
  String get accountFormStatementDateLabel => 'Statement date';

  @override
  String get accountFormStatementDateHelper => 'Day of month (1–31)';

  @override
  String get accountFormPaymentDueLabel => 'Payment due';

  @override
  String get accountFormPaymentDueHelper => 'Day of month (1–31)';

  @override
  String get accountFormMinimumPaymentLabel => 'Minimum payment';

  @override
  String get accountFormDayInvalid => 'Must be 1–31';

  @override
  String get accountFormSave => 'Save account';

  @override
  String get accountFormDiscardTitle => 'Discard new account?';

  @override
  String get accountFormDiscardBody => 'Your changes will be lost.';

  @override
  String get accountFormCurrencyLabel => 'Currency';

  @override
  String get accountFormCurrencyPhase2 => 'Multi-currency ships in Phase 2';

  @override
  String get accountFormPhase2Badge => 'Phase 2';

  @override
  String get accountFormNoteLabel => 'Note';

  @override
  String get accountFormNoteHelper =>
      'Optional — context only you see (e.g. \"Travel money for Japan trip\").';

  @override
  String get accountFormNoteTooLong => 'Max 500 characters';

  @override
  String get iconPickerSectionStyle => 'Style';

  @override
  String get iconPickerSectionColor => 'Color';

  @override
  String get iconPickerUseThis => 'Use this';

  @override
  String get iconPickerRemove => 'Remove';

  @override
  String get iconPickerUploadComingSoon => 'Upload (Phase 2)';

  @override
  String get iconPickerCropComingSoon => 'Crop (Phase 2)';

  @override
  String get projectsPlaceholderTitle => 'No projects yet';

  @override
  String get projectsPlaceholderMessage => 'Shared projects ship in Phase 1b.';

  @override
  String get moreSheetTitle => 'More';

  @override
  String get morePhase1aHeader => 'Phase 1a — coming soon';

  @override
  String get morePhase1bHeader => 'Phase 1b — coming soon';

  @override
  String get morePhase1cHeader => 'Phase 1c — coming soon';

  @override
  String get moreTransactions => 'Transactions';

  @override
  String get moreCategories => 'Categories';

  @override
  String get moreTags => 'Tags';

  @override
  String get moreContacts => 'Contacts';

  @override
  String get moreDebts => 'Debts';

  @override
  String get moreNotifications => 'Notifications';

  @override
  String get moreBudgets => 'Budgets';

  @override
  String get moreSavingGoals => 'Saving goals';

  @override
  String get moreScheduled => 'Scheduled transactions';

  @override
  String get moreComingSoonBadge => 'Soon';

  @override
  String get moreComingInPhase1a => 'Ships in Phase 1a';

  @override
  String get moreComingInPhase1b => 'Ships in Phase 1b';

  @override
  String get moreComingInPhase1c => 'Ships in Phase 1c';

  @override
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesSectionExpense => 'Expense';

  @override
  String get categoriesSectionIncome => 'Income';

  @override
  String get categoriesEmptyTitle => 'No categories yet';

  @override
  String get categoriesEmptyMessage =>
      'Add your first category to start organizing transactions.';

  @override
  String get categoriesLimitReached =>
      '100-category limit reached. Archive or delete one to add another.';

  @override
  String get categoryTypeExpense => 'Expense';

  @override
  String get categoryTypeIncome => 'Income';

  @override
  String get categoryHiddenFromReport => 'Hidden from reports';

  @override
  String get categoryFormTitleNew => 'New category';

  @override
  String get categoryFormTitleEdit => 'Edit category';

  @override
  String get categoryFormBadge => 'Category';

  @override
  String get categoryFormPreviewLabel => 'Preview';

  @override
  String get categoryFormNameLabel => 'Name';

  @override
  String get categoryFormNameRequired => 'Required';

  @override
  String get categoryFormNameTooLong => 'Max 100 characters';

  @override
  String get categoryFormNameDuplicate =>
      'Another category at this level already uses this name';

  @override
  String get categoryFormTypeLabel => 'Type';

  @override
  String get categoryFormTypeImmutableHelper =>
      'Type can\'t be changed after creation. Delete and recreate to switch.';

  @override
  String get categoryFormParentLabel => 'Parent';

  @override
  String get categoryFormParentNone => '(None — top level)';

  @override
  String get categoryFormParentDepthHint =>
      'Categories can nest up to 3 levels deep.';

  @override
  String get categoryFormIconLabel => 'Icon';

  @override
  String get categoryFormColorLabel => 'Color';

  @override
  String get categoryFormDescriptionLabel => 'Description';

  @override
  String get categoryFormDescriptionHelper =>
      'What this category is for. Visible to you only.';

  @override
  String get categoryFormDescriptionTooLong => 'Max 200 characters';

  @override
  String get categoryFormNoteLabel => 'Note';

  @override
  String get categoryFormNoteHelper =>
      'Personal scratch note (e.g. \"Don\'t use for snacks\").';

  @override
  String get categoryFormNoteTooLong => 'Max 200 characters';

  @override
  String get categoryFormIncludeInReportLabel => 'Include in reports';

  @override
  String get categoryFormIncludeInReportHelper =>
      'Off = transactions in this category are excluded from totals and charts.';

  @override
  String get categoryFormSave => 'Save category';

  @override
  String get categoryFormDiscardTitle => 'Discard changes?';

  @override
  String get categoryFormDiscardBody => 'Your edits will be lost.';

  @override
  String get categoriesAddNew => 'Add category';

  @override
  String get categoriesReorderEnter => 'Reorder';

  @override
  String get categoriesReorderSave => 'Save';

  @override
  String get categoriesReorderDiscard => 'Discard';

  @override
  String get categoriesReorderHint =>
      'Drag to reorder. Drop near another category to move under its parent.';

  @override
  String get categoriesUndo => 'Undo';

  @override
  String get categoriesReorderTooDeep =>
      'That move would exceed the 3-level limit';

  @override
  String get categoriesReorderCycle =>
      'Can\'t drop a category into its own descendant';

  @override
  String get categoriesReorderCancel => 'Cancel';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsSectionAccount => 'Account';

  @override
  String get settingsSectionPreferences => 'Preferences';

  @override
  String get settingsSectionAbout => 'About';

  @override
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsDefaultCurrency => 'Default currency';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsFont => 'Font';

  @override
  String get settingsAppVersion => 'App version';

  @override
  String get settingsAppVersionValue => 'Phase 0 (1.0.0+1)';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLogoutDialogTitle => 'Log out of ChubiPocket?';

  @override
  String get settingsLogoutDialogBody =>
      'You will be returned to the login screen.';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileDisplayNameLabel => 'Display name';

  @override
  String get editProfileCurrencyLabel => 'Default currency';

  @override
  String get editProfileCurrencyHelper =>
      'Used as default for new transactions. Existing transactions keep their original currency.';

  @override
  String get editProfileAvatarUrlLabel => 'Avatar URL (optional)';

  @override
  String get editProfileAvatarUrlHelper =>
      'Phase 0: paste a URL or leave blank for initials.';

  @override
  String get editProfileUsernameLabel => 'Username';

  @override
  String get editProfileEmailLabel => 'Email';

  @override
  String get editProfileReadOnlyHelper => 'Cannot be changed in this version';

  @override
  String get editProfileEmailNone => '—';

  @override
  String get editProfileSnackSuccess => 'Profile updated';

  @override
  String get editProfileDiscardTitle => 'Discard changes?';

  @override
  String get editProfileDiscardBody => 'Your edits will be lost.';

  @override
  String get editProfileDiscardKeep => 'Keep editing';

  @override
  String get editProfileDiscardConfirm => 'Discard';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get changePasswordCurrentLabel => 'Current password';

  @override
  String get changePasswordNewLabel => 'New password';

  @override
  String get changePasswordNewHelper => 'At least 8 characters';

  @override
  String get changePasswordConfirmLabel => 'Confirm new password';

  @override
  String get changePasswordCurrentWrong => 'Current password is incorrect';

  @override
  String get changePasswordNewMustDiffer => 'Must differ from current password';

  @override
  String get changePasswordConfirmMismatch => 'Doesn\'t match new password';

  @override
  String get changePasswordSubmit => 'Update password';

  @override
  String get changePasswordSnackSuccess => 'Password updated';

  @override
  String get avatarPickerStyleLabel => 'Style';

  @override
  String get avatarPickerColorLabel => 'Color';

  @override
  String get avatarPickerUseThis => 'Use this';

  @override
  String get avatarPickerUploadDisabled => 'Upload (Phase 2)';

  @override
  String get avatarPickerCropDisabled => 'Crop (Phase 2)';

  @override
  String get avatarPresetInitials => 'Initials';

  @override
  String get avatarPresetMale => 'Male';

  @override
  String get avatarPresetFemale => 'Female';

  @override
  String get avatarPresetChubby => 'Chubby';

  @override
  String get avatarPresetSnacker => 'Snacker';

  @override
  String get avatarPresetStrong => 'Strong';

  @override
  String get avatarColorRed => 'Red';

  @override
  String get avatarColorGreen => 'Green';

  @override
  String get avatarColorBlue => 'Blue';

  @override
  String get avatarColorTeal => 'Teal';

  @override
  String get avatarColorPink => 'Pink';

  @override
  String get previewTitle => 'Core Preview';

  @override
  String get sectionTheme => 'Theme';

  @override
  String get sectionMode => 'Mode';

  @override
  String get sectionLanguage => 'Language';

  @override
  String get sectionFont => 'Font';

  @override
  String get sectionCurrentSelection => 'Current selection';

  @override
  String get sectionTypographySamples => 'Typography samples';

  @override
  String get sectionSemanticColors => 'Semantic colors';

  @override
  String get sectionFormatters => 'Formatters';

  @override
  String get sectionControls => 'Controls';

  @override
  String get sectionInput => 'Input';

  @override
  String get sectionCard => 'Card';

  @override
  String get modeLight => 'Light';

  @override
  String get modeDark => 'Dark';

  @override
  String get modeSystem => 'System';

  @override
  String fontsAvailableFor(int count, String lang) {
    return '$count available for \"$lang\"';
  }

  @override
  String get amountLabel => 'Amount';

  @override
  String get amountHint => '0.00';

  @override
  String get monthlyBalance => 'Monthly balance';
}
