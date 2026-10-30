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
    'The offline banner: while the server is unreachable the app pings /health (10 s after each failed result, 6 retries, then a Retry button; never on /dev).',
    [
      FlowStep.action('Server unreachable (a network-level failure)', [
        FlowCall(
          'getHealth',
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
    FlowStep.action('Row "รายการประจำ" chip ✕ (ผูกกับ)', [
      FlowCall(
        'unlinkRecurringItem',
        note: 'occurrence open again; the tx is untouched',
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
    FlowStep.action('Button "บันทึก" after switching the ผูกกับ tab', [
      FlowCall(
        'updateTransaction',
        note:
            '?preview=true first (nothing saved): who / which wallet moves, '
            'for the ONE confirm',
      ),
      FlowCall(
        'updateTransaction',
        note:
            'then the PUT with link_mode + that tab\'s data; returns the '
            'row + person_balances',
      ),
    ]),
    FlowStep.action('Row "บิลในอีเวนต์ถูกแก้ | อัปเดตตามอีเวนต์"', [
      FlowCall(
        'applyEventToTransaction',
        note: 'my tx takes the bill as it is now (event_bill.in_sync false)',
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
    // 0.4.1-2 (V16): the event pick on the new endpoints only.
    FlowStep.action('Event pick: a bill I\'m in → another event', [
      FlowCall(
        'rebookEventBill',
        note: 'move (project_id / new_event); every copy stays connected',
      ),
    ]),
    FlowStep.action('Event pick: not in a bill → join an event', [
      FlowCall(
        'updateTransaction',
        note: 'the อีเวนต์ link (I paid); a new event is made first',
      ),
    ]),
    FlowStep.action('Event card "ตัดการเชื่อม"', [
      FlowCall(
        'disconnectEventBill',
        note: 'my copy tx + my debts of the bill become plain; the bill stays',
      ),
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
    FlowStep.action('Button "บันทึก" (ผูกกับ อีเวนต์ tab)', [
      FlowCall(
        'bookEventBill',
        note:
            'ONE call (0.4.1-1 E8): the bill (new event or existing), '
            '"คืนแล้ว" paybacks, my tx, "จดหนี้ด้วย"; effects patch the caches',
      ),
    ], today: 'was 3-6 calls (addBills / quickCreate, setTags, debts, paybacks)'),
    FlowStep.action('Button "บันทึก" (ผูกกับ แบ่งกับคน / คนจ่ายแทน tab)', [
      FlowCall(
        'bookEventBill',
        note:
            'ONE call (0.4.1-2 SA7): split: true = a split bill (payer, '
            'shares, "คืนแล้ว", my copy; each member\'s copy by their switch)',
      ),
    ], today: 'was the tx add + one repayment call per "คืนแล้ว" person'),
    FlowStep.action('Button "บันทึกร่าง"', [
      FlowCall('createPending', note: 'saves a draft'),
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
        note: 'no caller since 0.4.1-2 (bookEventBill); retired with V16',
      ),
      FlowCall(
        'updateProjectTransaction',
        note: 'no caller since 0.4.1-2 (rebookEventBill); retired with V16',
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
    FlowStep.action('Row "ติดป้ายจ่ายแล้ว" opened (จ่ายคืน side)', [
      FlowCall('listDebtEntries', note: 'paid=false: the open entries'),
    ]),
    FlowStep.action('Amount / person / chip / arrow changed (debt mode)', [
      FlowCall(
        'createDebtEntry',
        note:
            'record chip: ?preview=true (debounced, nothing saved) → the '
            'result box: before → after + the wallet',
      ),
      FlowCall(
        'createDebtRepayment',
        note: 'settle chip: ?preview=true; flipped → the overpay warning',
      ),
    ]),
    FlowStep.action('Button "บันทึก" (debt mode, จดหนี้)', [
      FlowCall(
        'createDebtEntry',
        note:
            'the debt row (+ its own wallet tx when "มีเงินเข้า/ออกกระเป๋า" is on); returns the balance + wallet balances',
      ),
    ]),
    FlowStep.action('Button "บันทึก" (debt mode, จ่ายคืน)', [
      FlowCall(
        'createDebtRepayment',
        note:
            'ONE transaction tied to the person + paid labels; returns the tx, the balance + wallet balances',
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
  PageFlow('app-start', 'The shared datasets kept on the device.', [
    FlowStep.open([
      FlowCall(
        'postSync',
        note: 'only the datasets whose version moved; none when nothing did',
      ),
    ]),
    FlowStep.action('Back to the app after 5+ minutes', [
      FlowCall('postSync', note: 'every dataset, behind a loading screen'),
    ]),
    FlowStep.action('Pull to refresh (screen or sheet)', [
      FlowCall('postSync', note: 'the datasets that screen reads'),
    ]),
    FlowStep.action('After any write', [
      FlowCall('postSync', note: 'only when the X-Sync-Versions header moved'),
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
        note: 'include=members: wallet + members (this month is on the row)',
      ),
    ]),
    FlowStep.action('Period changed to another month', [
      FlowCall('getAccountSummary', note: 'that month\'s in / out, cached'),
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
    // 0.4.1-2 SA15: one call for every shared-bill notice (created, changed,
    // deleted with my switch off; and the old recorded-for-you rows).
    FlowStep.action('Shared bill: "เพิ่มในสมุด" / "อัปเดตตาม" / "ลบตาม"', [
      FlowCall(
        'applyEventBill',
        note: 'my copy takes the bill as it is now; the rest rides effects',
      ),
    ]),
    FlowStep.action('Event link request: accept', [
      FlowCall('acceptProjectLinkRequest'),
    ]),
    FlowStep.action('Event link request: reject', [
      FlowCall('rejectProjectLinkRequest'),
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
  PageFlow(
    'settings-home',
    'The settings home: groups with a one-line summary (no own call: the '
        'signed-in user carries every value).',
    [
      FlowStep.action('Pull to refresh', [
        FlowCall('getMe', note: 'preferences, switches, notification summary'),
      ]),
    ],
  ),
  PageFlow(
    'settings-app',
    'Theme, theme mode, language, one font per language (shown at once, '
        'saved to the account; login: the server wins, unset keys are filled '
        'from the device).',
    [
      FlowStep.action('Change any value', [
        FlowCall(
          'updateMe',
          note:
              'preferences: theme_id / theme_mode / '
              'language / font_th / font_en, only the changed keys',
        ),
      ]),
    ],
  ),
  PageFlow(
    'settings-money',
    'Currency, money style, main wallet, fee category.',
    [
      FlowStep.action('Change any value', [
        FlowCall(
          'updateMe',
          note: 'currency / preferences / default_account_id',
        ),
      ]),
      FlowStep.action('Wallet picker opened (lazy)', [
        FlowCall('listAccounts'),
      ]),
      FlowStep.action('Category picker opened (lazy)', [
        FlowCall('listCategories'),
      ]),
    ],
  ),
  PageFlow(
    'settings-page-prefs',
    'Remembered sort / filter per list page (also written by the pages).',
    [
      FlowStep.action('Pick a value / a page changes one', [
        FlowCall('updateMe', note: 'preferences.page_prefs {page: {...}}'),
      ]),
      FlowStep.action('คืนค่าเริ่มต้น (one page / all)', [
        FlowCall('updateMe', note: 'page_prefs {page: null} / null'),
      ]),
    ],
  ),
  PageFlow('settings-sync', 'The two auto-sync switches.', [
    FlowStep.action('Flip a switch', [
      FlowCall('updateMe', note: 'auto_sync_events / auto_sync_debts'),
    ]),
  ]),
  PageFlow('settings-notifications', 'On / off per notification type.', [
    FlowStep.open([
      FlowCall('getNotificationSettings', note: 'types in page order'),
    ]),
    FlowStep.action('Flip a switch', [
      FlowCall('updateNotificationSettings', note: 'the whole muted_types'),
    ]),
  ]),
  PageFlow('settings-account', 'Profile, password, deactivate.', [
    FlowStep.open([FlowCall('getMe', note: 'typed preferences')]),
    FlowStep.action('Button "บันทึก"', [FlowCall('updateMe')]),
    FlowStep.action('Change password', [FlowCall('changePassword')]),
    FlowStep.action('Button "ปิดบัญชี"', [FlowCall('deactivateMe')]),
    FlowStep.action('Button "เปิดบัญชีอีกครั้ง"', [FlowCall('reactivateMe')]),
    FlowStep.action('Icon packs opened (lazy)', [FlowCall('listMyPacks')]),
    FlowStep.action('รูปโปรไฟล์ picked / colours 1–3 + border saved', [
      FlowCall('updateMe', note: 'avatar_settings {source, colors, border}'),
    ]),
    FlowStep.action(
      'Button "ลบ" on a linked app'
      's picture',
      [
        FlowCall(
          'deleteAvatarPhoto',
          note: 'DELETE /avatars/{source}; answers my profile',
        ),
      ],
    ),
  ]),
  PageFlow(
    'profile-connections',
    'Profile → การเชื่อมต่อ (0.4.2 1b): one row per outside app (Telegram live; LINE / Google เร็วๆ นี้).',
    [
      FlowStep.open([
        FlowCall(
          'listConnections',
          note:
              'name, logo_url, brand_color, linked, account, photo, permissions',
        ),
      ]),
      FlowStep.action('Each row draws its logo (cached by URL)', [
        FlowCall('getBrandLogo', note: 'public PNG, ?v= in logo_url'),
      ]),
      FlowStep.action('Any person avatar of kind photo (every page)', [
        FlowCall(
          'getAvatarImage',
          note: 'Bearer; cached by photo_url incl. ?v=',
        ),
      ]),
    ],
  ),
  PageFlow(
    'profile-connection',
    'One outside app (0.4.2 1b): link / unlink, permissions, its picture.',
    [
      FlowStep.open([
        FlowCall('getConnection', note: 'also on app resume after linking'),
      ]),
      FlowStep.action('Button "เชื่อม <name>" / "เปลี่ยนบัญชี"', [
        FlowCall(
          'startConnectionLink',
          note: 'url → opened in the outside app',
        ),
      ]),
      FlowStep.action('Button "ยกเลิกการเชื่อม" (confirmed)', [
        FlowCall('unlinkConnection'),
      ]),
      FlowStep.action('Flip a permission switch', [
        FlowCall('updateConnectionPermissions', note: '{key: bool}'),
      ]),
      FlowStep.action('Button "อัปเดต" (the picture)', [
        FlowCall('importConnectionPhoto'),
      ]),
      FlowStep.action('Button "ลบ" (the picture, confirmed)', [
        FlowCall('deleteAvatarPhoto'),
      ]),
    ],
  ),
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
  PageFlow(
    'auth-telegram',
    'เข้าสู่ระบบด้วย Telegram (0.4.2 1b-2, PKCE): log in, or sign up from Telegram.',
    [
      FlowStep.action('Button "เข้าสู่ระบบด้วย Telegram"', [
        FlowCall(
          'startTelegramLogin',
          note: 'code_challenge; url opened in Telegram',
        ),
      ]),
      FlowStep.action('App resumed / "ลองอีกครั้ง" while pending', [
        FlowCall(
          'exchangeTelegramLogin',
          note: '202 pending | login tokens | signup prefill',
        ),
      ]),
      FlowStep.action('Sign-up page: Button "สร้างบัญชี"', [
        FlowCall('signupWithTelegram'),
      ]),
    ],
  ),

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
    // Owner 2026-10-28: bills stay as split bills, so no preview counts.
    FlowStep.action(
      '"ลบอีเวนต์นี้" (edit mode, or the status menu once '
      'completed) → confirm',
      [FlowCall('deleteProject', note: 'event only; effects re-point my rows')],
    ),
    // fe-pages: archive / restore + the event-tag manager sheet.
    FlowStep.action('Button "เก็บถาวร" / "กู้คืน"', [
      FlowCall('archiveProject'),
      FlowCall('restoreProject'),
    ]),
    // 0.4.1-2 V3: completed = locked for good, every book unsynced.
    FlowStep.action('Status "เสร็จสิ้น" → confirm "ปิดอีเวนต์"', [
      FlowCall('completeProject'),
    ]),
    // V15: a removed member's empty spots ("( ) ____").
    FlowStep.action('ต้องจัดการ "ใส่คน" / tap an empty spot on a bill', [
      FlowCall(
        'assignRemovedMember',
        note: 'all their bills, or bill_ids = the tapped bill',
      ),
    ]),
    FlowStep.action('Tag manager: rename / restyle / delete', [
      FlowCall('updateProjectTag'),
      FlowCall('deleteProjectTag'),
    ]),
    FlowStep.action('Button "เชิญสมาชิก"', [FlowCall('addProjectMember')]),
    // 0.4.1-2: no caller any more (ticks are gone, a bill is deleted from
    // the bill form = deleteEventBill); retired with V16.
    FlowStep.action('Tick a bill / split (retired)', [
      FlowCall('markProjectTransaction', note: 'no caller'),
    ]),
    FlowStep.action('Delete a bill (retired)', [
      FlowCall('deleteProjectTransaction', note: 'no caller'),
    ]),
    FlowStep.action('Tag menu "+ เพิ่มเข้าแท็กของฉัน" / "นำเข้าทั้งหมด"', [
      FlowCall('importProjectTags'),
    ]),
    FlowStep.action('Resolve sheet "บันทึกเป็นรายการ"', [
      FlowCall('createTransaction'),
    ]),
    FlowStep.action('Resolve sheet "บันทึกเป็นหนี้"', [
      FlowCall('createDebtEntry'),
    ]),
    FlowStep.action('Tab "สรุป" (who pays whom)', [
      FlowCall('getProjectSettle'),
    ]),
    // 0.4.1-2 V7: "claim ก้อน" on a pair row with me (replaces the old
    // {event_id} debt from the settle line).
    FlowStep.action('สรุป pair row "จดเป็นหนี้" → claim sheet', [
      FlowCall('listClaimableBills', note: '?member_id = the other person'),
    ]),
    // V12: completed events only, once per member.
    FlowStep.action('สรุป "จ่ายน้อยครั้งสุด" → "ลงในสมุดฉัน"', [
      FlowCall(
        'bookEventSettle',
        note: 'my simplified lines (wallet + category each); effects',
      ),
    ]),
    FlowStep.action('Claim sheet "ลงสมุด N บิล"', [
      FlowCall(
        'claimBills',
        note: 'one debt (lump) + my "จ่ายโดย" copies; effects',
      ),
    ]),
    FlowStep.action('Bill sheet: people as event members', [
      FlowCall('resolveProjectPeople'),
    ]),
    // 0.4.1-1 E8: the bill sheet's save is ONE call (bill + paybacks + my
    // book in one DB transaction).
    FlowStep.action('Bill sheet "บันทึก" (new bill / payback)', [
      FlowCall('bookEventBill'),
    ]),
    FlowStep.action('Bill sheet "บันทึก" (edit) / ⤓ "ลงบัญชี"', [
      FlowCall(
        'rebookEventBill',
        note: 'expected_updated_at → 409 BILL_CHANGED carries the newer bill',
      ),
    ]),
    // 0.4.1-2 SA2: an existing bill (event or split) opens from its own
    // answer, from anywhere (tx edit, a debt, a notification, this page).
    FlowStep.action('Bill sheet opened on an existing bill', [
      FlowCall(
        'getEventBill',
        note: 'ONE call: the bill + shares, rights, my copy, version',
      ),
    ]),
    FlowStep.action('Bill sheet "ลบ"', [
      FlowCall(
        'deleteEventBill',
        note: 'one call; the others\' copies follow their switch',
      ),
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
    FlowStep.action('"ผูกกับผู้ติดต่อของฉัน" / "เพิ่มเข้าผู้ติดต่อของฉัน"', [
      FlowCall('bindProjectMemberContact'),
    ]),
    FlowStep.action('"เลิกผูกกับผู้ติดต่อของฉัน"', [
      FlowCall('unbindProjectMemberContact'),
    ]),
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
    FlowStep.action('Button "เพิ่มเป้าหมาย" → "บันทึก"', [
      FlowCall('createSavingGoal'),
      FlowCall('createSavingEntry', note: 'the starting amount, when set'),
    ]),
  ]),
  PageFlow('goals-detail', 'One saving goal and its saving entries.', [
    FlowStep.open([
      FlowCall('getSavingGoal'),
      FlowCall('listRecurring', note: 'its saving rules, from the shared list'),
    ]),
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
      FlowStep.action('ต้องจัดการ: ยืนยัน / จ่ายแล้ว / ข้าม ที่เลือก', [
        FlowCall(
          'settleRecurringOccurrences',
          note: 'action confirm | mark_paid | skip, ≤ 100 rule + slot per call',
        ),
      ]),
    ],
  ),
  PageFlow(
    'recurring-detail',
    'One recurring: what it made and what is next.',
    [
      FlowStep.open([
        FlowCall('getRecurring', note: 'hero + stats + first history page'),
      ]),
      FlowStep.action('Tab "ประวัติ" scroll', [
        FlowCall('listRecurringRuleItems', note: 'tab=produced&page='),
      ]),
      FlowStep.action('Tab "ล่วงหน้า": ดูปีถัดไป / ไปที่เดือน', [
        FlowCall(
          'listRecurringRuleItems',
          note: 'tab=upcoming&from=&months=12 (no end) or page= (with an end)',
        ),
      ]),
      FlowStep.action('Hero: แก้ยอด / ใส่ยอด / เลื่อนวัน', [
        FlowCall('updateRecurringOccurrence', note: '{amount} or {date}'),
      ]),
      FlowStep.action('Hero: ข้าม', [FlowCall('skipRecurringOccurrence')]),
      FlowStep.action('Old BE row (no slot): ข้าม / กู้คืน', [
        FlowCall('archiveRecurringItem'),
        FlowCall('restoreRecurringItem'),
      ]),
      FlowStep.action('Status chip พัก / ทำต่อ', [
        FlowCall('pauseRecurring'),
        FlowCall('resumeRecurring'),
      ]),
      FlowStep.action('Button "ต่ออีก"', [FlowCall('extendRecurring')]),
    ],
  ),
  PageFlow(
    'recurring-occurrence',
    'One occurrence: the quick create sheet (แก้เฉพาะงวดนี้) and the '
        'ต้องจัดการ row buttons. By rule + slot (C3); an old BE row by id.',
    [
      FlowStep.open([
        FlowCall(
          'listRecurringItems',
          note: 'home card: ?month=&status=all&rule_id=, then by slot',
        ),
        FlowCall('getRecurringItem', note: 'a stored row by id'),
      ]),
      FlowStep.action('Button "บันทึก"', [
        FlowCall('updateRecurringOccurrence', note: 'only the changed fields'),
        FlowCall('updateRecurringItem', note: 'old BE, by id'),
      ]),
      FlowStep.action('Button "ยืนยัน"', [
        FlowCall('confirmRecurringOccurrence'),
      ]),
      FlowStep.action('Chip "ข้าม" / "ยกเลิกการข้าม"', [
        FlowCall('skipRecurringOccurrence'),
        FlowCall('restoreRecurringOccurrence'),
      ]),
      FlowStep.action('Chip "จ่ายแล้ว" / "ยกเลิกจ่ายแล้ว"', [
        FlowCall('markRecurringOccurrencePaid'),
        FlowCall('unmarkRecurringOccurrencePaid'),
      ]),
      FlowStep.action('Chip "ผูกกับรายการที่มีอยู่"', [
        FlowCall('listTransactions', note: '±45 days, same type'),
        FlowCall(
          'linkRecurringOccurrence',
          note: 'replace: true after "สลับ?"',
        ),
      ]),
      FlowStep.action('ยืนยัน / จ่ายแล้ว / ข้ามทั้งหมด (one rule)', [
        FlowCall('confirmRecurringOccurrencesReady'),
        FlowCall('markRecurringOccurrencesPaidReady'),
        FlowCall('skipRecurringOccurrencesReady'),
      ]),
      FlowStep.action('Quick create / tx detail: pick the occurrence', [
        FlowCall(
          'listRecurringOccurrences',
          note: '?tx_date=&past=3&upcoming=3 → suggested_slot',
        ),
        FlowCall('unlinkRecurringOccurrence'),
      ]),
    ],
  ),
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
    'One list of people and their net (รอรับ / รอจ่าย together).',
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
      FlowStep.action('บันทึกในรายการ: pick a transaction', [
        FlowCall('linkDebtEntryTx', note: 'saves at once'),
      ]),
      FlowStep.action('บันทึกในรายการ: ✕', [
        FlowCall('unlinkDebtEntryTx', note: 'the transaction stays'),
      ]),
      FlowStep.action('Button "ตัดการเชื่อม" (linked partner, D9)', [
        FlowCall(
          'disconnectDebtPartner',
          note: 'my side only; the other user gets debt_disconnected',
        ),
      ]),
      FlowStep.action('Button "ลบ"', [
        FlowCall(
          'deleteDebtEntry',
          note: 'deletes the wallet tx too; returns balances',
        ),
      ]),
    ],
  ),
];
