import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_spacing.dart';
import '../cubit/accounts_cubit.dart';
import '../widgets/account_card.dart';
import '../widgets/add_account_tile.dart';

/// Accounts grid — Phase 0 mock implementation.
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
        return GridView.builder(
          padding: const EdgeInsets.all(AppSpacing.lg),
          // mainAxisExtent locks the row height regardless of column count,
          // so cards stay readable on narrow tablet columns instead of
          // collapsing into squashed pills.
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            mainAxisSpacing: AppSpacing.md,
            crossAxisSpacing: AppSpacing.md,
            // 96 dp leaves room for an optional description / note line
            // under the type label without squishing the icon or
            // balance. Cards without those fields render with a tiny
            // bit of extra padding — acceptable trade for consistency.
            mainAxisExtent: 96,
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
        );
      },
    );
  }

  void _onAddTap(BuildContext context) {
    context.push('/accounts/new');
  }
}
