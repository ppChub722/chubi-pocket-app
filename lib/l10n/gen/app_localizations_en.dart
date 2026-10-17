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
  String get commonName => 'Name';

  @override
  String get commonDescription => 'Description';

  @override
  String get commonNote => 'Note';

  @override
  String get editDiscardTitle => 'Discard your changes?';

  @override
  String get editDiscardMessage => 'What you changed won\'t be saved.';

  @override
  String get editKeepEditing => 'Keep editing';

  @override
  String get editDiscardConfirm => 'Discard changes';

  @override
  String get categorySystemOpening => 'Opening balance';

  @override
  String get categorySystemAdjustment => 'Balance adjustment';

  @override
  String get categorySystemTransferIn => 'Transfer in';

  @override
  String get categorySystemTransferOut => 'Transfer out';

  @override
  String get categorySystemDebtReceived => 'Debt received';

  @override
  String get categorySystemDebtPaid => 'Debt paid';

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
  String get uiPickDate => 'Pick a date';

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
  String get appExitTitle => 'Close the app?';

  @override
  String get appExitConfirm => 'Close';

  @override
  String get navProjects => 'Events';

  @override
  String get projectsCreateNew => 'Create new';

  @override
  String get navMore => 'More';

  @override
  String get navNotificationsTooltip => 'Notifications';

  @override
  String get navProfileTooltip => 'Profile & settings';

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
  String get accountDetailAdjustBalance => 'Adjust balance';

  @override
  String get accountDetailArchive => 'Archive';

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
  String get accountDetailTabOverview => 'Overview';

  @override
  String get accountFormTitle => 'New wallet';

  @override
  String get accountFormTitleEdit => 'Edit wallet';

  @override
  String get accountFormTypeLabel => 'Type';

  @override
  String get accountFormNameRequired => 'Required';

  @override
  String get accountFormNameTooLong => 'Max 100 characters';

  @override
  String get accountFormIconLabel => 'Icon';

  @override
  String get accountFormColorLabel => 'Color';

  @override
  String get accountFormBalanceLabel => 'Opening balance';

  @override
  String get accountFormBalanceHelper =>
      'Money already in this wallet on the day you start tracking.';

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
  String get accountAdjustBalanceTitle => 'Adjust balance';

  @override
  String get accountAdjustBalanceCurrentLabel => 'Current balance';

  @override
  String get accountAdjustBalanceNewLabel => 'New balance';

  @override
  String get accountAdjustBalanceNoChange =>
      'New balance must differ from the current balance.';

  @override
  String get accountArchiveConfirmTitle => 'Archive this wallet?';

  @override
  String get accountArchiveConfirmBody =>
      'The wallet will be hidden from the active list. Its transactions stay intact and remain referenced.';

  @override
  String get accountArchiveConfirmAction => 'Archive';

  @override
  String get accountFormNoteHelper =>
      'Anything you want to jot down. The wallet\'s members see it too.';

  @override
  String get iconPickerUseThis => 'Use this';

  @override
  String get iconMakerRoleIcon => 'Icon';

  @override
  String get iconMakerRoleBackground => 'Background';

  @override
  String get iconMakerRoleBorder => 'Border';

  @override
  String get iconMakerThemeColors => 'Theme';

  @override
  String get iconMakerReset => 'Reset to default';

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
  String get projectsPlaceholderTitle => 'No events yet';

  @override
  String get projectsPlaceholderMessage =>
      'Create an event to track costs you share with others.';

  @override
  String get moreCategories => 'Categories';

  @override
  String get moreProjects => 'Events';

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
  String get contactsNoMatchMessage =>
      'Try another search or change the status filter';

  @override
  String get contactsArchivedEmptyTitle => 'No archived contacts';

  @override
  String get contactsArchivedEmptyMessage =>
      'Archived contacts show up here — hidden from pickers, history kept';

  @override
  String get contactTitleNew => 'New contact';

  @override
  String get contactTitleEdit => 'Edit contact';

  @override
  String get contactNotFound => 'Contact not found';

  @override
  String get contactNameLabel => 'Name';

  @override
  String get contactNameHint => 'Name (required)';

  @override
  String get contactEmailHint => 'Optional · name@example.com';

  @override
  String get contactPhoneHint => 'Optional · 081-234-5678';

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
  String get contactDescriptionHint => 'Optional · e.g. a work friend';

  @override
  String get contactNoteHint => 'Optional · e.g. prefers PromptPay';

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
  String get debtsOwedToMe => 'To receive';

  @override
  String get debtsIOwe => 'To pay';

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
  String get debtSourceProject => 'Event';

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
  String get projectsSearchHint => 'Search events';

  @override
  String get projectsSortRecent => 'Recent';

  @override
  String get projectsSortName => 'Name';

  @override
  String get projectsEmptyTitle => 'No events yet';

  @override
  String get projectsEmptyMessage =>
      'Keep a trip or a job\'s spending in one place, then settle up with friends at the end.';

  @override
  String get projectsNoMatch => 'No matching events';

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
  String get projectTabDashboard => 'Overview';

  @override
  String get projectTabTransactions => 'Transactions';

  @override
  String get projectTabResolve => 'Settle up';

  @override
  String get projectAddTransaction => 'Add transaction';

  @override
  String get projectNewTitle => 'New event';

  @override
  String get projectEditTitle => 'Edit event';

  @override
  String get projectNameLabel => 'Event name';

  @override
  String get projectNameRequired => 'Name is required';

  @override
  String get projectTypeLabel => 'Type';

  @override
  String get projectTypeHint => 'e.g. trip, freelance';

  @override
  String get projectIconLabel => 'Event icon';

  @override
  String get projectStatusChangeTitle => 'Change status';

  @override
  String projectStatusLockTitle(String status) {
    return 'Change to $status?';
  }

  @override
  String get projectStatusLockBody =>
      'The event gets locked: no adding or editing transactions until it is reopened.';

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
      'Only events without transactions can be deleted. If it has some, archive it instead.';

  @override
  String get projectDeleted => 'Event deleted';

  @override
  String get projectDashTotalExpense => 'Total spent';

  @override
  String get projectDashTotalIncome => 'Total income';

  @override
  String get projectDashMembers => 'Members';

  @override
  String get projectDashWhoPaid => 'Who paid';

  @override
  String get projectDashTopTags => 'Top tags';

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
  String get projectTxSortTag => 'Tag';

  @override
  String get projectTxEmpty => 'No transactions in this event yet';

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
  String get projectResolveDebtHint => 'The person comes from the event member';

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
  String get projectLeave => 'Leave event';

  @override
  String projectLeaveTitle(String name) {
    return 'Leave $name?';
  }

  @override
  String get projectLeaveBody =>
      'You will not see this event again unless you are invited back.';

  @override
  String get projectLeft => 'You left the event';

  @override
  String get projectMemberRemove => 'Remove from event';

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
      'Only members with an app account can own an event';

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
  String get projectTxNewTitle => 'Add event transaction';

  @override
  String get projectTxEditTitle => 'Edit transaction';

  @override
  String get projectTxPaidBy => 'Paid by';

  @override
  String get projectTxReceivedBy => 'Received by';

  @override
  String get projectTxTags => 'Tags';

  @override
  String get projectTxAddTag => 'New tag';

  @override
  String get projectTxTagHint => 'Tag name';

  @override
  String get projectTxDescriptionHint => 'Description';

  @override
  String projectTxDescriptionUse(String text) {
    return 'Use \"$text\"';
  }

  @override
  String get projectTxDescriptionPast => 'Used before in this event';

  @override
  String get projectTxSplitMember => 'Who';

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
  String settingsNotificationsSummary(int on, int auto) {
    return '$on on · $auto automatic';
  }

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
  String get notificationsMarkAllRead => 'Mark all as read';

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
  String notifProjectTxForYou(String actor) {
    return '$actor recorded an event transaction for you';
  }

  @override
  String notifProjectTxChanged(String actor) {
    return '$actor edited an event transaction';
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
  String get notifGroupSplits => 'Bill splits';

  @override
  String get notifGroupProjects => 'Events';

  @override
  String get notifGroupRequests => 'Invites and requests';

  @override
  String get notifTypeSplitCreated => 'Someone splits a bill with me';

  @override
  String get notifTypeProjectTxForYou =>
      'An event transaction is recorded for me';

  @override
  String get notifTypeProjectTxChanged => 'An event transaction is edited';

  @override
  String get notifTypeAlwaysOn => 'Always on';

  @override
  String get notifTypeProjectAdded => 'Added to an event';

  @override
  String get notifAutoAddDebt => 'Auto: add to my debts';

  @override
  String get notifAutoCopyToBook => 'Auto: add to my book';

  @override
  String get notifAutoUpdateCopy => 'Auto: update my copy to match';

  @override
  String get notifActionAddDebt => 'Add to my payables';

  @override
  String get notifActionCopyToBook => 'Add to my book';

  @override
  String get notifActionUpdateCopy => 'Update to match';

  @override
  String get notifActionSkip => 'Skip';

  @override
  String get notifActionDone => 'Done · tap to open';

  @override
  String notifProjectAdded(String actor, String project) {
    return '$actor added you to $project';
  }

  @override
  String get notifDefaultAccount => 'Receiving wallet';

  @override
  String get notifDefaultAccountNone => 'Not set';

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
  String get txDetailAccount => 'Wallet';

  @override
  String get txDetailCategory => 'Category';

  @override
  String get txDetailTags => 'Tags';

  @override
  String get txDetailSplits => 'Split';

  @override
  String get txDetailRecordedBy => 'Recorded by';

  @override
  String get txDetailSource => 'From';

  @override
  String get txDetailSourceProject => 'Event';

  @override
  String get txDetailTransferTo => 'To';

  @override
  String get txDetailBalanceAfter => 'Balance after';

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
  String get txSplitExceeds =>
      'Split total is more than the transaction amount';

  @override
  String get txSavedTagsFailed =>
      'Saved, but the tags didn\'t stick — edit them on the transaction';

  @override
  String get txTransferNeedsTo => 'Pick the destination wallet';

  @override
  String get txTransferSameWallet =>
      'Source and destination must be different wallets';

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
  String get accountsTotalShared => 'Shared pot';

  @override
  String get accountsSummaryNet => 'My net balance';

  @override
  String get accountsSummaryAssets => 'Money on hand';

  @override
  String get accountsSummaryDebt => 'Debt (cards · overdrawn)';

  @override
  String accountsSummaryCreditUsed(int pct, String left) {
    return 'Credit used $pct% · $left left';
  }

  @override
  String accountsSummaryWalletCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallets',
      one: '1 wallet',
    );
    return '$_temp0';
  }

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
  String get categoriesTitle => 'Categories';

  @override
  String get categoriesEmptyTitle => 'No categories yet';

  @override
  String get categoriesEmptyMessage =>
      'Add your first category to start organizing transactions.';

  @override
  String get categoryDetailNotFound => 'Category not found';

  @override
  String get categoryDetailNotFoundMessage =>
      'This category may have been deleted.';

  @override
  String get categoriesLimitReached =>
      '100-category limit reached. Delete one to add another.';

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
  String get categoryFormIconLabel => 'Icon';

  @override
  String get categoryFormColorLabel => 'Color';

  @override
  String get categoryFormIncludeInReportLabel => 'Include in reports';

  @override
  String get categoryFormIncludeInReportHelper =>
      'Off = transactions in this category are excluded from totals and charts.';

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
  String get budgetDeleteThis => 'Delete this budget';

  @override
  String get savingGoalDeleteThis => 'Delete this goal';

  @override
  String get contactDeleteThis => 'Delete this contact';

  @override
  String get debtDeleteThis => 'Delete this debt';

  @override
  String get projectDeleteThis => 'Delete this event';

  @override
  String get scheduledDeleteThis => 'Delete this schedule';

  @override
  String get transactionDeleteThis => 'Delete this transaction';

  @override
  String get categoriesReorderEnter => 'Reorder';

  @override
  String get categoriesReorderSave => 'Save';

  @override
  String get categoriesUndo => 'Undo';

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
  String get tagFormTitleEdit => 'Edit tag';

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
  String get editProfileSnackSuccess => 'Profile updated';

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
  String get quickSave => 'Save';

  @override
  String get quickSaved => 'Saved';

  @override
  String get txHeroTitleHint => 'What\'s it for?';

  @override
  String get txDetailRepaymentBanner =>
      'Recorded from a debt repayment — it can\'t be edited, but it can be deleted (the debt\'s repaid amount goes down).';

  @override
  String get debtOverpaid => 'Overpaid';

  @override
  String get debtOverpaidIOwe => 'Overpaid · I owe them back';

  @override
  String get debtOverpaidTheyOwe => 'Overpaid · they owe me back';

  @override
  String get debtOverpaidCantSettle =>
      'This debt is already overpaid — nothing more to record';

  @override
  String txDetailDeleteRepaymentBody(String amount) {
    return 'The debt\'s repaid amount goes down by $amount.';
  }

  @override
  String get notifTypeSplitChanged => 'Someone changes a split with me';

  @override
  String get notifAutoApplySplitChange => 'Auto: update my debt to match';

  @override
  String notifSplitAmountChanged(
    String who,
    String what,
    String from,
    String to,
  ) {
    return '$who changed the split $what: $from → $to';
  }

  @override
  String notifSplitRemovedYou(String who, String what) {
    return '$who removed you from the split $what';
  }

  @override
  String get notifSplitChangeUpdated => 'Your debt was updated';

  @override
  String get notifSplitChangeDeleted => 'That debt was removed';

  @override
  String get notifSplitChangeZeroed =>
      'Your share is now 0 — what you paid counts as overpaid';

  @override
  String get notifSplitChangeUsed => 'Already updated';

  @override
  String get notifSplitChangeStale =>
      'Can\'t update any more — there\'s a newer change';

  @override
  String get notifSplitChangeGone => 'That debt was deleted';

  @override
  String txSplitStatusOverpaidToThem(String amount) {
    return 'Overpaid $amount · you owe it back';
  }

  @override
  String txSplitStatusOverpaidByMe(String amount) {
    return 'Overpaid $amount · they owe it back';
  }

  @override
  String txSplitRepaidSoFar(String amount) {
    return 'Paid back $amount';
  }

  @override
  String get txSplitErrorContact => 'That contact can\'t be used any more';

  @override
  String get txSplitSeeDebts => 'See on the debts page';

  @override
  String get txSplitEditOnDebts => 'Edit on the debts page';

  @override
  String get txSplitStatusPaid => '✓ Paid';

  @override
  String get txSplitStatusRepaid => '✓ Repaid';

  @override
  String txSplitStatusAwaiting(String amount) {
    return 'Owes you $amount';
  }

  @override
  String txSplitStatusToPay(String amount) {
    return 'You owe $amount';
  }

  @override
  String txSplitStatusPartPaid(String paid, String total) {
    return 'Paid $paid of $total';
  }

  @override
  String txSplitStatusPartRepaid(String paid, String total) {
    return 'Repaid $paid of $total';
  }

  @override
  String get txSplitStatusCancelled => 'Cancelled';

  @override
  String txDetailMetaRecordedBy(String name) {
    return 'Recorded by $name';
  }

  @override
  String get txTypeLockedHint => 'The type can\'t change after saving';

  @override
  String txDetailSplitEditElsewhere(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count people',
      one: '1 person',
    );
    return '$_temp0 · edit on the debts page';
  }

  @override
  String get txDetailCreatedAt => 'Recorded';

  @override
  String get txDetailUpdatedAt => 'Last edited';

  @override
  String get txSplitShareShort => 'Share with';

  @override
  String tagPickerCreateNamed(String name) {
    return 'Create “$name”';
  }

  @override
  String get txNoteAddHint => 'Add a note...';

  @override
  String get quickEventNone => 'None';

  @override
  String get quickUnsavedTitle => 'Not saved yet';

  @override
  String get quickUnsavedMessage => 'Close now and this entry is lost.';

  @override
  String get quickDiscardEntry => 'Discard this entry';

  @override
  String get txSplitIncompleteTitle => 'Some split rows aren\'t complete';

  @override
  String txSplitIncompleteNoName(String amount) {
    return '$amount — no name yet';
  }

  @override
  String txSplitIncompleteNoAmount(String name) {
    return '$name — no amount yet';
  }

  @override
  String get txSplitSkipIncomplete => 'Save without these rows';

  @override
  String get txTagCreateFailed => 'Couldn\'t create the tag';

  @override
  String get quickEventUseName => 'Use this name';

  @override
  String get quickEventCreatedOnSave => 'The event is created when you save.';

  @override
  String get projectTxPayerRequired => 'Pick a member first';

  @override
  String get scheduledHeroNameHint => 'What\'s it for, e.g. Netflix';

  @override
  String get quickFrom => 'From';

  @override
  String get quickTo => 'To';

  @override
  String get quickSwap => 'Swap source and destination';

  @override
  String get quickPickWallet => 'Pick a wallet';

  @override
  String get quickAmountRequired => 'Enter an amount first';

  @override
  String get quickDiscardConfirm => 'Discard';

  @override
  String get quickAddToEvent => 'Add to an event';

  @override
  String get quickEventLabel => 'Event';

  @override
  String quickEventNewNamed(String name) {
    return 'New: $name';
  }

  @override
  String get quickEventRemove => 'Don\'t add to an event';

  @override
  String get quickEventNew => 'Create a new event';

  @override
  String get quickEventNameLabel => 'Event name';

  @override
  String get quickEventExisting => 'Or add to an existing event';

  @override
  String get quickEventNoneYet => 'No open events yet';

  @override
  String get quickEventDefaultName => 'Event';

  @override
  String get quickEventNeedsWallet => 'Adding to an event needs a wallet';

  @override
  String get pendingTitle => 'Pending';

  @override
  String get pendingTooltip => 'Pending';

  @override
  String get pendingImportSlip => 'Import slips';

  @override
  String get pendingTypeIt => 'Type a draft';

  @override
  String get pendingChatHint => 'e.g. coffee 65';

  @override
  String get pendingChatSend => 'Send';

  @override
  String get pendingChatClose => 'Close';

  @override
  String get pendingScanning => 'Reading slips…';

  @override
  String get pendingScanDone => 'Slips imported';

  @override
  String get pendingSelectAll => 'Select all';

  @override
  String get pendingSelectNone => 'Select none';

  @override
  String get pendingSelectOne => 'Select this one';

  @override
  String pendingFilterAll(int count) {
    return 'All $count';
  }

  @override
  String pendingFilterManual(int count) {
    return 'Mine $count';
  }

  @override
  String pendingFilterOthers(int count) {
    return 'From others $count';
  }

  @override
  String pendingResult(int done, int failed) {
    return 'Saved $done · $failed left';
  }

  @override
  String get pendingEmptyTitle => 'Nothing pending';

  @override
  String get pendingEmptyMessage =>
      'Jot things down now and confirm them here later';

  @override
  String get pendingAdd => 'Add drafts';

  @override
  String pendingSubmitSelected(int count) {
    return 'Confirm selected ($count)';
  }

  @override
  String pendingSubmittedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count transactions saved',
      one: '1 transaction saved',
    );
    return '$_temp0';
  }

  @override
  String get pendingSeeTransactions => 'View';

  @override
  String get pendingUntitled => 'No description';

  @override
  String get pendingSourceManual => 'Mine';

  @override
  String get pendingSourceSplitPaid => 'Paid back';

  @override
  String get pendingSourceProject => 'Event';

  @override
  String get pendingSourceOcr => 'Scan';

  @override
  String get pendingSourceChat => 'Chat';

  @override
  String get pendingSourceOther => 'Other';

  @override
  String pendingSavedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count drafts saved',
      one: '1 draft saved',
    );
    return '$_temp0';
  }

  @override
  String get pendingBatchHint =>
      'An amount is enough — fill in the rest on the Pending page';

  @override
  String get pendingAddRow => 'Add a row';

  @override
  String pendingSaveAsDrafts(int count) {
    return 'Save $count as drafts';
  }

  @override
  String pendingSubmitAllNow(int count) {
    return 'Confirm all $count now';
  }

  @override
  String get pendingRemoveRow => 'Remove this row';

  @override
  String get pendingSavedAsDraft => 'Saved as a draft · it\'s in Pending';

  @override
  String get pendingSaveDraft => 'Save draft';

  @override
  String get pendingSubmitThis => 'Confirm this one';

  @override
  String get pendingEditTitle => 'Edit draft';

  @override
  String get pendingDiscardTitle => 'Discard this draft?';

  @override
  String pendingDiscardSelectedTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Discard $count drafts?',
      one: 'Discard 1 draft?',
    );
    return '$_temp0';
  }

  @override
  String get pendingKeepAsDraft => 'Keep as a draft';

  @override
  String pendingBlockTitle(int count) {
    return '$count pending';
  }

  @override
  String pendingBlockMore(int count) {
    return '+ $count more';
  }

  @override
  String get pendingNotCounted => 'Not counted in the totals below yet';

  @override
  String get pendingErrMissingType => 'Pick a type before confirming';

  @override
  String get pendingErrMissingAmount => 'Enter an amount before confirming';

  @override
  String get pendingErrMissingDate => 'Pick a date before confirming';

  @override
  String get pendingErrAccount =>
      'This wallet can\'t be used any more — pick another or none';

  @override
  String get pendingErrCategory =>
      'This category can\'t be used — pick another';

  @override
  String get pendingErrCurrency => 'Can\'t transfer between currencies';

  @override
  String get pendingErrTag => 'A tag on it was deleted';

  @override
  String get pendingErrContact => 'A contact in the split was deleted';

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
  String get transactionFormCategoryLabel => 'Category';

  @override
  String get transactionFormCategoryNone => 'Uncategorized';

  @override
  String get transactionFormAmountLabel => 'Amount';

  @override
  String get transactionFormTagsLabel => 'Tags';

  @override
  String get transactionFormSave => 'Save';

  @override
  String get transactionFormAccountNone => 'No wallet';

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
  String get transactionsListFilterAll => 'All';

  @override
  String get transactionsListEmptyMessage =>
      'Record the first income or expense of the month.';

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
  String get savingGoalFormIconLabel => 'Icon';

  @override
  String get savingGoalFormNameRequired => 'Required';

  @override
  String get savingGoalFormLinkedAccountLabel => 'Linked wallet';

  @override
  String get savingGoalFormAccountRequired => 'Pick a linked wallet';

  @override
  String get savingGoalFormTargetLabel => 'Target amount';

  @override
  String get savingGoalFormTargetInvalid => 'Enter a positive amount';

  @override
  String get savingGoalFormAllocationLabel => 'Allocation';

  @override
  String get savingGoalFormAllocationInvalid => 'Must be between 0 and 100';

  @override
  String get savingGoalFormDeadlineLabel => 'Deadline';

  @override
  String get savingGoalFormDeadlinePlaceholder => 'Optional';

  @override
  String get savingGoalDetailNotFound => 'Goal not found';

  @override
  String get savingGoalDetailNotFoundMessage =>
      'This saving goal may have been deleted or archived.';

  @override
  String get savingGoalDetailArchive => 'Archive';

  @override
  String savingGoalDetailOfTarget(String target) {
    return 'of $target';
  }

  @override
  String get savingGoalDetailRemaining => 'Remaining';

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
  String get budgetFormCategoryLabel => 'Category';

  @override
  String get budgetFormCategoryPlaceholder => 'Pick a category';

  @override
  String get budgetFormCategoryRequired => 'Pick a category';

  @override
  String get budgetFormAmountLabel => 'Limit per period';

  @override
  String get budgetFormAmountInvalid => 'Enter a positive amount';

  @override
  String get budgetFormPeriodLabel => 'Period';

  @override
  String get budgetDetailNotFound => 'Budget not found';

  @override
  String get budgetDetailNotFoundMessage =>
      'This budget may have been deleted or archived.';

  @override
  String get budgetDetailFallbackTitle => 'Budget';

  @override
  String get budgetDetailArchive => 'Archive';

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
  String get scheduledFormSave => 'Create';

  @override
  String get scheduledFormIconLabel => 'Icon';

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
  String get scheduledDetailNotFound => 'Schedule not found';

  @override
  String get scheduledDetailNotFoundMessage =>
      'This scheduled entry may have been deleted or cancelled.';

  @override
  String get scheduledDetailPause => 'Pause';

  @override
  String get scheduledDetailResume => 'Resume';

  @override
  String get scheduledDetailCancel => 'Cancel';

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
  String get scheduledGenerateNowTitle => 'Generate now';

  @override
  String get scheduledGenerateNowBody =>
      'Record the next payment now and move the due date to the next period.';

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
  String projectMetaPlanned(String amount) {
    return 'Budget $amount';
  }

  @override
  String projectPlannedLine(String planned, String remaining) {
    return 'Planned $planned · $remaining left';
  }

  @override
  String projectPlannedOverLine(String over) {
    return '🔴 Over budget by $over';
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
  String get transactionSplitWithTitle => 'Split with…';

  @override
  String get transactionSplitShareTitle =>
      'Share with… (I owe them their part)';

  @override
  String get quickCreateErrorTxNotFound =>
      'Some selected bills no longer exist — refresh and try again.';

  @override
  String get quickCreateErrorTxAlreadyInProject =>
      'Some selected bills already belong to another event — refresh and try again.';

  @override
  String get quickCreateErrorValidation =>
      'Something\'s not right — check the form and try again.';

  @override
  String budgetsOverviewSpent(String spent, String total) {
    return 'Spent $spent of $total';
  }

  @override
  String budgetsOverviewOverCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count budgets over',
      one: '1 budget over',
    );
    return '$_temp0';
  }

  @override
  String get transactionsSearchHint =>
      'Search description · note · category · wallet';

  @override
  String get savingGoalAllocationAuto => 'Auto';

  @override
  String get accountSharingSectionTitle => 'Sharing & reports';

  @override
  String get accountFormOpeningDebtLabel => 'Opening outstanding balance';

  @override
  String get accountFormOpeningDebtHelper =>
      'What you still owe on it on the day you start tracking (0 if nothing)';

  @override
  String get accountAdjustBalanceNewDebtLabel => 'New outstanding balance';

  @override
  String get accountAdjustBalanceDiffLabel => 'Difference';

  @override
  String accountAdjustBalanceWillCreate(String amount) {
    return 'This adds an \"Adjust balance\" transaction of $amount, dated today.';
  }

  @override
  String get scheduledSheetTitleNew => 'New scheduled entry';

  @override
  String get scheduledSheetTitleEdit => 'Edit scheduled entry';

  @override
  String get accountIdentifiersTitle => 'Reference numbers';

  @override
  String get accountIdentifiersHelper => 'Matches bank slips to this wallet';

  @override
  String get accountIdentifiersEmpty => 'No numbers yet';

  @override
  String get accountIdentifiersAdd => 'Add a number';

  @override
  String get identifierKindBankAccount => 'Bank account';

  @override
  String get identifierKindPromptPay => 'PromptPay';

  @override
  String get identifierKindCard => 'Card';

  @override
  String get identifierKindOther => 'Other';

  @override
  String get identifierSheetAddTitle => 'Add a number';

  @override
  String get identifierSheetEditTitle => 'Edit number';

  @override
  String get identifierKindLabel => 'Kind';

  @override
  String get identifierBankLabel => 'Bank';

  @override
  String get identifierBankNone => 'Not set';

  @override
  String get identifierValueLabel => 'Number';

  @override
  String get identifierValueHint => 'e.g. 123-4-56789-0 or xxx-x-x2780-x';

  @override
  String get identifierValueHelperPromptPay => 'Phone or national ID number';

  @override
  String get identifierValueInvalid => 'Digits, x and dashes only';

  @override
  String get identifierValueTooShort => 'Needs at least 4 digits';

  @override
  String get identifierValueTooLong => 'Too long';

  @override
  String get identifierDelete => 'Remove this number';

  @override
  String get walletErrorInvalidIdentifier => 'That account number isn’t valid';

  @override
  String get categoryFeeSwitchLabel => 'Use for fees';

  @override
  String get categoryFeeSwitchHelper =>
      'Fees from bank slips go here · one category at a time';

  @override
  String get categoryFeeSwitchFailed => 'Couldn’t set the fee category';

  @override
  String get monthPickerTitle => 'Pick a month';

  @override
  String get monthPickerThisMonth => 'This month';

  @override
  String get monthPickerPrevYear => 'Previous year';

  @override
  String get monthPickerNextYear => 'Next year';

  @override
  String get monthPickerPrevMonth => 'Previous month';

  @override
  String get monthPickerNextMonth => 'Next month';

  @override
  String get appUpdateRequiredTitle => 'Update required';

  @override
  String get appUpdateRequiredBody =>
      'This version of the app is too old. Download the new version to keep using it.';

  @override
  String get appUpdateDownload => 'Download the new version';

  @override
  String get appUpdateNoLink => 'No download link yet — contact the admin';

  @override
  String get appUpdateOpenFailed => 'Couldn\'t open the download link';

  @override
  String appUpdateBuildLine(int current, int required) {
    return 'This is build $current · $required or newer is needed';
  }

  @override
  String get appUpdateAvailable => 'A new version is available';

  @override
  String get appUpdateAvailableAction => 'Update';

  @override
  String get appUpdateLater => 'Later';

  @override
  String get transactionsEmptyMonthTitle => 'No transactions this month yet';

  @override
  String get transactionsNoMatchMessage =>
      'Try other filters, or clear them to see everything.';

  @override
  String get notifCopyUpdated => 'Your copy is updated';

  @override
  String get homeTodoTitle => 'To do';

  @override
  String get homeTodoPending => 'To confirm';

  @override
  String get homeTodoComingUp => 'Coming up';

  @override
  String get transactionsFiltersTitle => 'Filters';

  @override
  String get transactionsFiltersApply => 'Apply filters';

  @override
  String get transactionsSortBy => 'Sort by';

  @override
  String get txPeriodMonth => 'Month';

  @override
  String get txPeriodWeek => 'Week';

  @override
  String get txPeriodYear => 'Year';

  @override
  String get txPeriodCustom => 'Custom';

  @override
  String get txPeriodPrev => 'Previous period';

  @override
  String get txPeriodNext => 'Next period';

  @override
  String get transactionsEmptyPeriodTitle => 'No transactions in this period';

  @override
  String get transactionsFilterRemove => 'Remove this filter';

  @override
  String get commonMore => 'More';

  @override
  String get txShareMine => 'Your share';

  @override
  String txShareOthersOwe(String amount) {
    return 'others owe $amount';
  }

  @override
  String txShareOthers(String amount) {
    return 'others\' share $amount';
  }

  @override
  String get txSplitAuthorOnly =>
      'Only whoever recorded this transaction can change its splits';

  @override
  String get quickCreateErrorNotBillable =>
      'Opening-balance and adjustment rows can\'t go into an event';

  @override
  String get txEventRemove => 'Take out of the event';

  @override
  String get txEventSplitRepaid =>
      'Someone already paid their share back — this can\'t go into an event';

  @override
  String txEventFailedAfterSave(String reason) {
    return 'Saved — but the event didn\'t change: $reason';
  }

  @override
  String get txEventSplitCancelled =>
      'A split on this was forgiven — it can\'t go into an event';

  @override
  String get txSplitExceedsShare => 'More than your share';

  @override
  String get accountsGroupMine => 'Mine';

  @override
  String get accountsReorder => 'Reorder';

  @override
  String get accountsReorderSave => 'Save order';

  @override
  String get accountsReorderDiscard => 'Discard';

  @override
  String get accountsEmptyTitle => 'No wallets yet';

  @override
  String get accountsEmptyMessage =>
      'Add your first one — cash, a bank account or a card';

  @override
  String get accountsArchivedEmptyMessage =>
      'Archived wallets wait here — restore one any time';

  @override
  String get accountDetailAddTx => 'Transaction';

  @override
  String get accountDetailTransfer => 'Transfer';

  @override
  String accountSharedWith(int count) {
    return 'Shared · $count';
  }

  @override
  String get accountDayNone => 'Not set';

  @override
  String get txPeriodDay => 'Day';

  @override
  String get txPeriodWeekHint =>
      'Tap any day — its whole week (Monday to Sunday)';

  @override
  String get quickEventOpenTitle => 'Open events';

  @override
  String get quickEventNewRow => 'New event';

  @override
  String quickEventCreateNamed(String name) {
    return 'Create \"$name\"';
  }

  @override
  String get quickEventMembersInfo =>
      'The people you split with join the event as members';

  @override
  String get txSplitInEvent => 'Split in the event';

  @override
  String get txSplitInEventHelper =>
      'This split will live in the event — change it on the event page';

  @override
  String get txSplitFromMyShare => 'Split from your share';

  @override
  String get categoryPickerTitle => 'Pick a category';

  @override
  String get categoryPickerSearchHint => 'Search categories';

  @override
  String get categoryPickerNoMatch => 'No category matches';

  @override
  String get tagPickerSearchHint => 'Search or name a new tag';

  @override
  String get tagPickerEmpty => 'No tags yet — make them on the tags page';

  @override
  String get tagPickerNoMatch => 'No tag matches';

  @override
  String get contactPickerSaveAsContact => 'Save as a contact';

  @override
  String get contactPickerSaveFailed => 'Couldn\'t save the contact';

  @override
  String get contactsSortRecent => 'Recently used';

  @override
  String get contactsSortNameAsc => 'Name A→Z';

  @override
  String get contactsSortNameDesc => 'Name Z→A';

  @override
  String get contactArchiveConfirmTitle => 'Archive this contact?';

  @override
  String get tagsBulkDeleteConfirmBody =>
      'The selected tags are deleted when you save, and removed from any transactions using them.';

  @override
  String get contactLinked => 'Linked';

  @override
  String get contactsLinkLabel => 'Link';

  @override
  String get contactsLinkUnlinked => 'Not linked';

  @override
  String get contactsNoFilterMatch => 'No contacts match this filter';

  @override
  String get contactsNoFilterMatchMessage => 'Try changing the filter';

  @override
  String get contactsNoMatchFilterMessage =>
      'Try another search or change the filters';

  @override
  String get walletInviteFromContacts => 'Invite from contacts';

  @override
  String get walletInvitePickTitle => 'Invite to this wallet';

  @override
  String get walletInvitePickHint =>
      'Only contacts linked to an app account can be invited.';

  @override
  String get walletInvitePickEmpty =>
      'No linked contacts left to invite. Link a contact to their app account first (Contacts).';

  @override
  String get walletErrorContactNotFound => 'That contact no longer exists.';

  @override
  String get walletErrorContactArchived =>
      'That contact is archived. Restore it to invite them.';

  @override
  String get walletErrorContactNotLinked =>
      'That contact isn\'t linked to an app account yet.';

  @override
  String get walletErrorInviteInvalid =>
      'The invite couldn\'t be sent. Please try again.';

  @override
  String get reorderMoveUp => 'Move up';

  @override
  String get reorderMoveDown => 'Move down';

  @override
  String get reorderOutdent => 'Move out a level';

  @override
  String get reorderIndent => 'Move in a level';

  @override
  String categoriesReorderUnder(String name) {
    return 'Under $name';
  }

  @override
  String get categoriesReorderTopLevel => 'Top level';

  @override
  String get categoriesReorderTapHint =>
      'Tap a row and use the arrows, or drag ⠿';

  @override
  String get categoryErrorMaxDepth =>
      'Categories nest up to 3 levels (counting this one\'s sub-categories)';

  @override
  String get accountsReorderTapHint =>
      'Tap to select and use the arrows, or drag ⠿. This order is yours alone; shared-wallet members aren\'t affected.';

  @override
  String get categorySectionSettings => 'Settings';

  @override
  String get dayPickerLastDay => 'Last day of the month';

  @override
  String get dayPickerNone => 'Not set';

  @override
  String dayPickerEveryMonth(int day) {
    return '$day of every month';
  }

  @override
  String get txSplitMe => 'My share';

  @override
  String txSplitLeft(String amount) {
    return 'Not split yet $amount';
  }

  @override
  String get txSplitBalanced => 'All split';

  @override
  String txSplitOverBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String get txSplitUnbalanced =>
      'The split doesn\'t add up yet — make your share and theirs total the amount before saving.';

  @override
  String txShareOthersOweYou(String amount) {
    return 'others owe you $amount';
  }

  @override
  String txShareYouOweOthers(String amount) {
    return 'you owe others $amount';
  }

  @override
  String get txSplitNoContact => 'No contact';

  @override
  String get txSplitNoContactHint => 'Keep the name, still editable';

  @override
  String get accountFormNameExample => 'e.g. Salary account';

  @override
  String get accountFormDescriptionExample => 'e.g. For household spending';

  @override
  String get accountsSortCustom => 'My order';

  @override
  String get accountsSortBalance => 'Balance, high to low';

  @override
  String get accountsSortName => 'Name';

  @override
  String get accountsSortType => 'Type';

  @override
  String accountsSummarySharedCount(int count) {
    return '($count shared)';
  }

  @override
  String get accountsSummaryCardDebt => 'Card debt';

  @override
  String get accountReportSectionTitle => 'Reports';

  @override
  String get accountOpeningSectionTitle => 'Opening balance';

  @override
  String get accountCreditSectionTitle => 'Card / credit limit';

  @override
  String get accountMinPaymentOverLimit =>
      'The minimum payment is more than the credit limit. Check it.';

  @override
  String get identifierHintBankAccount => 'e.g. 123-4-56789-0';

  @override
  String get identifierHintPromptPay => '10-digit phone or 13-digit ID';

  @override
  String get identifierHintCard => 'Last 4 digits of the card';

  @override
  String get identifierPromptPayLength =>
      'PromptPay is a 10-digit phone or a 13-digit ID number';

  @override
  String get identifierCardLength => 'Enter the card\'s last 4 digits';

  @override
  String get txSplitAuto => 'Auto';

  @override
  String get contactPickerCreateNew => 'New contact';

  @override
  String get contactPickerEmptyPlain => 'No contacts yet';

  @override
  String get txSplitNameHint => 'Name';

  @override
  String get accountIdentifiersHint =>
      'Only used to match accounts when scanning slips';

  @override
  String get detailManageTitle => 'Manage';

  @override
  String get draftPickWalletFrom => 'Pick the source wallet';

  @override
  String get draftPickWalletTo => 'Pick the destination wallet';

  @override
  String get draftPickCategory => 'Pick a category';

  @override
  String get draftExtrasTitle => 'Split with / Event';

  @override
  String draftExtrasSplits(int count) {
    return 'Split with $count';
  }

  @override
  String get draftExtrasNone => 'Not set';

  @override
  String get pendingErrInvalidSplit =>
      'A split row is incomplete — it needs a name and an amount above 0';

  @override
  String get pendingErrSplitsExceed =>
      'The split adds up to more than the amount';

  @override
  String get pendingErrProjectGone =>
      'That event no longer exists — pick another or remove it';

  @override
  String get pendingErrProjectClosed =>
      'That event is closed or locked — nothing can be added';

  @override
  String get pendingErrProjectMember => 'You\'re not a member of that event';

  @override
  String get pendingErrProjectReadOnly =>
      'You can only view that event — nothing can be added';

  @override
  String get accountReportSectionDescription =>
      'Choose how much of this wallet counts in your reports';

  @override
  String get accountMembersSectionDescription =>
      'People who share this wallet with you';

  @override
  String get accountCreditSectionDescription =>
      'Statement day, due day and minimum payment for this card';

  @override
  String get accountOpeningSectionDescription =>
      'The wallet\'s starting balance; after creating, change it with Adjust balance';

  @override
  String get accountTypeSectionDescription => 'What kind of wallet this is';

  @override
  String get walletMembersHistoryDescription =>
      'People who were in this wallet and have left';

  @override
  String get categorySettingsSectionDescription =>
      'Whether this category counts in reports and is used for fees';

  @override
  String get contactActionsSectionDescription =>
      'Link to a user account, match split names and see this person\'s debts';

  @override
  String get budgetDetailBreakdownDescription =>
      'Spending split by sub-category this period';

  @override
  String get scheduledDetailHistoryDescription =>
      'Transactions already created from this schedule';

  @override
  String get projectMembersDescription =>
      'People currently taking part in this event';

  @override
  String get projectMembersPendingDescription =>
      'Invited and waiting to accept';

  @override
  String get projectMembersLeftDescription => 'People who have left this event';

  @override
  String get contactFieldNotSet => 'Not set';

  @override
  String get txSplitSectionTitle => 'Linked to';

  @override
  String get txSplitSectionHint =>
      'Split the amount with other people, or put it in an event';

  @override
  String get txSplitRowLabel => 'Split';

  @override
  String get quickEventAdd => 'Add event';

  @override
  String get dayPickerLastShort => 'Last';

  @override
  String get profileCurrencyLabel => 'Currency';

  @override
  String get contactNicknameLabel => 'Nickname';

  @override
  String get contactNicknameHint => 'Optional · e.g. Mum';

  @override
  String get contactShowNicknameLabel => 'Show nickname';

  @override
  String get contactShowNicknameHelper =>
      'On = use the nickname instead of the name everywhere';

  @override
  String get accountsSummarySharedPot => 'Shared wallets';

  @override
  String accountsSummaryOtherCurrency(num count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallets in another currency are not counted',
      one: '1 wallet in another currency is not counted',
    );
    return '$_temp0';
  }

  @override
  String get notOwnerError => 'Only the wallet owner can do this';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEmailCannotClear => 'Once set, the email can\'t be removed';

  @override
  String get connectionOffline => 'Can\'t reach the server · trying again…';

  @override
  String get connectionReconnecting => 'Reconnecting…';

  @override
  String get connectionBack => 'Connected again';

  @override
  String get connectionRetry => 'Retry';

  @override
  String get uiLoadMoreFailed => 'Couldn\'t load more';

  @override
  String get debtsTabEntries => 'Entries';

  @override
  String get debtsTabMoney => 'Payments';

  @override
  String get debtsAddEntry => 'Add entry';

  @override
  String get debtsSortLabel => 'Sort';

  @override
  String get debtsSortNewest => 'Newest';

  @override
  String get debtsSortOldest => 'Oldest';

  @override
  String get debtsSortAmountDesc => 'Largest amount';

  @override
  String get debtsSortAmountAsc => 'Smallest amount';

  @override
  String get debtsDirLabel => 'Type';

  @override
  String get debtsDirPaid => 'Paid';

  @override
  String get debtsDirReceived => 'Received';

  @override
  String get debtsPaidChip => 'Paid';

  @override
  String get debtsTimelineEmpty => 'No entries yet';

  @override
  String get debtsMoneyEmpty => 'No payments yet';

  @override
  String get debtsEntriesNoMatch => 'No matching entries';

  @override
  String get debtsEntrySearchHint => 'Search entries';

  @override
  String debtEntryPaidTo(String name) {
    return 'Paid $name';
  }

  @override
  String debtEntryReceivedFrom(String name) {
    return 'Received from $name';
  }

  @override
  String get eventStartDateLabel => 'Start date';

  @override
  String get eventEndDateLabel => 'End date';

  @override
  String get eventDatesInvalid =>
      'The end date can\'t be before the start date';

  @override
  String get eventDateNone => 'Not set';

  @override
  String get eventTagShowBills => 'Show bills with this tag';

  @override
  String get eventTagAddToMine => 'Add to my tags';

  @override
  String get eventTagsImportAll => 'Import all';

  @override
  String eventTagFilter(String name) {
    return 'Tag: $name';
  }

  @override
  String get quickModeTx => 'Transaction';

  @override
  String get quickModeDebt => 'Debt';

  @override
  String get debtNoWallet => 'No wallet';

  @override
  String get debtPickPerson => 'Pick a person';

  @override
  String get debtPersonPickerTitle => 'With whom?';

  @override
  String debtPersonAddTyped(Object name) {
    return 'Add “$name”';
  }

  @override
  String get debtPersonFromContacts => 'From contacts';

  @override
  String get debtSettledLabel => 'All square';

  @override
  String debtResultAfter(Object result) {
    return 'After saving: $result';
  }

  @override
  String get debtMarkPaidTitle => 'Mark entries as paid';

  @override
  String get debtMarkPaidNone => 'Nothing open';

  @override
  String get debtEntrySaved => 'Debt saved';

  @override
  String get eventSourceTx => 'Source transaction';

  @override
  String get eventLinkedHint =>
      'Amount, date and payer are linked to the source transaction: edits change both';

  @override
  String eventTagsImported(int count) {
    return 'Added $count tags to my tags';
  }

  @override
  String get debtEntryTitle => 'Debt entry';

  @override
  String get debtEntryNotFound => 'This debt entry doesn\'t exist';

  @override
  String get debtEntryDelete => 'Delete this entry';

  @override
  String get debtEntryDeleteTitle => 'Delete this debt entry?';

  @override
  String debtDeleteBothMessage(Object wallet) {
    return 'Its transaction in “$wallet” goes too — the money returns to the wallet.';
  }

  @override
  String debtDeleteLedgerMessage(Object name) {
    return 'The balance with $name changes accordingly.';
  }

  @override
  String debtSourceHint(Object source) {
    return 'From $source: only the description, note and paid label can change.';
  }

  @override
  String get debtSourceRowLabel => 'From';

  @override
  String debtBalanceNow(Object result) {
    return 'Now: $result';
  }

  @override
  String txInEventRow(Object name) {
    return 'In the event $name';
  }

  @override
  String get txLinkedMoneyHint =>
      'Amount and date are shared with the event bill: an edit changes both.';

  @override
  String get eventBillLinkedMoneyHint =>
      'Amount and date are shared with the source transaction: an edit changes both.';

  @override
  String get eventErrLocked => 'This event is locked: it can\'t be edited';

  @override
  String get eventErrNotOwner => 'Only the event owner can do this';

  @override
  String get eventErrMoneyLinked =>
      'Amount and date are linked to a member\'s transaction: its owner edits them';

  @override
  String get eventErrTagTaken => 'This event already has a tag with that name';

  @override
  String get eventErrTagNotFound => 'That tag isn\'t in this event';

  @override
  String get eventErrNoShare => 'You have no share in this bill';

  @override
  String get eventErrOwnerCannotLeave =>
      'The owner must transfer ownership before leaving';

  @override
  String get eventDeleteBody =>
      'Every bill in the event is deleted · your transactions linked to it can stay or be deleted too';

  @override
  String get eventDeleteKeepTxs => 'Delete, keep my transactions';

  @override
  String eventDeleteWithTxs(int count) {
    return 'Delete and remove $count transactions';
  }

  @override
  String get eventDeleteConfirm => 'Delete';

  @override
  String get eventDeleteNotYet => 'Not now';

  @override
  String get occurrenceStateUpcoming => 'Upcoming';

  @override
  String get occurrenceStateNotCreated => 'Not created';

  @override
  String get occurrenceStatePending => 'Waiting';

  @override
  String get occurrenceStateDone => 'Saved';

  @override
  String get occurrenceStateArchived => 'Archived';

  @override
  String get quickUpcomingHintTitle => 'Upcoming';

  @override
  String quickUpcomingHintText(Object date) {
    return 'goes to drafts on $date';
  }

  @override
  String get quickEditUpcomingTitle => 'Edit upcoming item';

  @override
  String get linkedSaveTitle => 'Update the other side too?';

  @override
  String get linkedCancel => 'Not now';

  @override
  String get linkedSaveThisOnly => 'Save this side only';

  @override
  String get linkedSaveBoth => 'Save and update the other side';

  @override
  String get linkedDeleteTitle => 'Delete the linked item too?';

  @override
  String get linkedDeleteThisOnly => 'Delete this side only';

  @override
  String get linkedDeleteBoth => 'Delete both';

  @override
  String get dueToday => 'Today';

  @override
  String get dueTomorrow => 'Tomorrow';

  @override
  String get dueYesterday => 'Yesterday';

  @override
  String dueInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'in 1 day',
    );
    return '$_temp0';
  }

  @override
  String dueOverdueDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days overdue',
      one: '1 day overdue',
    );
    return '$_temp0';
  }

  @override
  String recurEveryDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count days',
      one: 'Every day',
    );
    return '$_temp0';
  }

  @override
  String recurEveryWeeks(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count weeks',
      one: 'Every week',
    );
    return '$_temp0';
  }

  @override
  String get recurWeekday1 => 'Monday';

  @override
  String get recurWeekday2 => 'Tuesday';

  @override
  String get recurWeekday3 => 'Wednesday';

  @override
  String get recurWeekday4 => 'Thursday';

  @override
  String get recurWeekday5 => 'Friday';

  @override
  String get recurWeekday6 => 'Saturday';

  @override
  String get recurWeekday7 => 'Sunday';

  @override
  String recurWeekdayPair(String a, String b) {
    return '$a and $b';
  }

  @override
  String recurWeekdayList(String list, String last) {
    return '$list and $last';
  }

  @override
  String get recurWeekdayListSep => ', ';

  @override
  String recurEveryWeekdays(String weekdays) {
    return 'Every $weekdays';
  }

  @override
  String recurOnWeekdays(String weekdays) {
    return '$weekdays';
  }

  @override
  String recurEveryMonths(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count months',
      one: 'Every month',
    );
    return '$_temp0';
  }

  @override
  String recurMonthlyOnDay(int day) {
    return 'Monthly on day $day';
  }

  @override
  String get recurMonthlyLastDay => 'Monthly on the last day';

  @override
  String recurOnDay(int day) {
    return 'day $day';
  }

  @override
  String get recurLastDay => 'last day';

  @override
  String recurMonthlyNthWeekday(String ord, int nth, String weekday) {
    String _temp0 = intl.Intl.selectLogic(ord, {
      'first': 'Monthly on the first $weekday',
      'second': 'Monthly on the second $weekday',
      'third': 'Monthly on the third $weekday',
      'fourth': 'Monthly on the fourth $weekday',
      'other': 'Monthly on the fifth $weekday',
    });
    return '$_temp0';
  }

  @override
  String recurMonthlyLastWeekday(String weekday) {
    return 'Monthly on the last $weekday';
  }

  @override
  String recurOnNthWeekday(String ord, int nth, String weekday) {
    String _temp0 = intl.Intl.selectLogic(ord, {
      'first': 'the first $weekday',
      'second': 'the second $weekday',
      'third': 'the third $weekday',
      'fourth': 'the fourth $weekday',
      'other': 'the fifth $weekday',
    });
    return '$_temp0';
  }

  @override
  String recurOnLastWeekday(String weekday) {
    return 'the last $weekday';
  }

  @override
  String recurEveryYears(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Every $count years',
      one: 'Every year',
    );
    return '$_temp0';
  }

  @override
  String recurYearlyOn(String date) {
    return 'Every year on $date';
  }

  @override
  String recurCustomDates(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Custom · $count dates',
      one: 'Custom · 1 date',
      zero: 'Custom',
    );
    return '$_temp0';
  }

  @override
  String recurEndCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count times',
      one: '1 time',
    );
    return '$_temp0';
  }

  @override
  String recurEndUntil(String date) {
    return 'until $date';
  }

  @override
  String get uiPickDatesHint => 'Tap the days to pick them';

  @override
  String get txSavedAsUpcoming => 'Saved as an upcoming item';

  @override
  String get txMovedToUpcoming => 'Moved to upcoming items';

  @override
  String get txRecurringRowLabel => 'Recurring';

  @override
  String get recurringTitle => 'Recurring';

  @override
  String get recurringTabRecurring => 'Recurring';

  @override
  String get recurringTabUpcoming => 'Upcoming';

  @override
  String get recurringFilterCurrent => 'Active';

  @override
  String get recurringFilterArchived => 'Archived';

  @override
  String get recurringFilterAll => 'All';

  @override
  String get recurringAdd => 'Add recurring';

  @override
  String get recurringEmptyTitle => 'No recurring yet';

  @override
  String get recurringEmptyMessage =>
      'Set up repeating items like rent or internet. When the day comes, they wait in Pending.';

  @override
  String get recurringArchivedEmpty => 'No archived recurring';

  @override
  String get upcomingEmptyTitle => 'Nothing upcoming';

  @override
  String get upcomingEmptyMessage =>
      'Future-dated items and upcoming recurring items show here.';

  @override
  String get recurringNewTitle => 'New recurring';

  @override
  String get recurringNotFound => 'Recurring not found';

  @override
  String get recurringNotFoundMessage => 'It may have been deleted.';

  @override
  String get recurringFieldIcon => 'Icon';

  @override
  String get recurringFieldAmount => 'Amount';

  @override
  String get recurringFieldWallet => 'Wallet';

  @override
  String get recurringFieldToWallet => 'To wallet';

  @override
  String get recurringFieldCategory => 'Category';

  @override
  String get recurringFieldRepeat => 'Repeat';

  @override
  String get recurringFieldStart => 'Starts';

  @override
  String get recurringFieldEnd => 'Ends';

  @override
  String get recurringNameRequired => 'Enter a name';

  @override
  String get recurringAmountInvalid => 'Enter an amount above 0';

  @override
  String get recurringWalletRequired => 'Pick a wallet';

  @override
  String get recurringRepeatDates => 'Pick dates…';

  @override
  String get recurringRepeatDatesTitle => 'Pick dates';

  @override
  String recurringRepeatDatesConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pick $count days',
      one: 'Pick 1 day',
    );
    return '$_temp0';
  }

  @override
  String get recurringEndNever => 'Never';

  @override
  String get recurringEndOnDateOption => 'On a date…';

  @override
  String get recurringEndAfterCountOption => 'After a number of times…';

  @override
  String get recurringStatusActive => 'Active';

  @override
  String get recurringStatusPaused => 'Paused';

  @override
  String get recurringStatusArchived => 'Archived';

  @override
  String get recurringStatusEndingSoon => 'Ending soon';

  @override
  String get recurringPause => 'Pause';

  @override
  String get recurringResume => 'Resume';

  @override
  String get recurringArchive => 'Archive';

  @override
  String get recurringRestore => 'Restore';

  @override
  String get recurringDelete => 'Delete recurring';

  @override
  String get recurringArchiveTitle => 'Archive this recurring?';

  @override
  String get recurringArchiveBody =>
      'It stops producing items and is hidden. You can restore it later.';

  @override
  String get recurringDeleteTitle => 'Delete this recurring?';

  @override
  String get recurringDeleteBody =>
      'Deletes the setting and the items not created yet.';

  @override
  String recurringDeleteLinkedBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items are already saved as transactions.',
      one: '1 item is already saved as a transaction.',
    );
    return '$_temp0';
  }

  @override
  String get recurringDeleteKeepTxs => 'Delete, keep the transactions';

  @override
  String recurringDeleteWithTxs(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete with $count transactions',
      one: 'Delete with 1 transaction',
    );
    return '$_temp0';
  }

  @override
  String get recurringScopeTitle => 'Apply to';

  @override
  String get recurringScopeUpcoming => 'All upcoming items';

  @override
  String get recurringScopeAll => 'All items';

  @override
  String recurringEndingSoon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Ending soon: $count items left',
      one: 'Ending soon: 1 item left',
    );
    return '$_temp0';
  }

  @override
  String get recurringExtend => 'Extend';

  @override
  String get recurringPausedNotice =>
      'Paused: dates that pass while paused produce nothing.';

  @override
  String get recurringTabProduced => 'Items';

  @override
  String get recurringTabUpcomingShort => 'Upcoming';

  @override
  String get recurringItemsEmpty => 'Nothing due yet';

  @override
  String get recurringItemsEmptyMessage =>
      'When a date comes, the item goes to Pending and shows here.';

  @override
  String get recurringUpcomingEmpty => 'Nothing upcoming';

  @override
  String get recurringUpcomingEmptyMessage =>
      'Extend it or edit the setting to produce more.';

  @override
  String recurringUpcomingSummary(String name, String amount, String rule) {
    return '$name $amount · $rule';
  }

  @override
  String recurringUpcomingCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more · tap to see them all',
      one: '1 more · tap to see it',
    );
    return '$_temp0';
  }

  @override
  String get recurringSelectAll => 'Select all';

  @override
  String get recurringItemSendNow => 'Send to pending now';

  @override
  String get recurringItemCreate => 'Create';

  @override
  String get recurringItemCreateTitle => 'Create this item';

  @override
  String get recurringItemCreateBody =>
      'Send it to Pending first, or save it as a transaction now.';

  @override
  String get recurringItemToPending => 'To pending';

  @override
  String get recurringItemToTx => 'Save now';

  @override
  String get recurringItemOpenPending => 'Open pending';

  @override
  String get recurringItemOpenTx => 'Open transaction';

  @override
  String get recurringItemOpenRecurring => 'Open recurring';

  @override
  String get recurringItemArchive => 'Archive';

  @override
  String get recurringItemRestore => 'Restore';

  @override
  String get recurringDeleteLinkedTitle => 'Delete the real transaction too?';

  @override
  String get recurringDeleteItemOnly => 'Only here';

  @override
  String get recurringDeleteItemBoth => 'Both';

  @override
  String recurringItemDeleteTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Delete $count items?',
      one: 'Delete 1 item?',
    );
    return '$_temp0';
  }

  @override
  String get recurringItemDeleteBody => 'They are removed from this recurring.';

  @override
  String get recurringScopeThis => 'This item only';

  @override
  String get recurringScopeFollowing => 'This and following';

  @override
  String get recurringScopePast => 'All past items';

  @override
  String get recurringItemEditTitle => 'Edit item';

  @override
  String get recurringAddItem => 'Add item';

  @override
  String get moreRecurring => 'Recurring';

  @override
  String get moreRecurringDesc => 'Recurring bills & upcoming items';

  @override
  String get pendingSourceRecurring => 'Recurring';

  @override
  String get pendingSourceUpcoming => 'Upcoming';

  @override
  String notifRecurringDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recurring items are due, waiting to confirm',
      one: '1 recurring item is due, waiting to confirm',
    );
    return '$_temp0';
  }

  @override
  String notifRecurringEnding(String name, int left) {
    return '$name has $left items left — extend it?';
  }

  @override
  String get recurSheetTitle => 'Custom repeat';

  @override
  String get recurSheetEvery => 'Every';

  @override
  String recurSheetUnitDay(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'days',
      one: 'day',
    );
    return '$_temp0';
  }

  @override
  String recurSheetUnitWeek(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'weeks',
      one: 'week',
    );
    return '$_temp0';
  }

  @override
  String recurSheetUnitMonth(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'months',
      one: 'month',
    );
    return '$_temp0';
  }

  @override
  String recurSheetUnitYear(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'years',
      one: 'year',
    );
    return '$_temp0';
  }

  @override
  String get recurSheetRepeatOn => 'Repeat on';

  @override
  String get recurSheetMonthlyOn => 'Monthly on';

  @override
  String get recurSheetLastDayOfMonth => 'the last day of the month';

  @override
  String get recurSheetEnds => 'Ends';

  @override
  String get recurSheetEndNever => 'Never';

  @override
  String get recurSheetEndOnDate => 'On a date';

  @override
  String get recurSheetEndAfter => 'After';

  @override
  String recurSheetOccurrences(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'times',
      one: 'time',
    );
    return '$_temp0';
  }

  @override
  String get recurringRepeatCustom => 'Custom…';

  @override
  String get moreGroupPlan => 'Money plans';

  @override
  String get moreGroupOthers => 'Money with others';

  @override
  String get moreGroupSetup => 'Setup data';

  @override
  String get moreGroupMain => 'Main menu';

  @override
  String get moreSettings => 'Profile & settings';

  @override
  String get moreDashboardDesc => 'This month\'s overview';

  @override
  String get moreTransactionsDesc => 'All income and expenses';

  @override
  String get moreWalletsDesc => 'Cash, accounts and cards';

  @override
  String get morePendingDesc => 'Drafts waiting for you to confirm';

  @override
  String get moreNotificationsDesc => 'News and reminders';

  @override
  String get moreSettingsDesc => 'Account, theme and notifications';

  @override
  String moreLiveUnread(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread',
    );
    return '$_temp0';
  }

  @override
  String get sgv2SavedTotal => 'Saved in total';

  @override
  String get sgv2InGoals => 'In goals';

  @override
  String get sgv2Spare => 'Not allocated';

  @override
  String get sgv2SpareHint => 'Savings without a goal';

  @override
  String get sgv2FilterActive => 'Saving';

  @override
  String get sgv2FilterCompleted => 'Reached';

  @override
  String get sgv2FilterArchived => 'Archived';

  @override
  String get sgv2EmptyFilteredTitle => 'No goals here';

  @override
  String sgv2PaceLate(int n) {
    return '$n months late';
  }

  @override
  String get sgv2PaceOnTrack => 'On track';

  @override
  String sgv2PaceLine(String needed, String pace) {
    return 'Need $needed/mo · saving $pace';
  }

  @override
  String sgv2DueOn(String date) {
    return 'Due $date';
  }

  @override
  String get sgv2NoDeadline => 'No deadline';

  @override
  String get sgv2ActionAdd => 'Add savings';

  @override
  String get sgv2ActionWithdraw => 'Withdraw';

  @override
  String get sgv2ActionMove => 'Move';

  @override
  String get sgv2Overview => 'Overview';

  @override
  String get sgv2NeededMonthly => 'Needed per month';

  @override
  String get sgv2PaceMonthly => 'Actual (3-month average)';

  @override
  String get sgv2Eta => 'At this pace, done';

  @override
  String get sgv2TimeLeft => 'Time left';

  @override
  String get sgv2ByWallet => 'By wallet';

  @override
  String get sgv2ByWalletHint => 'Saved money remembers its wallet';

  @override
  String get sgv2Entries => 'Saving entries';

  @override
  String get sgv2EntriesEmpty => 'No saving entries yet';

  @override
  String get sgv2EntriesMore => 'Show more';

  @override
  String get sgv2AutoSave => 'Auto-save';

  @override
  String get sgv2AutoSaveNone => 'Not set';

  @override
  String get sgv2CloseGoal => 'Close goal';

  @override
  String sgv2CloseTitle(String name) {
    return 'Close “$name”';
  }

  @override
  String sgv2CloseBody(String amount) {
    return 'Where should the $amount go?';
  }

  @override
  String get sgv2CloseToSpare => 'Into not allocated';

  @override
  String get sgv2CloseToWallets => 'Back to the wallets';

  @override
  String get sgv2Restore => 'Restore';

  @override
  String get sgv2KindSave => 'Save';

  @override
  String get sgv2KindWithdraw => 'Withdraw';

  @override
  String get sgv2KindMove => 'Move';

  @override
  String get sgv2SpareTitle => 'Not allocated';

  @override
  String sgv2Milestone(int pct) {
    return 'Reached $pct%';
  }

  @override
  String get walletTrackLabel => 'Track balance';

  @override
  String get walletTrackHelper =>
      'Turn off if you do not want a balance for this wallet (you can still log and transfer)';

  @override
  String get walletTrackSetBalanceTitle => 'Current balance';

  @override
  String get walletTrackSetBalanceAction => 'Set balance';

  @override
  String walletTrackUntrackedNote(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count wallets not tracked',
      one: '1 wallet not tracked',
    );
    return '$_temp0';
  }

  @override
  String get walletTrackOffHero => 'Balance not tracked';

  @override
  String get walletErrorBalanceNotTracked =>
      'This wallet does not track its balance - turn tracking on to adjust it';

  @override
  String get multiPickCategoriesTitle => 'Choose categories';

  @override
  String get multiPickWalletsTitle => 'Choose wallets';

  @override
  String get multiPickSearch => 'Search';

  @override
  String get multiPickIncludeChildren => 'Include subcategories';

  @override
  String get multiPickEmpty => 'Nothing here yet';

  @override
  String get multiPickNoMatch => 'No match';

  @override
  String multiPickConfirm(int count) {
    return 'Done ($count)';
  }

  @override
  String get bgFilterActive => 'Active';

  @override
  String get bgFilterEnded => 'Ended';

  @override
  String get bgFilterArchived => 'Archived';

  @override
  String get bgSortRisk => 'Closest to the limit';

  @override
  String get bgSortName => 'Name';

  @override
  String get bgSortNewest => 'Newest';

  @override
  String bgSortChip(String sort) {
    return 'Sort: $sort';
  }

  @override
  String get bgSummaryCaption => 'Current period of every budget';

  @override
  String get bgStatActive => 'Active';

  @override
  String get bgStatOver => 'Over budget';

  @override
  String get bgStatWarn => 'Near the limit';

  @override
  String get bgStatPace => 'On pace to exceed';

  @override
  String get bgStatusOver => 'Over';

  @override
  String get bgStatusWarn => 'Near limit';

  @override
  String get bgStatusPace => 'On pace to exceed';

  @override
  String get bgStatusEnded => 'Ended';

  @override
  String get bgStatusArchived => 'Archived';

  @override
  String get bgStatusUpcoming => 'Not started';

  @override
  String get bgListEmptyEnded => 'No ended budgets yet';

  @override
  String get bgListEmptyArchived => 'No archived budgets';

  @override
  String get bgRuleDaily => 'Daily';

  @override
  String get bgRuleWeekly => 'Weekly';

  @override
  String get bgRuleMonthly => 'Monthly';

  @override
  String get bgRuleYearly => 'Yearly';

  @override
  String bgRowRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String get bgRowOpenEnded => 'No end date';

  @override
  String bgRowSince(String date) {
    return 'Since $date';
  }

  @override
  String bgRowStartsOn(String date) {
    return 'Starts $date';
  }

  @override
  String bgRowDaysLeft(int count) {
    return '$count days left';
  }

  @override
  String bgRowUsed(String used, String amount) {
    return 'Used $used of $amount';
  }

  @override
  String bgRowOverBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String bgRowExpected(String amount) {
    return 'Expected +$amount';
  }

  @override
  String get bgTabPeriods => 'Periods';

  @override
  String get bgTabSetup => 'Setup';

  @override
  String get bgPeriodNow => 'This period';

  @override
  String get bgPeriodOverridden => 'This period only';

  @override
  String bgPeriodLabelFallback(int seq) {
    return 'Period $seq';
  }

  @override
  String get bgHeroUsed => 'Used';

  @override
  String bgHeroOfLimit(String amount) {
    return 'of $amount';
  }

  @override
  String bgHeroRemaining(String amount) {
    return '$amount left';
  }

  @override
  String bgHeroOver(String amount) {
    return 'Over by $amount';
  }

  @override
  String bgLegendUsed(int pct) {
    return 'Used $pct%';
  }

  @override
  String bgLegendExpected(String amount) {
    return 'Expected +$amount';
  }

  @override
  String get bgSectionOverview => 'Overview';

  @override
  String bgOverviewDays(int elapsed, int total) {
    return 'Day $elapsed of $total';
  }

  @override
  String get bgTileAllowance => 'Can spend per day';

  @override
  String get bgTileAllowanceSub => 'after what is expected';

  @override
  String get bgTilePaceOver => 'On this pace over on';

  @override
  String bgTilePaceAvg(String amount) {
    return 'Avg $amount a day';
  }

  @override
  String get bgTilePaceOk => 'On this pace: within';

  @override
  String get bgTileForecastEnd => 'Forecast at the end';

  @override
  String bgTileForecastOver(String amount) {
    return 'Over by $amount';
  }

  @override
  String bgTileHistoryAvg(int count) {
    return 'Avg of last $count';
  }

  @override
  String get bgTilePerPeriod => 'per period';

  @override
  String get bgTileAvgMonthly => 'Avg per month';

  @override
  String get bgTileThisMonth => 'This month';

  @override
  String get bgTileRemainingAfter => 'Left after expected';

  @override
  String get bgSectionSource => 'By source';

  @override
  String get bgSourceNormal => 'Normal';

  @override
  String get bgSourceRecurring => 'Recurring';

  @override
  String get bgSourceEvent => 'Event';

  @override
  String get bgSourceUpcoming => 'Recurring · upcoming';

  @override
  String get bgSourcePending => 'Pending';

  @override
  String bgSourceCount(int count) {
    return '$count items';
  }

  @override
  String get bgSectionCategory => 'By category';

  @override
  String get bgNoCategory => 'No category';

  @override
  String get bgSectionPeriods => 'Periods';

  @override
  String get bgPeriodsDescription => 'Tap a period to view it or edit it alone';

  @override
  String get bgPeriodsAll => 'All earlier periods';

  @override
  String get bgSectionItems => 'Counted in this period';

  @override
  String get bgItemsDescription =>
      'Everything this budget counts, with its source';

  @override
  String get bgItemsMore => 'Show more';

  @override
  String get bgItemsEmpty => 'Nothing counted in this period yet';

  @override
  String get bgPeriodEditTitle => 'Edit this period only';

  @override
  String get bgPeriodAmountField => 'Amount for this period';

  @override
  String bgPeriodUseBase(String amount) {
    return 'Use the base amount ($amount)';
  }

  @override
  String get bgFieldAmountOnce => 'Budget';

  @override
  String get bgFieldRecurring => 'Recurring budget';

  @override
  String get bgFieldRecurringHint =>
      'The budget repeats every period; each period can be edited alone';

  @override
  String get bgSectionScope => 'What it counts';

  @override
  String get bgScopeDescription =>
      'Budgets may overlap; a row counts when it matches any one';

  @override
  String get bgScopeAll => 'Every expense';

  @override
  String get bgScopeCategories => 'Categories';

  @override
  String get bgScopeTags => 'Tags';

  @override
  String get bgScopeWallets => 'Wallets';

  @override
  String get bgScopeTagsHint =>
      'Event bills whose event has a tag with the same name count too';

  @override
  String get bgScopeChildren => '+ sub';

  @override
  String get bgScopeRequired =>
      'Pick what to count, or turn on \"Every expense\"';

  @override
  String get bgSectionPeriod => 'Time';

  @override
  String get bgFieldRepeat => 'Period';

  @override
  String get bgFieldStart => 'Start';

  @override
  String get bgFieldEnd => 'End';

  @override
  String get bgEndNone => 'No end';

  @override
  String get bgEndPickDate => 'Pick a date…';

  @override
  String bgEndPeriods(int count) {
    return '$count periods';
  }

  @override
  String get bgSectionWarn => 'Warning';

  @override
  String get bgFieldWarn => 'Warn at';

  @override
  String get bgWarnOff => 'No warning';

  @override
  String bgWarnPct(int pct) {
    return '$pct%';
  }

  @override
  String get bgWarnHint => 'Past 100% is always over budget';

  @override
  String get bgScopeChoiceTitle => 'Apply the new setup to';

  @override
  String get bgScopeFollowing => 'This and following periods';

  @override
  String get bgScopeAllPeriods => 'Every period (past ones too)';

  @override
  String get bgClose => 'Close the budget';

  @override
  String get bgCloseHint => 'Stops counting from today and moves to \"Ended\"';

  @override
  String get bgCloseConfirmTitle => 'Close this budget?';

  @override
  String get bgCloseConfirmBody =>
      'It stops counting from today and moves to \"Ended\".';

  @override
  String get bgRestore => 'Restore';

  @override
  String get bgNameRequired => 'Enter a name';

  @override
  String bgChipRecurring(String rule) {
    return '🔁 $rule';
  }

  @override
  String get pendingSavingConfirmTitle => 'Confirm as saving?';

  @override
  String get pendingSavingConfirm => 'Confirm';

  @override
  String get pendingSavingNoWallet => 'Pick a wallet before confirming';

  @override
  String get walletSavingsTitle => 'Savings';

  @override
  String get walletSavingsDescription =>
      'Money you have set aside in this wallet';

  @override
  String get walletSavingsBalance => 'Real balance';

  @override
  String get walletSavingsSaved => 'Saved';

  @override
  String get walletSavingsAvailable => 'Available to spend';

  @override
  String walletSavingsOver(String amount) {
    return 'Saved more than the real balance $amount';
  }

  @override
  String get quickModeSaving => 'Savings';

  @override
  String get savingEntryTitleHint => 'Note (optional)';

  @override
  String get savingEntryTarget => 'Save into';

  @override
  String get savingEntrySpare => 'Not allocated';

  @override
  String get savingEntryPickGoal => 'Pick a goal';

  @override
  String savingEntryAvailable(String amount) {
    return '$amount free to save';
  }

  @override
  String savingEntryOverAvailable(String amount) {
    return '$amount more than is free (still allowed)';
  }

  @override
  String get savingEntryWalletRequired => 'Pick the wallet to save from';

  @override
  String get savingEntrySaved => 'Saving recorded';

  @override
  String get walletSavingsAdd => 'Add savings';

  @override
  String get recurringKindTx => 'Transaction';

  @override
  String get recurringKindSaving => 'Saving';

  @override
  String get recurringFieldFromWallet => 'From wallet';

  @override
  String get recurringFieldGoal => 'Save into';

  @override
  String get recurringSavingName => 'Saving';

  @override
  String recurringSavingNameGoal(String goal) {
    return 'Saving · $goal';
  }

  @override
  String get sgv2MoveTitle => 'Move savings';

  @override
  String get sgv2WithdrawTitle => 'Withdraw savings';

  @override
  String get sgv2MoveFrom => 'From';

  @override
  String get sgv2MoveTo => 'To';

  @override
  String get sgv2WalletsCard => 'Wallets';

  @override
  String get sgv2AmountLabel => 'Amount';

  @override
  String get sgv2SplitTitle => 'By wallet (automatic)';

  @override
  String get sgv2SplitEdit => 'Edit';

  @override
  String sgv2SplitHas(String amount) {
    return 'Has $amount';
  }

  @override
  String sgv2SumOk(String sum) {
    return 'Total $sum ✓';
  }

  @override
  String sgv2SumOff(String sum, String amount) {
    return 'Total $sum does not match $amount';
  }

  @override
  String get sgv2ReturnsTitle => 'If it goes back';

  @override
  String get sgv2Cancel => 'Cancel';

  @override
  String get sgv2MovePick => 'Move to where?';

  @override
  String get sgv2MoveSave => 'Move';

  @override
  String get sgv2WithdrawSave => 'Withdraw';

  @override
  String get sgv2ChartCaption => 'Saved so far';

  @override
  String get sgv2ChartActual => 'Saved / at this pace';

  @override
  String get sgv2ChartNeeded => 'Line needed';

  @override
  String sgv2ChartTarget(String amount) {
    return 'Goal $amount';
  }

  @override
  String get sgv2SpareName => 'Not allocated';

  @override
  String get sgv2NoOtherGoal => 'No other goal to move to';

  @override
  String get sgv2EntryDeleted => 'Saving entry deleted';

  @override
  String get profileCurrencyChangeTitle => 'Change currency?';

  @override
  String get profileCurrencyChangeMessage =>
      'Only the label changes. Your amounts are NOT converted: 100 stays 100.';

  @override
  String get profileCurrencyChangeConfirm => 'Change currency';

  @override
  String get bgSearchHint => 'Search budgets';

  @override
  String get bgNoMatch => 'No matching budgets';

  @override
  String get sgv2SearchHint => 'Search goals';

  @override
  String get recurringSearchHint => 'Search recurring';

  @override
  String get recurringNoMatch => 'No matching recurring';

  @override
  String get recurringSummaryMonth => 'Per month';

  @override
  String get recurringSummaryPay => 'Pay';

  @override
  String get recurringSummaryReceive => 'Receive';

  @override
  String get recurringSummaryNext => 'Next due';

  @override
  String get recurringStatusLabel => 'Status';

  @override
  String get accountsSearchHint => 'Search wallets';

  @override
  String get accountsNoMatch => 'No matching wallets';

  @override
  String get bgSummaryUsedCaption => 'Current period · total used';

  @override
  String bgSummaryRemaining(String amount) {
    return '$amount left in total';
  }

  @override
  String get bgTileAll => 'All';

  @override
  String get bgTileOk => 'Normal';

  @override
  String get bgStatusFieldLabel => 'Status';

  @override
  String get bgRowLeft => 'Left';

  @override
  String get bgRowOverAmount => 'Over';

  @override
  String get bgRowOneOff => 'One-off';

  @override
  String get fpWalletsTileCash => 'Wallets';

  @override
  String fpWalletsSavedLine(String saved, String available) {
    return 'Saved $saved · really available $available';
  }

  @override
  String get fpWalletsSortByType => 'By type';

  @override
  String get fpWalletsReorderChip => 'Reorder';

  @override
  String get fpWalletBalanceLabel => 'In the wallet';

  @override
  String fpWalletMonthIn(String month) {
    return '$month · in';
  }

  @override
  String fpWalletMonthOut(String month) {
    return '$month · out';
  }

  @override
  String fpWalletAvailableLegend(String amount) {
    return 'Available $amount';
  }

  @override
  String fpWalletSavedLegend(String amount) {
    return 'Saved $amount';
  }

  @override
  String fpWalletCardUsed(int pct, String limit) {
    return 'Used $pct% of the $limit limit';
  }

  @override
  String fpWalletCardLeft(String amount) {
    return '$amount left';
  }

  @override
  String fpWalletDueAlert(String date, int days) {
    return 'Payment due $date · in $days days';
  }

  @override
  String get fpWalletPayCard => 'Pay card';

  @override
  String get fpWalletSave => 'Save';

  @override
  String get fpWalletSettingsDesc =>
      'How this wallet counts in totals and reports';

  @override
  String get fpWalletCardSettingsDesc => 'How this card counts in reports';

  @override
  String get fpWalletArchiveConsequence =>
      'Counted nowhere, read-only, restorable';

  @override
  String get fpWalletRefLabel => 'Reference numbers';

  @override
  String get fpWalletRefHint => 'Used to match slips when scanning';

  @override
  String get fpWalletInviteLabel => 'Invite';

  @override
  String get fpWalletTrackOff => 'Off';

  @override
  String get fpWalletOwnerCaption => 'Owner';

  @override
  String get fpWalletMemberCaption => 'Member';

  @override
  String get fpTxNetCaption => 'Net';

  @override
  String fpTxAvgDaily(String amount) {
    return 'Avg spend $amount/day';
  }

  @override
  String get fpWalletDeleteLabel => 'Delete this wallet';

  @override
  String get fpWalletDeleteConsequence =>
      'See what is attached first · saved money stays, just unlinked from the wallet';

  @override
  String get fpWalletDeleteTitle => 'Delete this wallet?';

  @override
  String fpWalletDeleteBody(
    int transactions,
    int transfers,
    int system,
    int recurring,
    int savings,
    String amount,
  ) {
    return '$transactions transactions stay with no wallet ($transfers transfers) · $system opening / adjustment rows are deleted · $recurring recurring settings keep running · $savings saving entries ($amount) stay, unlinked from the wallet';
  }

  @override
  String get fpWalletDeleted => 'Wallet deleted';

  @override
  String get fpContactsNotLinked => 'Not linked to an app user';

  @override
  String fpContactsLinkedWith(String user) {
    return 'Linked with $user';
  }

  @override
  String get fpContactsSettingsDesc =>
      'The name used for this person across the app';

  @override
  String get fpContactsLinkSection => 'Link account';

  @override
  String get fpContactsLinkSectionDesc =>
      'Link to an app user and match names in splits';

  @override
  String get fpContactsArchiveConsequence =>
      'Hidden from the list and person pickers; debts unchanged';

  @override
  String get fpContactsDeleteConsequence =>
      'Old records keep just the name; amounts unchanged';

  @override
  String get fpDebtsTotalCaption => 'Total outstanding';

  @override
  String fpDebtsOwedToMeTile(int count) {
    return 'To receive · $count people';
  }

  @override
  String fpDebtsIOweTile(int count) {
    return 'To pay · $count people';
  }

  @override
  String fpDebtsOver30(int count) {
    return 'Over 30 days: $count people';
  }

  @override
  String fpDebtsDaysOutstanding(int count) {
    return 'Outstanding $count days';
  }

  @override
  String get fpDebtsIncludeCleared => 'Show cleared';

  @override
  String get fpDebtsSortOldest => 'Longest owed';

  @override
  String get fpDebtsSortAmount => 'Largest';

  @override
  String get fpDebtsSortRecent => 'Latest';

  @override
  String get fpDebtsMessageLabel => 'Summary message · editable before sending';

  @override
  String get fpDebtsCopy => 'Copy';

  @override
  String get fpDebtsShare => 'Share';

  @override
  String get fpDebtsCopied => 'Message copied';

  @override
  String get fpDebtsCycleHeader => 'Where the balance comes from';

  @override
  String fpDebtsCycleHeaderSince(String date) {
    return 'Where the balance comes from · since cleared $date';
  }

  @override
  String get fpDebtsEarlierHeader => 'Earlier cycle · cleared';

  @override
  String get fpDebtsEarlierLink => 'Earlier cycles';

  @override
  String fpBudgetsRangeDay(String range, int elapsed, int total) {
    return '$range · day $elapsed/$total';
  }

  @override
  String get fpBudgetsLeftLabel => 'Still available';

  @override
  String get fpBudgetsOverLabel => 'Over budget';

  @override
  String fpBudgetsLimitTarget(String amount) {
    return '/ $amount';
  }

  @override
  String fpBudgetsUsedCaption(String amount) {
    return 'Used $amount';
  }

  @override
  String fpBudgetsPaceCaption(int pct) {
    return 'Should be at $pct% by today';
  }

  @override
  String get fpBudgetsTileDaily => 'Can spend per day';

  @override
  String get fpBudgetsTileProjected => 'Forecast at the end';

  @override
  String get fpBudgetsTileDaysLabel => 'Left';

  @override
  String fpBudgetsDaysValue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get fpBudgetsSettingsDesc =>
      'What this budget counts, and when it warns';

  @override
  String get fpBudgetsCountsWhat => 'What it counts';

  @override
  String get fpBudgetsWarnAt => 'Warn at';

  @override
  String get fpBudgetsRepeat => 'Repeat every period';

  @override
  String get fpBudgetsRepeatCaption =>
      'Each period\'s limit can be edited on its own';

  @override
  String get fpBudgetsTabItems => 'This period';

  @override
  String get fpBudgetsTabPeriods => 'All periods';

  @override
  String get fpBudgetsLimitLabel => 'Budget limit';

  @override
  String get fpBudgetsReasonAll => 'Counted because: every expense';

  @override
  String fpBudgetsReasonCategory(String name) {
    return 'Counted because: category $name';
  }

  @override
  String fpBudgetsReasonSubCategory(String name) {
    return 'Counted because: sub-category of $name';
  }

  @override
  String get fpBudgetsReasonSubCategoryAny =>
      'Counted because: sub-category of a counted category';

  @override
  String fpBudgetsReasonTag(String name) {
    return 'Counted because: tag $name';
  }

  @override
  String fpBudgetsReasonWallet(String name) {
    return 'Counted because: wallet $name';
  }

  @override
  String fpBudgetsPeriodReset(String amount) {
    return 'Back to the base amount ($amount)';
  }

  @override
  String get fpBudgetsCloseConsequence =>
      'Ends this budget, no new periods, old ones stay visible';

  @override
  String get fpBudgetsArchiveConsequence =>
      'Hidden, not counted in totals, restorable';

  @override
  String get fpBudgetsRestoreConsequence =>
      'Back in the list and counted again';

  @override
  String get fpBudgetsDeleteConsequence => 'Deleted for good, every period';

  @override
  String get fpGoalsListCaption => 'Total savings now';

  @override
  String fpGoalsMonthShortLine(String amount) {
    return 'Still short this month $amount';
  }

  @override
  String fpGoalsSpareLine(String amount) {
    return '🐷 Not allocated $amount ›';
  }

  @override
  String fpGoalsStatusChip(String status) {
    return 'Status: $status';
  }

  @override
  String get fpGoalsGroupShort => 'Still short this month';

  @override
  String get fpGoalsGroupDone => 'Done this month ✓';

  @override
  String get fpGoalsGroupNoPlan => 'No monthly plan yet';

  @override
  String fpGoalsRowShort(String amount) {
    return 'Short $amount';
  }

  @override
  String fpGoalsEtaOn(String date) {
    return 'Goal $date';
  }

  @override
  String fpGoalsEtaBehind(String date, int n) {
    return 'Goal $date · $n months late';
  }

  @override
  String get fpGoalsBehind => 'Behind plan';

  @override
  String get fpGoalsReached => 'Reached';

  @override
  String get fpGoalsClosed => 'Closed';

  @override
  String get fpGoalsSavedLabel => 'Saved';

  @override
  String fpGoalsTargetSuffix(String target, int pct) {
    return '/ $target · $pct%';
  }

  @override
  String fpGoalsDaysLeft(int count) {
    return '$count days left';
  }

  @override
  String get fpGoalsTileShort => 'Short this month';

  @override
  String get fpGoalsTileSaved => 'Saved this month';

  @override
  String get fpGoalsTileNeeded => 'Needed / month';

  @override
  String get fpGoalsActionSave => 'Save';

  @override
  String get fpGoalsActionRestore => 'Restore';

  @override
  String get fpGoalsSettingsDesc => 'Save automatically';

  @override
  String fpGoalsAutoCaption(String day, String amount, String wallet) {
    return '$day · $amount from $wallet';
  }

  @override
  String get fpGoalsAutoOffHint =>
      'Turn on to get a saving to confirm every month';

  @override
  String get fpGoalsAutoEdit => 'Edit amount, day and wallet';

  @override
  String get fpGoalsAutoSheetTitle => 'Auto-saving';

  @override
  String get fpGoalsAutoDay => 'Day of the month';

  @override
  String get fpGoalsAutoFrom => 'Take from';

  @override
  String get fpGoalsNoWallet => 'No wallet';

  @override
  String get fpGoalsChartActual => 'Saved';

  @override
  String get fpGoalsAutoTag => 'Auto';

  @override
  String fpGoalsPlanLeft(String saved, String left) {
    return 'Saved $saved · $left to go';
  }

  @override
  String fpGoalsPlanNeeded(String amount) {
    return 'Save $amount/month';
  }

  @override
  String get fpGoalsCloseConsequence =>
      'Move the money to “Not allocated” or back to its wallets';

  @override
  String get fpGoalsArchiveConsequence =>
      'Hidden, not counted, can be restored';

  @override
  String get fpGoalsArchiveNeedsClose => 'Close the goal first';

  @override
  String get fpGoalsArchiveHasSavings => 'Close the goal before archiving it';

  @override
  String get fpGoalsDeleteConsequence =>
      'Deleted for good, with its saving history';

  @override
  String get fpGoalsArchiveConfirmBody =>
      'Hide this goal. It is not counted and can be restored later.';

  @override
  String get fpGoalsDeleteConfirmBody =>
      'Delete this goal for good, with its saving history.';

  @override
  String get fpGoalsRefreshFailed => 'Refresh failed, showing the latest data';

  @override
  String get fpEventsSummaryCaption => 'Active events · my share';

  @override
  String fpEventsPaidLine(String paid, String receivable) {
    return 'I paid $paid → owed $receivable';
  }

  @override
  String get fpEventsTileActive => 'Active';

  @override
  String get fpEventsTileUnsettled => 'Not settled';

  @override
  String get fpEventsTileEnded => 'Ended';

  @override
  String get fpEventsSortRecent => 'Latest first';

  @override
  String get fpEventsSortOldest => 'Oldest first';

  @override
  String get fpEventsSortAmount => 'Biggest first';

  @override
  String get fpEventsCreate => 'Create event';

  @override
  String fpEventsRowSpent(String amount) {
    return 'Spent $amount';
  }

  @override
  String fpEventsRowShare(String amount) {
    return 'My share $amount';
  }

  @override
  String get fpEventsOwed => 'Owed to me';

  @override
  String get fpEventsOwe => 'I owe';

  @override
  String get fpEventsSpentTotal => 'Total spent';

  @override
  String fpEventsBudgetUsed(String spent, String planned) {
    return 'Spent $spent of $planned budget';
  }

  @override
  String fpEventsBudgetLeft(String amount) {
    return '$amount left';
  }

  @override
  String fpEventsBudgetOver(String amount) {
    return 'Over by $amount';
  }

  @override
  String get fpEventsMyShare => 'My share';

  @override
  String get fpEventsIncomeTotal => 'Total income';

  @override
  String get fpEventsMyTags => 'My tags';

  @override
  String get fpEventsTagPick => 'Pick';

  @override
  String get fpEventsMembersTitle => 'Members · who paid / who owes';

  @override
  String get fpEventsManage => 'Manage ›';

  @override
  String fpEventsMemberPaid(String amount) {
    return 'Paid $amount';
  }

  @override
  String fpEventsMemberOwed(String amount) {
    return 'Owed $amount';
  }

  @override
  String fpEventsMemberOwe(String amount) {
    return 'Owes $amount';
  }

  @override
  String get fpEventsInvite => 'Invite';

  @override
  String get fpEventsBillsSearchHint => 'Search bills in this event';

  @override
  String get fpEventsPayerFilter => 'Paid by';

  @override
  String get fpEventsPayerAll => 'Everyone';

  @override
  String get fpEventsTagsFilterLabel => 'Event tags';

  @override
  String get fpEventsTagAll => 'All';

  @override
  String fpEventsSplitCount(int count) {
    return 'Split $count';
  }

  @override
  String fpEventsPaidBy(String name) {
    return '$name paid';
  }

  @override
  String get fpEventsBudgetLabel => 'Planned budget (optional)';

  @override
  String get fpEventsBudgetHelper =>
      'What you intend to spend · clear to hide the plan';

  @override
  String get fpEventsDatesLabel => 'Start – end';

  @override
  String get fpEventsSettingsDesc =>
      'Bill tags in this event, shared with every member';

  @override
  String get fpEventsManageTags => 'Manage event tags';

  @override
  String fpEventsTagsCount(int count) {
    return '$count tags';
  }

  @override
  String get fpEventsArchiveConsequence =>
      'Hidden, not counted, can be restored';

  @override
  String get fpEventsDeleteConsequence => 'You choose whether its bills go too';

  @override
  String get fpEventsRestore => 'Restore event';

  @override
  String get fpEventsRestoreConsequence => 'Back to in progress';

  @override
  String get fpEventsArchived => 'Event archived';

  @override
  String get fpEventsRestored => 'Event restored';

  @override
  String get fpEventsArchiveConfirmTitle => 'Archive this event?';

  @override
  String get fpEventsArchiveConfirmBody =>
      'Hidden, not counted and read-only. You can restore it any time.';

  @override
  String get fpEventsTagsTitle => 'Event tags · shared with members';

  @override
  String get fpEventsTagAdd => 'Add event tag';

  @override
  String get fpEventsTagsImportAll => 'Import all to my tags';

  @override
  String get fpEventsTagRename => 'Rename';

  @override
  String get fpEventsTagRestyle => 'Change icon / colour';

  @override
  String get fpEventsTagImportOne => 'Import to my tags';

  @override
  String get fpEventsTagNameLabel => 'Tag name';

  @override
  String get fpEventsTagNameRequired => 'Enter a tag name';

  @override
  String get fpEventsTagNewTitle => 'New event tag';

  @override
  String get fpEventsTagRenameTitle => 'Rename tag';

  @override
  String get fpEventsTagIconTitle => 'Tag icon';

  @override
  String fpEventsTagDeleteTitle(String name) {
    return 'Delete tag $name?';
  }

  @override
  String get fpEventsTagDeleteBody => 'Bills using it lose the tag.';

  @override
  String get fpEventsTagsEmpty => 'No event tags yet';

  @override
  String fpEventsTagBills(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count bills',
      one: '1 bill',
    );
    return '$_temp0';
  }

  @override
  String get fpEventsTagInMine => 'In my tags already';

  @override
  String get fpEventsLoadFailed => 'Couldn\'t refresh · showing the last data';

  @override
  String get categoryDeleteConsequence =>
      'Deleted for good · its transactions will have no category';

  @override
  String categoryMonthSpentLabel(String month, int count) {
    return '$month spent · $count transactions ›';
  }

  @override
  String categoryMonthEarnedLabel(String month, int count) {
    return '$month received · $count transactions ›';
  }

  @override
  String get notifSettingsLegend =>
      'Off: no notice · Notify: a notice with a one-tap button · Auto: done for you, then you are told what was done';

  @override
  String get notifStateOff => 'Off';

  @override
  String get notifStateNotify => 'Notify';

  @override
  String get notifStateAuto => 'Auto';

  @override
  String get notifGroupRecurring => 'Recurring';

  @override
  String get notifTypeRecurringDue => 'Recurring items are due';

  @override
  String get notifTypeRecurringDueHint =>
      'Drafts always wait in Pending · Off = no notice';

  @override
  String get notifTypeRecurringEnding => 'A recurring is about to end';

  @override
  String get notifTypeRecurringEndingHint => 'A few items left · extend it?';

  @override
  String get notifTypeRequestsHint =>
      'Needs an answer, so it can\'t be turned off';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsSectionMoney => 'Money';

  @override
  String get settingsSectionData => 'Data';

  @override
  String get settingsCurrencyHint =>
      'Changes the label only, amounts are not converted';

  @override
  String get settingsMainWallet => 'Main wallet';

  @override
  String get settingsMainWalletHint => 'Used as the default when recording';

  @override
  String get settingsMainWalletNone => 'Not set';

  @override
  String get settingsArchived => 'Archive';

  @override
  String get settingsArchivedHint =>
      'Wallets, budgets, goals, events, contacts';

  @override
  String get settingsExportCsv => 'Export CSV';

  @override
  String get settingsComingIn04 => '0.4';

  @override
  String get profileSectionSecurity => 'Security';

  @override
  String get settingsSaveFailed => 'Could not save, try again';

  @override
  String get notifTileAll => 'All';

  @override
  String get notifTileNeedsAnswer => 'Needs answer';

  @override
  String get notifTileUnread => 'Unread';

  @override
  String get notifTileHidden => 'Hidden';

  @override
  String get notifCardCaption => 'Needs answer';

  @override
  String notifCardMain(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      zero: 'Nothing',
    );
    return '$_temp0';
  }

  @override
  String notifCardUnread(int count) {
    return '· unread $count';
  }

  @override
  String get notifReadAllTooltip => 'Mark all as read';

  @override
  String get notifSettingsTooltip => 'Notification settings';

  @override
  String get notifRestore => 'Restore';

  @override
  String get notifUndo => 'Undo';

  @override
  String get notifEmptyNeedsAnswer => 'Nothing waiting for an answer';

  @override
  String get notifEmptyHidden => 'No hidden notifications';

  @override
  String get notifActionExtend => 'Extend';

  @override
  String get notifActionLetEnd => 'Let it end';

  @override
  String get notifActionOpenPending => 'Open pending ›';

  @override
  String get archivedGroupWallets => 'Wallets';

  @override
  String get archivedGroupBudgets => 'Budgets';

  @override
  String get archivedGroupGoals => 'Goals';

  @override
  String get archivedGroupEvents => 'Events';

  @override
  String get archivedGroupContacts => 'Contacts';

  @override
  String get archivedGroupRecurring => 'Recurring';

  @override
  String archivedOn(String date) {
    return 'Archived $date';
  }

  @override
  String get archivedRestore => 'Restore';

  @override
  String archivedRestored(String name) {
    return 'Restored $name';
  }

  @override
  String get archivedEmpty => 'Nothing archived';

  @override
  String get archivedEmptyMessage =>
      'Archived items show here. Restore them any time.';

  @override
  String get txRecurringPick => 'Pick a recurring';

  @override
  String get txRecurringUnlink => 'Unlink';

  @override
  String get recurringPickerTitle => 'Link to a recurring';

  @override
  String get recurringPickerGroupRecurring => 'Recurring';

  @override
  String get recurringPickerGroupReminders => 'Payment reminders';

  @override
  String get recurringPickerAwaitingAmount => 'Amount pending';

  @override
  String get recurringPickerCreate =>
      'Create a recurring from this transaction';

  @override
  String get recurringPickerEmpty => 'No recurring to link to';

  @override
  String recurringPickerPeriod(String date) {
    return 'Period $date';
  }

  @override
  String get recurringPickerStatusUpcoming => 'not yet due';

  @override
  String get recurringPickerStatusPending => 'awaiting confirmation';

  @override
  String get recurringPickerStatusNotCreated => 'not paid yet';

  @override
  String get recurringPickerStatusReminder => 'enter the amount';

  @override
  String recurringLinkAskAmount(String rule, String tx) {
    return 'The amount differs from the recurring ($rule → $tx). Update the recurring\'s amount too?';
  }

  @override
  String get recurringLinkAskNo => 'No';

  @override
  String get recurringLinkAskYes => 'Update';

  @override
  String get recurringLinked => 'Linked to the recurring';

  @override
  String get recurringLinkedAmountUpdated => 'Recurring amount updated';

  @override
  String get recurringLinkAlreadyLinked =>
      'That period is already linked (or this transaction is linked already)';

  @override
  String get fpRecurringTabReminder => 'Reminders';

  @override
  String get fpRecurringTabCalendar => 'Calendar';

  @override
  String get fpRecurringListCaption => 'Next 30 days to pay';

  @override
  String fpRecurringAwaitingAlert(int n) {
    return '$n waiting for an amount';
  }

  @override
  String fpRecurringMonthLine(String pay, String receive) {
    return 'Per month: pay $pay · receive $receive';
  }

  @override
  String get fpRecurringPausedGroup => 'Paused';

  @override
  String get fpRecurringGroupDue => 'Due · in pending';

  @override
  String get fpRecurringGroupComing => 'Coming up';

  @override
  String get fpRecurringAwaitingAmount => 'No amount yet';

  @override
  String get fpRecurringAddReminder => 'Add a reminder';

  @override
  String get fpRecurringKindSubscription => 'Subscription';

  @override
  String get fpRecurringKindInstallment => 'Installment';

  @override
  String get fpRecurringKindIncome => 'Income';

  @override
  String get fpRecurringKindReminder => 'Reminder';

  @override
  String get fpRecurringRefreshFailed =>
      'Refresh failed, showing the latest data';

  @override
  String get fpRecurringCalendarNone => 'Nothing on this day';

  @override
  String get fpRecurringPerRound => 'Each time';

  @override
  String get fpRecurringAwaitingValue => 'Enter amount';

  @override
  String get fpRecurringTileYearly => 'Per year';

  @override
  String get fpRecurringTileSaved => 'Saved';

  @override
  String get fpRecurringTilePending => 'To confirm';

  @override
  String get fpRecurringTileInstallment => 'Installment';

  @override
  String fpRecurringCountUnit(int n) {
    return '$n times';
  }

  @override
  String fpRecurringAlertAwaiting(String due) {
    return 'Enter the amount · $due';
  }

  @override
  String get fpRecurringInfoSpan => 'Start – end';

  @override
  String fpRecurringNextInline(String date, String due) {
    return 'next $date ($due)';
  }

  @override
  String get fpRecurringTrialUntil => 'Free trial until';

  @override
  String get fpRecurringTabPast => 'Past';

  @override
  String get fpRecurringTabUpcoming => 'Upcoming';

  @override
  String fpRecurringNextTitle(String due) {
    return 'Next · $due';
  }

  @override
  String get fpRecurringNextCaption => 'Becomes a draft in pending on that day';

  @override
  String get fpRecurringEditedChip => 'Edited';

  @override
  String get fpRecurringActEditAmount => 'Edit amount';

  @override
  String get fpRecurringActMove => 'Move date';

  @override
  String get fpRecurringActSkip => 'Skip';

  @override
  String get fpRecurringActEnterAmount => 'Enter amount';

  @override
  String fpRecurringThenTitle(int n) {
    return '$n upcoming in total';
  }

  @override
  String get fpRecurringMoreDates => 'More ›';

  @override
  String fpRecurringChipEdited(String date, String amount) {
    return '$date · $amount';
  }

  @override
  String fpRecurringChipSkipped(String date) {
    return '$date · skipped';
  }

  @override
  String get fpRecurringOccEditTitle => 'Edit this occurrence';

  @override
  String get fpRecurringOccMoveTitle => 'Move this occurrence';

  @override
  String get fpRecurringOccEnterTitle => 'Enter the amount';

  @override
  String get fpRecurringOccDate => 'Date';

  @override
  String get fpRecurringOccAmount => 'Amount';

  @override
  String get fpRecurringSkipTitle => 'Skip this occurrence?';

  @override
  String get fpRecurringSkipBody =>
      'It will not become a draft in pending. You can restore it later.';

  @override
  String get fpRecurringAmountLabel => 'Amount / time';

  @override
  String get fpRecurringAmountOptional => 'Amount / time (optional)';

  @override
  String get fpRecurringReminderHint =>
      'No amount needed. On the day, enter the real amount in the draft.';

  @override
  String get fpRecurringFieldCount => 'Number of payments';

  @override
  String fpRecurringCountValue(int n) {
    return '$n payments';
  }

  @override
  String get fpRecurringCountRequired =>
      'An installment needs a number of payments';

  @override
  String get fpRecurringFieldMode => 'Type';

  @override
  String get fpRecurringFieldPayFrom => 'Pay from';

  @override
  String get fpRecurringFieldIntoWallet => 'Into wallet';

  @override
  String get fpRecurringFieldFromWallet => 'From wallet';

  @override
  String get fpRecurringSelectDone => 'Done';

  @override
  String get fpRecurringArchiveConsequence =>
      'Stops making new occurrences. Hidden, can be restored.';

  @override
  String get fpRecurringRestoreConsequence =>
      'Active again, making occurrences';

  @override
  String get fpRecurringDeleteConsequence =>
      'Deletes this recurring with its unsaved occurrences';

  @override
  String get fpRecurringDuplicate => 'Duplicate';

  @override
  String get fpRecurringDuplicateConsequence =>
      'Creates the same recurring, starting today';

  @override
  String fpM5ContactDeleteDebts(int n) {
    return '$n debt records keep only the name';
  }

  @override
  String fpM5ContactDeleteMembers(int n) {
    return 'Member of $n events';
  }

  @override
  String get fpM5ContactDeleteLinked =>
      'Linked to an account, the link is removed';

  @override
  String fpM5BudgetDeleteBody(
    int periods,
    int overridden,
    int categories,
    int wallets,
  ) {
    return 'Deletes $periods periods ($overridden adjusted) · $categories categories · $wallets wallets. Transactions are not affected.';
  }

  @override
  String fpM5GoalDeleteBody(int n) {
    return 'Deletes this goal for good. $n saving entries stay, detached from it.';
  }

  @override
  String get fpM5GoalsSortTooltip => 'Sort';

  @override
  String get fpM5GoalsSortCreated => 'By created';

  @override
  String get fpM5GoalsSortDeadline => 'Nearest deadline';

  @override
  String get fpM5GoalsSortProgress => 'Progress';

  @override
  String get fpM5GoalsSortRemaining => 'Remaining';

  @override
  String get fpM5GoalsSortName => 'Name';

  @override
  String fpM5GoalsMonthSaved(String saved, String plan) {
    return 'Saved $saved / $plan';
  }

  @override
  String get fpM5GoalsChartPlan => 'On plan';

  @override
  String get fpM5bRecurringPerMonth => 'Per month';

  @override
  String get fpM5bRecurringAmountPerTime => 'Amount each time';

  @override
  String fpM5bRecurringDeleteNumbers(int items, int drafts, int linked) {
    return 'This deletes $items occurrences, $drafts waiting drafts and touches $linked saved records.';
  }

  @override
  String fpM5bEventDeleteNumbers(int bills, int members) {
    return 'This deletes $bills bills and $members members.';
  }
}
