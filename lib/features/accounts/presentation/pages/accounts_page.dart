import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/shell_chrome.dart';
import '../../../../app/shell/tab_root_scaffold.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/account.dart';
import '../../domain/account_type.dart';
import '../cubit/accounts_cubit.dart';
import '../widgets/account_card.dart';

/// Wallets tab root (§10, owner 2026-10-10):
///
///   summary (mine only — the shared pot is never summed in, spec §14;
///   👁 hides amounts)
///   ของฉัน ⇅ · grid (2 col phone / 3 tablet) · dashed "+ เพิ่มกระเป๋า"
///   กระเป๋าร่วม ⇅ · grid
///   "กระเป๋าที่เก็บถาวร (n) ›"
///
/// ⇅ (or a long-press on a wallet) → reorder mode: a drag list per group,
/// save / cancel replacing the shell nav. The order is the caller's own,
/// saved mine-first in one PATCH /accounts/reorder (contract §3).
class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

/// One grid's mainAxisExtent: icon row · name · description · balance ·
/// credit bar. The skeleton uses it too.
const double _cardExtent = 156;

class _AccountsPageState extends State<AccountsPage> {
  int _archivedCount = 0;

  /// Non-null while reordering — the staged order, per group.
  List<Account>? _stagedMine;
  List<Account>? _stagedShared;
  bool _savingOrder = false;
  ShellChromeController? _shellChrome;

  bool get _reordering => _stagedMine != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shellChrome = ShellChrome.of(context);
  }

  @override
  void dispose() {
    if (_reordering) _shellChrome?.show();
    super.dispose();
  }

  void _enterReorder(List<Account> current) {
    HapticFeedback.lightImpact();
    _shellChrome?.hide(); // the action bar replaces the shell nav
    setState(() {
      _stagedMine = [
        for (final a in current)
          if (!a.isShared) a,
      ];
      _stagedShared = [
        for (final a in current)
          if (a.isShared) a,
      ];
    });
  }

  void _exitReorder() {
    _shellChrome?.show();
    setState(() {
      _stagedMine = null;
      _stagedShared = null;
      _savingOrder = false;
    });
  }

  void _move(List<Account> group, int from, int to) => setState(() {
    final item = group.removeAt(from);
    group.insert(to, item);
  });

  Future<void> _saveOrder() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _savingOrder = true);
    try {
      // One order for all of them: mine first, then the shared ones.
      await context.read<AccountsCubit>().saveOrder([
        ..._stagedMine!,
        ..._stagedShared!,
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
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountsCubit>().loadIfNeeded();
      _loadArchivedCount();
    });
  }

  Future<void> _loadArchivedCount() async {
    try {
      final list = await context.read<AccountsCubit>().listArchived();
      if (mounted) setState(() => _archivedCount = list.length);
    } on ApiException {
      // Optional link — keep the last count.
    }
  }

  Future<void> _refresh() async {
    await context.read<AccountsCubit>().load();
    await _loadArchivedCount();
  }

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
    return TabRootScaffold(
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
              if (_reordering) return _reorderView(context);
              return _gridView(context, accounts, cols);
            },
          );
        },
      ),
    );
  }

  Widget _gridView(BuildContext context, List<Account> accounts, int cols) {
    final l = AppLocalizations.of(context)!;
    final mine = [
      for (final a in accounts)
        if (!a.isShared) a,
    ];
    final shared = [
      for (final a in accounts)
        if (a.isShared) a,
    ];
    Widget reorderButton() => IconButton(
      tooltip: l.accountsReorder,
      icon: const Icon(AppIcons.reorder),
      onPressed: () => _enterReorder(accounts),
    );
    // One group: header (⇅ when it has two to swap), then its cards.
    List<Widget> group(String title, List<Account> list, {bool add = false}) =>
        [
          SliverToBoxAdapter(
            child: SectionHeader(
              title: title,
              count: list.length,
              trailing: list.length < 2 ? null : reorderButton(),
            ),
          ),
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
                    onTap: () => context.push('/accounts/new'),
                  );
                }
                final a = list[i];
                return GestureDetector(
                  onLongPress: accounts.length < 2
                      ? null
                      : () => _enterReorder(accounts),
                  child: AccountCard(
                    account: a,
                    horizontal: false,
                    onTap: () => context.push('/accounts/${a.id}'),
                  ),
                );
              }, childCount: list.length + (add ? 1 : 0)),
            ),
          ),
        ];
    return PullToRefresh(
      onRefresh: _refresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Clear the transparent top bar.
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.paddingOf(context).top),
          ),
          SliverToBoxAdapter(child: _WalletsSummary(accounts: accounts)),
          ...group(l.accountsGroupMine, mine, add: true),
          if (shared.isNotEmpty) ...group(l.walletSharedLabel, shared),
          if (_archivedCount > 0)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: DetailRow(
                  leading: const Icon(AppIcons.archive),
                  label: l.accountsArchivedLink(_archivedCount),
                  showChevron: true,
                  onTap: () async {
                    await context.push('/accounts/archived');
                    if (mounted) _loadArchivedCount();
                  },
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

  /// Reorder mode: a hint, a drag list per group (a wallet stays in its
  /// group), and save / cancel at the bottom.
  Widget _reorderView(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final mine = _stagedMine!;
    final shared = _stagedShared!;
    Widget list(List<Account> group) => ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: group.length,
      onReorderItem: (from, to) => _move(group, from, to),
      itemBuilder: (context, i) {
        final a = group[i];
        return Padding(
          key: ValueKey(a.id),
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            children: [
              Expanded(child: AccountCard(account: a, horizontal: true)),
              ReorderableDragStartListener(
                index: i,
                child: const Padding(
                  padding: EdgeInsets.all(AppSpacing.md),
                  child: Icon(AppIcons.reorder),
                ),
              ),
            ],
          ),
        );
      },
    );
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.only(
              // Clear the transparent top bar.
              top: MediaQuery.paddingOf(context).top + AppSpacing.sm,
              bottom: AppSpacing.lg,
            ),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: Text(
                  l.accountsReorderHint,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (mine.isNotEmpty) ...[
                SectionHeader(title: l.accountsGroupMine, count: mine.length),
                list(mine),
              ],
              if (shared.isNotEmpty) ...[
                SectionHeader(title: l.walletSharedLabel, count: shared.length),
                list(shared),
              ],
            ],
          ),
        ),
        ModeActionBar(
          canSave: true,
          saving: _savingOrder,
          cancelLabel: l.accountsReorderDiscard,
          saveLabel: l.accountsReorderSave,
          onCancel: _exitReorder,
          onSave: _saveOrder,
        ),
      ],
    );
  }
}

