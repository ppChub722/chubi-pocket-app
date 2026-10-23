import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../l10n/gen/app_localizations.dart';
import '../../features/transactions/presentation/widgets/quick_create_sheet.dart';
import 'fade_branch_container.dart';
import 'main_bottom_nav.dart';
import 'quick_create_context.dart';
import 'shell_chrome.dart';
import 'tab_nav.dart';
import '../../ui/ui.dart';

class MainShell extends StatefulWidget {
  const MainShell({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell>
    with SingleTickerProviderStateMixin {
  final ShellChromeController _chrome = ShellChromeController();

  late final QuickCreateContext _quickCreate = QuickCreateContext()
    ..currentBranch = widget.navigationShell.currentIndex;

  static final _moreBranch = ShellTab.more.index;

  ShellTab get _current => ShellTab.values[widget.navigationShell.currentIndex];

  void _goBranch(int i) => widget.navigationShell.goBranch(
    i,
    initialLocation: i == widget.navigationShell.currentIndex,
  );

  final List<int> _history = [];

  /// The tab a back is heading to — arriving there records nothing, so back
  /// never builds a "forward" trail.
  int? _backTo;

  @override
  void didUpdateWidget(MainShell old) {
    super.didUpdateWidget(old);
    final from = old.navigationShell.currentIndex;
    final to = widget.navigationShell.currentIndex;
    _quickCreate.currentBranch = to;
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

  static bool _swipesBetweenTabs(ShellTab tab) =>
      tab.row == ShellRow.nav || tab.row == ShellRow.top;

  void _onDragStart(DragStartDetails _) {
    final shell = widget.navigationShell;
    final branchNav = shell.route.branches[shell.currentIndex].navigatorKey;
    _swiping =
        _swipesBetweenTabs(_current) &&
        !_chrome.hidden &&
        !(branchNav.currentState?.canPop() ?? true);
    _dragDx = 0;
    if (_swiping) _nudge.stop();
  }

  /// The body trails the finger, damped so it only ever moves a little — half
  /// as far toward an end with no tab past it.
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
    if (_pageSwipes(v)) {
      HapticFeedback.selectionClick();
      _swipeHandlers[_current]!.onSwipe(v < 0 ? 1 : -1);
      return _settle();
    }
    final next = _neighbour(v);
    if (next == null) return _settle();
    _nudge.value = 0;
    HapticFeedback.selectionClick();
    _goBranch(next);
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

  int? _neighbour(double dx) => _current.beside(dx < 0 ? 1 : -1)?.index;

  bool _askingExit = false;

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
                currentIndex: widget.navigationShell.currentIndex,
                moreSelected:
                    widget.navigationShell.currentIndex == _moreBranch,
                onTabSelected: _goBranch,
                addMode: _quickCreate.preset.mode,
                addWord: _quickCreate.preset.word,
                addColor: _quickCreate.preset.color,
                addIcon: _quickCreate.preset.icon,
                onAddPressed: () => _openQuickCreate(context),
                onMorePressed: () => _goBranch(_moreBranch),
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
