import 'package:flutter/material.dart';

import '../../ui/ui.dart';
import '../hub_playground.dart';

/// `/dev/templates/dashboard` — the Dashboard template: a home overview is
/// ONE skeleton. Two zones: a "right now" snapshot (not period-scoped) and a
/// period-scoped zone headed by the period stepper.
Widget buildDashboardTemplate(BuildContext context) =>
    const _DashboardTemplate();

enum _Data { data, loading, error }

class _DashboardTemplate extends StatefulWidget {
  const _DashboardTemplate();

  @override
  State<_DashboardTemplate> createState() => _DashboardTemplateState();
}

class _DashboardTemplateState extends State<_DashboardTemplate> {
  _Data _data = _Data.data;
  bool _refreshing = false;
  DateTime _month = DateTime(2026, 10);

  Future<void> _refresh() => Future<void>.delayed(const Duration(seconds: 1));

  /// A phone-sized frame, so the scrolling body has a bounded height.
  Widget _framed(Widget child) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 640,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: scheme.outlineVariant),
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.md),
          child: child,
        ),
      ),
    );
  }

  // ── Chubi Home: the real kit widgets, sample data ──────────────────────

  Widget _netWorth() => AppCard(
    margin: EdgeInsets.zero,
    child: Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Net worth',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          MoneyText(
            128450,
            symbol: '฿',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );

  Widget _attention() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const SectionHeader(
        title: 'Needs attention',
        padding: EdgeInsets.fromLTRB(AppSpacing.xs, AppSpacing.lg, 0, 0),
      ),
      AppCard(
        margin: const EdgeInsets.only(top: AppSpacing.xs),
        child: Column(
          children: const [
            ListRow(
              title: '3 drafts to confirm',
              subtitle: 'Not counted yet',
              leading: AppAvatar.icon(AppIcons.pending, size: 36),
            ),
            ListRow(
              title: 'Aom paid you back',
              subtitle: 'Notification',
              leading: AppAvatar.icon(AppIcons.notifications, size: 36),
            ),
          ],
        ),
      ),
    ],
  );

  Widget _kpis() => AppCard(
    margin: const EdgeInsets.only(bottom: AppSpacing.md),
    child: const Padding(
      padding: EdgeInsets.all(AppSpacing.lg),
      child: SummaryStats(
        stats: [
          SummaryStat(label: 'Income', amount: 42000, tone: MoneyTone.income),
          SummaryStat(label: 'Expense', amount: 18350, tone: MoneyTone.expense),
          SummaryStat(label: 'Net', amount: 23650, tone: MoneyTone.signed),
        ],
      ),
    ),
  );

  Widget _donut() {
    final colors = ChartPalette.categorical(context);
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            DonutChart(
              size: 96,
              thickness: 12,
              segments: [
                DonutSegment(value: 6200, color: colors[0]),
                DonutSegment(value: 4100, color: colors[1]),
                DonutSegment(value: 2400, color: colors[2]),
              ],
            ),
            const SizedBox(width: AppSpacing.lg),
            const Expanded(
              child: Text('Where it went: Food · Transport · Home'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _trend() {
    final palette = Theme.of(context).extension<AppColors>()!;
    return AppCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: PairedBarChart(
          colorA: palette.income,
          colorB: palette.expense,
          groups: const [
            BarPair(label: 'Aug', a: 38000, b: 21000),
            BarPair(label: 'Sep', a: 40000, b: 25500),
            BarPair(label: 'Oct', a: 42000, b: 18350),
          ],
        ),
      ),
    );
  }

  Widget _tiles() {
    final modules = ModuleColors.of(context);
    Widget tile(IconData icon, Color color, String label, String value) =>
        Expanded(
          child: AppCard(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconTile(icon: icon, color: color),
                  IconTile.gap,
                  Text(label, style: Theme.of(context).textTheme.labelMedium),
                  Text(value, style: Theme.of(context).textTheme.titleSmall),
                ],
              ),
            ),
          ),
        );
    return Row(
      children: [
        tile(AppIcons.scheduled, modules.planning, 'Planning', '2 due'),
        const SizedBox(width: AppSpacing.sm),
        tile(AppIcons.debt, modules.people, 'Debts', '฿1,200'),
        const SizedBox(width: AppSpacing.sm),
        tile(AppIcons.category, modules.library, 'Library', '12'),
      ],
    );
  }

  Widget _recent() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      SectionHeader(
        title: 'Recent',
        actionLabel: 'See all',
        onAction: () {},
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xs,
          AppSpacing.lg,
          0,
          AppSpacing.xs,
        ),
      ),
      AppCard(
        margin: EdgeInsets.zero,
        child: Column(
          children: [
            TxRow(
              leading: const AppAvatar.icon(AppIcons.expense, size: 36),
              title: 'Chicken rice',
              amount: -120,
              walletLabel: 'Cash',
              category: 'Food',
            ),
            TxRow(
              leading: const AppAvatar.icon(AppIcons.income, size: 36),
              title: 'Salary',
              amount: 42000,
              walletLabel: 'KBank',
              category: 'Income',
            ),
          ],
        ),
      ),
    ],
  );

  Widget _stepper() => Center(
    child: StepperPill.month(
      value: _month,
      last: DateTime(2026, 10),
      onChanged: (m) => setState(() => _month = m),
    ),
  );

  Widget _stateChips() => Wrap(
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xs,
    children: [
      for (final s in _Data.values)
        AppChip(
          label: s.name,
          selected: _data == s,
          onTap: () => setState(() => _data = s),
        ),
      AppChip(
        label: 'refreshing (dim)',
        selected: _refreshing,
        onTap: () => setState(() => _refreshing = !_refreshing),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final home = DashboardPageBody(
      loading: _data == _Data.loading,
      error: _data == _Data.error ? 'Could not load' : null,
      isEmpty: _data != _Data.data,
      onRetry: _refresh,
      refreshing: _refreshing,
      snapshot: [_netWorth(), _attention()],
      period: _stepper(),
      kpis: [_kpis()],
      charts: [_donut(), _trend()],
      tiles: _tiles(),
      lists: [_recent()],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HubInApp(
          note:
              'Dashboard — home overview: period, KPIs, attention, charts, '
              'tiles, lists. One generic skeleton; the Chubi Home page fills '
              'the slots with its own blocks.',
          uses: [
            HubUse(
              wide: true,
              label:
                  'Chubi Home — domain example, the real kit widgets with '
                  'sample data (switch the data state to see skeleton / error)',
              page: 'Home (domain)',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _stateChips(),
                  const SizedBox(height: AppSpacing.sm),
                  _framed(home),
                ],
              ),
            ),
          ],
        ),
        HubPlayground(
          title: 'DashboardPageBody',
          note:
              'The template: snapshot → period → kpis → charts → tiles → '
              'lists in one ListView. Real options: which slots are filled, '
              'refreshing (both zones dim, the period bar never does), '
              'banner (stale-data warning), topInset / bottomInset.',
          controls: const [
            PlayBool('snapshot', initialValue: true),
            PlayBool('period', initialValue: true),
            PlayBool('kpis', initialValue: true),
            PlayBool('charts', initialValue: true),
            PlayBool('tiles', initialValue: true),
            PlayBool('lists', initialValue: true),
            PlayBool('refreshing'),
            PlayBool('banner'),
            PlayNum('bottomInset', min: 0, max: 96, step: 16, initialValue: 32),
          ],
          builder: (context, v) => _framed(
            DashboardPageBody(
              loading: false,
              error: null,
              isEmpty: false,
              onRetry: _refresh,
              refreshing: v<bool>('refreshing'),
              banner: v<bool>('banner') ? 'Could not refresh' : null,
              bottomInset: v<double>('bottomInset'),
              snapshot: v<bool>('snapshot')
                  ? [_netWorth(), _attention()]
                  : const [],
              period: v<bool>('period') ? _stepper() : null,
              kpis: v<bool>('kpis') ? [_kpis()] : const [],
              charts: v<bool>('charts') ? [_donut(), _trend()] : const [],
              tiles: v<bool>('tiles') ? _tiles() : null,
              lists: v<bool>('lists') ? [_recent()] : const [],
            ),
          ),
        ),
      ],
    );
  }
}
