import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_playground.dart';

/// `/dev/ui/molecules/list-header` — AppListHeader (the head of a group of
/// rows) and AppListToolbar (search, filters, sort; opened by 🔍).
Widget buildListHeaderPage(BuildContext context) => const _ListHeaderPage();

class _ListHeaderPage extends StatefulWidget {
  const _ListHeaderPage();

  @override
  State<_ListHeaderPage> createState() => _ListHeaderPageState();
}

enum _Status { all, waiting, paid }

enum _Sort { date, amount, name }

class _ListHeaderPageState extends State<_ListHeaderPage> {
  final _monthTools = AppListToolbarState.local();
  final _allTools = AppListToolbarState.local();
  final _playTools = AppListToolbarState.local(open: true);
  final _search = TextEditingController();
  _Status _status = _Status.all;
  String? _kind;
  _Sort _sort = _Sort.date;
  bool _dayPicked = true;

  @override
  void dispose() {
    _monthTools.dispose();
    _allTools.dispose();
    _playTools.dispose();
    _search.dispose();
    super.dispose();
  }

  String _statusLabel(_Status s) => switch (s) {
    _Status.all => 'ทุกสถานะ',
    _Status.waiting => 'รอจัดการ',
    _Status.paid => 'จ่ายแล้ว',
  };

  SortChip<_Sort> _sortChip() => SortChip<_Sort>(
    value: _sort,
    tooltip: 'Sort',
    options: const [
      SortOption(_Sort.date, 'วันที่'),
      SortOption(_Sort.amount, 'ยอด'),
      SortOption(_Sort.name, 'ชื่อ'),
    ],
    onChanged: (s) => setState(() => _sort = s),
  );

