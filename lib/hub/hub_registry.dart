import 'package:flutter/material.dart';
import 'package:pp_forge/hub.dart';

import 'api/page_flows.dart';
import 'debug/cache_page.dart';
import 'debug/env_page.dart';
import 'debug/imports_lab_page.dart';
import 'debug/logs_page.dart';
import 'debug/network_page.dart';
import 'pages/api_pages.dart';
import 'pages/domain_bars_page.dart';
import 'pages/domain_bottom_bar_page.dart';
import 'pages/domain_budgets_page.dart';
import 'pages/domain_debts_page.dart';
import 'pages/domain_events_page.dart';
import 'pages/domain_money_page.dart';
import 'pages/domain_multi_pickers_page.dart';
import 'pages/domain_others_page.dart';
import 'pages/domain_people_accounts_page.dart';
import 'pages/domain_progress_page.dart';
import 'pages/domain_recurring_page.dart';
import 'pages/domain_saving_page.dart';
import 'pages/domain_transactions_page.dart';
import 'pages/sheets_accounts_page.dart';
import 'pages/sheets_people_page.dart';
import 'pages/sheets_pickers_page.dart';
import 'pages/sheets_projects_page.dart';
import 'pages/sheets_transactions_page.dart';
import 'pages/templates_transaction_detail_page.dart';

/// chubiPocket's portal, on ppForge's hub (owner 2026-10-17): ppForge's kit
/// pages ([ppForgeHubPages]) first, then the app's own — its domain pieces,
/// the API views, the labs and the debug tools.
abstract final class AppHubLevels {
  static const domain = HubLevel(
    'domain',
    'Domain',
    'The app’s own pieces: money, people, transactions, accounts, debts.',
    icon: Icons.apps_outlined,
  );
  static const api = HubLevel(
    'api',
    'API',
    'Read from the server OpenAPI spec: endpoints, schemas, which page calls what.',
    icon: Icons.api_outlined,
    section: 'api',
  );
  static const labs = HubLevel(
    'labs',
    'Labs',
    'Experiments against the real server: slips, chat parse.',
    icon: Icons.science_outlined,
    section: 'labs',
  );
  static const debug = HubLevel(
    'debug',
    'Debug',
    'Tools for developers: logs, environment, network, cache.',
    icon: Icons.bug_report_outlined,
    section: 'debug',
  );
}

/// The whole portal: what `/dev` lists and the router resolves.
final hubCatalog = HubCatalog(
  sections: [
    HubSection.ui(extraLevels: [AppHubLevels.domain]),
    HubSection(
      'api',
      'API',
      'What each page calls and when, the shared schemas, spec coverage.',
      icon: Icons.api_outlined,
      levels: [AppHubLevels.api],
      countLabel: (pages) =>
          '${pages.length} views · ${pageFlows.length} app pages',
    ),
    HubSection(
      'labs',
      'Labs',
      'Experiments against the real server: slips, chat parse.',
      icon: Icons.science_outlined,
      levels: [AppHubLevels.labs],
    ),
    HubSection(
      'debug',
      'Debug',
      'Logs, environment, the network calls and the in-memory cache.',
      icon: Icons.bug_report_outlined,
      levels: [AppHubLevels.debug],
    ),
  ],
  pages: [...ppForgeHubPages, ...appHubPages],
);

/// Every portal page — ppForge's and the app's.
List<HubPage> get hubPages => hubCatalog.pages;

