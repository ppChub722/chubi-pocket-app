import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../atoms/app_chip.dart';

/// A chip row's order, fixed once the lists it ranks have loaded (option B,
/// owner 2026-10-10): tapping a chip highlights it in place — nothing jumps
/// to the front. One picked elsewhere ("เพิ่มเติม") that isn't in the row
/// joins at the end, and stays. Keep one per row for the screen's life
/// (in a State).
class ChipOrder {
  List<String>? _frozen;

  /// [rank] is the order as of now — kept from the first call where
  /// [ready] (until then it's re-ranked every build, so a cold cache
  /// doesn't freeze an empty row). [picked] ids missing from it are added
  /// at the end.
  List<String> ids({
    required bool ready,
    required List<String> Function() rank,
    required Iterable<String> picked,
  }) {
    final out = _frozen ?? rank();
    if (ready) _frozen ??= out;
    for (final id in picked) {
      if (!out.contains(id)) out.add(id);
    }
    return out;
  }
}

/// `[icon]  [chip] [chip] … [⋯ เพิ่มเติม]` — one pick row of a form or a
/// filter: a muted leading [icon] says what the row is (no label), the
/// chips scroll sideways, and [onMore] adds "เพิ่มเติม" at the end (the
/// full picker). The transaction form's หมวด / แท็ก rows, the filter
/// sheet's ประเภท / กระเป๋า / หมวด / แท็ก rows. Under a section title
/// that carries the icon (the filter sheet), [icon] is null and the chips
/// start flush left.
///
/// [maxLines] (the filter sheet, owner 2026-10-11): the chips WRAP instead
/// of scrolling, onto at most that many lines; past it they're cut and the
/// last line ends with "เพิ่มเติม" (needs [onMore]). Null = one line that
/// scrolls sideways (the forms).
class ChipRow extends StatelessWidget {
  const ChipRow({
    required this.chips,
    this.icon,
    this.onMore,
    this.moreLabel,
    this.moreFirst = false,
    this.maxLines,
    super.key,
  }) : assert(maxLines == null || maxLines > 0),
       assert(!moreFirst || maxLines == null, 'moreFirst scrolls, never wraps');

  /// Null = no leading icon (a titled section shows it instead).
  final IconData? icon;
  final List<Widget> chips;

  /// Null = no "เพิ่มเติม" (a view-only row).
  final VoidCallback? onMore;

  /// The "เพิ่มเติม" text — required with [onMore].
  final String? moreLabel;

  /// The pick chip leads the row instead of ending it, and shows dashed — "no
  /// choice made, tap to choose" (the pending form's เลือกกระเป๋า / เลือกหมวด,
  /// [moreLabel] is its text). One scrolling line only.
  final bool moreFirst;

