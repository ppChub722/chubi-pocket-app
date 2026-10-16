import 'package:flutter/material.dart';

import '../atoms/list_break.dart';
import '../atoms/skeleton_box.dart';
import '../atoms/skeletons.dart';
import '../molecules/detail_rows.dart';
import '../molecules/hero_shell.dart';
import '../molecules/hero_style.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';
import 'divided_rows.dart';
import 'header_card.dart';

// Page-shaped skeletons (owner 2026-10-12): the loading state mirrors the REAL
// layout — same slots, paddings and line heights (the bars are laid out over
// invisible text of the real style, SkeletonText) — so nothing jumps when the
// data arrives. The templates compose these; a page never draws its own.

/// A list row at the transaction row geometry: icon · two lines · amount.
class ListRowSkeleton extends StatelessWidget {
  const ListRowSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(
        horizontal: PpForgeSpacing.lg,
        vertical: PpForgeSpacing.sm,
      ),
      child: Row(
        children: [
          SkeletonCircle(size: 36),
          SizedBox(width: PpForgeSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SkeletonText(style: _bodyLarge, width: 150),
                SizedBox(height: 2),
                SkeletonText(style: _bodySmall, width: 100),
              ],
            ),
          ),
          SizedBox(width: PpForgeSpacing.sm),
          SkeletonText(style: _titleSmall, width: 56),
        ],
      ),
    );
  }
}

/// A day / section header row (a group break — gets the band above it).
class DayHeaderSkeleton extends StatelessWidget implements ListBreak {
  const DayHeaderSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.fromLTRB(
        PpForgeSpacing.lg,
        PpForgeSpacing.md,
        PpForgeSpacing.lg,
        PpForgeSpacing.xs,
      ),
      child: Row(
        children: [
          Expanded(child: SkeletonText(style: _labelLarge, width: 80)),
          SkeletonText(style: _labelLarge, width: 64),
        ],
      ),
    );
  }
}

