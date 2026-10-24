import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

/// Whether the shell nav shows is worked out from what is on screen NOW, never
/// remembered (owner 2026-10-24): every editing bar holds a [ShellChromeClaim]
/// whose question is "am I on screen with my bar up right now?", and the nav
/// hides while any claim says yes. A claim on a page left in another tab, under
/// another page, or not released at all just answers no, so nothing can leave
/// the nav stuck hidden.
class ShellChromeController extends ChangeNotifier {
  final Set<ShellChromeClaim> _claims = {};
  bool _hidden = false;
  bool _scheduled = false;
  bool _disposed = false;

  bool get hidden => _hidden;

  ShellChromeClaim claim(bool Function() onScreen) {
    final c = ShellChromeClaim._(this, onScreen);
    _claims.add(c);
    refresh();
    return c;
  }

  /// Asks every claim again after this frame (when the screen has settled).
  /// Call it whenever what is on screen may have changed.
  void refresh() {
    if (_scheduled || _disposed) return;
    _scheduled = true;
    SchedulerBinding.instance
      ..addPostFrameCallback((_) {
        _scheduled = false;
        recompute();
      })
      ..scheduleFrame();
  }

  @visibleForTesting
  void recompute() {
    if (_disposed) return;
    final next = _claims.any((c) => c._onScreen());
    if (next == _hidden) return;
    _hidden = next;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

class ShellChromeClaim {
  ShellChromeClaim._(this._controller, this._onScreen);

  final ShellChromeController _controller;
  final bool Function() _onScreen;

  /// The page's own state changed (e.g. edit mode on / off).
  void changed() => _controller.refresh();

  void release() {
    _controller._claims.remove(this);
    _controller.refresh();
  }
}

/// A page's claim on the nav, for a [State]: [wantsHidden] is the page's own
/// side (an editing bar is up); [attach] in didChangeDependencies adds the
/// screen side — its tab is shown, nothing covers it, its push has settled.
class ShellNavClaim {
  ShellNavClaim(this.wantsHidden);

  final bool Function() wantsHidden;

  ShellChromeClaim? _claim;
  ModalRoute<dynamic>? _route;
  ValueListenable<TickerModeData>? _ticker;

  void attach(BuildContext context) {
    final element = context
        .getElementForInheritedWidgetOfExactType<ShellChrome>();
    final controller = (element?.widget as ShellChrome?)?.notifier;
    if (controller == null) return; // outside the shell (tests, sheets)
    final ticker = TickerMode.getValuesNotifier(context);
    if (!identical(ticker, _ticker)) {
      _ticker?.removeListener(changed);
      _ticker = ticker..addListener(changed);
    }
    final route = ModalRoute.of(context);
    if (!identical(route, _route)) {
      _route?.animation?.removeStatusListener(_onAnimation);
      _route = route;
      route?.animation?.addStatusListener(_onAnimation);
    }
    _claim ??= controller.claim(_onScreen);
    changed();
  }

  bool _onScreen() {
    if (!wantsHidden()) return false;
    if (!(_ticker?.value.enabled ?? true)) return false;
    final r = _route;
    if (r == null) return true;
    return r.isActive &&
        r.isCurrent &&
        !r.offstage &&
        (r.animation?.isCompleted ?? true);
  }

  void changed() => _claim?.changed();

  void _onAnimation(AnimationStatus _) => changed();

  void dispose() {
    _ticker?.removeListener(changed);
    _route?.animation?.removeStatusListener(_onAnimation);
    _claim?.release();
    _claim = null;
  }
}

/// A route whose page always shows an editing bar (a form page): the nav
/// hides while this page is the one on screen.
class ShellChromeHider extends StatefulWidget {
  const ShellChromeHider({required this.child, super.key});

  final Widget child;

  @override
  State<ShellChromeHider> createState() => _ShellChromeHiderState();
}

class _ShellChromeHiderState extends State<ShellChromeHider> {
  late final ShellNavClaim _nav = ShellNavClaim(() => mounted);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _nav.attach(context);
  }

  @override
  void dispose() {
    _nav.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class ShellChrome extends InheritedNotifier<ShellChromeController> {
  const ShellChrome({
    required ShellChromeController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

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
