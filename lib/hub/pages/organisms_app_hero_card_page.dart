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
