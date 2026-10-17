import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class ShellChromeController extends ChangeNotifier {
  static const Object _anonymous = Object();

  final Set<Object> _owners = {};

  bool get hidden => _owners.isNotEmpty;

  void hide({Object? owner}) {
    final was = hidden;
    _owners.add(owner ?? _anonymous);
    if (!was) _notify();
  }

  void show({Object? owner}) {
    final was = hidden;
    _owners.remove(owner ?? _anonymous);
    if (was && !hidden) _notify();
  }

  /// Pages call [hide]/[show] from `dispose` too, which runs while the tree is
  /// locked — rebuilding the shell then throws (debug) and the nav never comes
  /// back.
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

void whenRouteSettled(ModalRoute<dynamic>? route, VoidCallback action) {
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
    if (controller == null) return; // outside the shell (tests)
    _controller = controller;
    final route = ModalRoute.of(context);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      whenRouteSettled(route, () {
        if (mounted) controller.hide(owner: this);
      });
    });
  }

  @override
  void dispose() {
    _controller?.show(owner: this);
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
