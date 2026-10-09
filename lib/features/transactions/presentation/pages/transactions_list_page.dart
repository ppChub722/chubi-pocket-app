import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../categories/presentation/widgets/category_picker_sheet.dart';
import '../../../tags/domain/tag.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../widgets/quick_create_sheet.dart';
import '../widgets/transaction_tile.dart';

/// [custom] = one specific month ([_TransactionsListPageState._month]),
/// set when opened from the dashboard.
enum _Range { week, month, year, all, custom }

/// Wallet filter: everything, floating rows only, or one wallet.
sealed class _WalletFilter {
  const _WalletFilter();
}

class _AnyWallet extends _WalletFilter {
  const _AnyWallet();
}

class _NoWallet extends _WalletFilter {
  const _NoWallet();
}

class _OneWallet extends _WalletFilter {
  const _OneWallet(this.account);
  final Account account;
}

/// `/transactions` tab root (§9). Top bar comes from the shell. A search
/// box (note / category / wallet, contract §1), then one scrolling row of
/// dropdown chips — [ประเภท▾][ช่วงเวลา▾][กระเป๋า▾][หมวด▾][แท็ก▾] — plus
/// sort; rows grouped under "วันนี้ · −฿540" day headers.
///
/// [initialAccountId] pre-filters to one wallet ("ดูทั้งหมด ›" from a
/// wallet). [initialCategoryId] / [initialUncategorized] + [initialMonth]
/// open a dashboard slice ("เงินไปไหน" → one category in one month).
/// Picking a category always includes its subcategories.
class TransactionsListPage extends StatefulWidget {
  const TransactionsListPage({
    this.initialAccountId,
    this.initialCategoryId,
    this.initialUncategorized = false,
    this.initialMonth,
    this.title,
    this.embedded = false,
    this.lockedAccount,
    super.key,
  });

  /// Just the search · filters · list, no Scaffold / top bar — a tab of
  /// another page (a wallet's รายการ). Give it its own [TransactionsCubit].
  final bool embedded;

  /// Pinned to this wallet: no wallet filter, everything added from here
  /// presets it, and the list ends in an add tile.
  final Account? lockedAccount;

  final String? initialAccountId;
  final String? initialCategoryId;
  final bool initialUncategorized;

  /// Any day in the month to show; null = the default range.
  final DateTime? initialMonth;

  /// Set when pushed outside the tab root (a wallet's "ดูทั้งหมด") — the
  /// page then draws its own top bar.
  final String? title;

  @override
  State<TransactionsListPage> createState() => _TransactionsListPageState();
}

class _TransactionsListPageState extends State<TransactionsListPage> {
  TransactionType? _type;
  _Range _range = _Range.month;
  _WalletFilter _wallet = const _AnyWallet();
  Category? _category;

