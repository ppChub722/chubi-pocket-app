/// The page-flow registry — the FE's own account of what each page calls, and
/// WHEN: on open, or on a button / gesture. It is the source of truth for the
/// hub's API "Pages" view and for each endpoint's "used by" (the spec's
/// `x-used-by` is no longer read).
///
/// The target (owner 2026-10-12): ONE call on open, ONE call per action. A
/// page over it shows a red badge in the hub.
///
/// - A call names an operation of the BE spec by `operationId`.
/// - A call the app makes that the spec does not describe yet is
///   [FlowCall.unspecified] (shown grey, "not in spec yet").
///
/// `test/hub/page_flows_test.dart` keeps it honest: every operationId exists
/// in the BE spec, an unspecified call really is not in it, and every
/// endpoint the app calls is in some flow or on the baseline of debt.
library;

class FlowCall {
  /// An operation of the BE spec.
  const FlowCall(this.operationId, {this.note}) : method = null, path = null;

  /// A call the spec does not describe yet.
  const FlowCall.unspecified(this.method, this.path, {this.note})
    : operationId = null;

  final String? operationId;
  final String? method;
  final String? path;

  /// What it is for on this page (the spec's summary is the fallback).
  final String? note;

  bool get inSpec => operationId != null;
}

class FlowStep {
  const FlowStep.open(this.calls, {this.today}) : trigger = null;
  const FlowStep.action(String this.trigger, this.calls, {this.today});

  /// What the app does today for this trigger, for contrast with the target
  /// ("3 calls"); null = not measured / same.
  final String? today;

  /// A button label / gesture ("Button \"บันทึก\"", "Swipe a draft"); null =
  /// the page opening.
  final String? trigger;
  final List<FlowCall> calls;

  bool get isOpen => trigger == null;
  String get label => trigger ?? 'On open';
}

class PageFlow {
  const PageFlow(this.page, this.purpose, this.steps);

  /// The page's slug, as the spec's tags and the hub show it.
  final String page;
  final String purpose;
  final List<FlowStep> steps;

  int get openCalls =>
      steps.where((s) => s.isOpen).fold(0, (n, s) => n + s.calls.length);
  Iterable<FlowStep> get actions => steps.where((s) => !s.isOpen);

  /// Over the target: more than one call on open, or an action that makes
  /// more than one.
  bool get overOpen => openCalls > 1;
  int get overActions => actions.where((s) => s.calls.length > 1).length;
}

