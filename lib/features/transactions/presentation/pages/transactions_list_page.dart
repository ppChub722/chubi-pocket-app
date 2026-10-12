import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../categories/domain/category.dart';
import '../../../categories/domain/category_type.dart';
import '../../data/transactions_repository.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../tx_list_filters.dart';
import '../widgets/quick_create_sheet.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/tx_filter_sheet.dart';
import '../widgets/tx_period_pill.dart';

/// `/transactions` (owner 2026-10-10 redesign):
///
/// ```
///        ‹  ตุลาคม 2026 ▾  ›          the date filter: ‹ › / swipe step
///                                      one unit, the label opens the
///                                      period sheet (วัน…กำหนดเอง)
///  [ รายรับ · รายจ่าย · คงเหลือ ]        totals of the whole filtered set
///  [🔍 ค้นหา…                    ]      full width
///  [⚙ ตัวกรอง •n]      [⇅ ใหม่สุด ▾]    → right side sheet · the sort
///  (รายจ่าย ✕) (KBank ✕) (#ทริป ✕)      the active filters, wrapping
///  วันนี้                    −฿540
///  rows (2 lines: title · category · wallet · #tags)
/// ```
///
/// Everything above the rows scrolls with them, so the list keeps the
/// screen. The same page is a wallet's รายการ tab ([lockedAccount], no
/// wallet filter, this month to start) and the dashboard drill-down pages.
///
/// [initialCategoryId] / [initialUncategorized] + [initialMonth] open a
/// dashboard slice ("เงินไปไหน" → one category in one month).
/// Picking a category always includes its sub-categories.
class TransactionsListPage extends StatefulWidget {
  const TransactionsListPage({
    this.initialCategoryId,
    this.initialUncategorized = false,
    this.initialMonth,
    this.initialCategoryName,
    this.initialCategoryType,
    this.title,
    this.embedded = false,
    this.lockedAccount,
    super.key,
  });

  /// Just the list, no Scaffold / top bar — a tab of another page (a
  /// wallet's รายการ). Give it its own [TransactionsCubit].
  final bool embedded;

  /// Pinned to this wallet: no wallet filter, everything added from here
  /// presets it, and the list ends in an add tile.
  final Account? lockedAccount;

  final String? initialCategoryId;

  /// The drill-down category's name and type, when the caller knows them
  /// (the list itself is the only call this page makes). Without a name the
  /// chip takes it from the first row of that category.
  // The dashboard drill-down route passes both (the slice's label and
  // expense), so the chip never waits on the categories cache.
  final String? initialCategoryName;
  final CategoryType? initialCategoryType;
  final bool initialUncategorized;

  /// Any day in the month to show; null = the current month.
  final DateTime? initialMonth;

  /// Set when pushed outside the tab root (a wallet's "ดูทั้งหมด") — the
  /// page then draws its own top bar.
  final String? title;

  @override
  State<TransactionsListPage> createState() => _TransactionsListPageState();
}

