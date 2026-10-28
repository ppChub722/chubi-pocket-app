import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../features/transactions/presentation/widgets/quick_create_sheet.dart';
import 'back_history.dart';
import 'fade_branch_container.dart';
import 'main_bottom_nav.dart';
import 'nav_layout.dart';
import 'quick_create_context.dart';
import 'shell_chrome.dart';
import 'tab_nav.dart';
import '../../ui/ui.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.navigationShell, this.layout, super.key});

  final StatefulNavigationShell navigationShell;

  /// Where the bars, chips and More groups sit; [NavLayout.defaults] = today.
  final NavLayout? layout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  final ShellChromeController _chrome = ShellChromeController();

  late final QuickCreateContext _quickCreate = QuickCreateContext()
    ..currentBranch = widget.navigationShell.currentIndex;

  NavLayout get _layout => widget.layout ?? NavLayout.defaults;

  ShellTab get _current => ShellTab.values[widget.navigationShell.currentIndex];

  void _goBranch(int i) => goTab(
    ShellTab.values[i],
    from: widget.navigationShell.currentIndex,
    goBranch: widget.navigationShell.goBranch,
  );

  final ShellBackHistory _history = ShellBackHistory();

  @override
  void initState() {
    super.initState();
    // Any push / pop / replace in a tab: ask the editing bars again.
    QuickCreateRouteObserver.changes.addListener(_chrome.refresh);
    // A pull re-checks the nav, so a wrongly hidden one comes back.
    PullToRefresh.onPull = _chrome.refresh;
  }

  @override
  void didUpdateWidget(MainShell old) {
    super.didUpdateWidget(old);
    final to = widget.navigationShell.currentIndex;
    _quickCreate.currentBranch = to;
    _history.branchChanged(old.navigationShell.currentIndex, to);
    _chrome.refresh();
  }

  @override
  void dispose() {
    QuickCreateRouteObserver.changes.removeListener(_chrome.refresh);
    if (PullToRefresh.onPull == _chrome.refresh) PullToRefresh.onPull = null;
    _nudge.dispose();
    _chrome.dispose();
    _quickCreate.dispose();
    super.dispose();
  }

  static const _minFlingVelocity = 300.0;

  static const _maxNudge = 24.0;

  late final AnimationController _nudge = AnimationController.unbounded(
    vsync: this,
  );

  bool _swiping = false;
  double _dragDx = 0;

  /// The body trails a swipe on a bar tab's root page (never switches tabs;
  /// only the bars do, owner 2026-10-28).
  bool _followsSwipe(ShellTab tab) => _layout.barOf(tab) != null;

  void _onDragStart(DragStartDetails _) {
    final shell = widget.navigationShell;
    final branchNav = shell.route.branches[shell.currentIndex].navigatorKey;
    _swiping =
        _followsSwipe(_current) &&
        !_chrome.hidden &&
        !(branchNav.currentState?.canPop() ?? true);
    _dragDx = 0;
    if (_swiping) _nudge.stop();
  }

  /// The body trails the finger, damped so it only ever moves a little, then
  /// eases back.
  void _onDragUpdate(DragUpdateDetails d) {
    if (!_swiping) return;
    _dragDx += d.primaryDelta ?? 0;
    if (_pageSwipes(_dragDx) || MediaQuery.disableAnimationsOf(context)) {
      _nudge.value = 0;
      return;
    }
    final u = _dragDx / (_maxNudge * 3);
    _nudge.value = _maxNudge * u / (1 + u.abs());
  }

  void _onDragEnd(DragEndDetails d) {
    if (!_swiping) return;
    _swiping = false;
    final v = d.primaryVelocity ?? 0;
    if (v.abs() >= _minFlingVelocity && _pageSwipes(v)) {
      HapticFeedback.selectionClick();
      _swipeHandlers[_current]!.onSwipe(v < 0 ? 1 : -1);
    }
    _settle();
  }

  final Map<ShellTab, ShellSwipeHandler> _swipeHandlers = {};

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

  bool _askingExit = false;

  Future<void> _onBackAtRoot() async {
    final to = _history.backTarget(_current, _layout);
    if (to != null) {
      _goBranch(to);
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
      // The shell is the root navigator's only page, so a back that reaches it
      // would close the app — handle it instead.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shell = widget.navigationShell;
        final tab = shell.route.branches[shell.currentIndex].navigatorKey;
        if (await tab.currentState?.maybePop() ?? false) return;
        _onBackAtRoot();
      },
      child: NavLayoutScope(
        layout: _layout,
        child: ShellBackScope(
          onBack: _onBackAtRoot,
          child: ShellSwipeScope(
            handlers: _swipeHandlers,
            child: QuickCreateContextScope(
              registry: _quickCreate,
              child: _shell(context),
            ),
          ),
        ),
      ),
    );
  }

  void _openQuickCreate(BuildContext context) {
    final preset = _quickCreate.active() ?? QuickCreatePreset.none;
    // A page with its own create action (an event's "เพิ่มบิล") runs it.
    final own = preset.onCreate;
    if (own != null) return own();
    showQuickCreateSheet(context, preset: preset);
  }

  Widget _shell(BuildContext context) {
    return ShellChrome(
      controller: _chrome,
      child: Scaffold(
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
        bottomNavigationBar: ListenableBuilder(
          listenable: _chrome,
          builder: (context, _) => _animatedNav(context),
        ),
      ),
    );
  }

  /// The nav slides down / back up instead of popping, so the body resizes
  /// smoothly when a form or edit mode takes over the bottom (instantly under
  /// reduced motion).
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
          : ListenableBuilder(
              key: const ValueKey('nav'),
              listenable: _quickCreate,
              builder: (context, _) => MainBottomNav(
                items: _layout.bottomItems,
                current: _current,
                onSelected: (tab) => _goBranch(tab.index),
                addMode: _quickCreate.preset.mode,
                addWord: _quickCreate.preset.word,
                addColor: _quickCreate.preset.color,
                addIcon: _quickCreate.preset.icon,
                onAddPressed: () => _openQuickCreate(context),
              ),
            ),
    );
  }
}

/// `extendBody` only grows `MediaQuery.padding.bottom` by the nav's height; a
/// page's FAB is placed by `viewPadding`, so it would sit under the nav.
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
