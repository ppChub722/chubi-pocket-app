import 'package:flutter/widgets.dart';

import '../../features/accounts/domain/account.dart';

/// What the shell's centre + presets in the quick create when pressed over
/// a page that set it (owner 2026-10-11): on a wallet's detail page (any
/// of its tabs), that wallet.
class QuickCreatePreset {
  const QuickCreatePreset({this.account});

  final Account? account;
}

/// The shell's list of pages that offer a [QuickCreatePreset] — one per
/// mounted [QuickCreatePresetScope]. The + takes the newest one whose page
/// is on screen ([active]): its route is the top of its tab and its tab is
/// the visible one. A page underneath another, or in a tab left behind,
/// offers nothing.
class QuickCreateContext {
  final List<_Entry> _entries = [];

  void _add(_Entry e) => _entries.add(e);
  void _remove(_Entry e) => _entries.remove(e);

  /// The preset of the page on screen, or null (a plain quick create).
  QuickCreatePreset? active() {
    for (final e in _entries.reversed) {
      if (e.isShowing()) return e.preset;
    }
    return null;
  }
}

class _Entry {
  _Entry(this.preset, this.isShowing);
  QuickCreatePreset preset;
  final bool Function() isShowing;
}

/// Hands the shell's [QuickCreateContext] down to the tabs' pages.
class QuickCreateContextScope extends InheritedWidget {
  const QuickCreateContextScope({
    required this.registry,
    required super.child,
    super.key,
  });

  final QuickCreateContext registry;

  static QuickCreateContext? maybeOf(BuildContext context) => context
      .getInheritedWidgetOfExactType<QuickCreateContextScope>()
      ?.registry;

  @override
  bool updateShouldNotify(QuickCreateContextScope old) =>
      registry != old.registry;
}

/// Wrap a page's body: while this page is on screen, the shell's + opens
/// the quick create with [preset]. Mounted = registered; disposed = gone.
/// Outside the shell (a root-navigator page) it does nothing.
class QuickCreatePresetScope extends StatefulWidget {
  const QuickCreatePresetScope({
    required this.preset,
    required this.child,
    super.key,
  });

  final QuickCreatePreset preset;
  final Widget child;

  @override
  State<QuickCreatePresetScope> createState() => _QuickCreatePresetScopeState();
}

class _QuickCreatePresetScopeState extends State<QuickCreatePresetScope> {
  QuickCreateContext? _registry;
  late final _Entry _entry = _Entry(widget.preset, _isShowing);

  /// The top page of its tab, in the tab that's showing.
  bool _isShowing() =>
      mounted &&
      (ModalRoute.of(context)?.isCurrent ?? false) &&
      TickerMode.valuesOf(context).enabled;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final registry = QuickCreateContextScope.maybeOf(context);
    if (registry == _registry) return;
    _registry?._remove(_entry);
    _registry = registry?.._add(_entry);
  }

  @override
  void didUpdateWidget(QuickCreatePresetScope old) {
    super.didUpdateWidget(old);
    _entry.preset = widget.preset;
  }

  @override
  void dispose() {
    _registry?._remove(_entry);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
