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
    FlowStep.action('Row "รายการประจำ" picked (ผูกกับ)', [
      FlowCall(
        'linkRecurringItem',
        note: 'binds this tx to the period occurrence',
      ),
    ]),
    FlowStep.action('Ask "อัปเดตยอดรายการประจำ" → อัปเดต', [
      FlowCall('updateRecurring', note: 'amount only'),
    ]),
    FlowStep.action('Button "บันทึก" (edit)', [
      FlowCall(
        'updateTransaction',
        note:
            'returns the row + wallet balances; also_update_link from the '
            'linked prompt; a date after today → an upcoming item',
      ),
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
      FlowCall(
        'deleteTransaction',
        note:
            'returns id + wallet balances; also_delete_link from the linked '
            'prompt',
      ),
    ]),
    FlowStep.action('Event card: out of the event', [
      FlowCall('removeBillFromProject'),
    ]),
  ]),
  PageFlow('quick-create-sheet', 'Create a transaction, a draft, or an event bill.', [
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
    FlowStep.action('Recurring picker opened (ผูกกับ)', [
      FlowCall(
        'listRecurring',
        note:
            'for_type = the draft type; active settings with their current occurrence',
      ),
    ]),
    FlowStep.action('After create with a recurring picked', [
      FlowCall(
        'linkRecurringItem',
        note: 'one extra call right after the tx exists',
      ),
    ]),
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
    FlowStep.action('Event mode opened', [
      FlowCall('listProjectTags', note: 'the event tags for the tag row'),
    ]),
    FlowStep.action('Button "บันทึก" (event mode)', [
      FlowCall(
        'createProjectTag',
        note: 'only for a new tag name: it becomes an event tag first',
      ),
      FlowCall(
        'createProjectTransaction',
        note: 'new bill (tag_ids); returns the EventPatch',
      ),
      FlowCall(
        'updateProjectTransaction',
        note: 'edit a bill (tag_ids); returns the EventPatch',
      ),
    ]),
    FlowStep.action('Mode chip "หนี้" (debt mode)', [
      FlowCall(
        'listDebtPeople',
        note: 'the person chip row (open people first)',
      ),
    ]),
    FlowStep.action('Person picker opened', [
      FlowCall('listDebtPeople', note: 'all=true, everyone, searchable'),
    ]),
    FlowStep.action('Section "ทำเครื่องหมายรายการที่จ่ายครบ" opened', [
      FlowCall('listDebtEntries', note: 'paid=false: the open entries'),
    ]),
    FlowStep.action('Button "บันทึก" (debt mode)', [
      FlowCall(
        'createDebtEntry',
        note:
            'entry + wallet tx + tags + paid labels; returns the balance + wallet balances',
      ),
    ]),
  ]),
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
    FlowStep.action('Button "ยืนยันทั้งหมดที่พร้อม"', [
      FlowCall('submitReadyPending', note: 'every draft with no needs_input'),
    ]),
    FlowStep.action('Sheet "ยืนยัน" (one draft)', [
      FlowCall('submitOnePending', note: 'returns rows + balances + badges'),
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
    FlowStep.action('Button "ลบ"', [
      FlowCall('deleteAccount', note: 'real delete; owner only'),
    ]),
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
    // fe-pages M5: delete preview first, then the delete after the confirm.
    FlowStep.action('Button "ลบ"', [
      FlowCall('getContact', note: 'include=delete_preview: the confirm text'),
      FlowCall('deleteContact'),
    ]),
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
    FlowStep.action('Undo / กู้คืน a hidden item', [
      FlowCall('restoreNotification'),
    ]),
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
    FlowStep.action('Event bill: copy to my book', [
      FlowCall('copyProjectTransactionToPersonal'),
    ]),
    FlowStep.action('Event link request: accept', [
      FlowCall('acceptProjectLinkRequest'),
    ]),
    FlowStep.action('Event link request: reject', [
      FlowCall('rejectProjectLinkRequest'),
    ]),
    FlowStep.action('Split request: accept', [
      FlowCall(
        'acceptDebtSplitRequest',
        note: 'my entry; opens the person page',
      ),
    ]),
    FlowStep.action('Split change: "อัปเดตตาม"', [
      FlowCall('applyDebtSplitChange'),
    ]),
    FlowStep.action('Split paid: "บันทึกรับเงิน"', [
      FlowCall(
        'getDebtEntry',
        note: 'the person, then quick create in debt mode',
      ),
    ]),
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
  PageFlow('archived', 'The archived hub (ที่เก็บถาวร) and its restores.', [
    FlowStep.open([FlowCall('getMyArchived', note: 'every kind, one call')]),
    FlowStep.action('กู้คืน (wallet)', [FlowCall('restoreAccount')]),
    FlowStep.action('กู้คืน (budget)', [FlowCall('restoreBudget')]),
    FlowStep.action('กู้คืน (goal)', [FlowCall('restoreSavingGoal')]),
    FlowStep.action('กู้คืน (event)', [FlowCall('restoreProject')]),
    FlowStep.action('กู้คืน (contact)', [FlowCall('restoreContact')]),
    FlowStep.action('กู้คืน (recurring)', [FlowCall('restoreRecurring')]),
  ]),
  PageFlow('auth', 'Sign in, register, sign out, app version.', [
    FlowStep.open([FlowCall('getAppVersion', note: 'boot / resume')]),
    FlowStep.action('Button "เข้าสู่ระบบ"', [FlowCall('login')]),
    FlowStep.action('Button "สมัคร"', [FlowCall('register')]),
    FlowStep.action('Button "ออกจากระบบ"', [FlowCall('logout')]),
  ]),

  // ── Events (projects) ───────────────────────────────────────────────────────
  PageFlow(
    'events-list',
    'All events (paged; search / status / my tags / sort on the server).',
    [
      FlowStep.open([FlowCall('listProjects')]),
      FlowStep.action('Search / status / tags / sort / scroll', [
        FlowCall('listProjects'),
      ]),
    ],
  ),
  PageFlow(
    'event-form',
    'Create an event (plan, dates, my tags in one call).',
    [
      FlowStep.action('Button "บันทึก"', [FlowCall('createProject')]),
    ],
  ),
  PageFlow('event-detail', 'One event: hero, my tags, สรุป, รายการ (board).', [
    FlowStep.open([FlowCall('getProjectDetail')]),
    FlowStep.action('รายการ: scroll / search / filter / sort', [
      FlowCall('listBoardRows'),
    ]),
    FlowStep.action('Button "บันทึก" (edit event) / status / my tags', [
      FlowCall('updateProject'),
    ]),
    FlowStep.action('Button "ลบอีเวนต์นี้"', [
      FlowCall('getProjectDetail', note: '?include=delete_preview'),
    ]),
    FlowStep.action('Delete dialog "ยืนยัน"', [FlowCall('deleteProject')]),
    FlowStep.action('Button "เชิญสมาชิก"', [FlowCall('addProjectMember')]),
    FlowStep.action('Tick a bill / split', [
      FlowCall('markProjectTransaction'),
    ]),
    FlowStep.action('Delete a bill', [FlowCall('deleteProjectTransaction')]),
    FlowStep.action('Tag menu "+ เพิ่มเข้าแท็กของฉัน" / "นำเข้าทั้งหมด"', [
      FlowCall('importProjectTags'),
    ]),
    FlowStep.action('Resolve sheet "บันทึกเป็นรายการ"', [
      FlowCall('createTransaction'),
    ]),
    FlowStep.action('Resolve sheet "บันทึกเป็นหนี้"', [
      FlowCall('createDebtEntry'),
    ]),
  ]),
  PageFlow('event-members', 'Members (on hold: kept as is, on the new API).', [
    FlowStep.open([FlowCall('getProject'), FlowCall('listProjectMembers')]),
    FlowStep.action('Button "เชิญสมาชิก"', [FlowCall('addProjectMember')]),
    FlowStep.action('Edit a member', [FlowCall('updateProjectMember')]),
    FlowStep.action('Remove a member', [FlowCall('removeProjectMember')]),
    FlowStep.action('Button "โอนความเป็นเจ้าของ"', [
      FlowCall('transferProjectOwnership'),
    ]),
    FlowStep.action('Button "ออกจากอีเวนต์"', [FlowCall('leaveProject')]),
  ]),

  // ── Budgets ─────────────────────────────────────────────────────────────────
  PageFlow('budgets-list', 'Budgets and their current periods.', [
    FlowStep.open([FlowCall('listBudgets')]),
    FlowStep.action('Chip active / ended / archived or the sort', [
      FlowCall('listBudgets'),
    ]),
  ]),
  PageFlow('budget-detail', 'One budget: its periods, items and rule.', [
    FlowStep.open([FlowCall('getBudget')]),
    FlowStep.action('Tap a period', [FlowCall('getBudget')]),
    FlowStep.action('Button "ดูเพิ่ม" (items)', [FlowCall('listBudgetItems')]),
    FlowStep.action('Button "ดูรอบก่อนหน้าทั้งหมด"', [
      FlowCall('listBudgetPeriods'),
    ]),
    FlowStep.action('Button "แก้เฉพาะรอบนี้"', [
      FlowCall('updateBudgetPeriod'),
    ]),
    FlowStep.action('Button "บันทึก" (create)', [FlowCall('createBudget')]),
    FlowStep.action('Button "บันทึก" (edit)', [FlowCall('updateBudget')]),
    FlowStep.action('Button "ปิดงบ"', [FlowCall('closeBudget')]),
    FlowStep.action('Button "เก็บถาวร"', [FlowCall('archiveBudget')]),
    FlowStep.action('Button "กู้คืน"', [FlowCall('restoreBudget')]),
    // fe-pages M5: delete preview first, then the delete after the confirm.
    FlowStep.action('Button "ลบ"', [
      FlowCall('getBudget', note: 'include=delete_preview: the confirm text'),
      FlowCall('deleteBudget'),
    ]),
  ]),

  // ── Saving goals ────────────────────────────────────────────────────────────
  PageFlow('goals-list', 'Saving goals and the spare pool.', [
    FlowStep.open([FlowCall('listSavingGoals', note: 'sort=')]),
    // fe-pages M5: the sort chip re-opens the list with sort=.
    FlowStep.action('Sort chip', [FlowCall('listSavingGoals')]),
    FlowStep.action('Spare opened', [
      FlowCall('getSavingSpare', note: 'saved but not yet in a goal'),
    ]),
    FlowStep.action('Button "เพิ่มเป้าหมาย"', [FlowCall('createSavingGoal')]),
  ]),
  PageFlow('goals-detail', 'One saving goal and its saving entries.', [
    FlowStep.open([FlowCall('getSavingGoal')]),
    FlowStep.action('Entries opened / scroll', [FlowCall('listSavingEntries')]),
    FlowStep.action('Button "เพิ่มเงินออม" / "ถอน" / "ย้าย"', [
      FlowCall('createSavingEntry'),
    ]),
    FlowStep.action('Edit an entry', [FlowCall('updateSavingEntry')]),
    FlowStep.action('Delete an entry', [FlowCall('deleteSavingEntry')]),
    FlowStep.action('Button "บันทึก"', [FlowCall('updateSavingGoal')]),
    FlowStep.action('Button "ปิดเป้าหมาย"', [FlowCall('closeSavingGoal')]),
    // fe-pages M5: delete preview first (can_delete), then the delete.
    FlowStep.action('Button "ลบ"', [
      FlowCall('getSavingGoal', note: 'include=delete_preview'),
      FlowCall('deleteSavingGoal'),
    ]),
    FlowStep.action('Button "เก็บถาวร"', [FlowCall('archiveSavingGoal')]),
    FlowStep.action('Button "กู้คืน"', [FlowCall('restoreSavingGoal')]),
  ]),

  // ── Recurring + upcoming items (owner 2026-10-13) ───────────────────────────
  PageFlow(
    'recurring-home',
    'Recurring settings, reminders and the calendar.',
    [
      FlowStep.open([
        FlowCall('listRecurring', note: 'both list tabs + the summary card'),
      ]),
      FlowStep.action('Tab "ปฏิทิน" (lazy) / month stepper', [
        FlowCall('listRecurringItems', note: '?month=YYYY-MM'),
      ]),
      FlowStep.action('Search / status chip', [FlowCall('listRecurring')]),
    ],
  ),
  PageFlow(
    'recurring-detail',
    'One recurring: what it made and what is next.',
    [
      FlowStep.open([FlowCall('getRecurring')]),
      FlowStep.action('Tab "ล่วงหน้า" (lazy) + scroll', [
        FlowCall('listRecurringRuleItems'),
      ]),
      FlowStep.action('Status chip พัก / ทำต่อ', [
        FlowCall('pauseRecurring'),
        FlowCall('resumeRecurring'),
      ]),
      FlowStep.action('Button "ต่ออีก"', [FlowCall('extendRecurring')]),
      FlowStep.action('Selection toolbar', [FlowCall('batchRecurringItems')]),
      FlowStep.action('Item popover', [
        FlowCall('createFromRecurringItem', note: 'item → a pending draft'),
        FlowCall('archiveRecurringItem'),
        FlowCall('restoreRecurringItem'),
        FlowCall('deleteRecurringItem'),
      ]),
      FlowStep.action('Item entry sheet "บันทึก"', [
        FlowCall('updateRecurringItem'),
        FlowCall('createRecurringItem'),
      ]),
    ],
  ),
  // fe-pages: the 0.4.0 recurring pages (view ⇄ edit is ONE page now).
  PageFlow('recurring-occurrence', 'One occurrence of a recurring.', [
    FlowStep.action('แก้ยอด / ใส่ยอด / เลื่อนวัน', [
      FlowCall('updateRecurringItem', note: '{date, amount}, scope this'),
    ]),
    FlowStep.action('ข้าม / กู้คืน', [
      FlowCall('archiveRecurringItem'),
      FlowCall('restoreRecurringItem'),
    ]),
  ]),
  PageFlow('recurring-duplicate', 'Copy a recurring (edit mode end zone).', [
    FlowStep.action('Button "ทำสำเนา"', [FlowCall('duplicateRecurring')]),
  ]),
  PageFlow('recurring-settings', 'Create or edit a recurring.', [
    FlowStep.open([FlowCall('getRecurring', note: 'edit only')]),
    FlowStep.action('Button "บันทึก"', [
      FlowCall('createRecurring'),
      FlowCall('updateRecurring'),
    ]),
    FlowStep.action('Button "เก็บถาวร" / "กู้คืน"', [
      FlowCall('archiveRecurring'),
      FlowCall('restoreRecurring'),
    ]),
    FlowStep.action('Button "ลบ"', [
      FlowCall('getRecurring', note: '?include=delete_preview'),
    ]),
    FlowStep.action('Delete dialog "ยืนยัน"', [FlowCall('deleteRecurring')]),
  ]),

  // ── Debts ───────────────────────────────────────────────────────────────────
  PageFlow(
    'debts-people',
    'One list of people and their net (ติดคุณ / คุณติด together).',
    [
      FlowStep.open([FlowCall('listDebtPeople', note: 'page 1 + totals')]),
      FlowStep.action('Search / "ทั้งหมด" / a summary box / scroll', [
        FlowCall('listDebtPeople'),
      ]),
    ],
  ),
  PageFlow('debt-person', 'One person: the net, the timeline, the payments.', [
    FlowStep.open([
      FlowCall(
        'getDebtPerson',
        note: 'balance + counts + the first timeline page',
      ),
    ]),
    FlowStep.action(
      'Tab "ประวัติการจ่าย" (first open) / search / filter / sort / scroll',
      [FlowCall('listDebtEntries')],
    ),
    FlowStep.action('The paid label on an entry', [
      FlowCall('updateDebtEntry', note: 'paid only'),
    ]),
  ]),
  PageFlow(
    'debt-entry',
    'An entry: the transaction detail page in debt mode.',
    [
      FlowStep.open([
        FlowCall('getDebtEntry', note: 'entry + balance + the full tx row'),
      ]),
      FlowStep.action('Button "บันทึก"', [FlowCall('updateDebtEntry')]),
      FlowStep.action('Button "ลบ"', [
        FlowCall(
          'deleteDebtEntry',
          note: 'deletes the wallet tx too; returns balances',
        ),
      ]),
    ],
  ),
];
