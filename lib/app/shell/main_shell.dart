import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import 'main_bottom_nav.dart';
import 'main_top_bar.dart';
import 'more_menu_sheet.dart';

/// App chrome shared by every primary tab (Dashboard / Accounts / Projects).
///
/// Owns the top app bar, the bottom navigation, and the centered `+` FAB.
/// Sub-pages routed outside this shell (e.g. `/settings`, `/accounts/:id`)
/// supply their own [Scaffold] + [AppBar] with a back button.
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
        onPressed: () => _showAddComingSoon(context, l),
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
        onAddPressed: () => _showAddComingSoon(context, l),
        onMorePressed: () => MoreMenuSheet.show(context),
      ),
    );
  }

  String _titleFor(AppLocalizations l, int index) {
    switch (index) {
      case 0:
        return l.navDashboard;
      case 1:
        return l.navAccounts;
      case 2:
        return l.navProjects;
      default:
        return l.appName;
    }
  }

  void _showAddComingSoon(BuildContext context, AppLocalizations l) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(l.addTransactionComingSoon)),
      );
  }
}