  /// Null = one scrolling line; else wrap, cut past this many lines.
  final int? maxLines;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final more = onMore == null
        ? null
        : moreFirst
        ? AppChip(
            label: moreLabel ?? '',
            icon: AppIcons.add,
            dashed: true,
            onTap: onMore,
          )
        : AppChip(label: moreLabel ?? '', icon: AppIcons.more, onTap: onMore);
    final lines = maxLines;
    return Row(
      crossAxisAlignment: lines == null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: lines != null
              ? _LimitedWrap(
                  maxLines: lines,
                  hasTrailing: more != null,
                  children: [...chips, ?more],
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      if (moreFirst && more != null) ...[
                        more,
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      for (final c in chips) ...[
                        c,
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      if (!moreFirst) ?more,
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

/// [ChipRow.maxLines]: the chips wrap onto at most [maxLines] lines with
/// the last child (the "เพิ่มเติม" chip, when [hasTrailing]) at the very
/// end. Chips that don't fit are left out — the trailing chip takes their
/// place on the last line — so a long list never grows the section past
/// [maxLines]. Every child is laid out; only the shown ones paint and take
/// taps.
class _LimitedWrap extends MultiChildRenderObjectWidget {
  const _LimitedWrap({
    required this.maxLines,
    required this.hasTrailing,
    required super.children,
  });

  final int maxLines;
  final bool hasTrailing;

  @override
  _RenderLimitedWrap createRenderObject(BuildContext context) =>
      _RenderLimitedWrap(maxLines: maxLines, hasTrailing: hasTrailing);

  @override
  void updateRenderObject(BuildContext context, _RenderLimitedWrap r) {
    r
      ..maxLines = maxLines
      ..hasTrailing = hasTrailing;
  }
}

class _WrapData extends ContainerBoxParentData<RenderBox> {
  bool shown = true;
}

class _RenderLimitedWrap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _WrapData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _WrapData> {
  _RenderLimitedWrap({required int maxLines, required bool hasTrailing})
    : _maxLines = maxLines,
      _hasTrailing = hasTrailing;

  static const _gap = AppSpacing.xs;

  int _maxLines;
  set maxLines(int v) {
    if (v == _maxLines) return;
    _maxLines = v;
    markNeedsLayout();
  }

  bool _hasTrailing;
  set hasTrailing(bool v) {
    if (v == _hasTrailing) return;
    _hasTrailing = v;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _WrapData) child.parentData = _WrapData();
  }

  /// Greedy lines of item indexes, each item [widths]-wide, in [max].
  static List<List<int>> _lines(List<double> widths, double max) {
    final lines = <List<int>>[];
    var x = 0.0;
    for (var i = 0; i < widths.length; i++) {
      final w = widths[i];
      if (lines.isEmpty || (lines.last.isNotEmpty && x + _gap + w > max)) {
        lines.add([i]);
        x = w;
      } else {
        lines.last.add(i);
        x += _gap + w;
      }
    }
    return lines;
  }

  @override
  void performLayout() {
    final max = constraints.maxWidth;
    final kids = getChildrenAsList();
    for (final c in kids) {
      c.layout(BoxConstraints(maxWidth: max), parentUsesSize: true);
    }
    final widths = [for (final c in kids) c.size.width];
    var lines = _lines(widths, max);
    if (lines.length > _maxLines) {
      // Cut: the first [maxLines] lines of chips, then the trailing chip
      // at the end of the last one — dropping chips from its end until it
      // fits.
      final trailing = _hasTrailing ? kids.length - 1 : null;
      lines = [
        for (final line in lines.take(_maxLines))
          [
            for (final i in line)
              if (i != trailing) i,
          ],
      ];
      if (trailing != null) {
        final last = lines.last;
        double used() => last.isEmpty
            ? 0
            : last.map((i) => widths[i]).reduce((a, b) => a + b) +
                  _gap * (last.length - 1);
        while (last.isNotEmpty && used() + _gap + widths[trailing] > max) {
          last.removeLast();
        }
        last.add(trailing);
      }
    }
    final shown = {for (final line in lines) ...line};
    var y = 0.0;
    var width = 0.0;
    for (final (n, line) in lines.indexed) {
      if (n > 0) y += _gap;
      final h = line.map((i) => kids[i].size.height).fold(0.0, math.max);
      var x = 0.0;
      for (final i in line) {
        final c = kids[i];
        (c.parentData! as _WrapData).offset = Offset(
          x,
          y + (h - c.size.height) / 2,
        );
        x += c.size.width + _gap;
      }
      width = math.max(width, x - _gap);
      y += h;
    }
    for (final (i, c) in kids.indexed) {
      (c.parentData! as _WrapData).shown = shown.contains(i);
    }
    size = constraints.constrain(Size(width, y));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    var child = firstChild;
    while (child != null) {
      final data = child.parentData! as _WrapData;
      if (data.shown) context.paintChild(child, offset + data.offset);
      child = data.nextSibling;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    var child = lastChild;
    while (child != null) {
      final data = child.parentData! as _WrapData;
      if (data.shown &&
          result.addWithPaintOffset(
            offset: data.offset,
            position: position,
            hitTest: (r, p) => child!.hitTest(r, position: p),
          )) {
        return true;
      }
      child = data.previousSibling;
    }
    return false;
  }
}
