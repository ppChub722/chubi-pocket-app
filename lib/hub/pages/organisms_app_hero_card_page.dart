import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/organisms/app-hero-card` — THE hero card: header · content ·
/// footer, three modes, expanded / folded versions, and every hub piece a
/// page builds its hero from. Stand-in data only (no domain): this page moves
/// to the package as it is.
Widget buildAppHeroCardPage(BuildContext context) => const _AppHeroCardPage();

class _AppHeroCardPage extends StatefulWidget {
  const _AppHeroCardPage();

  @override
  State<_AppHeroCardPage> createState() => _AppHeroCardPageState();
}

enum _Versions { content, folded, both }

class _AppHeroCardPageState extends State<_AppHeroCardPage> {
  final _open = ValueNotifier(true);
  final _listOpen = ValueNotifier(true);
  final _name = TextEditingController(text: 'Groceries');
  final _desc = TextEditingController(text: 'Fresh food and drinks');
  final _what = TextEditingController(text: 'Lunch with the team');
  final _amount = TextEditingController(text: '1,250');

  @override
  void dispose() {
    _open.dispose();
    _listOpen.dispose();
    _name.dispose();
    _desc.dispose();
    _what.dispose();
    _amount.dispose();
    super.dispose();
  }

  Color get _red => Theme.of(context).extension<AppColors>()!.expense;
  Color get _green => Theme.of(context).extension<AppColors>()!.income;
  Color get _amber => Theme.of(context).extension<AppColors>()!.warning;

  Widget _circle(IconData icon, Color color, {double size = 40}) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    child: Icon(icon, size: size * 0.55, color: Colors.white),
  );

  Widget _muted(String s) => Text(
    s,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );

  List<Widget> _tiles({bool selectable = false}) => [
    SummaryTileView(
      tile: SummaryTile(
        label: 'Income',
        value: '12,400',
        tone: SummaryTileTone.green,
        selected: selectable,
        onTap: () {},
      ),
    ),
    SummaryTileView(
      tile: SummaryTile(
        label: 'Expense',
        value: '8,210',
        tone: SummaryTileTone.red,
        onTap: () {},
      ),
    ),
    const SummaryTileView(
      tile: SummaryTile(label: 'Transfer', value: '1,000'),
    ),
  ];

  /// The playground's card: every part optional, every mode, every version.
  Widget _play(PlayValues v) {
    final mode = v<HeroCardMode>('mode');
    final versions = v<_Versions>('versions');
    final editing = mode != HeroCardMode.view;
    final long = v<bool>('long text');
    final name = long
        ? 'A very long name that needs more than one line to fit'
        : 'Groceries';
    final content = <Widget?>[
      HeroIdentity(
        icon: _circle(AppIcons.category, _red),
        name: editing
            ? AppInput.title(editing: true, controller: _name)
            : Text(name),
        description: editing
            ? AppInput.card(controller: _desc, underline: true)
            : _muted('Fresh food and drinks'),
      ),
      if (editing)
        HeroAmountField(
          controller: _amount,
          label: 'Budget',
          accent: _red,
          symbol: '฿',
        )
      else
        HeroNumber(
          label: 'Spent',
          value: const Text('฿5,100'),
          color: _red,
          target: '/ ฿8,000 | 64%',
        ),
      if (!editing) HeroBar(value: 0.64, color: _red, left: '12 days left'),
      if (!editing && v<bool>('alert'))
        const HeroAlert(text: 'Over the pace by ฿600'),
    ];
    final folded = <Widget?>[
      HeroNumber(
        label: 'Spent',
        value: const Text('฿5,100'),
        color: _red,
        layout: HeroNumberLayout.inline,
        small: true,
      ),
    ];
    return AppHeroCard(
      style: HeroStyle.tinted(color: _red, glyph: AppIcons.category),
      mode: mode,
      header: v<bool>('header')
          ? HeroHeader(
              leading: [
                AppChip(
                  label: 'Monthly',
                  icon: AppIcons.scheduled,
                  selected: true,
                  tone: AppChipTone.neutral,
                  onTap: editing ? () {} : null,
                  dashed: editing,
                ),
              ],
              actions: [AppIconButton(icon: AppIcons.search, onPressed: () {})],
              onEdit: () {},
            )
          : null,
      content: versions == _Versions.folded ? null : content,
      folded: versions == _Versions.content ? null : folded,
      open: versions == _Versions.both ? _open : null,
      footer: [
        if (v<bool>('footer') && !editing) HeroTiles(children: _tiles()),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubPlayground(
          title: 'AppHeroCard',
          note:
              'header | content | footer. The card adds ✏️ (view only) and '
              '⌄ / ⌃ (both versions) to the header itself; spacing comes '
              'from HeroMetrics in the theme.',
          controls: [
            PlayChoice<HeroCardMode>('mode', [
              for (final m in HeroCardMode.values) (m.name, m),
            ]),
            PlayChoice<_Versions>('versions', [
              ('content only', _Versions.content),
              ('folded only', _Versions.folded),
              ('both (folds)', _Versions.both),
            ]),
            const PlayBool('header', initialValue: true),
            const PlayBool('footer', initialValue: true),
            const PlayBool('alert'),
            const PlayBool('long text'),
          ],
          builder: (context, v) => _play(v),
        ),
        HubDemo(
          title: 'HeroBar: pace and warn lines',
          note:
              'The budget hero: alert is the warn point, marker the pace, each '
              'named above its line.',
          child: Builder(
            builder: (context) => HeroBar(
              value: 0.39,
              marker: 0.26,
              markerLabel: 'Today',
              alert: 0.8,
              alertColor: Theme.of(context).extension<AppColors>()!.warning,
              alertLabel: 'Warn',
              left: 'Used ฿3,120',
              right: 'Up to ฿2,080 by today',
            ),
          ),
        ),
        HubDemo(
          title: 'HeroColors: set the card color, the rest follows',
          note:
              'HeroSurface puts a HeroColors (accent, soft, line, track, text, '
              'muted, warning, danger, success) in a HeroColorScope, made '
              'from the card color, or from the theme primary on a plain '
              'card. Nothing below passes a color: the number, bar, tiles, '
              'captions and the round button all read the card. A status '
              'tile (red) takes the card\'s danger.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (name, style) in const [
                ('purple', HeroStyle.tinted(color: Color(0xFFB35BC9))),
                ('pink', HeroStyle.tinted(color: Color(0xFFD9488F))),
                ('plain = theme primary', HeroStyle.plain()),
              ]) ...[
                AppHeroCard(
                  style: style,
                  content: [
                    HeroIdentity(
                      name: Text('Budget ($name)'),
                      fact: const Text('Monthly | 1 Oct – 31 Oct | day 20/31'),
                      trailing: CardActionButton(
                        icon: AppIcons.edit,
                        onTap: () {},
                      ),
                    ),
                    const HeroNumber(
                      label: 'Left',
                      value: Text('฿1,100'),
                      target: 'of ฿2,000',
                    ),
                    const HeroBar(
                      value: 0.45,
                      marker: 0.645,
                      markerLabel: 'Today',
                      alert: 0.8,
                      alertLabel: 'Warn',
                      left: 'Used ฿900',
                      right: 'Up to ฿1,300 by today',
                    ),
                    const HeroTiles(
                      children: [
                        SummaryTileView(
                          tile: SummaryTile(label: 'Per day', value: '฿100'),
                        ),
                        SummaryTileView(
                          tile: SummaryTile(label: 'Days left', value: '11'),
                        ),
                        SummaryTileView(
                          tile: SummaryTile(
                            label: 'Over on',
                            value: '฿300',
                            tone: SummaryTileTone.red,
                          ),
                        ),
                      ],
                    ),
                    const _HeroColorSwatches(),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
        HubDemo(
          title: 'Ring hero: HeroRing + HeroFactList + HeroInfoBox',
          note:
              'The budget hero. HeroInfoBox sits beside the edit button '
              '(max 168 wide, lines end in "…" so a long name keeps its '
              'room). HeroRing: used + expected (lighter), a pace tick and '
              'a warn tick, the number inside; over the base ring a shade '
              'starts at a round head at the top and is gone by half way, '
              'so the start reads at 0; color: paints a '
              'warning / over state. HeroRingRow: the facts get half the '
              'row (min 176, room for ฿1,000,000), the ring the rest (max '
              '160). The plan status goes last, chip size. All colors come '
              'from the card.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (name, used, color, status) in [
                ('test', 0.0, null, (StatusKind.active, 'On plan')),
                (
                  'A very long budget name for the new year trip',
                  0.725,
                  _amber,
                  (StatusKind.warning, '฿150 ahead of plan'),
                ),
                ('Over', 1.15, _red, (StatusKind.over, 'Over by ฿300')),
              ]) ...[
                AppHeroCard(
                  style: const HeroStyle.tinted(color: Color(0xFFB35BC9)),
                  content: [
                    HeroIdentity(
                      name: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      description: const Text('testss'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const HeroInfoBox(
                            icon: AppIcons.recurring,
                            title: 'Monthly on the 1st',
                            subtitle: '12 days left | 20/31',
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          CardActionButton(icon: AppIcons.edit, onTap: () {}),
                        ],
                      ),
                    ),
                    // The over card uses a ฿1,000,000 limit: the facts keep
                    // room for seven digits.
                    HeroRingRow(
                      ring: (size) => HeroRing(
                        size: size,
                        stroke: 14,
                        value: used,
                        expected: used > 0 && used < 1 ? 0.1 : null,
                        marker: 0.65,
                        alert: 0.8,
                        color: color,
                        label: used > 1 ? 'Over' : 'Left',
                        amount: Text(
                          used > 1
                              ? '฿150,000'
                              : '฿${((1 - used) * 2000).round()}',
                        ),
                        target: used > 1 ? 'of ฿1,000,000' : 'of ฿2,000',
                      ),
                      facts: [
                        HeroFact(
                          'Spent',
                          used > 1 ? '฿1,150,000' : '฿${(used * 2000).round()}',
                          icon: AppIcons.receipt,
                        ),
                        if (used > 0 && used < 1)
                          const HeroFact(
                            'Coming up',
                            '฿200',
                            icon: AppIcons.scheduled,
                          ),
                        HeroFact(
                          'Plan to date',
                          used > 1 ? '฿650,000' : '฿1,300',
                          icon: AppIcons.trendingUp,
                        ),
                        used > 1
                            ? HeroFact(
                                'Next period',
                                '1 Nov',
                                color: _red,
                                icon: AppIcons.recurring,
                              )
                            : const HeroFact(
                                'Per day',
                                '฿46',
                                icon: AppIcons.date,
                              ),
                      ],
                    ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: StatusChip(
                        label: status.$2,
                        kind: status.$1,
                        size: ChipSize.chip,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ],
          ),
        ),
        HubDemo(
          title: 'List hero: HeroRingRow + HeroFilterChips (+ a HeroFact link)',
          note:
              'The budgets / saving goals lists: HeroModuleTile + a bold '
              'StatusChip(emphasis) lead the header (no faint caption), then '
              'the ring of the total, its facts with icons (HeroFact.onTap '
              'adds a › and opens something), and HeroFilterChips in place of '
              'the summary tiles.',
          child: Builder(
            builder: (context) {
              final scheme = Theme.of(context).colorScheme;
              return AppHeroCard(
                style: HeroStyle.tinted(color: scheme.primary),
                header: HeroHeader(
                  leading: const [
                    HeroModuleTile(AppIcons.budget),
                    StatusChip(
                      label: 'Ahead of plan ฿1,390',
                      kind: StatusKind.warning,
                      emphasis: true,
                    ),
                  ],
                  actions: [
                    AppIconButton(icon: AppIcons.search, onPressed: () {}),
                  ],
                ),
                content: [
                  HeroRingRow(
                    ring: (size) => HeroRing(
                      size: size,
                      stroke: 14,
                      value: 0.765,
                      label: 'Left in total',
                      amount: const Text('฿2,350'),
                      target: 'of ฿10,000',
                    ),
                    facts: [
                      const HeroFact('Spent', '฿7,650', icon: AppIcons.receipt),
                      const HeroFact('Used', '77%', icon: AppIcons.pie),
                      HeroFact(
                        'Unallocated',
                        '฿23,123',
                        icon: AppIcons.wallet,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
                footer: [
                  HeroFilterChips(
                    filters: [
                      HeroFilter(
                        label: 'All',
                        count: 3,
                        selected: true,
                        onTap: () {},
                      ),
                      HeroFilter(
                        label: 'On track',
                        count: 1,
                        tone: AppChipTone.success,
                        onTap: () {},
                      ),
                      HeroFilter(
                        label: 'Near',
                        count: 1,
                        tone: AppChipTone.warning,
                        onTap: () {},
                      ),
                      HeroFilter(
                        label: 'Over',
                        count: 0,
                        tone: AppChipTone.danger,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        HubDemo(
          title: 'HeroFlowRow + HeroInsetBox',
          note:
              'HeroFlowRow (the wallet hero, under the split + facts): [‹] '
              '[money in] [money out] [›] across the card. The labels carry '
              'the month; a null onNext fades › (this month). Tapping a box '
              'selects it (a filter on the list). HeroInsetBox: the card\'s '
              'soft fill + line border around pieces that act on one thing '
              '(the recurring hero\'s next occurrence and its buttons).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (month, selected) in [
                ('Oct', HeroFlowSelection.none),
                ('Sep', HeroFlowSelection.expense),
              ]) ...[
                AppHeroCard(
                  style: HeroStyle.tinted(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  content: [
                    HeroFlowRow(
                      incomeLabel: 'Money in $month',
                      expenseLabel: 'Money out $month',
                      income: '+฿0',
                      expense: '-฿24,681',
                      onPrev: () {},
                      onNext: month == 'Oct' ? null : () {},
                      onTapIncome: () {},
                      onTapExpense: () {},
                      selected: selected,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              AppHeroCard(
                style: HeroStyle.tinted(
                  color: Theme.of(context).colorScheme.tertiary,
                ),
                content: [
                  HeroInsetBox(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const HeroNumber(
                          label: 'Next | in 14 days',
                          value: Text('-฿419'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          children: [
                            AppChip(label: 'Edit amount', onTap: () {}),
                            AppChip(label: 'Move date', onTap: () {}),
                            AppChip(label: 'Skip', onTap: () {}),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Wallets hero: split bar + dotted facts + icon filters',
          note:
              'One card, no fold. The net in big, a HeroBar.split of what makes '
              'it (available | saved | card debt). HeroFact.icon + iconColor '
              'tie each row to its part (the legend); HeroFilter.icon puts an '
              'icon on each filter. '
              'The filters show only when there are cards to filter by.',
          child: Builder(
            builder: (context) {
              final palette = Theme.of(context).extension<AppColors>()!;
              final saved = ModuleColors.of(context).planning;
              return AppHeroCard(
                style: HeroStyle.tinted(
                  color: Theme.of(context).colorScheme.primary,
                ),
                header: HeroSummaryHead(
                  icon: AppIcons.wallet,
                  label: 'My net worth | 3 wallets',
                  amount: const Text('฿4,199,485'),
                  actions: [
                    AppIconButton(icon: AppIcons.search, onPressed: () {}),
                  ],
                ),
                content: [
                  Builder(
                    builder: (context) => HeroBar.split(
                      parts: [
                        (0.992, HeroColors.maybeOf(context)!.accent),
                        (0.01, saved),
                        (0.003, palette.walletLiability),
                      ],
                    ),
                  ),
                  Builder(
                    builder: (context) => HeroFactList(
                      facts: [
                        HeroFact(
                          'Available',
                          '฿4,188,528',
                          icon: AppIcons.coin,
                          iconColor: HeroColors.maybeOf(context)!.accent,
                        ),
                        HeroFact(
                          'Saved',
                          '฿23,357',
                          icon: AppIcons.savings,
                          iconColor: saved,
                          onTap: () {},
                        ),
                        HeroFact(
                          'Card debt | 25% of the limit',
                          '฿12,400',
                          icon: AppIcons.creditCard,
                          iconColor: palette.walletLiability,
                          color: palette.walletLiability,
                        ),
                      ],
                    ),
                  ),
                ],
                footer: [
                  HeroFilterChips(
                    filters: [
                      HeroFilter(
                        label: 'All',
                        count: 3,
                        icon: AppIcons.wallet,
                        selected: true,
                        onTap: () {},
                      ),
                      HeroFilter(
                        label: 'Cash / bank',
                        count: 2,
                        icon: AppIcons.bank,
                        onTap: () {},
                      ),
                      HeroFilter(
                        label: 'Credit card',
                        count: 1,
                        icon: AppIcons.creditCard,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        HubDemo(
          title: 'HeroStepperHead',
          note:
              'A list hero\'s plan head: a stepper with the plan\'s title '
              'beside it, no divider. The saving goals list puts a month '
              'StepperPill here; the title is its own text per month.',
          child: AppHeroCard(
            style: HeroStyle.tinted(
              color: Theme.of(context).colorScheme.primary,
            ),
            content: [
              HeroStepperHead(
                stepper: StepperPill.month(
                  value: DateTime(2026, 10),
                  onChanged: (_) {},
                ),
                title: 'This month\'s saving plan',
              ),
              HeroStepperHead(
                stepper: StepperPill.month(
                  value: DateTime(2026, 9),
                  onChanged: (_) {},
                ),
                title: 'Saving plan',
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'List summary — folds',
          note:
              'header: a period pill + actions (⌃ added by the card). '
              'content: the number inline with its label. footer: filter '
              'tiles. Folded: header + the number, small.',
          child: AppHeroCard(
            style: HeroStyle.tinted(color: scheme.primary),
            open: _listOpen,
            header: HeroHeader(
              leading: [
                StepperPill(label: 'October 2026', onPrev: () {}, onTap: () {}),
              ],
              actions: [AppIconButton(icon: AppIcons.search, onPressed: () {})],
            ),
            content: [
              HeroNumber(
                label: 'Net',
                value: const Text('+฿4,190'),
                color: _green,
                layout: HeroNumberLayout.inline,
              ),
              DailyBars(
                bars: [
                  for (final (i, v) in [120, 300, 80, 0, 560, 210, 90].indexed)
                    DailyBar(
                      value: v.toDouble(),
                      kind: i < 5
                          ? DailyBarKind.past
                          : i == 5
                          ? DailyBarKind.today
                          : DailyBarKind.future,
                    ),
                ],
                startLabel: '1 Oct',
                centerLabel: 'Avg ฿270 / day',
                endLabel: '7 Oct',
              ),
            ],
            folded: [
              HeroNumber(
                label: 'Net',
                value: const Text('+฿4,190'),
                color: _green,
                layout: HeroNumberLayout.inline,
                small: true,
              ),
            ],
            footer: [HeroTiles(children: _tiles(selectable: true))],
          ),
        ),
        HubDemo(
          title: 'Entry — two fields on one row',
          note:
              'content: HeroFields (description | amount, fixed-height '
              'inputs, no extra gap). footer: two pick cards.',
          child: AppHeroCard(
            style: HeroStyle.tinted(color: _red),
            mode: HeroCardMode.edit,
            header: HeroHeader(
              leading: [
                AppChip(
                  label: 'Expense',
                  icon: AppIcons.expense,
                  color: _red,
                  selected: true,
                ),
                AppChip(
                  label: 'Income',
                  color: _green,
                  dashed: true,
                  onTap: () {},
                ),
              ],
              actions: [
                AppChip(
                  label: 'Today',
                  icon: AppIcons.date,
                  dashed: true,
                  onTap: () {},
                ),
              ],
            ),
            content: [
              HeroFields(
                start: AppInput.card(
                  controller: _what,
                  size: AppInputSize.hero,
                  label: 'Description',
                  labelPlacement: AppInputLabelPlacement.above,
                  underline: true,
                  focusColor: _red,
                ),
                end: AppInput.card(
                  controller: _amount,
                  type: AppInputType.amount,
                  size: AppInputSize.hero,
                  label: 'Amount',
                  labelPlacement: AppInputLabelPlacement.above,
                  textAlign: TextAlign.end,
                  currencySymbol: '฿',
                  symbolScale: 0.7,
                  style: text.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: _red,
                  ),
                  underline: true,
                  focusColor: _red,
                ),
              ),
            ],
            footer: [
              HeroTiles(
                children: [
                  PickCard(
                    label: 'Category',
                    value: 'Food & Drinks',
                    leading: _circle(AppIcons.category, Colors.orange),
                    accent: Colors.orange,
                    reserveSubtitle: true,
                    onTap: () {},
                  ),
                  PickCard(
                    label: 'Wallet',
                    placeholder: 'Pick a wallet',
                    leading: const PickCardEmptyIcon(AppIcons.wallet),
                    reserveSubtitle: true,
                    onTap: () {},
                  ),
                ],
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Identity only — no header, no footer',
          note: 'A profile hero: the header is left out, so nothing is drawn.',
          child: AppHeroCard(
            style: HeroStyle.tinted(
              color: scheme.primary,
              glyph: AppIcons.profile,
            ),
            content: [
              HeroIdentity(
                icon: _circle(AppIcons.profile, scheme.primary, size: 52),
                name: const Text('Chalee'),
                fact: const Text('chalee@example.com'),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Folded only — can’t expand',
          note: 'Only a folded version: a floating pill, no ⌄.',
          child: AppHeroCard(
            style: HeroStyle.tinted(color: _green),
            header: HeroHeader(
              leading: [StepperPill(label: '2026', onTap: () {})],
            ),
            folded: [
              HeroNumber(
                label: 'Saved',
                value: const Text('฿18,000'),
                color: _green,
                layout: HeroNumberLayout.inline,
                small: true,
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'Pieces',
          note:
              'Everything a hero is built from. A page uses these and '
              'nothing else; a new look starts here as a new piece.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              HubCell(
                caption: 'HeroNumber | stacked',
                child: HeroNumber(
                  label: 'Spent',
                  value: const Text('฿5,100'),
                  color: _red,
                  target: '/ ฿8,000',
                ),
              ),
              HubCell(
                caption: 'HeroNumber | inline',
                child: HeroNumber(
                  label: 'Net',
                  value: const Text('+฿4,190'),
                  color: _green,
                  layout: HeroNumberLayout.inline,
                  target: 'this month',
                ),
              ),
              HubCell(
                caption: 'HeroNumber | inline | small',
                child: HeroNumber(
                  label: 'Net',
                  value: const Text('+฿4,190'),
                  color: _green,
                  layout: HeroNumberLayout.inline,
                  small: true,
                ),
              ),
              HubCell(
                caption: 'HeroBar | split',
                child: HeroBar.split(
                  parts: [(0.5, _green), (0.3, _red)],
                  left: 'Paid',
                  right: 'Left',
                ),
              ),
              const HubCell(
                caption: 'HeroValueLine',
                child: HeroValueLine(
                  label: 'Each month',
                  value: Text('฿1,500'),
                ),
              ),
              HubCell(
                caption: 'HeroAlert',
                child: HeroAlert(text: 'Over the pace by ฿600', onTap: () {}),
              ),
              const HubCell(
                caption: 'HeroCaption',
                child: HeroCaption('Net | 4 wallets | 1 shared'),
              ),
              const HubCell(
                caption: 'CountMark',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  spacing: AppSpacing.sm,
                  children: [
                    CountMark(
                      icon: AppIcons.wallet,
                      count: 4,
                      label: 'Wallets',
                    ),
                    CountMark(icon: AppIcons.link, count: 1, label: 'Shared'),
                  ],
                ),
              ),
              HubCell(
                caption: 'HeroNote',
                child: HeroNote(
                  alignment: AlignmentDirectional.centerEnd,
                  onTap: () {},
                  child: const Text('Your share ฿600 | others owe ฿650'),
                ),
              ),
              HubCell(
                caption: 'HeroTiles',
                child: HeroTiles(children: _tiles()),
              ),
              HubCell(
                caption: 'StatusAmountLine',
                child: StatusAmountLine(
                  status: 'To receive',
                  tone: AppChipTone.success,
                  color: _green,
                  amount: const AmountText('฿1,232'),
                ),
              ),
              HubCell(
                caption: 'AmountText',
                child: AmountText(
                  '-฿5,100',
                  color: _red,
                  style: text.titleLarge,
                ),
              ),
              HubCell(
                caption: 'MessageShareBox',
                child: MessageShareBox(
                  text: 'Summary with Chalee | 17 Oct you paid +1,232',
                  label: 'Summary message | edit before sending',
                  copyLabel: 'Copy',
                  shareLabel: 'Share',
                  onCopy: (_) {},
                  onShare: (_) {},
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The card's [HeroColors], read from inside it, one dot per role.
class _HeroColorSwatches extends StatelessWidget {
  const _HeroColorSwatches();

  @override
  Widget build(BuildContext context) {
    final c = HeroColors.maybeOf(context)!;
    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.xs,
      children: [
        for (final (name, color) in [
          ('accent', c.accent),
          ('soft', c.soft),
          ('line', c.line),
          ('track', c.track),
          ('muted', c.muted),
          ('warning', c.warning),
          ('danger', c.danger),
          ('success', c.success),
        ])
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(color: c.line),
                ),
                child: const SizedBox.square(dimension: 14),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                name,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: c.muted),
              ),
            ],
          ),
      ],
    );
  }
}