/// The app's own pages.
final List<HubPage> appHubPages = [
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'bars',
    title: 'Heroes & compact bars',
    summary:
        'The wallet / transaction heroes and compact hero bars, built on '
        'ppForge HeroShell and CompactHeroBar.',
    generic: false,
    usedBy: 'Transaction detail, account detail',
    builder: buildDomainBarsPage,
  ),
  const HubPage(
    level: HubLevel.templates,
    slug: 'transaction-detail',
    title: 'Transaction detail',
    summary: 'The transaction page (exempt from the detail standard).',
    generic: false,
    usedBy: '1 page',
    covers: [],
    builder: buildTransactionDetailPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'money',
    title: 'Money',
    summary: 'Money text, money list tile, date group header, currency tile.',
    generic: false,
    usedBy: '28 files',
    covers: [
      'MoneyText',
      'MoneyTone',
      'MoneyVisibilityToggle',
      'MoneyListTile',
      'DateGroupHeader',
      'CurrencyTile',
    ],
    builder: buildMoneyPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'sheets-transactions',
    title: 'Transaction sheets',
    summary:
        'Quick create frame, filter, event target, wallet picker, description picker, settle: each a presentational organism + a thin feature wrapper.',
    generic: false,
    usedBy: '6 sheets',
    covers: [
      'AccountPick',
      'AccountPickNone',
      'AccountPickWallet',
      'AccountPickerLabels',
      'AccountPickerSheet',
      'DescriptionPickerLabels',
      'DescriptionPickerSheet',
      'EventPickExisting',
      'EventPickNew',
      'EventPickRemove',
      'EventTargetItem',
      'EventTargetPick',
      'EventTargetSheet',
      'EventTargetSheetLabels',
      'QuickCreateSheetShell',
      'SettleResult',
      'SettleSheet',
      'SettleSheetData',
      'SettleSheetLabels',
      'SettleWalletField',
      'TxFilterOption',
      'TxFilterOptions',
      'TxFilterSelection',
      'TxFilterSheet',
      'TxFilterSheetLabels',
      'WalletPickItem',
      'showAccountPickSheet',
      'showDescriptionPickerSheet',
      'showEventTargetPickSheet',
      'showSettleSheet',
      'showTxFilterSideSheet',
    ],
    builder: buildSheetsTransactionsPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'debts',
    title: 'Debts',
    summary:
        'People + balance rows, the net balance (row / hero), the debts summary card, the ledger row.',
    generic: false,
    usedBy: 'Debts list, debt person page, quick create debt mode',
    covers: [
      'PersonRow',
      'PersonBalanceRow',
      'NetBalance',
      'NetBalanceSize',
      'DebtSummaryCard',
      'LedgerRow',
      'LedgerDirection',
    ],
    builder: buildDebtsPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'recurring',
    title: 'Recurring',
    summary:
        'Item states, the relative due date, a recurrence rule in words + the RecurrenceRule value class.',
    generic: false,
    usedBy: 'Recurring pages, upcoming list, home coming-up',
    covers: [
      'OccurrenceState',
      'OccurrenceStateChip',
      'DueText',
      'dueLabel',
      'RecurrenceText',
      'recurrenceLabel',
      'RecurrenceEditor',
      'showRecurrenceSheet',
      'RecurrenceRule',
      'RecurrenceFreq',
      'RecurrenceMonthly',
      'RecurrenceMonthlyMode',
      'RecurrenceEnd',
      'RecurrenceEndKind',
    ],
    builder: buildRecurringPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'multi-pickers',
    title: 'Multi pickers',
    summary:
        'Multi-select pickers: category tree with a per-row include-subcategories switch, and a wallet list.',
    generic: false,
    usedBy: 'Budget scope (categories / wallets)',
    covers: [
      'CategoryMultiPick',
      'CategoryMultiPickerLabels',
      'showCategoryMultiPicker',
      'CategoryMultiPickerSheet',
      'AccountMultiPickItem',
      'AccountMultiPickerLabels',
      'showAccountMultiPicker',
      'AccountMultiPickerSheet',
    ],
    builder: buildDomainMultiPickersPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'saving',
    title: 'Saving goals',
    summary:
        'Saving goals v2: milestone steps, history chart, saving-tx row (+ draft), move / withdraw sheet, close-goal dialog, action row.',
    generic: false,
    usedBy: 'Saving goals list / detail, wallet page, pending list',
    covers: [
      'MilestoneRow',
      'MilestoneStep',
      'MilestoneState',
      'SavingHistoryChart',
      'SavingChartGeometry',
      'SavingTxRow',
      'SavingTxKind',
      'showSavingMoveSheet',
      'SavingMoveSheet',
      'SavingMoveEnd',
      'SavingSplitRow',
      'SavingMoveSplit',
      'showCloseGoalDialog',
      'CloseGoalDialog',
      'CloseGoalChoice',
      'CloseGoalReturn',
    ],
    builder: buildDomainSavingPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'progress',
    title: 'Progress',
    summary:
        'ProgressRow expected segment, ProgressCard row / compact / skeleton, summary, hero footer, breakdown row, stat grid.',
    generic: false,
    usedBy: 'Budgets, saving goals',
    covers: [
      'ProgressTone',
      'ProgressCard',
      'ProgressHeroFooter',
      'ProgressSummary',
      'BreakdownRow',
      'StatGrid',
      'StatTile',
    ],
    builder: buildProgressPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'budgets',
    title: 'Budgets',
    summary:
        'Source chips, scope prompt, simple period editor, DetailRow error, wallet value chip, card-list gap.',
    generic: false,
    usedBy: 'Budget list and detail',
    covers: [
      'SourceChip',
      'SourceChips',
      'SourceChipItem',
      'showScopePrompt',
      'walletValueChip',
    ],
    builder: buildBudgetsPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'events',
    title: 'Events',
    summary:
        'Event list row, board bill row + split lines with the resolve tick, position / share bar row.',
    generic: false,
    usedBy: 'Events list, event detail (summary / bills tabs)',
    covers: [
      'EventCard',
      'EventTagRef',
      'EventBillRow',
      'EventBillChildRow',
      'EventTagAnchorBuilder',
      'PositionRow',
    ],
    builder: buildEventsPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'bottom-bar',
    title: 'Bottom bar & +',
    summary:
        'The shell bar; the centre + in every quick create mode (its colour = the mode); the sheet’s mode chips.',
    generic: false,
    usedBy: 'The shell (every page)',
    covers: [
      'QuickCreateButton',
      'QuickCreateModeChips',
      'QuickCreateMode',
      'QuickCreateModeColors',
    ],
    builder: buildBottomBarPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'transactions',
    title: 'Transactions',
    summary: 'Tx row, hero, draft form + chip layout, pickers, quick create.',
    generic: false,
    usedBy: '~20 files',
    covers: [
      'TxRow',
      'TxHeroCard',
      'txHeroStyle',
      'txTypeChip',
      'txTypeColor',
      'EntryCard',
      'EntryCardSkeleton',
      'EntryField',
      'SplitEventSection',
      'SplitEventSlot',
      'SplitEventVariant',
      'EventRow',
      'DraftFieldRow',
    ],
    builder: buildTransactionsPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'people-accounts',
    title: 'People & accounts',
    summary:
        'Person mark, member strip, account card, wallet pick card, avatars.',
    generic: false,
    usedBy: '~15 files',
    covers: [
      'PersonMark',
      'PersonLevel',
      'PersonLinkBadge',
      'PersonRef',
      'AvatarStack',
      'MemberStrip',
      'UserProfilePreview',
    ],
    builder: buildPeopleAccountsPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'sheets-projects',
    title: 'Sheets: events',
    summary:
        'Resolve a board row into my book (tabs, share only, account / category chips) and invite a member; live with sample data.',
    generic: false,
    usedBy: '2 sheets',
    covers: [
      'EventResolveSheet',
      'EventResolveMode',
      'showEventResolveSheet',
      'EventResolveLabels',
      'EventResolveResult',
      'ResolvePickValue',
      'ResolvePickResult',
      'AddMemberSheet',
      'showAddMemberFormSheet',
      'AddMemberLabels',
      'AddMemberFill',
    ],
    builder: buildSheetsProjectsPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'sheets-accounts',
    title: 'Wallet sheets',
    summary:
        'Adjust balance, bank picker, identifier kind and wallet invite sheets as presentational organisms (plain params in, plain result out).',
    generic: false,
    usedBy: 'Wallet detail, wallet edit, wallet members',
    covers: [
      'showAdjustBalanceFormSheet',
      'AdjustBalanceSheet',
      'AdjustBalanceStrings',
      'AdjustBalanceSheetResult',
      'showBankSelectSheet',
      'BankPickerItem',
      'BankPickerChoice',
      'BankPickerStrings',
      'BankBrandMark',
      'showIdentifierKindSelectSheet',
      'IdentifierKindOption',
      'IdentifierKindChoice',
      'IdentifierKindStrings',
      'showWalletInviteSelectSheet',
      'WalletInviteSheet',
      'WalletInviteCandidate',
      'WalletInviteStrings',
    ],
    builder: buildSheetsAccountsPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'pickers',
    title: 'Category & tag pickers',
    summary: 'Category-tree and tag picker sheets (presentational organisms).',
    generic: false,
    usedBy: 'quick-create, category parent, tx filters',
    covers: [
      'showCategoryPicker',
      'CategoryPickerSheet',
      'CategoryPickerRow',
      'CategoryPickerLabels',
      'CategoryPickerChoice',
      'CategoryPickerNone',
      'CategoryPickerPicked',
      'showTagPicker',
      'TagPickerSheet',
      'TagPickerItem',
      'TagPickerData',
      'TagPickerLabels',
      'showNewTagNameSheet',
    ],
    builder: buildSheetsPickersPage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'sheets-people',
    title: 'People sheets',
    summary:
        'Contact picker and wire-names sheets: rows and words in, result out.',
    generic: false,
    usedBy: 'Split editor, contact detail',
    covers: [
      'ContactPickerSheet',
      'showContactPicker',
      'ContactPickerRow',
      'ContactPickerLabels',
      'ContactPickerSheetData',
      'ContactPickerOutcome',
      'ContactPickerRowPicked',
      'ContactPickerNameTyped',
      'WireNamesSheet',
      'showWireNamesSheet',
      'WireNameRow',
      'WireNamesLabels',
    ],
    builder: buildSheetsPeoplePage,
  ),
  const HubPage(
    level: AppHubLevels.domain,
    slug: 'others',
    title: 'Others',
    summary:
        'Debt tile, notification tile, project tiles, brand logo, auth header.',
    generic: false,
    usedBy: '~10 files',
    covers: [
      'BrandLogo',
      'BrandHeader',
      'BankBrand',
      'OfflineBanner',
      'ProjectMemberAvatar',
      'ProjectMemberPickCard',
      'NotificationTileView',
      'NotificationRejectConfirm',
    ],
    builder: buildOthersPage,
  ),
  const HubPage(
    level: AppHubLevels.api,
    slug: 'pages',
    icon: Icons.account_tree_outlined,
    title: 'Pages',
    summary:
        'Page → trigger (on open / a button) → endpoints, each expandable with request, responses and examples; the coverage counter; endpoints no page uses.',
    generic: false,
    builder: buildApiPagesPage,
  ),
  const HubPage(
    level: AppHubLevels.api,
    slug: 'schemas',
    icon: Icons.data_object,
    title: 'Schemas',
    summary: 'The shared component schemas: fields, types, required, examples.',
    generic: false,
    builder: buildApiSchemasPage,
  ),
  HubPage(
    level: AppHubLevels.debug,
    slug: 'logs',
    icon: Icons.receipt_long_outlined,
    title: 'Logs',
    summary: 'Live log tail, level filter, search, copy.',
    generic: false,
    screen: (_) => const LogsViewerScreen(),
  ),
  HubPage(
    level: AppHubLevels.labs,
    slug: 'imports',
    icon: Icons.document_scanner_outlined,
    title: 'Imports lab',
    summary: 'Real slips (QR + OCR), parse-text, the slip flow.',
    generic: false,
    screen: (_) => const ImportsLabScreen(),
  ),
  HubPage(
    level: AppHubLevels.debug,
    slug: 'env',
    icon: Icons.info_outline,
    title: 'Environment',
    summary: 'API base URL, build mode, platform, app version and build.',
    generic: false,
    screen: (_) => const EnvInfoScreen(),
  ),
  HubPage(
    level: AppHubLevels.debug,
    slug: 'network',
    icon: Icons.swap_vert,
    title: 'Network',
    summary:
        'The last API calls: path, status, time, size, the page and whether opening or an action started it; a per-endpoint summary.',
    generic: false,
    screen: (_) => const NetworkPage(),
  ),
  HubPage(
    level: AppHubLevels.debug,
    slug: 'cache',
    icon: Icons.memory_outlined,
    title: 'Cache',
    summary:
        'What the app holds in memory: each store with its status and item count; reload or clear one.',
    generic: false,
    screen: (_) => const CachePage(),
  ),
];
