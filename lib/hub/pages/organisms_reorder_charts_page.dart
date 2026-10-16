import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_playground.dart';

/// `/dev/organisms/reorder-charts` — the reorder kit, DonutChart and
/// PairedBarChart. Real examples first, the playgrounds last.
Widget buildReorderChartsPage(BuildContext context) =>
    const _ReorderChartsPage();

class _ReorderChartsPage extends StatelessWidget {
  const _ReorderChartsPage();

  static const _values = [6200.0, 3100.0, 2400.0, 1800.0, 6880.0];
  static const _months = [
    BarPair(label: 'May', a: 30000, b: 21000),
    BarPair(label: 'Jun', a: 30000, b: 26500),
    BarPair(label: 'Jul', a: 32000, b: 18000),
    BarPair(label: 'Aug', a: 30000, b: 31200),
    BarPair(label: 'Sep', a: 30000, b: 24000),
    BarPair(label: 'Oct', a: 32000, b: 18580),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = ChartPalette.categorical(context);
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    final text = Theme.of(context).textTheme;
    List<DonutSegment> segments(int n) => [
      for (var i = 0; i < n; i++)
        DonutSegment(
          value: _values[i],
          color: i < colors.length ? colors[i] : ChartPalette.other(context),
        ),
    ];
    Widget bars(List<BarPair> groups, {int? selected, double height = 96}) =>
        PairedBarChart(
          groups: groups,
          colorA: palette.income,
          colorB: palette.expense,
          height: height,
          selected: selected,
        );
    Widget center(String t) => Text(t, style: text.labelLarge);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubInApp(
          columns: 2,
          note:
              'DonutChart — the real shapes, side by side. Slice colours come '
              'from ChartPalette; colour is never the only cue.',
          uses: [
            HubUse(
              label: '5 slices, total in the centre (the 5th is "other")',
              page: 'Home (expense by category)',
              child: Center(
                child: DonutChart(
                  size: 112,
                  segments: segments(5),
                  center: center('Total'),
                ),
              ),
            ),
            HubUse(
              label: '3 slices — no folded "other"',
              page: 'Home (a quiet month)',
              child: Center(
                child: DonutChart(
                  size: 112,
                  segments: segments(3),
                  center: center('Total'),
                ),
              ),
            ),
            HubUse(
              label: '1 slice — one category fills the ring',
              page: 'Home (single category)',
              child: Center(
                child: DonutChart(
                  size: 112,
                  segments: segments(1),
                  center: center('Total'),
                ),
              ),
            ),
            HubUse(
              label: 'no data — the empty track',
              page: 'Home (empty month)',
              child: Center(
                child: DonutChart(
                  size: 112,
                  segments: const [],
                  center: center('฿0'),
                ),
              ),
            ),
            HubUse(
              label: 'thick ring, no centre',
              page: 'Option (thickness 24)',
              child: Center(
                child: DonutChart(
                  size: 112,
                  thickness: 24,
                  segments: segments(4),
                ),
              ),
            ),
            HubUse(
              label: 'small (80) — a tile',
              page: 'Option (size 80)',
              child: Center(
                child: DonutChart(
                  size: 80,
                  thickness: 10,
                  segments: segments(4),
                  center: center('4'),
                ),
              ),
            ),
            HubUse(
              wide: true,
              label: 'default size, total in the centre, legend beside it',
              page: 'Home (expense by category)',
              child: Row(
                children: [
                  DonutChart(segments: segments(5), center: center('Total')),
                  const SizedBox(width: PpForgeSpacing.lg),
                  Expanded(
                    child: Text(
                      'Legend + amounts sit next to it; colour is never the '
                      'only cue.',
                      style: text.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            HubUse(
              wide: true,
              label: 'ChartPalette — categorical (4) + the grey "other"',
              page: 'Every chart',
              child: Wrap(
                spacing: PpForgeSpacing.sm,
                runSpacing: PpForgeSpacing.sm,
                children: [
                  for (final c in [...colors, ChartPalette.other(context)])
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(PpForgeRadius.sm),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        HubInApp(
          columns: 2,
          note:
              'PairedBarChart — income vs expense per month; selected keeps '
              'one group at full strength.',
          uses: [
            HubUse(
              wide: true,
              label: 'tappable months, one selected (onSelect)',
              page: 'Home (income vs expense by month)',
              child: _BarsDemo(months: _months),
            ),
            HubUse(
              wide: true,
              label: 'height 80, last month selected',
              page: 'Home (compact)',
              child: bars(_months, selected: 5, height: 80),
            ),
            HubUse(
              label: 'display only, none selected',
              page: 'Option (selected null)',
              child: bars(_months.take(3).toList()),
            ),
            HubUse(
              label: 'first group selected',
              page: 'Option (selected 0)',
              child: bars(_months.take(3).toList(), selected: 0),
            ),
            HubUse(
              label: 'a single month',
              page: 'Home (new account)',
              child: bars([_months.last], selected: 0),
            ),
            HubUse(
              label: 'tall (160)',
              page: 'Option (height 160)',
              child: bars(_months.take(3).toList(), selected: 1, height: 160),
            ),
          ],
        ),
        const HubInApp(
          note:
              'The reorder kit (ReorderController). Drag the handle; tap a row '
              'for the move bar; long-press a collapsed parent while dragging '
              'to expand it.',
          uses: [
            HubUse(
              wide: true,
              label: 'a 3-level tree, or a flat list in two sections',
              page: 'Categories, Accounts (reorder mode)',
              child: _ReorderDemo(),
            ),
          ],
        ),
        HubPlayground(
          title: 'DonutChart',
          note:
              'Proportion donut with a centre widget. segments = the slice '
              'count (0 = the empty track); size / thickness / center are the '
              'real options. Slice colours come from ChartPalette.',
          controls: [
            const PlayNum(
              'size',
              min: 80,
              max: 200,
              step: 20,
              initialValue: 120,
            ),
            const PlayNum(
              'thickness',
              min: 6,
              max: 32,
              step: 2,
              initialValue: 14,
            ),
            const PlayNum('segments', min: 0, max: 5, initialValue: 5),
            const PlayBool('center', initialValue: true),
          ],
          builder: (context, v) => Center(
            child: DonutChart(
              size: v<double>('size'),
              thickness: v<double>('thickness'),
              segments: segments(v<double>('segments').round()),
              center: v<bool>('center') ? const Text('Total') : null,
            ),
          ),
        ),
        HubPlayground(
          title: 'PairedBarChart',
          note:
              'Two bars per group (income vs expense per month). height is '
              'the plot height; selected keeps one group full strength and '
              'fades the rest (none = all full). onSelect null = display '
              'only, as here.',
          controls: [
            const PlayNum(
              'height',
              min: 48,
              max: 200,
              step: 8,
              initialValue: 96,
            ),
            PlayChoice<int?>('selected', [
              ('none', null),
              for (var i = 0; i < _months.length; i++) (_months[i].label, i),
            ], initial: 5),
          ],
          builder: (context, v) => PairedBarChart(
            groups: _months,
            colorA: palette.income,
            colorB: palette.expense,
            height: v<double>('height'),
            selected: v<int?>('selected'),
          ),
        ),
      ],
    );
  }
}

// ─── Reorder ──────────────────────────────────────────────────────────

const _names = {
  'food': 'Food',
  'rice': 'Rice',
  'noodle': 'Noodles',
  'snack': 'Snacks',
  'cake': 'Cake',
  'drink': 'Drinks',
  'coffee': 'Coffee',
  'travel': 'Travel',
  'bts': 'BTS',
  'taxi': 'Taxi',
  'bills': 'Bills',
  'cash': 'Cash',
  'kbank': 'KBank',
  'card': 'Credit card',
  'trip': 'Japan trip',
  'home': 'Home',
};

List<OutlineItem> _tree() => const [
  OutlineItem('food', 1),
  OutlineItem('rice', 2),
  OutlineItem('noodle', 2),
  OutlineItem('snack', 2),
  OutlineItem('cake', 3),
  OutlineItem('drink', 1),
  OutlineItem('coffee', 2),
  OutlineItem('travel', 1),
  OutlineItem('bts', 2),
  OutlineItem('taxi', 2),
  OutlineItem('bills', 1),
];

List<OutlineItem> _flat() => const [
  OutlineItem('cash', 1, section: 'mine'),
  OutlineItem('kbank', 1, section: 'mine'),
  OutlineItem('card', 1, section: 'mine'),
  OutlineItem('trip', 1, section: 'shared'),
  OutlineItem('home', 1, section: 'shared'),
];

class _ReorderDemo extends StatefulWidget {
  const _ReorderDemo();

  @override
  State<_ReorderDemo> createState() => _ReorderDemoState();
}

class _ReorderDemoState extends State<_ReorderDemo> {
  bool _flatMode = false;
  final _scroll = ScrollController();
  final Set<String> _collapsed = {'travel'};
  late ReorderController _c = _make();

  ReorderController _make() => ReorderController(
    items: _flatMode ? _flat() : _tree(),
    maxDepth: _flatMode ? 1 : 3,
    collapsed: _collapsed,
  )..addListener(_changed);

  void _changed() => setState(() {});

  void _reset() {
    final old = _c;
    setState(() => _c = _make());
    WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
  }

  @override
  void dispose() {
    _c.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: PpForgeSpacing.sm,
          runSpacing: PpForgeSpacing.sm,
          children: [
            PpForgeChip(
              label: '3-level tree',
              selected: !_flatMode,
              onTap: () {
                _flatMode = false;
                _reset();
              },
            ),
            PpForgeChip(
              label: 'Flat, 2 sections',
              selected: _flatMode,
              onTap: () {
                _flatMode = true;
                _reset();
              },
            ),
          ],
        ),
        const SizedBox(height: PpForgeSpacing.md),
        SizedBox(
          height: 520,
          child: Column(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(PpForgeSpacing.md),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(PpForgeSpacing.md),
                    child: ReorderListScope(
                      controller: _c,
                      scrollController: _scroll,
                      dropLabel: _flatMode
                          ? null
                          : (id) => id == null
                                ? 'Top level'
                                : 'Under ${_names[id]}',
                      child: ListView(
                        controller: _scroll,
                        padding: const EdgeInsets.only(
                          bottom: PpForgeSpacing.lg,
                        ),
                        children: _flatMode ? _flatRows() : _treeRows(),
                      ),
                    ),
                  ),
                ),
              ),
              ReorderMoveBar(controller: _c),
              ModeActionBar(
                canUndo: _c.canUndo,
                canSave: _c.dirty,
                cancelLabel: 'Reset',
                saveLabel: _c.dirty ? 'Changed' : 'No changes',
                undoTooltip: 'Undo',
                onCancel: _reset,
                onUndo: _c.undo,
                onSave: _reset,
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<Widget> _treeRows() => [
    for (final (i, item) in _c.visible().indexed) ...[
      if (i > 0) const PpForgeDivider.row(),
      ReorderRow(
        key: ValueKey(item.id),
        id: item.id,
        child: ListRow(
          indent: (item.level - 1) * PpForgeSpacing.xxl,
          leading: CircleAvatar(
            radius: 20,
            child: Text(_names[item.id]!.characters.first),
          ),
          title: _names[item.id]!,
          subtitle: 'Level ${item.level}',
          trailing: _c.hasChildren(item.id)
              ? IconButton(
                  visualDensity: VisualDensity.compact,
                  icon: Icon(
                    _c.isCollapsed(item.id)
                        ? PpForgeIcons.expand
                        : PpForgeIcons.collapse,
                  ),
                  onPressed: () => _c.toggleCollapsed(item.id),
                )
              : null,
        ),
      ),
    ],
  ];

  List<Widget> _flatRows() => [
    for (final (title, section) in [
      ('Mine', 'mine'),
      ('Shared wallets', 'shared'),
    ]) ...[
      SectionHeader(
        title: title,
        count: _c.visible(section: section).length,
      ),
      for (final item in _c.visible(section: section))
        ReorderRow(
          key: ValueKey(item.id),
          id: item.id,
          child: ListRow(
            leading: const CircleAvatar(
              radius: 20,
              child: Icon(PpForgeIcons.wallet),
            ),
            title: _names[item.id]!,
          ),
        ),
    ],
  ];
}

// ─── Charts ───────────────────────────────────────────────────────────

class _BarsDemo extends StatefulWidget {
  const _BarsDemo({required this.months});

  final List<BarPair> months;

  @override
  State<_BarsDemo> createState() => _BarsDemoState();
}

class _BarsDemoState extends State<_BarsDemo> {
  int? _selected = 5;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<PpForgeColors>()!;
    return PairedBarChart(
      groups: widget.months,
      colorA: palette.income,
      colorB: palette.expense,
      selected: _selected,
      onSelect: (i) => setState(() => _selected = i),
    );
  }
}
