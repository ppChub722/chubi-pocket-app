import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/shell/tab_root_scaffold.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import 'package:flutter/services.dart';
import '../../../../app/shell/shell_chrome.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/skeleton_box.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/account.dart';
import '../../domain/account_type.dart';
import '../cubit/accounts_cubit.dart';
import '../widgets/account_card.dart';

/// Wallets tab root (§10). Wallet dashboard (mine — shared pot never summed,
/// spec §14; 👁 hides them) → wallet grid (2 col phone / 3 col tablet) →
/// dashed "+ เพิ่มกระเป๋า" → "กระเป๋าที่เก็บถาวร (n) ›". Long-press a wallet
/// → reorder mode (drag list + save / cancel bar replacing the shell nav);
/// the order is the caller's own, shared wallets included (contract §3).
class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  int _archivedCount = 0;

  /// Non-null while reordering — the staged order.
  List<Account>? _staged;
  bool _savingOrder = false;
  ShellChromeController? _shellChrome;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _shellChrome = ShellChrome.of(context);
  }

  @override
  void dispose() {
    if (_staged != null) _shellChrome?.show();
    super.dispose();
  }

  void _enterReorder(List<Account> current) {
    HapticFeedback.lightImpact();
    _shellChrome?.hide(); // the action bar replaces the shell nav
    setState(() => _staged = [...current]);
  }

  void _exitReorder() {
    _shellChrome?.show();
    setState(() {
      _staged = null;
      _savingOrder = false;
    });
  }

  void _move(int from, int to) => setState(() {
    final item = _staged!.removeAt(from);
    _staged!.insert(to, item);
  });

  Future<void> _saveOrder() async {
    final l = AppLocalizations.of(context)!;
    setState(() => _savingOrder = true);
    try {
      await context.read<AccountsCubit>().saveOrder(_staged!);
      if (mounted) _exitReorder();
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _savingOrder = false);
      showAppSnackBar(
        context,
        '${l.categoriesReorderSave}: ${e.message}',
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
            // No empty view: the grid's add tile is the first-wallet CTA.
            builder: (context) {
              final staged = _staged;
              if (staged != null) return _reorderView(context, staged);
              return PullToRefresh(
                onRefresh: _refresh,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Clear the transparent top bar.
                    SliverToBoxAdapter(
                      child: SizedBox(
                        height: MediaQuery.paddingOf(context).top,
                      ),
                    ),
                    if (accounts.isNotEmpty)
                      SliverToBoxAdapter(
                        child: _WalletsSummary(accounts: accounts),
                      ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.lg,
                        AppSpacing.md,
                        AppSpacing.lg,
                        0,
                      ),
                      sliver: SliverGrid(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: cols,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          // Icon row · name · description · balance · credit bar.
                          mainAxisExtent: 156,
                        ),
                        delegate: SliverChildBuilderDelegate((context, i) {
                          if (i == accounts.length) {
                            return AddTile(
                              label: l.accountsAddNew,
                              onTap: () => context.push('/accounts/new'),
                            );
                          }
                          final a = accounts[i];
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
                        }, childCount: accounts.length + 1),
                      ),
                    ),
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
                    const SliverToBoxAdapter(child: SizedBox(height: 96)),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

extension on _AccountsPageState {
  /// Reorder mode: a hint, the drag list, and save / cancel at the bottom.
  Widget _reorderView(BuildContext context, List<Account> staged) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Padding(
          // Top: clear the transparent top bar.
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            MediaQuery.paddingOf(context).top + AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: Text(
            l.accountsReorderHint,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            itemCount: staged.length,
            onReorderItem: _move,
            itemBuilder: (context, i) {
              final a = staged[i];
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
          ),
        ),
        ModeActionBar(
          canSave: true,
          saving: _savingOrder,
          cancelLabel: l.categoriesReorderDiscard,
          saveLabel: l.categoriesReorderSave,
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
/// - Net balance (all my wallets; card / pay-later debt is negative)
/// - What the money on hand is made of (cash · bank · e-wallet bar)
/// - Money on hand · card debt · shared pot
/// - Credit-limit usage across my cards, when any has a limit
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

    var net = 0.0;
    var debt = 0.0;
    var shared = 0.0;
    var hasShared = false;
    var hasCredit = false;
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
      net += a.balance;
      if (a.type.isCredit) {
        hasCredit = true;
        if (a.balance < 0) debt += -a.balance;
        final limit = a.creditLimit;
        if (limit != null && limit > 0) {
          creditLimit += limit;
          creditUsed += a.balance.abs().clamp(0, limit);
        }
      } else if (a.balance > 0) {
        byType[a.type] = (byType[a.type] ?? 0) + a.balance;
      }
    }
    final assets = byType.values.fold(0.0, (s, v) => s + v);
    final parts = byType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Card(
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
                if (hasCredit)
                  SummaryStat(
                    label: l.accountsSummaryDebt,
                    amount: debt,
                    tone: debt > 0 ? MoneyTone.expense : MoneyTone.plain,
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

/// Loading placeholder mirroring the real layout: summary + 2-col grid.
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
        0,
      ),
      children: [
        const SkeletonBox(height: 168, borderRadius: AppRadius.md),
        const SizedBox(height: AppSpacing.md),
        GridView.count(
          crossAxisCount: cols,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AppSpacing.md,
          crossAxisSpacing: AppSpacing.md,
          childAspectRatio: 1.05,
          children: [
            for (var i = 0; i < cols * 2; i++)
              const SkeletonBox(height: 150, borderRadius: AppRadius.lg),
          ],
        ),
      ],
    );
  }
}
