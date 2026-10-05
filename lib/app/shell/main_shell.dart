import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/transactions/presentation/pages/transaction_form_page.dart';
import '../../l10n/gen/app_localizations.dart';
import 'main_bottom_nav.dart';
import 'main_top_bar.dart';
import 'more_menu_sheet.dart';
import 'shell_chrome.dart';

/// App chrome shared by every authed screen.
///
/// Every feature route now lives inside the shell so the bottom nav is
/// visible everywhere. Chrome adapts by depth:
/// - **At a branch root** (`/`, `/transactions`, `/accounts`) — full
///   chrome: top app bar + centered `+` FAB + bottom nav.
/// - **Deeper pages** (`/accounts/:id`, `/projects`, `/settings`, ...) —
///   bottom nav only; the page supplies its own [Scaffold] + [AppBar]
///   with a back button, and the shell FAB stays out of the way.
///
/// A page can also **take over the bottom chrome** via [ShellChrome]: when
/// it calls [ShellChromeController.hide] (e.g. categories' reorder mode),
/// the shell drops its bottom nav + FAB so the page's own contextual
/// action bar replaces them instead of stacking under them.
class MainShell extends StatefulWidget {
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

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final ShellChromeController _chrome = ShellChromeController();

  static const _branchRoots = {'/', '/transactions', '/accounts'};

  @override
  void dispose() {
    _chrome.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShellChrome(
      controller: _chrome,
      // Only the chrome (nav + FAB) needs to rebuild when a page toggles
      // the controller — the branch content underneath is untouched.
      child: ListenableBuilder(
        listenable: _chrome,
        builder: (context, _) => _buildScaffold(context),
      ),
    );
  }

  Widget _buildScaffold(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final atRoot = _branchRoots.contains(widget.currentPath);
    final hidden = _chrome.hidden;

    final bottomNav = hidden
        ? null
        : MainBottomNav(
            currentIndex: widget.navigationShell.currentIndex,
            onTabSelected: (i) => widget.navigationShell.goBranch(
              i,
              // Re-tapping the active tab pops to the branch root, matching
              // the behaviour users expect from native bottom nav.
              initialLocation: i == widget.navigationShell.currentIndex,
            ),
            onAddPressed: () => showTransactionFormSheet(context),
            onMorePressed: () => MoreMenuSheet.show(context),
          );

    if (!atRoot) {
      // Deep page: it brings its own app bar; keep only the bottom nav.
      return Scaffold(
        body: widget.navigationShell,
        bottomNavigationBar: bottomNav,
      );
    }

    return Scaffold(
      appBar: MainTopBar(title: _titleFor(l, widget.navigationShell.currentIndex)),
      body: widget.navigationShell,
      // Quick create event-from-bills lives INSIDE the + sheet as a
      // collapsible section (spec §10/4.24) — no second FAB.
      floatingActionButton: hidden
          ? null
          : FloatingActionButton(
              tooltip: l.navAddTransaction,
              onPressed: () => showTransactionFormSheet(context),
              shape: const CircleBorder(),
              child: const Icon(Icons.add),
            ),
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
