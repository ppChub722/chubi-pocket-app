import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../domain/account.dart';
import '../cubit/accounts_cubit.dart';
import '../widgets/account_card.dart';
import '../widgets/add_account_tile.dart';

/// Wallets grid (single unified list — shared wallets mix in, spec §14).
///
/// Responsive (APK only — web target lives in a separate repo):
/// - **Phone** (shortestSide < 600 dp), portrait or landscape → **1 col**
/// - **Tablet** (shortestSide >= 600 dp), any orientation → **2 col**
///
/// Card layout is always the **horizontal row** style — icon · name+type ·
/// balance — because the vertical/stacked layout looked off in narrow
/// 2-col mode. We accept slightly less density on tablets in exchange for
/// a single, consistent card visual.
///
/// The [AddAccountTile] is rendered as the **last** item in the grid (not
/// first). Tapping it opens the create form.
class AccountsPage extends StatefulWidget {
  const AccountsPage({super.key});

  @override
  State<AccountsPage> createState() => _AccountsPageState();
}

class _AccountsPageState extends State<AccountsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AccountsCubit>().loadIfNeeded();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AccountsCubit, AccountsState>(
      builder: (context, state) {
        final accounts = state.accounts;
        final isLoading = state.status == AccountsStatus.loading &&
            accounts.isEmpty;
        if (isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
        final cols = isTablet ? 2 : 1;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (accounts.isNotEmpty) _TotalsHeader(accounts: accounts),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                // mainAxisExtent locks the row height regardless of column
                // count, so cards stay readable on narrow tablet columns
                // instead of collapsing into squashed pills.
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cols,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  // 108 dp leaves room for an optional description / note
                  // line under the type label PLUS the shared-member
                  // avatar stack (spec §14) without squishing the icon
                  // or balance.
                  mainAxisExtent: 108,
                ),
                itemCount: accounts.length + 1,
                itemBuilder: (context, index) {
                  if (index == accounts.length) {
                    return AddAccountTile(onTap: () => _onAddTap(context));
                  }
                  final account = accounts[index];
                  return AccountCard(
                    account: account,
                    horizontal: true,
                    onTap: () => context.push('/accounts/${account.id}'),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  void _onAddTap(BuildContext context) {
    context.push('/accounts/new');
  }
}

/// Split header totals (spec §14 / B2): personal-wallet balances and
/// shared-wallet balances are NEVER summed into one number — "mine" is
/// my money, "shared" is the pot. The shared part only appears when at
/// least one shared wallet exists.
class _TotalsHeader extends StatelessWidget {
  const _TotalsHeader({required this.accounts});
  final List<Account> accounts;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    double mine = 0;
    double shared = 0;
    var hasShared = false;
    for (final a in accounts) {
      if (a.isShared) {
        hasShared = true;
        shared += a.balance;
      } else {
        mine += a.balance;
      }
    }
    final parts = <String>[
      l.walletsHeaderMine(CurrencyFormatter.format(mine)),
      if (hasShared) l.walletsHeaderShared(CurrencyFormatter.format(shared)),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        0,
      ),
      child: Text(
        parts.join(' · '),
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}
