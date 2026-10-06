import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/account.dart';
import '../cubit/accounts_cubit.dart';
import '../widgets/account_card.dart';

/// Wallets tab root (§10). Totals card (mine · shared pot — never summed,
/// spec §14; 👁 hides them) → wallet grid (1 col phone / 2 col tablet) →
/// dashed "+ เพิ่มกระเป๋า" → "กระเป๋าที่เก็บถาวร (n) ›". Reorder waits on
/// `PATCH /accounts/reorder` (contract §3).
class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  int _archivedCount = 0;

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
          return ListView(children: [
            for (var i = 0; i < 4; i++) const SkeletonListTile(),
          ]);
        }
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
                    AppSpacing.lg, AppSpacing.md, AppSpacing.lg, 0),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    mainAxisSpacing: AppSpacing.md,
                    crossAxisSpacing: AppSpacing.md,
                    // Room for description/note + shared-member avatars.
                    mainAxisExtent: 108,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      if (i == accounts.length) {
                        return AddTile(
                          label: l.accountsAddNew,
                          onTap: () => context.push('/accounts/new'),
                        );
                      }
                      final a = accounts[i];
                      return AccountCard(
                        account: a,
                        horizontal: true,
                        onTap: () => context.push('/accounts/${a.id}'),
                      );
                    },
                    childCount: accounts.length + 1,
                  ),
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
          AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg, AppSpacing.sm, AppSpacing.sm, AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Align(
              alignment: Alignment.centerRight,
              child: MoneyVisibilityToggle(),
            ),
            SummaryStats(stats: [
              SummaryStat(label: l.accountsTotalMine, amount: mine),
              if (hasShared)
                SummaryStat(label: l.accountsTotalShared, amount: shared),
            ]),
          ],
        ),
      ),
    );
  }
}
