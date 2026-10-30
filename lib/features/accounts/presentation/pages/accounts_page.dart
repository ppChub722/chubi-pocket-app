import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/shell_chrome.dart';
import '../../../../app/shell/tab_nav.dart';
import '../../../../app/shell/tab_root_scaffold.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../auth/domain/user.dart';
import '../../../preferences/page_prefs.dart';
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
  final _toolbarOpen = AppListToolbarState.of('wallets');

  ReorderController? _reorder;
  final _reorderScroll = ScrollController();
  bool _savingOrder = false;
  late final ShellNavClaim _shellNav = ShellNavClaim(
    () => mounted && _reordering,
  );

  bool get _reordering => _reorder != null;

  bool _canReorder(List<Account> accounts) => accounts.length > 1;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shellNav.attach(context);
  }

  @override
  void dispose() {
    _shellNav.dispose();
    _reorder?.dispose();
    _reorderScroll.dispose();
    _search.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _restorePrefs();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<AccountsCubit>().loadIfNeeded());
    });
  }

  /// The sort and tile remembered on the account (defaults when none).
  void _restorePrefs() {
    final pref = readPagePref(context, PagePrefIds.wallets);
    final fields = pagePrefPage(PagePrefIds.wallets).fields;
    String pick(String key) =>
        fields.firstWhere((f) => f.key == key).pick(pref);
    _sort = _WalletSort.values.asNameMap()[pick('sort')] ?? _WalletSort.custom;
    _tile = _WalletTile.values.asNameMap()[pick('tile')];
  }

  void _setSort(_WalletSort s) {
    setState(() => _sort = s);
    unawaited(rememberPagePref(context, PagePrefIds.wallets, {'sort': s.name}));
  }

  void _setTile(_WalletTile? t) {
    setState(() => _tile = t);
    unawaited(
      rememberPagePref(context, PagePrefIds.wallets, {
        'tile': t?.name ?? 'all',
      }),
    );
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
    final c = ReorderController(
      maxDepth: 1,
      items: [for (final a in current) OutlineItem(a.id, 1)],
    )..addListener(_onReorderChanged);
    if (select != null) c.select(select);
    setState(() => _reorder = c);
    _shellNav.changed();
  }

  void _onReorderChanged() => setState(() {});

  void _exitReorder() {
    final c = _reorder;
    setState(() {
      _reorder = null;
      _savingOrder = false;
    });
    _shellNav.changed();
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
        '${l.accountsReorderSave}: ${errorText(l, e)}',
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
    return BusyScope(
      busy: _savingOrder,
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
              // No wallets is not a bare empty screen: the page keeps its
              // summary (zeros), toolbar and the add tile, like the others.
              isEmpty: false,
              onRetry: _refresh,
              skeletonShape: ListSkeletonShape.grid(
                headerHeight: 192,
                sortRow: true,
                gridColumns: cols,
                gridItemExtent: _cardExtent,
              ),
              empty: EmptyView(
                icon: AppIcons.wallet,
                title: l.accountsEmptyTitle,
                message: l.accountsEmptyMessage,
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
    return AppListToolbar(
      state: _toolbarOpen,
      search: ListToolbarSearch(
        controller: _search,
        onChanged: (_) => setState(() {}),
        hint: l.accountsSearchHint,
      ),
      filters: [
        OptionMenuAnchor<_WalletSort>(
          selected: _sort,
          onSelected: _setSort,
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

  /// The net in big, a bar of what makes it (available | saved | card debt)
  /// and a row for each, zeros included: ฿0 saved and ฿0 card debt are worth
  /// seeing. Filters show only when there are card wallets to split by.
  Widget _summary(
    BuildContext context,
    AppLocalizations l,
    AccountsState state,
  ) {
    final t = state.totals;
    final net = MoneyText(t.net == 0 ? 0 : t.net);
    final palette = Theme.of(context).extension<AppColors>()!;
    final savedColor = ModuleColors.of(context).planning;
    final debtColor = palette.walletLiability;
    final hasDebt = t.cardDebt.abs() >= 0.005;
    final cards = state.accounts.where((a) => a.type.isCredit).length;
    final total = t.availableTotal + t.savedTotal + t.cardDebt.abs();
    HeroFilter filter(_WalletTile? v, String label, IconData icon, int count) =>
        HeroFilter(
          label: label,
          icon: icon,
          count: count,
          selected: _tile == v,
          onTap: () => _setTile(v),
        );
    return AppHeroCard(
      style: HeroStyle.tinted(color: Theme.of(context).colorScheme.primary),
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      header: HeroSummaryHead(
        icon: AppIcons.wallet,
        label: [
          l.accountsSummaryNet,
          l.accountsSummaryWalletCount(state.accounts.length),
          if (t.sharedCount > 0) l.fpWalletsSharedTooltip(t.sharedCount),
        ].join(' | '),
        amount: net,
        actions: [
          ListenableBuilder(
            listenable: _search,
            builder: (context, _) => AppListToolbarToggle(
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
        // Builders: the card's accent is only known inside the card.
        if (total > 0)
          Builder(
            builder: (context) => HeroBar.split(
              parts: [
                (t.availableTotal / total, HeroColors.maybeOf(context)!.accent),
                // A small saving still shows as a sliver.
                if (t.savedTotal > 0)
                  ((t.savedTotal / total).clamp(0.01, 1.0), savedColor),
                if (hasDebt) (t.cardDebt.abs() / total, debtColor),
              ],
            ),
          ),
        Builder(
          builder: (context) => HeroFactList(
            facts: [
              HeroFact(
                l.fpWalletsTileAvailable,
                _money(context, t.availableTotal),
                icon: AppIcons.coin,
                iconColor: HeroColors.maybeOf(context)!.accent,
              ),
              HeroFact(
                l.walletSavingsSaved,
                _money(context, t.savedTotal),
                icon: AppIcons.savings,
                iconColor: savedColor,
                onTap: () => openPage(context, '/saving-goals'),
              ),
              HeroFact(
                hasDebt && t.creditLimit > 0
                    ? '${l.accountsSummaryCardDebt} | '
                          '${l.fpWalletsCreditUsedPct(t.cardUsedPct)}'
                    : l.accountsSummaryCardDebt,
                _money(context, t.cardDebt),
                icon: AppIcons.creditCard,
                iconColor: debtColor,
                color: hasDebt ? debtColor : null,
              ),
            ],
          ),
        ),
      ],
      footer: [
        if (cards > 0)
          HeroFilterChips(
            filters: [
              filter(
                null,
                l.fpWalletsFilterAll,
                AppIcons.wallet,
                state.accounts.length,
              ),
              filter(
                _WalletTile.cash,
                l.fpWalletsFilterCash,
                AppIcons.bank,
                state.accounts.length - cards,
              ),
              filter(
                _WalletTile.card,
                l.fpWalletsFilterCard,
                AppIcons.creditCard,
                cards,
              ),
            ],
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
          child: AppDetailRow(
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
      AppListHeader(
        title: accountTypeLabel(context, type),
        count: of.length,
        trailing: showSubtotal && sum != null && of.every((a) => a.showsBalance)
            ? ListHeaderTrailing.value(MoneyText(sum == 0 ? 0 : sum))
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