  List<ListHeaderAction> _filters() => [
    ListHeaderAction.filter<_Status>(
      label: _statusLabel(_status),
      value: _status,
      active: _status != _Status.all,
      options: [
        for (final s in _Status.values)
          SheetOption(value: s, label: _statusLabel(s)),
      ],
      onSelected: (s) => setState(() => _status = s),
    ),
    ListHeaderAction.filter<String?>(
      label: _kind ?? 'ทุกประเภท',
      value: _kind,
      active: _kind != null,
      options: const [
        SheetOption(value: null, label: 'ทุกประเภท'),
        SheetOption(value: 'ค่าสมาชิก', label: 'ค่าสมาชิก'),
        SheetOption(value: 'ผ่อนชำระ', label: 'ผ่อนชำระ'),
      ],
      onSelected: (k) => setState(() => _kind = k),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    final scheme = Theme.of(context).colorScheme;
    Widget row(String title, num amount, Color color) => AppListRow(
      leading: IconTile(icon: AppIcons.category, color: color),
      title: title,
      trailing: ListRowTrailing.value(
        MoneyText(amount, tone: MoneyTone.signed),
      ),
      onTap: () {},
    );
    Widget card(List<Widget> rows) => AppCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Column(
          children: [
            for (final (i, r) in rows.indexed) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: scheme.outlineVariant),
              r,
            ],
          ],
        ),
      ),
    );
    Widget group(List<Widget> children) => ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubPlayground(
          title: 'AppListHeader',
          note:
              'Title 14 w600, "| count" muted, the same on every list. The '
              'value ends over the rows\' amounts (16 in); actions end at the '
              'edge. Over a card of rows (cardedRows) the title moves to a '
              'card title\'s inset. Knows no domain: money comes in through '
              'ListHeaderTrailing.value.',
          controls: [
            const PlayText('title', initialValue: 'ค่าสมาชิก'),
            const PlayBool('count', initialValue: true),
            const PlayBool('leading'),
            const PlayBool('onClearTitle'),
            PlayChoice<String>('trailing', const [
              ('value', 'value'),
              ('value + prefix', 'prefix'),
              ('text', 'text'),
              ('off', 'off'),
            ]),
            PlayChoice<String>('actions', const [
              ('off', 'off'),
              ('toolbar', 'toolbar'),
              ('toolbar + button', 'button'),
              ('link', 'link'),
              ('filters + toolbar', 'filters'),
            ]),
          ],
          builder: (context, v) => group([
            AppListHeader(
              title: v<String>('title'),
              count: v<bool>('count') ? 7 : null,
              leading: v<bool>('leading')
                  ? AppIcon(
                      AppIcons.recurring,
                      size: AppIconSize.md,
                      color: scheme.onSurfaceVariant,
                    )
                  : null,
              onClearTitle: v<bool>('onClearTitle') ? () {} : null,
              trailing: switch (v<String>('trailing')) {
                'value' => const ListHeaderTrailing.value(
                  MoneyText(-1149, tone: MoneyTone.signed),
                ),
                'prefix' => const ListHeaderTrailing.value(
                  MoneyText(2400, tone: MoneyTone.income),
                  prefix: 'รวม',
                ),
                'text' => const ListHeaderTrailing.text(
                  '฿5,635.17/เดือน | ฿67,622/ปี',
                ),
                _ => null,
              },
              actions: switch (v<String>('actions')) {
                'toolbar' => [
                  ListHeaderAction.toolbar(_playTools, tooltip: 'Search'),
                ],
                'button' => [
                  ListHeaderAction.toolbar(_playTools, tooltip: 'Search'),
                  ListHeaderAction.button(
                    AppIcons.add,
                    tooltip: 'Add',
                    onTap: () {},
                  ),
                ],
                'link' => [ListHeaderAction.link('ดูทั้งหมด', onTap: () {})],
                'filters' => [
                  ..._filters(),
                  ListHeaderAction.toolbar(_playTools, tooltip: 'Search'),
                ],
                _ => const [],
              },
            ),
            card([
              row('Netflix', -419, palette.info),
              row('Spotify', -129, palette.success),
            ]),
          ]),
        ),
        HubPlayground(
          title: 'AppListToolbar',
          note:
              'Search box, then filter chips with the sort at the end. With '
              'a state it opens and closes from the 🔍 (AppListToolbarToggle '
              '/ ListHeaderAction.toolbar); without one it stays open '
              '(categories, tags, contacts).',
          controls: [
            const PlayBool('state', initialValue: true),
            const PlayBool('search', initialValue: true),
            const PlayBool('filters', initialValue: true),
            const PlayBool('sort', initialValue: true),
          ],
          builder: (context, v) => group([
            if (v<bool>('state'))
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: AppListToolbarToggle(
                    state: _playTools,
                    filtered: _search.text.isNotEmpty,
                    tooltip: 'Search',
                  ),
                ),
              ),
            AppListToolbar(
              state: v<bool>('state') ? _playTools : null,
              search: v<bool>('search')
                  ? ListToolbarSearch(
                      controller: _search,
                      hint: 'ค้นหาคำอธิบาย | โน้ต | หมวด',
                      onChanged: (_) => setState(() {}),
                    )
                  : null,
              filters: v<bool>('filters')
                  ? [
                      AppChip(
                        label: 'ตัวกรอง',
                        icon: AppIcons.sort,
                        onTap: () {},
                      ),
                    ]
                  : const [],
              sort: v<bool>('sort') ? _sortChip() : null,
            ),
          ]),
        ),
        HubInApp(
          note:
              'Today\'s headers and toolbars redrawn with the new pieces, '
              'before any page moves over. Data is made up.',
          uses: [
            HubUse(
              label: 'Day header: total over the rows\' amounts',
              page:
                  'Transactions, budget, pending, saving history (DateGroupHeader)',
              child: group([
                const AppListHeader(
                  title: 'เมื่อวาน',
                  trailing: ListHeaderTrailing.value(
                    MoneyText(149650, tone: MoneyTone.signed),
                  ),
                ),
                card([
                  row('ยอดยกมา', 150000, palette.success),
                  row('Grab Food', -350, palette.warning),
                ]),
              ]),
            ),
            HubUse(
              label: 'Kind section: count + totals as text',
              page: 'Recurring · all (SectionHeader)',
              child: group([
                const AppListHeader(
                  title: 'ค่าสมาชิก',
                  count: 7,
                  trailing: ListHeaderTrailing.text(
                    '฿5,635.17/เดือน | ฿67,622/ปี',
                  ),
                ),
                card([row('Netflix', -419, palette.info)]),
              ]),
            ),
            HubUse(
              label: 'Leading icon, "รวม" + total in the side\'s colour',
              page: 'Debts (SectionHeader)',
              child: group([
                AppListHeader(
                  leading: AppIcon(
                    AppIcons.debt,
                    size: AppIconSize.md,
                    color: palette.income,
                  ),
                  title: 'คนอื่นติดเรา',
                  count: 2,
                  trailing: const ListHeaderTrailing.value(
                    MoneyText(3300, tone: MoneyTone.income),
                    prefix: 'รวม',
                  ),
                ),
                card([row('ฝน', 900, palette.income)]),
              ]),
            ),
            HubUse(
              label: 'Leading icon, count, "ดูทั้งหมด ›"',
              page: 'Home · recent (SectionHeader)',
              child: group([
                AppListHeader(
                  leading: AppIcon(
                    AppIcons.transactions,
                    size: AppIconSize.md,
                    color: scheme.onSurfaceVariant,
                  ),
                  title: 'รายการล่าสุด',
                  count: 5,
                  actions: [ListHeaderAction.link('ดูทั้งหมด', onTap: () {})],
                ),
                card([row('Grab Food', -350, palette.warning)]),
              ]),
            ),
            HubUse(
              label: '🔍 + ＋ at the end; the toolbar opens under it',
              page: 'Recurring · all',
              child: group([
                AppListHeader(
                  title: 'รายการประจำทั้งหมด',
                  actions: [
                    ListHeaderAction.toolbar(_allTools, tooltip: 'Search'),
                    ListHeaderAction.button(
                      AppIcons.add,
                      tooltip: 'Add',
                      onTap: () {},
                    ),
                  ],
                ),
                AppListToolbar(
                  state: _allTools,
                  search: ListToolbarSearch(
                    controller: _search,
                    hint: 'ค้นหารายการประจำ',
                  ),
                ),
                card([row('Netflix', -419, palette.info)]),
              ]),
            ),
            HubUse(
              label:
                  'Filters next to 🔍 work at once; search + sort open under '
                  '🔍; a picked day is a ✕ chip that goes back to the month',
              page: 'Recurring · calendar list',
              child: group([
                AppListHeader(
                  title: _dayPicked ? 'วันนี้' : 'ตุลาคม 2026',
                  count: _dayPicked ? 1 : 26,
                  onClearTitle: _dayPicked
                      ? () => setState(() => _dayPicked = false)
                      : null,
                  actions: [
                    ..._filters(),
                    ListHeaderAction.toolbar(
                      _monthTools,
                      tooltip: 'Search',
                      filtered: _sort != _Sort.date,
                    ),
                  ],
                ),
                AppListToolbar(
                  state: _monthTools,
                  search: ListToolbarSearch(
                    controller: _search,
                    hint: 'ค้นหารายการประจำ',
                  ),
                  sort: _sortChip(),
                ),
                card([row('ค่าไฟ', -1305, palette.warning)]),
                if (!_dayPicked)
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    child: AppButton(
                      label: 'Pick a day again (demo)',
                      variant: AppButtonVariant.text,
                      onPressed: () => setState(() => _dayPicked = true),
                    ),
                  ),
              ]),
            ),
            HubUse(
              label: 'No state: search + chips + sort always open',
              page: 'Categories, tags, contacts (ListToolbar)',
              child: group([
                AppListToolbar(
                  search: ListToolbarSearch(
                    controller: _search,
                    hint: 'ค้นหาหมวด',
                  ),
                  filters: [
                    AppChip(label: 'รายจ่าย', selected: true, onTap: () {}),
                  ],
                  sort: _sortChip(),
                ),
                card([row('Dining', -540, palette.warning)]),
              ]),
            ),
          ],
        ),
      ],
    );
  }
}
