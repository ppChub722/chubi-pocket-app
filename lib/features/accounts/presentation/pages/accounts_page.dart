import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import 'package:flutter/services.dart';
import '../../../../app/shell/shell_chrome.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/account.dart';
import '../cubit/accounts_cubit.dart';
import '../widgets/account_card.dart';

/// Wallets tab root (§10). Totals card (mine · shared pot — never summed,
/// spec §14; 👁 hides them) → wallet grid (1 col phone / 2 col tablet) →
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
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        final accounts = state.accounts;
        if (state.status == AccountsStatus.loading && accounts.isEmpty) {
          return ListView(
            children: [for (var i = 0; i < 4; i++) const SkeletonListTile()],
          );
        }
        final staged = _staged;
        if (staged != null) return _reorderView(context, staged);
        final cols = MediaQuery.sizeOf(context).shortestSide >= 600 ? 2 : 1;
        return PullToRefresh(
          onRefresh: _refresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (accounts.isNotEmpty)
                SliverToBoxAdapter(child: _TotalsCard(accounts: accounts)),
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
                    // Room for description/note + shared-member avatars.
                    mainAxisExtent: 108,
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
                        horizontal: true,
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
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
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
                        child: Icon(Icons.drag_handle),
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

/// Mine and the shared pot side by side (never summed — spec §14).
class _TotalsCard extends StatelessWidget {
  const _TotalsCard({required this.accounts});
  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    var mine = 0.0;
    var shared = 0.0;
    var hasShared = false;
    for (final a in accounts) {
      if (a.isShared) {
        hasShared = true;
        shared += a.balance;
      } else {
        mine += a.balance;
      }
    }
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
            const Align(
              alignment: Alignment.centerRight,
              child: MoneyVisibilityToggle(),
            ),
            SummaryStats(
              stats: [
                SummaryStat(label: l.accountsTotalMine, amount: mine),
                if (hasShared)
                  SummaryStat(label: l.accountsTotalShared, amount: shared),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
