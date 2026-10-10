import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/shell/app_top_bar.dart';
import '../../../../app/shell/fade_branch_container.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../../accounts/domain/account.dart';
import '../../../accounts/presentation/cubit/accounts_cubit.dart';
import '../../../categories/domain/category_type.dart';
import '../../../categories/presentation/cubit/categories_cubit.dart';
import '../../../tags/presentation/cubit/tags_cubit.dart';
import '../../data/transactions_repository.dart';
import '../../domain/transaction.dart';
import '../../domain/transaction_type.dart';
import '../cubit/transactions_cubit.dart';
import '../tx_list_filters.dart';
import '../widgets/quick_create_sheet.dart';
import '../widgets/transaction_tile.dart';
import '../widgets/tx_filter_sheet.dart';

/// `/transactions` (owner 2026-10-10 redesign):
///
/// ```
///        ‹  ตุลาคม 2026 ▾  ›          period pill (swipe = step it)
///  [ รายรับ · รายจ่าย · คงเหลือ ]        totals of the whole filtered set
///  [🔍 ค้นหา…] [⚙ ตัวกรอง (n)]          → right side sheet
///  (รายจ่าย ✕) (KBank ✕)                only the active filters
///  วันนี้                    −฿540
///  rows (2 lines: title · category · wallet · #tags)
/// ```
///
/// Everything above the rows scrolls with them, so the list keeps the
/// screen. The same page is a wallet's รายการ tab ([lockedAccount], no
/// wallet filter) and the "ดูทั้งหมด" / dashboard drill-down pages.
///
/// [initialAccountId] pre-filters to one wallet ("ดูทั้งหมด ›" from a
/// wallet). [initialCategoryId] / [initialUncategorized] + [initialMonth]
/// open a dashboard slice ("เงินไปไหน" → one category in one month).
/// Picking a category always includes its sub-categories.
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

  /// Just the list, no Scaffold / top bar — a tab of another page (a
  /// wallet's รายการ). Give it its own [TransactionsCubit].
  final bool embedded;

  /// Pinned to this wallet: no wallet filter, everything added from here
  /// presets it, and the list ends in an add tile.
  final Account? lockedAccount;

  final String? initialAccountId;
  final String? initialCategoryId;
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
  final _scroll = ScrollController();
  final _search = TextEditingController();
  Map<ShellTab, ShellSwipeHandler>? _swipeHandlers;

  /// The transactions tab's own root — the only place the sideways swipe
  /// steps the period (elsewhere it belongs to the wallet tabs / the shell).
  bool get _isTabRoot =>
      !widget.embedded && widget.title == null && widget.lockedAccount == null;

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
      var f = _f;
      final locked = widget.lockedAccount;
      if (locked != null) {
        f = f.copyWith(wallet: TxOneWallet(locked), period: TxPeriod.all);
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
          f = f.copyWith(wallet: TxOneWallet(a), period: TxPeriod.all);
        }
      }
      final catId = widget.initialCategoryId;
      if (catId != null) {
        final c = context.read<CategoriesCubit>().byId(catId);
        if (c != null) {
          f = f.copyWith(
            category: c,
            type: c.type == CategoryType.income
                ? TransactionType.income
                : TransactionType.expense,
          );
        }
      }
      if (widget.initialUncategorized) {
        f = f.copyWith(uncategorized: true, type: TransactionType.expense);
      }
      final m = widget.initialMonth;
      if (m != null) f = f.copyWith(period: TxPeriod.month(m));
      context.read<TagsCubit>().loadIfNeeded();
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
    _scroll.dispose();
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
    _apply(_base.copyWith(period: _f.period));
  }

  // ── Active filter chips ─────────────────────────────────────────────

  /// One removable chip per filter that differs from how the page opened.
  List<({String label, TxFilters without})> _activeChips(AppLocalizations l) {
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
          label: _f.category!.name,
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
      if (_f.sort != base.sort)
        (label: txSortLabel(l, _f.sort), without: _f.copyWith(sort: base.sort)),
    ];
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final locked = widget.lockedAccount;
    final chips = _activeChips(l);

    final content = BlocBuilder<TransactionsCubit, TransactionsState>(
      builder: (context, state) {
        final loading =
            state.status == TransactionsStatus.initial ||
            (state.status == TransactionsStatus.loading &&
                state.transactions.isEmpty);
        final header = <Widget>[
          const SizedBox(height: AppSpacing.sm),
          Center(child: _periodPill(l)),
          if (state.totals case final t?) _TotalsCard(totals: t),
          Row(
            children: [
              Expanded(
                child: AppSearchBar(
                  key: const ValueKey('tx-search'),
                  controller: _search,
                  onChanged: _onSearch,
                  hint: l.transactionsSearchHint,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    AppSpacing.xs,
                    AppSpacing.sm,
                    AppSpacing.xs,
                  ),
                ),
              ),
              FilterDropdownChip(
                label: l.transactionsFiltersTitle,
                icon: Icons.tune,
                count: chips.length,
                onTap: _openFilters,
              ),
              const SizedBox(width: AppSpacing.lg),
            ],
          ),
          if (chips.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  for (final c in chips) ...[
                    _ActiveFilterChip(
                      label: c.label,
                      tooltip: l.transactionsFilterRemove,
                      onRemove: () => _apply(c.without),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                ],
              ),
            ),
        ];

        final List<Widget> body;
        if (loading) {
          body = [for (var i = 0; i < 8; i++) const SkeletonListTile()];
        } else if (state.status == TransactionsStatus.error &&
            state.transactions.isEmpty) {
          body = [
            const SizedBox(height: AppSpacing.xxl),
            ErrorView(error: state.error!, onRetry: _refetch),
          ];
        } else if (state.transactions.isEmpty) {
          body = [const SizedBox(height: AppSpacing.xl), _empty(l, locked)];
        } else {
          body = _rows(
            context,
            state,
            footer: locked == null
                ? null
                : AddTile(
                    label: l.navAddTransaction,
                    variant: AddTileVariant.row,
                    onTap: () => showQuickCreateSheet(context, account: locked),
                  ),
          );
        }

        return PullToRefresh(
          onRefresh: _refetch,
          child: ListView(
            controller: _scroll,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.only(
              bottom: 96 + MediaQuery.paddingOf(context).bottom,
            ),
            children: [...header, ...body],
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

  Widget _periodPill(AppLocalizations l) {
    final p = _f.period;
    final now = DateTime.now();
    if (p.kind == TxPeriodKind.month) {
      return MonthPill(
        month: p.start,
        last: now,
        onChanged: (m) => _apply(_f.copyWith(period: TxPeriod.month(m))),
      );
    }
    final prev = p.step(-1);
    final canNext = p.canStepForward(now);
    final stepping = prev != null;
    return PeriodPill(
      label: p.label(context),
      prevTooltip: l.txPeriodPrev,
      nextTooltip: l.txPeriodNext,
      onPrev: stepping ? () => _apply(_f.copyWith(period: prev)) : null,
      // Forward stops at today's period (›dimmed); ทั้งหมด / a custom range
      // have no neighbours, so no arrows at all.
      onNext: stepping && canNext
          ? () => _apply(_f.copyWith(period: p.step(1)))
          : null,
      // The label opens the filter sheet (its ช่วงเวลา section).
      onTap: _openFilters,
    );
  }

  /// Filters changed → "nothing matches" + clear (back to how the page
  /// opened, keeping the period); as opened → nothing here yet + add.
  Widget _empty(AppLocalizations l, Account? locked) {
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
    // Next page in flight → row-shaped skeletons, never a spinner (§8.5).
    if (state.loadingMore) {
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
    return children;
  }
}

/// รายรับ · รายจ่าย · คงเหลือ of the whole filtered set (every page — the
/// server's `totals`), transfers left out.
class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.totals});

  final ListTotals totals;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
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
      ),
    );
  }
}

/// An active filter under the search — its label and ✕ to drop it.
class _ActiveFilterChip extends StatelessWidget {
  const _ActiveFilterChip({
    required this.label,
    required this.onRemove,
    required this.tooltip,
  });

  final String label;
  final VoidCallback onRemove;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Tooltip(
      message: tooltip,
      child: PillShell(
        size: PillSize.medium,
        background: scheme.primary.withValues(alpha: 0.12),
        border: scheme.primary.withValues(alpha: 0.5),
        onTap: onRemove,
        child: PillContent(
          label: label,
          color: scheme.primary,
          size: PillSize.medium,
          trailing: Icon(AppIcons.close, size: 16, color: scheme.primary),
        ),
      ),
    );
  }
}
