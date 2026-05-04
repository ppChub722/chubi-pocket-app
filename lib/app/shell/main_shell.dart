import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/transactions/presentation/pages/transaction_form_page.dart';
import '../../l10n/gen/app_localizations.dart';
import 'main_bottom_nav.dart';
import 'main_top_bar.dart';
import 'more_menu_sheet.dart';

/// App chrome shared by every primary tab (Dashboard / Transactions /
/// Accounts).
///
/// Owns the top app bar, the bottom navigation, and the centered `+`
/// FAB. Sub-pages routed outside this shell (`/settings`,
/// `/accounts/:id`, `/projects`, etc.) supply their own [Scaffold] +
/// [AppBar] with a back button.
class MainShell extends StatelessWidget {
  const MainShell({required this.navigationShell, super.key});

  /// The branched navigation tree managed by
  /// [StatefulShellRoute.indexedStack].
  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: MainTopBar(title: _titleFor(l, navigationShell.currentIndex)),
      body: navigationShell,
      floatingActionButton: FloatingActionButton(
        tooltip: l.navAddTransaction,
        onPressed: () => showTransactionFormSheet(context),
        shape: const CircleBorder(),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: MainBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTabSelected: (i) => navigationShell.goBranch(
          i,
          // Re-tapping the active tab pops to the branch root, matching the
          // behaviour users expect from native bottom nav.
          initialLocation: i == navigationShell.currentIndex,
        ),
        onAddPressed: () => showTransactionFormSheet(context),
        onMorePressed: () => MoreMenuSheet.show(context),
      ),
    );
  }

  String _titleFor(AppLocalizations l, int index) {
    switch (index) {
      case 0:
        return l.navDashboard;
      case 1:
        return l.navTransactions;
      case 2:
        return l.navAccounts;
      default:
        return l.appName;
    }
  }

}
