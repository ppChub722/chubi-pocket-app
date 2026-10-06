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

  /// True while a page has asked the shell to drop its bottom nav + FAB.
  bool get hidden => _hidden;

  void hide() {
    if (_hidden) return;
    _hidden = true;
    notifyListeners();
  }

  void show() {
    if (!_hidden) return;
    _hidden = false;
    notifyListeners();
  }
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
    final element =
        context.getElementForInheritedWidgetOfExactType<ShellChrome>();
    final controller = (element?.widget as ShellChrome?)?.notifier;
    if (controller == null) return; // outside the shell (overlay, tests)
    _controller = controller;
    // Defer: hiding notifies the shell, which must not rebuild mid-build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) controller.hide();
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
    final element =
        context.getElementForInheritedWidgetOfExactType<ShellChrome>();
    assert(
      element != null,
      'ShellChrome.of() called with no ShellChrome ancestor.',
    );
    return (element!.widget as ShellChrome).notifier!;
  }
}