/// The search capsule + the filter / sort chip row (the ListToolbar shape).
class ListToolbarSkeleton extends StatelessWidget {
  const ListToolbarSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: PpForgeSpacing.xs),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PpForgeSpacing.lg),
            child: SkeletonBox(height: 40, borderRadius: 20),
          ),
          SizedBox(height: PpForgeSpacing.sm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: PpForgeSpacing.lg),
            child: Row(
              children: [
                SkeletonBox(width: 96, height: 28, borderRadius: 14),
                Spacer(),
                SkeletonBox(width: 110, height: 28, borderRadius: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// What a list page looks like on its first load — `ListPageBody.skeletonShape`
/// (the template builds the [ListPageSkeleton]; a page never draws its own):
///
/// - default: [rows] list rows (grouped by day when the list has row
///   dividers);
/// - [ListSkeletonShape.grid]: a cards grid (wallets) — an optional summary
///   block of [headerHeight] on top, an optional sort row (a chip at the
///   right), then two rows of [gridColumns] cards of [gridItemExtent], all
///   inset by [PpForgeSpacing.lg] like the real cards.
class ListSkeletonShape {
  const ListSkeletonShape({this.rows = 6})
    : headerHeight = 0,
      sortRow = false,
      gridColumns = 0,
      gridItemExtent = 0;

  const ListSkeletonShape.grid({
    required this.gridColumns,
    required this.gridItemExtent,
    this.headerHeight = 0,
    this.sortRow = false,
  }) : rows = 0;

  final int rows;
  final double headerHeight;
  final bool sortRow;
  final int gridColumns;
  final double gridItemExtent;

  bool get isGrid => gridColumns > 0;
}

/// The body of a list page while it loads for the first time: [toolbar] (when
/// the page has one and doesn't render it itself), then rows. [grouped] draws
/// [days] day groups (header · rows) with the SAME hairlines / band the real
/// grouped list has; otherwise [rows] plain rows. [shape] = a grid page (see
/// [ListSkeletonShape.grid]) instead of rows.
class ListPageSkeleton extends StatelessWidget {
  const ListPageSkeleton({
    this.toolbar = false,
    this.grouped = false,
    this.days = 2,
    this.rows = 5,
    this.padding = EdgeInsets.zero,
    this.rowDividerIndent = 64,
    this.shape,
    super.key,
  });

  final bool toolbar;
  final bool grouped;
  final int days;
  final int rows;
  final EdgeInsets padding;
  final double rowDividerIndent;
  final ListSkeletonShape? shape;

  Widget _grid(ListSkeletonShape s) {
    const inset = EdgeInsets.symmetric(horizontal: PpForgeSpacing.lg);
    return Padding(
      padding: inset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (s.headerHeight > 0) ...[
            SkeletonBox(height: s.headerHeight, borderRadius: PpForgeRadius.md),
            const SizedBox(height: PpForgeSpacing.lg),
          ],
          if (s.sortRow) ...[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: SkeletonBox(
                width: 120,
                height: ChipSize.chip.height,
                borderRadius: ChipSize.chip.height / 2,
              ),
            ),
            const SizedBox(height: PpForgeSpacing.md),
          ],
          for (var r = 0; r < 2; r++) ...[
            if (r > 0) const SizedBox(height: PpForgeSpacing.md),
            Row(
              children: [
                for (var c = 0; c < s.gridColumns; c++) ...[
                  if (c > 0) const SizedBox(width: PpForgeSpacing.md),
                  Expanded(
                    child: SkeletonBox(
                      height: s.gridItemExtent,
                      borderRadius: PpForgeRadius.lg,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = shape;
    if (s != null && s.isGrid) {
      return ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: padding,
        children: [if (toolbar) const ListToolbarSkeleton(), _grid(s)],
      );
    }
    final rows = s?.rows ?? this.rows;
    final items = <Widget>[
      if (grouped)
        for (var d = 0; d < days; d++) ...[
          const DayHeaderSkeleton(),
          for (var r = 0; r < (d == 0 ? 3 : 4); r++) const ListRowSkeleton(),
        ]
      else
        for (var r = 0; r < rows; r++) const ListRowSkeleton(),
    ];
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      children: [
        if (toolbar) const ListToolbarSkeleton(),
        ...(grouped
            ? dividedRows(context, items, indent: rowDividerIndent)
            : items),
      ],
    );
  }
}

/// The hero at the real HeaderCard geometry: a status-chip row, the icon, the
/// name and a description line.
class HeroSkeleton extends StatelessWidget {
  const HeroSkeleton({this.chips = true, this.description = true, super.key});

  final bool chips;
  final bool description;

  @override
  Widget build(BuildContext context) {
    return HeaderCard(
      heroStyle: const HeroStyle.plain(),
      topRow: chips
          ? [
              SkeletonBox(
                width: 84,
                height: ChipSize.control.height,
                borderRadius: 20,
              ),
            ]
          : null,
      leading: const SkeletonCircle(size: 52),
      title: const SkeletonText(style: _titleMedium, width: 150),
      description: description
          ? const SkeletonText(style: _bodySmall, width: 220)
          : null,
    );
  }
}

/// The tag chip strip under the hero.
class TagsStripSkeleton extends StatelessWidget {
  const TagsStripSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final w in const [64.0, 84.0, 56.0]) ...[
          SkeletonBox(width: w, height: ChipSize.chip.height, borderRadius: 14),
          const SizedBox(width: PpForgeSpacing.xs),
        ],
      ],
    );
  }
}

/// A DetailRow at its real padding: icon slot · label · value.
class DetailRowSkeleton extends StatelessWidget {
  const DetailRowSkeleton({this.icon = false, super.key});

  final bool icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: PpForgeSpacing.md),
      child: Row(
        children: [
          if (icon) ...[
            const SkeletonCircle(size: 22),
            const SizedBox(width: PpForgeSpacing.md),
          ],
          const Expanded(child: SkeletonText(style: _labelBold, width: 110)),
          const SizedBox(width: PpForgeSpacing.md),
          const SkeletonText(style: _bodyLarge, width: 72),
        ],
      ),
    );
  }
}

/// A grouped section: [heading] (a title + description line above the box, like
/// SectionCard) and [rows] rows in the filled container.
class SectionSkeleton extends StatelessWidget {
  const SectionSkeleton({
    this.rows = 3,
    this.heading = true,
    this.icons = false,
    this.first = false,
    super.key,
  });

