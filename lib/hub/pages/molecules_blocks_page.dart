import 'package:flutter/material.dart';

import '../../ui/ui.dart';
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
                    icon: AppIcons.refresh,
                    onPressed: () {},
                  ),
                  ActionBarItem(
                    label: 'รายการ',
                    icon: AppIcons.add,
                    onPressed: () {},
                  ),
                  ActionBarItem(
                    label: 'โอน',
                    icon: AppIcons.transfer,
                    onPressed: () {},
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
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
                    icon: AppIcons.colorPicker,
                    onTap: () {},
                  ),
                  SelectionAction(
                    label: 'Icon',
                    icon: AppIcons.iconPicker,
                    onTap: () {},
                  ),
                  SelectionAction(
                    label: 'Import slip',
                    icon: AppIcons.importSlip,
                    needsSelection: false,
                    onTap: () {},
                  ),
                ],
                onDelete: () {},
                deleteTooltip: 'Delete',
              ),
              Wrap(
                spacing: AppSpacing.sm,
                children: [
                  for (final n in [0, 2, 5])
                    AppChip(
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
                icon: AppIcons.wallet,
                title: 'Wallets',
                subtitle: 'Your accounts and balances',
                color: scheme.primary,
                onTap: () {},
              ),
              TileCard(
                icon: AppIcons.category,
                title: 'Categories',
                subtitle: 'Group your spending',
                color: scheme.tertiary,
                onTap: () {},
              ),
              TileCard(
                icon: AppIcons.budget,
                title: 'Budgets',
                subtitle: 'Limits per category',
                color: scheme.secondary,
                onTap: () {},
              ),
              TileCard(
                icon: AppIcons.scheduled,
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
                borderRadius: BorderRadius.circular(AppRadius.md),
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
                      child: AppTabBar<String>(
                        selected: _tab,
                        onChanged: (v) => setState(() => _tab = v),
                        tabs: const [
                          AppTab(value: 'a', label: 'Overview'),
                          AppTab(value: 'b', label: 'Members', badgeCount: 3),
                          AppTab(value: 'c', label: 'History'),
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
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const CenteredFormBody(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppInput(label: 'Email'),
                    SizedBox(height: AppSpacing.md),
                    AppInput(label: 'Password', obscurable: true),
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
