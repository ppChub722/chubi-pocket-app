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
import '../widgets/account_card.dart';

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
        final c = b.$2.balance.compareTo(a.$2.balance);
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
            return AsyncStateView(
              loading:
                  state.status == AccountsStatus.initial ||
                  state.status == AccountsStatus.loading,
              error: state.error,
              isEmpty: accounts.isEmpty,
              onRetry: context.read<AccountsCubit>().load,
              skeleton: _AccountsSkeleton(cols: cols),
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
              builder: (context) {
                if (_reordering) return _reorderView(context, accounts);
                return _gridView(context, state, cols);
              },
            );
          },
        ),
      ),
    );
  }

  /// `✏️ ……… [sort ▾]` — the list's edit mode left (✏️ = the list's edit
  /// mode, owner 2026-10-11), the order right. No search.
  Widget _toolbar(AppLocalizations l, List<Account> accounts) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          AppIconButton.edit(
            tooltip: l.accountsReorder,
            onPressed: _canReorder(accounts)
                ? () => _enterReorder(accounts)
                : null,
          ),
          const Spacer(),
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
      ),
    );
  }

  Widget _gridView(BuildContext context, AccountsState state, int cols) {
    final accounts = state.accounts;
    final l = AppLocalizations.of(context)!;
    final list = _sorted(accounts);
    return PullToRefresh(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Clear the transparent top bar.
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).top),
          ),
          SliverToBoxAdapter(child: _WalletsSummary(state: state)),
          SliverToBoxAdapter(child: _toolbar(l, accounts)),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                mainAxisSpacing: AppSpacing.md,
                crossAxisSpacing: AppSpacing.md,
                mainAxisExtent: _cardExtent,
              ),
              delegate: SliverChildBuilderDelegate((context, i) {
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
              }, childCount: list.length + 1),
            ),
          ),
          if (state.archivedCount > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: DetailRow(
                  leading: const AppIcon(AppIcons.archive),
                  label: l.accountsArchivedLink(state.archivedCount),
                  showChevron: true,
                  onTap: () => _open(() => context.push('/accounts/archived')),
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: SizedBox(height: 96 + MediaQuery.paddingOf(context).bottom),
          ),
        ],
      ),
    );
  }

  /// Reorder mode (the kit's, flat): a hint, the wallets with ⠿ handles
  /// (drag at once; tap → the ↑ ↓ bar), then the move bar + ยกเลิก / ↶ /
  /// บันทึก at the bottom.
  Widget _reorderView(BuildContext context, List<Account> accounts) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
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
                  child: Text(
                    l.accountsReorderTapHint,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
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
  const _WalletsSummary({required this.state});
  final AccountsState state;

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
    final textTheme = Theme.of(context).textTheme;
    final palette = Theme.of(context).extension<AppColors>()!;
    final liability = palette.walletLiability;
    final muted = textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);

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
          style: TextStyle(color: liability, fontWeight: FontWeight.w600),
        ),
      ],
      if (sharedCount > 0) ...[
        if (debt > 0) const TextSpan(text: '  ·  '),
        TextSpan(text: '${l.accountsSummarySharedPot} '),
        TextSpan(
          text: moneyString(context, totals.sharedBalance),
          style: const TextStyle(fontWeight: FontWeight.w600),
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
                  child: Text(
                    '${l.accountsSummaryNet} · '
                    '${l.accountsSummaryWalletCount(state.accounts.length)}'
                    '${sharedCount > 0 ? ' ${l.accountsSummarySharedCount(sharedCount)}' : ''}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.labelLarge?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const MoneyVisibilityToggle(),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: MoneyText(
                net == 0 ? 0 : net,
                style: textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (partsTotal > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: SizedBox(
                    height: 8,
                    child: Row(
                      // Childless ColoredBoxes collapse to 0 height otherwise.
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (final p in parts)
                          Expanded(
                            flex: (p.balance / partsTotal * 1000).round().clamp(
                              1,
                              1000,
                            ),
                            child: ColoredBox(color: _colorOf(context, p.type)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final p in parts)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _colorOf(context, p.type),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${accountTypeLabel(context, p.type)} '
                          '${(p.balance / partsTotal * 100).round()}%',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                ],
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
                      style: const TextStyle(fontWeight: FontWeight.w600),
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
              Text(
                l.accountsSummaryOtherCurrency(totals.otherCurrencyCount),
                style: muted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading placeholder mirroring the real layout: summary, the toolbar
/// and the grid at the cards' own height.
class _AccountsSkeleton extends StatelessWidget {
  const _AccountsSkeleton({required this.cols});
  final int cols;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        MediaQuery.paddingOf(context).top + AppSpacing.sm,
        AppSpacing.lg,
        MediaQuery.paddingOf(context).bottom,
      ),
      children: [
        const SkeletonBox(height: 168, borderRadius: AppRadius.md),
        const SizedBox(height: AppSpacing.lg),
        const Align(
          alignment: Alignment.centerRight,
          child: SkeletonBox(
            width: 120,
            height: 28,
            borderRadius: AppRadius.xs,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: cols * 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            mainAxisExtent: _cardExtent,
          ),
          itemBuilder: (_, _) => const SkeletonBox(
            height: _cardExtent,
            borderRadius: AppRadius.lg,
          ),
        ),
      ],
    );
  }
}
