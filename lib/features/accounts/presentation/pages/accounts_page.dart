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

/// How the wallets list is ordered — client-side; [custom] is the user's
/// own order (the only one that can be rearranged).
enum _WalletSort { custom, balance, name, type }

/// Wallets tab root (§10, owner 2026-10-11):
///
///   summary card (net · composition · debt / shared pot)
///   ✏️ ………………………………………… [ลำดับที่จัดเอง ▾]
///   one flat grid in that order (shared wallets keep their badge) ·
///   dashed "+ เพิ่มกระเป๋า"
///   "กระเป๋าที่เก็บถาวร (n) ›"
///
/// ✏️ (or a long-press on a wallet) → the kit's reorder mode, flat — only
/// in ลำดับที่จัดเอง. The order is the caller's own, saved in one
/// PATCH /accounts/reorder (contract §3).
class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

/// One grid's mainAxisExtent: icon row · name · description · balance ·
/// credit bar. The skeleton uses it too.
const double _cardExtent = 156;

class _AccountsPageState extends State<AccountsPage> {
  _WalletSort _sort = _WalletSort.custom;
  final _search = TextEditingController();
  final _toolbarOpen = ToolbarToggleState.of('wallets');

  /// Non-null while reordering — the kit's flat reorder mode.
  ReorderController? _reorder;
  final _reorderScroll = ScrollController();
  bool _savingOrder = false;
  ShellChromeController? _shellChrome;

  bool get _reordering => _reorder != null;

