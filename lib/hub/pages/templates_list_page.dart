import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_playground.dart';

/// `/dev/templates/list-page` — the ListPage template: search + filters
/// pinned above a list that has one loading / error / empty / refresh story.
Widget buildListPageTemplate(BuildContext context) => const _ListPageTemplate();

enum _State { data, loading, error, empty }

class _ListPageTemplate extends StatefulWidget {
  const _ListPageTemplate();

  @override
  State<_ListPageTemplate> createState() => _ListPageTemplateState();
}

class _ListPageTemplateState extends State<_ListPageTemplate> {
  _State _state = _State.data;
  bool _selecting = false;
  final Set<int> _picked = {};
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() => Future<void>.delayed(const Duration(seconds: 1));

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = [
      for (var i = 0; i < 8; i++)
        PpForgeCard(
          margin: const EdgeInsets.only(bottom: PpForgeSpacing.sm),
          onTap: _selecting
              ? () => setState(() {
                  if (!_picked.remove(i)) _picked.add(i);
                })
              : () {},
          child: ListRow(
            title: 'Item ${i + 1}',
            subtitle: 'A line about it',
            leading: const PpForgeAvatar.icon(PpForgeIcons.wallet, size: 36),
            checked: _selecting ? _picked.contains(i) : null,
            onCheck: _selecting
                ? () => setState(() {
                    if (!_picked.remove(i)) _picked.add(i);
                  })
                : null,
          ),
        ),
    ];

    // Search + filters / sort as ONE block (ListToolbar): the chip row sits
    // one size below the 40 capsule (chip 28).
    final header = <Widget>[
      if (_selecting)
        ListToolbar(
          searchController: _search,
          searchHint: 'Search',
          onSearchChanged: (_) {},
          chips: [
            SelectAllCount(
              selected: _picked.length,
              total: 8,
              onTap: () => setState(() {
                if (_picked.length == 8) {
                  _picked.clear();
                } else {
                  _picked.addAll([for (var i = 0; i < 8; i++) i]);
                }
              }),
            ),
          ],
          trailing: BulkDeleteButton(onPressed: _picked.isEmpty ? null : () {}),
        )
      else
        ListToolbar(
          searchController: _search,
          searchHint: 'Search',
          onSearchChanged: (_) {},
          chips: const [
            PpForgeChip(
              label: 'Status',
              trailing: PpForgeChipTrailing.dropdown,
              onTap: _noop,
            ),
            PpForgeChip(
              label: 'Sort',
              icon: PpForgeIcons.sort,
              trailing: PpForgeChipTrailing.dropdown,
              onTap: _noop,
            ),
          ],
          trailing: PpForgeIconButton(
            icon: PpForgeIcons.edit,
            size: 36,
            onPressed: () => setState(() => _selecting = true),
          ),
        ),
    ];

    Widget framed(Widget child, double height) => Container(
      height: height,
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(PpForgeRadius.lg),
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );

    // Static state variants (the live one above switches between them).
    Widget stateBody(_State s, {bool withCta = false}) => ListPageBody(
      header: [
        PpForgeInput.search(
          controller: _search,
          hint: 'Search',
          onChanged: (_) {},
        ),
      ],
      loading: s == _State.loading,
      error: s == _State.error ? const _DemoError() : null,
      isEmpty: s == _State.empty,
      onRetry: _refresh,
      empty: EmptyView(
        icon: PpForgeIcons.empty,
        title: 'Nothing here yet',
        message: 'Add your first item to get started.',
        cta: withCta ? AddTile(label: 'Add an item', onTap: () {}) : null,
      ),
      children: rows.take(3).toList(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubInApp(
          note:
              'The real list pages all use this skeleton. The first one is '
              'live (states, select mode); below it each state on its own.',
          uses: [
            HubUse(
              wide: true,
              label:
                  'ListPageBody with search + filter bar, select mode and '
                  'AddTile (states: data, loading, error, empty)',
              page:
                  'Accounts, Categories, Contacts, Budgets, Scheduled, '
                  'Transactions, Debts lists',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                    spacing: PpForgeSpacing.xs,
                    runSpacing: PpForgeSpacing.xs,
                    children: [
                      for (final s in _State.values)
                        PpForgeChip(
                          label: s.name,
                          selected: _state == s,
                          onTap: () => setState(() => _state = s),
                        ),
                      PpForgeChip(
                        label: _selecting ? 'Done selecting' : 'Select',
                        icon: PpForgeIcons.check,
                        selected: _selecting,
                        onTap: () => setState(() {
                          _selecting = !_selecting;
                          _picked.clear();
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: PpForgeSpacing.md),
                  framed(
                    ListPageBody(
                      header: header,
                      loading: _state == _State.loading,
                      error: _state == _State.error ? const _DemoError() : null,
                      isEmpty: _state == _State.empty,
                      onRetry: _refresh,
                      empty: EmptyView(
                        icon: PpForgeIcons.empty,
                        title: 'Nothing here yet',
                        message: 'Add your first item to get started.',
                        cta: AddTile(label: 'Add an item', onTap: () {}),
                      ),
                      children: [
                        ...rows,
                        AddTile(
                          label: 'Add an item',
                          variant: AddTileVariant.row,
                          onTap: () {},
                        ),
                      ],
                    ),
                    560,
                  ),
                ],
              ),
            ),
            HubUse(
              wide: true,
              label:
                  'grouped by day — rowDividers: hairlines between rows, one under '
                  'each day header, a thick band between the days',
              page: 'Transactions (+ wallet / event tabs), Pending, Project tx',
              child: framed(
                ListPageBody(
                  loading: false,
                  error: null,
                  isEmpty: false,
                  onRetry: _refresh,
                  empty: const EmptyView(
                    icon: PpForgeIcons.empty,
                    title: 'Nothing here yet',
                    message: '',
                  ),
                  sidePadding: 0,
                  topInset: 0,
                  rowDividers: true,
                  children: [
                    const DateGroupHeader(label: 'Today', total: -540),
                    ...rows.take(2),
                    const DateGroupHeader(label: 'Yesterday', total: 1200),
                    ...rows.take(3),
                  ],
                ),
                420,
              ),
            ),
            HubUse(
              wide: true,
              label:
                  'loading — the skeleton mirrors the grouped list: toolbar, day '
                  'header, rows at the real height, the same hairlines and band',
              page: 'Every list on first load (built into ListPageBody)',
              child: framed(
                const ListPageSkeleton(toolbar: true, grouped: true),
                460,
              ),
            ),
            HubUse(
              wide: true,
              label:
                  'loading — a cards grid: ListPageBody(skeletonShape: '
                  'ListSkeletonShape.grid(...)) — summary block, sort row, two '
                  'rows of cards at the cards height',
              page: 'Wallets',
              child: framed(
                const ListPageSkeleton(
                  shape: ListSkeletonShape.grid(
                    headerHeight: 168,
                    sortRow: true,
                    gridColumns: 2,
                    gridItemExtent: 156,
                  ),
                ),
                520,
              ),
            ),
            HubUse(
              wide: true,
              label: 'data — search above a short list',
              page: 'Contacts, Budgets lists',
              child: framed(stateBody(_State.data), 320),
            ),
            HubUse(
              wide: true,
              label: 'loading — the first-load skeleton',
              page: 'Every list on first load',
              child: framed(stateBody(_State.loading), 320),
            ),
            HubUse(
              wide: true,
              label: 'error — full-page message + retry',
              page: 'Every list when the fetch fails',
              child: framed(stateBody(_State.error), 320),
            ),
            HubUse(
              wide: true,
              label: 'empty — message with an AddTile call to action',
              page: 'Accounts, Scheduled (nothing yet)',
              child: framed(stateBody(_State.empty, withCta: true), 320),
            ),
            HubUse(
              wide: true,
              label: 'empty — message only',
              page: 'Transactions (filtered to nothing)',
              child: framed(stateBody(_State.empty), 320),
            ),
            HubUse(
              wide: true,
              label:
                  'paging — the next page loading: two row skeletons at the '
                  'end (onLoadMore fires near the end while hasMore)',
              page: 'Transactions, debts, event bills',
              child: framed(
                ListPageBody(
                  loading: false,
                  error: null,
                  isEmpty: false,
                  onRetry: _refresh,
                  empty: const EmptyView.compact(message: 'Nothing'),
                  hasMore: true,
                  loadingMore: true,
                  onLoadMore: () {},
                  children: rows.take(2).toList(),
                ),
                300,
              ),
            ),
            HubUse(
              wide: true,
              label:
                  'paging — the next page failed: LoadMoreErrorRow (could not '
                  'load more · Retry); the loaded rows stay, scrolling stops '
                  'asking until Retry',
              page: 'Transactions, debts, event bills',
              child: framed(
                ListPageBody(
                  loading: false,
                  error: null,
                  isEmpty: false,
                  onRetry: _refresh,
                  empty: const EmptyView.compact(message: 'Nothing'),
                  hasMore: true,
                  loadMoreError: const _DemoError(),
                  onRetryMore: () {},
                  footer: const Padding(
                    padding: EdgeInsets.all(PpForgeSpacing.md),
                    child: Center(child: Text('footer slot')),
                  ),
                  children: rows.take(2).toList(),
                ),
                300,
              ),
            ),
          ],
        ),
        HubPlayground(
          title: 'ListPageBody',
          note:
              'The content of every list page: a pinned header over a list '
              'with the first-load skeleton, the full-page error + retry, the '
              'empty state and pull-to-refresh. Real options: loading, error, '
              'isEmpty, header, topInset, bottomInset, sidePadding.',
          controls: [
            PlayChoice<_State>('state', [
              for (final s in _State.values) (s.name, s),
            ]),
            const PlayBool('header', initialValue: true),
            const PlayNum(
              'topInset',
              min: 0,
              max: 32,
              step: 8,
              initialValue: 12,
            ),
            const PlayNum(
              'bottomInset',
              min: 0,
              max: 128,
              step: 16,
              initialValue: 96,
            ),
            const PlayNum(
              'sidePadding',
              min: 0,
              max: 32,
              step: 8,
              initialValue: 16,
            ),
          ],
          builder: (context, v) {
            final state = v<_State>('state');
            return framed(
              ListPageBody(
                header: v<bool>('header')
                    ? [
                        PpForgeInput.search(
                          controller: _search,
                          hint: 'Search',
                          onChanged: (_) {},
                        ),
                      ]
                    : const [],
                topInset: v<double>('topInset'),
                bottomInset: v<double>('bottomInset'),
                sidePadding: v<double>('sidePadding'),
                loading: state == _State.loading,
                error: state == _State.error ? const _DemoError() : null,
                isEmpty: state == _State.empty,
                onRetry: _refresh,
                empty: const EmptyView(
                  icon: PpForgeIcons.empty,
                  title: 'Nothing here yet',
                  message: 'Add your first item to get started.',
                ),
                children: rows.take(5).toList(),
              ),
              420,
            );
          },
        ),
      ],
    );
  }
}

void _noop() {}

class _DemoError implements Exception {
  const _DemoError();

  @override
  String toString() => 'demo error';
}