/// Wallet-tab dashboard. "Mine" figures only — the shared pot is shown on
/// its own line and never summed into them (spec §14); 👁 hides amounts.
///
/// - Net = what I have − what I owe ([Account.asset] / [Account.debt]:
///   an overpaid card is money I have, an overdrawn wallet is debt)
/// - What the money on hand is made of (a bar by wallet type)
/// - Money on hand · debt · shared pot
/// - Credit-limit usage across my cards ([Account.creditUsed])
class _WalletsSummary extends StatelessWidget {
  const _WalletsSummary({required this.accounts});
  final List<Account> accounts;

  static Tone _toneOf(AccountType t) => switch (t) {
    AccountType.cash => Tone.success,
    AccountType.bank => Tone.info,
    AccountType.eWallet => Tone.primary,
    _ => Tone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    var debt = 0.0;
    var shared = 0.0;
    var hasShared = false;
    var creditUsed = 0.0;
    var creditLimit = 0.0;
    var mineCount = 0;
    final byType = <AccountType, double>{};
    for (final a in accounts) {
      if (a.isShared) {
        hasShared = true;
        shared += a.balance;
        continue;
      }
      mineCount++;
      debt += a.debt;
      if (a.asset > 0) byType[a.type] = (byType[a.type] ?? 0) + a.asset;
      final limit = a.creditLimit;
      if (a.type.isCredit && limit != null && limit > 0) {
        creditLimit += limit;
        creditUsed += a.creditUsed.clamp(0, limit);
      }
    }
    final assets = byType.values.fold(0.0, (s, v) => s + v);
    final net = assets - debt;
    final parts = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return TintedCard(
      tint: scheme.primary,
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
                    '${l.accountsSummaryWalletCount(mineCount)}',
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
                net,
                style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            if (assets > 0) ...[
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
                            flex: (p.value / assets * 1000).round().clamp(
                              1,
                              1000,
                            ),
                            child: ColoredBox(
                              color: _toneOf(p.key).color(context),
                            ),
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
                            color: _toneOf(p.key).color(context),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${accountTypeLabel(context, p.key)} '
                          '${(p.value / assets * 100).round()}%',
                          style: textTheme.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            SummaryStats(
              stats: [
                SummaryStat(label: l.accountsSummaryAssets, amount: assets),
                if (debt > 0)
                  SummaryStat(
                    label: l.accountsSummaryDebt,
                    amount: debt,
                    tone: MoneyTone.expense,
                  ),
                if (hasShared)
                  SummaryStat(label: l.accountsTotalShared, amount: shared),
              ],
            ),
            if (creditLimit > 0) ...[
              const SizedBox(height: AppSpacing.md),
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: ProgressRow(
                  label: l.accountsSummaryCreditUsed(
                    (creditUsed / creditLimit * 100).round(),
                    moneyString(context, creditLimit - creditUsed),
                  ),
                  value: creditUsed / creditLimit,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Loading placeholder mirroring the real layout: summary, a group header
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
          alignment: Alignment.centerLeft,
          child: SkeletonBox(width: 96, height: 20, borderRadius: AppRadius.xs),
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
