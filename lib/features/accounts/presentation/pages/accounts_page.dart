import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/shell_chrome.dart';
import '../../../../app/shell/tab_root_scaffold.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/account.dart';
import '../../domain/account_type.dart';
import '../cubit/accounts_cubit.dart';

enum _WalletSort { type, custom, balance, name }

enum _WalletTile { cash, card }

class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

const double _cardExtent = 156;

class _AccountsPageState extends State<AccountsPage> {
  _WalletSort _sort = _WalletSort.custom;
  _WalletTile? _tile;
  final _search = TextEditingController();
  final _toolbarOpen = ToolbarToggleState.of('wallets');
  final _summaryOpen = ToolbarToggleState.of('wallets_summary', open: true);

  ReorderController? _reorder;
  final _reorderScroll = ScrollController();
  bool _savingOrder = false;
  ShellChromeController? _shellChrome;

  bool get _reordering => _reorder != null;

  bool _canReorder(List<Account> accounts) => accounts.length > 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shellChrome = ShellChrome.of(context);
  }

  @override
  void dispose() {
    if (_reordering) _shellChrome?.show();
    _reorder?.dispose();
    _reorderScroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<AccountsCubit>().loadIfNeeded());
    });
  }

  Future<void> _refresh() => context.read<AccountsCubit>().load();

  Future<void> _open(Future<Object?> Function() push) => push();

  String _sortLabel(AppLocalizations l, _WalletSort s) => switch (s) {
    _WalletSort.custom => l.accountsSortCustom,
    _WalletSort.balance => l.accountsSortBalance,
    _WalletSort.name => l.accountsSortName,
    _WalletSort.type => l.fpWalletsSortByType,
  };

  List<Account> _sorted(List<Account> accounts) {
    final indexed = [...accounts.indexed];
    int byOrder((int, Account) a, (int, Account) b) => a.$1.compareTo(b.$1);
    final int Function((int, Account), (int, Account)) cmp = switch (_sort) {
      _WalletSort.custom => byOrder,
      _WalletSort.balance => (a, b) {
        final c = (b.$2.showsBalance ? b.$2.balance : double.negativeInfinity)
            .compareTo(
              a.$2.showsBalance ? a.$2.balance : double.negativeInfinity,
            );
        return c != 0 ? c : byOrder(a, b);
      },
      _WalletSort.name => (a, b) {
        final c = a.$2.name.toLowerCase().compareTo(b.$2.name.toLowerCase());
        return c != 0 ? c : byOrder(a, b);
      },
      _WalletSort.type => (a, b) {
        final c = a.$2.type.index.compareTo(b.$2.type.index);
        return c != 0 ? c : byOrder(a, b);
      },
    };
    indexed.sort(cmp);
    return [for (final (_, a) in indexed) a];
  }

  void _enterReorder(List<Account> current, {String? select}) {
    HapticFeedback.lightImpact();
    _shellChrome?.hide();
    final c = ReorderController(
      maxDepth: 1,
      items: [for (final a in current) OutlineItem(a.id, 1)],
    )..addListener(_onReorderChanged);
    if (select != null) c.select(select);
    setState(() => _reorder = c);
  }

  void _onReorderChanged() => setState(() {});

  void _exitReorder() {
    _shellChrome?.show();
    final c = _reorder;
    setState(() {
      _reorder = null;
      _savingOrder = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => c?.dispose());
  }

  Future<void> _saveOrder(List<Account> accounts) async {
    final l = AppLocalizations.of(context)!;
    final c = _reorder;
    if (c == null || !c.dirty) {
      _exitReorder();
      return;
    }
    final byId = {for (final a in accounts) a.id: a};
    setState(() => _savingOrder = true);
    try {
      await context.read<AccountsCubit>().saveOrder([
        for (final item in c.items) ?byId[item.id],
      ]);
      if (mounted) _exitReorder();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingOrder = false);
      showAppSnackBar(
        context,
        '${l.accountsReorderSave}: ${e.message}',
        tone: Tone.danger,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return PopScope(
      canPop: !_reordering,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _reordering) _exitReorder();
      },
      child: _page(context, l),
    );
  }

  Widget _page(BuildContext context, AppLocalizations l) {
    return SavingOverlay(
      saving: _savingOrder,
      child: TabRootScaffold(
        title: l.navAccounts,
        body: BlocBuilder<AccountsCubit, AccountsState>(
          builder: (context, state) {
            final accounts = state.accounts;
            final cols = MediaQuery.sizeOf(context).shortestSide >= 600 ? 3 : 2;
            if (_reordering) return _reorderView(context, accounts);
            return ListPageBody(
              // Only the FIRST load shows the skeleton: a reload keeps the
              // wallets (a skeleton would kill a pull-to-refresh).
              loading:
                  (state.status == AccountsStatus.initial ||
                      state.status == AccountsStatus.loading) &&
                  state.accounts.isEmpty,
              error: state.accounts.isEmpty ? state.error : null,
              isEmpty: accounts.isEmpty,
              onRetry: _refresh,
              skeletonShape: ListSkeletonShape.grid(
                headerHeight: 168,
                sortRow: true,
                gridColumns: cols,
                gridItemExtent: _cardExtent,
              ),
              empty: EmptyView(
                icon: AppIcons.wallet,
                title: l.accountsEmptyTitle,
                message: l.accountsEmptyMessage,
                cta: AppButton(
                  label: l.accountsAddNew,
                  icon: AppIcons.add,
                  onPressed: () => context.push('/accounts/new'),
                ),
              ),
              sidePadding: 0,
              topInset: 0,
              children: _gridChildren(context, state, cols),
            );
          },
        ),
      ),
    );
  }

  Widget _listToolbar(AppLocalizations l, List<Account> accounts) {
    return ListToolbar(
      collapse: _toolbarOpen,
      searchController: _search,
      onSearchChanged: (_) => setState(() {}),
      searchHint: l.accountsSearchHint,
      chips: [
        OptionMenuAnchor<_WalletSort>(
          selected: _sort,
          onSelected: (s) => setState(() => _sort = s),
          options: [
            for (final s in _WalletSort.values)
              SheetOption(value: s, label: _sortLabel(l, s)),
          ],
          builder: (context, toggle) => AppChip(
            label: _sortLabel(l, _sort),
            icon: AppIcons.sort,
            selected: _sort != _WalletSort.custom,
            trailing: AppChipTrailing.dropdown,
            onTap: toggle,
          ),
        ),
      ],
      trailing: AppChip(
        label: l.fpWalletsReorderChip,
        icon: AppIcons.reorder,
        onTap: _canReorder(accounts) ? () => _enterReorder(accounts) : null,
      ),
    );
  }

  String _money(BuildContext context, double v) =>
      moneyString(context, v == 0 ? 0 : v);

  /// The two filter tiles — only with a card / pay-later wallet (without one
  /// the cash tile would repeat the net).
  List<SummaryTile> _tiles(
    BuildContext context,
    AppLocalizations l,
    AccountsState state,
  ) {
    final t = state.totals;
    final hasCards = t.byType.any((b) => b.type.isCredit && b.count > 0);
    if (!hasCards) return const [];
    final split = t.cashSplit.isEmpty
        ? null
        : t.cashSplit
              .map((s) => '${accountTypeLabel(context, s.type)} ${s.pct}%')
              .join(' · ');
    void toggle(_WalletTile v) => setState(() => _tile = _tile == v ? null : v);
    return [
      SummaryTile(
        label: l.fpWalletsTileCash,
        value: _money(context, t.cashTotal),
        tone: SummaryTileTone.green,
        selected: _tile == _WalletTile.cash,
        onTap: () => toggle(_WalletTile.cash),
        caption: split,
      ),
      SummaryTile(
        label: l.accountsSummaryCardDebt,
        value: _money(context, t.cardDebt),
        tone: SummaryTileTone.orange,
        selected: _tile == _WalletTile.card,
        onTap: () => toggle(_WalletTile.card),
        caption: t.creditLimit > 0
            ? l.accountsSummaryCreditUsed(
                t.cardUsedPct,
                _money(context, t.cardRemaining),
              )
            : null,
      ),
    ];
  }

  Widget _summary(
    BuildContext context,
    AppLocalizations l,
    AccountsState state,
  ) {
    final t = state.totals;
    final net = MoneyText(t.net == 0 ? 0 : t.net);
    final tiles = _tiles(context, l, state);
    return AppHeroCard(
      style: HeroStyle.tinted(color: Theme.of(context).colorScheme.primary),
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.xs,
      ),
      open: _summaryOpen,
      header: HeroHeader(
        leading: [
          HeroCaption(
            '${l.accountsSummaryNet} · '
            '${l.accountsSummaryWalletCount(state.accounts.length)}'
            '${t.sharedCount > 0 ? ' ${l.accountsSummarySharedCount(t.sharedCount)}' : ''}',
          ),
        ],
        actions: [
          const MoneyVisibilityToggle(),
          ListenableBuilder(
            listenable: _search,
            builder: (context, _) => ToolbarToggleButton(
              state: _toolbarOpen,
              filtered:
                  _search.text.isNotEmpty ||
                  _sort != _WalletSort.custom ||
                  _tile != null,
              tooltip: l.commonSearch,
            ),
          ),
        ],
      ),
      content: [
        HeroNumber(value: net, layout: HeroNumberLayout.inline),
        if (t.savedTotal > 0)
          HeroNote(
            child: Text(
              l.fpWalletsSavedLine(
                _money(context, t.savedTotal),
                _money(context, t.availableTotal),
              ),
            ),
          ),
      ],
      folded: [
        HeroNumber(value: net, layout: HeroNumberLayout.inline, small: true),
      ],
      footer: [
        if (tiles.isNotEmpty)
          HeroTiles(
            children: [for (final tile in tiles) SummaryTileView(tile: tile)],
          ),
      ],
    );
  }

  bool _inTile(Account a) => switch (_tile) {
    null => true,
    _WalletTile.cash => !a.type.isCredit,
    _WalletTile.card => a.type.isCredit,
  };

  List<Widget> _gridChildren(
    BuildContext context,
    AccountsState state,
    int cols,
  ) {
    final accounts = state.accounts;
    final l = AppLocalizations.of(context)!;
    final q = _search.text.trim().toLowerCase();
    final list = [
      for (final a in _sorted(accounts))
        if (_inTile(a) && (q.isEmpty || a.name.toLowerCase().contains(q))) a,
    ];
    final grouped = _sort == _WalletSort.type;
    return [
      _summary(context, l, state),
      _listToolbar(l, accounts),
      if (list.isEmpty && accounts.isNotEmpty)
        EmptyView.compact(message: l.accountsNoMatch),
      if (grouped)
        for (final type in AccountType.values)
          ..._group(context, state, accounts, list, type, cols, q.isEmpty)
      else
        _grid(context, accounts, list, cols),
      Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          0,
        ),
        child: AddTile(
          label: l.accountsAddNew,
          onTap: () => _open(() => context.push('/accounts/new')),
        ),
      ),
      if (state.archivedCount > 0)
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.md),
          child: DetailRow(
            leading: const AppIcon(AppIcons.archive),
            label: l.accountsArchivedLink(state.archivedCount),
            showChevron: true,
            onTap: () => _open(() => context.push('/accounts/archived')),
          ),
        ),
    ];
  }

  List<Widget> _group(
    BuildContext context,
    AccountsState state,
    List<Account> accounts,
    List<Account> list,
    AccountType type,
    int cols,
    bool showSubtotal,
  ) {
    final of = [
      for (final a in list)
        if (a.type == type) a,
    ];
    if (of.isEmpty) return const [];
    final sum = state.totals.byType
        .where((b) => b.type == type)
        .fold<double?>(null, (s, b) => (s ?? 0) + b.balance);
    return [
      SectionHeader(
        title: accountTypeLabel(context, type),
        count: of.length,
        trailing: showSubtotal && sum != null && of.every((a) => a.showsBalance)
            ? MoneyText(sum == 0 ? 0 : sum)
            : null,
      ),
      _grid(context, accounts, of, cols),
    ];
  }

  Widget _grid(
    BuildContext context,
    List<Account> accounts,
    List<Account> list,
    int cols,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          mainAxisExtent: _cardExtent,
        ),
        itemCount: list.length,
        itemBuilder: (context, i) {
          final a = list[i];
          return GestureDetector(
            onLongPress: _canReorder(accounts)
                ? () => _enterReorder(accounts, select: a.id)
                : null,
            child: AccountCard(
              account: a,
              horizontal: false,
              onTap: () => _open(() => context.push('/accounts/${a.id}')),
            ),
          );
        },
      ),
    );
  }

  Widget _reorderView(BuildContext context, List<Account> accounts) {
    final l = AppLocalizations.of(context)!;
    final c = _reorder!;
    final byId = {for (final a in accounts) a.id: a};
    return Column(
      children: [
        Expanded(
          child: ReorderListScope(
            controller: c,
            scrollController: _reorderScroll,
            child: ListView(
              controller: _reorderScroll,
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
                bottom: AppSpacing.lg,
              ),
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.sm,
                  ),
                  child: AppText(
                    l.accountsReorderTapHint,
                    role: AppTextRole.caption,
                  ),
                ),
                for (final item in c.visible())
                  if (byId[item.id] case final a?)
                    ReorderRow(
                      key: ValueKey(a.id),
                      id: a.id,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.lg,
                          AppSpacing.xs,
                          0,
                          AppSpacing.xs,
                        ),
                        child: AccountCard(account: a, horizontal: true),
                      ),
                    ),
              ],
            ),
          ),
        ),
        ReorderMoveBar(controller: c),
        ModeActionBar(
          canUndo: c.canUndo && !_savingOrder,
          canSave: c.dirty && !_savingOrder,
          saving: _savingOrder,
          cancelLabel: l.accountsReorderDiscard,
          saveLabel: l.accountsReorderSave,
          undoTooltip: l.categoriesUndo,
          onCancel: _exitReorder,
          onUndo: c.undo,
          onSave: () => _saveOrder(accounts),
        ),
      ],
    );
  }
}
