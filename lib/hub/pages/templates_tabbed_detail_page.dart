import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';

/// The Tabbed detail template: hero → below-hero block → pinned tab bar →
/// one lazy list per tab; the compact hero bar once the hero is gone.
Widget buildTabbedDetailTemplate(BuildContext context) =>
    const _TabbedDetailDemo();

enum _Tab { ledger, history }

class _TabbedDetailDemo extends StatefulWidget {
  const _TabbedDetailDemo();

  @override
  State<_TabbedDetailDemo> createState() => _TabbedDetailDemoState();
}

class _TabbedDetailDemoState extends State<_TabbedDetailDemo> {
  _Tab _tab = _Tab.ledger;
  int _shown = 8;
  bool _failNext = false;
  Object? _moreError;
  bool _loadingMore = false;

  Future<void> _refresh() async {
    await Future<void>.delayed(const Duration(milliseconds: 600));
    if (mounted) setState(() => _shown = 8);
  }

  Future<void> _loadMore() async {
    setState(() {
      _loadingMore = true;
      _moreError = null;
    });
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (!mounted) return;
    setState(() {
      _loadingMore = false;
      if (_failNext) {
        _moreError = StateError('demo');
      } else {
        _shown += 8;
      }
    });
  }

  Widget _rows(String prefix, int n) => ListPageBody(
    loading: false,
    error: null,
    isEmpty: n == 0,
    onRetry: _refresh,
    empty: const EmptyView.compact(message: 'No entries'),
    rowDividers: true,
    hasMore: _shown < 40,
    loadingMore: _loadingMore,
    loadMoreError: _moreError,
    onLoadMore: _loadMore,
    bottomInset: AppSpacing.lg,
    header: [
      ListToolbar(
        searchHint: 'Search',
        onSearchChanged: (_) {},
        chips: [
          AppChip(label: 'Paid', onTap: () {}),
          AppChip(label: 'Open', onTap: () {}),
        ],
      ),
    ],
    children: [
      for (var i = 0; i < n; i++)
        ListRow(title: '$prefix ${i + 1}', subtitle: '12 Oct', onTap: () {}),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'TabbedDetailBody — the debts person page shape',
          note:
              'Hero (a HeaderCard) → belowHero (the page’s ONE primary '
              'button, an optional DetailRow section) → the tab bar pins '
              'under the top bar → each tab is a ListPageBody (toolbar, '
              'hairlines, paging with the retry row, pull-to-refresh), built '
              'the first time it shows. Scroll: the compact bar appears '
              'under the tabs once the hero is gone (tap = back up).',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  AppChip(
                    label: 'fail the next page',
                    selected: _failNext,
                    onTap: () => setState(() => _failNext = !_failNext),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Container(
                height: 560,
                decoration: BoxDecoration(
                  border: Border.all(color: scheme.outlineVariant),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                clipBehavior: Clip.antiAlias,
                child: TabbedDetailBody<_Tab>(
                  selected: _tab,
                  onChanged: (t) => setState(() => _tab = t),
                  tabs: const [
                    AppTab(value: _Tab.ledger, label: 'Entries'),
                    AppTab(value: _Tab.history, label: 'Payments'),
                  ],
                  hero: const HeaderCard(
                    leading: SizedBox(width: 52, height: 52),
                    title: Text('Mom'),
                    subtitle: Text('Linked contact'),
                  ),
                  belowHero: [
                    AppButton(
                      label: 'Add an entry',
                      icon: AppIcons.add,
                      expand: true,
                      onPressed: () {},
                    ),
                  ],
                  compactBar: const CompactHeroBar(title: Text('Mom')),
                  tabBuilder: (context, t) => switch (t) {
                    _Tab.ledger => _rows('Entry', _shown),
                    _Tab.history => _rows('Payment', 3),
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
