import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/empty_view.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../widgets/category_picker_sheet.dart';
import '../../../../shared/icon_maker/icon_registry.dart';

/// Global transactions list, routed at `/transactions` (entry point: the
/// More menu's "Transactions" item, formerly a stub).
///
/// Renders the user's whole book filtered by:
/// - **Type chip row**: All / Expense / Income / Transfer.
/// - **Date range chip row**: Week / Month / Year / All — same component
///   pattern as the account-detail summary, but shipped inline.
///
/// Rows are date-grouped into sections ("Today" / "Yesterday" / `YYYY-MM-DD`).
/// Pagination via scroll-near-end → cubit's `loadMore`.
class TransactionsListPage extends StatefulWidget {
  const TransactionsListPage({super.key});

  @override
  State<TransactionsListPage> createState() => _TransactionsListPageState();
}

enum _TypeFilter { all, expense, income, transfer }

extension on _TypeFilter {
  TransactionType? toType() {
    switch (this) {
      case _TypeFilter.all:
        return null;
      case _TypeFilter.expense:
        return TransactionType.expense;
      case _TypeFilter.income:
        return TransactionType.income;
      case _TypeFilter.transfer:
        return TransactionType.transfer;
    }
  }
}

enum _RangeFilter { week, month, year, all }

extension on _RangeFilter {
  ({String? from, String? to}) toRange(DateTime now) {
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final today = DateTime(now.year, now.month, now.day);
    switch (this) {
      case _RangeFilter.week:
        final monday = today.subtract(Duration(days: today.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return (from: fmt(monday), to: fmt(sunday));
      case _RangeFilter.month:
        return (
          from: fmt(DateTime(now.year, now.month, 1)),
          to: fmt(DateTime(now.year, now.month + 1, 0)),
        );
      case _RangeFilter.year:
        return (
          from: fmt(DateTime(now.year, 1, 1)),
          to: fmt(DateTime(now.year, 12, 31)),
        );
      case _RangeFilter.all:
        return (from: null, to: null);
    }
  }
}

class _TransactionsListPageState extends State<TransactionsListPage> {
  _TypeFilter _typeFilter = _TypeFilter.all;
  _RangeFilter _rangeFilter = _RangeFilter.month;

  /// Selected category filter. Only shown when [_typeFilter] is
  /// `expense` or `income` — `all` and `transfer` hide the chip
  /// since a category implies a type and transfers use system
  /// auto-assigned categories the user can't pick.
  Category? _categoryFilter;

  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_maybeLoadMore);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _refetch();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_maybeLoadMore);
    _scrollController.dispose();
    super.dispose();
  }

  void _maybeLoadMore() {
    final pos = _scrollController.position;
    if (pos.pixels > pos.maxScrollExtent - 240) {
      context.read<TransactionsCubit>().loadMore();
    }
  }

  void _refetch() {
    final r = _rangeFilter.toRange(DateTime.now());
    context.read<TransactionsCubit>().load(
          type: _typeFilter.toType(),
          categoryId: _categoryFilter?.id,
          from: r.from,
          to: r.to,
        );
  }

  void _setType(_TypeFilter f) {
    if (_typeFilter == f) return;
    setState(() {
      _typeFilter = f;
      // Clear category filter on type change — a category belongs to
      // exactly one type, so the previous selection is almost certainly
      // invalid for the new type.
      _categoryFilter = null;
    });
    _refetch();
  }

  void _setRange(_RangeFilter f) {
    if (_rangeFilter == f) return;
    setState(() => _rangeFilter = f);
    _refetch();
  }

  Future<void> _pickCategory() async {
    // Only callable when type is expense or income — see [_FilterBar].
    final categoryType = _typeFilter == _TypeFilter.income
        ? CategoryType.income
        : CategoryType.expense;
    final all = context.read<CategoriesCubit>().state.categories;
    final result = await showCategoryPickerSheet(
      context: context,
      categories: all,
      type: categoryType,
      selected: _categoryFilter,
    );
    if (!mounted || result == null) return;
    setState(() {
      _categoryFilter =
          result is CategoryPickerSelected ? result.category : null;
    });
    _refetch();
  }

  void _clearCategoryFilter() {
    if (_categoryFilter == null) return;
    setState(() => _categoryFilter = null);
    _refetch();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        title: Text(l.transactionsListTitle),
      ),
      body: Column(
        children: [
          _FilterBar(
            typeFilter: _typeFilter,
            rangeFilter: _rangeFilter,
            categoryFilter: _categoryFilter,
            onTypeChanged: _setType,
            onRangeChanged: _setRange,
            onPickCategory: _pickCategory,
            onClearCategory: _clearCategoryFilter,
          ),
          Expanded(
            child: BlocBuilder<TransactionsCubit, TransactionsState>(
              builder: (context, state) {
                final isFirstLoad =
                    state.status == TransactionsStatus.loading &&
                        state.transactions.isEmpty;
                if (isFirstLoad) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.status == TransactionsStatus.error &&
                    state.transactions.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            state.errorMessage ?? l.commonRemove,
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          FilledButton(
                            onPressed: _refetch,
                            child: Text(l.transactionsListRetry),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                if (state.transactions.isEmpty) {
                  return EmptyView(
                    icon: Icons.receipt_long_outlined,
                    title: l.transactionsEmptyAccountTitle,
                    message: l.transactionsListEmptyMessage,
                  );
                }
                return _DateGroupedList(
                  transactions: state.transactions,
                  scrollController: _scrollController,
                  showLoadingFooter:
                      state.status == TransactionsStatus.loading,
                  hasMore: state.hasMore,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.typeFilter,
    required this.rangeFilter,
    required this.categoryFilter,
    required this.onTypeChanged,
    required this.onRangeChanged,
    required this.onPickCategory,
    required this.onClearCategory,
  });

  final _TypeFilter typeFilter;
  final _RangeFilter rangeFilter;
  final Category? categoryFilter;
  final ValueChanged<_TypeFilter> onTypeChanged;
  final ValueChanged<_RangeFilter> onRangeChanged;
  final VoidCallback onPickCategory;
  final VoidCallback onClearCategory;

  /// Category filter only makes sense for expense / income.
  /// "All" — multiple types in play, category implies a type.
  /// "Transfer" — uses system Transfer In/Out, no user pick.
  bool get _categoryRowVisible =>
      typeFilter == _TypeFilter.expense || typeFilter == _TypeFilter.income;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.md, AppSpacing.lg, AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                _typeChip(l.transactionsListFilterAll, _TypeFilter.all),
                _typeChip(l.transactionTypeExpense, _TypeFilter.expense),
                _typeChip(l.transactionTypeIncome, _TypeFilter.income),
                _typeChip(l.transactionTypeTransfer, _TypeFilter.transfer),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Wrap(
              spacing: AppSpacing.sm,
              children: [
                _rangeChip(l.transactionsRangeWeek, _RangeFilter.week),
                _rangeChip(l.transactionsRangeMonth, _RangeFilter.month),
                _rangeChip(l.transactionsRangeYear, _RangeFilter.year),
                _rangeChip(l.transactionsRangeAll, _RangeFilter.all),
              ],
            ),
          ),
          if (_categoryRowVisible) ...[
            const SizedBox(height: AppSpacing.sm),
            _categoryChip(context, l),
          ],
        ],
      ),
    );
  }

  Widget _typeChip(String label, _TypeFilter f) {
    return ChoiceChip(
      label: Text(label),
      selected: typeFilter == f,
      onSelected: (_) => onTypeChanged(f),
    );
  }

  Widget _rangeChip(String label, _RangeFilter f) {
    return ChoiceChip(
      label: Text(label),
      selected: rangeFilter == f,
      onSelected: (_) => onRangeChanged(f),
    );
  }

  /// Single-chip "filter by category" surface. When nothing is picked,
  /// the chip shows "All categories" and tapping opens the picker. When
  /// a category is picked, the chip's avatar carries the category color
  /// + icon and a trailing × clears the filter.
  Widget _categoryChip(BuildContext context, AppLocalizations l) {
    if (categoryFilter == null) {
      return ActionChip(
        avatar: const Icon(Icons.tune, size: 18),
        label: Text(l.transactionsListFilterCategoryAll),
        onPressed: onPickCategory,
      );
    }
    return InputChip(
      avatar: CircleAvatar(
        radius: 12,
        backgroundColor: categoryFilter!.iconCode?.resolvedBgColor ?? Colors.grey,
        child: Icon(
          IconRegistry.get(categoryFilter!.iconCode?.icon, fallback: Icons.category_outlined),
          color: Colors.white,
          size: 14,
        ),
      ),
      label: Text(categoryFilter!.name),
      onPressed: onPickCategory,
      onDeleted: onClearCategory,
      deleteIcon: const Icon(Icons.close, size: 16),
    );
  }
}

