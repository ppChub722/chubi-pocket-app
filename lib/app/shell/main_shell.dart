import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_durations.dart';
import '../../l10n/gen/app_localizations.dart';
import '../../shared/widgets/feedback/confirm_dialog.dart';

import '../../features/transactions/presentation/widgets/quick_create_sheet.dart';
import 'fade_branch_container.dart';
import 'main_bottom_nav.dart';
import 'shell_chrome.dart';
import 'tab_nav.dart';

/// App chrome shared by every tab-layer screen.
///
/// The shell owns only the floating bottom nav (with its centred `+`
/// quick-create button), shown on **every** page. Top bars belong to the
/// pages: tab roots use [TabRootScaffold] (transparent bar, content scrolls
/// under it), deeper pages bring their own [Scaffold] + back button — so
/// pushing a page never changes the shell's layout mid-transition.
/// Every page group is its own tab ([ShellTab]); only the four nav tabs
/// light a slot — เพิ่มเติม only on the hub itself, the hub's cards and the
/// ⏳ / 🔔 / 👤 pages none.
///
/// **Back between tabs** (owner 2026-10-09): the shell remembers the tabs
/// visited, so back on a tab's root returns to the previous one — see
/// [_MainShellState._onBackAtRoot].
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

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  final ShellChromeController _chrome = ShellChromeController();

  static final _moreBranch = ShellTab.more.index;

  ShellTab get _current => ShellTab.values[widget.navigationShell.currentIndex];

  void _goBranch(int i) => widget.navigationShell.goBranch(
    i,
    // Re-tapping the active tab pops to the branch root, matching the
    // behaviour users expect from native bottom nav.
    initialLocation: i == widget.navigationShell.currentIndex,
  );

  /// Tabs visited before the current one, most recent last. Each appears
  /// once (revisiting moves it to the end) and never the current tab, so
  /// back can't ping-pong between two tabs forever.
  final List<int> _history = [];

  /// The tab a back is heading to — arriving there records nothing, so
  /// back never builds a "forward" trail.
  int? _backTo;

  @override
  void didUpdateWidget(MainShell old) {
    super.didUpdateWidget(old);
    final from = old.navigationShell.currentIndex;
    final to = widget.navigationShell.currentIndex;
    if (from == to) return;
    _history.remove(to);
    if (_backTo == to) {
      _backTo = null;
      return;
    }
    _history
      ..remove(from)
      ..add(from);
  }

  @override
  void dispose() {
    _nudge.dispose();
    _chrome.dispose();
    super.dispose();
  }

  /// A fling this fast (px/s) sideways moves to the neighbouring tab.
  static const _minFlingVelocity = 300.0;

  /// Furthest (px) the tab body trails the finger mid-swipe.
  static const _maxNudge = 24.0;

  /// The tab body's mid-swipe offset (px), read by [TabSwitchBody].
  late final AnimationController _nudge = AnimationController.unbounded(
    vsync: this,
  );

  /// Whether the drag in progress may switch tabs.
  bool _swiping = false;
  double _dragDx = 0;

  /// Swipe between the tabs of one on-screen row ([ShellRow] — the nav,
  /// the top bar's chips, each เพิ่มเติม section; owner 2026-10-09/10) —
  /// only on a tab's root page (nothing pushed in that tab) and not while
  /// a page has taken over the bottom chrome (edit / reorder). Anything
  /// inside that wants a sideways drag — an in-page tab pager, a horizontal
  /// chip row, swipe-to-dismiss — is deeper in the gesture arena and wins,
  /// so this only fires where nothing else claims the gesture.
  void _onDragStart(DragStartDetails _) {
    final shell = widget.navigationShell;
    final branchNav = shell.route.branches[shell.currentIndex].navigatorKey;
    _swiping = !_chrome.hidden && !(branchNav.currentState?.canPop() ?? true);
    _dragDx = 0;
    if (_swiping) _nudge.stop();
  }

  /// The body trails the finger, damped so it only ever moves a little —
  /// half as far toward an end with no tab past it. Not when the page takes
  /// the swipe itself (the dashboard's month): moving the whole tab would
  /// read as a tab switch — the page gives its own feedback instead. Not
  /// at all under reduced motion.
  void _onDragUpdate(DragUpdateDetails d) {
    if (!_swiping) return;
    _dragDx += d.primaryDelta ?? 0;
    if (_pageSwipes(_dragDx) || MediaQuery.disableAnimationsOf(context)) {
      _nudge.value = 0;
      return;
    }
    final max = _neighbour(_dragDx) != null ? _maxNudge : _maxNudge / 2;
    final u = _dragDx / (max * 3);
    _nudge.value = max * u / (1 + u.abs());
  }

  void _onDragEnd(DragEndDetails d) {
    if (!_swiping) return;
    _swiping = false;
    final v = d.primaryVelocity ?? 0;
    if (v.abs() < _minFlingVelocity) return _settle();
    // The page first (the dashboard's month); the tab once it's at its end.
    if (_pageSwipes(v)) {
      HapticFeedback.selectionClick();
      _swipeHandlers[_current]!.onSwipe(v < 0 ? 1 : -1);
      return _settle();
    }
    final next = _neighbour(v);
    if (next == null) return _settle();
    // The new tab brings its own entry slide (TabSwitchBody).
    _nudge.value = 0;
    HapticFeedback.selectionClick();
    _goBranch(next);
  }

  /// Tab roots that use the sideways swipe themselves ([ShellSwipeScope]).
  final Map<ShellTab, ShellSwipeHandler> _swipeHandlers = {};

  /// Whether the current tab's page takes a swipe toward [dx]'s sign.
  bool _pageSwipes(double dx) =>
      _swipeHandlers[_current]?.canSwipe(dx < 0 ? 1 : -1) ?? false;

  void _onDragCancel() {
    if (!_swiping) return;
    _swiping = false;
    _settle();
  }

  void _settle() => _nudge.animateTo(
    0,
    duration: AppDurations.chrome,
    curve: AppDurations.chromeCurve,
  );

  /// The tab a swipe toward [dx]'s sign lands on, or null past either end
  /// of the row. Swipe left (negative) → the tab to the right.
  int? _neighbour(double dx) => _current.beside(dx < 0 ? 1 : -1)?.index;

  bool _askingExit = false;

  /// Back with nothing left to pop in the tab (pushed pages and sheets pop
  /// before this is reached; the top bar's ← lands here too):
  /// 1. the previous tab in the history, as it was left;
  /// 2. none — a เพิ่มเติม card's tab → the hub; any other tab → the
  ///    dashboard;
  /// 3. the dashboard → "ปิดแอป?" (owner 2026-10-09).
  Future<void> _onBackAtRoot() async {
    final ShellTab? fallback = _current.inMore
        ? ShellTab.more
        : _current == ShellTab.home
        ? null
        : ShellTab.home;
    final to = _history.isNotEmpty ? _history.removeLast() : fallback?.index;
    if (to != null) {
      _backTo = to;
      widget.navigationShell.goBranch(to);
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
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        // go_router sends system back to a tab's navigator only when it can
        // pop — a tab's ROOT page never got asked, so its PopScope (reorder
        // / edit mode: "leave the mode first") was skipped and the shell
        // switched tabs with the page still in its mode, the nav hidden.
        // Ask the current tab first; only a page that lets go falls
        // through to the shell's back.
        final shell = widget.navigationShell;
        final tab = shell.route.branches[shell.currentIndex].navigatorKey;
        if (await tab.currentState?.maybePop() ?? false) return;
        _onBackAtRoot();
      },
      child: ShellBackScope(
        onBack: _onBackAtRoot,
        child: ShellSwipeScope(
          handlers: _swipeHandlers,
          child: _shell(context),
        ),
      ),
    );
  }

  Widget _shell(BuildContext context) {
    return ShellChrome(
      controller: _chrome,
      child: Scaffold(
        // Pages run on under the floating nav (owner 2026-10-10: no solid
        // strip behind it). Scaffold folds the nav's height into
        // `MediaQuery.paddingOf(context).bottom` — scrollables pad their
        // last item with it, like the top bar's height at the top.
        extendBody: true,
        body: _NavClearance(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            onHorizontalDragCancel: _onDragCancel,
            child: TabSwipeNudge(offset: _nudge, child: widget.navigationShell),
          ),
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
  /// smoothly when a form or edit mode takes over the bottom (instantly
  /// under reduced motion).
  Widget _animatedNav(BuildContext context) {
    final hidden = _chrome.hidden;
    return AnimatedSwitcher(
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 240),
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

/// `extendBody` only grows `MediaQuery.padding.bottom` by the nav's height;
/// a page's FAB is placed by `viewPadding`, so it would sit under the nav.
/// Grow `viewPadding` the same way — FABs float above the nav again.
class _NavClearance extends StatelessWidget {
  const _NavClearance({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final bottom = math.max(mq.viewPadding.bottom, mq.padding.bottom);
    return MediaQuery(
      data: mq.copyWith(viewPadding: mq.viewPadding.copyWith(bottom: bottom)),
      child: child,
    );
  }
}
