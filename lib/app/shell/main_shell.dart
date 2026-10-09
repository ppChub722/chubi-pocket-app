import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/feedback/confirm_dialog.dart';

import '../../features/transactions/presentation/widgets/quick_create_sheet.dart';
import 'main_bottom_nav.dart';
import 'shell_chrome.dart';

/// App chrome shared by every tab-layer screen.
///
/// The shell owns only the floating bottom nav (with its centred `+`
/// quick-create button), shown on **every** page. Top bars belong to the
/// pages: tab roots use [TabRootScaffold] (transparent bar, content scrolls
/// under it), deeper pages bring their own [Scaffold] + back button — so
/// pushing a page never changes the shell's layout mid-transition.
/// "More"-menu pages highlight the เพิ่มเติม slot. Settings / notifications
/// are NOT here — they're the overlay layer on the root navigator (no nav).
///
/// A page can also **take over the bottom chrome** via [ShellChrome]: when
/// it calls [ShellChromeController.hide] (e.g. categories' reorder mode),
/// the nav slides away so the page's own contextual action bar replaces it
/// instead of stacking under it.
class MainShell extends StatefulWidget {
  const MainShell({required this.navigationShell, super.key});

  /// The branched navigation tree managed by [StatefulShellRoute].
  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final ShellChromeController _chrome = ShellChromeController();

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

  /// A fling this fast (px/s) sideways moves to the neighbouring tab.
  static const _minFlingVelocity = 300.0;

  /// Swipe between tabs (owner 2026-10-09) — only on a tab's root page
  /// (nothing pushed in that tab) and not while a page has taken over the
  /// bottom chrome (edit / reorder). Anything inside that wants a sideways
  /// drag — an in-page tab pager, a horizontal chip row, swipe-to-dismiss —
  /// is deeper in the gesture arena and wins, so this only fires where
  /// nothing else claims the gesture.
  void _onFling(DragEndDetails d) {
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < _minFlingVelocity || _chrome.hidden) return;
    final shell = widget.navigationShell;
    final branchNav = shell.route.branches[shell.currentIndex].navigatorKey;
    if (branchNav.currentState?.canPop() ?? true) return;
    // Swipe left (negative) → the tab to the right.
    final next = shell.currentIndex + (v < 0 ? 1 : -1);
    if (next < 0 || next >= shell.route.branches.length) return;
    HapticFeedback.selectionClick();
    _goBranch(next);
  }

  /// Branch index of the dashboard (หน้าแรก).
  static const _homeBranch = 0;

  bool _askingExit = false;

  /// Back with nothing left to pop (a tab's root page — pushed pages,
  /// sheets and the overlay layer pop before this is reached): another tab
  /// → the dashboard; the dashboard → "ปิดแอป?" (owner 2026-10-09).
  Future<void> _onBackAtRoot() async {
    if (widget.navigationShell.currentIndex != _homeBranch) {
      _goBranch(_homeBranch);
      return;
    }
    if (_askingExit) return;
    _askingExit = true;
    final l = AppLocalizations.of(context)!;
    final ok = await showConfirmDialog(
      context,
      title: l.appExitTitle,
      confirmLabel: l.appExitConfirm,
    );
    _askingExit = false;
    if (ok) await SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // The shell is the root navigator's only page, so a back that reaches
      // it would close the app — handle it instead.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _onBackAtRoot();
      },
      child: _shell(context),
    );
  }

  Widget _shell(BuildContext context) {
    return ShellChrome(
      controller: _chrome,
      child: Scaffold(
        body: GestureDetector(
          behavior: HitTestBehavior.translucent,
          onHorizontalDragEnd: _onFling,
          child: widget.navigationShell,
        ),
        // Only the nav rebuilds when a page toggles the controller — the
        // branch content underneath is untouched.
        bottomNavigationBar: ListenableBuilder(
          listenable: _chrome,
          builder: (context, _) => _animatedNav(context),
        ),
      ),
    );
  }

  /// The nav slides down / back up instead of popping, so the body resizes
  /// smoothly when a form or edit mode takes over the bottom.
  Widget _animatedNav(BuildContext context) {
    final hidden = _chrome.hidden;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 240),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => SizeTransition(
        sizeFactor: animation,
        alignment: Alignment.topCenter,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: hidden
          ? const SizedBox(key: ValueKey('nav-hidden'), width: double.infinity)
          : MainBottomNav(
              key: const ValueKey('nav'),
              currentIndex: widget.navigationShell.currentIndex,
              moreSelected: widget.navigationShell.currentIndex == _moreBranch,
              onTabSelected: _goBranch,
              // Quick create event-from-bills lives INSIDE the + sheet
              // (spec §10/4.24).
              onAddPressed: () => showQuickCreateSheet(context),
              onMorePressed: () => _goBranch(_moreBranch),
            ),
    );
  }
}
