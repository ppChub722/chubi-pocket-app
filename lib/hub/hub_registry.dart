import 'package:flutter/material.dart';

import 'pages/atoms_chip_page.dart';
import 'pages/atoms_input_button_page.dart';
import 'pages/atoms_input_page.dart';
import 'pages/tokens_basics_page.dart';
import 'pages/tokens_colors_type_icons_page.dart';
import 'pages/molecules_feedback_page.dart';
import 'pages/organisms_collapsible_section_page.dart';
import 'pages/organisms_sheets_page.dart';
import 'pages/organisms_item_picker_page.dart';
import 'pages/domain_entity_pickers_page.dart';
import 'pages/organisms_states_page.dart';
import 'pages/molecules_pickers_inputs_page.dart';
import 'pages/molecules_blocks_page.dart';
import 'pages/molecules_split_row_page.dart';
import 'debug/env_page.dart';
import 'debug/imports_lab_page.dart';
import 'pages/api_pages.dart';
import 'debug/logs_page.dart';
import 'debug/cache_page.dart';
import 'debug/network_page.dart';
import 'debug/sync_page.dart';
import 'pages/templates_form_sheet_page.dart';
import 'pages/domain_bottom_bar_page.dart';
import 'pages/domain_debts_page.dart';
import 'pages/domain_events_page.dart';
import 'pages/domain_recurring_page.dart';
import 'pages/domain_saving_page.dart';
import 'pages/domain_progress_page.dart';
import 'pages/domain_budgets_page.dart';
import 'pages/domain_money_page.dart';
import 'pages/templates_transaction_detail_page.dart';
import 'pages/domain_transactions_page.dart';
import 'pages/sheets_transactions_page.dart';
import 'pages/atoms_badge_avatar_page.dart';
import 'pages/atoms_card_page.dart';
import 'pages/atoms_switch_check_divider_page.dart';
import 'pages/molecules_bars_page.dart';
import 'pages/molecules_rows_page.dart';
import 'pages/organisms_reorder_charts_page.dart';
import 'pages/organisms_app_hero_card_page.dart';
import 'pages/organisms_hero_card_page.dart';
import 'pages/organisms_section_hero_page.dart';
import 'pages/templates_detail_page.dart';
import 'pages/templates_tabbed_detail_page.dart';
import 'pages/templates_detail_sections_page.dart';
import 'pages/domain_others_page.dart';
import 'pages/domain_people_accounts_page.dart';
import 'pages/templates_auth_page.dart';
import 'pages/templates_dashboard_page.dart';
import 'pages/templates_list_page.dart';
import 'pages/sheets_projects_page.dart';
import 'pages/sheets_accounts_page.dart';
import 'pages/sheets_pickers_page.dart';

/// The app hub — the single source of truth for the UI (owner 2026-10-12).
/// Every piece the app is built from has a page here; every UI change lands
/// here first, the owner reviews it, then the pages adopt it. English only.
///
/// Atomic Design: tokens → atoms → molecules → organisms → templates, then
/// the app's own domain pieces and the debug tools.
enum HubLevel {
  tokens(
    'Tokens',
    'The values everything is built from: spacing, radius, sizes, colours, type, icons.',
  ),
  atoms(
    'Atoms',
    'One job each: a button, a chip, an input, a switch, a divider, an avatar.',
  ),
  molecules(
    'Molecules',
    'A few atoms working together: a detail row, a search bar, a snackbar.',
  ),
  organisms(
    'Organisms',
    'A whole region: a section, a hero, a sheet, an async list state.',
  ),
  templates(
    'Templates',
    'A page skeleton with slots: detail page, list page, form sheet.',
  ),
  domain(
    'Domain',
    'The app’s own pieces: money, people, transactions, accounts, debts.',
  ),
  api(
    'API',
    'Read from the server OpenAPI spec: endpoints, schemas, which page calls what.',
  ),
  labs('Labs', 'Experiments against the real server: slips, chat parse.'),
  debug('Debug', 'Tools for developers: logs, environment, network, cache.');

  const HubLevel(this.title, this.blurb);
  final String title;
  final String blurb;

  /// The portal section this level lives in: ui | api | labs | debug.
  String get sectionName => switch (this) {
    api => 'api',
    labs => 'labs',
    debug => 'debug',
    _ => 'ui',
  };

  bool get isUi => sectionName == 'ui';
}

/// One hub page. [generic] pieces never import features, app models,
/// localisation strings or money colours (they can move to a core library
/// later); [domain] ones may.
class HubPage {
  const HubPage({
    required this.level,
    required this.slug,
    required this.title,
    required this.summary,
    this.generic = true,
    this.covers = const [],
    this.usedBy = '',
    this.phase = 0,
    this.legacyRoute,
    this.builder,
    this.screen,
  });