  /// "No category" filter — mutually exclusive with [_category].
  bool _uncategorized = false;
  Tag? _tag;
  String _q = '';
  Timer? _debounce;
  DateTime? _month;
  String _sort = 'date_desc';
  final _scroll = ScrollController();
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final p = _scroll.position;
      if (p.pixels > p.maxScrollExtent - 240) {
        context.read<TransactionsCubit>().loadMore();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final locked = widget.lockedAccount;
      if (locked != null) {
        _wallet = _OneWallet(locked);
        _range = _Range.all;
      }
      final id = widget.initialAccountId;
      if (id != null && locked == null) {
        final a = context
            .read<AccountsCubit>()
            .state
            .accounts
            .where((a) => a.id == id)
            .firstOrNull;
        if (a != null) {
          _wallet = _OneWallet(a);
          _range = _Range.all;
        }
      }
      final catId = widget.initialCategoryId;
      if (catId != null) {
        final c = context.read<CategoriesCubit>().byId(catId);
        if (c != null) {
          _category = c;
          _type = c.type == CategoryType.income
              ? TransactionType.income
              : TransactionType.expense;
        }
      }
      if (widget.initialUncategorized) {
        _uncategorized = true;
        _type = TransactionType.expense;
      }
      final m = widget.initialMonth;
      if (m != null) {
        _month = DateTime(m.year, m.month);
        _range = _Range.custom;
      }
      context.read<TagsCubit>().loadIfNeeded();
      setState(() {});
      _refetch();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || v.trim() == _q) return;
      _set(() => _q = v.trim());
    });
  }

  Future<void> _pickTag() async {
    final l = AppLocalizations.of(context)!;
    final tags = context.read<TagsCubit>().state.tags;
    final picked = await showOptionSheet<String>(
      context,
      title: l.transactionsFilterTag,
      selected: _tag?.id ?? '*',
      options: [
        SheetOption(value: '*', label: l.transactionsListFilterAll),
        for (final t in tags) SheetOption(value: t.id, label: t.name),
      ],
    );
    if (picked == null || !mounted) return;
    _set(
      () => _tag = picked == '*'
          ? null
          : tags.where((t) => t.id == picked).firstOrNull,
    );
  }

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  ({String? from, String? to}) _bounds() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return switch (_range) {
      _Range.week => (
        from: _ymd(today.subtract(Duration(days: today.weekday - 1))),
        to: _ymd(today.add(Duration(days: 7 - today.weekday))),
      ),
      _Range.month => (
        from: _ymd(DateTime(now.year, now.month, 1)),
        to: _ymd(DateTime(now.year, now.month + 1, 0)),
      ),
      _Range.year => (
        from: _ymd(DateTime(now.year, 1, 1)),
        to: _ymd(DateTime(now.year, 12, 31)),
      ),
      _Range.all => (from: null, to: null),
      _Range.custom => (
        from: _ymd(_month ?? DateTime(now.year, now.month)),
        to: _ymd(DateTime((_month ?? now).year, (_month ?? now).month + 1, 0)),
      ),
    };
  }

  Future<void> _refetch() async {
    final b = _bounds();
    await context.read<TransactionsCubit>().load(
      type: _type,
      categoryId: _category?.id,
      includeChildren: _category != null,
      uncategorized: _uncategorized,
      accountId: _wallet is _OneWallet
          ? (_wallet as _OneWallet).account.id
          : null,
      noWallet: _wallet is _NoWallet,
      q: _q,
      tagIds: [?_tag?.id],
      from: b.from,
      to: b.to,
      sort: _sort,
    );
  }

  void _set(VoidCallback change) {
    setState(change);
    _refetch();
  }

  bool get _filtered =>
      _type != null ||
      _range != _Range.month ||
      _wallet is! _AnyWallet ||
      _category != null ||
      _uncategorized ||
      _tag != null ||
      _q.isNotEmpty;

  void _clearFilters() {
    _search.clear();
    _set(() {
      _type = null;
      _range = _Range.month;
      _month = null;
      _wallet = const _AnyWallet();
      _category = null;
      _uncategorized = false;
      _tag = null;
      _q = '';
    });
  }

  Future<void> _pickWallet() async {
    final l = AppLocalizations.of(context)!;
    final accounts = context.read<AccountsCubit>().state.accounts;
    final current = switch (_wallet) {
      _AnyWallet() => '*',
      _NoWallet() => '-',
      _OneWallet(:final account) => account.id,
    };
    final picked = await showOptionSheet<String>(
      context,
      title: l.transactionsFilterAccount,
      selected: current,
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
    if (picked == null || !mounted) return;
    _set(
      () => _wallet = switch (picked) {
        '*' => const _AnyWallet(),
        '-' => const _NoWallet(),
        _ => _OneWallet(accounts.firstWhere((a) => a.id == picked)),
      },
    );
  }

  Future<void> _pickCategory() async {
    final r = await showCategoryPickerSheet(
      context: context,
      categories: context.read<CategoriesCubit>().state.categories,
      type: _type == TransactionType.income
          ? CategoryType.income
          : CategoryType.expense,
      selected: _category,
    );
    if (!mounted || r == null) return;
    _set(() {
      _category = r is CategoryPickerSelected ? r.category : null;
      _uncategorized = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final typeLabels = <TransactionType?, String>{
      null: l.transactionsListFilterAll,
      TransactionType.expense: l.transactionTypeExpense,
      TransactionType.income: l.transactionTypeIncome,
      TransactionType.transfer: l.transactionTypeTransfer,
    };
    final rangeLabels = {
      _Range.week: l.transactionsRangeWeek,
      _Range.month: l.transactionsRangeMonth,
      _Range.year: l.transactionsRangeYear,
      _Range.all: l.transactionsRangeAll,
      if (_month != null)
        _Range.custom: DateFormatter.monthYear(
          _month!,
          locale: Localizations.localeOf(context).toLanguageTag(),
        ),
    };
    final categoryEnabled =
        _type == TransactionType.expense || _type == TransactionType.income;
    final walletLabel = switch (_wallet) {
      _AnyWallet() => null,
      _NoWallet() => l.transactionFormAccountNone,
      _OneWallet(:final account) => account.name,
    };

    final locked = widget.lockedAccount;
    final content = Column(
      children: [
        AppSearchBar(
          controller: _search,
          onChanged: _onSearch,
          hint: l.transactionsSearchHint,
        ),
        FilterBar(
          chips: [
            OptionMenuAnchor<TransactionType?>(
              selected: _type,
              onSelected: (t) => _set(() {
                _type = t;
                // A category belongs to one type.
                _category = null;
                _uncategorized = false;
              }),
              options: [
                for (final e in typeLabels.entries)
                  SheetOption(value: e.key, label: e.value),
              ],
              builder: (context, toggle) => FilterDropdownChip(
                label: l.transactionsFilterType,
                valueLabel: _type == null ? null : typeLabels[_type],
                onTap: toggle,
              ),
            ),
            OptionMenuAnchor<_Range>(
              selected: _range,
              onSelected: (r) => _set(() => _range = r),
              options: [
                for (final e in rangeLabels.entries)
                  SheetOption(value: e.key, label: e.value),
              ],
              builder: (context, toggle) => FilterDropdownChip(
                label: l.transactionsFilterRange,
                valueLabel: rangeLabels[_range],
                active: _range != _Range.month,
                onTap: toggle,
              ),
            ),
            if (locked == null)
              FilterDropdownChip(
                label: l.transactionsFilterAccount,
                valueLabel: walletLabel,
                onTap: _pickWallet,
              ),
            if (categoryEnabled)
              FilterDropdownChip(
                label: l.transactionsFilterCategory,
                valueLabel: _uncategorized
                    ? l.homeUncategorized
                    : _category?.name,
                onTap: _pickCategory,
              ),
            FilterDropdownChip(
              label: l.transactionsFilterTag,
              valueLabel: _tag?.name,
              onTap: _pickTag,
            ),
          ],
          trailing: SortChip<String>(
            selected: _sort,
            onSelected: (s) => _set(() => _sort = s),
            options: [
              SortOption('date_desc', l.transactionsSortNewest),
              SortOption('date_asc', l.transactionsSortOldest),
              SortOption('amount_desc', l.transactionsSortAmountHigh),
              SortOption('amount_asc', l.transactionsSortAmountLow),
            ],
          ),
        ),
        Expanded(
          child: BlocBuilder<TransactionsCubit, TransactionsState>(
            builder: (context, state) => AsyncStateView(
              loading:
                  state.status == TransactionsStatus.initial ||
                  state.status == TransactionsStatus.loading,
              error: state.error,
              isEmpty: state.transactions.isEmpty,
              onRetry: _refetch,
              skeleton: ListView(
                children: [
                  for (var i = 0; i < 8; i++) const SkeletonListTile(),
                ],
              ),
              // Filters on → "no match" + clear; off → first-tx CTA.
              empty: EmptyView(
                icon: _filtered ? AppIcons.search : AppIcons.empty,
                title: _filtered
                    ? l.transactionsNoMatch
                    : l.transactionsEmptyAccountTitle,
                message: _filtered ? '' : l.transactionsListEmptyMessage,
                cta: _filtered
                    ? AppButton(
                        label: l.transactionsClearFilters,
                        variant: AppButtonVariant.tonal,
                        onPressed: _clearFilters,
                      )
                    : AddTile(
                        label: l.homeAddFirstTx,
                        // Same flow as the nav's +.
                        onTap: () =>
                            showQuickCreateSheet(context, account: locked),
                      ),
              ),
              builder: (context) => PullToRefresh(
                onRefresh: _refetch,
                child: _DayGroupedList(
                  transactions: state.transactions,
                  controller: _scroll,
                  byDate: _sort.startsWith('date'),
                  loadingMore: state.loadingMore,
                  hideAccount: _wallet is _OneWallet,
                  footer: locked == null
                      ? null
                      : AddTile(
                          label: l.navAddTransaction,
                          variant: AddTileVariant.row,
                          onTap: () =>
                              showQuickCreateSheet(context, account: locked),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
    if (widget.embedded) return content;
    return Scaffold(
      // Tab root (no title passed) → the tab's own bar; pushed → back + title.
      // Nothing scrolls under it here (search + filters are pinned), so the
      // body doesn't extend behind it.
      appBar: AppTopBar(
        title: widget.title ?? l.navTransactions,
        showBack: widget.title != null,
      ),
      // Tab switch animates the body only — the bar stays put.
      body: TabSwitchBody(child: content),
    );
  }
}

/// Rows under "วันนี้ · −฿540" headers (net of the day's income/expense).
/// When sorted by amount the list is flat — day headers would repeat.
class _DayGroupedList extends StatelessWidget {
  const _DayGroupedList({
    required this.transactions,
    required this.controller,
    required this.byDate,
    required this.loadingMore,
    required this.hideAccount,
    this.footer,
  });

  final List<Transaction> transactions;
  final ScrollController controller;
  final bool byDate;
  final bool loadingMore;
  final bool hideAccount;

  /// After the last row (once every page is in).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final children = <Widget>[];
    if (byDate) {
      final days = <String, List<Transaction>>{};
      for (final t in transactions) {
        days.putIfAbsent(t.date, () => []).add(t);
      }
      for (final e in days.entries) {
        final d = DateFormatter.parseDay(e.key);
        final net = e.value
            .where((t) => t.type != TransactionType.transfer)
            .fold<double>(0, (a, t) => a + t.signedAmount);
        children.add(
          DateGroupHeader(
            label: d == null
                ? e.key
                : DateFormatter.friendly(
                    d,
                    today: l.commonToday,
                    yesterday: l.commonYesterday,
                    locale: Localizations.localeOf(context).languageCode,
                  ),
            total: net,
          ),
        );
        for (final t in e.value) {
          children.add(
            TransactionTile(transaction: t, showAccount: !hideAccount),
          );
        }
      }
    } else {
      for (final t in transactions) {
        children.add(
          TransactionTile(
            transaction: t,
            showAccount: !hideAccount,
            showDate: true,
          ),
        );
      }
    }
    // Next page in flight → row-shaped skeletons, never a spinner (§8.5).
    if (loadingMore) {
      children.addAll(const [SkeletonListTile(), SkeletonListTile()]);
    } else if (footer != null) {
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            0,
          ),
          child: footer,
        ),
      );
    }
    return ListView(
      controller: controller,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: AppSpacing.md, bottom: 96),
      children: children,
    );
  }
}
