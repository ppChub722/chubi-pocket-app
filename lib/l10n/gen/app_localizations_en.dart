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
  String get categorySystemDebtReceived => 'Debt collected';

  @override
  String get categorySystemDebtPaid => 'Debt repayment';

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
  String get commonClose => 'Close';

  @override
  String get commonEdit => 'Edit';

  @override
  String get commonLongPressToEdit => 'Long-press to edit';

  @override
  String get commonSearch => 'Search';

  @override
  String get commonCustomValue => 'Custom';

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
  String get contactPickerEmpty => 'No contacts yet — type a name above';

  @override
  String get errorNetworkTitle => 'No connection';

  @override
  String get errorNetworkMessage => 'Check your internet and try again.';

  @override
  String get errorGenericTitle => 'Something went wrong';

  @override
  String get errorGenericMessage => 'Please try again';

  @override
  String get errorValidationMessage =>
      'Some fields aren’t valid — please check them';

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
  String get authRegisterCurrencyLabel => 'Currency';

  @override
  String get authRegisterSubmit => 'Create account';

  @override
  String get authRegisterIncomplete => 'Fill in every field correctly';

  @override
  String get authTelegramWaitTitle => 'Waiting for Telegram';

  @override
  String get authTelegramWaitBody =>
      'Tap “Confirm” in the bot chat, then come back to this app';

  @override
  String get authTelegramReopen => 'Open Telegram again';

  @override
  String get authTelegramCheck => 'Check again';

  @override
  String get authTelegramExpired =>
      'The link expired. Start signing in with Telegram again';

  @override
  String get authTelegramOpenFailed =>
      'Could not open Telegram. Is the Telegram app installed?';

  @override
  String get authTelegramSignupTitle => 'Create an account with Telegram';

  @override
  String get authTelegramSignupPhoto =>
      'Your Telegram profile picture will be your picture';

  @override
  String get authTelegramUsernameTaken =>
      'That username is taken. We filled in a free one';

  @override
  String get authTelegramAlreadyLinked =>
      'This Telegram is already linked to an account. Try signing in with Telegram again';

  @override
  String get authTelegramUnavailable => 'Telegram is not available right now';

  @override
  String get authRegistrationClosed => 'Sign-up is closed right now';

  @override
  String get authRegisterGoToLogin => 'Already have an account? Log in';

  @override
  String get authRegisterUsernameTaken => 'That username is already taken.';

  @override
  String get authRegisterEmailTaken => 'That email is already registered.';

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
  String get homeComingSoonTitle => 'Coming Soon';

  @override
  String get homeComingSoonMessage =>
      'The overview is being reworked. Use the tabs below in the meantime.';

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
  String get navMore => 'More';

  @override
  String get navNotificationsTooltip => 'Notifications';

  @override
  String get navProfileTooltip => 'Profile & settings';

  @override
  String get accountsAddNew => 'Add wallet';

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
  String get accountDetailNotFound => 'Wallet not found';

  @override
  String get accountDetailNotFoundMessage =>
      'This wallet may have been archived or deleted.';

  @override
  String get accountDetailAdjustBalance => 'Adjust balance';

  @override
  String get accountDetailArchive => 'Archive';

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
  String get accountDetailTransactionsTitle => 'Transactions';

  @override
  String get accountDetailTabOverview => 'Overview';

  @override
  String get accountFormTitle => 'New wallet';

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
  String get accountFormCreditLimitLabel => 'Credit limit';

  @override
  String get accountFormCreditLimitRequired => 'Required for credit wallets';

  @override
  String get accountFormStatementDateLabel => 'Statement date';

  @override
  String get accountFormPaymentDueLabel => 'Payment due';

  @override
  String get accountFormMinimumPaymentLabel => 'Minimum payment';

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
  String get contactNotFound => 'Contact not found';

  @override
  String get contactNameLabel => 'Name';

  @override
  String get contactNameHint => 'Name (required)';

  @override
  String get contactEmailHint => 'Optional | name@example.com';

  @override
  String get contactPhoneHint => 'Optional | 081-234-5678';

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
  String get contactDescriptionHint => 'Optional | e.g. a work friend';

  @override
  String get contactNoteHint => 'Optional | e.g. prefers PromptPay';

  @override
  String get contactLinkedLockedHint =>
      'Name and email come from their account';

  @override
  String get contactArchivedBadge => 'Archived';

  @override
  String get contactLinkRequest => 'Send link request';

  @override
  String get contactLinkRequestHint =>
      'If this email belongs to a user, they\'ll get a request';

  @override
  String get contactEmailFromAccount => 'From their account';

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
  String get contactWireTitle => 'Link names you typed before';

  @override
  String contactWireHint(int names, int splits) {
    return '$names names | $splits entries not linked to anyone';
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
  String get debtsOwedToMe => 'Owes me';

  @override
  String get debtsIOwe => 'I owe';

  @override
  String get debtsEven => 'Settled up';

  @override
  String get debtsSearchHint => 'Search name';

  @override
  String get debtsStatusAll => 'All';

  @override
  String get debtsEmptyMessage =>
      'Record who owes you or whom you owe — or split a bill from a transaction.';

  @override
  String get debtsNoMatch => 'No matching people';

  @override
  String get debtsPersonAddContact => 'Add to contacts';

  @override
  String get debtsPersonAddContactHint =>
      'Add this name to an existing contact or create a new one';

  @override
  String debtsPersonLinked(int count, String name) {
    return 'Linked $count debts to $name';
  }

  @override
  String get debtsPersonOpenContact => 'View contact';

  @override
  String get debtPay => 'Pay back';

  @override
  String get debtCounterpartyRequired => 'Add the person first';

  @override
  String get debtDirectionOwedToMe => 'To receive';

  @override
  String get debtDirectionIOwe => 'To pay';

  @override
  String get projectStatusActive => 'In progress';

  @override
  String get projectStatusCompleted => 'Completed';

  @override
  String get projectStatusCancelled => 'Cancelled';

  @override
  String get projectStatusArchived => 'Archived';

  @override
  String get projectsStatusLabel => 'Status';

  @override
  String get projectsSearchHint => 'Search events';

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
  String get projectNewTitle => 'New event';

  @override
  String get projectNameRequired => 'Name is required';

  @override
  String get projectIconLabel => 'Event icon';

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
  String get projectDeleted => 'Event deleted';

  @override
  String get projectTxEmpty => 'No transactions in this event yet';

  @override
  String get projectTxNoMatch => 'No matching transactions';

  @override
  String get projectTxDelete => 'Delete transaction';

  @override
  String get projectTxDeleteTitle => 'Delete this transaction?';

  @override
  String get projectResolveAmount => 'Amount';

  @override
  String get projectResolveCategory => 'Category (optional)';

  @override
  String get projectResolveCategoryNone => 'No category';

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
  String get projectTxPaidBy => 'Paid by';

  @override
  String get projectTxAddTag => 'New tag';

  @override
  String get projectTxTagHint => 'Tag name';

  @override
  String get projectTxSplitMember => 'Who';

  @override
  String get settingsThemeMint => 'Mint';

  @override
  String get settingsThemeSweet => 'Sweet';

  @override
  String get settingsNotifications => 'Notifications';

  @override
  String get settingsFontSample => 'Sample ภาษาไทย 123';

  @override
  String get notificationsTitle => 'Notifications';

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
  String get notifAccepted => 'Accepted | tap to open';

  @override
  String get notifRejectTitle => 'Decline this request?';

  @override
  String get notifRejectBody => 'They will not be told that you declined.';

  @override
  String get notifHidden => 'Hidden';

  @override
  String get notifGroupProjects => 'Events';

  @override
  String get notifGroupRequests => 'Invites and requests';

  @override
  String get notifTypeSplitCreated => 'Someone shares a bill with me';

  @override
  String get notifTypeProjectTxForYou =>
      'An event transaction is recorded for me';

  @override
  String get notifTypeProjectTxChanged => 'An event transaction is edited';

  @override
  String get notifTypeProjectAdded => 'Added to an event';

  @override
  String get notifActionCopyToBook => 'Add to my book';

  @override
  String get notifActionUpdateCopy => 'Update to match';

  @override
  String get notifActionSkip => 'Skip';

  @override
  String get notifActionDone => 'Done | tap to open';

  @override
  String notifProjectAdded(String actor, String project) {
    return '$actor added you to $project';
  }

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
  String get txDetailSourceProject => 'Event';

  @override
  String get txDeleted => 'Transaction deleted';

  @override
  String get txSplitEqually => 'Split equally';

  @override
  String get txSplitAddPerson => 'Add person';

  @override
  String get txSplitRemove => 'Remove';

  @override
  String get txSplitExceeds =>
      'Split total is more than the transaction amount';

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
  String get accountsSummaryNet => 'My net balance';

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
  String get moreDebts => 'Debts';

  @override
  String get moreNotifications => 'Notifications';

  @override
  String get moreBudgets => 'Budgets';

  @override
  String get moreSavingGoals => 'Saving goals';

  @override
  String get moreCategoriesDesc => 'Group your entries';

  @override
  String get moreTagsDesc => 'Labels for quick search';

  @override
  String get moreContactsDesc => 'People in your bills and debts';

  @override
  String get moreProjectsDesc => 'Trips and shared-cost activities';

  @override
  String get moreDebtsDesc => 'Loans and money owed';

  @override
  String get moreBudgetsDesc => 'Keep monthly spending in check';

  @override
  String get moreSavingGoalsDesc => 'Save for what you want';

  @override
  String get moreChipOverBudget => 'Over budget';

  @override
  String get moreChipNearBudget => 'Near limit';

  @override
  String get moreChipGoalReached => 'Goal reached';

  @override
  String get moreChipNearGoal => 'Near goal';

  @override
  String moreChipDueSoon(int count) {
    return '$count due soon';
  }

  @override
  String moreChipReceivable(String amount) {
    return 'To receive $amount';
  }

  @override
  String moreChipPayable(String amount) {
    return 'To pay $amount';
  }

  @override
  String moreChipOpenEvents(int count) {
    return '$count open';
  }

  @override
  String moreChipPending(int count) {
    return '$count to confirm';
  }

  @override
  String moreChipUnread(int count) {
    return '$count unread';
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
  String get categoryFormNameRequired => 'Required';

  @override
  String get categoryFormNameTooLong => 'Max 100 characters';

  @override
  String get categoryFormNameDuplicate =>
      'Another category at this level already uses this name';

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
  String get projectDeleteThis => 'Delete this event';

  @override
  String get transactionDeleteThis => 'Delete this transaction';

  @override
  String get transactionDeleteConsequence =>
      'Deleted for good | the wallet balance goes back to before it was saved';

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
  String get tagDeleteConfirmAction => 'Delete';

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
  String get settingsChangePassword => 'Change password';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsAppearance => 'Appearance';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsAppVersion => 'App version';

  @override
  String get settingsLogout => 'Log out';

  @override
  String get settingsLogoutDialogTitle => 'Log out of ChubiPocket?';

  @override
  String get settingsLogoutDialogBody => 'Back to the sign-in screen.';

  @override
  String get editProfileTitle => 'Edit profile';

  @override
  String get editProfileDisplayNameLabel => 'Display name';

  @override
  String get editProfileUsernameLabel => 'Username';

  @override
  String get editProfileEmailLabel => 'Email';

  @override
  String get editProfileEmailInvalid => 'Enter a valid email address.';

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
  String get changePasswordSnackSuccess => 'Password updated';

  @override
  String get modeLight => 'Light';

  @override
  String get modeDark => 'Dark';

  @override
  String get modeSystem => 'System';

  @override
  String get amountLabel => 'Amount';

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
  String txDetailDeleteRepaymentBody(String amount) {
    return 'The debt\'s repaid amount goes down by $amount.';
  }

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
  String txSplitStatusOverpaidToThem(String amount) {
    return 'Overpaid $amount | you owe it back';
  }

  @override
  String txSplitStatusOverpaidByMe(String amount) {
    return 'Overpaid $amount | they owe it back';
  }

  @override
  String txSplitRepaidSoFar(String amount) {
    return 'Paid back $amount';
  }

  @override
  String get txSplitErrorContact => 'That contact can\'t be used any more';

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
  String get txDetailCreatedAt => 'Recorded';

  @override
  String get txDetailUpdatedAt => 'Last edited';

  @override
  String tagPickerCreateNamed(String name) {
    return 'Create “$name”';
  }

  @override
  String get txNoteAddHint => 'e.g. where, with whom';

  @override
  String get bgNoteHint =>
      'e.g. why this limit, or what you want to spend less on';

  @override
  String get projectNoteHint =>
      'e.g. where you stay, group rules, or the account to pay into';

  @override
  String get recurringNoteHint =>
      'e.g. contract number, billing day, or how you pay';

  @override
  String get fpGoalsNoteHint => 'e.g. what it is for, or how you plan to save';

  @override
  String get categoryNoteHint => 'e.g. which spending belongs here';

  @override
  String get debtNoteHint => 'e.g. what it was for';

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
  String get quickEventNameLabel => 'Event name';

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
  String get pendingSelectAll => 'Select all';

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
    return 'Saved $done | $failed left';
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
  String get pendingSavedAsDraft => 'Saved as a draft | it\'s in Pending';

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
  String get transactionFormAccountNone => 'Unspecified wallet';

  @override
  String get transactionFormAccountPickerTitle => 'Pick a wallet';

  @override
  String get transactionFormAccountPickerEmpty =>
      'No active wallets. Create one first.';

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
  String get savingGoalCompletedLabel => 'Goal reached';

  @override
  String get savingGoalFormTitle => 'New saving goal';

  @override
  String get savingGoalFormIconLabel => 'Icon';

  @override
  String get savingGoalFormNameRequired => 'Required';

  @override
  String get savingGoalFormTargetLabel => 'Target amount';

  @override
  String get savingGoalFormTargetInvalid => 'Enter a positive amount';

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
  String get savingGoalArchiveConfirmTitle => 'Archive this goal?';

  @override
  String get savingGoalArchiveConfirmAction => 'Archive';

  @override
  String get savingGoalDeleteConfirmTitle => 'Delete this goal?';

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
  String get budgetFormTitle => 'New budget';

  @override
  String get budgetFormAmountInvalid => 'Enter a positive amount';

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
  String get projectFormPlannedInvalid => 'Enter a positive amount';

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
  String get walletReportScopeTitle => 'In my reports';

  @override
  String get walletReportScopeNone => 'Not in reports';

  @override
  String get walletReportScopeOwn => 'Only my entries';

  @override
  String get walletReportScopeAll => 'In reports';

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
  String get quickCreateErrorTxNotFound =>
      'Some selected bills no longer exist — refresh and try again.';

  @override
  String get quickCreateErrorTxAlreadyInProject =>
      'Some selected bills already belong to another event — refresh and try again.';

  @override
  String get quickCreateErrorValidation =>
      'Something\'s not right — check the form and try again.';

  @override
  String get transactionsSearchHint =>
      'Search description | note | category | wallet';

  @override
  String get accountAdjustBalanceNewDebtLabel => 'New outstanding balance';

  @override
  String get accountAdjustBalanceDiffLabel => 'Difference';

  @override
  String accountAdjustBalanceWillCreate(String amount) {
    return 'This adds an \"Adjust balance\" transaction of $amount, dated today.';
  }

  @override
  String get accountIdentifiersTitle => 'Reference numbers';

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
  String get identifierKindLabel => 'Kind';

  @override
  String get identifierBankLabel => 'Bank';

  @override
  String get identifierBankNone => 'Not set';

  @override
  String get identifierValueLabel => 'Number';

  @override
  String get identifierValueTooShort => 'Needs at least 4 digits';

  @override
  String get identifierValueTooLong => 'Too long';

  @override
  String get identifierDelete => 'Remove this number';

  @override
  String get walletErrorInvalidIdentifier => 'That account number isn’t valid';

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
    return 'This is build $current | $required or newer is needed';
  }

  @override
  String get appUpdateAvailable => 'A new version is available';

  @override
  String get appUpdateAvailableAction => 'Update';

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
  String get commonMore => 'More';

  @override
  String get txShareMine => 'Your share';

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
  String get txPeriodDay => 'Day';

  @override
  String get txPeriodWeekHint =>
      'Tap any day — its whole week (Monday to Sunday)';

  @override
  String quickEventCreateNamed(String name) {
    return 'Create \"$name\"';
  }

  @override
  String get quickEventMembersInfo =>
      'The people you split with join the event as members';

  @override
  String get eventPickerTabOpen => 'Open';

  @override
  String get eventPickerTabClosed => 'Closed';

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
  String get accountsSortCustom => 'My order';

  @override
  String get accountsSortBalance => 'Balance, high to low';

  @override
  String get accountsSortName => 'Name';

  @override
  String get accountsSummaryCardDebt => 'Card debt';

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
  String get contactPickerFilterAll => 'All';

  @override
  String get contactPickerFilterContacts => 'Contacts';

  @override
  String get contactPickerFilterNotInContacts => 'Not in contacts';

  @override
  String get contactPickerFilterOwing => 'Owing';

  @override
  String get contactPickerFilterNoDebt => 'No debt';

  @override
  String get contactPickerNoMatch => 'No one matches';

  @override
  String get contactPickerTypeName => 'New name';

  @override
  String contactPickerUseName(Object name) {
    return 'Use the name \"$name\"';
  }

  @override
  String get txSplitNameHint => 'Name';

  @override
  String get accountIdentifiersHint =>
      'Only used to match accounts when scanning slips';

  @override
  String get detailManageTitle => 'Manage';

  @override
  String get draftExtrasNone => 'Not set';

  @override
  String get accountMembersSectionDescription =>
      'People who share this wallet with you';

  @override
  String get accountCreditSectionDescription =>
      'Statement day, due day and minimum payment for this card';

  @override
  String get walletMembersHistoryDescription =>
      'People who were in this wallet and have left';

  @override
  String get categorySettingsSectionDescription =>
      'Whether this category counts in reports and is used for fees';

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
      'Split the amount, put it in an event, or link a recurring';

  @override
  String get txSplitRowLabel => 'Split';

  @override
  String get txSplitPeopleLabel => 'Split with people';

  @override
  String get quickEventAdd => 'Add event';

  @override
  String get dayPickerLastShort => 'Last';

  @override
  String get profileCurrencyLabel => 'Currency';

  @override
  String get contactNicknameLabel => 'Nickname';

  @override
  String get contactNicknameHint => 'Optional | e.g. Mum';

  @override
  String get contactShowNicknameLabel => 'Show nickname';

  @override
  String get notOwnerError => 'Only the wallet owner can do this';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileEmailCannotClear => 'Once set, the email can\'t be removed';

  @override
  String get connectionOffline => 'Can\'t reach the server | trying again…';

  @override
  String get connectionReconnecting => 'Reconnecting…';

  @override
  String get connectionBack => 'Connected again';

  @override
  String get connectionRetry => 'Retry';

  @override
  String get uiLoadMoreFailed => 'Couldn\'t load more';

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
  String get eventDatesInvalid =>
      'The end date can\'t be before the start date';

  @override
  String get eventTagShowBills => 'Show bills with this tag';

  @override
  String get eventTagAddToMine => 'Add to my tags';

  @override
  String get quickModeTx => 'Transaction';

  @override
  String get quickModeDebt => 'Debt';

  @override
  String get debtNoWallet => 'Unspecified wallet';

  @override
  String get debtPickPerson => 'Pick a person';

  @override
  String get debtPersonPickerTitle => 'With whom?';

  @override
  String get debtSettledLabel => 'Settled up';

  @override
  String get debtMarkPaidTitle => 'Mark entries as paid';

  @override
  String get debtMarkPaidNone => 'Nothing open';

  @override
  String get debtCloseLabel => 'Close debts';

  @override
  String debtCloseConfirm(int n) {
    return 'Pick $n debts';
  }

  @override
  String get txFilterNoWallet => 'Unspecified wallet';

  @override
  String get txFilterNoCategory => 'Unspecified category';

  @override
  String get txFilterNoTag => 'Unspecified tag';

  @override
  String get txSummaryNet => 'Net';

  @override
  String get txFilterAmount => 'Amount';

  @override
  String get txFilterAmountMin => 'Min';

  @override
  String get txFilterAmountMax => 'Max';

  @override
  String get txTitleHintExpense => 'What did you pay for?';

  @override
  String get txTitleHintIncome => 'What is the money for?';

  @override
  String get savingTitleHint => 'Saving for what?';

  @override
  String get savingEntryGoalLabel => 'Saving goal';

  @override
  String get debtEntrySaved => 'Debt saved';

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
  String get eventErrLocked => 'This event is locked: it can\'t be edited';

  @override
  String get eventErrNotOwner => 'Only the event owner can do this';

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
  String get eventDeleteConfirm => 'Delete';

  @override
  String get occurrenceStateUpcoming => 'Upcoming';

  @override
  String get occurrenceStateNotCreated => 'To confirm';

  @override
  String get occurrenceStatePending => 'Waiting';

  @override
  String get occurrenceStateDone => 'Saved';

  @override
  String get occurrenceStatePaid => 'Paid';

  @override
  String get occurrenceStateArchived => 'Skipped';

  @override
  String get occurrenceEditOnly => 'This occurrence only';

  @override
  String get occurrenceConfirm => 'Confirm';

  @override
  String get occurrenceEnterAmount => 'Enter amount';

  @override
  String get occurrenceMarkPaid => 'Paid';

  @override
  String get occurrenceSkip => 'Skip';

  @override
  String get occurrenceRestore => 'Un-skip';

  @override
  String get occurrenceRecordInTx => 'Recorded as';

  @override
  String get occurrenceLinkPick => 'Link a transaction';

  @override
  String get occurrenceCreateNow => 'Create it now';

  @override
  String get occurrenceConfirmAll => 'Confirm all';

  @override
  String get occurrencePaidAll => 'All paid';

  @override
  String get occurrenceSkipAll => 'Skip all';

  @override
  String occurrenceLeftOut(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count left without an amount',
      one: '1 left without an amount',
    );
    return '$_temp0';
  }

  @override
  String occurrenceLeftOutRefused(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count couldn\'t be recorded',
      one: '1 couldn\'t be recorded',
    );
    return '$_temp0';
  }

  @override
  String get occurrenceDueTitle => 'Needs action';

  @override
  String occurrenceDueMore(int n) {
    return 'See all $n';
  }

  @override
  String get occurrenceSelectAll => 'Select all';

  @override
  String occurrenceSelectedCount(int n) {
    return '$n selected';
  }

  @override
  String get occurrenceSkipSelected => 'Skip selected';

  @override
  String occurrenceConfirmSelected(int n) {
    String _temp0 = intl.Intl.pluralLogic(
      n,
      locale: localeName,
      other: 'Confirm selected ($n)',
      zero: 'Confirm selected',
    );
    return '$_temp0';
  }

  @override
  String occurrenceSkipSelectedTitle(int n) {
    return 'Skip the $n selected?';
  }

  @override
  String occurrenceSkippedCount(int n) {
    return '$n skipped';
  }

  @override
  String occurrenceSavedCount(int n) {
    return '$n recorded';
  }

  @override
  String occurrencePaidCount(int n) {
    return '$n marked paid';
  }

  @override
  String get occurrencePaidSelected => 'Mark paid';

  @override
  String get occurrenceNeedsAmount => 'Enter the amount first';

  @override
  String get recurringSortDate => 'Date';

  @override
  String get recurringSortAmount => 'Largest amount';

  @override
  String get recurringSortTooltip => 'Sort';

  @override
  String get recurringFilterAllStatus => 'Any status';

  @override
  String get recurringFilterAllKinds => 'Any type';

  @override
  String get recurringMonthNoMatch => 'Nothing matches these filters';

  @override
  String get occurrenceShowLess => 'Show less';

  @override
  String get recurringAheadCustomize => 'Change ahead';

  @override
  String get recurringAheadCustomizeHint =>
      'Change the amount, move or skip the ones ahead';

  @override
  String get recurringAheadNext => 'Next';

  @override
  String get recurringTileMoved => 'Moved';

  @override
  String get recurringTileEdited => 'Edited';

  @override
  String get recurringFieldKind => 'Type';

  @override
  String get recurringFieldDates => 'Pick dates';

  @override
  String get recurringSectionPeriod => 'Schedule';

  @override
  String get recurringHomeTabOverview => 'Overview';

  @override
  String get recurringHomeMonthPay => 'Paid out this month';

  @override
  String get recurringHomeMonthCount => 'This month';

  @override
  String recurringHomeItemCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String recurringHomeToday(String date) {
    return 'Today $date';
  }

  @override
  String recurringDayEmpty(String date) {
    return 'Nothing on $date';
  }

  @override
  String get recurringHomeAllTitle => 'All recurring';

  @override
  String recurringHomePerMonthYear(String month, String year) {
    return '$month/mo | $year/yr';
  }

  @override
  String recurringHomePerMonth(String amount) {
    return '$amount/mo';
  }

  @override
  String recurringHomeAvgPerMonth(String amount) {
    return 'Avg $amount/mo';
  }

  @override
  String recurringHomeLeft(String amount) {
    return '$amount left';
  }

  @override
  String get txPickerTitle => 'Pick a transaction';

  @override
  String get txPickerGroupNear => 'Near the date';

  @override
  String get quickUpcomingHintTitle => 'Upcoming';

  @override
  String get linkedSaveTitle => 'Update the other side too?';

  @override
  String get linkedCancel => 'Not now';

  @override
  String get linkedSaveThisOnly => 'Save this side only';

  @override
  String get linkedSaveBoth => 'Save and update the other side';

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
      other: 'Custom | $count dates',
      one: 'Custom | 1 date',
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
  String get txRecurringRowLabel => 'Recurring';

  @override
  String get recurringTitle => 'Recurring';

  @override
  String get recurringAdd => 'Add recurring';

  @override
  String get recurringEmptyTitle => 'No recurring yet';

  @override
  String get recurringEmptyMessage =>
      'Set up repeating items like rent or internet. When the day comes, they wait in Pending.';

  @override
  String get recurringNewTitle => 'New recurring';

  @override
  String get recurringNotFound => 'Recurring not found';

  @override
  String get recurringNotFoundMessage => 'It may have been deleted.';

  @override
  String get recurringFieldIcon => 'Icon';

  @override
  String get recurringFieldToWallet => 'To wallet';

  @override
  String get recurringFieldCategory => 'Category';

  @override
  String get recurringFieldRepeat => 'Repeat';

  @override
  String get recurringFieldStart => 'Starts';

  @override
  String get recurringNameRequired => 'Enter a name';

  @override
  String get recurringAmountInvalid => 'Enter an amount above 0';

  @override
  String get recurringWalletRequired => 'Pick a wallet';

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
  String get recurringItemsEmpty => 'Nothing due yet';

  @override
  String get recurringUpcomingEmpty => 'Nothing upcoming';

  @override
  String get recurringUpcomingEmptyMessage =>
      'Extend it or edit the setting to produce more.';

  @override
  String get moreRecurring => 'Recurring';

  @override
  String get moreRecurringDesc => 'Bills and repeating entries';

  @override
  String notifRecurringDue(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count recurring payments are due',
      one: '1 recurring payment is due',
    );
    return '$_temp0';
  }

  @override
  String notifRecurringAutoCreated(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Recorded $count automatically',
      one: 'Recorded 1 automatically',
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
  String get recurSheetPeriodStart => 'Each period starts on';

  @override
  String get recurSheetYearlyOn => 'Every year on';

  @override
  String get recurSheetByDay => 'On a date';

  @override
  String get recurSheetByWeekday => 'On a weekday';

  @override
  String recurSheetNth(String ord, int nth) {
    String _temp0 = intl.Intl.selectLogic(ord, {
      'first': '1st',
      'second': '2nd',
      'third': '3rd',
      'other': '4th',
    });
    return '$_temp0';
  }

  @override
  String recurSheetStartMoves(String date) {
    return 'The start moves to $date';
  }

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
  String sgv2DueOn(String date) {
    return 'Due $date';
  }

  @override
  String get sgv2ActionWithdraw => 'Withdraw';

  @override
  String get sgv2ActionMove => 'Move';

  @override
  String get sgv2Overview => 'Overview';

  @override
  String get sgv2Entries => 'Saving entries';

  @override
  String get sgv2EntriesEmpty => 'No saving entries yet';

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
  String get sgv2KindSave => 'Save';

  @override
  String get sgv2KindWithdraw => 'Withdraw';

  @override
  String get sgv2KindMove => 'Move';

  @override
  String sgEntryFrom(String name) {
    return 'from $name';
  }

  @override
  String sgEntryTo(String name) {
    return 'to $name';
  }

  @override
  String get sgv2SpareTitle => 'Not allocated';

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
  String get bgStatOver => 'Over budget';

  @override
  String get bgStatWarn => 'Near the limit';

  @override
  String get bgStatusOver => 'Over';

  @override
  String get bgStatusWarn => 'Near limit';

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
  String bgRowDaysLeft(int count) {
    return '$count days left';
  }

  @override
  String bgRowUsed(String used, String amount) {
    return 'Used $used of $amount';
  }

  @override
  String get bgPeriodNow => 'This period';

  @override
  String get bgPeriodOverridden => 'This period only';

  @override
  String get bgSourceNormal => 'Normal';

  @override
  String get bgSourceRecurring => 'Recurring';

  @override
  String get bgSourceEvent => 'Event';

  @override
  String get bgSourceUpcoming => 'Recurring | upcoming';

  @override
  String get bgSourcePending => 'Pending';

  @override
  String get bgSourceFutureTx => 'Upcoming';

  @override
  String get bgPeriodsAll => 'All earlier periods';

  @override
  String get bgItemsMore => 'Show more';

  @override
  String get bgItemsEmpty => 'Nothing counted in this period yet';

  @override
  String get bgPeriodAmountField => 'Amount for this period';

  @override
  String bgPeriodEditSubtitle(String period) {
    return 'Only $period | other periods stay';
  }

  @override
  String get bgPeriodBase => 'Base amount';

  @override
  String get bgPeriodNoteHint => 'e.g. a wedding this month';

  @override
  String get bgSectionScope => 'Which spending counts';

  @override
  String get bgScopeAll => 'Every expense';

  @override
  String get bgScopeCategories => 'Categories';

  @override
  String get bgScopeTags => 'Tags';

  @override
  String get bgScopeWallets => 'Wallets';

  @override
  String bgScopeChildren(String name) {
    return 'All $name';
  }

  @override
  String get bgScopeRequired =>
      'Pick what to count, or turn on \"Every expense\"';

  @override
  String get bgSectionPeriod => 'Time';

  @override
  String get bgFieldRepeat => 'Period';

  @override
  String get bgFieldRepeatToggle => 'Repeat';

  @override
  String get bgFieldStart => 'Start';

  @override
  String get bgFieldEnd => 'End';

  @override
  String get bgSectionPeriodDesc => 'When it starts and how it repeats';

  @override
  String get bgScopeChoose => 'Choose';

  @override
  String get bgScopeAndHint =>
      'Counts spending that matches every row you pick (any item within a row)';

  @override
  String get bgScopePickTags => 'Choose tags';

  @override
  String get bgStatusOnPlan => 'On plan';

  @override
  String bgStatusAhead(String amount) {
    return '$amount ahead of plan';
  }

  @override
  String bgStatusOverBy(String amount) {
    return 'Over by $amount';
  }

  @override
  String bgRingOf(String amount) {
    return 'of $amount';
  }

  @override
  String get bgFactUsed => 'Spent';

  @override
  String get bgFactPending => 'Coming up';

  @override
  String get bgFactPlanToday => 'Plan to date';

  @override
  String bgPaceBubble(String amount) {
    return 'Plan $amount';
  }

  @override
  String get bgRingTotalLeft => 'Left in total';

  @override
  String get bgFactUsedTotal => 'Total spent';

  @override
  String get bgFactUsedPct => 'Used';

  @override
  String get bgFactBudgetCount => 'Budgets this period';

  @override
  String bgCountBudgets(int count) {
    return '$count budgets';
  }

  @override
  String get bgFactNextRound => 'Next period';

  @override
  String get bgFieldStartHelp => 'Spending counts from this day';

  @override
  String get bgEndNone => 'No end';

  @override
  String bgEndOnDate(Object date) {
    return 'ends $date';
  }

  @override
  String get bgEndPickDate => 'Pick a date…';

  @override
  String bgEndPeriods(int count) {
    return '$count periods';
  }

  @override
  String get bgWarnOff => 'No warning';

  @override
  String bgWarnPct(int pct) {
    return '$pct%';
  }

  @override
  String get bgScopeChoiceTitle => 'Apply the new setup to';

  @override
  String get bgScopeFollowing => 'This and following periods';

  @override
  String get bgScopeAllPeriods => 'Every period (past ones too)';

  @override
  String get bgClose => 'Close the budget';

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
  String get pendingSavingNoWallet => 'Pick a wallet before confirming';

  @override
  String get walletSavingsSaved => 'Saved';

  @override
  String get quickModeSaving => 'Savings';

  @override
  String get savingEntrySpare => 'Not allocated';

  @override
  String get savingEntryPickGoal => 'Pick a saving goal';

  @override
  String savingEntryAvailable(String amount) {
    return '$amount free to save';
  }

  @override
  String savingEntryOverAvailable(String amount) {
    return '$amount more than is free (still allowed)';
  }

  @override
  String get savingEntrySaved => 'Saving recorded';

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
  String sgv2ChartTarget(String amount) {
    return 'Goal $amount';
  }

  @override
  String get sgv2SpareName => 'Not allocated';

  @override
  String get profileCurrencyChangeTitle => 'Change currency?';

  @override
  String get profileCurrencyChangeMessage => '100 stays 100';

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
  String get accountsSearchHint => 'Search wallets';

  @override
  String get accountsNoMatch => 'No matching wallets';

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
  String get fpWalletsTileAvailable => 'Available';

  @override
  String fpWalletsCreditUsedPct(int pct) {
    return '$pct% of limit used';
  }

  @override
  String get fpWalletsFilterAll => 'All';

  @override
  String get fpWalletsFilterCash => 'Cash / bank';

  @override
  String get fpWalletsFilterCard => 'Credit cards';

  @override
  String fpWalletsSharedTooltip(int count) {
    return '$count shared';
  }

  @override
  String get fpWalletsSortByType => 'By type';

  @override
  String get fpWalletsReorderChip => 'Reorder';

  @override
  String get fpWalletBalanceLabel => 'In the wallet';

  @override
  String fpWalletSavedLegend(String amount) {
    return 'Saved $amount';
  }

  @override
  String get fpWalletSavedInTitle => 'Saved in';

  @override
  String get fpWalletSavedInDesc => 'Money in this wallet set aside for goals';

  @override
  String get fpWalletAvailableLabel => 'Available';

  @override
  String get fpWalletSavedLabel => 'Saved';

  @override
  String fpWalletSavedOverAlert(String amount) {
    return 'Saved $amount more than the wallet holds';
  }

  @override
  String get fpWalletCreditUsedLabel => 'Used on the card';

  @override
  String fpWalletCardAvailableLabel(String limit) {
    return 'Available of the $limit limit';
  }

  @override
  String get fpWalletScopeOwnChip => 'Mine only';

  @override
  String fpWalletFlowIn(String month) {
    return 'In $month';
  }

  @override
  String fpWalletFlowOut(String month) {
    return 'Out $month';
  }

  @override
  String fpWalletCardLeft(String amount) {
    return '$amount left';
  }

  @override
  String fpWalletDueAlert(String date, int days) {
    return 'Payment due $date | in $days days';
  }

  @override
  String accountCardDueIn(int days) {
    return 'Due in $days days';
  }

  @override
  String get accountCardDueToday => 'Due today';

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
  String get fpWalletInviteLabel => 'Invite';

  @override
  String get fpWalletOwnerCaption => 'Owner';

  @override
  String get fpWalletMemberCaption => 'Member';

  @override
  String fpTxAvgDaily(String amount) {
    return 'Avg spend $amount/day';
  }

  @override
  String get fpWalletDeleteLabel => 'Delete this wallet';

  @override
  String get fpWalletDeleteConsequence =>
      'See what is attached first | saved money stays, just unlinked from the wallet';

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
    return '$transactions transactions stay with no wallet ($transfers transfers) | $system opening / adjustment rows are deleted | $recurring recurring settings keep running | $savings saving entries ($amount) stay, unlinked from the wallet';
  }

  @override
  String get fpWalletDeleted => 'Wallet deleted';

  @override
  String get fpContactsLinkSection => 'App account';

  @override
  String get fpContactsLinkSectionDesc =>
      'Tie this person to the account they use in the app (their name, email and icon), and merge names typed in splits';

  @override
  String contactLinkedAccount(String name) {
    return 'Linked to $name\'s account';
  }

  @override
  String get fpContactsArchiveConsequence =>
      'Hidden from the list and person pickers; debts unchanged';

  @override
  String get fpContactsDeleteConsequence =>
      'Old records keep just the name; amounts unchanged';

  @override
  String fpDebtsOwedToMeTile(int count) {
    return 'Owe me | $count people';
  }

  @override
  String fpDebtsIOweTile(int count) {
    return 'I owe | $count people';
  }

  @override
  String fpDebtsDaysOutstanding(int count) {
    return 'Outstanding $count days';
  }

  @override
  String get fpDebtsCopy => 'Copy';

  @override
  String get fpDebtsCopied => 'Message copied';

  @override
  String get fpBudgetsLeftLabel => 'Still available';

  @override
  String get fpBudgetsOverLabel => 'Over budget';

  @override
  String get fpBudgetsTileDaily => 'Can spend per day';

  @override
  String get fpBudgetsWarnAt => 'Warn at';

  @override
  String get fpBudgetsTabItems => 'This period';

  @override
  String get fpBudgetsTabPeriods => 'All periods';

  @override
  String get fpBudgetsLimitLabel => 'Budget limit';

  @override
  String fpBudgetsPeriodReset(String amount) {
    return '↺ Use the base amount ($amount)';
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
  String fpGoalsStatusChip(String status) {
    return 'Status: $status';
  }

  @override
  String fpGoalsDueBy(String date) {
    return 'By $date';
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
  String fpGoalsDaysLeft(int count) {
    return '$count days left';
  }

  @override
  String get fpGoalsTileSaved => 'Saved this month';

  @override
  String get fpGoalsActionSave => 'Save';

  @override
  String get fpGoalsActionRestore => 'Restore';

  @override
  String get fpGoalsAutoFrom => 'Take from';

  @override
  String get fpGoalsNoWallet => 'Unspecified wallet';

  @override
  String get fpGoalsChartActual => 'Saved';

  @override
  String get fpGoalsCloseConsequence =>
      'Move the money to “Not allocated” or back to its wallets';

  @override
  String get fpGoalsArchiveConsequence =>
      'Hidden, not counted, can be restored';

  @override
  String get fpGoalsArchiveNeedsClose => 'Close the goal first';

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
  String get fpGoalsGroupOngoing => 'Ongoing';

  @override
  String fpGoalsRingOfPlan(String amount) {
    return 'Goal $amount';
  }

  @override
  String fpGoalsRingOf(String target, int pct) {
    return 'of $target | $pct%';
  }

  @override
  String get fpGoalsFactTotal => 'Total saved';

  @override
  String get fpGoalsFactGoals => 'Goals';

  @override
  String get fpGoalsFactTarget => 'Target';

  @override
  String get fpGoalsFactStillShort => 'Short this month';

  @override
  String get fpGoalsFactShouldHave => 'Should have by now';

  @override
  String get fpGoalsFactLeft => 'Left to go';

  @override
  String get fpGoalsFactReachedOn => 'Reached on';

  @override
  String get fpGoalsFilterAll => 'All';

  @override
  String get fpGoalsFilterShort => 'Saving';

  @override
  String get fpGoalsFilterFree => 'No deadline';

  @override
  String get fpGoalsSortNeed => 'Needs saving first';

  @override
  String get fpGoalsRowDone => 'Done ✓';

  @override
  String fpGoalsRowMonthOnly(String month, String amount) {
    return '$month $amount';
  }

  @override
  String get fpGoalsThisMonth => 'This month';

  @override
  String fpGoalsChipShort(String amount) {
    return 'Short $amount this month';
  }

  @override
  String fpGoalsChipLate(int n) {
    return '$n months behind schedule';
  }

  @override
  String get fpGoalsFactPeriodSaved => 'This period';

  @override
  String get fpGoalsFactPeriodTarget => 'Period target';

  @override
  String get fpGoalsFactPeriodEta => 'Done by';

  @override
  String fpGoalsChipPeriodShort(String amount, int days) {
    return 'Short $amount this period | $days days left';
  }

  @override
  String get fpGoalsChipPeriodDone => 'This period is done';

  @override
  String fpGoalsArchiveConsequenceMoney(String amount) {
    return 'Hidden | $amount not counted in savings | can be restored';
  }

  @override
  String fpGoalsArchiveConfirmBodyMoney(String amount) {
    return 'Hide this goal. The $amount saved in it won’t count in your savings. You can restore it later.';
  }

  @override
  String get savingGoalFormTargetOptionalHint =>
      'Leave empty for an ongoing goal with no target';

  @override
  String get sgPlanSection => 'Saving plan';

  @override
  String get sgPlanSectionDesc => 'When it\'s due, and what it starts with';

  @override
  String get sgOpeningLabel => 'Starting amount';

  @override
  String get sgOpeningHelp =>
      'Money you already have, saved as the first entry';

  @override
  String get sgAutoAdd => 'Add a saving';

  @override
  String sgCreatedPartly(String error) {
    return 'The goal was created, but part of it didn\'t save: $error';
  }

  @override
  String get fpGoalsRefreshFailed => 'Refresh failed, showing the latest data';

  @override
  String fpEventsHeroNet(int count) {
    return 'Net owed | $count events';
  }

  @override
  String fpEventsOwedFact(int count) {
    return 'Gets back | $count events';
  }

  @override
  String fpEventsOweFact(int count) {
    return 'To pay | $count events';
  }

  @override
  String fpEventsShareFact(int count) {
    return 'My share | $count active';
  }

  @override
  String get fpEventsFilterAll => 'All';

  @override
  String get fpEventsOverBudget => 'Over budget';

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
  String fpEventsRowShare(String amount) {
    return 'My share $amount';
  }

  @override
  String get fpEventsOwed => 'Gets back';

  @override
  String get fpEventsOwe => 'To pay';

  @override
  String get fpEventsSpentTotal => 'Total spent';

  @override
  String get fpEventsMyShare => 'My share';

  @override
  String get fpEventsIncomeTotal => 'Total income';

  @override
  String get fpEventsMyTags => 'My tags';

  @override
  String get fpEventsTagPick => 'Pick';

  @override
  String fpEventsMemberPaid(String amount) {
    return 'Paid $amount';
  }

  @override
  String fpEventsMemberOwed(String amount) {
    return 'Gets back $amount';
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
  String get fpEventsTagAll => 'All';

  @override
  String get fpEventsBudgetLabel => 'Planned budget (optional)';

  @override
  String get fpEventsBudgetHelper =>
      'What you intend to spend | clear to hide the plan';

  @override
  String get fpEventsDatesLabel => 'Start – end';

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
  String get fpEventsTagsTitle => 'Event tags | shared with members';

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
  String get fpEventsLoadFailed => 'Couldn\'t refresh | showing the last data';

  @override
  String get evbNewBill => 'Add bill';

  @override
  String get evbEditBill => 'Edit bill';

  @override
  String get evbNewPayback => 'Payback';

  @override
  String get evbEditPayback => 'Edit payback';

  @override
  String get evbTypePayback => 'Payback';

  @override
  String evbPeople(int count) {
    return 'In the bill | $count';
  }

  @override
  String get evbPays => 'Paid';

  @override
  String get evbPaidBack => 'Paid back';

  @override
  String get evbMembersSection => 'In this event';

  @override
  String evbAddPeopleConfirm(int count) {
    return 'Add $count';
  }

  @override
  String get evbMyBooks => 'Add to my books';

  @override
  String get evbBooked => 'In my books';

  @override
  String evbBookDebtLine(String name) {
    return 'I owe $name';
  }

  @override
  String evbPaybackBy(String name) {
    return 'Payback | by $name';
  }

  @override
  String get evbNoWallet => 'No wallet';

  @override
  String get evbTabBills => 'Bills';

  @override
  String get evbTabSummary => 'Summary';

  @override
  String get evbNets => 'Each person';

  @override
  String get evbMembersTitle => 'Members';

  @override
  String get evbManageMembers => 'Manage members ›';

  @override
  String get evbSettleSection => 'Settle up';

  @override
  String get evbSettleRecord => 'Record as a debt';

  @override
  String get evbSettleRecorded => 'Recorded';

  @override
  String get evbBookedDebt => 'Debt';

  @override
  String get evbBookedTx => 'Transaction';

  @override
  String get evbBookMine => 'Book it';

  @override
  String get evbSettleHint =>
      'Tap a line to record the payback in the event (anyone can) | the inbox button records it as your debt';

  @override
  String get evbAllSettled => 'Everyone is even';

  @override
  String get evbOnlyMine => 'Only mine';

  @override
  String get evbNoDebt => 'No debt';

  @override
  String get evbRecordDebt => 'Record the debt';

  @override
  String get evbIPaid => 'I paid';

  @override
  String get evbBackReceived => 'Got back';

  @override
  String get evbBackSent => 'Paid back';

  @override
  String evbTheyOweMe(String name) {
    return '$name owes me';
  }

  @override
  String get evbDebtUp => 'Debt up';

  @override
  String get evbDebtDown => 'Debt down';

  @override
  String get categoryDeleteConsequence =>
      'Deleted for good | its transactions will have no category';

  @override
  String categoryMonthSpentLabel(String month, int count) {
    return '$month spent | $count transactions ›';
  }

  @override
  String categoryMonthEarnedLabel(String month, int count) {
    return '$month received | $count transactions ›';
  }

  @override
  String get notifGroupRecurring => 'Recurring';

  @override
  String get notifTypeRecurringDue => 'Recurring items are due';

  @override
  String get notifTypeRecurringEnding => 'A recurring is about to end';

  @override
  String get notifTypeRecurringAutoCreated => 'Recorded automatically';

  @override
  String get notifTypeRequestsHint =>
      'Needs an answer, so it can\'t be turned off';

  @override
  String get settingsSectionApp => 'App';

  @override
  String get settingsSectionMoney => 'Money';

  @override
  String get settingsCurrencyHint =>
      'Changes the label only, amounts are not converted';

  @override
  String get settingsMainWallet => 'Main wallet';

  @override
  String get settingsMoneyStyle => 'Money format';

  @override
  String get settingsMoneySignPlusMinus => '+ / −';

  @override
  String get settingsMoneySignParentheses => 'Parentheses ( )';

  @override
  String get settingsMoneySignNone => 'No sign';

  @override
  String get settingsMoneyColor => 'Red / green colours';

  @override
  String get settingsMoneyColorHint => 'Income in green, expenses in red';

  @override
  String get settingsMoneyDecimals => 'Decimals';

  @override
  String get settingsMoneyDecimalsAlways => 'Always';

  @override
  String get settingsMoneyDecimalsNever => 'Never (rounded)';

  @override
  String get settingsMoneyDecimalsAuto => 'Hide .00 only';

  @override
  String get settingsMainWalletHint => 'Not set = the last wallet used';

  @override
  String get settingsMainWalletNone => 'Not set';

  @override
  String get settingsArchived => 'Archive';

  @override
  String get settingsArchivedHint =>
      'Wallets, budgets, saving goals, recurring, events, contacts';

  @override
  String get settingsExportCsv => 'Export CSV';

  @override
  String get profileSectionSecurity => 'Security';

  @override
  String get notifTileAll => 'All';

  @override
  String get notifTileNeedsAnswer => 'Needs answer';

  @override
  String get notifTileUnread => 'Unread';

  @override
  String get notifTileHidden => 'Hidden';

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
  String get notifActionOpenDue => 'Open ›';

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
  String archivedSecondaryBalance(String amount) {
    return 'Left $amount';
  }

  @override
  String archivedSecondaryLimit(String amount) {
    return 'Limit $amount';
  }

  @override
  String archivedSecondaryTarget(String amount) {
    return 'Goal $amount';
  }

  @override
  String archivedSecondaryPlanned(String amount) {
    return 'Budget $amount';
  }

  @override
  String archivedSecondaryAmount(String amount) {
    return 'Amount $amount';
  }

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
  String get recurringPickerGroupLikely => 'Likely';

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
  String get recurringPickerGroupNearest => 'Nearest';

  @override
  String get recurringPickerGroupNext => 'Coming';

  @override
  String get recurringPickerGroupPast => 'Past';

  @override
  String get recurringPickerOtherRule => 'Pick another recurring';

  @override
  String get recurringLinkSwapTitle => 'Swap the linked transaction?';

  @override
  String recurringLinkSwapBody(String name) {
    return 'This period is linked to $name. Link this transaction instead? $name stays, just unlinked.';
  }

  @override
  String get recurringLinkMoveBody =>
      'This transaction is linked to another period. Move it here? That period goes back to due.';

  @override
  String get recurringLinkSwapYes => 'Swap';

  @override
  String get fpRecurringTabCalendar => 'Calendar';

  @override
  String get fpRecurringPausedGroup => 'Paused';

  @override
  String get fpRecurringAwaitingAmount => 'No amount yet';

  @override
  String get fpRecurringKindSubscription => 'Subscription';

  @override
  String get fpRecurringKindInstallment => 'Installment';

  @override
  String get fpRecurringKindIncome => 'Income';

  @override
  String get fpRecurringKindReminder => 'Reminder';

  @override
  String get fpRecurringKindSaving => 'Saving';

  @override
  String get recurringHomeMonthPayNoSaving =>
      'Paid this month, savings not included';

  @override
  String get recurringHomeMonthSave => 'Saved this month';

  @override
  String get sgRecurringTitle => 'Recurring saves';

  @override
  String get sgPlanTitle => 'Saving plan';

  @override
  String get sgRecurringLabel => 'Recurring saves';

  @override
  String get sgPeriodTarget => 'Target per period';

  @override
  String get sgPeriodTargetField => 'Amount per period';

  @override
  String get sgPeriodNone => 'Not set';

  @override
  String get sgPeriodClear => 'No target per period';

  @override
  String get sgPeriodHelper =>
      'The last period takes only what is left of the goal';

  @override
  String get sgPeriodRule => 'Period';

  @override
  String sgPeriodPlanShort(String plan, String target) {
    return 'Recurring saves put in $plan a period, short of the $target target';
  }

  @override
  String get sgRecurringSpareCaption =>
      'Saves into unallocated on the round you set';

  @override
  String get fpRecurringRefreshFailed =>
      'Refresh failed, showing the latest data';

  @override
  String get fpRecurringAwaitingValue => 'Enter amount';

  @override
  String get fpRecurringTileYearly => 'Per year';

  @override
  String get fpRecurringTileSaved => 'Saved';

  @override
  String fpRecurringCountUnit(int n) {
    return '$n times';
  }

  @override
  String get fpRecurringTrialUntil => 'Free trial until';

  @override
  String get fpRecurringTabPast => 'Past';

  @override
  String get fpRecurringTabUpcoming => 'Upcoming';

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
  String fpRecurringCountValue(int n) {
    return '$n payments';
  }

  @override
  String get fpRecurringCountRequired =>
      'An installment needs a number of payments';

  @override
  String get fpRecurringFieldMode => 'Type';

  @override
  String get fpRecurringFieldFromWallet => 'From wallet';

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
    return 'Deletes $periods periods ($overridden adjusted) | $categories categories | $wallets wallets. Transactions are not affected.';
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
  String get fpM5GoalsChartPlan => 'On plan';

  @override
  String fpRecurringSince(String date) {
    return 'Since $date';
  }

  @override
  String fpRecurringNextOnce(String due) {
    return 'Next | $due';
  }

  @override
  String fpRecurringNextInstallment(int n, int total, String due) {
    return 'Next installment ($n/$total) | $due';
  }

  @override
  String get fpRecurringStatPaid => 'Paid';

  @override
  String get fpRecurringStatRemaining => 'Left';

  @override
  String get fpRecurringStatLast => 'Last one';

  @override
  String get fpRecurringStatAvg => 'Average';

  @override
  String get fpRecurringStatPrev => 'Last time';

  @override
  String get fpRecurringStatMax => 'Highest';

  @override
  String fpRecurringAvgLine(String amount) {
    return 'Avg $amount';
  }

  @override
  String fpRecurringChainLabel(int done, int total) {
    return '$done of $total paid';
  }

  @override
  String get fpRecurringChartLabel => 'Amount each time';

  @override
  String get fpRecurringAutoChip => 'Auto-record';

  @override
  String get fpRecurringTagNext => 'Next';

  @override
  String get fpRecurringTagMoved => 'Moved';

  @override
  String get fpRecurringTagLast => 'Last';

  @override
  String fpRecurringUsualAmount(String amount) {
    return 'Usually $amount';
  }

  @override
  String fpRecurringMovedFrom(String date) {
    return 'From $date';
  }

  @override
  String get fpRecurringTapToEnter => 'Tap to enter the amount';

  @override
  String get fpRecurringTapToRestore => 'Tap to undo the skip';

  @override
  String get fpRecurringAutoCreate => 'Record automatically on the day';

  @override
  String get fpRecurringAutoCreateHint =>
      'On the day it\'s recorded for you, no confirm needed';

  @override
  String get fpM5bRecurringPerMonth => 'Per month';

  @override
  String fpM5bRecurringDeleteNumbers(int items, int drafts, int linked) {
    return 'This deletes $items occurrences, $drafts waiting drafts and touches $linked saved records.';
  }

  @override
  String get fpGoalsFactTargetShort => 'Short of the targets';

  @override
  String get fpGoalsFactMonthToSave => 'To save this month';

  @override
  String get debtRepayReceive => 'Got back';

  @override
  String get debtRecordChip => 'Log a debt';

  @override
  String get debtSettleChip => 'Pay a debt';

  @override
  String get debtRoleDebtor => 'Owes me';

  @override
  String get debtRoleCreditor => 'I owe';

  @override
  String debtSummaryDebtor(String name) {
    return '$name owes me';
  }

  @override
  String debtSummaryCreditor(String name) {
    return 'I owe $name';
  }

  @override
  String debtSummaryBecomesDebtor(String name) {
    return '$name now owes me';
  }

  @override
  String debtSummaryBecomesCreditor(String name) {
    return 'Now I owe $name';
  }

  @override
  String debtSummaryCleared(String name) {
    return 'Settled up with $name';
  }

  @override
  String get debtRepayTo => 'Pay back to';

  @override
  String get debtRepayFrom => 'Got back from';

  @override
  String get debtMarkPaidLabel => 'Close debts';

  @override
  String get debtRepayCleared => 'Settled up';

  @override
  String get debtRepayPickTitle => 'People with an open balance';

  @override
  String get debtRepayNoOpen => 'No one owes or is owed right now';

  @override
  String get txRepaymentCategoryLocked =>
      'A repayment keeps its system category';

  @override
  String get txLinkModeNeedsPayer => 'Pick who paid first';

  @override
  String get txLinkModeNeedsEvent => 'Pick an event first';

  @override
  String get txLinkModeUnbalanced =>
      'The amounts don\'t add up to the bill yet. See the card\'s status line.';

  @override
  String get txLinkTabSplit => 'Split';

  @override
  String get txLinkBillLabel => 'Bill';

  @override
  String get txLinkCardPaidTitle => 'Who paid, and how much';

  @override
  String get txLinkCardMyPaid => 'I paid (from my wallet)';

  @override
  String get txLinkCardWhoPaid => 'Who paid';

  @override
  String get txLinkCardWhoInBill => 'Who\'s in the bill';

  @override
  String get txLinkCardMe => 'Me';

  @override
  String get txLinkCardSplitOk => '✓ All split';

  @override
  String get txLinkCardPaidOk => '✓ Fully paid';

  @override
  String txLinkCardShort(String amount) {
    return '$amount short';
  }

  @override
  String txLinkCardOver(String amount) {
    return '$amount over';
  }

  @override
  String get txLinkCardNewToEvent => 'New · joins the event';

  @override
  String get txLinkAddToEvent => 'Add to event';

  @override
  String get txPaidBackNeedsWallet =>
      'Paid back needs the wallet the money went into';

  @override
  String get txLinkBookDebt => 'Record the debts too';

  @override
  String get txLinkWalletNotOut => 'Not from your wallet';

  @override
  String txLinkWalletPart(String amount) {
    return '$amount from this wallet';
  }

  @override
  String txLinkShareIOwe(String name, String amount) {
    return 'I owe $name $amount';
  }

  @override
  String get txLinkViewPaidLabel => 'Paid by';

  @override
  String txLinkViewMyPaid(String amount) {
    return 'I paid $amount';
  }

  @override
  String get txLinkViewEventLabel => 'Event bill';

  @override
  String get txLinkViewIPaid => 'I paid';

  @override
  String txLinkViewTheyPaid(String name) {
    return '$name paid';
  }

  @override
  String txLinkViewPeople(int count) {
    return '$count people';
  }

  @override
  String get txLinkPreviewTitle => 'What will change';

  @override
  String txLinkPreviewLine(String name, String before, String after) {
    return '$name: $before → $after';
  }

  @override
  String get txLinkPreviewNone => 'No one\'s balance changes';

  @override
  String get txLinkOutOfSyncLabel => 'The event bill changed';

  @override
  String get txLinkApplyEvent => 'Update from the event';

  @override
  String get txLinkApplied => 'Updated from the event';

  @override
  String get linkedEventAskTitle => 'Change it in the event too?';

  @override
  String get linkedMineOnly => 'Only mine';

  @override
  String get linkedBoth => 'Both';

  @override
  String get txLinkDraftNeedsExistingEvent =>
      'A draft can only go to an existing event';

  @override
  String debtResultNow(String name) {
    return '$name now';
  }

  @override
  String get debtResultAfterSave => 'After saving';

  @override
  String debtResultWallet(String wallet) {
    return 'Wallet $wallet';
  }

  @override
  String get debtWalletNotUsed => 'No change';

  @override
  String debtOverpayWarn(String after) {
    return 'More than what\'s open — after saving: $after';
  }

  @override
  String get debtOverpayTitle => 'More than what\'s open';

  @override
  String get debtOverpayConfirm => 'Save anyway';

  @override
  String get debtOverpayEdit => 'Change the amount';

  @override
  String get debtSomeone => 'them';

  @override
  String get debtTxHintLend => 'Adds an expense to the wallet';

  @override
  String get debtTxHintBorrow => 'Adds income to the wallet';

  @override
  String get debtTxHintOff => 'Wallet balance unchanged';

  @override
  String debtsHeroNet(int count) {
    return 'Net debts | $count people';
  }

  @override
  String get debtsFilterAll => 'All';

  @override
  String get debtsOver30Label => 'Open over 30 days';

  @override
  String debtsPeopleCount(int count) {
    return '$count people';
  }

  @override
  String debtPersonSince(String month) {
    return 'together since $month';
  }

  @override
  String debtPersonSettlePay(String amount) {
    return 'Pay back $amount';
  }

  @override
  String debtPersonSettleReceive(String amount) {
    return 'Got back $amount';
  }

  @override
  String get debtPersonSummary => 'Summary';

  @override
  String get debtPersonChase => 'Remind';

  @override
  String debtPersonSummaryTitle(String name) {
    return 'Summary with $name';
  }

  @override
  String debtPersonChaseTitle(String name) {
    return 'Remind $name';
  }

  @override
  String get debtShareThisCycle => 'This cycle';

  @override
  String get debtShareBalanceOnly => 'Balance only';

  @override
  String get debtShareFieldLabel => 'Message (edit before sending)';

  @override
  String get debtShareSend => 'Share to LINE / other apps';

  @override
  String debtDayUp(String amount) {
    return 'up $amount';
  }

  @override
  String debtDayDown(String amount) {
    return 'down $amount';
  }

  @override
  String debtEarlierShow(String date) {
    return 'Settled up $date | Earlier ▾';
  }

  @override
  String get debtEarlierShowPlain => 'Earlier ▾';

  @override
  String get debtEarlierHide => 'Hide earlier ▴';

  @override
  String debtRowTheyPaid(String name) {
    return '$name paid for me';
  }

  @override
  String get debtRowIPaid => 'you paid for them';

  @override
  String debtRowSplitBill(String amount) {
    return 'split bill $amount';
  }

  @override
  String debtRowEvent(String name) {
    return 'event $name';
  }

  @override
  String debtRowIPaidBack(String name) {
    return 'You paid $name back';
  }

  @override
  String debtRowTheyPaidBack(String name) {
    return '$name paid back';
  }

  @override
  String get debtUnpaidLabel => 'Not paid';

  @override
  String get debtDueLabel => 'Due';

  @override
  String get debtsSectionTotal => 'Total';

  @override
  String get debtDuePick => 'Pick a due date';

  @override
  String debtDueOn(String date) {
    return 'Due $date';
  }

  @override
  String debtOverdueDays(int days) {
    return '$days days overdue';
  }

  @override
  String debtsOwingDays(int days) {
    return 'Owing for $days days';
  }

  @override
  String get debtLinkTx => 'Create a transaction from this debt';

  @override
  String get debtTxNone => 'No transaction linked';

  @override
  String debtLinkedAmountDiffers(String amount) {
    return 'The transaction is $amount, not the debt\'s amount';
  }

  @override
  String debtOriginLabel(String kind) {
    return 'From ($kind)';
  }

  @override
  String get debtOriginSplit => 'split bill';

  @override
  String get debtOriginPaidBy => 'paid for me';

  @override
  String get debtOriginPartner => 'their split';

  @override
  String get debtOriginEvent => 'event';

  @override
  String get debtOriginCash => 'a loan';

  @override
  String get debtOriginLocked => 'can\'t change it here';

  @override
  String get quickCreateBtnTx => 'Add';

  @override
  String get quickCreateBtnDebt => 'Add debt';

  @override
  String get quickCreateBtnSaving => 'Save money';

  @override
  String get debtsEmptyOpenTitle => 'No open debts';

  @override
  String get debtsEmptyOpenMessage =>
      'Note who borrowed and who paid for whom, so you never forget to ask';

  @override
  String get evbReceives => 'Received';

  @override
  String get txLinkWalletNotIn => 'Not into this wallet';

  @override
  String txLinkWalletPartIn(String amount) {
    return '$amount into this wallet';
  }

  @override
  String get txLinkViewGotLabel => 'Received by';

  @override
  String txLinkViewMyGot(String amount) {
    return 'I got $amount';
  }

  @override
  String get txLinkViewIGot => 'I got it';

  @override
  String get txLinkCardGotTitle => 'Who got it, and how much';

  @override
  String get txLinkCardMyGot => 'I got it (into my wallet)';

  @override
  String get txLinkCardWhoGot => 'Who got it';

  @override
  String get txLinkCardGotOk => '✓ Fully received';

  @override
  String txFutureHint(String when) {
    return '$when | counts in the balance from that day';
  }

  @override
  String get categorySystemLoanGiven => 'Loan given';

  @override
  String get categorySystemLoanTaken => 'Loan taken';

  @override
  String get categorySystemLockedHelper =>
      'System category: the name and \"count in reports\" can\'t change';

  @override
  String get debtLinkExistingLabel => 'Connect an existing transaction';

  @override
  String get debtLinkedAmountNote =>
      'Amount and date follow the connected transaction';

  @override
  String get debtCloseAllHint => 'Label every open debt with this person paid';

  @override
  String get fpRecurringAutoCreateNeedsWallet => 'Pick a wallet first';

  @override
  String get fpRecurringAutoCreateZeroWarn =>
      'No fixed amount: on the day it records 0 for you to fix. Not a good fit for an amount that changes every time (e.g. electricity)';

  @override
  String get txLinkDisconnect => 'Disconnect';

  @override
  String get txLinkDisconnectTitle => 'Disconnect from the event?';

  @override
  String get txLinkDisconnected => 'Disconnected';

  @override
  String get occurrenceSkipFilled =>
      'This one is recorded. Disconnect its transaction first to skip it';

  @override
  String get recurringPausedOverdue =>
      '3 waiting: paused. Clear them and resume; it goes on from the current period';

  @override
  String get recurringPausedGoal => 'The saving goal is closed: paused';

  @override
  String get recurringOverdueLimitChip => '3 waiting';

  @override
  String get notifTypeDebtDisconnected => 'Someone disconnects a debt with me';

  @override
  String notifDebtDisconnected(String who, String amount) {
    return '$who disconnected the debt $amount';
  }

  @override
  String debtDisconnectTitle(String name) {
    return 'Disconnect the debt with $name?';
  }

  @override
  String get debtDisconnectBody =>
      'It becomes a plain debt in your book that you can edit. Their bill edits won\'t follow any more; they get a notice';

  @override
  String debtPartnerLinked(String name) {
    return 'Linked with $name\'s book';
  }

  @override
  String get eventCompleteTitle => 'Complete this event for good?';

  @override
  String get eventCompleteBody =>
      'This can\'t be undone. No more adding or editing bills, and everyone\'s books stop updating with this event at once (the links stay).';

  @override
  String get eventCompleteConfirm => 'Complete event';

  @override
  String get eventCompleted => 'Event completed';

  @override
  String get eventCompletedNotice =>
      'This event is completed: bills can\'t be added or edited, and nobody\'s book updates with it any more.';

  @override
  String get eventErrCompleted =>
      'This event is completed and can\'t be changed';

  @override
  String get eventErrNotActive => 'Only an active event can be completed';

  @override
  String get eventErrEmptyPerson =>
      'A bill still has an empty person slot: fill it before completing the event';

  @override
  String get settingsGroupSync => 'Auto update';

  @override
  String get settingsGroupPagePrefs => 'Filters and sorting';

  @override
  String get settingsComingSoon => 'Coming soon';

  @override
  String get settingsFontThai => 'Thai font';

  @override
  String get settingsFontEnglish => 'English font';

  @override
  String get settingsPreview => 'Preview';

  @override
  String get settingsSectionNumbers => 'Number display';

  @override
  String get settingsSectionEntryDefaults => 'Entry defaults';

  @override
  String get settingsFeeCategory => 'Fee category';

  @override
  String get settingsFeeCategoryHint => 'Used for transfers with a fee';

  @override
  String get settingsSyncFootnote =>
      'The same auto switches as on the event page and the person page: change them anywhere, it\'s one value';

  @override
  String get notifSettingsOnOffLegend =>
      'Notify = send me a notification about it\nEvents / Splits = auto: don\'t ask, just do it\nWith auto off, notify stays on: someone has to answer';

  @override
  String get notifGroupSharedBills => 'Shared bills';

  @override
  String get notifSetSplitChanged => 'Someone edited a bill shared with me';

  @override
  String get notifSetSharedBillDeleted =>
      'Someone deleted a bill shared with me';

  @override
  String get notifSetSharedBillDisconnected =>
      'Someone disconnected a bill shared with me';

  @override
  String get notifSetSharedBillDisconnectedHint =>
      'My bill stays, just no longer connected';

  @override
  String get notifSetDebtDisconnectedHint =>
      'My debt stays, just no longer connected';

  @override
  String get notifSetEventCompleted => 'Event completed';

  @override
  String get notifSetEventCompletedHint =>
      'Locked for good, no more updates, claim once';

  @override
  String get notifSetEventMemberRemoved => 'Removed from an event';

  @override
  String get notifSetEventMemberRemovedHint =>
      'What I booked stays, just no longer connected';

  @override
  String get notifSetRecurringAutoCreatedHint =>
      'Entries recorded for me on schedule';

  @override
  String get notifSetRequests =>
      'Event invites, contact link requests, wallet invites';

  @override
  String get notifActionAddToBook => 'Add to my book';

  @override
  String get notifActionRemoveMine => 'Remove mine too';

  @override
  String get notifActionKeepMine => 'Keep';

  @override
  String notifSharedBillCreated(String who, String what) {
    return '$who recorded $what, a bill you\'re in';
  }

  @override
  String notifSharedBillDeleted(String who, String what) {
    return '$who deleted the bill $what';
  }

  @override
  String notifSharedBillDisconnected(String who, String what) {
    return '$who disconnected from the bill $what';
  }

  @override
  String notifEventCompleted(String who, String name) {
    return '$who completed the event $name';
  }

  @override
  String notifEventMemberRemoved(String who, String name) {
    return '$who removed you from the event $name';
  }

  @override
  String get notifBillRemovedMine =>
      'This bill\'s records were removed from your book';

  @override
  String get notifBillGone => 'This bill was deleted';

  @override
  String get notifBillDisconnectedMine =>
      'You disconnected this bill; connect again from the bill';

  @override
  String get txLinkDisconnectBodyCopy =>
      'This entry and your debts from this bill become plain records you edit freely. The bill doesn\'t change and its edits won\'t reach you any more.';

  @override
  String get evbEmptyPerson => 'No one yet';

  @override
  String get evbAssignMe => 'Me';

  @override
  String get evbAssignTitle => 'Who takes this spot';

  @override
  String get evbAssignWhose => 'Whose spots';

  @override
  String get evbAssignAction => 'Fill in';

  @override
  String get evbAssigned => 'Spot filled';

  @override
  String evbEmptyPersonsNotice(int count) {
    return '$count bills have an empty spot from a removed member: fill them before completing the event';
  }

  @override
  String get evbBillChanged => 'This bill was changed meanwhile; reloaded';

  @override
  String get evbSplitBill => 'Split bill';

  @override
  String get fpRecurringKindDebt => 'Debt';

  @override
  String get pagePrefSort => 'Sort';

  @override
  String get pagePrefFilter => 'Filter';

  @override
  String get pagePrefStatus => 'Status';

  @override
  String get pagePrefKind => 'Kind';

  @override
  String get pagePrefLink => 'Link';

  @override
  String get pagePrefCollapsed => 'Collapsed parents';

  @override
  String get pagePrefAll => 'All';

  @override
  String get pagePrefPendingManual => 'Added by me';

  @override
  String get pagePrefPendingOthers => 'From others';

  @override
  String get pagePrefNone => 'none';

  @override
  String get pagePrefsChanged => 'Changed';

  @override
  String get pagePrefsCaption =>
      'Picking on a page changes it here too\nTap to set it yourself';

  @override
  String get pagePrefsFootnote =>
      'Tabs, date ranges and search start fresh every time a page opens';

  @override
  String get pagePrefsResetAll => 'Reset all to defaults';

  @override
  String get pagePrefsResetAllBody =>
      'Every page goes back to its default filters and sorting';

  @override
  String get pagePrefsResetPage => 'Reset this page';

  @override
  String get pagePrefsSetOnPage => 'Set on the page itself';

  @override
  String evbClaimTitle(String name) {
    return 'Into my book: $name';
  }

  @override
  String evbClaimTheyOwe(String name) {
    return '$name owes me';
  }

  @override
  String evbClaimIOwe(String name) {
    return 'I owe $name';
  }

  @override
  String get evbClaimPaybacks => 'Paybacks / loans';

  @override
  String get evbClaimUntitled => 'Bill';

  @override
  String get evbClaimDone => 'In my book';

  @override
  String get evbClaimNote =>
      'The picked bills become one debt with this person; bills someone else paid get a \"paid by\" entry of my share';

  @override
  String evbClaimConfirm(int count) {
    return 'Book $count bills';
  }

  @override
  String evbClaimed(String name) {
    return 'Booked with $name';
  }

  @override
  String get evbClaimNothing => 'No bills left to book';

  @override
  String get evbClaimMixed =>
      'Pick one side at a time: they owe me, or I owe them';

  @override
  String get evbClaimAlready => 'Some bills are already in your book';

  @override
  String get evbMyCopy => 'My book';

  @override
  String evbPaidByName(String name) {
    return 'Paid by $name';
  }

  @override
  String evbPaidBackName(String name) {
    return 'Paid $name back';
  }

  @override
  String get evbPrivateNote => 'Private note';

  @override
  String get evbPrivateNoteHint => 'Only you see it';

  @override
  String get evbCopyDisconnected =>
      'Disconnected: this bill doesn\'t reach my book';

  @override
  String get evbReconnect => 'Connect again';

  @override
  String get evbCopyOutOfSync => 'My book doesn\'t match the bill';

  @override
  String get evbApplyBill => 'Update to match';

  @override
  String get debtBillsTitle => 'Bills in this debt';

  @override
  String get debtBillSplit => 'Split bill';

  @override
  String get debtBillOutOfSync => 'Out of sync';

  @override
  String get evbJoinTitle => 'Join which bill';

  @override
  String evbJoinPaidBy(String name) {
    return '$name paid';
  }

  @override
  String get evbJoined => 'Joined the bill';

  @override
  String get evbSettlePairs => 'Real pairs';

  @override
  String get evbSettleSimplified => 'Fewest transfers';

  @override
  String get evbSettleBook => 'Into my book';

  @override
  String get evbSettleBookTitle => 'Book it into my book once?';

  @override
  String get evbSettleBookBody =>
      'The money that moves becomes entries, the bill debts you already booked are cleared to zero, and real pairs can\'t be booked any more.';

  @override
  String get evbSettleBooked => 'Booked into my book';

  @override
  String evbSettleBookedOn(String date) {
    return 'Booked into my book on $date';
  }

  @override
  String get evbSettleAlreadyBooked => 'Already booked';

  @override
  String evbBookLinePay(String name, String amount) {
    return 'Pay $name $amount';
  }

  @override
  String evbBookLineGet(String name, String amount) {
    return 'Receive from $name $amount';
  }

  @override
  String get occurrenceNothingOwed => 'Nothing is owed with this person now';

  @override
  String get recurringPausedNoBalance =>
      'Paused: nothing owed for 3 rounds | it starts again by itself with a new debt with this person';

  @override
  String get recurringNoBalanceChip => 'Nothing owed';

  @override
  String get debtsPersonAddRecurring => 'Make it recurring';

  @override
  String get occurrenceDebtPickEmpty => 'No entries with this person to link';

  @override
  String get debtFromEventLabel => 'From event bills';

  @override
  String get debtFromEventPick => 'Pick bills';

  @override
  String get txJoinBill => 'Join a bill in an event';

  @override
  String get settingsAcceptTitle => 'Auto-accept new bills';

  @override
  String get eventDeleteKeepsBills =>
      'Only the event goes. Its bills stay as split bills, everyone stays connected, and nothing in anyone\'s book is deleted.';

  @override
  String get eventDeleteKeepsBillsShort => 'Its bills stay, as split bills';

  @override
  String get evbPayersLabel => 'Paid by';

  @override
  String evbPayers(int count) {
    return 'Payers | $count';
  }

  @override
  String get evbAddPayer => 'Add a payer';

  @override
  String evbPayersLine(String payers) {
    return 'Paid by $payers';
  }

  @override
  String get settingsSectionSettings => 'Settings';

  @override
  String get settingsSectionData => 'Data';

  @override
  String settingsNotificationsSummary(int on, int total, int auto) {
    return 'Notify $on of $total | Auto $auto';
  }

  @override
  String settingsPagePrefsChangedSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages changed',
      one: '1 page changed',
      zero: 'No changes',
    );
    return '$_temp0';
  }

  @override
  String get settingsSectionAppearance => 'Look';

  @override
  String get settingsSectionLanguageFont => 'Language and fonts';

  @override
  String get settingsMoneyStyleHint =>
      'How income / expense amounts are signed';

  @override
  String get settingsMoneyDecimalsHint => 'Show the cents or not';

  @override
  String get notifColumnNotify => 'Notify';

  @override
  String get notifColumnAuto => 'Auto';

  @override
  String get notifAutoAcceptHint => 'Auto = put it in my book at once';

  @override
  String get notifAutoUpdateHint => 'Auto = update mine at once';

  @override
  String get notifAutoDeleteHint =>
      'Events: follows the Events switch of \"Someone edited a shared bill\"\nSplits: my copy always becomes a plain record';

  @override
  String get notifLockedByAutoHint =>
      'Auto is off, so notify can\'t be turned off';

  @override
  String get notifSetProjectAddedHint => 'Someone adds me as a member';

  @override
  String get notifSetRecurringDueHint => 'Payments to pay / receive today';

  @override
  String get notifSetRecurringEndingHint => 'The last payment is left';

  @override
  String get settingsAutoTitle => 'Auto';

  @override
  String get settingsAutoEventsDescription =>
      'For every event; set it in Settings › Notifications';

  @override
  String get settingsAutoDebtsDescription =>
      'For everyone; set it in Settings › Notifications';

  @override
  String get profileSectionAccount => 'Account';

  @override
  String get pagePrefsResetTitle => 'Reset';

  @override
  String get pagePrefsResetAllHint => 'Every page back to its defaults';

  @override
  String get pagePrefsResetPageBody =>
      'This page goes back to the default filters and sort';

  @override
  String pagePrefSetCount(String title, int count) {
    return '$title $count';
  }

  @override
  String get settingsMainWalletUnsetSummary => 'No main wallet';

  @override
  String get pagePrefsSectionPages => 'Pages';

  @override
  String connectionConnectingAttempt(int attempt, int attempts) {
    return 'Connecting… $attempt/$attempts';
  }

  @override
  String get connectionCantConnect => 'Can\'t reach the server';

  @override
  String get connectionsNotLinked => 'Not linked';

  @override
  String get connectionsPermissionChat => 'Log entries by chat';

  @override
  String get connectionsPermissionAsk => 'Ask for balances';

  @override
  String get connectionsPermissionSlip => 'Send slips';

  @override
  String get connectionsPermissionNotify => 'Notifications';

  @override
  String get connectionsPermissionLogin => 'Sign in with Google';

  @override
  String get connectionsPermissionSheets => 'Send entries to Sheets';

  @override
  String get connectionsPermissionCalendar => 'Put due dates in Calendar';

  @override
  String connectionsErrorNoPhoto(String name) {
    return '$name didn\'t send a picture';
  }

  @override
  String get connectionsErrorLastLoginMethod =>
      'Set a password first, or you won\'t be able to sign in';

  @override
  String get avatarColorsTitle => 'Colours & ring';

  @override
  String avatarColorsSlot(int n) {
    return 'Colour $n';
  }

  @override
  String get avatarColorsRingColor => 'Ring';

  @override
  String get avatarColorsClear => 'Clear this colour';

  @override
  String get avatarBorderNone => 'None';

  @override
  String get avatarBorderThin => 'Thin';

  @override
  String get avatarBorderThick => 'Thick';

  @override
  String get avatarBorderDashed => 'Dashed';

  @override
  String get profileSectionConnections => 'Connections';

  @override
  String get profileSectionPicture => 'Profile picture';

  @override
  String get profileSetPassword => 'Set a password';

  @override
  String get profileSetPasswordSnackSuccess => 'Password set';

  @override
  String profileUsernameReadOnly(String username) {
    return '@$username (can\'t change)';
  }

  @override
  String get profilePictureIcon => 'Icon';

  @override
  String get profilePictureUpload => 'Upload';

  @override
  String get profilePictureEdit => 'Edit';

  @override
  String profilePictureImportedAt(String date) {
    return 'Imported $date';
  }

  @override
  String get profileColorsLabel => 'Profile colours 1–3';

  @override
  String get connectionsTapToLink => 'Tap to link';

  @override
  String get connectionsSectionPermissions => 'Permissions';

  @override
  String connectionsPhotoFrom(String name) {
    return 'Picture from $name';
  }

  @override
  String get connectionsPhotoNotImported => 'Not imported yet';

  @override
  String get connectionsPhotoUpdate => 'Update';

  @override
  String get connectionsPhotoImport => 'Import';

  @override
  String connectionsPhotoDeleteTitle(String name) {
    return 'Delete the picture from $name?';
  }

  @override
  String get connectionsPhotoDeleteInUse =>
      'It\'s your profile picture; your icon is used after deleting';

  @override
  String connectionsChangeAccount(String name) {
    return 'Change $name account';
  }

  @override
  String get connectionsUnlink => 'Unlink';

  @override
  String connectionsUnlinkTitle(String name) {
    return 'Unlink $name?';
  }

  @override
  String connectionsLink(String name) {
    return 'Link $name';
  }

  @override
  String connectionsLinkedAt(String date) {
    return 'Linked $date';
  }

  @override
  String connectionsOpenFailed(String name) {
    return 'Couldn\'t open $name';
  }

  @override
  String get notifSetBillCreated => 'A new bill shared with me';

  @override
  String get notifColumnAutoEvents => 'Events';

  @override
  String get notifColumnAutoSplit => 'Splits';
}
