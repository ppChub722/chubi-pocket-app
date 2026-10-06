import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/ui.dart';
import '../../data/transactions_repository.dart';
import '../../domain/transactions_summary.dart';

/// Period window for [PeriodSummaryCard].
enum SummaryPeriod { week, month, year, all }

extension SummaryPeriodRange on SummaryPeriod {
  /// Inclusive `YYYY-MM-DD` range for this period, relative to [now].
  ({String from, String to}) rangeFrom(DateTime now) {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final today = DateTime(now.year, now.month, now.day);
    return switch (this) {
      SummaryPeriod.week => (
          from: fmt(today.subtract(Duration(days: today.weekday - 1))),
          to: fmt(today.add(Duration(days: 7 - today.weekday))),
        ),
      SummaryPeriod.month => (
          from: fmt(DateTime(now.year, now.month, 1)),
          to: fmt(DateTime(now.year, now.month + 1, 0)),
        ),
      SummaryPeriod.year => (
          from: fmt(DateTime(now.year, 1, 1)),
          to: fmt(DateTime(now.year, 12, 31)),
        ),
      // The summary API needs a range; a far-past start = "everything".
      SummaryPeriod.all => (from: '1970-01-01', to: fmt(today)),
    };
  }
}

/// "สรุป" card — period chips (สัปดาห์ / เดือน / ปี / ทั้งหมด) + income ·
/// expense · net + transaction count. One widget for the dashboard
/// (all wallets) and account detail ([accountId]). Fetches on its own via
/// [TransactionsRepository.summary]; amounts respect the 👁 toggle.
class PeriodSummaryCard extends StatefulWidget {
  const PeriodSummaryCard({
    this.accountId,
    this.initial = SummaryPeriod.month,
    this.title,
    super.key,
  });

  /// Limit to one wallet; null = everything the user can see.
  final String? accountId;
  final SummaryPeriod initial;

  /// Defaults to the localized "สรุป".
  final String? title;

  @override
  State<PeriodSummaryCard> createState() => _PeriodSummaryCardState();
}

class _PeriodSummaryCardState extends State<PeriodSummaryCard> {
  late SummaryPeriod _period = widget.initial;
  late Future<TransactionsSummary> _future = _fetch();

  Future<TransactionsSummary> _fetch() {
    final r = _period.rangeFrom(DateTime.now());
    return context.read<TransactionsRepository>().summary(
          from: r.from,
          to: r.to,
          accountId: widget.accountId,
        );
  }

  @override
  void didUpdateWidget(PeriodSummaryCard old) {
    super.didUpdateWidget(old);
    if (old.accountId != widget.accountId) _future = _fetch();
  }

  void _select(SummaryPeriod p) {
    if (p == _period) return;
    setState(() {
      _period = p;
      _future = _fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final labels = {
      SummaryPeriod.week: l.transactionsRangeWeek,
      SummaryPeriod.month: l.transactionsRangeMonth,
      SummaryPeriod.year: l.transactionsRangeYear,
      SummaryPeriod.all: l.transactionsRangeAll,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(widget.title ?? l.accountDetailSummaryTitle,
                      style: textTheme.titleMedium),
                ),
                OptionMenuAnchor<SummaryPeriod>(
                  selected: _period,
                  onSelected: _select,
                  options: [
                    for (final p in SummaryPeriod.values)
                      SheetOption(value: p, label: labels[p]!),
                  ],
                  builder: (context, toggle) => FilterDropdownChip(
                    label: labels[_period]!,
                    active: true,
                    onTap: toggle,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            FutureBuilder<TransactionsSummary>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Row(
                    children: [
                      Expanded(child: SkeletonBox(height: 36)),
                      SizedBox(width: AppSpacing.md),
                      Expanded(child: SkeletonBox(height: 36)),
                      SizedBox(width: AppSpacing.md),
                      Expanded(child: SkeletonBox(height: 36)),
                    ],
                  );
                }
                if (snap.hasError || snap.data == null) {
                  return Row(
                    children: [
                      Expanded(
                        child: Text(l.errorUnknownMessage,
                            style: textTheme.bodySmall
                                ?.copyWith(color: scheme.error)),
                      ),
                      AppButton(
                        label: l.commonRetry,
                        variant: AppButtonVariant.text,
                        onPressed: () => setState(() => _future = _fetch()),
                      ),
                    ],
                  );
                }
                final s = snap.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SummaryStats(stats: [
                      SummaryStat(
                          label: l.accountDetailSummaryIncome,
                          amount: s.totalIncome,
                          tone: MoneyTone.income),
                      SummaryStat(
                          label: l.accountDetailSummaryExpense,
                          amount: s.totalExpense,
                          tone: MoneyTone.expense),
                      SummaryStat(
                          label: l.accountDetailSummaryNet,
                          amount: s.net,
                          tone: MoneyTone.signed),
                    ]),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      l.accountDetailSummaryTransactions(s.transactionCount),
                      style: textTheme.bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
