import 'dart:async';

import 'package:flutter/foundation.dart' show setEquals;

import 'package:flutter/foundation.dart' show ValueListenable;
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
    this.typeFilter,
    this.period,
    super.key,
  });

  final bool embedded;

  final Account? lockedAccount;

  final ValueListenable<TransactionType?>? typeFilter;

  /// The period, shared both ways with an owner outside the list (a hero
  /// stepping months): the list writes its changes and follows the owner's.
  final ValueNotifier<TxPeriod>? period;

  final String? initialCategoryId;

  final String? initialCategoryName;
  final CategoryType? initialCategoryType;
  final bool initialUncategorized;

  final DateTime? initialMonth;

  final String? title;

  @override
  State<TransactionsListPage> createState() => _TransactionsListPageState();
}

class _TransactionsListPageState extends State<TransactionsListPage>
    implements ShellSwipeHandler {
  TxFilters _f = TxFilters(period: TxPeriod.month(DateTime.now()));

  late TxFilters _base = _f;
  String _q = '';
  Timer? _debounce;
  final _search = TextEditingController();
  late final _toolbarOpen = AppListToolbarState.of(
    widget.embedded ? 'transactions_wallet' : 'transactions',
  );
  final _summaryOpen = AppListToolbarState.of(
    'transactions_summary',
    open: true,
  );
  Map<ShellTab, ShellSwipeHandler>? _swipeHandlers;

  bool get _isTabRoot =>
      !widget.embedded && widget.title == null && widget.lockedAccount == null;

  @override
  void initState() {
    super.initState();
    widget.typeFilter?.addListener(_onTypeFilter);
    final owned = widget.period;
    if (owned != null) {
      _f = _f.copyWith(period: owned.value);
      owned.addListener(_onPeriod);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      var f = _f;
      final locked = widget.lockedAccount;
      if (locked != null) f = f.copyWith(wallets: [locked]);
      final catId = widget.initialCategoryId;
      if (catId != null) {
        final t = widget.initialCategoryType;
        f = f.copyWith(
          categories: [
            Category(
              id: catId,
              name: widget.initialCategoryName ?? '',
              type: t ?? CategoryType.expense,
            ),
          ],
          types: switch (t) {
            null => const {},
            CategoryType.income => const {TransactionType.income},
            _ => const {TransactionType.expense},
          },
        );
      }
      if (widget.initialUncategorized) {
        f = f.copyWith(
          uncategorized: true,
          types: const {TransactionType.expense},
        );
      }
      final m = widget.initialMonth;
      if (m != null) f = f.copyWith(period: TxPeriod.month(m));
      setState(() => _f = _base = f);
      widget.period?.value = f.period;
      _refetch();
    });
  }

  void _onPeriod() {
    final p = widget.period?.value;
    if (!mounted || p == null || p == _f.period) return;
    _apply(_f.copyWith(period: p));
  }

  void _onTypeFilter() {
    final t = widget.typeFilter?.value;
    final next = t == null ? const <TransactionType>{} : {t};
    if (!mounted || setEquals(next, _f.types)) return;
    _apply(_f.copyWith(types: next));
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
    widget.typeFilter?.removeListener(_onTypeFilter);
    widget.period?.removeListener(_onPeriod);
    if (_swipeHandlers?[ShellTab.transactions] == this) {
      _swipeHandlers!.remove(ShellTab.transactions);
    }
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  @override
  bool canSwipe(int dir) {
    return _f.period.step(dir) != null;
  }

  @override
  void onSwipe(int dir) {
    final next = _f.period.step(dir);
    if (next != null) _apply(_f.copyWith(period: next));
  }

  Future<void> _refetch() {
    final b = _f.period.bounds;
    return context.read<TransactionsCubit>().load(
      types: _f.types,
      categoryIds: [for (final c in _f.categories) c.id],
      includeChildren: _f.categories.isNotEmpty,
      uncategorized: _f.uncategorized,
      accountIds: [for (final w in _f.wallets) w.id],
      noWallet: _f.noWallet,
      noTags: _f.noTags,
      amountMin: _f.amountMin,
      amountMax: _f.amountMax,
      q: _q,
      tagIds: [for (final t in _f.tags) t.id],
      from: b.from,
      to: b.to,
      sort: _f.sort,
    );
  }

  void _apply(TxFilters f) {
    setState(() => _f = f);
    widget.period?.value = f.period;
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

  bool get _filtered => !_f.sameFiltersAs(_base) || _q.isNotEmpty;

  void _clearFilters() {
    _search.clear();
    _q = '';
    _apply(_base.copyWith(period: _f.period, sort: _f.sort));
  }

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
        final activeFilters = _f.activeCount(_base);
        final header = <Widget>[
          if (widget.embedded) ...[
            const SizedBox(height: AppSpacing.sm),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Row(
                children: [
                  Flexible(child: _periodPill()),
                  const Spacer(),
                  ListenableBuilder(
                    listenable: _search,
                    builder: (context, _) => AppListToolbarToggle(
                      state: _toolbarOpen,
                      filtered: activeFilters > 0 || _q.isNotEmpty,
                      tooltip: l.commonSearch,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (state.totals case final t?)
            _summary(l, t, activeFilters)
          else
            const SizedBox(height: AppSpacing.sm),
          AppListToolbar(
            state: _toolbarOpen,
            search: ListToolbarSearch(
              key: const ValueKey('tx-search'),
              controller: _search,
              onChanged: _onSearch,
              hint: l.transactionsSearchHint,
            ),
            filters: [
              AppChip(
                label: l.transactionsFiltersTitle,
                icon: Icons.tune,
                selected: activeFilters > 0,
                trailing: AppChipTrailing.count,
                count: activeFilters,
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
          rowCards: true,
          topInset: 0,
          clearTopBar: !widget.embedded,
          footer: locked == null || state.transactions.isEmpty
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.md),
                  child: AddTile(
                    label: l.navAddTransaction,
                    onTap: () => showQuickCreateSheet(context, account: locked),
                  ),
                ),
          children: state.transactions.isEmpty
              ? const []
              : _rows(context, state),
        );
      },
    );

    if (widget.embedded) return content;
    return Scaffold(
      appBar: AppTopBar(
        title: widget.title ?? l.navTransactions,
        showBack: widget.title != null,
      ),
      body: TabSwitchBody(child: content),
    );
  }

  Widget _summary(AppLocalizations l, ListTotals t, int activeFilters) {
    final locale = Localizations.localeOf(context).languageCode;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = <DateTime?>[
      for (final d in t.daily) DateFormatter.parseDay(d.date),
    ];
    DailyBarKind kindOf(DateTime? d) => d == null || d.isBefore(today)
        ? DailyBarKind.past
        : d.isAtSameMomentAs(today)
        ? DailyBarKind.today
        : DailyBarKind.future;
    String dayLabel(DateTime? d) =>
        d == null ? '' : DateFormatter.short(d, locale: locale);
    bool only(TransactionType type) =>
        _f.types.length == 1 && _f.types.contains(type);
    void toggle(TransactionType type) =>
        _apply(_f.copyWith(types: only(type) ? const {} : {type}));
    final net = MoneyText(t.net, tone: MoneyTone.signed);
    return AppHeroCard(
      // The page color (the ▤ tile's); its pieces take their colors from it.
      style: HeroStyle.tinted(color: Theme.of(context).colorScheme.primary),
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      open: _summaryOpen,
      header: HeroHeader(
        leading: const [HeroModuleTile(AppIcons.transactions)],
        fill: _periodPill(),
        actions: [
          AppListToolbarToggle(
            state: _toolbarOpen,
            filtered: activeFilters > 0 || _q.isNotEmpty,
            tooltip: l.commonSearch,
          ),
        ],
      ),
      content: [
        HeroNumber(
          label: l.txSummaryNet,
          value: net,
          layout: HeroNumberLayout.inline,
        ),
        if (t.daily.isNotEmpty)
          DailyBars(
            bars: [
              for (final (i, d) in t.daily.indexed)
                DailyBar(
                  value: d.expense,
                  kind: kindOf(days[i]),
                  semanticLabel: dayLabel(days[i]),
                ),
            ],
            startLabel: dayLabel(days.first),
            centerLabel: t.avgDailySpend == null
                ? null
                : l.fpTxAvgDaily(moneyString(context, t.avgDailySpend!)),
            endLabel: dayLabel(days.last),
            onTap: (i) {
              final d = days[i];
              if (d != null) _apply(_f.copyWith(period: TxPeriod.day(d)));
            },
          ),
      ],
      folded: [
        HeroNumber(
          label: l.txSummaryNet,
          value: net,
          layout: HeroNumberLayout.inline,
          small: true,
        ),
      ],
      footer: [
        HeroTiles(
          children: [
            SummaryTileView(
              tile: SummaryTile(
                label: l.homeIncome,
                value: moneyString(context, t.income),
                tone: SummaryTileTone.green,
                selected: only(TransactionType.income),
                onTap: () => toggle(TransactionType.income),
              ),
            ),
            SummaryTileView(
              tile: SummaryTile(
                label: l.homeExpense,
                value: moneyString(context, t.expense),
                tone: SummaryTileTone.red,
                selected: only(TransactionType.expense),
                onTap: () => toggle(TransactionType.expense),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _periodPill() => TxPeriodPill(
    period: _f.period,
    onChanged: (p) => _apply(_f.copyWith(period: p)),
  );

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
              onTap: () => showQuickCreateSheet(context, account: locked),
            ),
    );
  }

  List<Widget> _rows(BuildContext context, TransactionsState state) {
    final l = AppLocalizations.of(context)!;
    final hideAccount = _f.wallets.length == 1 && !_f.noWallet;
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
          AppListHeader(
            title: d == null
                ? e.key
                : DateFormatter.friendly(
                    d,
                    today: l.commonToday,
                    yesterday: l.commonYesterday,
                    locale: Localizations.localeOf(context).languageCode,
                  ),
            trailing: ListHeaderTrailing.value(
              MoneyText(net, tone: MoneyTone.signed),
            ),
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
    return children;
  }
}
