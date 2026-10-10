import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';
import 'reorder_controller.dart';
import 'reorder_outline.dart';

/// Reorder mode for a list or a tree (owner 2026-10-11). Wrap the page's
/// scroll view in a [ReorderListScope] and each row in a [ReorderRow]:
///
/// - every row gets a ⠿ handle; touching it drags **at once** — the proxy
///   lifts from exactly where the row is (no jump), the row dims in place;
/// - sideways while dragging picks the level, counted from where the row
///   was picked up: ±1 per [ReorderListScope.levelStep], changing only
///   after a deliberate move past the threshold held briefly. Only valid
///   levels show (the line never goes red); a light haptic on each change;
///   [ReorderListScope.dropLabel] names the parent at the line;
/// - holding over a collapsed parent ~0.6 s opens it; near the top /
///   bottom edge the list scrolls;
/// - tap a row → it's selected (tinted) and a [ReorderMoveBar] moves it;
///   tap it again, or empty space, to deselect.
///
/// The page keeps building its own rows from
/// [ReorderController.visible] (so the scroll view — and its offset — is
/// the same one in browse mode, where [ReorderListScope.controller] is
/// null and nothing changes).
class ReorderListScope extends StatefulWidget {
  const ReorderListScope({
    required this.child,
    required this.scrollController,
    this.controller,
    this.indentStep = AppSpacing.xxl,
    this.levelStep = 32,
    this.indentBase = AppSpacing.lg,
    this.dropLabel,
    super.key,
  });

  /// The scroll view whose rows are [ReorderRow]s.
  final Widget child;

  /// Drives the edge auto-scroll; the one [child] uses.
  final ScrollController scrollController;

  /// Null = not reordering: the rows are plain.
  final ReorderController? controller;

  /// One level of indent — the rows' indent step (where the drop line
  /// starts for a level).
  final double indentStep;

  /// How far sideways a drag moves to change level by one (~32 dp, owner
  /// 2026-10-11).
  final double levelStep;

  /// Where level 1 starts (the rows' side padding).
  final double indentBase;

  /// The drop line's label for a parent id (null = top level). Null hides
  /// the label (a flat list).
  final String Function(String? parentId)? dropLabel;

  @override
  State<ReorderListScope> createState() => _ReorderListScopeState();
}

/// How far past a level boundary (in levels) a drag must go, and for how
/// long it must stay there, before the level changes.
const double _levelThreshold = 0.75;
const Duration _levelHold = Duration(milliseconds: 150);

/// Hover this long on a collapsed parent to open it.
const Duration _expandHold = Duration(milliseconds: 600);

/// Edge band that auto-scrolls while dragging, and its top speed per tick.
const double _scrollBand = 72;
const double _scrollMaxStep = 10;

class _Drag {
  _Drag({
    required this.id,
    required this.section,
    required this.blockIds,
    required this.rest,
    required this.home,
    required this.height,
    required this.startLevel,
    required this.originX,
  }) : lateral = startLevel;

  final String id;
  final Object? section;
  final Set<String> blockIds;

  /// The outline without the dragged block; drops index into it.
  final List<OutlineItem> rest;

  /// The block's own spot in [rest] (dropping there = in place).
  final int home;
  final int height;
  final int startLevel;

  /// Pointer x the sideways level is measured from (moves when the level
  /// is clamped, so coming back is immediate).
  double originX;

  /// The level the sideways position asks for.
  int lateral;
  int? pending;
  Timer? pendingTimer;

  Offset? pointer;

  /// The current target: index in [rest] and level.
  int? k;
  int? level;
}

class _DropLine {
  const _DropLine({required this.y, required this.level, this.label});
  final double y;
  final int level;
  final String? label;
}

class _ReorderListScopeState extends State<ReorderListScope> {
  final Map<String, BuildContext> _rows = {};
  final ValueNotifier<_DropLine?> _line = ValueNotifier(null);
  _Drag? _drag;
  int _version = 0;
  int _seenMoves = 0;
  String? _seenSelected;
  Timer? _scrollTimer;
  double _scrollStep = 0;
  Timer? _expandTimer;
  String? _hoverId;

