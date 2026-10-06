import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/transactions/presentation/pages/transaction_form_page.dart';
import '../../l10n/gen/app_localizations.dart';
import 'app_top_bar.dart';
import 'main_bottom_nav.dart';
import 'shell_chrome.dart';

/// App chrome shared by every tab-layer screen.
///
/// Bottom nav + the centred `+` quick-create FAB show on **every** page.
/// Chrome adapts by depth:
/// - **At a branch root** (`/`, `/transactions`, `/accounts`) — the shell
///   also renders the [AppTopBar].
/// - **Deeper pages** (`/accounts/:id`, `/contacts`, ...) — the page
///   supplies its own [Scaffold] + top bar with a back button.
/// - "More"-menu pages highlight the เพิ่มเติม slot.
/// Settings / notifications are NOT here — they're the overlay layer on
/// the root navigator (no nav, no FAB).
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

  static const _branchRoots = {'/', '/transactions', '/accounts', '/more'};

  /// Branch index of the เพิ่มเติม tab (see app_router.dart).
  static const _moreBranch = 3;

  void _goBranch(int i) => widget.navigationShell.goBranch(
        i,
        // Re-tapping the active tab pops to the branch root, matching the
        // behaviour users expect from native bottom nav.
        initialLocation: i == widget.navigationShell.currentIndex,
      );

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
            moreSelected: widget.navigationShell.currentIndex == _moreBranch,
            onTabSelected: _goBranch,
            onAddPressed: () => showTransactionFormSheet(context),
            onMorePressed: () => _goBranch(_moreBranch),
          );

    // The `+` quick-create FAB shows on every page, docked in the nav's
    // notch; it leaves together with the nav in edit mode. Quick create
    // event-from-bills lives INSIDE the + sheet (spec §10/4.24).
    final fab = hidden
        ? null
        : FloatingActionButton(
            tooltip: l.navAddTransaction,
            onPressed: () => showTransactionFormSheet(context),
            shape: const CircleBorder(),
            child: const Icon(Icons.add),
          );

    return Scaffold(
      // Tab roots get the shell's top bar; deeper pages bring their own.
      appBar: atRoot
          ? AppTopBar(title: _titleFor(l, widget.navigationShell.currentIndex))
          : null,
      body: widget.navigationShell,
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
      case _moreBranch:
        return l.navMore;
      default:
        return l.appName;
    }
  }
}
