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
      'Add an account from the Accounts tab, then tap the + button to log your first transaction.';

  @override
  String get homeNetWorthLabel => 'Net worth';

  @override
  String homeNetWorthAccountCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count accounts',
      one: '1 account',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentTitle => 'Recent transactions';

  @override
  String get homeRecentViewAll => 'View all';

  @override
  String get homeSettingsTooltip => 'Settings';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navTransactions => 'Transactions';

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
  String get accountDetailSummaryTitle => 'Summary';

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
  String get accountFormTitleEdit => 'Edit account';

  @override
  String get accountFormSaveEdit => 'Save changes';

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
  String get accountFormDiscardTitleEdit => 'Discard changes?';

  @override
  String get accountAdjustBalanceTitle => 'Adjust balance';

  @override
  String get accountAdjustBalanceBody =>
      'Set a new balance. The difference will be recorded as an Adjustment transaction so the history stays consistent.';

  @override
  String get accountAdjustBalanceCurrentLabel => 'Current balance';

  @override
  String get accountAdjustBalanceNewLabel => 'New balance';

  @override
  String get accountAdjustBalanceNoteLabel => 'Note (optional)';

  @override
  String get accountAdjustBalanceInvalidAmount => 'Enter a number';

  @override
  String get accountAdjustBalanceNoChange =>
      'New balance must differ from the current balance.';

  @override
  String get accountAdjustBalanceConfirm => 'Adjust';

  @override
  String get accountArchiveConfirmTitle => 'Archive this account?';

  @override
  String get accountArchiveConfirmBody =>
      'The account will be hidden from the active list. Its transactions stay intact and remain referenced.';

  @override
  String get accountArchiveConfirmAction => 'Archive';

  @override
  String get accountFormCurrencyLabel => 'Currency';

  @override
  String get accountFormCurrencyPhase2 => 'Multi-currency ships in Phase 2';

  @override
  String get accountFormPhase2Badge => 'Phase 2';

  @override
  String get accountFormDescriptionLabel => 'Description';

  @override
  String get accountFormDescriptionHelper =>
      'What this account is for. Visible to you only.';

  @override
  String get accountFormDescriptionTooLong => 'Max 200 characters';

  @override
  String get accountFormNoteLabel => 'Note';

  @override
  String get accountFormNoteHelper =>
      'Personal scratch note (e.g. \"Travel money for Japan trip\").';

  @override
  String get accountFormNoteTooLong => 'Max 200 characters';

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
  String get moreProjects => 'Projects';

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
  String get tagsTitle => 'Tags';

  @override
  String get tagsEmptyTitle => 'No tags yet';

  @override
  String get tagsEmptyMessage =>
      'Tag transactions to slice your spending however you want.';

  @override
  String get tagsAddNew => 'Add tag';

  @override
  String tagsUsageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '×$count',
      one: '×1',
      zero: '',
    );
    return '$_temp0';
  }

  @override
  String get tagDeleteConfirmTitle => 'Delete tag?';

  @override
  String get tagDeleteConfirmBody =>
      'Removes the tag from any transactions using it. This can\'t be undone.';

  @override
  String get tagDeleteConfirmAction => 'Delete';

  @override
  String get tagFormTitleNew => 'New tag';

  @override
  String get tagFormTitleEdit => 'Edit tag';

  @override
  String get tagFormPreviewLabel => 'Preview';

  @override
  String get tagFormNameLabel => 'Name';

  @override
  String get tagFormNameRequired => 'Required';

  @override
  String get tagFormNameTooLong => 'Max 50 characters';

  @override
  String get tagFormNameDuplicate => 'Another tag already uses this name';

  @override
  String get tagFormIconLabel => 'Icon';

  @override
  String get tagFormColorLabel => 'Color';

  @override
  String get tagFormSave => 'Save tag';

  @override
  String get tagFormDiscardTitle => 'Discard changes?';

  @override
  String get tagFormDiscardBody => 'Your edits will be lost.';

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
  String get editProfileEmailHelper =>
      'Used as your account ID and as the matching key when other people send you a contact link request.';

  @override
  String get editProfileEmailInvalid => 'Enter a valid email address.';

  @override
  String get editProfileEmailTooLong => 'Email is too long.';

  @override
  String get editProfileEmailTaken =>
      'That email is already registered to another account.';

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

  @override
  String get transactionFormTitleNew => 'New transaction';

  @override
  String get transactionFormTitleEdit => 'Edit transaction';

  @override
  String get transactionTypeExpense => 'Expense';

  @override
  String get transactionTypeIncome => 'Income';

  @override
  String get transactionTypeTransfer => 'Transfer';

  @override
  String get transactionFormAccountLabel => 'Account';

  @override
  String get transactionFormFromAccountLabel => 'From account';

  @override
  String get transactionFormToAccountLabel => 'To account';

  @override
  String get transactionFormAccountRequired => 'Pick an account';

  @override
  String get transactionFormAccountSameError =>
      'Source and destination must differ';

  @override
  String get transactionFormCategoryLabel => 'Category';

  @override
  String get transactionFormCategoryNone => 'Uncategorized';

  @override
  String get transactionFormTransferCategoryHint =>
      'Auto-set to Transfer In/Out';

  @override
  String get transactionFormDateLabel => 'Date';

  @override
  String get transactionFormAmountLabel => 'Amount';

  @override
  String get transactionFormAmountRequired => 'Required';

  @override
  String get transactionFormAmountInvalid => 'Enter a valid number';

  @override
  String get transactionFormAmountTooSmall => 'Must be greater than 0';

  @override
  String get transactionFormNoteLabel => 'Note (optional)';

  @override
  String get transactionFormNoteAddLabel => '+ Add note';

  @override
  String get transactionFormTagsLabel => 'Tags';

  @override
  String get transactionFormTagsEmpty =>
      'No tags yet. Create one from the Tags page.';

  @override
  String get transactionFormSave => 'Save';

  @override
  String get transactionFormSaveAndAddAnother => 'Save & add another';

  @override
  String get transactionFormSavedAddedAnother => 'Saved. Add another below.';

  @override
  String get transactionFormAccountPickerTitle => 'Pick an account';

  @override
  String get transactionFormAccountPickerEmpty =>
      'No active accounts. Create one first.';

  @override
  String get transactionFormCategoryPickerTitle => 'Pick a category';

  @override
  String get transactionFormCategoryPickerNoneOption => 'Uncategorized';

  @override
  String get transactionFormCategoryPickerEmpty =>
      'No categories of this type yet.';

  @override
  String get transactionFormDiscardTitle => 'Discard transaction?';

  @override
  String get transactionFormDiscardTitleEdit => 'Discard changes?';

  @override
  String get transactionFormDiscardBody => 'Your changes will be lost.';

  @override
  String get transactionDetailEdit => 'Edit';

  @override
  String get transactionDetailDelete => 'Delete';

  @override
  String get transactionDetailNotFound => 'Transaction not found';

  @override
  String get transactionDetailNotFoundMessage =>
      'This transaction may have been deleted.';

  @override
  String get transactionDetailDeleteConfirmTitle => 'Delete this transaction?';

  @override
  String get transactionDetailDeleteConfirmTitleTransfer =>
      'Delete this transfer?';

  @override
  String get transactionDetailDeleteConfirmBody =>
      'This will reverse the balance change on the account.';

  @override
  String get transactionDetailDeleteConfirmBodyTransfer =>
      'Both rows of the transfer will be deleted and balances on both accounts will reverse.';

  @override
  String get transactionDetailDeleteConfirmAction => 'Delete';

  @override
  String get transactionDetailTransferReadonlyHint =>
      'To change accounts, delete and create a new transfer.';

  @override
  String get transactionDetailSystemRowBanner =>
      'Auto-created — to change this, use the matching account-level action (account edit, or Adjust balance).';

  @override
  String get transactionsRangeWeek => 'This week';

  @override
  String get transactionsRangeMonth => 'This month';

  @override
  String get transactionsRangeYear => 'This year';

  @override
  String get transactionsRangeAll => 'All';

  @override
  String get transactionsEmptyAccountTitle => 'No transactions yet';

  @override
  String get transactionsEmptyAccountMessage => 'Tap the + button to add one.';

  @override
  String get transactionsListTitle => 'Transactions';

  @override
  String get transactionsListFilterAll => 'All';

  @override
  String get transactionsListFilterCategoryAll => 'All categories';

  @override
  String get transactionsListEmptyMessage =>
      'No transactions match these filters.';

  @override
  String get transactionsListRetry => 'Retry';

  @override
  String get transactionsListDateToday => 'Today';

  @override
  String get transactionsListDateYesterday => 'Yesterday';

  @override
  String get accountAdjustBalanceViewTransaction => 'View';

  @override
  String get accountAdjustBalanceSuccess => 'Balance adjusted';

  @override
  String get savingGoalsTitle => 'Saving goals';

  @override
  String get savingGoalsAddNew => 'Add saving goal';

  @override
  String get savingGoalsEmptyTitle => 'No saving goals yet';

  @override
  String get savingGoalsEmptyMessage =>
      'Set a target on top of an account and track your progress as the balance grows.';

  @override
  String savingGoalProgressLine(String current, String target) {
    return '$current of $target';
  }

  @override
  String get savingGoalCompletedLabel => 'Goal reached';

  @override
  String get savingGoalFormTitle => 'New saving goal';

  @override
  String get savingGoalFormTitleEdit => 'Edit saving goal';

  @override
  String get savingGoalFormSave => 'Create goal';

  @override
  String get savingGoalFormSaveEdit => 'Save changes';

  @override
  String get savingGoalFormIconLabel => 'Icon';

  @override
  String get savingGoalFormNameLabel => 'Goal name';

  @override
  String get savingGoalFormNameRequired => 'Required';

  @override
  String get savingGoalFormLinkedAccountLabel => 'Linked account';

  @override
  String get savingGoalFormLinkedAccountHelper =>
      'Progress = account balance × allocation %';

  @override
  String get savingGoalFormLinkedAccountLockedHelper =>
      'Linked account can\'t be changed. Delete and recreate to switch accounts.';

  @override
  String get savingGoalFormAccountRequired => 'Pick a linked account';

  @override
  String get savingGoalFormTargetLabel => 'Target amount';

  @override
  String get savingGoalFormTargetInvalid => 'Enter a positive amount';

  @override
  String get savingGoalFormAllocationLabel => 'Allocation';

  @override
  String get savingGoalFormAllocationHelper =>
      'Leave blank to let the server suggest a default. Total per account ≤ 100%.';

  @override
  String get savingGoalFormAllocationInvalid => 'Must be between 0 and 100';

  @override
  String get savingGoalFormDeadlineLabel => 'Deadline';

  @override
  String get savingGoalFormDeadlinePlaceholder => 'Optional';

  @override
  String get savingGoalFormNoteLabel => 'Note';

  @override
  String get savingGoalDetailNotFound => 'Goal not found';

  @override
  String get savingGoalDetailNotFoundMessage =>
      'This saving goal may have been deleted or archived.';

  @override
  String get savingGoalDetailEdit => 'Edit';

  @override
  String get savingGoalDetailArchive => 'Archive';

  @override
  String get savingGoalDetailDelete => 'Delete';

  @override
  String savingGoalDetailOfTarget(String target) {
    return 'of $target';
  }

  @override
  String get savingGoalDetailAllocation => 'Allocation';

  @override
  String get savingGoalDetailRemaining => 'Remaining';

  @override
  String get savingGoalDetailDeadline => 'Deadline';

  @override
  String get savingGoalDetailDaysRemaining => 'Days remaining';

  @override
  String savingGoalDetailDaysValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get savingGoalDetailRequiredMonthly => 'Suggested monthly';

  @override
  String get savingGoalArchiveConfirmTitle => 'Archive this goal?';

  @override
  String get savingGoalArchiveConfirmBody =>
      'Archiving frees its allocation slot on the linked account. You can restore it later if capacity is available.';

  @override
  String get savingGoalArchiveConfirmAction => 'Archive';

  @override
  String get savingGoalDeleteConfirmTitle => 'Delete this goal?';

  @override
  String get savingGoalDeleteConfirmBody =>
      'This permanently removes the goal. The linked account and its transactions are unaffected.';

  @override
  String get savingGoalDeleteConfirmAction => 'Delete';

  @override
  String get budgetsTitle => 'Budgets';

  @override
  String get budgetsAddNew => 'Add budget';

  @override
  String get budgetsEmptyTitle => 'No budgets yet';

  @override
  String get budgetsEmptyMessage =>
      'Set a per-category limit and we\'ll track your spending against it each period.';

  @override
  String get budgetPeriodWeekly => 'Weekly';

  @override
  String get budgetPeriodMonthly => 'Monthly';

  @override
  String get budgetPeriodYearly => 'Yearly';

  @override
  String budgetSpentLine(String spent, String limit) {
    return '$spent of $limit';
  }

  @override
  String get budgetFormTitle => 'New budget';

  @override
  String get budgetFormTitleEdit => 'Edit budget';

  @override
  String get budgetFormSave => 'Create budget';

  @override
  String get budgetFormSaveEdit => 'Save changes';

  @override
  String get budgetFormCategoryLabel => 'Category';

  @override
  String get budgetFormCategoryPlaceholder => 'Pick a category';

  @override
  String get budgetFormCategoryHelper =>
      'Only expense categories. Picking a parent tracks all its sub-categories.';

  @override
  String get budgetFormCategoryLockedHelper =>
      'Category can\'t be changed. Delete and recreate to switch categories.';

  @override
  String get budgetFormCategoryRequired => 'Pick a category';

  @override
  String get budgetFormDescriptionLabel => 'Description';

  @override
  String get budgetFormDescriptionHelper =>
      'Optional. Shown as the budget\'s title; falls back to the category name when blank.';

  @override
  String get budgetFormDescriptionTooLong => 'Max 200 characters';

  @override
  String get budgetFormAmountLabel => 'Limit per period';

  @override
  String get budgetFormAmountInvalid => 'Enter a positive amount';

  @override
  String get budgetFormPeriodLabel => 'Period';

  @override
  String get budgetFormNoteLabel => 'Note';

  @override
  String get budgetFormNoteHelper =>
      'Optional. Longer free-form note shown on the detail page.';

  @override
  String get budgetDetailNotFound => 'Budget not found';

  @override
  String get budgetDetailNotFoundMessage =>
      'This budget may have been deleted or archived.';

  @override
  String get budgetDetailFallbackTitle => 'Budget';

  @override
  String get budgetDetailEdit => 'Edit';

  @override
  String get budgetDetailArchive => 'Archive';

  @override
  String get budgetDetailDelete => 'Delete';

  @override
  String budgetDetailOfLimit(String limit) {
    return 'of $limit';
  }

  @override
  String budgetDetailRemainingLine(String amount) {
    return '$amount left';
  }

  @override
  String budgetDetailPeriodRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get budgetDetailOverLimitWarning =>
      'You\'ve gone over the limit for this period.';

  @override
  String get budgetDetailBreakdownTitle => 'Spend by category';

  @override
  String get budgetArchiveConfirmTitle => 'Archive this budget?';

  @override
  String get budgetArchiveConfirmBody =>
      'Archiving hides the budget from your active list. You can restore it later.';

  @override
  String get budgetArchiveConfirmAction => 'Archive';

  @override
  String get budgetDeleteConfirmTitle => 'Delete this budget?';

  @override
  String get budgetDeleteConfirmBody =>
      'This permanently removes the budget. Your transactions are unaffected.';

  @override
  String get budgetDeleteConfirmAction => 'Delete';

  @override
  String get scheduledTitle => 'Scheduled transactions';

  @override
  String get scheduledAddNew => 'Add scheduled';

  @override
  String get scheduledEmptyTitle => 'No scheduled transactions';

  @override
  String get scheduledEmptyMessage =>
      'Set up subscriptions, installments, or loans and we\'ll generate the transactions for you.';

  @override
  String get scheduledVariantRecurring => 'Recurring';

  @override
  String get scheduledVariantInstallment => 'Installment';

  @override
  String get scheduledVariantLoan => 'Loan';

  @override
  String get scheduledTypeExpense => 'Expense';

  @override
  String get scheduledTypeIncome => 'Income';

  @override
  String get scheduledCycleDaily => 'Daily';

  @override
  String get scheduledCycleWeekly => 'Weekly';

  @override
  String get scheduledCycleMonthly => 'Monthly';

  @override
  String get scheduledCycleYearly => 'Yearly';

  @override
  String get scheduledStatusActive => 'Active';

  @override
  String get scheduledStatusPaused => 'Paused';

  @override
  String get scheduledStatusCompleted => 'Completed';

  @override
  String get scheduledStatusCancelled => 'Cancelled';

  @override
  String scheduledNextDue(String date) {
    return 'Due $date';
  }

  @override
  String scheduledInstallmentsLeft(int remaining, int total) {
    return '$remaining/$total left';
  }

  @override
  String get scheduledFormTitle => 'New scheduled';

  @override
  String get scheduledFormTitleEdit => 'Edit scheduled';

  @override
  String get scheduledFormSave => 'Create';

  @override
  String get scheduledFormSaveEdit => 'Save changes';

  @override
  String get scheduledFormIconLabel => 'Icon';

  @override
  String get scheduledFormVariantLabel => 'Type';

  @override
  String get scheduledFormTypeLabel => 'Direction';

  @override
  String get scheduledFormNameLabel => 'Name';

  @override
  String get scheduledFormNameRequired => 'Required';

  @override
  String get scheduledFormAmountLabel => 'Amount per cycle';

  @override
  String get scheduledFormPaymentLabel => 'Payment per cycle';

  @override
  String get scheduledFormAmountInvalid => 'Enter a positive amount';

  @override
  String get scheduledFormAccountLabel => 'Account';

  @override
  String get scheduledFormAccountRequired => 'Pick an account';

  @override
  String get scheduledFormCategoryLabel => 'Category';

  @override
  String get scheduledFormCategoryRequired => 'Pick a category';

  @override
  String get scheduledFormCycleLabel => 'Cycle';

  @override
  String get scheduledFormNextBillingLabel => 'Next billing date';

  @override
  String get scheduledFormInstallmentSection => 'Installment details';

  @override
  String get scheduledFormTotalAmountLabel => 'Total amount';

  @override
  String get scheduledFormTotalAmountHelper =>
      'Sum of all installments + down payment.';

  @override
  String get scheduledFormTotalAmountHelperLoan =>
      'Lifetime total: principal + interest combined.';

  @override
  String get scheduledFormDownPaymentLabel => 'Down payment';

  @override
  String get scheduledFormTotalInstallmentsLabel => 'Total installments';

  @override
  String get scheduledFormRemainingInstallmentsLabel => 'Remaining';

  @override
  String get scheduledFormInstallmentsInvalid => 'Enter a valid count';

  @override
  String get scheduledFormRemainingExceeds => 'Cannot exceed total';

  @override
  String get scheduledFormInterestRateLabel => 'Interest rate (APR)';

  @override
  String get scheduledFormInterestInvalid => 'Must be between 0 and 99.99';

  @override
  String get scheduledFormNoteLabel => 'Note';

  @override
  String get scheduledDetailNotFound => 'Schedule not found';

  @override
  String get scheduledDetailNotFoundMessage =>
      'This scheduled entry may have been deleted or cancelled.';

  @override
  String get scheduledDetailEdit => 'Edit';

  @override
  String get scheduledDetailPause => 'Pause';

  @override
  String get scheduledDetailResume => 'Resume';

  @override
  String get scheduledDetailCancel => 'Cancel';

  @override
  String get scheduledDetailDelete => 'Delete';

  @override
  String scheduledDetailNextDue(String date) {
    return 'Next due $date';
  }

  @override
  String get scheduledDetailAccount => 'Account';

  @override
  String get scheduledDetailCategory => 'Category';

  @override
  String get scheduledDetailCycle => 'Cycle';

  @override
  String get scheduledDetailTotalAmount => 'Total amount';

  @override
  String get scheduledDetailDownPayment => 'Down payment';

  @override
  String get scheduledDetailInstallments => 'Installments';

  @override
  String get scheduledDetailInterestRate => 'Interest rate';

  @override
  String get scheduledDetailNote => 'Note';

  @override
  String get scheduledGenerateNowTitle => 'Generate now';

  @override
  String get scheduledGenerateNowBody =>
      'Manually create the next transaction and advance the schedule. Phase 1c only — Phase 3 adds an automatic scheduler.';

  @override
  String get scheduledGenerateNowAction => 'Generate';

  @override
  String get scheduledGenerateNowSuccess => 'Transaction generated';

  @override
  String get scheduledGenerateNowViewTransaction => 'View';

  @override
  String get scheduledDetailHistoryTitle => 'Generated transactions';

  @override
  String get scheduledDetailHistoryEmpty =>
      'No transactions have been generated yet.';

  @override
  String scheduledDetailHistoryTotal(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get scheduledCancelConfirmTitle => 'Cancel this schedule?';

  @override
  String get scheduledCancelConfirmBody =>
      'Cancelling is final — you\'ll need to create a new entry to schedule again.';

  @override
  String get scheduledCancelConfirmAction => 'Cancel schedule';

  @override
  String get scheduledDeleteConfirmTitle => 'Delete this schedule?';

  @override
  String get scheduledDeleteConfirmBody =>
      'Past generated transactions stay; only the schedule is removed.';

  @override
  String get scheduledDeleteConfirmAction => 'Delete';
}
