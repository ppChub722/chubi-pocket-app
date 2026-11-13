import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import '../../ui/ui.dart' show PpForgePageMotion;
import 'nav_layout.dart';
import 'tab_nav.dart';

enum TabEntryKind {
  /// Slides in from the right while fading in (owner 2026-11-12): the mirror
  /// of a back, where the page above slides off to the right.
  slide,

  /// Fades only (reduced motion).
  fade,

  /// Already in place (a back: the page above slid away off it).
  none,
}

/// How a page group arrives on a tab switch: it slides in from the right,
/// fading in (the duration is FadeBranchContainer's) — no scale, so it is a
/// translate and an opacity of the page's layer.
@immutable
class TabEntry {
  const TabEntry._(this.kind);

  static const slide = TabEntry._(TabEntryKind.slide);
  static const fade = TabEntry._(TabEntryKind.fade);
  static const none = TabEntry._(TabEntryKind.none);

  final TabEntryKind kind;

  /// The page's shift at [t] (0 → 1), a fraction of its width ([PpForgePageMotion]).
  Offset offsetAt(double t) => kind == TabEntryKind.slide
      ? Offset(PpForgePageMotion.enterShift(t), 0)
      : Offset.zero;

  double opacityAt(double t) =>
      kind == TabEntryKind.none ? 1 : PpForgePageMotion.enterOpacity(t);

  /// The paint transform at [t] for a page of [size].
  Matrix4 transformAt(double t, Size size) {
    final o = offsetAt(t);
    return Matrix4.translationValues(o.dx * size.width, o.dy * size.height, 0);
  }

  @override
  bool operator ==(Object other) => other is TabEntry && other.kind == kind;

  @override
  int get hashCode => kind.hashCode;

  @override
  String toString() => 'TabEntry(${kind.name})';
}

/// Asks the shell to play the open tab's entry again: tapping the tab
/// already open starts it over (see [goTab]).
abstract final class ShellReopen {
  static final ValueNotifier<int> signal = ValueNotifier(0);

  static void request() => signal.value++;
}

/// How [to] arrives when the shell switches to it from [from] (owner
/// 2026-11-12): a back lands in place; anything else slides in from the right.
/// A [reopen] (the open tab tapped) plays the same entry again. [origin] (a
/// More card, the bell) no longer shapes the entry.
TabEntry resolveTabEntry({
  required ShellTab from,
  required ShellTab to,
  required NavLayout layout,
  Alignment? origin,
  bool back = false,
  bool reopen = false,
  bool reducedMotion = false,
}) {
  // Temporary fps probe: --dart-define=NO_TAB_ANIM=true
  if (const bool.fromEnvironment('NO_TAB_ANIM')) return TabEntry.none;
  if (back || (from == to && !reopen)) return TabEntry.none;
  if (reducedMotion) return TabEntry.fade;
  return TabEntry.slide;
}

/// [rect] (global) as an alignment inside a page of [size] at the origin;
/// the centre when unknown.
Alignment originAlignment(Rect? rect, Size size) {
  if (rect == null || size.isEmpty) return Alignment.center;
  final c = rect.center;
  return Alignment(
    (c.dx / size.width * 2 - 1).clamp(-1.0, 1.0),
    (c.dy / size.height * 2 - 1).clamp(-1.0, 1.0),
  );
}

/// Where the next tab switch was tapped: the one helper tap sites call right
/// before they switch (a More card, a notification), so the page grows out
/// of that spot. Unused, it expires.
abstract final class ShellEntryOrigin {
  static Rect? _pending;
  static Timer? _expiry;

  static void markRect(Rect rect) {
    _pending = rect;
    _expiry?.cancel();
    _expiry = Timer(const Duration(milliseconds: 500), _clear);
  }

  /// The widget at [context] was tapped.
  static void markTapped(BuildContext context) {
    final rect = _rectOf(context);
    if (rect != null) markRect(rect);
  }

  /// Opened from a notification: it grows out of the bell in the top bar.
  static void markBell() =>
      markRect(EntryOriginAnchor._bellRect() ?? _bellGuess());

  /// The pending origin, taken (null when none).
  static Rect? take() {
    final r = _pending;
    _clear();
    return r;
  }

  static void _clear() {
    _pending = null;
    _expiry?.cancel();
    _expiry = null;
  }

  static Rect? _rectOf(BuildContext context) {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero) & box.size;
  }

  /// No bell on screen: where it sits in the top bar (top right).
  static Rect _bellGuess() {
    final view = PlatformDispatcher.instance.implicitView;
    if (view == null) return Rect.zero;
    final size = view.physicalSize / view.devicePixelRatio;
    final top = view.padding.top / view.devicePixelRatio;
    return Rect.fromCenter(
      center: Offset(size.width - 96, top + 28),
      width: 40,
      height: 40,
    );
  }
}

/// Marks the notifications bell so [ShellEntryOrigin.markBell] can find the
/// one on screen.
class EntryOriginAnchor extends StatefulWidget {
  const EntryOriginAnchor.bell({required this.child, super.key});

  final Widget child;

  static final Set<_EntryOriginAnchorState> _bells = {};

  static Rect? _bellRect() {
    for (final a in _bells) {
      final c = a.context;
      if (!a.mounted || !TickerMode.valuesOf(c).enabled) continue;
      if (!(ModalRoute.isCurrentOf(c) ?? true)) continue;
      final r = ShellEntryOrigin._rectOf(c);
      if (r != null) return r;
    }
    return null;
  }

  @override
  State<EntryOriginAnchor> createState() => _EntryOriginAnchorState();
}

class _EntryOriginAnchorState extends State<EntryOriginAnchor> {
  @override
  void initState() {
    super.initState();
    EntryOriginAnchor._bells.add(this);
  }

  @override
  void dispose() {
    EntryOriginAnchor._bells.remove(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
