import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../../tags/presentation/widgets/tag_picker_sheet.dart';
import '../../domain/transaction_type.dart';
import '../tx_list_filters.dart';

/// The transactions list's filters, in a side sheet from the right (owner
/// 2026-10-10): ประเภท · ช่วงเวลา · กระเป๋า · หมวด · แท็ก · เรียงตาม, then
/// [ล้าง] [ใช้ตัวกรอง]. Resolves the new filters, or null when closed
/// without applying. [base] is what ล้าง goes back to (how the list
/// opened); [walletLocked] hides the wallet section (a wallet's own list).
Future<TxFilters?> showTxFilterSheet(
  BuildContext context, {
  required TxFilters current,
  required TxFilters base,
  bool walletLocked = false,
}) => showSideSheet<TxFilters>(
  context,
  builder: (_) =>
      _TxFilterSheet(initial: current, base: base, walletLocked: walletLocked),
);

/// A category belongs to one type — does [c] fit [type]?
bool categoryFitsType(Category c, TransactionType? type) => switch (type) {
  null => true,
  TransactionType.income => c.type == CategoryType.income,
  TransactionType.expense => c.type == CategoryType.expense,
  TransactionType.transfer => false,
};

/// The category choice: ทั้งหมด (null, false) · ไม่ระบุหมวด (null, true) ·
/// a category (with its sub-categories). Null when dismissed.
Future<({Category? category, bool uncategorized})?> pickCategoryFilter(
  BuildContext context, {
  required TransactionType? type,
  required Category? selected,
  required bool uncategorized,
}) async {
  final l = AppLocalizations.of(context)!;
  final pool = context
      .read<CategoriesCubit>()
      .state
      .categories
      .where((c) => !c.isSystem && categoryFitsType(c, type))
      .toList();
  int order(Category a, Category b) => a.sortOrder.compareTo(b.sortOrder);
  final roots = pool.where((c) => c.parentId == null).toList()..sort(order);
  final byId = {for (final c in pool) c.id: c};
  String typeOf(Category c) => c.type == CategoryType.income
      ? l.transactionTypeIncome
      : l.transactionTypeExpense;
  final picked = await showOptionSheet<String>(
    context,
    title: l.transactionsFilterCategory,
    searchable: pool.length > 8,
    selected: uncategorized ? '-' : selected?.id ?? '*',
    options: [
      SheetOption(value: '*', label: l.transactionsListFilterAll),
      SheetOption(
        value: '-',
        label: l.homeUncategorized,
        leading: const Icon(AppIcons.noCategory),
      ),
      for (final root in roots) ...[
        SheetOption(
          value: root.id,
          label: root.name,
          subtitle: type == null ? typeOf(root) : null,
        ),
        for (final child
            in pool.where((c) => c.parentId == root.id).toList()..sort(order))
          SheetOption(value: child.id, label: child.name, subtitle: root.name),
      ],
    ],
  );
  if (picked == null) return null;
  return (category: byId[picked], uncategorized: picked == '-');
}

/// The wallet choice. Null when dismissed.
Future<TxWalletFilter?> pickWalletFilter(
  BuildContext context, {
  required TxWalletFilter selected,
}) async {
  final l = AppLocalizations.of(context)!;
  final accounts = context.read<AccountsCubit>().state.accounts;
  final picked = await showOptionSheet<String>(
    context,
    title: l.transactionsFilterAccount,
    selected: switch (selected) {
      TxAnyWallet() => '*',
      TxNoWallet() => '-',
      TxOneWallet(:final account) => account.id,
    },
    options: [
      SheetOption(value: '*', label: l.transactionsListFilterAll),
      SheetOption(
        value: '-',
        label: l.transactionFormAccountNone,
        leading: const Icon(AppIcons.noWallet),
      ),
      for (final a in accounts)
        SheetOption(value: a.id, label: a.name, leading: Icon(a.type.icon)),
    ],
  );
  return switch (picked) {
    null => null,
    '*' => const TxAnyWallet(),
    '-' => const TxNoWallet(),
    _ => TxOneWallet(accounts.firstWhere((a) => a.id == picked)),
  };
}

/// Labels the list and the sheet share.
String txTypeLabel(AppLocalizations l, TransactionType? t) => switch (t) {
  null => l.transactionsListFilterAll,
  TransactionType.expense => l.transactionTypeExpense,
  TransactionType.income => l.transactionTypeIncome,
  TransactionType.transfer => l.transactionTypeTransfer,
};

String txSortLabel(AppLocalizations l, String sort) => switch (sort) {
  'date_asc' => l.transactionsSortOldest,
  'amount_desc' => l.transactionsSortAmountHigh,
  'amount_asc' => l.transactionsSortAmountLow,
  _ => l.transactionsSortNewest,
};

String? txWalletLabel(AppLocalizations l, TxWalletFilter w) => switch (w) {
  TxAnyWallet() => null,
  TxNoWallet() => l.transactionFormAccountNone,
  TxOneWallet(:final account) => account.name,
};

class _TxFilterSheet extends StatefulWidget {
  const _TxFilterSheet({
    required this.initial,
    required this.base,
    required this.walletLocked,
  });

  final TxFilters initial;
  final TxFilters base;
  final bool walletLocked;

  @override
  State<_TxFilterSheet> createState() => _TxFilterSheetState();
}

class _TxFilterSheetState extends State<_TxFilterSheet> {
  late TxFilters _f = widget.initial;

  void _set(TxFilters f) => setState(() => _f = f);