/// Groups [transactions] by date and renders a header per date plus
/// rows. Assumes the input is already date-desc sorted (server default).
class _DateGroupedList extends StatelessWidget {
  const _DateGroupedList({
    required this.transactions,
    required this.scrollController,
    required this.showLoadingFooter,
    required this.hasMore,
  });

  final List<Transaction> transactions;
  final ScrollController scrollController;
  final bool showLoadingFooter;
  final bool hasMore;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDate(transactions);
    final l = AppLocalizations.of(context)!;
    final today = _ymd(DateTime.now());
    final yesterday = _ymd(DateTime.now().subtract(const Duration(days: 1)));

    final items = <_ListEntry>[];
    for (final entry in groups.entries) {
      items.add(_HeaderEntry(
        label: _humanLabel(entry.key, today, yesterday, l),
      ));
      for (final tx in entry.value) {
        items.add(_RowEntry(tx: tx));
      }
    }

    return ListView.builder(
      controller: scrollController,
      padding: const EdgeInsets.only(
          left: AppSpacing.lg, right: AppSpacing.lg, bottom: AppSpacing.huge),
      itemCount: items.length + (showLoadingFooter || hasMore ? 1 : 0),
      itemBuilder: (context, idx) {
        if (idx >= items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Center(
              child: showLoadingFooter
                  ? const CircularProgressIndicator()
                  : const SizedBox.shrink(),
            ),
          );
        }
        final entry = items[idx];
        if (entry is _HeaderEntry) {
          return _SectionHeader(label: entry.label);
        }
        if (entry is _RowEntry) return _Row(tx: entry.tx);
        return const SizedBox.shrink();
      },
    );
  }

  static Map<String, List<Transaction>> _groupByDate(List<Transaction> txs) {
    final out = <String, List<Transaction>>{};
    for (final t in txs) {
      out.putIfAbsent(t.date, () => []).add(t);
    }
    return out;
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  static String _humanLabel(
    String date,
    String today,
    String yesterday,
    AppLocalizations l,
  ) {
    if (date == today) return l.transactionsListDateToday;
    if (date == yesterday) return l.transactionsListDateYesterday;
    return date;
  }
}

