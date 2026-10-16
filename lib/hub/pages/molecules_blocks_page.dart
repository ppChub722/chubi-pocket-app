import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../../ui/tokens/app/theme/themes/sweet_theme.dart';
import '../hub_kit.dart';

/// `/dev/ui/molecules/blocks` — page building blocks: the select-mode bar, the
/// pinned tab bar, the tile grid, the centred form body.
Widget buildBlocksPage(BuildContext context) => const _BlocksPage();

class _BlocksPage extends StatefulWidget {
  const _BlocksPage();

  @override
  State<_BlocksPage> createState() => _BlocksPageState();
}

class _BlocksPageState extends State<_BlocksPage> {
  int _picked = 2;
  String _tab = 'a';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'TopScrim — content fading under the top bar',
          note:
              'The top bar is transparent and bodies run behind it, so scrolled '
              'rows would show under the clock and behind the floating pills. '
              'TopScrim (the bar\'s flexible space) is the page colour — solid '
              'over the status-bar inset, fading to transparent over the bar '
              'height — so the pills still look floating. It ignores pointers '
              '(rows under the fade stay tappable) and shifts nothing. Dark and '
              'light, a list and a detail-like page; the list is scrolled.',
          child: Wrap(
            spacing: PpForgeSpacing.md,
            runSpacing: PpForgeSpacing.md,
            children: [
              for (final (dark, detail) in const [
                (true, false),
                (false, false),
                (true, true),
                (false, true),
              ])
                _ScrimPhone(dark: dark, detail: detail),
            ],
          ),
        ),
        HubDemo(
          title: 'ActionBar',
          note:
              '2–4 EQUAL-width buttons in one row under a hero: control height '
              '40, icon + short label; one can be primary (filled), the rest '
              'tonal. Used by the wallet (adjust balance · add transaction · '
              'transfer).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ActionBar(
                actions: [
                  ActionBarItem(
                    label: 'ปรับยอด',
                    icon: PpForgeIcons.refresh,
                    onPressed: () {},
                  ),
                  ActionBarItem(
                    label: 'รายการ',
                    icon: PpForgeIcons.add,
                    onPressed: () {},
                  ),
                  ActionBarItem(
                    label: 'โอน',
                    icon: PpForgeIcons.transfer,
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: PpForgeSpacing.md),
              ActionBar(
                actions: [
                  ActionBarItem(label: 'Edit', onPressed: () {}),
                  ActionBarItem(label: 'Archive', onPressed: null),
                ],
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'SelectionToolbar',
          note:
              'The select-mode bar at the top of a list: [☐ n/N] the select-all, '
              'the bulk actions (dimmed until something is selected), the red '
              'trash at the end. Not ModeActionBar (the bottom Cancel · Save). '
              'Used by tags (edit), pending, and every multi-select list.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SelectionToolbar(
                selected: _picked,
                total: 5,
                onSelectAll: () =>
                    setState(() => _picked = _picked == 5 ? 0 : 5),
                selectAllTooltip: 'Select all',
                actions: [
                  SelectionAction(
                    label: 'Colour',
                    icon: PpForgeIcons.colorPicker,
                    onTap: () {},
                  ),
                  SelectionAction(
                    label: 'Icon',
                    icon: PpForgeIcons.iconPicker,
                    onTap: () {},
                  ),
                  SelectionAction(
                    label: 'Import slip',
                    icon: PpForgeIcons.importSlip,
                    needsSelection: false,
                    onTap: () {},
                  ),
                ],
                onDelete: () {},
                deleteTooltip: 'Delete',
              ),
              Wrap(
                spacing: PpForgeSpacing.sm,
                children: [
                  for (final n in [0, 2, 5])
                    PpForgeChip(
                      label: 'picked: $n',
                      size: ChipSize.chip,
                      selected: _picked == n,
                      onTap: () => setState(() => _picked = n),
                    ),
                ],
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'CardGrid + TileCard',
          note:
              'A grid of tinted tiles inside a scrolling page: fixed height, the '
              'column count follows the width (2 on phones, 3–4 wide). Each tile '
              'is the group colour + a faded glyph + a solid rounded icon tile. '
              'The More page.',
          child: CardGrid(
            children: [
              TileCard(
                icon: PpForgeIcons.wallet,
                title: 'Wallets',
                subtitle: 'Your accounts and balances',
                color: scheme.primary,
                onTap: () {},
              ),
              TileCard(
                icon: PpForgeIcons.category,
                title: 'Categories',
                subtitle: 'Group your spending',
                color: scheme.tertiary,
                onTap: () {},
              ),
              TileCard(
                icon: PpForgeIcons.budget,
                title: 'Budgets',
                subtitle: 'Limits per category',
                color: scheme.secondary,
                onTap: () {},
              ),
              TileCard(
                icon: PpForgeIcons.scheduled,
                title: 'Scheduled',
                color: scheme.error,
                onTap: () {},
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'PinnedTabBarDelegate',
          note:
              'The sliver delegate that pins a tab bar under the top bar once the '
              'hero above it has scrolled away (event and wallet detail). Scroll '
              'the box.',
          child: SizedBox(
            height: 260,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(PpForgeRadius.md),
              ),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Container(
                      height: 120,
                      alignment: Alignment.center,
                      color: scheme.primaryContainer,
                      child: const Text('hero (scrolls away)'),
                    ),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: PinnedTabBarDelegate(
                      background: scheme.surface,
                      child: PpForgeTabBar<String>(
                        selected: _tab,
                        onChanged: (v) => setState(() => _tab = v),
                        tabs: const [
                          PpForgeTab(value: 'a', label: 'Overview'),
                          PpForgeTab(
                            value: 'b',
                            label: 'Members',
                            badgeCount: 3,
                          ),
                          PpForgeTab(value: 'c', label: 'History'),
                        ],
                      ),
                    ),
                  ),
                  SliverList.builder(
                    itemCount: 20,
                    itemBuilder: (_, i) =>
                        ListTile(title: Text('Row ${i + 1}')),
                  ),
                ],
              ),
            ),
          ),
        ),
        HubDemo(
          title: 'SegmentedBar + LegendDot',
          note:
              'A thin proportion bar split into coloured segments, with an '
              'optional legend of dots + labels. The wallets summary (how the '
              'total divides by wallet type).',
          child: SegmentedBar(
            legend: true,
            segments: [
              BarSegment(value: 52, color: scheme.primary, label: 'Cash'),
              BarSegment(value: 30, color: scheme.tertiary, label: 'Savings'),
              BarSegment(value: 18, color: scheme.error, label: 'Credit'),
            ],
          ),
        ),
        const HubDemo(
          title: 'EmptyView.compact',
          note:
              'A small empty line (no icon, no title): a muted caption inside a '
              'page section. The full EmptyView is for a whole empty page.',
          child: EmptyView.compact(message: 'No payments yet'),
        ),
        HubDemo(
          title: 'CenteredFormBody',
          note:
              'The body of a centred, narrow form page (sign in, register): safe '
              'area, centred when short, scrolls when tall, the form capped at '
              '400 wide.',
          child: SizedBox(
            height: 220,
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(PpForgeRadius.md),
              ),
              child: const CenteredFormBody(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PpForgeInput(label: 'Email'),
                    SizedBox(height: PpForgeSpacing.md),
                    PpForgeInput(label: 'Password', obscurable: true),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A phone-sized mock page: scrolled rows, [TopScrim] over them, fake pills.
class _ScrimPhone extends StatelessWidget {
  const _ScrimPhone({required this.dark, required this.detail});

  final bool dark;
  final bool detail;

  @override
  Widget build(BuildContext context) {
    final colors = dark ? sweetTheme.darkColors : sweetTheme.lightColors;
    final theme = ThemeData(
      brightness: dark ? Brightness.dark : Brightness.light,
      colorScheme: colors.toColorScheme(),
      scaffoldBackgroundColor: colors.background,
      extensions: [colors],
    );
    const inset = 24.0;
    return Theme(
      data: theme,
      child: Builder(
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${dark ? 'dark' : 'light'} · ${detail ? 'detail' : 'list'}',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: PpForgeSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(PpForgeRadius.lg),
                child: SizedBox(
                  width: 190,
                  height: 280,
                  child: ColoredBox(
                    color: colors.background,
                    child: Stack(
                      children: [
                        // Scrolled: the first rows are already under the bar.
                        ListView(
                          physics: const NeverScrollableScrollPhysics(),
                          controller: ScrollController(initialScrollOffset: 34),
                          padding: EdgeInsets.zero,
                          children: [
                            for (var i = 0; i < 12; i++)
                              Container(
                                height: detail ? 52 : 44,
                                margin: const EdgeInsets.fromLTRB(8, 0, 8, 2),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                alignment: Alignment.centerLeft,
                                decoration: BoxDecoration(
                                  color: scheme.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  detail ? 'ชื่อที่แสดง · row $i' : 'row $i',
                                ),
                              ),
                          ],
                        ),
                        const Positioned(
                          left: 0,
                          right: 0,
                          top: 0,
                          height: inset + kToolbarHeight,
                          child: TopScrim(inset: inset),
                        ),
                        Positioned(
                          top: inset + 6,
                          left: 8,
                          right: 8,
                          child: Row(
                            children: [
                              PpForgeChip(label: 'Page', size: ChipSize.chip),
                              const Spacer(),
                              PpForgeChip(label: '3', size: ChipSize.chip),
                            ],
                          ),
                        ),
                        Positioned(
                          top: 4,
                          left: 12,
                          child: Text(
                            '21:52',
                            style: Theme.of(context).textTheme.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