  /// Where the last handle touch went down — a drag's sideways origin.
  Offset? _lastPointerDown;

  ReorderController? get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c?.addListener(_onController);
  }

  @override
  void didUpdateWidget(ReorderListScope old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?.removeListener(_onController);
      widget.controller?.addListener(_onController);
      _endDrag(commit: false);
      _seenMoves = widget.controller?.moves ?? 0;
      _seenSelected = null;
    }
  }

  @override
  void dispose() {
    _c?.removeListener(_onController);
    _drag?.pendingTimer?.cancel();
    _scrollTimer?.cancel();
    _expandTimer?.cancel();
    _line.dispose();
    super.dispose();
  }

  void _onController() {
    final c = _c!;
    final moved = c.moves != _seenMoves;
    final newlySelected = c.selectedId != _seenSelected;
    _seenMoves = c.moves;
    _seenSelected = c.selectedId;
    setState(() => _version++);
    // Keep the selected row on screen after a move, and once the move bar
    // has made room after selecting.
    if ((moved || newlySelected) && c.selectedId != null && _drag == null) {
      final id = c.selectedId!;
      WidgetsBinding.instance.addPostFrameCallback((_) => _reveal(id));
    }
  }

  void _reveal(String id) {
    final row = _rows[id];
    if (row == null || !row.mounted) return;
    final box = row.findRenderObject() as RenderBox?;
    final scrollable = Scrollable.maybeOf(row);
    final view = scrollable?.context.findRenderObject() as RenderBox?;
    if (box == null || view == null || !box.attached || !view.attached) {
      return;
    }
    final top = box.localToGlobal(Offset.zero, ancestor: view).dy;
    final bottom = top + box.size.height;
    final policy = top < 0
        ? ScrollPositionAlignmentPolicy.keepVisibleAtStart
        : bottom > view.size.height
        ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
        : null;
    if (policy == null) return;
    Scrollable.ensureVisible(
      row,
      alignmentPolicy: policy,
      duration: MediaQuery.disableAnimationsOf(row)
          ? Duration.zero
          : const Duration(milliseconds: 180),
    );
  }

  // ── Rows ────────────────────────────────────────────────────────────

  void _register(String id, BuildContext row) => _rows[id] = row;

  void _unregister(String id, BuildContext row) {
    if (_rows[id] == row) _rows.remove(id);
  }

  /// The row's rect in this scope's coordinates (null when not laid out).
  Rect? _rectOf(String id, RenderBox scope) {
    final row = _rows[id];
    if (row == null || !row.mounted) return null;
    final box = row.findRenderObject() as RenderBox?;
    if (box == null || !box.attached || !box.hasSize) return null;
    return box.localToGlobal(Offset.zero, ancestor: scope) & box.size;
  }

  // ── Drag ────────────────────────────────────────────────────────────

  void _startDrag(String id, Offset pointer) {
    final c = _c;
    if (c == null || _drag != null) return;
    final i = c.indexOf(id);
    if (i < 0) return;
    final items = c.items;
    final (block, rest) = ReorderOutline.cut(items, i);
    setState(() {
      _drag = _Drag(
        id: id,
        section: items[i].section,
        blockIds: {for (final r in block) r.id},
        rest: rest,
        home: i,
        height: ReorderOutline.heightOf(items, i),
        startLevel: items[i].level,
        originX: pointer.dx,
      )..pointer = pointer;
      _version++;
    });
    HapticFeedback.mediumImpact();
    _retarget();
  }

  void _updateDrag(Offset pointer) {
    final d = _drag;
    if (d == null) return;
    d.pointer = pointer;
    _updateLateral(pointer.dx);
    _retarget();
    _autoScroll(pointer);
    _hoverExpand(pointer);
  }

  void _endDrag({required bool commit}) {
    final d = _drag;
    if (d == null) return;
    d.pendingTimer?.cancel();
    _stopAutoScroll();
    _expandTimer?.cancel();
    _hoverId = null;
    _line.value = null;
    if (mounted) {
      setState(() {
        _drag = null;
        _version++;
      });
    } else {
      _drag = null;
    }
    if (commit && d.k != null && d.level != null) {
      final changed = _c?.drop(d.id, d.k!, d.level!) ?? false;
      if (changed) HapticFeedback.mediumImpact();
    }
  }

  /// Sideways → level, with hysteresis: a level change needs the pointer
  /// [_levelThreshold] levels past the current one for [_levelHold].
  void _updateLateral(double x) {
    final d = _drag!;
    final maxDepth = _c!.maxDepth;
    final step = widget.levelStep;
    final raw = d.startLevel + (x - d.originX) / step;
    int? want;
    if (raw >= d.lateral + _levelThreshold) want = d.lateral + 1;
    if (raw <= d.lateral - _levelThreshold) want = d.lateral - 1;
    if (want != null && (want < 1 || want > maxDepth)) {
      // Past the outermost / innermost level: slide the origin along so
      // turning back acts at once.
      final edge = want < 1 ? 1 - 0.5 : maxDepth + 0.5;
      d.originX = x - (edge - d.startLevel) * step;
      want = null;
    }
    if (want == null) {
      d.pending = null;
      d.pendingTimer?.cancel();
      return;
    }
    if (d.pending == want) return; // the hold timer is running
    d.pending = want;
    d.pendingTimer?.cancel();
    d.pendingTimer = Timer(_levelHold, () {
      if (_drag != d || d.pending != want) return;
      d.lateral = want!;
      d.pending = null;
      _retarget();
    });
  }

  /// Where the block would land for the current pointer: the gap between
  /// the visible rows around it, and the level (the sideways level clamped
  /// to what's valid there). An invalid gap keeps the last target.
  void _retarget() {
    final d = _drag;
    final c = _c;
    final pointer = d?.pointer;
    if (d == null || c == null || pointer == null) return;
    final scope = context.findRenderObject() as RenderBox?;
    if (scope == null || !scope.hasSize) return;
    final y = scope.globalToLocal(pointer).dy;

    final rows = c.visible(section: d.section);
    final rects = [for (final r in rows) _rectOf(r.id, scope)];
    // Rows above the first laid-out one are above the pointer; below the
    // last, below it.
    final first = rects.indexWhere((r) => r != null);
    if (first < 0) return;
    final last = rects.lastIndexWhere((r) => r != null);
    var gap = first;
    for (var i = first; i <= last; i++) {
      final r = rects[i];
      if (r != null && y > r.center.dy) gap = i + 1;
    }
    if (gap > last) gap = rows.length;
    final above = gap > 0 ? rows[gap - 1] : null;
    final below = gap < rows.length ? rows[gap] : null;
    final inPlace =
        (above != null && d.blockIds.contains(above.id)) ||
        (below != null && d.blockIds.contains(below.id));

    final int k;
    if (inPlace) {
      k = d.home;
    } else if (below == null) {
      k = ReorderOutline.sectionRange(d.rest, d.section).$2;
    } else {
      k = d.rest.indexWhere((r) => r.id == below.id);
    }
    final range = ReorderOutline.validLevels(
      d.rest,
      k,
      section: d.section,
      height: d.height,
      maxDepth: c.maxDepth,
      collapsed: c.collapsed,
    );
    if (range == null) return;
    final level = d.lateral.clamp(range.$1, range.$2);
    if (level != d.lateral) {
      // What you see is the level: re-measure sideways from here.
      d.lateral = level;
      d.originX = pointer.dx - (level - d.startLevel) * widget.levelStep;
      d.pending = null;
      d.pendingTimer?.cancel();
    }
    if (d.level != null && d.level != level) HapticFeedback.lightImpact();
    d.k = k;
    d.level = level;

    // The line: at the block's own top in place, else at the gap.
    double? lineY;
    if (inPlace) {
      lineY = _rectOf(d.id, scope)?.top;
    } else {
      final belowRect = below == null ? null : _rectOf(below.id, scope);
      final aboveRect = above == null ? null : _rectOf(above.id, scope);
      lineY = belowRect?.top ?? aboveRect?.bottom;
    }
    if (lineY == null) return;
    final label = widget.dropLabel?.call(
      ReorderOutline.parentAt(d.rest, k, level, section: d.section),
    );
    _line.value = _DropLine(
      y: lineY.clamp(0.0, scope.size.height),
      level: level,
      label: label,
    );
  }

  void _autoScroll(Offset pointer) {
    final scope = context.findRenderObject() as RenderBox?;
    if (scope == null || !scope.hasSize) return;
    final y = scope.globalToLocal(pointer).dy;
    final h = scope.size.height;
    double step = 0;
    if (y < _scrollBand) {
      step = -_scrollMaxStep * ((_scrollBand - y) / _scrollBand).clamp(0, 1);
    } else if (y > h - _scrollBand) {
      step =
          _scrollMaxStep * ((y - (h - _scrollBand)) / _scrollBand).clamp(0, 1);
    }
    if (step == 0) {
      _stopAutoScroll();
      return;
    }
    _scrollStep = step;
    _scrollTimer ??= Timer.periodic(const Duration(milliseconds: 16), (_) {
      final sc = widget.scrollController;
      if (!sc.hasClients) return;
      final pos = sc.position;
      final next = (pos.pixels + _scrollStep).clamp(
        pos.minScrollExtent,
        pos.maxScrollExtent,
      );
      if (next == pos.pixels) return;
      sc.jumpTo(next);
      _retarget();
    });
  }

  void _stopAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _scrollStep = 0;
  }

  /// Holding over a collapsed parent opens it.
  void _hoverExpand(Offset pointer) {
    final d = _drag;
    final c = _c;
    if (d == null || c == null) return;
    final scope = context.findRenderObject() as RenderBox?;
    if (scope == null) return;
    final p = scope.globalToLocal(pointer);
    String? over;
    for (final r in c.visible(section: d.section)) {
      final rect = _rectOf(r.id, scope);
      if (rect != null && rect.top <= p.dy && p.dy < rect.bottom) {
        over = r.id;
        break;
      }
    }
    final eligible =
        over != null &&
        !d.blockIds.contains(over) &&
        c.isCollapsed(over) &&
        c.hasChildren(over);
    if (!eligible) {
      _expandTimer?.cancel();
      _hoverId = null;
      return;
    }
    if (_hoverId == over) return;
    _hoverId = over;
    _expandTimer?.cancel();
    _expandTimer = Timer(_expandHold, () {
      if (_drag != d || _hoverId != over) return;
      c.expand(over!);
      HapticFeedback.selectionClick();
      WidgetsBinding.instance.addPostFrameCallback((_) => _retarget());
    });
  }

  // ── Build ───────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final c = _c;
    // The same shape in both modes, so the scroll view underneath (and its
    // offset) survives entering / leaving the mode.
    return _ScopeData(
      state: this,
      version: _version,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        // Empty space deselects (a row's own tap wins over this one).
        onTap: c == null ? null : () => c.select(null),
        child: Stack(
          children: [
            widget.child,
            Positioned.fill(
              child: IgnorePointer(
                child: ValueListenableBuilder<_DropLine?>(
                  valueListenable: _line,
                  builder: (context, line, _) => line == null
                      ? const SizedBox.shrink()
                      : _DropIndicator(
                          line: line,
                          left:
                              widget.indentBase +
                              (line.level - 1) * widget.indentStep,
                          right: widget.indentBase,
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScopeData extends InheritedWidget {
  const _ScopeData({
    required this.state,
    required this.version,
    required super.child,
  });

  final _ReorderListScopeState state;
  final int version;

  @override
  bool updateShouldNotify(_ScopeData old) => old.version != version;
}

/// The drop line + its parent label ("ใต้ Food & Drinks").
class _DropIndicator extends StatelessWidget {
  const _DropIndicator({
    required this.line,
    required this.left,
    required this.right,
  });

  final _DropLine line;
  final double left;
  final double right;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    const thickness = 4.0;
    const labelHeight = 20.0;
    // Above the line, unless that leaves the list.
    final labelTop = line.y >= labelHeight + thickness
        ? line.y - labelHeight - thickness
        : line.y + thickness;
    return Stack(
      children: [
        Positioned(
          left: left,
          right: right,
          top: line.y - thickness / 2,
          height: thickness,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(thickness / 2),
            ),
          ),
        ),
        if (line.label != null)
          Positioned(
            left: left,
            top: labelTop,
            height: labelHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: BorderRadius.circular(labelHeight / 2),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Center(
                  widthFactor: 1,
                  child: Text(
                    line.label!,
                    maxLines: 1,
                    style: textTheme.labelSmall?.copyWith(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// One row in reorder mode: tap = select (tinted), a ⠿ handle at the end
/// drags at once, dimmed while its block is being dragged. Outside reorder
/// mode (no controller on the scope) it's just [child].
///
/// [child] should not handle taps itself while reordering (pass the row a
/// null onTap); its own buttons (▾ / ▴) keep working.
class ReorderRow extends StatefulWidget {
  const ReorderRow({required this.id, required this.child, super.key});

  final String id;
  final Widget child;

  @override
  State<ReorderRow> createState() => _ReorderRowState();
}

class _ReorderRowState extends State<ReorderRow> {
  _ReorderListScopeState? _scope;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final scope = context
        .dependOnInheritedWidgetOfExactType<_ScopeData>()
        ?.state;
    if (scope != _scope) {
      _scope?._unregister(widget.id, context);
      _scope = scope;
    }
    _scope?._register(widget.id, context);
  }

  @override
  void didUpdateWidget(ReorderRow old) {
    super.didUpdateWidget(old);
    if (old.id != widget.id) {
      _scope?._unregister(old.id, context);
      _scope?._register(widget.id, context);
    }
  }

  @override
  void dispose() {
    _scope?._unregister(widget.id, context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scope = _scope;
    final c = scope?._c;
    if (scope == null || c == null) return widget.child;
    final scheme = Theme.of(context).colorScheme;
    final selected = c.selectedId == widget.id;
    final drag = scope._drag;
    final dragging = drag?.blockIds.contains(widget.id) ?? false;
    final busy = drag != null && !dragging;

    return LayoutBuilder(
      builder: (context, constraints) {
        Widget content(bool lifted) => Row(
          children: [
            Expanded(child: widget.child),
            _Handle(active: lifted),
          ],
        );
        final handle = Draggable<String>(
          data: widget.id,
          maxSimultaneousDrags: busy ? 0 : 1,
          // The proxy lifts from exactly where the row is.
          dragAnchorStrategy: (draggable, handleContext, position) {
            final box = this.context.findRenderObject() as RenderBox;
            return box.globalToLocal(position);
          },
          feedback: _Proxy(width: constraints.maxWidth, child: content(true)),
          onDragStarted: () {
            final box = this.context.findRenderObject() as RenderBox?;
            final pointer =
                scope._lastPointerDown ??
                box?.localToGlobal(box.size.centerRight(Offset.zero)) ??
                Offset.zero;
            scope._startDrag(widget.id, pointer);
          },
          onDragUpdate: (d) => scope._updateDrag(d.globalPosition),
          onDragEnd: (_) => scope._endDrag(commit: true),
          childWhenDragging: const _Handle(active: true),
          child: Listener(
            onPointerDown: (e) => scope._lastPointerDown = e.position,
            child: const _Handle(active: false),
          ),
        );
        final row = Material(
          color: selected
              ? scheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          child: InkWell(
            onTap: drag != null ? null : () => c.tapRow(widget.id),
            child: Row(
              children: [
                Expanded(child: widget.child),
                handle,
              ],
            ),
          ),
        );
        return Semantics(
          selected: selected,
          // Always an Opacity: swapping the wrapper in would remount the
          // handle's Draggable mid-drag and end the drag.
          child: Opacity(opacity: dragging ? 0.3 : 1, child: row),
        );
      },
    );
  }
}

/// The ⠿ handle — a full touch target at the end of the row.
class _Handle extends StatelessWidget {
  const _Handle({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: 48,
      height: 48,
      child: Icon(
        AppIcons.reorder,
        color: active ? scheme.primary : scheme.onSurfaceVariant,
      ),
    );
  }
}

/// The row lifted under the finger while dragging.
class _Proxy extends StatelessWidget {
  const _Proxy({required this.width, required this.child});

  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 8,
      color: scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(width: width, child: child),
    );
  }
}