class _TransactionsListPageState extends State<TransactionsListPage>
    implements ShellSwipeHandler {
  TxFilters _f = TxFilters(period: TxPeriod.month(DateTime.now()));

  /// How the page opened — what ล้าง goes back to, and what "filtered" is
  /// measured against (a wallet's list starts on its wallet).
  late TxFilters _base = _f;
  String _q = '';
  Timer? _debounce;
  final _search = TextEditingController();
  Map<ShellTab, ShellSwipeHandler>? _swipeHandlers;

  /// The transactions tab's own root — the only place the sideways swipe
  /// steps the period (elsewhere it belongs to the wallet tabs / the shell).
  bool get _isTabRoot =>
      !widget.embedded && widget.title == null && widget.lockedAccount == null;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var f = _f;
      final locked = widget.lockedAccount;
      // A wallet's รายการ tab opens at this month too (owner 2026-10-10).
      if (locked != null) f = f.copyWith(wallet: TxOneWallet(locked));
      final catId = widget.initialCategoryId;
      if (catId != null) {
        final t = widget.initialCategoryType;
        f = f.copyWith(
          category: Category(
            id: catId,
            name: widget.initialCategoryName ?? '',
            type: t ?? CategoryType.expense,
          ),
          type: switch (t) {
            null => null,
            CategoryType.income => TransactionType.income,
            _ => TransactionType.expense,
          },
        );
      }
      if (widget.initialUncategorized) {
        f = f.copyWith(uncategorized: true, type: TransactionType.expense);
      }
      final m = widget.initialMonth;
      if (m != null) f = f.copyWith(period: TxPeriod.month(m));
      setState(() => _f = _base = f);
      _refetch();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isTabRoot) {
      _swipeHandlers = ShellSwipeScope.maybeOf(context)
        ?..[ShellTab.transactions] = this;
    }
  }

  @override
  void dispose() {
    if (_swipeHandlers?[ShellTab.transactions] == this) {
      _swipeHandlers!.remove(ShellTab.transactions);
    }
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  // ── Swipe = step the period (like the dashboard's month) ────────────

  @override
  bool canSwipe(int dir) {
    final p = _f.period;
    if (p.step(dir) == null) return false;
    return dir < 0 || p.canStepForward(DateTime.now());
  }

  @override
  void onSwipe(int dir) {
    final next = _f.period.step(dir);
    if (next != null) _apply(_f.copyWith(period: next));
  }

  // ── Loading ─────────────────────────────────────────────────────────

  Future<void> _refetch() {
    final b = _f.period.bounds;
    return context.read<TransactionsCubit>().load(
      type: _f.type,
      categoryId: _f.category?.id,
      includeChildren: _f.category != null,
      uncategorized: _f.uncategorized,
      accountId: switch (_f.wallet) {
        TxOneWallet(:final account) => account.id,
        _ => null,
      },
      noWallet: _f.wallet is TxNoWallet,
      q: _q,
      tagIds: [for (final t in _f.tags) t.id],
      from: b.from,
      to: b.to,
      sort: _f.sort,
    );
  }

  void _apply(TxFilters f) {
    setState(() => _f = f);
    _refetch();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted || v.trim() == _q) return;
      setState(() => _q = v.trim());
      _refetch();
    });
  }

  Future<void> _openFilters() async {
    final f = await showTxFilterSheet(
      context,
      current: _f,
      base: _base,
      repository: context.read<TransactionsRepository>(),
      walletLocked: widget.lockedAccount != null,
    );
    if (f != null && mounted) _apply(f);
  }

  /// Filters changed from how the page opened (the period isn't one — the
  /// pill shows it) or a search is on.
  bool get _filtered => !_f.sameFiltersAs(_base) || _q.isNotEmpty;

  void _clearFilters() {
    _search.clear();
    _q = '';
    // The period and the sort are the page's own controls — kept.
    _apply(_base.copyWith(period: _f.period, sort: _f.sort));
  }

  // ── Active filter chips ─────────────────────────────────────────────

  /// The filtered category's name: the one we were given, else the first
  /// loaded row of that category (no category lookup — rows embed it).
  String _categoryName(TransactionsState state) {
    final c = _f.category!;
    if (c.name.isNotEmpty) return c.name;
    for (final t in state.transactions) {
      if (t.category?.id == c.id) return t.category!.name;
    }
    return '…';
  }

  /// One removable chip per filter that differs from how the page opened.
  List<({String label, TxFilters without})> _activeChips(
    AppLocalizations l,
    TransactionsState state,
  ) {
    final base = _base;
    return [
      if (_f.type != base.type)
        (
          label: txTypeLabel(l, _f.type),
          without: _f.copyWith(type: base.type, clearType: base.type == null),
        ),
      if (_f.wallet != base.wallet && txWalletLabel(l, _f.wallet) != null)
        (
          label: txWalletLabel(l, _f.wallet)!,
          without: _f.copyWith(wallet: base.wallet),
        ),
      if (_f.uncategorized && !base.uncategorized)
        (
          label: l.homeUncategorized,
          without: _f.copyWith(uncategorized: false),
        ),
      if (_f.category != null && _f.category!.id != base.category?.id)
        (
          label: _categoryName(state),
          without: _f.copyWith(
            category: base.category,
            clearCategory: base.category == null,
          ),
        ),
      for (final t in _f.tags)
        (
          label: '#${t.name}',
          without: _f.copyWith(
            tags: [
              for (final x in _f.tags)
                if (x.id != t.id) x,
            ],
          ),
        ),
      // The sort shows in its own control, the period in its pill.
    ];
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locked = widget.lockedAccount;
    final content = BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        final loading =
            state.status == TransactionsStatus.initial ||
            (state.status == TransactionsStatus.loading &&
                state.transactions.isEmpty);
        final chips = _activeChips(l, state);
        final header = <Widget>[
          const SizedBox(height: AppSpacing.sm),
          Center(child: _periodPill()),
          if (state.totals case final t?) _totals(l, t),
          // Search (the whole width) + [ตัวกรอง •n] … [⇅ ใหม่สุด ▾] as ONE
          // block (owner 2026-10-10 / 2026-10-12).
          ListToolbar(
            searchKey: const ValueKey('tx-search'),
            searchController: _search,
            onSearchChanged: _onSearch,
            searchHint: l.transactionsSearchHint,
            chips: [
              AppChip(
                label: l.transactionsFiltersTitle,
                icon: Icons.tune,
                selected: chips.isNotEmpty,
                trailing: AppChipTrailing.count,
                count: chips.length,
                onTap: _openFilters,
              ),
            ],
            trailing: OptionMenuAnchor<String>(
              selected: _f.sort,
              onSelected: (s) => _apply(_f.copyWith(sort: s)),
              options: [
                for (final s in const [
                  'date_desc',
                  'date_asc',
                  'amount_desc',
                  'amount_asc',
                ])
                  SheetOption(value: s, label: txSortLabel(l, s)),
              ],
              builder: (context, toggle) => AppChip(
                label: txSortLabel(l, _f.sort),
                icon: AppIcons.sort,
                trailing: AppChipTrailing.dropdown,
                onTap: toggle,
              ),
            ),
          ),
          // Every active filter, wrapping onto more lines (owner: see them
          // all), each ✕ removes it.
          if (chips.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final c in chips)
                    AppChip(
                      label: c.label,
                      selected: true,
                      trailing: AppChipTrailing.remove,
                      tooltip: l.transactionsFilterRemove,
                      onRemove: () => _apply(c.without),
                    ),
                ],
              ),
            ),
        ];

        final failed =
            state.status == TransactionsStatus.error &&
            state.transactions.isEmpty;
        return ListPageBody(
          loading: loading,
          error: failed ? state.error : null,
          isEmpty: state.transactions.isEmpty,
          onRetry: _refetch,
          empty: _empty(l, locked),
          header: header,
          hasMore: state.hasMore,
          loadingMore: state.loadingMore,
          onLoadMore: () => context.read<TransactionsCubit>().loadMore(),
          // Rows run edge to edge; the header items pad themselves.
          sidePadding: 0,
          rowDividers: true,
          topInset: 0,
          children: state.transactions.isEmpty
              ? const []
              : _rows(
                  context,
                  state,
                  footer: locked == null
                      ? null
                      : AddTile(
                          label: l.navAddTransaction,
                          variant: AddTileVariant.row,
                          onTap: () =>
                              showQuickCreateSheet(context, account: locked),
                        ),
                ),
        );
      },
    );

    if (widget.embedded) return content;
    return Scaffold(
      // Tab root (no title passed) → the tab's own bar; pushed → back + title.
      appBar: AppTopBar(
        title: widget.title ?? l.navTransactions,
        showBack: widget.title != null,
      ),
      // Tab switch animates the body only — the bar stays put.
      body: TabSwitchBody(child: content),
    );
  }

  /// รายรับ · รายจ่าย · คงเหลือ of the whole filtered set (every page — the
  /// server's `totals`), transfers left out.
  Widget _totals(AppLocalizations l, ListTotals totals) => Padding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.sm,
      AppSpacing.lg,
      AppSpacing.xs,
    ),
    child: AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SummaryStats(
        stats: [
          SummaryStat(
            label: l.homeIncome,
            amount: totals.income,
            tone: MoneyTone.income,
          ),
          SummaryStat(
            label: l.homeExpense,
            amount: -totals.expense,
            tone: MoneyTone.expense,
          ),
          SummaryStat(
            label: l.homeLeftOver,
            amount: totals.net,
            tone: totals.net < 0 ? MoneyTone.expense : MoneyTone.income,
          ),
        ],
      ),
    ),
  );

  /// The page's date filter: ‹ › step, the label opens the period sheet.
  Widget _periodPill() => TxPeriodPill(
    period: _f.period,
    onChanged: (p) => _apply(_f.copyWith(period: p)),
  );

  /// Filters changed → "nothing matches" + clear (back to how the page
  /// opened, keeping the period); as opened → nothing here yet + add.
  EmptyView _empty(AppLocalizations l, Account? locked) {
    final thisMonth =
        _f.period == TxPeriod.month(DateTime.now()) && locked == null;
    return EmptyView(
      icon: _filtered ? AppIcons.search : AppIcons.empty,
      title: _filtered
          ? l.transactionsNoMatch
          : thisMonth
          ? l.transactionsEmptyMonthTitle
          : _f.period.kind == TxPeriodKind.all
          ? l.transactionsEmptyAccountTitle
          : l.transactionsEmptyPeriodTitle,
      message: _filtered
          ? l.transactionsNoMatchMessage
          : thisMonth
          ? l.transactionsListEmptyMessage
          : '',
      cta: _filtered
          ? AppButton(
              label: l.transactionsClearFilters,
              variant: AppButtonVariant.tonal,
              onPressed: _clearFilters,
            )
          : AddTile(
              label: l.homeAddFirstTx,
              // Same flow as the nav's +.
              onTap: () => showQuickCreateSheet(context, account: locked),
            ),
    );
  }

  /// Rows under "วันนี้ · −฿540" headers (net of the day's income /
  /// expense), days always in date order. Sorted by amount → a flat list
  /// with dates on the rows (day headers would repeat).
  List<Widget> _rows(
    BuildContext context,
    TransactionsState state, {
    Widget? footer,
  }) {
    final l = AppLocalizations.of(context)!;
    final hideAccount = _f.wallet is TxOneWallet;
    final children = <Widget>[];
    if (_f.sort.startsWith('date')) {
      final days = <String, List<Transaction>>{};
      for (final t in state.transactions) {
        days.putIfAbsent(t.date, () => []).add(t);
      }
      final oldestFirst = _f.sort == 'date_asc';
      final ordered = days.entries.toList()
        ..sort(
          (a, b) =>
              oldestFirst ? a.key.compareTo(b.key) : b.key.compareTo(a.key),
        );
      for (final e in ordered) {
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
      for (final t in state.transactions) {
        children.add(
          TransactionTile(
            transaction: t,
            showAccount: !hideAccount,
            showDate: true,
          ),
        );
      }
    }
    // Next page in flight → the template shows row skeletons instead.
    if (footer != null && !state.loadingMore) {
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
    return children;
  }
}
