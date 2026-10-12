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
        AppCard(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          onTap: _selecting
              ? () => setState(() {
                  if (!_picked.remove(i)) _picked.add(i);
                })
              : () {},
          child: ListRow(
            title: 'Item ${i + 1}',
            subtitle: 'A line about it',
            leading: const AppAvatar.icon(AppIcons.wallet, size: 36),
            checked: _selecting ? _picked.contains(i) : null,
            onCheck: _selecting
                ? () => setState(() {
                    if (!_picked.remove(i)) _picked.add(i);
                  })
                : null,
          ),
        ),
    ];

    final header = <Widget>[
      AppInput.search(controller: _search, hint: 'Search', onChanged: (_) {}),
      if (_selecting)
        FilterBar(
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
        FilterBar(
          chips: const [
            AppChip(
              label: 'Status',
              trailing: AppChipTrailing.dropdown,
              onTap: _noop,
            ),
            AppChip(
              label: 'Sort',
              icon: AppIcons.sort,
              trailing: AppChipTrailing.dropdown,
              onTap: _noop,
            ),
          ],
          trailing: AppIconButton(
            icon: AppIcons.edit,
            size: 36,
            onPressed: () => setState(() => _selecting = true),
          ),
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
            return Container(
              height: 420,
              decoration: BoxDecoration(
                border: Border.all(color: scheme.outlineVariant),
                borderRadius: BorderRadius.circular(AppRadius.lg),
              ),
              clipBehavior: Clip.antiAlias,
              child: ListPageBody(
                header: v<bool>('header')
                    ? [
                        AppInput.search(
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
                  icon: AppIcons.empty,
                  title: 'Nothing here yet',
                  message: 'Add your first item to get started.',
                ),
                children: rows.take(5).toList(),
              ),
            );
          },
        ),
        HubInApp(
          note: 'The real list pages all use this skeleton.',
          uses: [
            HubUse(
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
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      for (final s in _State.values)
                        AppChip(
                          label: s.name,
                          selected: _state == s,
                          onTap: () => setState(() => _state = s),
                        ),
                      AppChip(
                        label: _selecting ? 'Done selecting' : 'Select',
                        icon: AppIcons.check,
                        selected: _selecting,
                        onTap: () => setState(() {
                          _selecting = !_selecting;
                          _picked.clear();
                        }),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    height: 560,
                    decoration: BoxDecoration(
                      border: Border.all(color: scheme.outlineVariant),
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ListPageBody(
                      header: header,
                      loading: _state == _State.loading,
                      error: _state == _State.error ? const _DemoError() : null,
                      isEmpty: _state == _State.empty,
                      onRetry: _refresh,
                      empty: EmptyView(
                        icon: AppIcons.empty,
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
                  ),
                ],
              ),
            ),
          ],
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
