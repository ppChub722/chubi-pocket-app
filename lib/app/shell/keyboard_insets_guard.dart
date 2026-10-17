import 'package:flutter/material.dart';

class KeyboardInsetsGuard extends StatefulWidget {
  const KeyboardInsetsGuard({required this.child, super.key});

  final Widget child;

  @override
  State<KeyboardInsetsGuard> createState() => _KeyboardInsetsGuardState();
}

class _KeyboardInsetsGuardState extends State<KeyboardInsetsGuard>
    with WidgetsBindingObserver {
  double? _stale;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    FocusManager.instance.addListener(_onFocus);
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(_onFocus);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  double get _engineInset => View.of(context).viewInsets.bottom;

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.hidden || AppLifecycleState.paused:
        FocusManager.instance.primaryFocus?.unfocus();
      case AppLifecycleState.resumed:
        final inset = _engineInset;
        if (inset > 0 && !_editing) setState(() => _stale = inset);
      case AppLifecycleState.inactive || AppLifecycleState.detached:
        break;
    }
  }

  @override
  void didChangeMetrics() {
    final stale = _stale;
    if (stale != null && _engineInset != stale) setState(() => _stale = null);
  }

  bool get _editing =>
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorStateOfType<EditableTextState>() !=
      null;

  void _onFocus() {
    if (_stale != null && _editing) setState(() => _stale = null);
  }

  @override
  Widget build(BuildContext context) {
    if (_stale == null) return widget.child;
    return MediaQuery.removeViewInsets(
      context: context,
      removeBottom: true,
      child: widget.child,
    );
  }
}
