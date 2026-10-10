import 'package:flutter/material.dart';

/// Drops a keyboard inset that outlived the keyboard (QA 2026-10-11): leave
/// the app with the keyboard up, come back, and Android often sends no
/// fresh window metrics. `viewInsets.bottom` keeps the old keyboard height,
/// so every sheet / Scaffold that pads for it leaves a blank band where the
/// keyboard was (quick create's pinned buttons floated mid-screen).
///
/// The fix sits once, at the app root (under [MaterialApp]'s MediaQuery):
/// - Leaving the app (hidden / paused) drops the text focus, so the keyboard
///   is closed for real and nothing re-opens it unasked.
/// - Coming back with a bottom inset still reported, that inset is treated
///   as stale and removed from the MediaQuery below — until the engine
///   reports a different inset, or a text field takes focus (the keyboard
///   opening sends fresh metrics).
class KeyboardInsetsGuard extends StatefulWidget {
  const KeyboardInsetsGuard({required this.child, super.key});

  final Widget child;

  @override
  State<KeyboardInsetsGuard> createState() => _KeyboardInsetsGuardState();
}

class _KeyboardInsetsGuardState extends State<KeyboardInsetsGuard>
    with WidgetsBindingObserver {
  /// The leftover inset (physical px) while it's being hidden; null = trust
  /// what the engine reports.
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

  /// A text field has the focus — its keyboard is (about to be) real.
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
