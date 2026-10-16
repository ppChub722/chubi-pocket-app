import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_kit.dart';
import '../hub_playground.dart';

/// `/dev/ui/organisms/list-summary-card` — the card on top of every list page.
Widget buildListSummaryCardPage(BuildContext context) =>
    const _ListSummaryCardDemo();

class _ListSummaryCardDemo extends StatefulWidget {
  const _ListSummaryCardDemo();

  @override
  State<_ListSummaryCardDemo> createState() => _ListSummaryCardDemoState();
}

class _ListSummaryCardDemoState extends State<_ListSummaryCardDemo> {
  String? _filter;
  int _ctaTaps = 0;

  /// Tap again to clear — the page's logic, not the card's.
  void _pick(String f) => setState(() => _filter = _filter == f ? null : f);

  Widget _search() =>
      CardActionButton(icon: AppIcons.search, onTap: () {}, tooltip: 'Search');

  static const _noMargin = EdgeInsets.zero;

  @override
  Widget build(BuildContext context) {
    final palette = Theme.of(context).extension<AppColors>()!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubDemo(
          title: 'Budgets-like: 4 filter tiles + bar',
          note:
              'Tiles are filters: tap selects (primary ring), tap again '
              'clears — that is the page logic. The bar carries the pace '
              'marker and the left / right captions.',
          child: ListSummaryCard(
            margin: _noMargin,
            caption: 'October budgets',
            actions: [_search()],
            amount: 12300,
            symbol: '฿',
            mainSuffix: 'of ฿19,000',
            bar: const ProgressRow(
              value: 0.65,
              marker: 0.5,
              label: 'Spent 65%',
              trailing: 'Left ฿6,700',
            ),
            tiles: [
              for (final t in [
                ('Safe', '5', SummaryTileTone.green),
                ('Near', '2', SummaryTileTone.amber),
                ('Over', '1', SummaryTileTone.red),
                ('Paused', '1', SummaryTileTone.neutral),
              ])
                SummaryTile(
                  label: t.$1,
                  value: t.$2,
                  tone: t.$3,
                  selected: _filter == t.$1,
                  onTap: () => _pick(t.$1),
                ),
            ],
          ),
        ),
        HubDemo(
          title: 'Goals-like: bar + info line',
          child: ListSummaryCard(
            margin: _noMargin,
            caption: 'Saved so far',
            actions: [_search()],
            amount: 42000,
            symbol: '฿',
            mainSuffix: 'of ฿120,000',
            bar: const ProgressRow(value: 0.35, label: '35%'),
            infoLine: Text(
              '🐷 Unallocated ฿8,500',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
        HubDemo(
          title: 'Recurring-like: tiles + amber alert',
          child: ListSummaryCard(
            margin: _noMargin,
            caption: 'Next 30 days',
            actions: [_search()],
            amount: 8400,
            symbol: '฿',
            mainTone: MoneyTone.expense,
            alert: '2 need attention',
            onAlertTap: () {},
            tiles: [
              SummaryTile(
                label: 'Active',
                value: '9',
                tone: SummaryTileTone.green,
                selected: _filter == 'Active',
                onTap: () => _pick('Active'),
              ),
              SummaryTile(
                label: 'Due',
                value: '2',
                tone: SummaryTileTone.orange,
                selected: _filter == 'Due',
                onTap: () => _pick('Due'),
                caption: 'this week',
              ),
              SummaryTile(
                label: 'Paused',
                value: '1',
                selected: _filter == 'Paused',
                onTap: () => _pick('Paused'),
              ),
            ],
          ),
        ),
        HubDemo(
          title: 'With a big button (CTA) and a tint',
          child: ListSummaryCard(
            margin: _noMargin,
            style: HeroStyle.tinted(color: palette.info),
            caption: 'Events',
            actions: [_search()],
            main: const Text('3 open'),
            tiles: const [
              SummaryTile(label: 'Open', value: '3'),
              SummaryTile(label: 'Done', value: '12'),
            ],
            cta: SummaryCta(
              label: 'New event ($_ctaTaps)',
              icon: AppIcons.add,
              onTap: () => setState(() => _ctaTaps++),
            ),
          ),
        ),
        HubPlayground(
          title: 'ListSummaryCard',
          note: 'Every part is optional.',
          controls: [
            PlayText('caption', initialValue: 'Caption'),
            PlayNum(
              'amount',
              min: 0,
              max: 100000,
              step: 500,
              initialValue: 12300,
            ),
            PlayText('suffix', initialValue: 'of ฿19,000'),
            PlayBool('bar', initialValue: true),
            PlayNum(
              'barValue',
              min: 0,
              max: 1.5,
              step: 0.05,
              initialValue: 0.6,
            ),
            PlayBool('marker'),
            PlayBool('info'),
            PlayBool('alert'),
            PlayBool('alertTappable', initialValue: true),
            PlayNum('tiles', min: 0, max: 4, step: 1, initialValue: 3),
            PlayBool('cta'),
            PlayBool('tinted'),
            PlayBool('action', initialValue: true),
          ],
          builder: (context, v) {
            final n = v<double>('tiles').round();
            final tones = SummaryTileTone.values;
            return ListSummaryCard(
              margin: _noMargin,
              caption: v<String>('caption'),
              actions: [if (v<bool>('action')) _search()],
              amount: v<double>('amount'),
              symbol: '฿',
              mainSuffix: v<String>('suffix').isEmpty
                  ? null
                  : v<String>('suffix'),
              bar: v<bool>('bar')
                  ? ProgressRow(
                      value: v<double>('barValue'),
                      marker: v<bool>('marker') ? 0.5 : null,
                      label: 'Left caption',
                      trailing: 'Right caption',
                    )
                  : null,
              infoLine: v<bool>('info') ? const Text('Info line') : null,
              alert: v<bool>('alert') ? 'Something needs attention' : null,
              onAlertTap: v<bool>('alertTappable') ? () {} : null,
              tiles: [
                for (var i = 0; i < n; i++)
                  SummaryTile(
                    label: 'Tile ${i + 1}',
                    value: '${i + 1}',
                    tone: tones[i % tones.length],
                    onTap: () {},
                  ),
              ],
              cta: v<bool>('cta')
                  ? SummaryCta(label: 'Add', icon: AppIcons.add, onTap: () {})
                  : null,
              style: v<bool>('tinted')
                  ? HeroStyle.tinted(color: palette.income)
                  : const HeroStyle.plain(),
            );
          },
        ),
      ],
    );
  }
}
