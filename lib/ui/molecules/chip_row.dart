import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/scheduler.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../atoms/app_chip.dart';
import '../tokens/chip_size.dart';

class ChipOrder {
  List<String>? _frozen;

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

class ChipRow extends StatelessWidget {
  const ChipRow({
    required this.chips,
    this.icon,
    this.label,
    this.onMore,
    this.moreLabel,
    this.moreFirst = false,
    this.maxLines,
    this.moreOnlyWhenCut = false,
    super.key,
  }) : assert(maxLines == null || maxLines > 0),
       assert(!moreFirst || maxLines == null, 'moreFirst scrolls, never wraps');

  final bool moreOnlyWhenCut;

  /// Null = no leading icon (a titled section shows it instead).
  final IconData? icon;

  final String? label;
  final List<Widget> chips;

  final VoidCallback? onMore;

  final String? moreLabel;

  final bool moreFirst;

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
        : AppChip(
            label: moreLabel ?? '',
            icon: AppIcons.more,
            dashed: true,
            onTap: onMore,
          );
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
        if (label != null) ...[
          Text(
            label!,
            maxLines: 1,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          child: lines != null
              ? _LimitedWrap(
                  maxLines: lines,
                  hasTrailing: more != null,
                  moreOnlyWhenCut: moreOnlyWhenCut,
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

class _LimitedWrap extends MultiChildRenderObjectWidget {
  const _LimitedWrap({
    required this.maxLines,
    required this.hasTrailing,
    required this.moreOnlyWhenCut,
    required super.children,
    this.onHidden,
  });

  final int maxLines;
  final bool hasTrailing;
  final bool moreOnlyWhenCut;

  /// After a layout that changed it: how many chips (the trailing one aside)
  /// didn't fit.
  final ValueChanged<int>? onHidden;

  @override
  _RenderLimitedWrap createRenderObject(BuildContext context) =>
      _RenderLimitedWrap(
        maxLines: maxLines,
        hasTrailing: hasTrailing,
        moreOnlyWhenCut: moreOnlyWhenCut,
      )..onHidden = onHidden;

  @override
  void updateRenderObject(BuildContext context, _RenderLimitedWrap r) {
    r
      ..maxLines = maxLines
      ..hasTrailing = hasTrailing
      ..moreOnlyWhenCut = moreOnlyWhenCut
      ..onHidden = onHidden;
  }
}

class _WrapData extends ContainerBoxParentData<RenderBox> {
  bool shown = true;
}

class _RenderLimitedWrap extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _WrapData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _WrapData> {
  _RenderLimitedWrap({
    required int maxLines,
    required bool hasTrailing,
    required bool moreOnlyWhenCut,
  }) : _maxLines = maxLines,
       _hasTrailing = hasTrailing,
       _moreOnlyWhenCut = moreOnlyWhenCut;

  bool _moreOnlyWhenCut;
  set moreOnlyWhenCut(bool v) {
    if (v == _moreOnlyWhenCut) return;
    _moreOnlyWhenCut = v;
    markNeedsLayout();
  }

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

  ValueChanged<int>? onHidden;
  int? _reportedHidden;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _WrapData) child.parentData = _WrapData();
  }

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
    final withoutTrailing = _hasTrailing && _moreOnlyWhenCut
        ? _lines(widths.sublist(0, widths.length - 1), max)
        : null;
    if (withoutTrailing != null && withoutTrailing.length <= _maxLines) {
      lines = withoutTrailing;
    } else if (lines.length > _maxLines) {
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
    final report = onHidden;
    if (report != null) {
      final chips = _hasTrailing ? kids.length - 1 : kids.length;
      final hidden = chips - shown.where((i) => i < chips).length;
      if (hidden != _reportedHidden) {
        _reportedHidden = hidden;
        // Layout can't rebuild the "+N" chip; tell the owner after the frame.
        SchedulerBinding.instance.addPostFrameCallback((_) => report(hidden));
      }
    }
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

/// Chips in at most [maxLines] lines; the ones that don't fit become one
/// "+N" chip at the end. Nothing extra shows when everything fits.
///
/// Tapping "+N" calls [onMore] (edit mode: open the picker). Without one and
/// with [expandable], it opens the row up to every chip, ending in a ⌃ chip
/// that folds it back to "+N".
class LimitedChipWrap extends StatefulWidget {
  const LimitedChipWrap({
    required this.chips,
    this.maxLines = 2,
    this.onMore,
    this.expandable = false,
    this.size = ChipSize.chip,
    super.key,
  });

  final List<Widget> chips;
  final int maxLines;
  final VoidCallback? onMore;
  final bool expandable;
  final ChipSize size;

  @override
  State<LimitedChipWrap> createState() => _LimitedChipWrapState();
}

class _LimitedChipWrapState extends State<LimitedChipWrap> {
  int _hidden = 0;
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final more =
        widget.onMore ??
        (widget.expandable ? () => setState(() => _open = true) : null);
    if (_open && widget.onMore == null) {
      return ChipSizeScope(
        size: widget.size,
        child: Wrap(
          spacing: _RenderLimitedWrap._gap,
          runSpacing: _RenderLimitedWrap._gap,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ...widget.chips,
            AppChip(
              key: const ValueKey('chipWrapFold'),
              label: '',
              icon: AppIcons.collapse,
              size: widget.size,
              onTap: () => setState(() => _open = false),
            ),
          ],
        ),
      );
    }
    return ChipSizeScope(
      size: widget.size,
      child: _LimitedWrap(
        maxLines: widget.maxLines,
        hasTrailing: true,
        moreOnlyWhenCut: true,
        onHidden: (n) {
          if (mounted && n != _hidden) setState(() => _hidden = n);
        },
        children: [
          ...widget.chips,
          AppChip(
            key: const ValueKey('chipWrapMore'),
            label: _hidden > 0 ? '+$_hidden' : '+',
            size: widget.size,
            onTap: more,
          ),
        ],
      ),
    );
  }
}
