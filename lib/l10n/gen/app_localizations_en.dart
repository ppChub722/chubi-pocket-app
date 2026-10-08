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
  String get commonEdit => 'Edit';

  @override
  String get commonLongPressToEdit => 'Long-press to edit';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonToday => 'Today';

  @override
  String get commonYesterday => 'Yesterday';

  @override
  String get commonInvite => 'Invite';

  @override
  String get commonClear => 'Clear';

  @override
  String get commonUndo => 'Undo';

  @override
  String get commonDiscard => 'Discard';

  @override
  String get commonDiscardTitle => 'Discard changes?';

  @override
  String get commonDiscardBody => 'Your edits will be lost.';

  @override
  String get commonCurrency => 'Currency';

  @override
  String get currencyNameTHB => 'Thai baht';

  @override
  String get currencyNameUSD => 'US dollar';

  @override
  String get currencyNameEUR => 'Euro';

  @override
  String get currencyNameGBP => 'British pound';

  @override
  String get currencyNameJPY => 'Japanese yen';

  @override
  String get contactPickerTitle => 'Who?';

  @override
  String get contactPickerSearchHint => 'Search contacts or type a name';

  @override
  String contactPickerUseName(String name) {
    return 'Use \"$name\"';
  }

  @override
  String get contactPickerUseNameHint => 'Not saved as a contact';

  @override
  String get contactPickerEmpty => 'No contacts yet — type a name above';

  @override
  String get commonShowAmounts => 'Show amounts';

  @override
  String get commonHideAmounts => 'Hide amounts';

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
  String get homeNetWorthLabel => 'Net worth';

  @override
  String homeNetWorthAccountCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallets',
      one: '1 wallet',
    );
    return '$_temp0';
  }

  @override
  String get homeRecentTitle => 'Recent transactions';

  @override
  String get homeRecentViewAll => 'View all';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navTransactions => 'Transactions';

  @override
  String get navAccounts => 'Wallets';

  @override
  String get navAddTransaction => 'Add transaction';

  @override
  String get navProjects => 'Projects & Events';

  @override
  String get projectsCreateNew => 'Create new';

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
  String get accountsPlaceholderTitle => 'No wallets yet';

  @override
  String get accountsPlaceholderMessage => 'Adding wallets ships in Phase 1a.';

  @override
  String get accountsAddNew => 'Add wallet';

  @override
  String get accountsReorderHint =>
      'Drag ≡ to reorder. This order is yours only — it never moves wallets for other members.';

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
  String get accountDetailNotFound => 'Wallet not found';

  @override
  String get accountDetailNotFoundMessage =>
      'This wallet may have been archived or deleted.';

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
  String get accountFormTitle => 'New wallet';

  @override
  String get accountFormTitleEdit => 'Edit wallet';

  @override
  String get accountFormSaveEdit => 'Save changes';

  @override
  String get accountFormPreviewLabel => 'Preview';

  @override
  String get accountFormTypeLabel => 'Type';

  @override
  String get accountFormNameLabel => 'Wallet name';

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
      'Money already in this wallet on the day you start tracking.';

  @override
  String get accountFormCreditSection => 'Credit details';

  @override
  String get accountFormCreditLimitLabel => 'Credit limit';

  @override
  String get accountFormCreditLimitRequired => 'Required for credit wallets';

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
  String get accountFormSave => 'Save wallet';

  @override
  String get accountFormDiscardTitle => 'Discard new wallet?';

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
  String get accountArchiveConfirmTitle => 'Archive this wallet?';

  @override
  String get accountArchiveConfirmBody =>
      'The wallet will be hidden from the active list. Its transactions stay intact and remain referenced.';

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
      'What this wallet is for. Visible to you only.';

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
  String get iconMakerRoleIcon => 'Icon';

  @override
  String get iconMakerRoleBackground => 'Background';

  @override
  String get iconMakerRoleBorder => 'Border';

  @override
  String get iconMakerColor => 'Colour';

  @override
  String get iconMakerColorEditing => 'Editing colour';

  @override
  String get iconMakerColorHint =>
      'Tap a colour below to change the selected slot';

  @override
  String get iconMakerRecentCustom => 'Recent · Custom';

  @override
  String get iconMakerThemeColors => 'Theme';

  @override
  String get iconMakerPresetColors => 'Preset';

  @override
  String get iconMakerHex => 'Hex';

  @override
  String get iconMakerReset => 'Reset to default';

  @override
  String get iconMakerPresetLabel => 'preset';

  @override
  String get iconMakerTitle => 'Icon';

  @override
  String get iconMakerTabStyle => 'Style';

  @override
  String get iconMakerTabColor => 'Color';

  @override
  String get iconMakerShape => 'Shape';

  @override
  String get iconMakerPattern => 'Pattern';

  @override
  String get iconMakerNone => 'None';

  @override
  String get iconMakerCommonColors => 'Common';

  @override
  String get iconMakerCustomColors => 'Custom';

  @override
  String get iconMakerSearchHint => 'Search icons, e.g. car, home';

  @override
  String iconMakerNoMatch(String query) {
    return 'No icons match \"$query\"';
  }

  @override
  String iconMakerLayerOff(String layer) {
    return '$layer: none — pick a style first';
  }

  @override
  String get iconMakerNotRecolorable => 'This style has fixed colors';

  @override
  String get iconMakerResetSlot => 'Reset this color';

  @override
  String get iconMakerPickColor => 'Pick a color';

  @override
  String get iconMakerHexInvalid => 'Use #RRGGBB';

  @override
  String get iconMakerResetConfirmTitle => 'Reset icon?';

  @override
  String get iconMakerResetConfirmBody =>
      'Icon, colors, background and border go back to the defaults. You can undo it.';

  @override
  String get iconMakerUseDefault => 'Use the app\'s default icon';

  @override
  String get iconShapeCircle => 'Circle';

  @override
  String get iconShapeSquircle => 'Squircle';

  @override
  String get iconShapeRounded => 'Rounded';

  @override
  String get iconShapeSquare => 'Square';

  @override
  String get iconShapeLeaf => 'Leaf';

  @override
  String get iconShapeDrop => 'Drop';

  @override
  String get colorPickerTitle => 'Pick a colour';

  @override
  String get colorPickerUse => 'Use colour';

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
  String get moreProjects => 'Projects & Events';

  @override
  String get moreTags => 'Tags';

  @override
  String get moreContacts => 'Contacts';

  @override
  String get contactsAddNew => 'New contact';

  @override
  String get contactsFilterActive => 'Active';

  @override
  String get contactsFilterArchived => 'Archived';

  @override
  String get contactsFilterAll => 'All';

  @override
  String get contactsEmptyTitle => 'No contacts yet';

  @override
  String get contactsEmptyMessage =>
      'People you add appear here — link them to share transactions and debts.';

  @override
  String get contactsSearchHint => 'Search name, email or phone';

  @override
  String get contactsStatusLabel => 'Status';

  @override
  String get contactsNoMatch => 'No matching contacts';

  @override
  String get contactTitleNew => 'New contact';

  @override
  String get contactTitleEdit => 'Edit contact';

  @override
  String get contactNotFound => 'Contact not found';

  @override
  String get contactNameLabel => 'Name';

  @override
  String get contactNameRequired => 'Name is required';

  @override
  String get contactNameTooLong => 'Up to 100 characters';

  @override
  String get contactEmailLabel => 'Email';

  @override
  String get contactEmailInvalid => 'Invalid email';

  @override
  String get contactPhoneLabel => 'Phone';

  @override
  String get contactNotesLabel => 'Notes';

  @override
  String get contactLinkedBadge => 'Linked to an app account';

  @override
  String get contactLinkedLockedHint =>
      'Name and email come from their account';

  @override
  String get contactArchivedBadge => 'Archived';

  @override
  String get contactSectionActions => 'Manage';

  @override
  String get contactLinkTitle => 'Link account';

  @override
  String get contactLinkLinked =>
      'Linked — name, email and icon follow their account';

  @override
  String get contactLinkRequest => 'Send link request';

  @override
  String get contactLinkRequestHint =>
      'If this email belongs to a user, they\'ll get a request';

  @override
  String get contactLinkNeedsEmail => 'Add an email to send a link request';

  @override
  String get contactLinkRequested => 'Link request sent';

  @override
  String get contactUnlink => 'Unlink';

  @override
  String contactUnlinkTitle(String name) {
    return 'Unlink $name?';
  }

  @override
  String get contactUnlinkBody =>
      'The contact goes back to the name and email you saved.';

  @override
  String get contactUnlinked => 'Unlinked';

  @override
  String get contactWireTitle => 'Match names in splits';

  @override
  String contactWireHint(int names, int splits) {
    return '$names names · $splits splits not linked to a contact';
  }

  @override
  String get contactWireNone => 'No unlinked names';

  @override
  String contactWireSheetTitle(String name) {
    return 'Link names to $name';
  }

  @override
  String get contactWireSheetBody =>
      'Pick the typed names in your splits that are this person — their debts get linked to this contact.';

  @override
  String get contactWireSearch => 'Search names';

  @override
  String contactWireCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count splits',
      one: '1 split',
    );
    return '$_temp0';
  }

  @override
  String contactWireSave(int count) {
    return 'Link $count';
  }

  @override
  String contactWireDone(int count, String name) {
    return 'Linked $count splits to $name';
  }

  @override
  String get contactArchive => 'Archive';

  @override
  String get contactArchiveHint => 'Hidden from pickers; history stays';

  @override
  String get contactRestore => 'Restore';

  @override
  String get contactDebts => 'Debts with this person';

  @override
  String contactDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get contactDeleteBody =>
      'Splits and debts that mention this person keep their name as text.';

  @override
  String contactDeleted(String name) {
    return 'Deleted $name';
  }

  @override
  String get contactLinkCreateTitle => 'Add linked contact';

  @override
  String get contactLinkExistingTitle => 'Link contact';

  @override
  String get contactLinkSave => 'Link & save';

  @override
  String contactLinkBannerNew(String name) {
    return 'Saving creates a new contact linked to $name.';
  }

  @override
  String contactLinkBannerExisting(String name) {
    return 'Saving links this contact to $name.';
  }

  @override
  String get debtsNet => 'Net';

  @override
  String get debtsOwedToMe => 'Owe you';

  @override
  String get debtsIOwe => 'You owe';

  @override
  String get debtsEven => 'Settled up';

  @override
  String get debtsSearchHint => 'Search name';

  @override
  String get debtsStatusLabel => 'Status';

  @override
  String get debtsStatusOpen => 'Outstanding';

  @override
  String get debtsStatusAll => 'All';

  @override
  String debtsOpenCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count outstanding',
      one: '1 outstanding',
      zero: 'Nothing outstanding',
    );
    return '$_temp0';
  }

  @override
  String get debtsEmptyTitle => 'No debts yet';

  @override
  String get debtsEmptyMessage =>
      'Record who owes you or whom you owe — or split a bill from a transaction.';

  @override
  String get debtsNoMatch => 'No matching people';

  @override
  String get debtsAddNew => 'Record a debt';

  @override
  String debtsPersonHistory(int count) {
    return 'History ($count)';
  }

  @override
  String get debtsPersonAdd => 'Record a debt with this person';

  @override
  String get debtsPersonLinkContact => 'Link to a contact';

  @override
  String get debtsPersonLinkContactHint =>
      'Merge this name\'s debts into a contact';

  @override
  String debtsPersonLinked(int count, String name) {
    return 'Linked $count debts to $name';
  }

  @override
  String get debtsPersonOpenContact => 'View contact';

  @override
  String debtTheyOweYou(String name) {
    return '$name owes you';
  }

  @override
  String debtYouOwe(String name) {
    return 'You owe $name';
  }

  @override
  String get debtStatusSettled => 'Paid back';

  @override
  String get debtStatusCancelled => 'Cancelled';

  @override
  String get debtOutstanding => 'Outstanding';

  @override
  String debtProgress(String paid, String total) {
    return 'Paid back $paid of $total';
  }

  @override
  String get debtReceive => 'Receive payment';

  @override
  String get debtPay => 'Pay back';

  @override
  String get debtAmount => 'Full amount';

  @override
  String get debtSettled => 'Paid back';

  @override
  String get debtSource => 'From';

  @override
  String get debtSourceManual => 'Recorded manually';

  @override
  String get debtSourceTransaction => 'Bill split';

  @override
  String get debtSourceProject => 'Project';

  @override
  String get debtNote => 'Note';

  @override
  String get debtCreatedAt => 'Created';

  @override
  String get debtCounterparty => 'With';

  @override
  String get debtCounterpartyPlaceholder => 'Pick a contact or type a name';

  @override
  String get debtCounterpartyRequired => 'Pick or type a name';

  @override
  String get debtCancel => 'Cancel this debt';

  @override
  String get debtCancelTitle => 'Cancel this debt?';

  @override
  String get debtCancelBody =>
      'No money moves. Use it when you forgive the debt or recorded it by mistake.';

  @override
  String get debtCancelled => 'Debt cancelled';

  @override
  String get debtDeleteTitle => 'Delete this debt?';

  @override
  String get debtDeleteBody => 'Deleted for good — this can\'t be undone.';

  @override
  String get debtDeleted => 'Debt deleted';

  @override
  String get debtNotFound => 'Debt not found';

  @override
  String get debtNewTitle => 'Record a debt';

  @override
  String get debtEditTitle => 'Edit debt';

  @override
  String get debtDirectionOwedToMe => 'They owe me';

  @override
  String get debtDirectionOwedToMeDesc => 'I lent money or paid for them';

  @override
  String get debtDirectionIOwe => 'I owe them';

  @override
  String get debtDirectionIOweDesc => 'I borrowed or they paid for me';

  @override
  String get debtAmountRequired => 'Enter an amount above 0';

  @override
  String debtAmountBelowSettled(String amount) {
    return 'Can\'t be less than what\'s been paid back ($amount)';
  }

  @override
  String debtSettleTitleReceive(String name) {
    return 'Receive from $name';
  }

  @override
  String debtSettleTitlePay(String name) {
    return 'Pay back $name';
  }

  @override
  String get debtSettleAll => 'All';

  @override
  String get debtSettleHalf => 'Half';

  @override
  String debtSettleOver(String amount) {
    return 'More than outstanding ($amount)';
  }

  @override
  String get debtSettleRecordTx => 'Record as a transaction';

  @override
  String get debtSettleRecordTxHint =>
      'Adds income/expense and updates the wallet balance';

  @override
  String get debtSettleNoTxHint =>
      'Only lowers the outstanding amount — no transaction';

  @override
  String get debtSettleAccount => 'Wallet';

  @override
  String get debtSettleAccountRequired => 'Pick a wallet';

  @override
  String get debtSettleDate => 'Date';

  @override
  String get debtSettleConfirm => 'Confirm';

  @override
  String get debtSettleDone => 'Payment recorded';

  @override
  String get projectStatusActive => 'In progress';

  @override
  String get projectStatusCompleted => 'Completed';

  @override
  String get projectStatusCancelled => 'Cancelled';

  @override
  String get projectStatusArchived => 'Archived';

  @override
  String get projectsStatusAll => 'All';

  @override
  String get projectsStatusLabel => 'Status';

  @override
  String get projectsSearchHint => 'Search projects';

  @override
  String get projectsSortRecent => 'Recent';

  @override
  String get projectsSortName => 'Name';

  @override
  String get projectsEmptyTitle => 'No projects yet';

  @override
  String get projectsEmptyMessage =>
      'Keep a trip or a job\'s spending in one place, then settle up with friends at the end.';

  @override
  String get projectsNoMatch => 'No matching projects';

  @override
  String projectsMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get projectTabDashboard => 'Dashboard';

  @override
  String get projectTabTransactions => 'Transactions';

  @override
  String get projectTabResolve => 'Settle up';

  @override
  String get projectAddTransaction => 'Add transaction';

  @override
  String get projectNewTitle => 'New project';

  @override
  String get projectEditTitle => 'Edit project';

  @override
  String get projectNameLabel => 'Project name';

  @override
  String get projectNameRequired => 'Name is required';

  @override
  String get projectTypeLabel => 'Type';

  @override
  String get projectTypeHint => 'e.g. trip, freelance';

  @override
  String get projectDescriptionLabel => 'Description';

  @override
  String get projectIconLabel => 'Project icon';

  @override
  String get projectStatusChangeTitle => 'Change status';

  @override
  String projectStatusLockTitle(String status) {
    return 'Change to $status?';
  }

  @override
  String get projectStatusLockBody =>
      'The project gets locked: no adding or editing transactions until it is reopened.';

  @override
  String projectStatusChanged(String status) {
    return 'Status changed to $status';
  }

  @override
  String get projectLockedCompleted => 'Completed: no new transactions';

  @override
  String get projectLockedCancelled =>
      'Cancelled: transactions cannot be added, edited or deleted';

  @override
  String get projectLockedArchived => 'Archived: read only';

  @override
  String projectDeleteTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get projectDeleteBody =>
      'Only projects without transactions can be deleted. If it has some, archive it instead.';

  @override
  String get projectDeleted => 'Project deleted';

  @override
  String get projectDashTotalExpense => 'Total spent';

  @override
  String get projectDashTotalIncome => 'Total income';

  @override
  String get projectDashMembers => 'Members';

  @override
  String get projectDashWhoPaid => 'Who paid';

  @override
  String get projectDashTopCategories => 'Top categories';

  @override
  String get projectDashRecent => 'Recent';

  @override
  String get projectDashSeeAll => 'See all';

  @override
  String projectDashTxCount(int count) {
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
  String get projectTxSearchHint => 'Search transactions';

  @override
  String get projectTxTypeLabel => 'Type';

  @override
  String get projectTxTypeAll => 'All';

  @override
  String get projectTxTypeExpense => 'Expense';

  @override
  String get projectTxTypeIncome => 'Income';

  @override
  String get projectTxOnlyMine => 'Only me';

  @override
  String get projectTxSortTime => 'Date';

  @override
  String get projectTxSortAmount => 'Amount';

  @override
  String get projectTxSortMember => 'Who paid';

  @override
  String get projectTxSortCategory => 'Category';

  @override
  String get projectTxEmpty => 'No transactions in this project yet';

  @override
  String get projectTxNoMatch => 'No matching transactions';

  @override
  String projectTxOwes(String name) {
    return 'owes $name';
  }

  @override
  String get projectTxUnmark => 'Unmark';

  @override
  String get projectTxResolve => 'Record in my book';

  @override
  String get projectTxResolveHint =>
      'Create a transaction or a debt in your own book';

  @override
  String get projectTxEdit => 'Edit transaction';

  @override
  String get projectTxDelete => 'Delete transaction';

  @override
  String get projectTxDeleteTitle => 'Delete this transaction?';

  @override
  String get projectTxDeleteBody => 'Its splits are deleted too.';

  @override
  String get projectTxDeleted => 'Transaction deleted';

  @override
  String get projectResolveAsTx => 'As transaction';

  @override
  String get projectResolveAsDebt => 'As debt';

  @override
  String get projectResolveShareOnly => 'Only my share';

  @override
  String projectResolveShareHint(String full, String share) {
    return 'Full $full · my share $share';
  }

  @override
  String get projectResolveAmount => 'Amount';

  @override
  String get projectResolveCategory => 'Category (optional)';

  @override
  String get projectResolveCategoryNone => 'No category';

  @override
  String get projectResolveDebtHint =>
      'The person comes from the project member';

  @override
  String get projectResolveConfirm => 'Record';

  @override
  String get projectResolveDone => 'Recorded in your book';

  @override
  String get projectResolveComingSoon =>
      'A settle-up summary is on the way. For now, tick rows in the Transactions tab.';

  @override
  String get projectMembersTitle => 'Members';

  @override
  String get projectMembersPending => 'Waiting to accept';

  @override
  String get projectMembersLeft => 'Left';

  @override
  String get projectRoleOwner => 'Owner';

  @override
  String get projectRoleMember => 'Member';

  @override
  String get projectRoleViewer => 'View only';

  @override
  String get projectMemberMakeViewer => 'Make view-only';

  @override
  String get projectMemberMakeContributor => 'Allow editing (member)';

  @override
  String get projectMemberRoleChanged => 'Access updated';

  @override
  String projectMyPosition(String paid, String share) {
    return 'Me: paid $paid · my share $share';
  }

  @override
  String get projectMyNet => 'Net';

  @override
  String get projectMemberLinked => 'Has an app account';

  @override
  String get projectMemberAdHoc => 'No app account';

  @override
  String get projectMembersInvite => 'Invite member';

  @override
  String get projectLeave => 'Leave project';

  @override
  String projectLeaveTitle(String name) {
    return 'Leave $name?';
  }

  @override
  String get projectLeaveBody =>
      'You will not see this project again unless you are invited back.';

  @override
  String get projectLeft => 'You left the project';

  @override
  String get projectMemberRemove => 'Remove from project';

  @override
  String projectMemberRemoveTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get projectMemberRemoved => 'Removed';

  @override
  String get projectMemberTransfer => 'Make owner';

  @override
  String projectMemberTransferTitle(String name) {
    return 'Make $name the owner?';
  }

  @override
  String projectMemberTransferBody(String name) {
    return '$name becomes the owner; you become a regular member.';
  }

  @override
  String get projectMemberTransferred => 'Ownership transferred';

  @override
  String get projectMemberTransferNeedsAccount =>
      'Only members with an app account can own a project';

  @override
  String get projectAddMemberName => 'Name';

  @override
  String get projectAddMemberNameRequired => 'Name is required';

  @override
  String get projectAddMemberEmail => 'Email (optional)';

  @override
  String get projectAddMemberEmailHint =>
      'Add an email to invite an app user; leave it empty for someone without an account';

  @override
  String get projectAddMemberFromContacts => 'Pick from contacts';

  @override
  String get projectAddMemberSubmit => 'Add';

  @override
  String projectAddMemberAdded(String name) {
    return 'Added $name';
  }

  @override
  String get projectTxNewTitle => 'Add project transaction';

  @override
  String get projectTxEditTitle => 'Edit transaction';

  @override
  String get projectTxPaidBy => 'Paid by';

  @override
  String get projectTxReceivedBy => 'Received by';

  @override
  String get projectTxDescription => 'Description';

  @override
  String get projectTxDescriptionRequired => 'Description is required';

  @override
  String get projectTxDate => 'Date';

  @override
  String get projectTxNote => 'Note';

  @override
  String get projectTxCategory => 'Category';

  @override
  String get projectTxCategoryRequired => 'Name the category and pick an icon';

  @override
  String get projectTxCategoryName => 'Category name';

  @override
  String get projectTxSplits => 'Split with';

  @override
  String get projectTxSplitsHint =>
      'How much each person owes the payer; the payer keeps the rest';

  @override
  String get projectTxAddSplit => 'Add a split';

  @override
  String get projectTxSplitEqual => 'Split equally';

  @override
  String projectTxSplitsOver(String sum) {
    return 'Splits ($sum) are more than the total';
  }

  @override
  String projectTxPayerKeeps(String amount) {
    return 'Payer\'s own share $amount';
  }

  @override
  String get projectTxAmountRequired => 'Enter an amount above 0';

  @override
  String get settingsThemeMint => 'Mint';

  @override
  String get settingsThemeSweet => 'Sweet';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsNotificationsHint =>
      'What you get and what happens automatically';

  @override
  String get settingsDefaultCurrencyHint =>
      'Used when you create wallets and debts';

  @override
  String get settingsCurrencySaved => 'Default currency updated';

  @override
  String get settingsFontSample => 'Sample ภาษาไทย 123';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsTabAll => 'All';

  @override
  String get notificationsTabUnread => 'Unread';

  @override
  String get notificationsMarkAllRead => 'Mark all as read';

  @override
  String get notificationsSettingsTooltip => 'Notification settings';

  @override
  String get notificationsEmptyTitle => 'You are all caught up';

  @override
  String get notificationsEmptyMessage =>
      'Activity from people you share with shows up here';

  @override
  String get notificationsEmptyUnread => 'Nothing unread';

  @override
  String get notificationsSomeone => 'Someone';

  @override
  String notifSplitCreated(String actor) {
    return '$actor split a bill with you';
  }

  @override
  String notifSplitPaid(String actor) {
    return '$actor paid back their share';
  }

  @override
  String notifSplitReceived(String actor) {
    return '$actor confirmed your payment';
  }

  @override
  String notifProjectTxForYou(String actor) {
    return '$actor recorded a project transaction for you';
  }

  @override
  String notifProjectTxChanged(String actor) {
    return '$actor edited a project transaction';
  }

  @override
  String notifProjectInvite(String actor, String project) {
    return '$actor invited you to $project';
  }

  @override
  String notifContactLink(String actor) {
    return '$actor wants to link as contacts';
  }

  @override
  String get notifUnknown => 'Notification';

  @override
  String get notifAccepted => 'Accepted · tap to open';

  @override
  String get notifRejectTitle => 'Decline this request?';

  @override
  String get notifRejectBody => 'They will not be told that you declined.';

  @override
  String get notifHidden => 'Hidden';

  @override
  String get notifSettingsTitle => 'Notification settings';

  @override
  String get notifSettingsReceive => 'Notifications you get';

  @override
  String get notifSettingsReceiveHint =>
      'Turn off what you do not need. Invites and requests always come through because they need an answer.';

  @override
  String get notifGroupSplits => 'Bill splits';

  @override
  String get notifGroupProjects => 'Projects';

  @override
  String get notifGroupRequests => 'Invites and requests';

  @override
  String get notifGroupPayments => 'Payments';

  @override
  String get notifTypeSplitCreated => 'Someone splits a bill with me';

  @override
  String get notifTypeSplitPaid => 'Someone pays back their share';

  @override
  String get notifTypeSplitReceived => 'Someone confirms my payment';

  @override
  String get notifTypeProjectTxForYou =>
      'A project transaction is recorded for me';

  @override
  String get notifTypeProjectTxChanged => 'A project transaction is edited';

  @override
  String get notifTypeAlwaysOn => 'Always on';

  @override
  String get notifSettingsAuto => 'Automatic actions';

  @override
  String get notifSettingsAutoHint =>
      'Applies to new activity right away. With auto-add off, the notification gets an \"add to my debts\" button. No receiving wallet = settle my side without a wallet entry.';

  @override
  String get notifTypeProjectAdded => 'Added to a project';

  @override
  String notifProjectAdded(String actor, String project) {
    return '$actor added you to $project';
  }

  @override
  String get notifAutoNotifySplit => 'Tell linked contacts when I split a bill';

  @override
  String get notifAutoAddDebt => 'Track bills split with me as debts';

  @override
  String get notifAutoRecordPayment => 'Record payments people send me';

  @override
  String get notifDefaultAccount => 'Receiving wallet';

  @override
  String get notifDefaultAccountNone => 'Not set';

  @override
  String get notifAutoResolveProject =>
      'Record my own project transactions in my book';

  @override
  String get notifSettingsSaveFailed => 'Could not save, changed back';

  @override
  String get profileUsernameLocked => 'Username cannot be changed';

  @override
  String homeUpcomingInDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: 'In $days days',
      one: 'Tomorrow',
      zero: 'Today',
    );
    return '$_temp0';
  }

  @override
  String get homeNoTxYet => 'No transactions yet';

  @override
  String get homeAddFirstTx => 'Add your first transaction';

  @override
  String get homeAssets => 'Assets';

  @override
  String get homeLiabilities => 'Liabilities';

  @override
  String get homeIncome => 'Income';

  @override
  String get homeExpense => 'Expense';

  @override
  String get homeLeftOver => 'Left over';

  @override
  String get homeVsPrevMonth => 'Spending vs last month';

  @override
  String get homeComingUp => 'Coming up';

  @override
  String homeComingUpWindow(int days) {
    return '$days days';
  }

  @override
  String homeOverdueDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days days late',
      one: '1 day late',
    );
    return '$_temp0';
  }

  @override
  String get homeCardDue => 'Card payment';

  @override
  String get homeWhereMoneyWent => 'Where it went';

  @override
  String get homeOther => 'Other';

  @override
  String get homeUncategorized => 'No category';

  @override
  String get homeNoExpense => 'No spending this month yet';

  @override
  String get homeTrend => 'Income vs expense, 6 months';

  @override
  String homeBudgetsUsed(String pct) {
    return '$pct% used';
  }

  @override
  String homeBudgetsOver(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count over budget',
      one: '1 over budget',
    );
    return '$_temp0';
  }

  @override
  String get homeBudgetsNone => 'No budgets yet';

  @override
  String homeDebtsOpen(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count open',
      one: '1 open',
    );
    return '$_temp0';
  }

  @override
  String get homeDebtsNone => 'All settled';

  @override
  String homeGoalsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count goals',
      one: '1 goal',
    );
    return '$_temp0';
  }

  @override
  String get homeGoalsNone => 'No goals yet';

  @override
  String get homeLoadError => 'Couldn\'t load the dashboard';

  @override
  String get homePrevMonth => 'Previous month';

  @override
  String get homeNextMonth => 'Next month';

  @override
  String get transactionsFilterType => 'Type';

  @override
  String get transactionsFilterRange => 'Period';

  @override
  String get transactionsFilterAccount => 'Wallet';

  @override
  String get transactionsFilterCategory => 'Category';

  @override
  String get transactionsFilterTag => 'Tag';

  @override
  String get transactionsSortNewest => 'Newest';

  @override
  String get transactionsSortOldest => 'Oldest';

  @override
  String get transactionsSortAmountHigh => 'Largest';

  @override
  String get transactionsSortAmountLow => 'Smallest';

  @override
  String get transactionsNoMatch => 'No transactions match these filters';

  @override
  String get transactionsClearFilters => 'Clear filters';

  @override
  String get txDetailDate => 'Date';

  @override
  String get txDetailAccount => 'Wallet';

  @override
  String get txDetailCategory => 'Category';

  @override
  String get txDetailTags => 'Tags';

  @override
  String get txDetailNote => 'Note';

  @override
  String get txDetailSplits => 'Split';

  @override
  String get txDetailHasSplits => 'Split with others';

  @override
  String get txDetailRecordedBy => 'Recorded by';

  @override
  String get txDetailSource => 'From';

  @override
  String get txDetailSourceDebt => 'Debt payment';

  @override
  String get txDetailSourceProject => 'Project';

  @override
  String get txDetailSystemLocked =>
      'System transaction: cannot be edited or deleted';

  @override
  String get txDetailTransferTo => 'To';

  @override
  String get txDetailBalanceAfter => 'Balance after';

  @override
  String get txDeleteTitle => 'Delete this transaction?';

  @override
  String get txDeleteBody => 'The wallet balance is adjusted back.';

  @override
  String get txDeleted => 'Transaction deleted';

  @override
  String get txSplitAdd => 'Split with others';

  @override
  String get txSplitWith => 'Split with';

  @override
  String get txSplitEqually => 'Split equally';

  @override
  String get txSplitCollapse => 'Remove split';

  @override
  String get txSplitAddPerson => 'Add person';

  @override
  String txSplitRemaining(String amount) {
    return 'Your share $amount';
  }

  @override
  String get txSplitWiredContact => 'Linked to a contact';

  @override
  String get txSplitName => 'Name';

  @override
  String get txSplitOwes => 'Owes';

  @override
  String get txSplitRemove => 'Remove';

  @override
  String get authTagline =>
      'Track income and spending, split bills with friends';

  @override
  String get authOr => 'or';

  @override
  String get authContinueWithGoogle => 'Continue with Google';

  @override
  String get authComingSoon => 'Coming soon';

  @override
  String get authRegisterSectionAccount => 'Sign-in details';

  @override
  String get authRegisterSectionProfile => 'About you';

  @override
  String get authRegisterUsernameHint => 'a-z 0-9 _ -, 3 to 50 characters';

  @override
  String get authRegisterPasswordHint => 'At least 8 characters';

  @override
  String get authRegisterEmailHint =>
      'Lets friends link their account with yours';

  @override
  String get authLanguage => 'Language';

  @override
  String get accountsTotalMine => 'Mine';

  @override
  String get accountsTotalShared => 'Shared pot';

  @override
  String accountsArchivedLink(int count) {
    return 'Archived wallets ($count)';
  }

  @override
  String get accountsArchivedTitle => 'Archived wallets';

  @override
  String get accountsArchivedEmpty => 'No archived wallets';

  @override
  String get accountRestore => 'Restore';

  @override
  String accountRestored(String name) {
    return 'Restored $name';
  }

  @override
  String get accountDetailSeeAll => 'See all';

  @override
  String get accountDetailDescription => 'Description';

  @override
  String get accountDetailNote => 'Note';

  @override
  String get accountDetailMembers => 'Members';

  @override
  String get accountArchiveHasMembers =>
      'A wallet with other members cannot be archived. Remove them first.';

  @override
  String get accountArchived => 'Wallet archived';

  @override
  String get txSplitOver => 'Splits are more than the transaction amount';

  @override
  String get txSplitFreeText =>
      'Typed name: pick a contact from the suggestions to link it';

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
  String get moreGroupLibrary => 'Library';

  @override
  String get moreGroupPeople => 'People & shared money';

  @override
  String get moreGroupPlanning => 'Planning';

  @override
  String get moreCategoriesDesc => 'Group income & spending';

  @override
  String get moreTagsDesc => 'Labels for quick search';

  @override
  String get moreContactsDesc => 'People you split bills with';

  @override
  String get moreProjectsDesc => 'Trips & shared budgets';

  @override
  String get moreDebtsDesc => 'Who owes whom';

  @override
  String get moreBudgetsDesc => 'Spending limits';

  @override
  String get moreSavingGoalsDesc => 'Save towards a target';

  @override
  String get moreScheduledDesc => 'Recurring & upcoming bills';

  @override
  String moreLiveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String moreLiveDebts(String owed, String owe) {
    return 'Owed to you $owed · you owe $owe';
  }

  @override
  String moreLiveDueSoon(int count, int days) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count due in $days days',
      one: '1 due in $days days',
    );
    return '$_temp0';
  }

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
  String get categoryFormParentNone => 'None';

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
  String get categoriesSearchHint => 'Search categories';

  @override
  String get categoriesSearchNoMatch => 'No matching categories';

  @override
  String get categoryDelete => 'Delete category';

  @override
  String categoryDeleteTitle(String name) {
    return 'Delete \"$name\"?';
  }

  @override
  String get categoryDeleteBody => 'Subcategories move up under the parent.';

  @override
  String categoryDeleteTxImpact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions',
      one: '1 transaction',
    );
    return '$_temp0 will become uncategorised.';
  }

  @override
  String categoryDeleteBudgetImpact(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count budgets',
      one: '1 budget',
    );
    return '$_temp0 for this category will be deleted.';
  }

  @override
  String categoryDeletedResult(String name) {
    return 'Deleted \"$name\"';
  }

  @override
  String get commonDelete => 'Delete';

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
  String get tagsSearchHint => 'Search tags';

  @override
  String get tagsNoMatch => 'No matching tags';

  @override
  String get tagsSortUsage => 'Most used';

  @override
  String get tagsSelectAll => 'Select all shown';

  @override
  String get tagsBulkColor => 'Change colour';

  @override
  String get tagsBulkIcon => 'Change icon';

  @override
  String get tagsDeleteSelected => 'Delete selected';

  @override
  String get tagsFiltersClearedForError =>
      'Filters cleared to show a tag that needs fixing';

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
  String get transactionFormAccountLabel => 'Wallet';

  @override
  String get transactionFormFromAccountLabel => 'From wallet';

  @override
  String get transactionFormToAccountLabel => 'To wallet';

  @override
  String get transactionFormAccountRequired => 'Pick a wallet';

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
  String get transactionFormAccountNone => 'No wallet';

  @override
  String get transactionFormMoveTransferTitle => 'Move wallets';

  @override
  String get transactionFormAccountPickerTitle => 'Pick a wallet';

  @override
  String get transactionFormAccountPickerEmpty =>
      'No active wallets. Create one first.';

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
      'This will reverse the balance change on the wallet.';

  @override
  String get transactionDetailDeleteConfirmBodyTransfer =>
      'Both rows of the transfer will be deleted and balances on both wallets will reverse.';

  @override
  String get transactionDetailDeleteConfirmAction => 'Delete';

  @override
  String get transactionDetailTransferReadonlyHint =>
      'To change wallets, delete and create a new transfer.';

  @override
  String get transactionDetailSystemRowBanner =>
      'Auto-created — to change this, use the matching wallet-level action (wallet edit, or Adjust balance).';

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
      'Set a target on top of a wallet and track your progress as the balance grows.';

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
  String get savingGoalFormLinkedAccountLabel => 'Linked wallet';

  @override
  String get savingGoalFormLinkedAccountHelper =>
      'Progress = wallet balance × allocation %';

  @override
  String get savingGoalFormLinkedAccountLockedHelper =>
      'Linked wallet can\'t be changed. Delete and recreate to switch wallets.';

  @override
  String get savingGoalFormAccountRequired => 'Pick a linked wallet';

  @override
  String get savingGoalFormTargetLabel => 'Target amount';

  @override
  String get savingGoalFormTargetInvalid => 'Enter a positive amount';

  @override
  String get savingGoalFormAllocationLabel => 'Allocation';

  @override
  String get savingGoalFormAllocationHelper =>
      'Leave blank to let the server suggest a default. Total per wallet ≤ 100%.';

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
      'Archiving frees its allocation slot on the linked wallet. You can restore it later if capacity is available.';

  @override
  String get savingGoalArchiveConfirmAction => 'Archive';

  @override
  String get savingGoalDeleteConfirmTitle => 'Delete this goal?';

  @override
  String get savingGoalDeleteConfirmBody =>
      'This permanently removes the goal. The linked wallet and its transactions are unaffected.';

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
  String get scheduledFormAccountLabel => 'Wallet';

  @override
  String get scheduledFormAccountRequired => 'Pick a wallet';

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
  String get scheduledDetailAccount => 'Wallet';

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
  String get scheduledStatusChangeTitle => 'Change status';

  @override
  String get scheduledDeleteConfirmBody =>
      'Past generated transactions stay; only the schedule is removed.';

  @override
  String get scheduledDeleteConfirmAction => 'Delete';

  @override
  String get projectFormPlannedLabel => 'Planned budget';

  @override
  String get projectFormPlannedHelper =>
      'Optional — the total you plan to spend. Clear to turn the plan display off.';

  @override
  String get projectFormPlannedInvalid => 'Enter a positive amount';

  @override
  String get projectFormPlannedClearTooltip => 'Clear';

  @override
  String projectMetaPlanned(String amount) {
    return 'Budget $amount';
  }

  @override
  String get projectPlannedRemainingCardLabel => 'Remaining';

  @override
  String projectPlannedLine(String planned, String remaining) {
    return 'Planned $planned · $remaining left';
  }

  @override
  String projectPlannedOverLine(String over) {
    return '🔴 Over budget by $over';
  }

  @override
  String get projectSummaryPlannedLabel => 'Planned';

  @override
  String get projectSummarySpentLabel => 'Spent (net)';

  @override
  String get projectSummaryRemainingLabel => 'Left';

  @override
  String get projectSummaryOverLabel => 'Over budget';

  @override
  String walletsHeaderMine(String amount) {
    return 'Mine $amount';
  }

  @override
  String walletsHeaderShared(String amount) {
    return 'Shared $amount';
  }

  @override
  String get walletSharedLabel => 'Shared wallet';

  @override
  String get walletMembersTitle => 'Members';

  @override
  String walletMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get walletMembersHistoryTitle => 'Past members';

  @override
  String get walletMemberRoleOwner => 'Owner';

  @override
  String get walletMemberRoleMember => 'Member';

  @override
  String get walletMemberPending => 'Pending';

  @override
  String get walletMemberYou => 'You';

  @override
  String walletMemberJoined(String date) {
    return 'Joined $date';
  }

  @override
  String walletMemberLeft(String date) {
    return 'Left $date';
  }

  @override
  String get walletMembersInvite => 'Invite by email';

  @override
  String get walletInviteTitle => 'Invite member';

  @override
  String get walletInviteEmailLabel => 'Email';

  @override
  String get walletInviteEmailInvalid => 'Enter a valid email address.';

  @override
  String get walletInviteSend => 'Send invite';

  @override
  String get walletInviteSent => 'Invite sent';

  @override
  String walletConvertWarnTitle(String name) {
    return '⚠️ Invite \"$name\" to this wallet?';
  }

  @override
  String walletConvertWarnBody(String wallet, String name) {
    return 'Wallet $wallet will become a shared wallet:\n• $name will see this wallet\'s entire history (every past entry)\n• Both of you can add, edit and delete entries\n• This wallet will automatically be removed from your personal reports (you can turn it back on in settings)';
  }

  @override
  String get walletLeave => 'Leave wallet';

  @override
  String get walletLeaveConfirmTitle => 'Leave this wallet?';

  @override
  String get walletLeaveConfirmBody =>
      'Your entries stay on the wallet but become read-only for you. Remaining members can still manage them.';

  @override
  String get walletLeaveAction => 'Leave';

  @override
  String get walletRemoveMemberAction => 'Remove from wallet';

  @override
  String walletRemoveMemberConfirmTitle(String name) {
    return 'Remove $name?';
  }

  @override
  String get walletRemoveMemberConfirmBody =>
      'Their entries stay on the wallet and become read-only for them.';

  @override
  String get walletTransferOwnershipAction => 'Make owner';

  @override
  String walletTransferOwnershipConfirmTitle(String name) {
    return 'Transfer ownership to $name?';
  }

  @override
  String get walletTransferOwnershipConfirmBody =>
      'They will own this wallet. You stay on as a member.';

  @override
  String get walletTransferOwnershipConfirm => 'Transfer';

  @override
  String get walletTransferOwnershipSuccess => 'Ownership transferred';

  @override
  String get walletSettingsTitle => 'Wallet settings';

  @override
  String get walletSettingsMembersSubtitlePersonal =>
      'Invite someone to share this wallet';

  @override
  String get walletReportScopeTitle => 'In my reports';

  @override
  String get walletReportScopeHelper =>
      'Controls how this wallet\'s entries count in your personal summaries and budgets. The wallet page itself always shows everything.';

  @override
  String get walletReportScopeNone => 'Not in reports';

  @override
  String get walletReportScopeOwn => 'Only my entries';

  @override
  String get walletReportScopeAll => 'Whole wallet';

  @override
  String get walletReportScopeSaved => 'Report setting saved';

  @override
  String get transactionFormCategoryAuthorOnlyHint =>
      'Only the author can change the category';

  @override
  String get transactionFormLockedBanner =>
      'Read-only — you\'re no longer a member of this wallet, so this entry can\'t be changed.';

  @override
  String notificationWalletInviteTitle(String actor, String wallet) {
    return '$actor invited you to wallet \"$wallet\"';
  }

  @override
  String get notificationAccept => 'Accept';

  @override
  String get notificationReject => 'Reject';

  @override
  String get walletErrorNotMember => 'You\'re not a member of this wallet.';

  @override
  String get walletErrorOwnerMustTransfer =>
      'Transfer ownership first — this wallet still has other members.';

  @override
  String get walletErrorHasMembers =>
      'This wallet still has other members, so it can\'t be archived or deleted.';

  @override
  String get walletErrorCategoryAuthorOnly =>
      'Only the entry\'s author can change its category.';

  @override
  String get walletErrorRowLocked =>
      'This entry is locked — you\'ve left this wallet.';

  @override
  String get walletErrorScopeNotAllowed =>
      'Past members can only use \"Not in reports\" or \"Only my entries\".';

  @override
  String get walletErrorUserNotFound => 'No user found with that email.';

  @override
  String get walletErrorAlreadyMember =>
      'That user is already a member of this wallet.';

  @override
  String get quickCreateToggle => 'Create an event from this bill...';

  @override
  String get transactionSplitWithTitle => 'Split with…';

  @override
  String get transactionSplitShareTitle =>
      'Share with… (I owe them their part)';

  @override
  String get quickCreateOldBillsSection =>
      'Add past bills to this event (optional)';

  @override
  String get quickCreateOldBillsHint =>
      'Your loose bills from the last 90 days — tick any to bring them onto the event board.';

  @override
  String get quickCreateSearchHint => 'Search past bills';

  @override
  String get quickCreateOldBillsEmpty =>
      'No loose bills from the last 90 days.';

  @override
  String get quickCreateOldBillsSearchEmpty => 'No bills match your search.';

  @override
  String get quickCreateOldBillsLoadMore => 'Load more';

  @override
  String get quickCreateOldBillsRetry => 'Retry';

  @override
  String quickCreateSelectedCount(int count) {
    return '$count selected';
  }

  @override
  String get quickCreateNameSection => 'Event name';

  @override
  String get quickCreateNameLabel => 'Event name';

  @override
  String get quickCreateNameRequired => 'Please enter an event name';

  @override
  String quickCreateDefaultName(String members, String date) {
    return '$members · $date';
  }

  @override
  String quickCreateDefaultNameSolo(String date) {
    return 'Event · $date';
  }

  @override
  String get quickCreateSubmit => 'Create event';

  @override
  String get quickCreateErrorTxNotFound =>
      'Some selected bills no longer exist — refresh and try again.';

  @override
  String get quickCreateErrorTxAlreadyInProject =>
      'Some selected bills already belong to another event — refresh and try again.';

  @override
  String get quickCreateErrorValidation =>
      'Something\'s not right — check the form and try again.';
}