/// The TARGET flows after the 0.3.1-9 API rework (spec draft 2, owner reviews
/// them in /#/dev/api/pages): what runs on open, what each button calls.
/// "today" notes are read from the current code (first open; lists are
/// cached afterwards) — the Network page of the Debug section measures the
/// rest in the real app.
const List<PageFlow> pageFlows = [
  // ── App shell ────────────────────────────────────────────────────────────
  PageFlow(
    'connection',
    'The offline banner: while the server is unreachable the app polls /health every few seconds (backoff 3 → 10 s) until it answers.',
    [
      FlowStep.action('Server unreachable (a network-level failure)', [
        FlowCall.unspecified(
          'GET',
          '/health',
          note: 'Liveness poll while offline; any answer = back online.',
        ),
      ]),
    ],
  ),
  // ── Reached pages ──────────────────────────────────────────────────────────
  PageFlow(
    'home',
    'The landing page: balances, month summary, recent rows, pending and attention blocks.',
    [
      FlowStep.open([
        FlowCall(
          'getDashboard',
          note: 'home in one call: pending, attention, badges inside',
        ),
      ]),
    ],
  ),
  PageFlow('transactions-list', 'Every transaction, filtered, with totals.', [
    FlowStep.open([
      FlowCall('listTransactions', note: 'self-contained rows + totals'),
    ]),
    FlowStep.action('Filter sheet opened (lazy)', [
      FlowCall('getTransactionFormOptions', note: 'wallets, categories, tags'),
    ]),
  ]),
  PageFlow('transaction-detail', 'One transaction: view, edit, delete.', [
    FlowStep.open([
      FlowCall(
        'getTransaction',
        note: 'refs, tags, event, transfer twin, splits with persons',
      ),
    ]),
    FlowStep.action('Button "บันทึก" (edit)', [
      FlowCall('updateTransaction', note: 'returns the row + wallet balances'),
    ]),
    FlowStep.action('Change tags', [
      FlowCall('setTransactionTags', note: 'replaces the tag set'),
    ]),
    FlowStep.action('Split editor opened (lazy)', [
      FlowCall('listContacts', note: 'person picker'),
    ]),
    FlowStep.action('Button "บันทึก" (splits)', [
      FlowCall('editSplits', note: 'replaces the whole split list'),
    ]),
    FlowStep.action('Button "ลบ"', [
      FlowCall('deleteTransaction', note: 'returns id + wallet balances'),
    ]),
  ]),
  PageFlow(
    'quick-create-sheet',
    'Create a transaction, a draft, or an event bill.',
    [
      FlowStep.open(
        [
          FlowCall(
            'getTransactionFormOptions',
            note:
                'wallets (+default), categories, tags, active events, fee category',
          ),
        ],
        today:
            '3 calls on first open (GET /accounts, /categories, /tags), then cached',
      ),
      FlowStep.action('Button "บันทึก"', [
        FlowCall(
          'createTransaction',
          note: 'creates tx + tags + splits; returns the row + wallet balances',
        ),
      ], today: '3 calls (create, reload wallets, reload the book)'),
      FlowStep.action('Button "บันทึกร่าง"', [
        FlowCall('createPending', note: 'saves a draft'),
      ]),
      FlowStep.action('Button "สร้างอีเวนต์"', [
        FlowCall('quickCreateEvent', note: 'creates the event from the bills'),
      ]),
      FlowStep.action('Button "เพิ่มเข้าอีเวนต์"', [
        FlowCall('addBillsToEvent', note: 'adds the bills to an event'),
      ]),
      FlowStep.action('Split editor opened (lazy)', [
        FlowCall('listContacts', note: 'person picker'),
      ]),
    ],
  ),
  PageFlow('pending', 'Drafts waiting to be confirmed.', [
    FlowStep.open(
      [FlowCall('listPending', note: 'drafts, rows carry "resolved"')],
      today:
          '4 calls on first open (GET /pending-transactions + /accounts, /categories, /tags)',
    ),
    FlowStep.action('Draft edit sheet opened (lazy)', [
      FlowCall('getTransactionFormOptions', note: 'pickers'),
    ]),
    FlowStep.action('Button "ยืนยัน"', [
      FlowCall(
        'submitPending',
        note: 'returns rows + wallet balances + badges',
      ),
    ]),
    FlowStep.action('Add drafts → "บันทึก"', [FlowCall('createPending')]),
    FlowStep.action('Edit a draft → "บันทึก"', [FlowCall('updatePending')]),
    FlowStep.action('Discard one draft', [FlowCall('deletePending')]),
    FlowStep.action('Select + discard', [
      FlowCall('discardPending', note: 'many drafts, one call'),
    ]),
    FlowStep.action('Slip import opened (lazy)', [
      FlowCall('listPaymentProviders'),
    ]),
    FlowStep.action('Button "สแกนสลิป"', [FlowCall('scanSlip')]),
    FlowStep.action('Slips picked', [
      FlowCall('checkSlips', note: 'duplicate check'),
    ]),
    FlowStep.action('Button "ล้างประวัติสลิป"', [FlowCall('resetSlipHistory')]),
    FlowStep.action('Chat text parse', [
      FlowCall('parseText', note: 'stub until 0.3.2'),
    ]),
  ]),
  PageFlow('wallets-list', 'All wallets with totals.', [
    FlowStep.open([FlowCall('listAccounts', note: 'wallets + totals')]),
    FlowStep.action('Button "เพิ่มกระเป๋า"', [FlowCall('createAccount')]),
    FlowStep.action('Reorder', [FlowCall('reorderAccounts')]),
  ]),
  PageFlow('wallet-detail', 'One wallet: balance, members, month, its rows.', [
    FlowStep.open([
      FlowCall(
        'getAccount',
        note: 'include=summary,members: wallet + members + month totals',
      ),
    ]),
    FlowStep.action('Transactions tab opened (lazy)', [
      FlowCall('listTransactions', note: 'rows of this wallet (account_id)'),
    ]),
    FlowStep.action('Button "บันทึก" (edit)', [FlowCall('updateAccount')]),
    FlowStep.action('Button "เก็บถาวร"', [FlowCall('archiveAccount')]),
    FlowStep.action('Button "กู้คืน"', [FlowCall('restoreAccount')]),
    FlowStep.action('Button "ปรับยอด"', [FlowCall('adjustAccountBalance')]),
    FlowStep.action('Add an identifier', [FlowCall('addAccountIdentifier')]),
    FlowStep.action('Button "เชิญสมาชิก"', [FlowCall('inviteAccountMember')]),
    FlowStep.action('Remove a member', [FlowCall('removeAccountMember')]),
    FlowStep.action('Button "โอนความเป็นเจ้าของ"', [
      FlowCall('transferAccountOwnership'),
    ]),
    FlowStep.action('Report scope switch', [
      FlowCall('updateAccountReportScope'),
    ]),
  ]),
  PageFlow('categories-list', 'All categories.', [
    FlowStep.open([FlowCall('listCategories')]),
    FlowStep.action('Button "เพิ่มหมวด"', [FlowCall('createCategory')]),
    FlowStep.action('Reorder', [FlowCall('reorderCategories')]),
  ]),
  PageFlow('category-detail', 'One category: counts, fee flag, edit, delete.', [
    FlowStep.open([
      FlowCall('getCategory', note: 'counts + the fee flag in one call'),
    ]),
    FlowStep.action('Button "บันทึก"', [FlowCall('updateCategory')]),
    FlowStep.action('Button "ลบ"', [FlowCall('deleteCategory')]),
  ]),
  PageFlow('tags', 'Tags with their usage.', [
    FlowStep.open([FlowCall('listTags', note: 'with usage_count')]),
    FlowStep.action('Button "เพิ่มแท็ก"', [FlowCall('createTag')]),
    FlowStep.action('Edit a tag', [FlowCall('updateTag')]),
    FlowStep.action('Button "ลบ"', [FlowCall('deleteTag')]),
  ]),
  PageFlow('contacts-list', 'All contacts, names already resolved.', [
    FlowStep.open([FlowCall('listContacts')]),
  ]),
  PageFlow('contact-detail', 'One contact: view, create, edit, link.', [
    FlowStep.open([
      FlowCall('getContact', note: 'include=unlinked_names: one call'),
    ]),
    FlowStep.action('Button "บันทึก" (new)', [FlowCall('createContact')]),
    FlowStep.action('Button "บันทึก" (edit)', [
      FlowCall('updateContact', note: 'incl. nickname / show_nickname'),
    ]),
    FlowStep.action('Button "ลบ"', [FlowCall('deleteContact')]),
    FlowStep.action('Button "เก็บถาวร"', [FlowCall('archiveContact')]),
    FlowStep.action('Button "กู้คืน"', [FlowCall('restoreContact')]),
    FlowStep.action('Button "ขอลิงก์"', [FlowCall('requestContactLink')]),
    FlowStep.action('Button "ยกเลิกลิงก์"', [FlowCall('unlinkContact')]),
    FlowStep.action('Button "รวมชื่อ"', [FlowCall('absorbContactNames')]),
  ]),
  PageFlow('notifications', 'The notification list and its one-tap actions.', [
    FlowStep.open([FlowCall('listNotifications', note: 'items display-ready')]),
    FlowStep.action('Tap an item', [FlowCall('markNotificationRead')]),
    FlowStep.action('Button on an item', [
      FlowCall('markNotificationActioned'),
    ]),
    FlowStep.action('Swipe an item', [FlowCall('dismissNotification')]),
    FlowStep.action('Button "อ่านทั้งหมด"', [FlowCall('readAllNotifications')]),
    FlowStep.action('Button "ลบ"', [FlowCall('deleteNotification')]),
    FlowStep.action('Link request opened', [FlowCall('getLinkRequestSender')]),
    FlowStep.action('Link request: accept', [
      FlowCall('acceptContactLinkRequest'),
    ]),
    FlowStep.action('Link request: new linked contact', [
      FlowCall('createLinkedContactFromRequest'),
    ]),
    FlowStep.action('Link request: link an existing contact', [
      FlowCall('linkExistingContactFromRequest'),
    ]),
    FlowStep.action('Link request: reject', [
      FlowCall('rejectContactLinkRequest'),
    ]),
    FlowStep.action('Wallet invite: accept', [FlowCall('acceptAccountInvite')]),
    FlowStep.action('Wallet invite: reject', [FlowCall('rejectAccountInvite')]),
    FlowStep.action('Unlinked names opened', [FlowCall('listUnlinkedNames')]),
  ]),
  PageFlow('notifications-badge', 'The bell badge in the shell (a poll).', [
    FlowStep.open([FlowCall('getUnreadCount', note: 'the cheap poll')]),
  ]),
  PageFlow('more-hub', 'The More tab: counts and badges.', [
    FlowStep.open([FlowCall('getMyCounts', note: 'badges + counts')]),
  ]),
  PageFlow('settings-notifications', 'Notification preferences.', [
    FlowStep.open([
      FlowCall('getNotificationSettings', note: 'default wallet as a full ref'),
    ]),
    FlowStep.action('Change a switch', [
      FlowCall('updateNotificationSettings'),
    ]),
    FlowStep.action('Wallet picker opened (lazy)', [FlowCall('listAccounts')]),
  ]),
  PageFlow('settings-account', 'Profile, password, deactivate.', [
    FlowStep.open([FlowCall('getMe', note: 'typed preferences')]),
    FlowStep.action('Button "บันทึก"', [FlowCall('updateMe')]),
    FlowStep.action('Change password', [FlowCall('changePassword')]),
    FlowStep.action('Button "ปิดบัญชี"', [FlowCall('deactivateMe')]),
    FlowStep.action('Button "เปิดบัญชีอีกครั้ง"', [FlowCall('reactivateMe')]),
    FlowStep.action('Icon packs opened (lazy)', [FlowCall('listMyPacks')]),
  ]),
  PageFlow('auth', 'Sign in, register, sign out, app version.', [
    FlowStep.open([FlowCall('getAppVersion', note: 'boot / resume')]),
    FlowStep.action('Button "เข้าสู่ระบบ"', [FlowCall('login')]),
    FlowStep.action('Button "สมัคร"', [FlowCall('register')]),
    FlowStep.action('Button "ออกจากระบบ"', [FlowCall('logout')]),
  ]),

  // ── Events (projects) ───────────────────────────────────────────────────────
  PageFlow('events-list', 'All events.', [
    FlowStep.open([FlowCall('listProjects')]),
    FlowStep.action('Button "สร้างอีเวนต์"', [FlowCall('createProject')]),
  ]),
  PageFlow('event-detail', 'One event: summary, members and board rows.', [
    FlowStep.open([
      FlowCall('getProject'),
      FlowCall('listBoardRows', note: 'event board rows'),
    ]),
    FlowStep.action('Summary tab opened (lazy)', [
      FlowCall('getProjectSummary'),
    ]),
    FlowStep.action('Members tab opened (lazy)', [
      FlowCall('listProjectMembers'),
    ]),
    FlowStep.action('Tag filter opened (lazy)', [FlowCall('listProjectTags')]),
    FlowStep.action('Button "บันทึก" (edit event)', [
      FlowCall('updateProject'),
    ]),
    FlowStep.action('Button "ลบอีเวนต์"', [FlowCall('deleteProject')]),
    FlowStep.action('Button "เพิ่มสมาชิก"', [FlowCall('addProjectMember')]),
    FlowStep.action('Edit a member', [FlowCall('updateProjectMember')]),
    FlowStep.action('Remove a member', [FlowCall('removeProjectMember')]),
    FlowStep.action('Button "ขอลิงก์"', [FlowCall('requestProjectMemberLink')]),
    FlowStep.action('Button "โอนความเป็นเจ้าของ"', [
      FlowCall('transferProjectOwnership'),
    ]),
    FlowStep.action('Button "ออกจากอีเวนต์"', [FlowCall('leaveProject')]),
    FlowStep.action('Button "เพิ่มรายการ"', [
      FlowCall('createProjectTransaction'),
    ]),
    FlowStep.action('Edit an event row', [
      FlowCall('updateProjectTransaction'),
    ]),
    FlowStep.action('Delete an event row', [
      FlowCall('deleteProjectTransaction'),
    ]),
    FlowStep.action('Mark an event row', [FlowCall('markProjectTransaction')]),
    FlowStep.action('Button "คัดลอกเข้าบัญชีฉัน"', [
      FlowCall('copyProjectTransactionToPersonal'),
    ]),
    FlowStep.action('Button "เพิ่มบิล"', [FlowCall('addBillsToEvent')]),
    FlowStep.action('Remove a bill', [FlowCall('removeBillFromProject')]),
    FlowStep.action('Link request: accept', [
      FlowCall('acceptProjectLinkRequest'),
    ]),
    FlowStep.action('Link request: reject', [
      FlowCall('rejectProjectLinkRequest'),
    ]),
  ]),

  // ── Budgets ─────────────────────────────────────────────────────────────────
  PageFlow('budgets-list', 'Budgets and the period overview.', [
    FlowStep.open([FlowCall('listBudgets')]),
    FlowStep.action('Overview opened (lazy)', [FlowCall('getBudgetsOverview')]),
    FlowStep.action('Button "เพิ่มงบ"', [FlowCall('createBudget')]),
  ]),
  PageFlow('budget-detail', 'One budget.', [
    FlowStep.open([FlowCall('getBudget')]),
    FlowStep.action('Button "บันทึก"', [FlowCall('updateBudget')]),
    FlowStep.action('Button "ลบ"', [FlowCall('deleteBudget')]),
    FlowStep.action('Button "เก็บถาวร"', [FlowCall('archiveBudget')]),
    FlowStep.action('Button "กู้คืน"', [FlowCall('restoreBudget')]),
  ]),

  // ── Saving goals ────────────────────────────────────────────────────────────
  PageFlow('goals-list', 'Saving goals.', [
    FlowStep.open([FlowCall('listSavingGoals')]),
    FlowStep.action('Button "เพิ่มเป้าหมาย"', [FlowCall('createSavingGoal')]),
  ]),
  PageFlow('goals-detail', 'One saving goal.', [
    FlowStep.open([FlowCall('getSavingGoal')]),
    FlowStep.action('Button "บันทึก"', [FlowCall('updateSavingGoal')]),
    FlowStep.action('Button "ลบ"', [FlowCall('deleteSavingGoal')]),
    FlowStep.action('Button "เก็บถาวร"', [FlowCall('archiveSavingGoal')]),
    FlowStep.action('Button "กู้คืน"', [FlowCall('restoreSavingGoal')]),
  ]),
  PageFlow('wallet-savings', 'What a wallet has set aside for goals.', [
    FlowStep.open([FlowCall('getAccountSavingAllocations')]),
  ]),

  // ── Scheduled ───────────────────────────────────────────────────────────────
  PageFlow('scheduled-list', 'Scheduled transactions and what is coming up.', [
    FlowStep.open([FlowCall('listScheduled')]),
    FlowStep.action('Upcoming opened (lazy)', [
      FlowCall('listScheduledUpcoming'),
    ]),
    FlowStep.action('Button "เพิ่มรายการประจำ"', [FlowCall('createScheduled')]),
  ]),
  PageFlow('scheduled-detail', 'One scheduled transaction.', [
    FlowStep.open([FlowCall('getScheduled')]),
    FlowStep.action('History opened (lazy)', [FlowCall('getScheduledHistory')]),
    FlowStep.action('Button "บันทึก"', [FlowCall('updateScheduled')]),
    FlowStep.action('Button "ลบ"', [FlowCall('deleteScheduled')]),
    FlowStep.action('Button "พัก"', [FlowCall('pauseScheduled')]),
    FlowStep.action('Button "เริ่มต่อ"', [FlowCall('resumeScheduled')]),
    FlowStep.action('Button "ยกเลิก"', [FlowCall('cancelScheduled')]),
    FlowStep.action('Button "สร้างตอนนี้"', [
      FlowCall('generateScheduledNow', note: 'returns wallet balances'),
    ]),
  ]),

  // ── Debts ───────────────────────────────────────────────────────────────────
  PageFlow('debts-list', 'Debts and the people they are with.', [
    FlowStep.open([
      FlowCall('listDebts'),
      FlowCall('listDebtPeople', note: 'grouped by person'),
    ]),
    FlowStep.action('Button "เพิ่มหนี้"', [FlowCall('createDebt')]),
  ]),
  PageFlow('debt-detail', 'One debt and its payments.', [
    FlowStep.open([FlowCall('getDebt')]),
    FlowStep.action('Button "ชำระ"', [
      FlowCall(
        'settleDebt',
        note: 'records a payment; returns wallet balances',
      ),
    ]),
    FlowStep.action('Button "บันทึก"', [FlowCall('updateDebt')]),
    FlowStep.action('Button "ลบ"', [FlowCall('deleteDebt')]),
    FlowStep.action('Button "ยกเลิกหนี้"', [FlowCall('cancelDebt')]),
    FlowStep.action('Split request: accept', [
      FlowCall('acceptDebtSplitRequest'),
    ]),
    FlowStep.action('Split change: apply', [FlowCall('applyDebtSplitChange')]),
  ]),
];
