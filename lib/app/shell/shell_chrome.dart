import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Lets the page currently shown inside [MainShell] temporarily take
/// over the shell's bottom chrome (the `MainBottomNav` + docked FAB).
///
/// The shell owns a single [ShellChromeController] and exposes it down
/// the tree through [ShellChrome]. A page that needs to swap the global
/// nav for its own bottom bar — e.g. categories' reorder mode showing a
/// Cancel · Undo · Save action bar — calls [ShellChromeController.hide]
/// on entry and [ShellChromeController.show] on exit. While hidden, the
/// shell renders no bottom nav and no FAB, so the page's own
/// `bottomNavigationBar` is the only bar on screen (no stacking).
class ShellChromeController extends ChangeNotifier {
  bool _hidden = false;

  /// True while a page has asked the shell to drop its bottom nav.
  bool get hidden => _hidden;

  void hide() {
    if (_hidden) return;
    _hidden = true;
    _notify();
  }

  void show() {
    if (!_hidden) return;
    _hidden = false;
    _notify();
  }

  /// Pages call [hide]/[show] from `dispose` too, which runs while the tree
  /// is locked — rebuilding the shell then throws (debug) and the nav never
  /// comes back. Mid-frame calls are deferred to the end of the frame.
  void _notify() {
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => notifyListeners());
    } else {
      notifyListeners();
    }
  }
}

/// Runs [action] once [route] has finished sliding in — right away if it
/// already has (or there's no route). If it's popped first, never.
///
/// Pages that open in edit mode (create / forms) hide the shell nav; doing
/// that while the page is still sliding in collapses the nav *during* the
/// transition, re-laying out the whole tab (both pages) every frame — the
/// "slight stutter when a create page comes in" (owner 2026-10-09) — and
/// stretches the top bar's hero flight. After the transition it's one
/// smooth slide of its own.
void whenRouteSettled(ModalRoute<dynamic>? route, VoidCallback action) {
  // A just-pushed route spends its first frame offstage (heroes measure
  // it) with its animation pinned to "complete" — ask again after that.
  if (route != null && route.offstage) {
    SchedulerBinding.instance.addPostFrameCallback(
      (_) => whenRouteSettled(route, action),
    );
    return;
  }
  final animation = route?.animation;
  if (animation == null || animation.isCompleted) {
    action();
    return;
  }
  void listener(AnimationStatus status) {
    if (status == AnimationStatus.forward) return;
    animation.removeStatusListener(listener);
    if (status == AnimationStatus.completed) action();
  }

  animation.addStatusListener(listener);
}

/// Hides the shell's bottom nav + FAB for as long as [child] is on screen —
/// wrap whole-page forms with it (app rule: forms are edit mode). Pages
/// with an in-place edit mode toggle the controller themselves instead.
class ShellChromeHider extends StatefulWidget {
  const ShellChromeHider({required this.child, super.key});

  final Widget child;

  @override
  State<ShellChromeHider> createState() => _ShellChromeHiderState();
}

class _ShellChromeHiderState extends State<ShellChromeHider> {
  ShellChromeController? _controller;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_controller != null) return;
    final element = context
        .getElementForInheritedWidgetOfExactType<ShellChrome>();
    final controller = (element?.widget as ShellChrome?)?.notifier;
    if (controller == null) return; // outside the shell (overlay, tests)
    _controller = controller;
    // Not mid-build (hiding rebuilds the shell), and not mid page
    // transition either — see [whenRouteSettled].
    final route = ModalRoute.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      whenRouteSettled(route, () {
        if (mounted) controller.hide();
      });
    });
  }

  @override
  void dispose() {
    _controller?.show();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Provides the shell's [ShellChromeController] to descendant pages.
class ShellChrome extends InheritedNotifier<ShellChromeController> {
  const ShellChrome({
    required ShellChromeController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  /// Returns the controller without registering a build dependency —
  /// callers toggle it from event handlers, not from `build`, so they
  /// don't want to rebuild when it changes.
  static ShellChromeController of(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<ShellChrome>();
    assert(
      element != null,
      'ShellChrome.of() called with no ShellChrome ancestor.',
    );
    return (element!.widget as ShellChrome).notifier!;
  }
}