  /// Rearranging only makes sense on the user's own order.
  bool _canReorder(List<Account> accounts) =>
      _sort == _WalletSort.custom && accounts.length > 1;

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
      final cubit = context.read<AccountsCubit>();
      // One call: the wallets, the totals and the archived count. A write
      // elsewhere only patched rows — re-read once now if the totals lag.
      cubit.loadIfNeeded().then((_) => cubit.refreshIfStale());
    });
  }

  Future<void> _refresh() => context.read<AccountsCubit>().load();

  /// Pushed pages patch the cubit; the totals catch up on return.
  Future<void> _open(Future<Object?> Function() push) async {
    await push();
    if (mounted) unawaited(context.read<AccountsCubit>().refreshIfStale());
  }

  // ── Sort ────────────────────────────────────────────────────────────

  String _sortLabel(AppLocalizations l, _WalletSort s) => switch (s) {
    _WalletSort.custom => l.accountsSortCustom,
    _WalletSort.balance => l.accountsSortBalance,
    _WalletSort.name => l.accountsSortName,
    _WalletSort.type => l.accountsSortType,
  };

  /// [accounts] in the cubit's (the user's) order, re-sorted for [_sort];
  /// ties keep the user's order.
  List<Account> _sorted(List<Account> accounts) {
    final indexed = [...accounts.indexed];
    int byOrder((int, Account) a, (int, Account) b) => a.$1.compareTo(b.$1);
    final int Function((int, Account), (int, Account)) cmp = switch (_sort) {
      _WalletSort.custom => byOrder,
      _WalletSort.balance => (a, b) {
        // Untracked wallets have no balance to rank by: they go last.
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

  // ── Reorder mode ────────────────────────────────────────────────────

  /// [select] — the long-pressed wallet, selected on entry so its ↑ ↓ bar
  /// is right there.
  void _enterReorder(List<Account> current, {String? select}) {
    HapticFeedback.lightImpact();
    _shellChrome?.hide(); // the action bar replaces the shell nav
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
    // After the frame: the scope stops listening first.
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

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    // Back while reordering leaves the mode (the staged order dropped) and
    // stays on the page — the shell asks a tab's root page first.
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
              // Summary · sort row · the cards grid at the cards' height.
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
              // Full-width children (the summary card and the grid pad
              // themselves).
              sidePadding: 0,
              topInset: 0,
              children: _gridChildren(context, state, cols),
            );
          },
        ),
      ),
    );
  }

  /// The collapsible toolbar (🔍 in the summary card): search by name + the
  /// order chip.
  Widget _listToolbar(AppLocalizations l) {
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
    );
  }

  /// `……… ✏️` — the list's edit mode (owner 2026-10-11), always visible.
  Widget _editRow(AppLocalizations l, List<Account> accounts) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xs,
        AppSpacing.sm,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          const Spacer(),
          AppIconButton.edit(
            tooltip: l.accountsReorder,
            onPressed: _canReorder(accounts)
                ? () => _enterReorder(accounts)
                : null,
          ),
        ],
      ),
    );
  }

  /// The page's scrolling content, in order: summary · toolbar · the wallet
  /// grid (+ add tile) · the archived link. ListPageBody supplies the scroll
  /// view, the insets, pull-to-refresh and the data states.
  List<Widget> _gridChildren(
    BuildContext context,
    AccountsState state,
    int cols,
  ) {
    final accounts = state.accounts;
    final l = AppLocalizations.of(context)!;
    // Search is local (the list is not paged): name contains the text.
    final q = _search.text.trim().toLowerCase();
    final list = [
      for (final a in _sorted(accounts))
        if (q.isEmpty || a.name.toLowerCase().contains(q)) a,
    ];
    return [
      _WalletsSummary(
        state: state,
        action: ListenableBuilder(
          listenable: _search,
          builder: (context, _) => ToolbarToggleButton(
            state: _toolbarOpen,
            filtered: _search.text.isNotEmpty || _sort != _WalletSort.custom,
            tooltip: l.commonSearch,
          ),
        ),
      ),
      _listToolbar(l),
      _editRow(l, accounts),
      if (list.isEmpty && accounts.isNotEmpty)
        EmptyView.compact(message: l.accountsNoMatch),
      Padding(
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
          itemCount: list.length + 1,
          itemBuilder: (context, i) {
            if (i == list.length) {
              return AddTile(
                label: l.accountsAddNew,
                onTap: () => _open(() => context.push('/accounts/new')),
              );
            }
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

  /// Reorder mode (the kit's, flat): a hint, the wallets with ⠿ handles
  /// (drag at once; tap → the ↑ ↓ bar), then the move bar + ยกเลิก / ↶ /
  /// บันทึก at the bottom.
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
                // Clear the transparent top bar.
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

/// Wallet-tab dashboard (owner 2026-10-11), drawn from the BE's `totals`
/// (no client sums); no number twice:
///
///   ยอดสุทธิ · n กระเป๋า (ร่วม m)                          👁
///   ฿ net                     (what I have − what I owe)
///   ▓▓▓▓▒▒░░  cash 60% · bank 30% · …   (what the money on hand is)
///   เงินที่มี ฿x              (only with debt — else it equals net)
///   ใช้วงเงิน n% · เหลือ ฿y   (cards with a limit; liability colour)
///   หนี้บัตร ฿a               (only when non-zero)
class _WalletsSummary extends StatelessWidget {
  const _WalletsSummary({required this.state, this.action});
  final AccountsState state;

  /// The card's top-right action (the list's 🔍), after the 👁.
  final Widget? action;

  /// A type's segment / legend colour: its group's theme token
  /// ([AccountType.colorOf] — have = cool, owe = warm, owner 2026-10-11),
  /// one shade per type so the segments stay apart.
  static Color _colorOf(BuildContext context, AccountType t) => t
      .colorOf(context)
      .withValues(
        alpha: switch (t) {
          AccountType.cash || AccountType.creditCard => 1,
          AccountType.bank || AccountType.payLater => 0.65,
          AccountType.eWallet => 0.4,
        },
      );

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final liability = palette.walletLiability;
    final muted = AppTypography.of(context, AppTextRole.caption);
    // Emphasis inside a muted line: the money role's weight (no hand weight).
    final strongWeight = AppTypography.of(
      context,
      AppTextRole.money,
    )?.fontWeight;

    final totals = state.totals;
    final sharedCount = totals.sharedCount;
    // Liabilities / credit used are positive numbers owed.
    final debt = totals.liabilities;
    final assets = totals.assets;
    final net = totals.net;
    final creditUsed = totals.creditUsed;
    final creditLimit = totals.creditLimit;
    // The money on hand by type: the positive balances only.
    final parts = [
      for (final t in totals.byType)
        if (t.balance > 0) t,
    ]..sort((a, b) => b.balance.compareTo(a.balance));
    final partsTotal = parts.fold(0.0, (s, t) => s + t.balance);

    // "หนี้บัตร ฿a · กระเป๋าร่วม ฿b" — each only when it applies.
    final bottom = <InlineSpan>[
      if (debt > 0) ...[
        TextSpan(text: '${l.accountsSummaryCardDebt} '),
        TextSpan(
          text: moneyString(context, debt),
          style: muted?.copyWith(color: liability, fontWeight: strongWeight),
        ),
      ],
      if (sharedCount > 0) ...[
        if (debt > 0) const TextSpan(text: '  ·  '),
        TextSpan(text: '${l.accountsSummarySharedPot} '),
        TextSpan(
          text: moneyString(context, totals.sharedBalance),
          style: muted?.copyWith(fontWeight: strongWeight),
        ),
      ],
    ];

    return AppCard(
      style: AppCardStyle.tinted,
      color: scheme.primary,
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        0,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.sm,
          AppSpacing.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: AppText(
                    '${l.accountsSummaryNet} · '
                    '${l.accountsSummaryWalletCount(state.accounts.length)}'
                    '${sharedCount > 0 ? ' ${l.accountsSummarySharedCount(sharedCount)}' : ''}',
                    role: AppTextRole.caption,
                    maxLines: 1,
                  ),
                ),
                const MoneyVisibilityToggle(),
                if (action != null) ...[
                  const SizedBox(width: AppSpacing.xs),
                  action!,
                ],
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: MoneyText(
                net == 0 ? 0 : net,
                style: AppTypography.of(context, AppTextRole.display),
              ),
            ),
            if (partsTotal > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: SegmentedBar(
                  legend: true,
                  segments: [
                    for (final p in parts)
                      BarSegment(
                        value: p.balance,
                        color: _colorOf(context, p.type),
                        label:
                            '${accountTypeLabel(context, p.type)} '
                            '${(p.balance / partsTotal * 100).round()}%',
                      ),
                  ],
                ),
              ),
            ],
            // With no debt, the money on hand IS the net — not twice.
            if (debt > 0) ...[
              const SizedBox(height: AppSpacing.sm),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(text: '${l.accountsSummaryAssets} '),
                    TextSpan(
                      text: moneyString(context, assets),
                      style: muted?.copyWith(fontWeight: strongWeight),
                    ),
                  ],
                ),
                style: muted,
              ),
            ],
            if (creditLimit > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ProgressRow(
                  label: l.accountsSummaryCreditUsed(
                    (creditUsed / creditLimit * 100).round(),
                    moneyString(context, creditLimit - creditUsed),
                  ),
                  value: (creditUsed / creditLimit).clamp(0.0, 1.0),
                  color: liability,
                ),
              ),
            ],
            if (bottom.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text.rich(TextSpan(children: bottom), style: muted),
            ],
            if (totals.otherCurrencyCount > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              AppText(
                l.accountsSummaryOtherCurrency(totals.otherCurrencyCount),
                role: AppTextRole.caption,
              ),
            ],
            if (totals.untrackedCount > 0) ...[
              const SizedBox(height: AppSpacing.xs),
              AppText(
                l.walletTrackUntrackedNote(totals.untrackedCount),
                role: AppTextRole.caption,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