  final HubLevel level;
  final String slug;
  final String title;

  /// One line: what these pieces are and when to use them.
  final String summary;
  final bool generic;

  /// Public pieces (class / function names exported by `ui.dart`) this page
  /// shows — the coverage test checks every exported piece is on some page.
  final List<String> covers;
  final String usedBy;

  /// The phase that builds this page (0 = live).
  final int phase;

  /// A current screen that already shows (part of) it, until the page is built.
  final String? legacyRoute;
  final WidgetBuilder? builder;

  /// A full screen with its own Scaffold (the debug tools): shown as is,
  /// without the page frame.
  final WidgetBuilder? screen;

  String get id => '${level.name}/$slug';

  /// `/dev/ui/<level>/<slug>` for the UI levels, `/dev/<section>/<slug>` for
  /// api / labs / debug.
  String get path => level.isUi
      ? '/dev/ui/${level.name}/$slug'
      : '/dev/${level.sectionName}/$slug';
  bool get live => builder != null || screen != null;
}

/// Every hub page, in index order. Pages fill in phase by phase.
final List<HubPage> hubPages = [
  // ── Tokens
  const HubPage(
    level: HubLevel.tokens,
    slug: 'spacing',
    title: 'Spacing',
    summary: 'AppSpacing steps and gaps in context.',
    usedBy: '~300 sites',
    covers: ['AppSpacing'],
    builder: buildSpacingPage,
  ),
  const HubPage(
    level: HubLevel.tokens,
    slug: 'radius-duration',
    title: 'Radius & duration',
    summary:
        'Corner radii; motion durations and curves (respect “reduce motion”).',
    usedBy: '~50 sites',
    covers: ['AppRadius', 'AppDurations'],
    builder: buildRadiusDurationPage,
  ),
  const HubPage(
    level: HubLevel.tokens,
    slug: 'sizes',
    title: 'Sizes',
    summary:
        'Chip 20 / 28 / 32, control heights, icon sizes, the 44 tap target.',
    usedBy: 'chips, heroes',
    covers: ['ChipSize', 'AppIconSize'],
    builder: buildSizesPage,
  ),
  const HubPage(
    level: HubLevel.tokens,
    slug: 'colors',
    title: 'Colours',
    summary:
        'Semantic palette per theme and mode, money colours, module colours.',
    generic: false,
    usedBy: 'everything',
    covers: ['AppColors', 'ModuleColors', 'Tone', 'ToneColor'],
    builder: buildColorsPage,
  ),
  const HubPage(
    level: HubLevel.tokens,
    slug: 'typography',
    title: 'Typography',
    summary:
        'The seven roles: display, title, section, label, body, caption, money.',
    usedBy: '53 files',
    covers: ['AppText', 'AppTextRole', 'AppTypography'],
    builder: buildTypographyPage,
  ),
  const HubPage(
    level: HubLevel.tokens,
    slug: 'icons',
    title: 'Icons',
    summary: 'AppIcons — every icon by name.',
    generic: false,
    usedBy: '~150 sites',
    covers: ['AppIcons'],
    builder: buildIconsPage,
  ),
  // ── Atoms
  const HubPage(
    level: HubLevel.atoms,
    slug: 'button',
    title: 'Button',
    summary:
        'Button variants × sizes × states; icon buttons (edit, shell chips, flat close / clear / more / back); edit-mode bar; bulk delete.',
    usedBy: '28 files',
    covers: [
      'AppButton',
      'AppButtonVariant',
      'AppButtonSize',
      'AppIconButton',
      'AppAvatarButton',
      'CountBadge',
      'IconChipActivity',
      'BulkDeleteButton',
    ],
    builder: buildButtonPage,
  ),
  const HubPage(
    level: HubLevel.atoms,
    slug: 'chip',
    title: 'Chip',
    summary: 'The one chip: three sizes, every state, trailing and tone.',
    usedBy: '47 files',
    covers: [
      'AppChip',
      'AppChipTone',
      'AppChipTrailing',
      'ChipSizeScope',
      'StatusChip',
      'StatusKind',
    ],
    builder: buildChipPage,
  ),
  const HubPage(
    level: HubLevel.atoms,
    slug: 'badge-avatar',
    title: 'Badge & avatar',
    summary:
        'Badge, avatars, icon tile, corner badge, editable circle — with the size ladder.',
    usedBy: '40 files',
    covers: [
      'AppBadge',
      'AppAvatar',
      'UserAvatar',
      'IconTile',
      'IconTileShape',
      'IconTileStyle',
      'CornerBadge',
      'EditableCircle',
    ],
    builder: buildBadgeAvatarPage,
  ),
  const HubPage(
    level: HubLevel.atoms,
    slug: 'input',
    title: 'Input',
    summary:
        'One text input: field, inline, title, search; looks filled, outlined, underline, pill, bare.',
    usedBy: '~95 sites',
    covers: [
      'AppInput',
      'AppInputType',
      'AppInputLabelPlacement',
      'AppInputSize',
    ],
    builder: buildInputPage,
  ),
  const HubPage(
    level: HubLevel.atoms,
    slug: 'switch-check-divider',
    title: 'Switch, check & divider',
    summary: 'Switch, select check, dividers, add tile, skeletons, spinner.',
    usedBy: '45 files',
    covers: [
      'AppSwitch',
      'AppDivider',
      'SelectCheck',
      'SelectAllCount',
      'AddTile',
      'AddTileVariant',
      'AppSpinner',
      'AppSpinnerSize',
      'AppIcon',
      'SkeletonBox',
      'SkeletonLine',
      'SkeletonCircle',
      'SkeletonText',
      'SkeletonListTile',
    ],
    builder: buildSwitchCheckDividerPage,
  ),
  const HubPage(
    level: HubLevel.atoms,
    slug: 'card',
    title: 'Card',
    summary: 'Surfaces: plain, bordered, accent, tinted, flat.',
    usedBy: '~38 sites',
    covers: ['AppCard', 'AppCardStyle', 'AppCardPick'],
    builder: buildCardPage,
  ),
  // ── Molecules
  const HubPage(
    level: HubLevel.molecules,
    slug: 'rows',
    title: 'Rows',
    summary:
        'Detail rows, sections (band | grouped), danger row, list row, section header.',
    usedBy: '32+ files',
    covers: [
      'DetailRow',
      'DetailPairRow',
      'DetailPairCell',
      'LinkedFieldHint',
      'HintLine',
      'DetailStacked',
      'DetailLeadingScope',
      'DetailTextField',
      'DetailAddRow',
      'SectionCard',
      'DetailGroupScope',
      'SectionHeader',
      'ListRow',
      'DangerRow',
    ],
    builder: buildRowsPage,
  ),
  const HubPage(
    level: HubLevel.molecules,
    slug: 'pickers-inputs',
    title: 'Pickers & inputs',
    summary:
        'Pick card, select cards, stepper pill (month / week / year presets), month / day grids, amount input, theme mode chips, chat dial.',
    usedBy: '~30 files',
    covers: [
      'PickCard',
      'PickCardEmptyIcon',
      'PickFrame',
      'PickFramePrompt',
      'SelectCardGroup',
      'SelectCardOption',
      'StepperPill',
      'StepperUnit',
      'MonthPickerGrid',
      'showMonthPicker',
      'MonthOfYearGrid',
      'DayOfMonthGrid',
      'showDayOfMonthPicker',
      'dayOfMonthLabel',
      'DayOfMonthPick',
      'AmountInput',
      'AmountQuickFill',
      'ThousandsInputFormatter',
      'RangeInputFormatter',
      'ThemeModeChips',
      'SegmentedChoice',
      'ChoiceSegment',
      'ChatDial',
    ],
    builder: buildPickersInputsPage,
  ),
  const HubPage(
    level: HubLevel.molecules,
    slug: 'blocks',
    title: 'Page blocks',
    summary: 'Select-mode bar, tile grid, pinned tab bar, centred form body.',
    usedBy: 'tags, pending, More, event detail, auth',
    covers: [
      'SelectionToolbar',
      'SelectionAction',
      'ActionBar',
      'TopScrim',
      'ActionBarItem',
      'ChipPath',
      'ChipPathSegment',
      'CardGrid',
      'TileCard',
      'PinnedTabBarDelegate',
      'SegmentedBar',
      'BarSegment',
      'LegendDot',
      'CenteredFormBody',
    ],
    builder: buildBlocksPage,
  ),
  const HubPage(
    level: HubLevel.molecules,
    slug: 'split-row',
    title: 'Split row',
    summary:
        'One row of a bill split: avatar | name | amount | fixed trailing slot; me, typed, contact and linked names; auto and remove actions.',
    usedBy: 'split editor',
    covers: [
      'SplitRow',
      'SplitRowAction',
      'SplitRowName',
      'ShareAmountField',
      'AutoToggleChip',
    ],
    builder: buildSplitRowPage,
  ),
  const HubPage(
    level: HubLevel.molecules,
    slug: 'feedback',
    title: 'Feedback',
    summary:
        'Banner and snackbar (one AppMessage design), dialogs, progress row, empty / error / loading views, the UI config.',
    usedBy: '~80 sites',
    covers: [
      'AppMessage',
      'ConnectionBanner',
      'ConnectionBannerState',
      'ConnectionScope',
      'AppMessageAction',
      'showAppMessage',
      'showAppMessageOn',
      'ProgressRow',
      'showAppSnackBar',
      'showAppSnackBarOn',
      'showErrorSnackBar',
      'showErrorSnackBarOn',
      'showConfirmDialog',
      'showChoiceDialog',
      'DialogChoice',
      'showLinkedPrompt',
      'LinkedChoice',
      'showEditScopeChoice',
      'EditScopeChoice',
      'EditScope',
      'EmptyView',
      'ErrorView',
      'LoadingView',
      'UiConfig',
      'UiStrings',
      'UiErrors',
      'UiErrorInfo',
      'AppUiConfig',
    ],
    builder: buildFeedbackPage,
  ),
  const HubPage(
    level: HubLevel.molecules,
    slug: 'bars',
    title: 'Bars',
    summary:
        'Tab bar, mode action bar, pinned bar, hero shell + compact hero bar, filter bar, chip row, popovers.',
    usedBy: '~25 files',
    covers: [
      'AppTab',
      'AppTabBar',
      'AppTabPager',
      'ModeActionBar',
      'PinnedBar',
      'HeroContent',
      'HeroSpacedRow',
      'HeroTopRow',
      'AppCompactHeroCard',
      'CompactHeroScope',
      'HeroStyle',
      'HeroSurface',
      'FilterBar',
      'ChipRow',
      'ChipOrder',
      'LimitedChipWrap',
      'SelectableFrame',
      'OptionMenuAnchor',
      'OptionMenuCustom',
      'MultiOptionMenuAnchor',
      'PopoverAnchor',
      'PopoverClearItem',
      'PopoverTriggerBuilder',
      'ColorSwatchGrid',
      'IconSwatchGrid',
      'SortChip',
      'SortOption',
    ],
    builder: buildBarsPage,
  ),
  // ── Organisms
  const HubPage(
    level: HubLevel.organisms,
    slug: 'section-hero',
    title: 'Section & hero',
    summary:
        'Hero card (tinted), archive / delete buttons, record info, locked rows, summary stats.',
    usedBy: '32 files',
    covers: [
      'ManageSection',
      'ManageAction',
      'DetailMeta',
      'LockedInEdit',
      'SummaryStats',
      'SummaryStat',
      'IconCodeTint',
      'HeroDescription',
      'HeroNameInput',
      'EditModeScope',
    ],
    builder: buildSectionHeroPage,
  ),
  const HubPage(
    level: HubLevel.organisms,
    slug: 'hero-card',
    title: 'Hero card',
    summary:
        'The 0.4.0 detail hero: rows A–G, edit variant, and the DetailLayout slot order.',
    usedBy: 'every detail page (0.4.0)',
    covers: ['DetailLayout', 'DetailSections', 'DetailRecords'],
    builder: buildHeroCardPage,
  ),
  const HubPage(
    level: HubLevel.organisms,
    slug: 'app-hero-card',
    title: 'App hero card',
    summary:
        'THE hero: header | content | footer, view / edit / create, expanded / folded, and every piece a page builds its hero from.',
    usedBy: 'transactions (list, detail, quick create), wallets (list, detail)',
    covers: [
      'AppHeroCard',
      'AppHeroScope',
      'AppHeroFoldButton',
      'HeroCardMode',
      'HeroHeader',
      'HeroIdentity',
      'HeroCaption',
      'CountMark',
      'HeroNote',
      'HeroNumber',
      'HeroNumberLayout',
      'HeroFields',
      'HeroTiles',
      'SummaryTileView',
      'SummaryTile',
      'SummaryTileTone',
      'DailyBars',
      'DailyBar',
      'DailyBarKind',
      'HeroBar',
      'HeroValueLine',
      'HeroAlert',
      'HeroAmountField',
      'StatusAmountLine',
      'AmountText',
      'MessageShareBox',
      'HeroMetrics',
      'HeroColors',
      'HeroColorScope',
      'HeroRing',
      'HeroRingRow',
      'HeroFactList',
      'HeroFact',
      'HeroInfoBox',
      'HeroFilterChips',
      'HeroFilter',
      'HeroModuleTile',
      'HeroSummaryHead',
      'HeroInsetBox',
      'HeroFlowRow',
      'PointerBubbles',
      'PointerBubble',
      'HeroFlowSelection',
      'HeroStepperHead',
      'HeroChipRow',
      'ControlSizes',
    ],
    builder: buildAppHeroCardPage,
  ),
  const HubPage(
    level: HubLevel.organisms,
    slug: 'sheets',
    title: 'Sheets',
    summary:
        'App sheet, picker sheet, option sheet, action sheet, side sheet, the date picker.',
    usedBy: '~40 files',
    covers: [
      'AppSheetScaffold',
      'showAppSheet',
      'showAppSheetCustom',
      'PickerSheet',
      'PickerRow',
      'PickerConfirmBar',
      'PickerCreateRow',
      'showOptionSheet',
      'SheetOption',
      'SheetAction',
      'ActionSheetHeader',
      'showActionSheet',
      'SideSheetScaffold',
      'SideSheetSection',
      'showSideSheet',
      'showAppDatePicker',
      'AppDatePickerSheet',
      'showAppDateRangePicker',
      'showPeriodPickerSheet',
      'PeriodPickerSheet',
      'PeriodPick',
      'PeriodUnit',
      'PeriodPickerLabels',
      'AppDateRangePickerSheet',
      'MultiDatePickerSheet',
      'showMultiDatePicker',
      'AppDateRangePreset',
      'AppDateResult',
      'AppDatePicked',
      'AppDateCleared',
    ],
    builder: buildSheetsPage,
  ),
  const HubPage(
    level: HubLevel.organisms,
    slug: 'item-picker',
    title: 'Item picker',
    summary:
        'The one picker every entity picker is built on: single / multi, rows / cards / chips, groups, filter tabs, a tree with sub-items, none, create.',
    usedBy: 'entity pickers (moving over)',
    covers: [
      'ItemPickerSheet',
      'showItemPicker',
      'PickerItem',
      'PickerGroup',
      'PickerFilter',
      'PickerNone',
      'PickerCreate',
      'PickerFreeText',
      'PickerAction',
      'PickerResult',
      'PickerData',
      'PickerLayout',
      'PickerCardBuilder',
      'PickerChildren',
      'PickerTree',
      'PickerSelection',
    ],
    builder: buildItemPickerPage,
  ),
  const HubPage(
    level: HubLevel.organisms,
    slug: 'collapsible-section',
    title: 'Collapsible section',
    summary:
        'A section whose heading toggles it: title, hint while open, summary while closed, a mark and an action.',
    usedBy: 'split block, debt history',
    covers: ['CollapsibleSection'],
    builder: buildCollapsibleSectionPage,
  ),
  const HubPage(
    level: HubLevel.organisms,
    slug: 'states',
    title: 'States',
    summary: 'Async state view, pull-to-refresh, saving overlay.',
    usedBy: '~50 files',
    covers: [
      'AsyncStateView',
      'PullToRefresh',
      'PagePopObserver',
      'CoinDropIndicator',
      'SavingOverlay',
      'RefreshRegistry',
      'RefreshScope',
      'SheetRefreshScope',
      'LiveItems',
    ],
    builder: buildStatesPage,
  ),
  const HubPage(
    level: HubLevel.organisms,
    slug: 'reorder-charts',
    title: 'Reorder & charts',
    summary: 'Reorder list, donut, paired bars.',
    usedBy: '6 files',
    covers: [
      'ReorderController',
      'ReorderListScope',
      'ReorderRow',
      'ReorderMoveBar',
      'OutlineItem',
      'DonutChart',
      'DonutSegment',
      'ChartPalette',
      'PairedBarChart',
      'BarPair',
    ],
    builder: buildReorderChartsPage,
  ),
  // ── Templates
  const HubPage(
    level: HubLevel.templates,
    slug: 'detail-page',
    title: 'Detail page',
    summary:
        'View ⇄ edit page skeleton with every slot and the owner’s detail rules.',
    usedBy:
        '7 detail pages (wallet, category, contact, event, budget, goal, scheduled)',
    covers: [
      'DetailPageBody',
      'DetailPlaceholder',
      'DetailPageSkeleton',
      'DetailRowSkeleton',
      'HeroSkeleton',
      'SectionSkeleton',
      'TagsStripSkeleton',
    ],
    builder: buildDetailPageTemplate,
  ),
  const HubPage(
    level: HubLevel.templates,
    slug: 'tabbed-detail',
    title: 'Tabbed detail',
    summary:
        'Hero → below-hero block → pinned tab bar → one lazy ListPageBody per tab; compact hero bar.',
    usedBy: 'Debts person page, events, wallets (adopting)',
    covers: ['TabbedDetailBody', 'PageDots', 'PageDotsScope', 'PageDotsFooter'],
    builder: buildTabbedDetailTemplate,
  ),
  const HubPage(
    level: HubLevel.templates,
    slug: 'detail-sections',
    title: 'Detail sections',
    summary:
        'Info box (one row / auto-stacked), settings, people strip, note, end zone, tag row.',
    usedBy: 'Detail pages (adopting)',
    covers: [
      'InfoBox',
      'InfoRow',
      'SettingsSection',
      'SettingToggleRow',
      'SettingSummaryRow',
      'SettingDropdownRow',
      'SettingMenuRow',
      'SettingMenuCustom',
      'SettingSwitchViewRow',
      'LiveSetting',
      'PeopleStrip',
      'PeopleStripMember',
      'NoteSection',
      'EndZone',
      'EndZoneAction',
      'EndZoneKind',
      'PeopleTone',
      'TagRow',
      'IconChipStrip',
    ],
    builder: buildDetailSectionsPage,
  ),
  const HubPage(
    level: HubLevel.templates,
    slug: 'auth-page',
    title: 'Auth page',
    summary:
        'Sign in + register: brand, banner, framed inputs, primary, social, link, language / theme.',
    usedBy: '2 pages (Login, Register)',
    covers: [
      'AuthPageBody',
      'OrDivider',
      'SocialSignInButton',
      'LanguageThemeBar',
    ],
    builder: buildAuthPageTemplate,
  ),
  const HubPage(
    level: HubLevel.templates,
    slug: 'dashboard',
    title: 'Dashboard',
    summary:
        'Dashboard — home overview: period, KPIs, attention, charts, tiles, lists.',
    usedBy: '1 page (Home) + the Chubi Home example',
    covers: [
      'DashboardPageBody',
      'DashboardPageSkeleton',
      'DashboardSkeletonShape',
    ],
    builder: buildDashboardTemplate,
  ),
  const HubPage(
    level: HubLevel.templates,
    slug: 'list-page',
    title: 'List page',
    summary:
        'Search, filters, grouped list, select + bulk delete, reorder, empty / error / loading.',
    usedBy: '~10 pages',
    covers: [
      'ListPageBody',
      'TabbedListPageBody',
      'ListToolbar',
      'ToolbarToggleState',
      'ToolbarToggleButton',
      'CardActionButton',
      'ListPageSkeleton',
      'ListSkeletonShape',
      'LoadMoreErrorRow',
      'ListRowSkeleton',
      'DayHeaderSkeleton',
      'ListToolbarSkeleton',
    ],
    builder: buildListPageTemplate,
  ),
  const HubPage(
    level: HubLevel.templates,
    slug: 'form-sheet',
    title: 'Form sheet',
    summary:
        'Sheet with fields, save bar, dirty-close guard, saving overlay, retry.',
    usedBy: '~8 sheets',
    covers: ['FormSheet'],
    builder: buildFormSheetPage,
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
  // ── Domain
  const HubPage(
    level: HubLevel.domain,
    slug: 'money',
    title: 'Money',
    summary: 'Money text, money list tile, date group header, currency tile.',
    generic: false,
    usedBy: '28 files',
    covers: [
      'MoneyText',
      'MoneyStyle',
      'MoneySign',
      'MoneyStyleScope',
      'MoneyDecimals',
      'formatMoneyWith',
      'signedMoneyString',
      'MoneyTone',
      'MoneyVisibilityToggle',
      'MoneyListTile',
      'DateGroupHeader',
      'CurrencyTile',
    ],
    builder: buildMoneyPage,
  ),
  const HubPage(
    level: HubLevel.domain,
    slug: 'sheets-transactions',
    title: 'Transaction sheets',
    summary:
        'Quick create frame, filter, description picker, settle: each a presentational organism + a thin feature wrapper.',
    generic: false,
    usedBy: '4 sheets',
    covers: [
      'DescriptionPickerLabels',
      'DescriptionPickerSheet',
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
      'showDescriptionPickerSheet',
      'showSettleSheet',
      'showTxFilterSideSheet',
      'TxFilterPick',
      'TxFilterPicks',
    ],
    builder: buildSheetsTransactionsPage,
  ),
  const HubPage(
    level: HubLevel.domain,
    slug: 'debts',
    title: 'Debts',
    summary:
        'People + balance rows, the net balance (row / hero), the debt hero pieces (amount line, age, net line, message box), the ledger row.',
    generic: false,
    usedBy: 'Debts list, debt person page, quick create debt mode',
    covers: [
      'PersonRow',
      'PersonBalanceRow',
      'NetBalance',
      'debtStateColor',
      'NetBalanceSize',
      'DebtAmountLine',
      'DebtModeChips',
      'DebtResultBox',
      'DebtSentenceAmount',
      'DebtPersonActions',
      'DebtStatementRow',
      'CycleDivider',
      'DebtShareSheet',
      'DebtEntryNote',
      'DebtAgeText',
      'DebtNetLine',
      'DebtSummaryMessageBox',
      'LedgerRow',
      'LedgerDirection',
    ],
    builder: buildDebtsPage,
  ),
  const HubPage(
    level: HubLevel.domain,
    slug: 'recurring',
    title: 'Recurring',
    summary:
        'Item states, the relative due date, a recurrence rule in words + the RecurrenceRule value class.',
    generic: false,
    usedBy: 'Recurring pages, upcoming list, home coming-up',
    covers: [
      'MonthCalendar',
      'CalendarDot',
      'CalendarTile',
      'DateTile',
      'TodayLine',
      'OccurrenceRow',
      'OccurrenceAction',
      'OccurrenceActions',
      'DueCard',
      'DueGroupHeader',
      'DueMoreRow',
      'OccurrenceChain',
      'ChainDot',
      'AmountLineChart',
      'AmountPoint',
      'OccurrenceEdit',
      'OccurrenceFocus',
      'showOccurrenceSheet',
      'showCountSheet',
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
      'AskCard',
    ],
    builder: buildRecurringPage,
  ),
  const HubPage(
    level: HubLevel.domain,
    slug: 'saving',
    title: 'Saving goals',
    summary:
        'Saving goals v2: milestone steps, history chart, goal row, saving-tx row (+ draft), move / withdraw sheet, auto-saving sheet, close-goal dialog, action row.',
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
      'SavingGoalPick',
      'SavingGoalCard',
      'SavingMoveSheet',
      'SavingMoveEnd',
      'SavingSplitRow',
      'SavingMoveSplit',
      'showCloseGoalDialog',
      'CloseGoalDialog',
      'CloseGoalChoice',
      'CloseGoalReturn',
      'SavingGoalRow',
      'ChartSection',
      'showSavingAutoSaveSheet',
      'SavingAutoSaveSheet',
      'SavingAutoSaveWallet',
      'SavingAutoSaveResult',
    ],
    builder: buildDomainSavingPage,
  ),
  const HubPage(
    level: HubLevel.domain,
    slug: 'progress',
    title: 'Progress',
    summary:
        'ProgressRow expected segment, ProgressCard row / compact / skeleton, summary, hero footer, breakdown row, stat grid.',
    generic: false,
    usedBy: 'Budgets, saving goals',
    covers: [
      'ProgressTone',
      'ProgressCard',
      'ProgressRemainder',
      'ProgressBadges',
      'ProgressHeroFooter',
      'ProgressSummary',
      'BreakdownRow',
      'StatGrid',
      'StatTile',
    ],
    builder: buildProgressPage,
  ),
  const HubPage(
    level: HubLevel.domain,
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
      'showPeriodLimitSheet',
      'PeriodLimitResult',
    ],
    builder: buildBudgetsPage,
  ),
  const HubPage(
    level: HubLevel.domain,
    slug: 'events',
    title: 'Events',
    summary:
        'Event list row, board bill row + split lines with the resolve tick, position / share bar row.',
    generic: false,
    usedBy: 'Events list, event detail (summary / bills tabs)',
    covers: [
      'EventCard',
      'EventListRow',
      'EventTagsSheet',
      'EventTagItem',
      'EventTagsLabels',
      'EventTagRef',
      'EventBillRow',
      'EventBillChildRow',
      'EventTagAnchorBuilder',
      'PositionRow',
    ],
    builder: buildEventsPage,
  ),
  const HubPage(
    level: HubLevel.domain,
    slug: 'bottom-bar',
    title: 'Bottom bar & +',
    summary:
        'The shell bar; the centre capsule (icon + word, the mode’s colour) in every quick create mode; the in-page + and empty-state CTA; the sheet’s mode chips.',
    generic: false,
    usedBy: 'The shell (every page), list heads, empty states',
    covers: [
      'QuickCreateButton',
      'QuickCreateHeadButton',
      'QuickCreateCtaButton',
      'quickCreateModeIcon',
      'QuickCreateModeTabs',
      'QuickCreateMode',
      'QuickCreateModeColors',
    ],
    builder: buildBottomBarPage,
  ),
  const HubPage(
    level: HubLevel.domain,
    slug: 'transactions',
    title: 'Transactions',
    summary: 'Tx row, hero, draft form + chip layout, pickers, quick create.',
    generic: false,
    usedBy: '~20 files',
    covers: [
      'TxRow',
      'TransactionHeroCard',
      'txHeroStyle',
      'txTypeChip',
      'txTypeColor',
      'txWordsColor',
      'EntryCard',
      'FlowCards',
      'EntryCardSkeleton',
      'EntryField',
      'SplitEventSection',
      'LinkModeBar',
      'LinkSectionFrame',
      'SplitPickChip',
      'ShareCard',
      'ShareRow',
      'ShareStatus',
      'ShareSubhead',
      'EventPickChip',
      'SplitEventSlot',
      'SplitEventVariant',
      'SplitRecurringSlot',
      'RecurringLinkRow',
      'EventRow',
      'DraftFieldRow',
    ],
    builder: buildTransactionsPage,
  ),
  const HubPage(
    level: HubLevel.domain,
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
      'AccountCard',
      'AccountCardSurface',
      'AccountIconCircle',
      'MemberAvatarStack',
      'MemberChip',
      'OtherMembersStack',
      'SharedWalletIconBadge',
      'accountBalanceColor',
      'accountDisplayBalance',
      'accountHeroStyle',
      'accountTypeLabel',
      'WalletPickCard',
    ],
    builder: buildPeopleAccountsPage,
  ),
  const HubPage(
    level: HubLevel.domain,
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
    level: HubLevel.domain,
    slug: 'sheets-accounts',
    title: 'Wallet sheets',
    summary:
        'Adjust balance and identifier kind sheets as presentational organisms (plain params in, plain result out), and the bank mark.',
    generic: false,
    usedBy: 'Wallet detail, wallet edit, wallet numbers',
    covers: [
      'showAdjustBalanceFormSheet',
      'AdjustBalanceSheet',
      'AdjustBalanceStrings',
      'AdjustBalanceSheetResult',
      'BankPickerItem',
      'BankPickerChoice',
      'BankBrandMark',
      'showIdentifierKindSelectSheet',
      'PickBank',
      'IdentifierKindOption',
      'IdentifierKindChoice',
      'IdentifierKindStrings',
    ],
    builder: buildSheetsAccountsPage,
  ),
  const HubPage(
    level: HubLevel.domain,
    slug: 'entity-pickers',
    title: 'Entity pickers',
    summary:
        'Each entity picker as the pages will open it (on the item picker), on the real caches, next to the sheet it replaces.',
    generic: false,
    usedBy: 'every entity picker (pages not moved yet)',
    covers: [],
    builder: buildEntityPickersPage,
  ),
  const HubPage(
    level: HubLevel.domain,
    slug: 'pickers',
    title: 'New tag name',
    summary: 'The new-tag name sheet the tag picker opens to create a tag.',
    generic: false,
    usedBy: 'tag picker (create)',
    covers: ['showNewTagNameSheet'],
    builder: buildSheetsPickersPage,
  ),
  const HubPage(
    level: HubLevel.domain,
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
  // ── API (read from GET /api/v1/openapi.json)
  const HubPage(
    level: HubLevel.api,
    slug: 'pages',
    title: 'Pages',
    summary:
        'Page → trigger (on open / a button) → endpoints, each expandable with request, responses and examples; the coverage counter; endpoints no page uses.',
    generic: false,
    builder: buildApiPagesPage,
  ),
  const HubPage(
    level: HubLevel.api,
    slug: 'schemas',
    title: 'Schemas',
    summary: 'The shared component schemas: fields, types, required, examples.',
    generic: false,
    builder: buildApiSchemasPage,
  ),
  // ── Debug
  HubPage(
    level: HubLevel.debug,
    slug: 'logs',
    title: 'Logs',
    summary: 'Live log tail, level filter, search, copy.',
    generic: false,
    screen: (_) => const LogsViewerScreen(),
  ),
  HubPage(
    level: HubLevel.labs,
    slug: 'imports',
    title: 'Imports lab',
    summary: 'Real slips (QR + OCR), parse-text, the slip flow.',
    generic: false,
    screen: (_) => const ImportsLabScreen(),
  ),
  HubPage(
    level: HubLevel.debug,
    slug: 'env',
    title: 'Environment',
    summary: 'API base URL, build mode, platform, app version and build.',
    generic: false,
    screen: (_) => const EnvInfoScreen(),
  ),
  HubPage(
    level: HubLevel.debug,
    slug: 'network',
    title: 'Network',
    summary:
        'The last API calls: path, status, time, size, the page and whether opening or an action started it; a per-endpoint summary.',
    generic: false,
    screen: (_) => const NetworkPage(),
  ),
  HubPage(
    level: HubLevel.debug,
    slug: 'cache',
    title: 'Cache',
    summary:
        'What the app holds in memory: each store with its status and item count; reload or clear one.',
    generic: false,
    screen: (_) => const CachePage(),
  ),
  HubPage(
    level: HubLevel.debug,
    slug: 'sync',
    title: 'Sync',
    summary:
        'Each shared dataset: the version the app holds against the one the server reports, the page-data versions and the last 50 sync rounds; sync now or clear the saved copy.',
    generic: false,
    screen: (_) => const SyncPage(),
  ),
];

HubPage? hubPageFor(String level, String slug) {
  for (final p in hubPages) {
    if (p.level.name == level && p.slug == slug) return p;
  }
  return null;
}
