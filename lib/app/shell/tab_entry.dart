import 'dart:async';
import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/widgets.dart';

import 'nav_layout.dart';
import 'tab_nav.dart';

enum TabEntryKind {
  /// From the side of the previous bottom-bar item.
  side,

  /// Up from below: into a bottom-bar page from a page it doesn't highlight.
  up,

  /// Down from above: into a top-row page.
  down,

  /// Grows (scale + fade) out of where it was tapped.
  expand,

  /// Fades only (reduced motion).
  fade,

  /// Already in place (a back: the page above slid away off it).
  none,
}

/// How a page group arrives on a tab switch: a small shift or a grow out of
/// the tapped spot, with a fade, over [AppDurations.chrome].
@immutable
class TabEntry {
  const TabEntry._(this.kind, {this.side = 0, this.origin = Alignment.center});

  /// From the right when [side] > 0, from the left when < 0.
  const TabEntry.side(int side) : this._(TabEntryKind.side, side: side);

  /// Grows out of [origin] (the page's own alignment).
  const TabEntry.expand([Alignment origin = Alignment.center])
    : this._(TabEntryKind.expand, origin: origin);

  static const up = TabEntry._(TabEntryKind.up);
  static const down = TabEntry._(TabEntryKind.down);
  static const fade = TabEntry._(TabEntryKind.fade);
  static const none = TabEntry._(TabEntryKind.none);

  final TabEntryKind kind;
  final int side;
  final Alignment origin;

  /// The shift a slide starts from (a fraction of the page).
  static const shift = 0.06;

  /// The scale a grow starts from.
  static const scaleFrom = 0.8;

  /// The page's shift at [t] (0 → 1), a fraction of its size.
  Offset offsetAt(double t) {
    final k = shift * (1 - t);
    return switch (kind) {
      TabEntryKind.side => Offset(side.sign * k, 0),
      TabEntryKind.up => Offset(0, k),
      TabEntryKind.down => Offset(0, -k),
      _ => Offset.zero,
    };
  }

  double scaleAt(double t) =>
      kind == TabEntryKind.expand ? scaleFrom + (1 - scaleFrom) * t : 1;

  double opacityAt(double t) => kind == TabEntryKind.none ? 1 : t;

  /// The paint transform at [t] for a page of [size].
  Matrix4 transformAt(double t, Size size) {
    final o = offsetAt(t);
    final s = scaleAt(t);
    final m = Matrix4.translationValues(
      o.dx * size.width,
      o.dy * size.height,
      0,
    );
    if (s != 1) {
      final p = origin.alongSize(size);
      m
        ..translateByDouble(p.dx, p.dy, 0, 1)
        ..scaleByDouble(s, s, 1, 1)
        ..translateByDouble(-p.dx, -p.dy, 0, 1);
    }
    return m;
  }

  @override
  bool operator ==(Object other) =>
      other is TabEntry &&
      other.kind == kind &&
      other.side == side &&
      other.origin == origin;

  @override
  int get hashCode => Object.hash(kind, side, origin);

  @override
  String toString() => 'TabEntry(${kind.name}, side: $side, origin: $origin)';
}

/// How [to] arrives when the shell switches to it from [from] (owner
/// 2026-10-28): a back lands in place; a known [origin] (a More card, the
/// bell) grows out of it; a bottom-bar page slides in from the side of the
/// previous bottom-bar page, or up from below when none was highlighted; a
/// top-row page slides down from above; anything else grows out of the
/// middle of the screen.
TabEntry resolveTabEntry({
  required ShellTab from,
  required ShellTab to,
  required NavLayout layout,
  Alignment? origin,
  bool back = false,
  bool reducedMotion = false,
}) {
  if (back || from == to) return TabEntry.none;
  if (reducedMotion) return TabEntry.fade;
  if (origin != null) return TabEntry.expand(origin);
  switch (layout.barOf(to)) {
    case NavBar.bottom:
      if (layout.barOf(from) != NavBar.bottom) return TabEntry.up;
      final items = layout.bottomItems;
      return TabEntry.side((items.indexOf(to) - items.indexOf(from)).sign);
    case NavBar.top:
      return TabEntry.down;
    case null:
      return const TabEntry.expand();
  }
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