  final int rows;
  final bool heading;
  final bool icons;
  final bool first;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!first) const SizedBox(height: PpForgeSpacing.lg),
        if (heading) ...const [
          Padding(
            padding: EdgeInsets.fromLTRB(
              PpForgeSpacing.md,
              0,
              PpForgeSpacing.xs,
              PpForgeSpacing.xs,
            ),
            child: SkeletonText(style: _labelLarge, width: 96),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              PpForgeSpacing.md,
              0,
              PpForgeSpacing.md,
              PpForgeSpacing.sm,
            ),
            child: SkeletonText(style: _bodySmall, width: 200),
          ),
        ],
        SectionCard(
          first: true,
          children: [
            for (var i = 0; i < rows; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: PpForgeSpacing.lg,
                ),
                child: DetailRowSkeleton(icon: icons),
              ),
          ],
        ),
      ],
    );
  }
}

/// A detail page while it loads: hero → [tags] strip → the ONE heading-less box
/// ([rows] rows) → one headed section per entry of [sections] (its row count).
/// Same paddings as DetailPageBody.
class DetailPageSkeleton extends StatelessWidget {
  const DetailPageSkeleton({
    this.tags = false,
    this.rows = 3,
    this.sections = const [2],
    this.topInset,
    super.key,
  });

  final bool tags;
  final int rows;
  final List<int> sections;

  /// Space above the hero; null = clear the floating top bar.
  final double? topInset;

  @override
  Widget build(BuildContext context) {
    final top =
        topInset ?? MediaQuery.paddingOf(context).top + PpForgeSpacing.lg;
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        PpForgeSpacing.lg,
        top,
        PpForgeSpacing.lg,
        PpForgeSpacing.xxl,
      ),
      children: [
        const HeroSkeleton(),
        const SizedBox(height: HeroSpacing.after),
        if (tags) ...const [
          TagsStripSkeleton(),
          SizedBox(height: PpForgeSpacing.md),
        ],
        if (rows > 0) SectionSkeleton(rows: rows, heading: false, first: true),
        for (final n in sections) SectionSkeleton(rows: n),
      ],
    );
  }
}

TextStyle? _bodyLarge(TextTheme t) => t.bodyLarge;
TextStyle? _bodySmall(TextTheme t) => t.bodySmall;
TextStyle? _titleSmall(TextTheme t) => t.titleSmall;
TextStyle? _titleMedium(TextTheme t) => t.titleMedium;
TextStyle? _labelLarge(TextTheme t) => t.labelLarge;
TextStyle? _labelBold(TextTheme t) =>
    t.titleMedium?.copyWith(fontWeight: FontWeight.bold);

/// The slot heights of a dashboard's first-load skeleton: one block per real
/// card, each height INCLUDING the margin / section header the real card
/// carries. The defaults are a generic dashboard; a page passes the heights its
/// own cards really have (Home keeps a geometry test on them) to
/// `DashboardPageBody.skeletonShape`.
class DashboardSkeletonShape {
  const DashboardSkeletonShape({
    this.snapshots = const [110],
    this.period = true,
    this.kpis = const [90],
    this.charts = const [160, 140],
    this.tilesHeight = 176,
  });

  /// Heights of the "right now" blocks.
  final List<double> snapshots;

  /// The month / period stepper bar.
  final bool period;

  /// Heights of the KPI cards.
  final List<double> kpis;

  /// Heights of the chart cards.
  final List<double> charts;

  /// Height of the tiles grid; 0 = none.
  final double tilesHeight;
}

/// A dashboard while it loads: the SAME slot order and gaps as
/// `DashboardPageBody` (snapshot → gap → period bar → gap → KPI cards → charts →
/// gap → tiles), each slot a block of the height the real card has
/// ([shape]). The template builds it; pages only pass the shape.
class DashboardPageSkeleton extends StatelessWidget {
  const DashboardPageSkeleton({
    this.shape = const DashboardSkeletonShape(),
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final DashboardSkeletonShape shape;
  final EdgeInsets padding;

  /// The period bar's height (a `StepperPill.month`).
  static const double periodHeight = 36;

  // A card slot: its height INCLUDES any margin the real card carries.
  Widget _block(double h) => SkeletonBox(height: h, borderRadius: 16);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      children: [
        for (final h in shape.snapshots) _block(h),
        if (shape.period) ...[
          const SizedBox(height: PpForgeSpacing.md),
          const SkeletonBox(height: periodHeight, borderRadius: 20),
          const SizedBox(height: PpForgeSpacing.sm),
        ],
        for (final h in shape.kpis) _block(h),
        for (final h in shape.charts) _block(h),
        if (shape.tilesHeight > 0) ...[
          const SizedBox(height: PpForgeSpacing.lg),
          SkeletonBox(height: shape.tilesHeight, borderRadius: 16),
        ],
      ],
    );
  }
}