  Future<void> _pickPeriod(TxPeriodKind kind) async {
    if (kind != TxPeriodKind.custom) {
      // Switching unit keeps the place: the new period holds the old one's
      // first day (today for ทั้งหมด).
      final anchor = _f.period.kind == TxPeriodKind.all
          ? DateTime.now()
          : _f.period.start;
      _set(_f.copyWith(period: TxPeriod.of(kind, anchor)));
      return;
    }
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: _f.period.kind == TxPeriodKind.all
          ? null
          : DateTimeRange(start: _f.period.start, end: _f.period.last!),
    );
    if (range == null || !mounted) return;
    _set(_f.copyWith(period: TxPeriod.custom(range.start, range.end)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final tagNames = _f.tags.map((t) => '#${t.name}').join(' ');
    return SideSheetScaffold(
      title: l.transactionsFiltersTitle,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SideSheetSection(
            title: l.transactionsFilterType,
            child: _Choices<TransactionType?>(
              values: const [
                null,
                TransactionType.expense,
                TransactionType.income,
                TransactionType.transfer,
              ],
              selected: _f.type,
              label: (t) => txTypeLabel(l, t),
              onSelected: (t) {
                final keep =
                    _f.category == null || categoryFitsType(_f.category!, t);
                _set(
                  _f.copyWith(
                    type: t,
                    clearType: t == null,
                    clearCategory: !keep,
                  ),
                );
              },
            ),
          ),
          SideSheetSection(
            title: l.transactionsFilterRange,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Choices<TxPeriodKind>(
                  values: TxPeriodKind.values,
                  selected: _f.period.kind,
                  label: (k) => switch (k) {
                    TxPeriodKind.month => l.txPeriodMonth,
                    TxPeriodKind.week => l.txPeriodWeek,
                    TxPeriodKind.year => l.txPeriodYear,
                    TxPeriodKind.all => l.transactionsRangeAll,
                    TxPeriodKind.custom => l.txPeriodCustom,
                  },
                  onSelected: _pickPeriod,
                  // Picking กำหนดเอง again re-opens the range picker.
                  reselect: (k) => k == TxPeriodKind.custom,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  _f.period.label(context),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          if (!widget.walletLocked)
            SideSheetSection(
              title: l.transactionsFilterAccount,
              child: PickerTile(
                label: l.transactionsFilterAccount,
                value: txWalletLabel(l, _f.wallet),
                placeholder: l.transactionsListFilterAll,
                onTap: () async {
                  final w = await pickWalletFilter(
                    context,
                    selected: _f.wallet,
                  );
                  if (w != null && mounted) _set(_f.copyWith(wallet: w));
                },
              ),
            ),
          SideSheetSection(
            title: l.transactionsFilterCategory,
            child: PickerTile(
              label: l.transactionsFilterCategory,
              value: _f.uncategorized ? l.homeUncategorized : _f.category?.name,
              placeholder: l.transactionsListFilterAll,
              onTap: () async {
                final r = await pickCategoryFilter(
                  context,
                  type: _f.type,
                  selected: _f.category,
                  uncategorized: _f.uncategorized,
                );
                if (r == null || !mounted) return;
                _set(
                  _f.copyWith(
                    category: r.category,
                    clearCategory: r.category == null,
                    uncategorized: r.uncategorized,
                  ),
                );
              },
            ),
          ),
          SideSheetSection(
            title: l.transactionsFilterTag,
            child: PickerTile(
              label: l.transactionsFilterTag,
              value: tagNames.isEmpty ? null : tagNames,
              placeholder: l.transactionsListFilterAll,
              onTap: () async {
                final tagsCubit = context.read<TagsCubit>();
                final ids = await showTagPickerSheet(
                  context,
                  selected: {for (final t in _f.tags) t.id},
                  title: l.transactionsFilterTag,
                  allowCreate: false,
                );
                if (ids == null || !mounted) return;
                final all = tagsCubit.state.tags;
                _set(
                  _f.copyWith(
                    tags: [
                      for (final t in all)
                        if (ids.contains(t.id)) t,
                    ],
                  ),
                );
              },
            ),
          ),
          SideSheetSection(
            title: l.transactionsSortBy,
            child: _Choices<String>(
              values: const [
                'date_desc',
                'date_asc',
                'amount_desc',
                'amount_asc',
              ],
              selected: _f.sort,
              label: (s) => txSortLabel(l, s),
              onSelected: (s) => _set(_f.copyWith(sort: s)),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
      footer: Row(
        children: [
          Expanded(
            child: AppButton(
              label: l.commonClear,
              variant: AppButtonVariant.outlined,
              expand: true,
              // Back to how the list opened (a wallet's list keeps its
              // wallet).
              onPressed: () => _set(widget.base),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 2,
            child: AppButton(
              label: l.transactionsFiltersApply,
              expand: true,
              onPressed: () => Navigator.of(context).pop(_f),
            ),
          ),
        ],
      ),
    );
  }
}

/// A row of choice chips — one value selected.
class _Choices<T> extends StatelessWidget {
  const _Choices({
    required this.values,
    required this.selected,
    required this.label,
    required this.onSelected,
    this.reselect,
  });

  final List<T> values;
  final T selected;
  final String Function(T) label;
  final ValueChanged<T> onSelected;

  /// Values that fire [onSelected] again when tapped while selected.
  final bool Function(T)? reselect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final v in values)
          ChoiceChip(
            label: Text(label(v)),
            selected: v == selected,
            showCheckmark: false,
            onSelected: (_) {
              if (v != selected || (reselect?.call(v) ?? false)) {
                onSelected(v);
              }
            },
          ),
      ],
    );
  }
}
