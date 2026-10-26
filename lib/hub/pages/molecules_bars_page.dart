import 'package:flutter/material.dart';

import '../../features/accounts/domain/account.dart';
import '../../features/accounts/domain/account_type.dart';
import '../../features/transactions/domain/transaction_type.dart';
import '../../features/accounts/presentation/widgets/wallet_compact_hero.dart';
import '../../features/transactions/presentation/widgets/tx_compact_hero.dart';
import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/molecules/bars` — tab, action, hero, filter and chip bars, and the
/// popover anchors. One playground per widget, then "In the app".
Widget buildBarsPage(BuildContext context) => const _BarsPage();

class _BarsPage extends StatefulWidget {
  const _BarsPage();

  @override
  State<_BarsPage> createState() => _BarsPageState();
}

class _BarsPageState extends State<_BarsPage> {
  final _heroAmount = TextEditingController(text: '1,250');
  final _heroTitle = TextEditingController(text: 'Chicken rice');
  late final _heroStyle = HeroStyle.tinted(
    color: Colors.teal,
    glyph: AppIcons.expense,
  );
  static const _wallet = Account(
    id: 'w',
    name: 'KBank savings',
    type: AccountType.bank,
    balance: 48200,
    currency: 'THB',
  );
  String _pagerTab = 'a';
  late final PageController _pager = PageController();
  bool _saving = false;
  bool _canUndo = true;
  final _heroKey = GlobalKey();

  String _filter = 'all';
  String _sort = 'date';
  String? _single = 'week';
  Set<String> _multi = {'food'};
  Set<int> _swatches = {1};
  final _chipPicked = <String>{'Food'};
  final _chipOrder = ChipOrder();
  final _orderPicked = <String>{'Coffee'};

  @override
  void dispose() {
    _pager.dispose();
    _heroAmount.dispose();
    _heroTitle.dispose();
    super.dispose();
  }

  static const _options = [
    SheetOption(value: 'day', label: 'Day'),
    SheetOption(value: 'week', label: 'Week', subtitle: 'Monday to Sunday'),
    SheetOption(value: 'month', label: 'Month'),
    SheetOption(value: 'year', label: 'Year', enabled: false),
  ];

  static const _multiOptions = [
    SheetOption(value: 'food', label: 'Food'),
    SheetOption(value: 'travel', label: 'Travel'),
    SheetOption(value: 'bills', label: 'Bills'),
  ];

  static const _chipNames = [
    'Food',
    'Travel',
    'Bills',
    'Health',
    'Gifts',
    'Fuel',
    'Coffee',
    'Books',
    'Pets',
    'Gym',
    'Rent',
    'Taxes',
  ];

  Widget _gap() => const SizedBox(height: AppSpacing.md);

  Widget _frame(Widget child) =>
      AppCard(style: AppCardStyle.bordered, child: child);

  Widget _swatchGrid(ColorScheme scheme) => ColorSwatchGrid(
    colors: [
      scheme.primary,
      scheme.secondary,
      scheme.tertiary,
      scheme.error,
      Colors.teal,
      Colors.orange,
    ],
    selected: _swatches,
    clearLabel: 'Clear',
    onToggle: (i) => setState(() {
      _swatches = {..._swatches};
      _swatches.contains(i) ? _swatches.remove(i) : _swatches.add(i);
    }),
    onClear: () => setState(() => _swatches = {}),
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final pagerTabs = [
      const AppTab(value: 'a', label: 'Overview', icon: AppIcons.pie),
      const AppTab(value: 'b', label: 'Entries', icon: AppIcons.receipt),
      const AppTab(
        value: 'c',
        label: 'Past',
        icon: AppIcons.history,
        badgeCount: 12,
      ),
    ];
    final colorChoices = <(String, Color)>[
      ('primary', scheme.primary),
      ('tertiary', scheme.tertiary),
      ('error', scheme.error),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---- In the app ----
        HubDemo(
          title: 'LimitedChipWrap: at most 2 lines, then "+N"',
          note:
              'Chips that don\'t fit in maxLines fold into one "+N" chip (a '
              'budget\'s scope rows). Nothing extra shows when all of them fit. '
              'expandable (view mode): "+N" opens the row and its ⌃ folds it '
              'back; with onMore (edit mode) "+N" opens the picker instead.',
          child: LimitedChipWrap(
            expandable: true,
            chips: [
              for (var i = 1; i <= 12; i++)
                AppChip(
                  label: 'Chip $i',
                  icon: AppIcons.tag,
                  size: ChipSize.chip,
                ),
            ],
          ),
        ),
        HubDemo(
          title: 'OptionMenuAnchor with a custom entry',
          note:
              'custom: OptionMenuCustom ends the menu with an empty input box. '
              'SettingMenuRow turns its value into a field when it is chosen.',
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: OptionMenuAnchor<int>(
              options: [
                SheetOption(value: 80, label: '80%'),
                SheetOption(value: 90, label: '90%'),
              ],
              selected: 80,
              onSelected: (_) {},
              custom: OptionMenuCustom(
                hint: 'Custom',
                suffix: '%',
                onChoose: () {},
              ),
              builder: (context, toggle) => AppButton(
                label: '80%',
                variant: AppButtonVariant.outlined,
                size: AppButtonSize.control,
                trailingIcon: AppIcons.dropdown,
                onPressed: toggle,
              ),
            ),
          ),
        ),
        HubInApp(
          columns: 2,
          note:
              'Every real variant, side by side, each with the page that uses it.',
          uses: [
            HubUse(
              label: 'AppTabBar — two tabs',
              page: 'Categories (expense / income), event resolve, icon maker',
              wide: true,
              child: _frame(
                HubStateful<String>(
                  initial: 'expense',
                  builder: (context, sel, set) => AppTabBar<String>(
                    tabs: const [
                      AppTab(
                        value: 'expense',
                        label: 'Expense',
                        icon: AppIcons.expense,
                      ),
                      AppTab(
                        value: 'income',
                        label: 'Income',
                        icon: AppIcons.income,
                        badgeCount: 3,
                      ),
                    ],
                    selected: sel,
                    onChanged: set,
                  ),
                ),
              ),
            ),
            HubUse(
              label: 'AppTabBar(framed: false) — inside a card',
              page: 'Event สรุป (ยอดสุทธิ / แยกรายคู่)',
              wide: true,
              child: _frame(
                HubStateful<String>(
                  initial: 'net',
                  builder: (context, sel, set) => AppTabBar<String>(
                    framed: false,
                    tabs: const [
                      AppTab(value: 'net', label: 'ยอดสุทธิ'),
                      AppTab(value: 'pairs', label: 'แยกรายคู่'),
                    ],
                    selected: sel,
                    onChanged: set,
                  ),
                ),
              ),
            ),
            HubUse(
              label: 'AppTabBar — three tabs, badge on the last',
              page: 'Quick create (รายการ / หนี้ / ออม)',
              wide: true,
              child: _frame(
                HubStateful<String>(
                  initial: 'a',
                  builder: (context, sel, set) => AppTabBar<String>(
                    tabs: pagerTabs,
                    selected: sel,
                    onChanged: set,
                  ),
                ),
              ),
            ),
            HubUse(
              label: 'AppTabBar + AppTabPager — swipe the bar or the page',
              page: 'Detail pages with tabs, categories',
              wide: true,
              child: _frame(
                Column(
                  children: [
                    AppTabBar<String>(
                      tabs: pagerTabs,
                      selected: _pagerTab,
                      pager: _pager,
                      onChanged: (v) => setState(() => _pagerTab = v),
                    ),
                    SizedBox(
                      height: 110,
                      child: AppTabPager<String>(
                        values: const ['a', 'b', 'c'],
                        selected: _pagerTab,
                        controller: _pager,
                        onChanged: (v) => setState(() => _pagerTab = v),
                        builder: (context, v) => Center(
                          child: Text(
                            'Page "$v" - tap, drag the bar or swipe here',
                            style: text.bodyMedium,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            HubUse(
              label: 'ModeActionBar — cancel / undo / save',
              page: 'Accounts, categories (edit + reorder mode)',
              wide: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    children: [
                      AppChip(
                        label: 'canUndo',
                        selected: _canUndo,
                        onTap: () => setState(() => _canUndo = !_canUndo),
                      ),
                      AppChip(
                        label: 'saving',
                        selected: _saving,
                        onTap: () => setState(() => _saving = !_saving),
                      ),
                    ],
                  ),
                  _frame(
                    ModeActionBar(
                      canSave: true,
                      canUndo: _canUndo,
                      saving: _saving,
                      cancelLabel: 'Cancel',
                      saveLabel: 'Save',
                      undoTooltip: 'Undo',
                      onCancel: () {},
                      onUndo: () {},
                      onSave: () {},
                    ),
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'ModeActionBar — nothing to save yet',
              page: 'Accounts, categories (edit mode, before any change)',
              wide: true,
              child: _frame(
                ModeActionBar(
                  canSave: false,
                  cancelLabel: 'Cancel',
                  saveLabel: 'Save',
                  onCancel: () {},
                  onUndo: () {},
                  onSave: () {},
                ),
              ),
            ),
            HubUse(
              label: 'ModeActionBar — form variant, no undo',
              page: 'Change password',
              wide: true,
              child: _frame(
                ModeActionBar(
                  canSave: true,
                  cancelLabel: 'Cancel',
                  saveLabel: 'Create',
                  onCancel: () {},
                  onSave: () {},
                ),
              ),
            ),
            HubUse(
              label: 'PinnedBar — one full-width button',
              page: 'Pending (batch), quick create sheet',
              wide: true,
              child: _frame(
                PinnedBar(
                  child: AppButton(
                    label: 'Submit',
                    size: AppButtonSize.large,
                    expand: true,
                    onPressed: () {},
                  ),
                ),
              ),
            ),
            HubUse(
              label: 'Hero — transaction (TransactionHeroCard)',
              page: 'Transaction detail, quick create',
              wide: true,
              child: TransactionHeroCard(
                type: TransactionType.expense,
                amount: _heroAmount,
                title: _heroTitle,
                dateLabel: 'Today',
                editing: false,
                inline: true,
                onEdit: () {},
              ),
            ),
            HubUse(
              label: 'Hero — wallet (own surface: wash + glyph, Adjust chip)',
              page: 'Account detail',
              wide: true,
              child: AccountCardSurface(
                account: _wallet,
                margin: EdgeInsets.zero,
                glyphSize: 132,
                child: HeroContent(
                  rows: [
                    HeroTopRow(
                      leading: [
                        AppChip(
                          label: 'Bank',
                          icon: AppIcons.bank,
                          color: scheme.primary,
                          selected: true,
                        ),
                      ],
                      trailing: [
                        AppChip(
                          icon: AppIcons.reset,
                          label: 'Adjust',
                          tone: AppChipTone.primary,
                          selected: true,
                          onTap: () {},
                        ),
                        AppIconButton(
                          icon: AppIcons.edit,
                          size: ControlSizes.of(context).control,
                          onPressed: () {},
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const AccountIconCircle(account: _wallet, size: 52),
                        const SizedBox(width: AppSpacing.md),
                        Flexible(
                          child: Text('KBank savings', style: text.titleMedium),
                        ),
                      ],
                    ),
                    MoneyText(
                      48200,
                      style: text.headlineMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            HubUse(
              label: 'Hero — category (tinted, type colour)',
              page: 'Category detail',
              wide: true,
              child: AppHeroCard(
                style: HeroStyle.tinted(
                  color: scheme.error,
                  glyph: AppIcons.category,
                ),
                header: HeroHeader(
                  leading: const [
                    AppChip(
                      label: 'Expense',
                      icon: AppIcons.expense,
                      tone: AppChipTone.danger,
                      selected: true,
                    ),
                  ],
                  onEdit: () {},
                ),
                content: [
                  HeroIdentity(
                    icon: const IconDisplay(type: IconType.category, size: 52),
                    name: const Text('Food'),
                    fact: const Text('Category'),
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'Hero — contact, linked (the chip sits under the name)',
              page: 'Contact detail',
              wide: true,
              child: AppHeroCard(
                style: HeroStyle.tinted(
                  color: scheme.primary,
                  glyph: AppIcons.contact,
                ),
                header: HeroHeader(leading: const [], onEdit: () {}),
                content: [
                  HeroIdentity(
                    icon: const UserAvatar(displayName: 'Bee', size: 52),
                    name: const Text('Bee'),
                    fact: const Align(
                      alignment: Alignment.centerLeft,
                      child: AppChip(
                        label: 'Linked',
                        icon: AppIcons.link,
                        tone: AppChipTone.success,
                        selected: true,
                        size: ChipSize.chip,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            HubUse(
              label:
                  'Hero — no chips: the top row collapses, edit sits level '
                  'with the title',
              page: 'Contact detail (unlinked contact)',
              wide: true,
              child: AppHeroCard(
                style: HeroStyle.tinted(
                  color: scheme.primary,
                  glyph: AppIcons.contact,
                ),
                header: HeroHeader(leading: const [], onEdit: () {}),
                content: [
                  HeroIdentity(
                    icon: const UserAvatar(displayName: 'Lee', size: 52),
                    name: const Text('Lee'),
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'Hero — top row with no actions, chips wrapping',
              page: 'Entity detail pages in view mode',
              wide: true,
              child: AppHeroCard(
                style: HeroStyle.tinted(
                  color: scheme.primary,
                  glyph: AppIcons.budget,
                ),
                header: HeroHeader(
                  leading: [
                    for (final n in const [
                      'Type',
                      'Category',
                      'Shared',
                      'Recurring',
                      'Linked',
                      'Archived',
                    ])
                      AppChip(label: n, selected: true),
                  ],
                ),
                content: [
                  HeroIdentity(
                    icon: const IconDisplay(type: IconType.category, size: 44),
                    name: const Text('Chips wrap, the row keeps 32'),
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'AppCompactHeroCard — transaction (txCompactHeroBar)',
              page: 'Transaction detail',
              wide: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  txCompactHeroBar(
                    context,
                    type: TransactionType.expense,
                    description: 'Chicken rice',
                    amount: 1250,
                    categoryName: 'Food',
                    onTap: () {},
                  ),
                  _gap(),
                  txCompactHeroBar(
                    context,
                    type: TransactionType.income,
                    description: '',
                    amount: 30000,
                    categoryName: 'Salary',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'AppCompactHeroCard — wallet (walletCompactHero)',
              page: 'Account detail',
              wide: true,
              child: walletCompactHero(context, _wallet, onTap: () {}),
            ),
            HubUse(
              label: 'AppCompactHeroCard — wallet, balance not tracked',
              page: 'Account detail',
              wide: true,
              child: walletCompactHero(
                context,
                _wallet.copyWith(trackBalance: false),
                onTap: () {},
              ),
            ),
            HubUse(
              label: 'AppCompactHeroCard — tinted entity hero',
              page: 'Category / contact / event detail',
              wide: true,
              child: AppCompactHeroCard(
                style: HeroStyle.tinted(
                  color: scheme.error,
                  glyph: AppIcons.category,
                ),
                leading: const IconDisplay(type: IconType.category, size: 28),
                title: const Text('Food'),
                trailing: const AppChip(
                  label: 'Expense',
                  tone: AppChipTone.danger,
                  selected: true,
                  size: ChipSize.chip,
                ),
                onTap: () {},
              ),
            ),
            HubUse(
              label: 'AppCompactHeroCard — plain, long title',
              page: 'Detail pages without an entity colour',
              wide: true,
              child: AppCompactHeroCard(
                leading: IconTile(
                  icon: AppIcons.wallet,
                  color: scheme.primary,
                  size: 28,
                  shape: IconTileShape.rounded,
                  style: IconTileStyle.solid,
                ),
                title: const Text(
                  'A wallet name that is much too long to fit on one line',
                ),
                trailing: Text('48,200.00', style: text.titleSmall),
              ),
            ),
            HubUse(
              label:
                  'CompactHeroScope — bar appears once the hero scrolls away',
              page: 'Every detail page (scroll the box)',
              wide: true,
              child: Container(
                height: 300,
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                clipBehavior: Clip.antiAlias,
                child: CompactHeroScope(
                  heroKey: _heroKey,
                  top: 0,
                  bar: AppCompactHeroCard(
                    style: _heroStyle,
                    leading: const AppChip(label: 'Expense', selected: true),
                    title: const Text('Chicken rice'),
                    trailing: Text('1,250.00', style: text.titleSmall),
                  ),
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    children: [
                      AppCard(
                        key: _heroKey,
                        style: AppCardStyle.accent,
                        color: scheme.primary,
                        child: HeroContent(
                          rows: [
                            HeroTopRow(
                              leading: const [
                                AppChip(label: 'Expense', selected: true),
                              ],
                            ),
                            Text('Chicken rice', style: text.titleLarge),
                            Text('1,250.00', style: text.headlineMedium),
                          ],
                        ),
                      ),
                      SizedBox(height: HeroMetrics.of(context).after),
                      SectionCard(
                        first: true,
                        children: [
                          for (var i = 1; i <= 12; i++)
                            DetailRow(
                              label: 'Row $i',
                              trailing: Text('Value $i'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            HubUse(
              label: 'FilterBar — filter chips + sort chip',
              page: 'Pending, debts, projects, categories, tags, contacts',
              wide: true,
              child: _frame(
                FilterBar(
                  chips: [
                    for (final f in const [
                      ('all', 'All'),
                      ('expense', 'Expense'),
                      ('income', 'Income'),
                      ('transfer', 'Transfer'),
                      ('debt', 'Debts'),
                      ('shared', 'Shared'),
                    ])
                      AppChip(
                        label: f.$2,
                        selected: _filter == f.$1,
                        onTap: () => setState(() => _filter = f.$1),
                      ),
                  ],
                  trailing: AppChip(
                    label: _sort == 'date' ? 'Date' : 'Amount',
                    icon: AppIcons.sort,
                    onTap: () => setState(
                      () => _sort = _sort == 'date' ? 'amount' : 'date',
                    ),
                  ),
                ),
              ),
            ),
            HubUse(
              label: 'ChipRow — icon, scrolling, More',
              page: 'Transaction form (category / tag rows), pick chip rows',
              wide: true,
              child: ChipRow(
                icon: AppIcons.category,
                chips: [
                  for (final n in _chipNames.take(8))
                    AppChip(
                      label: n,
                      selected: _chipPicked.contains(n),
                      onTap: () => setState(() {
                        _chipPicked.contains(n)
                            ? _chipPicked.remove(n)
                            : _chipPicked.add(n);
                      }),
                    ),
                ],
                onMore: () {},
                moreLabel: 'More',
              ),
            ),
            HubUse(
              label: 'FilterBar — no sort chip',
              page: 'Notifications inbox, tags',
              wide: true,
              child: _frame(
                FilterBar(
                  chips: [
                    for (final n in _chipNames.take(5))
                      AppChip(label: n, selected: n == 'Food'),
                  ],
                ),
              ),
            ),
            HubUse(
              label: 'ChipRow — view only, no icon, no More',
              page: 'Transaction form (read-only)',
              child: ChipRow(
                chips: [for (final n in _chipNames.take(3)) AppChip(label: n)],
              ),
            ),
            HubUse(
              label: 'ChipRow — maxLines wrap, cut, More at the end',
              page: 'Transaction filter sheet (type / wallet / category / tag)',
              wide: true,
              child: ChipRow(
                maxLines: 2,
                chips: [for (final n in _chipNames) AppChip(label: n)],
                onMore: () {},
                moreLabel: 'More',
              ),
            ),
            HubUse(
              label: 'ChipRow — moreOnlyWhenCut: everything fits, no More',
              page: 'Transaction filter sheet (wallet / category / tag rows)',
              wide: true,
              child: ChipRow(
                maxLines: 2,
                moreOnlyWhenCut: true,
                chips: [for (final n in _chipNames.take(4)) AppChip(label: n)],
                onMore: () {},
                moreLabel: 'More',
              ),
            ),
            HubUse(
              label: 'ChipRow — moreOnlyWhenCut: cut, so More shows',
              page: 'Transaction filter sheet (wallet / category / tag rows)',
              wide: true,
              child: ChipRow(
                maxLines: 2,
                moreOnlyWhenCut: true,
                chips: [for (final n in _chipNames) AppChip(label: n)],
                onMore: () {},
                moreLabel: 'More',
              ),
            ),
            HubUse(
              label: 'ChipRow — moreFirst, nothing chosen yet',
              page: 'Pending draft form (choose wallet / category)',
              child: ChipRow(
                icon: AppIcons.wallet,
                moreFirst: true,
                chips: const [],
                onMore: () {},
                moreLabel: 'Choose wallet',
              ),
            ),
            HubUse(
              label: 'ChipOrder — the row order freezes once loaded',
              page: 'Transaction form, transaction filter sheet',
              wide: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Tap a chip: it highlights in place and nothing jumps. '
                    'Taxes is picked elsewhere (More): it joins at the end and '
                    'stays.',
                    style: text.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ChipRow(
                    chips: [
                      for (final n in _chipOrder.ids(
                        ready: true,
                        rank: () => _chipNames.take(5).toList(),
                        picked: _orderPicked,
                      ))
                        AppChip(
                          label: n,
                          selected: _orderPicked.contains(n),
                          onTap: () => setState(() {
                            _orderPicked.contains(n)
                                ? _orderPicked.remove(n)
                                : _orderPicked.add(n);
                          }),
                        ),
                    ],
                    onMore: () => setState(() => _orderPicked.add('Taxes')),
                    moreLabel: 'More',
                  ),
                ],
              ),
            ),
            HubUse(
              label: 'SelectableFrame — card / tile picked',
              page: 'Wallet picker sheet, debts, settings (theme tiles)',
              child: Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.md,
                children: [
                  SelectableFrame(
                    selected: false,
                    child: _tile(context, 'Card', AppRadius.lg),
                  ),
                  SelectableFrame(
                    selected: true,
                    child: _tile(context, 'Card', AppRadius.lg),
                  ),
                  SelectableFrame(
                    selected: true,
                    color: scheme.tertiary,
                    gap: 6,
                    child: _tile(context, 'Card', AppRadius.lg),
                  ),
                  SelectableFrame(
                    selected: true,
                    radius: 20,
                    gap: 2,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: scheme.secondary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            HubUse(
              label:
                  'OptionMenuAnchor — single select, subtitle, disabled option',
              page: 'Accounts, tags, projects, debts, transactions list sort',
              child: Align(
                alignment: Alignment.centerLeft,
                child: OptionMenuAnchor<String>(
                  options: _options,
                  selected: _single,
                  onSelected: (v) => setState(() => _single = v),
                  builder: (context, toggle) => AppChip(
                    label: 'Range: ${_single ?? '-'}',
                    trailing: AppChipTrailing.dropdown,
                    onTap: toggle,
                  ),
                ),
              ),
            ),
            HubUse(
              label:
                  'MultiOptionMenuAnchor — multi select (no feature page yet)',
              page: 'Not used by a page yet',
              child: Align(
                alignment: Alignment.centerLeft,
                child: MultiOptionMenuAnchor<String>(
                  options: _multiOptions,
                  selected: _multi,
                  clearLabel: 'Clear',
                  onChanged: (v) => setState(() => _multi = v),
                  builder: (context, toggle) => AppChip(
                    label: _multi.isEmpty
                        ? 'Categories'
                        : 'Categories (${_multi.length})',
                    selected: _multi.isNotEmpty,
                    trailing: AppChipTrailing.dropdown,
                    onTap: toggle,
                  ),
                ),
              ),
            ),
            HubUse(
              label: 'PopoverAnchor — colour swatch grid',
              page: 'Categories, tags (colour filter)',
              child: Align(
                alignment: Alignment.centerLeft,
                child: PopoverAnchor(
                  builder: (context, toggle) => AppChip(
                    label: 'Colours (${_swatches.length})',
                    trailing: AppChipTrailing.dropdown,
                    onTap: toggle,
                  ),
                  contentBuilder: (context, close) => _swatchGrid(scheme),
                ),
              ),
            ),
          ],
        ),
        const HubSubheading(
          'Customize',
          note: 'Fully custom tweaks, one per widget (collapsed).',
        ),
        // ---- AppTabBar ----
        HubPlayground(
          title: 'AppTabBar',
          note:
              'The ONE tab style: a pill track (40 high), equal segments, the '
              'pill slides to a tapped tab (300 ms, cubic .2/.8/.2/1). Drag ON '
              'the bar: the pill follows the finger and snaps to the nearest '
              'tab. Theme primary only. Icons: on every tab with 2–3 tabs, '
              'only on the selected one with 4+. badgeCount > 0 shows a '
              'badge. (With a pager, a content swipe moves the pill too: see '
              '"In the app".)',
          controls: [
            const PlayNum('tabs', min: 2, max: 4, step: 1, initialValue: 2),
            const PlayBool('icons', initialValue: true),
            const PlayBool('badge', initialValue: true),
          ],
          builder: (context, v) {
            const names = ['Expense', 'Income', 'Transfer', 'Debts'];
            const icons = [
              AppIcons.expense,
              AppIcons.income,
              AppIcons.transfer,
              AppIcons.debt,
            ];
            final n = v<double>('tabs').round();
            return HubStateful<int>(
              initial: 0,
              builder: (context, sel, set) => _frame(
                AppTabBar<int>(
                  tabs: [
                    for (var i = 0; i < n; i++)
                      AppTab(
                        value: i,
                        label: names[i],
                        icon: v<bool>('icons') ? icons[i] : null,
                        badgeCount: v<bool>('badge') && i == 1 ? 3 : 0,
                      ),
                  ],
                  selected: sel >= n ? 0 : sel,
                  onChanged: set,
                ),
              ),
            );
          },
        ),
        // ---- ModeActionBar ----
        HubPlayground(
          title: 'ModeActionBar',
          note:
              'Cancel - Undo - Save. Undo exists only with onUndo and scales '
              'in when canUndo; Save disables when canSave is false; saving '
              'shows a spinner and locks Cancel.',
          controls: [
            const PlayBool('canSave', initialValue: true),
            const PlayBool('onUndo', initialValue: true),
            const PlayBool('canUndo', initialValue: true),
            const PlayBool('saving'),
            const PlayText('cancelLabel', initialValue: 'Cancel'),
            const PlayText('saveLabel', initialValue: 'Save'),
          ],
          builder: (context, v) => _frame(
            ModeActionBar(
              canSave: v<bool>('canSave'),
              canUndo: v<bool>('canUndo'),
              saving: v<bool>('saving'),
              cancelLabel: v<String>('cancelLabel'),
              saveLabel: v<String>('saveLabel'),
              undoTooltip: 'Undo',
              onCancel: () {},
              onUndo: v<bool>('onUndo') ? () {} : null,
              onSave: () {},
            ),
          ),
        ),
        // ---- PinnedBar ----
        HubPlayground(
          title: 'PinnedBar',
          note:
              'A bar pinned under a page or sheet: surface fill, a hairline on '
              'top, side padding. bottomGap clears the gesture bar; keyboardGap '
              'applies while the keyboard is open.',
          controls: const [
            PlayNum('bottomGap', min: 0, max: 32, step: 8, initialValue: 16),
            PlayNum('keyboardGap', min: 0, max: 24, step: 4, initialValue: 8),
          ],
          builder: (context, v) => _frame(
            PinnedBar(
              bottomGap: v<double>('bottomGap'),
              keyboardGap: v<double>('keyboardGap'),
              child: AppButton(
                label: 'Submit',
                size: AppButtonSize.large,
                expand: true,
                onPressed: () {},
              ),
            ),
          ),
        ),
        // ---- HeroContent / HeroTopRow ----
        HubPlayground(
          title: 'HeroContent + HeroTopRow',
          note:
              'HeroContent: 16 padding, 12 between rows, null rows skipped. '
              'HeroTopRow: chips wrap on the left, actions on the right, always '
              '32 high (it collapses nothing: with no items it keeps its '
              'height).',
          controls: const [
            PlayNum('chips', min: 0, max: 6, step: 1, initialValue: 2),
            PlayBool('adjustChip'),
            PlayBool('editButton', initialValue: true),
            PlayBool('titleRow', initialValue: true),
            PlayBool('amountRow', initialValue: true),
          ],
          builder: (context, v) {
            const names = ['Type', 'Category', 'Shared', 'Recurring', 'Linked'];
            final n = v<double>('chips').round();
            return AppCard(
              style: AppCardStyle.tinted,
              color: scheme.primary,
              child: HeroContent(
                rows: [
                  HeroTopRow(
                    leading: [
                      for (var i = 0; i < n; i++)
                        AppChip(
                          label:
                              names[i % names.length] + (i >= 5 ? ' $i' : ''),
                          selected: true,
                        ),
                    ],
                    trailing: [
                      if (v<bool>('adjustChip'))
                        AppChip(
                          icon: AppIcons.reset,
                          label: 'Adjust',
                          tone: AppChipTone.primary,
                          selected: true,
                          onTap: () {},
                        ),
                      if (v<bool>('editButton'))
                        AppIconButton(
                          icon: AppIcons.edit,
                          size: ControlSizes.of(context).control,
                          onPressed: () {},
                        ),
                    ],
                  ),
                  if (v<bool>('titleRow')) Text('Food', style: text.titleLarge),
                  if (v<bool>('amountRow'))
                    Text('1,250.00', style: text.headlineMedium),
                ],
              ),
            );
          },
        ),
        // ---- AppCompactHeroCard ----
        HubPlayground(
          title: 'AppCompactHeroCard',
          note:
              'The hero squeezed into one pill. style is the SAME HeroStyle as '
              'the hero it stands in for: plain, or tinted (colour + optional '
              'glyph watermark + strongBorder).',
          controls: [
            PlayChoice<String>('style', [
              ('plain', 'plain'),
              ('tinted', 'tinted'),
            ]),
            PlayChoice<Color>('color', colorChoices),
            const PlayBool('glyph', initialValue: true),
            const PlayBool('strongBorder', initialValue: true),
            const PlayText('title', initialValue: 'Chicken rice'),
            const PlayBool('leading', initialValue: true),
            const PlayBool('trailing', initialValue: true),
            const PlayBool('visible', initialValue: true),
            const PlayBool('onTap', initialValue: true),
          ],
          builder: (context, v) => AppCompactHeroCard(
            style: v<String>('style') == 'plain'
                ? const HeroStyle.plain()
                : HeroStyle.tinted(
                    color: v<Color>('color'),
                    glyph: v<bool>('glyph') ? AppIcons.category : null,
                    strongBorder: v<bool>('strongBorder'),
                  ),
            leading: v<bool>('leading')
                ? const AppChip(label: 'Expense', selected: true)
                : null,
            title: Text(v<String>('title')),
            trailing: v<bool>('trailing')
                ? Text('1,250.00', style: text.titleSmall)
                : null,
            visible: v<bool>('visible'),
            onTap: v<bool>('onTap') ? () {} : null,
          ),
        ),
        // ---- FilterBar ----
        HubPlayground(
          title: 'FilterBar',
          note:
              'A row of filter chips that scrolls sideways, plus an optional '
              'trailing chip (sort) that stays put.',
          controls: const [
            PlayNum('chips', min: 1, max: 10, step: 1, initialValue: 6),
            PlayBool('trailing', initialValue: true),
          ],
          builder: (context, v) => HubStateful<int>(
            initial: 0,
            builder: (context, sel, set) => _frame(
              FilterBar(
                chips: [
                  for (var i = 0; i < v<double>('chips').round(); i++)
                    AppChip(
                      label: _chipNames[i],
                      selected: sel == i,
                      onTap: () => set(i),
                    ),
                ],
                trailing: v<bool>('trailing')
                    ? AppChip(label: 'Date', icon: AppIcons.sort, onTap: () {})
                    : null,
              ),
            ),
          ),
        ),
        // ---- SortChip ----
        HubDemo(
          title: 'SortChip',
          note:
              'A list\'s sort: the current option + ▾; tap opens the central '
              'popover with the current one highlighted (no ✓). In a '
              'AppListToolbar\'s sort slot it follows the toolbar\'s chip '
              'size (28); alone it is a control chip (40).',
          child: HubStateful<String>(
            initial: 'newest',
            builder: (context, sort, set) {
              const options = [
                SortOption('newest', 'ใหม่สุด'),
                SortOption('oldest', 'เก่าสุด'),
                SortOption('amount_desc', 'จำนวนมาก'),
                SortOption('amount_asc', 'จำนวนน้อย'),
              ];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _frame(
                    AppListToolbar(
                      filters: [
                        AppChip(label: 'ฉันจ่าย', onTap: () {}),
                        AppChip(label: 'ค้าง', onTap: () {}),
                      ],
                      sort: SortChip<String>(
                        value: sort,
                        options: options,
                        onChanged: set,
                        tooltip: 'Sort',
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: SortChip<String>(
                      value: sort,
                      options: options,
                      onChanged: set,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        // ---- ChipRow ----
        HubPlayground(
          title: 'ChipRow',
          note:
              'One pick row. maxLines null = one line scrolling sideways; a '
              'number wraps the chips and cuts past that many lines, ending '
              'with the more chip. moreFirst puts a dashed pick chip first '
              '(scroll only, so it forces maxLines null).',
          controls: [
            const PlayBool('icon', initialValue: true),
            const PlayNum('chips', min: 0, max: 12, step: 1, initialValue: 8),
            PlayChoice<int?>('maxLines', [
              ('null', null),
              ('1', 1),
              ('2', 2),
              ('3', 3),
            ]),
            const PlayBool('onMore', initialValue: true),
            const PlayBool('moreFirst'),
            const PlayText('moreLabel', initialValue: 'More'),
          ],
          builder: (context, v) {
            final moreFirst = v<bool>('moreFirst');
            return ChipRow(
              icon: v<bool>('icon') ? AppIcons.category : null,
              chips: [
                for (final n in _chipNames.take(v<double>('chips').round()))
                  AppChip(label: n, selected: n == 'Food'),
              ],
              maxLines: moreFirst ? null : v<int?>('maxLines'),
              moreFirst: moreFirst,
              onMore: v<bool>('onMore') ? () {} : null,
              moreLabel: v<String>('moreLabel'),
            );
          },
        ),
        // ---- SelectableFrame ----
        HubPlayground(
          title: 'SelectableFrame',
          note:
              'The "this one is picked" ring around any card or tile: a primary '
              'outline plus a soft tint.',
          controls: [
            const PlayBool('selected', initialValue: true),
            const PlayNum('radius', min: 0, max: 24, step: 4, initialValue: 16),
            PlayChoice<Color?>('color', [
              ('primary (default)', null),
              ('tertiary', scheme.tertiary),
              ('error', scheme.error),
            ]),
            const PlayNum('gap', min: 0, max: 12, step: 2, initialValue: 3),
          ],
          builder: (context, v) => Align(
            alignment: Alignment.centerLeft,
            child: SelectableFrame(
              selected: v<bool>('selected'),
              radius: v<double>('radius'),
              color: v<Color?>('color'),
              gap: v<double>('gap'),
              child: _tile(context, 'Card', v<double>('radius')),
            ),
          ),
        ),
        // ---- MultiOptionMenuAnchor ----
        HubPlayground(
          title: 'MultiOptionMenuAnchor',
          note:
              'Multi-select popover: stays open while toggling and reports the '
              'whole selection. showClear adds the Clear row once something is '
              'selected.',
          controls: [
            const PlayBool('showClear', initialValue: true),
            const PlayText('clearLabel', initialValue: 'Clear'),
          ],
          builder: (context, v) => HubStateful<Set<String>>(
            initial: {'food'},
            builder: (context, sel, set) => Align(
              alignment: Alignment.centerLeft,
              child: MultiOptionMenuAnchor<String>(
                options: _multiOptions,
                selected: sel,
                showClear: v<bool>('showClear'),
                clearLabel: v<String>('clearLabel'),
                onChanged: set,
                builder: (context, toggle) => AppChip(
                  label: sel.isEmpty
                      ? 'Categories'
                      : 'Categories (${sel.length})',
                  selected: sel.isNotEmpty,
                  trailing: AppChipTrailing.dropdown,
                  onTap: toggle,
                ),
              ),
            ),
          ),
        ),
        // ---- PopoverAnchor ----
        HubPlayground(
          title: 'PopoverAnchor',
          note:
              'A popover with any content (here a colour swatch grid). '
              'maxWidth caps the popover. The content calls close, or the user '
              'taps outside.',
          controls: const [
            PlayNum(
              'maxWidth',
              min: 120,
              max: 400,
              step: 40,
              initialValue: 304,
            ),
          ],
          builder: (context, v) => Align(
            alignment: Alignment.centerLeft,
            child: PopoverAnchor(
              maxWidth: v<double>('maxWidth'),
              builder: (context, toggle) => AppChip(
                label: 'Colours (${_swatches.length})',
                trailing: AppChipTrailing.dropdown,
                onTap: toggle,
              ),
              contentBuilder: (context, close) => _swatchGrid(scheme),
            ),
          ),
        ),
        // ---- Popover title ----
        HubDemo(
          title: 'Popover title — OptionMenuAnchor(title:)',
          note:
              'An optional small muted header at the top of a popover: the '
              'question the options answer (the edit-scope choice "Save '
              'how?", the cycle choice). MultiOptionMenuAnchor and '
              'PopoverAnchor take it too. No title = no change.',
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              HubStateful<String>(
                initial: 'one',
                builder: (context, sel, set) => OptionMenuAnchor<String>(
                  title: 'Save how?',
                  options: const [
                    SheetOption(value: 'one', label: 'This one'),
                    SheetOption(
                      value: 'following',
                      label: 'This and following',
                    ),
                    SheetOption(value: 'past', label: 'All past'),
                    SheetOption(value: 'upcoming', label: 'All upcoming'),
                    SheetOption(value: 'all', label: 'All'),
                  ],
                  selected: sel,
                  onSelected: set,
                  builder: (context, toggle) => AppChip(
                    label: 'Scope: $sel',
                    trailing: AppChipTrailing.dropdown,
                    onTap: toggle,
                  ),
                ),
              ),
              PopoverAnchor(
                title: 'Colour',
                builder: (context, toggle) => AppChip(
                  label: 'Titled colours',
                  trailing: AppChipTrailing.dropdown,
                  onTap: toggle,
                ),
                contentBuilder: (context, close) => _swatchGrid(scheme),
              ),
            ],
          ),
        ),
        // ---- Offline: submits ----
        HubDemo(
          title: 'Offline — ActionBarItem(submits) | SheetOption(submits)',
          note:
              'Actions that send to the server pass submits: true and disable '
              'themselves while the app is offline (ConnectionScope): an '
              'ActionBar button, a popover row, an option-sheet row. Others '
              'stay live. Shown here inside an offline scope: Adjust / '
              'Transfer and Archive / Delete are off, + Entry and Edit work.',
          child: ConnectionScope(
            offline: true,
            reconnects: 0,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ActionBar(
                  actions: [
                    ActionBarItem(
                      label: 'Adjust',
                      icon: AppIcons.edit,
                      submits: true,
                      onPressed: () {},
                    ),
                    ActionBarItem(
                      label: 'Entry',
                      icon: AppIcons.add,
                      primary: true,
                      onPressed: () {},
                    ),
                    ActionBarItem(
                      label: 'Transfer',
                      icon: AppIcons.transfer,
                      submits: true,
                      onPressed: () {},
                    ),
                  ],
                ),
                _gap(),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OptionMenuAnchor<String>(
                    options: const [
                      SheetOption(value: 'edit', label: 'Edit'),
                      SheetOption(
                        value: 'archive',
                        label: 'Archive',
                        submits: true,
                      ),
                      SheetOption(
                        value: 'delete',
                        label: 'Delete',
                        submits: true,
                        destructive: true,
                      ),
                    ],
                    onSelected: (_) {},
                    builder: (context, toggle) => AppChip(
                      label: 'Row options (offline)',
                      icon: AppIcons.more,
                      trailing: AppChipTrailing.dropdown,
                      onTap: toggle,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _tile(BuildContext context, String label, double radius) => Container(
    width: 88,
    height: 56,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(radius),
    ),
    child: Text(label),
  );
}
