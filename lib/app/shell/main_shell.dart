import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_spacing.dart';
import '../../features/transactions/presentation/pages/transaction_form_page.dart';
import '../../l10n/gen/app_localizations.dart';
import 'main_bottom_nav.dart';
import 'main_top_bar.dart';
import 'more_menu_sheet.dart';

/// App chrome shared by every authed screen.
///
/// Every feature route now lives inside the shell so the bottom nav is
/// visible everywhere. Chrome adapts by depth:
/// - **At a branch root** (`/`, `/transactions`, `/accounts`) — full
///   chrome: top app bar + centered `+` FAB + bottom nav.
/// - **Deeper pages** (`/accounts/:id`, `/projects`, `/settings`, ...) —
///   bottom nav only; the page supplies its own [Scaffold] + [AppBar]
///   with a back button, and the shell FAB stays out of the way.
class MainShell extends StatelessWidget {
  const MainShell({
    required this.navigationShell,
    required this.currentPath,
    super.key,
  });

  /// The branched navigation tree managed by
  /// [StatefulShellRoute.indexedStack].
  final StatefulNavigationShell navigationShell;

  /// Current location path — drives the root-vs-deep chrome switch.
  final String currentPath;

  static const _branchRoots = {'/', '/transactions', '/accounts'};

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final atRoot = _branchRoots.contains(currentPath);

    final bottomNav = MainBottomNav(
      currentIndex: navigationShell.currentIndex,
      onTabSelected: (i) => navigationShell.goBranch(
        i,
        // Re-tapping the active tab pops to the branch root, matching the
        // behaviour users expect from native bottom nav.
        initialLocation: i == navigationShell.currentIndex,
      ),
      onAddPressed: () => showTransactionFormSheet(context),
      onMorePressed: () => MoreMenuSheet.show(context),
    );

    if (!atRoot) {
      // Deep page: it brings its own app bar; keep only the bottom nav.
      return Scaffold(
        body: navigationShell,
        bottomNavigationBar: bottomNav,
      );
    }

    final addFab = FloatingActionButton(
      tooltip: l.navAddTransaction,
      onPressed: () => showTransactionFormSheet(context),
      shape: const CircleBorder(),
      child: const Icon(Icons.add),
    );

    // Transactions tab root only (spec §10/4.24): quick create
    // project-from-bills — a second, labeled FAB stacked above the main
    // `+`. Distinct heroTag: two FABs on one route would otherwise
    // collide.
    final onTransactionsTab = navigationShell.currentIndex == 1;
    final fab = onTransactionsTab
        ? Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.extended(
                heroTag: 'quick-create-project-fab',
                onPressed: () => context.push('/projects/quick'),
                icon: const Icon(Icons.receipt_long_outlined, size: 18),
                label: Text(
                  l.quickCreateFabLabel,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              addFab,
            ],
          )
        : addFab;

    return Scaffold(
      appBar: MainTopBar(title: _titleFor(l, navigationShell.currentIndex)),
      body: navigationShell,
      floatingActionButton: fab,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: bottomNav,
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