sealed class _ListEntry {}

class _HeaderEntry extends _ListEntry {
  _HeaderEntry({required this.label});
  final String label;
}

class _RowEntry extends _ListEntry {
  _RowEntry({required this.tx});
  final Transaction tx;
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          0, AppSpacing.md, 0, AppSpacing.xs),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.tx});
  final Transaction tx;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final signed = tx.signedAmount;
    final color = signed > 0 ? Colors.green.shade400 : scheme.error;
    final sign = signed > 0 ? '+' : (signed < 0 ? '−' : '');
    final categoryName = tx.category?.name ?? '';
    final accountName = tx.account?.name ?? '';

    final cubit = context.watch<CategoriesCubit>();
    final cat = tx.category != null ? cubit.byId(tx.category!.id) : null;
    final iconData = IconRegistry.get(cat?.iconCode?.icon, fallback: _iconForType(tx.type));
    final fallbackColor = switch (tx.type) {
      TransactionType.expense => scheme.error,
      TransactionType.income => Colors.green.shade400,
      _ => scheme.onSurfaceVariant,
    };
    final iconColor = cat?.iconCode?.accentColor ?? fallbackColor;

    return InkWell(
      onTap: () => context.push('/transactions/${tx.id}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: iconColor.withValues(alpha: 0.18),
              child: Icon(iconData, size: 18, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    categoryName.isNotEmpty
                        ? categoryName
                        : (tx.note ?? '—'),
                    style: Theme.of(context).textTheme.bodyMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          accountName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (tx.tags.isNotEmpty) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Icon(Icons.sell_outlined,
                            size: 12, color: scheme.onSurfaceVariant),
                        const SizedBox(width: 2),
                        Text(
                          '${tx.tags.length}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            Text(
              '$sign${CurrencyFormatter.format(tx.amount)}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

IconData _iconForType(TransactionType t) {
  return switch (t) {
    TransactionType.expense => Icons.remove,
    TransactionType.income => Icons.add,
    TransactionType.transfer => Icons.swap_horiz,
  };
}
