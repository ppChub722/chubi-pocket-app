import 'package:flutter/material.dart';

import '../atoms/list_break.dart';
import '../atoms/skeleton_box.dart';
import '../atoms/skeletons.dart';
import '../molecules/detail_rows.dart';
import '../molecules/hero_shell.dart';
import '../molecules/hero_style.dart';
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
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          SkeletonCircle(size: 36),
          SizedBox(width: AppSpacing.md),
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
          SizedBox(width: AppSpacing.sm),
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
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.xs,
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
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: SkeletonBox(height: 40, borderRadius: 20),
          ),
          SizedBox(height: AppSpacing.sm),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Row(
              children: [
                SkeletonBox(width: 96, height: 40, borderRadius: 20),
                Spacer(),
                SkeletonBox(width: 110, height: 40, borderRadius: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The body of a list page while it loads for the first time: [toolbar] (when
/// the page has one and doesn't render it itself), then rows. [grouped] draws
/// [days] day groups (header · rows) with the SAME hairlines / band the real
/// grouped list has; otherwise [rows] plain rows.
class ListPageSkeleton extends StatelessWidget {
  const ListPageSkeleton({
    this.toolbar = false,
    this.grouped = false,
    this.days = 2,
    this.rows = 5,
    this.padding = EdgeInsets.zero,
    this.rowDividerIndent = 64,
    super.key,
  });

  final bool toolbar;
  final bool grouped;
  final int days;
  final int rows;
  final EdgeInsets padding;
  final double rowDividerIndent;

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(width: AppSpacing.xs),
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
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          if (icon) ...[
            const SkeletonCircle(size: 22),
            const SizedBox(width: AppSpacing.md),
          ],
          const Expanded(child: SkeletonText(style: _labelBold, width: 110)),
          const SizedBox(width: AppSpacing.md),
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
        if (!first) const SizedBox(height: AppSpacing.lg),
        if (heading) ...const [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.xs,
              AppSpacing.xs,
            ),
            child: SkeletonText(style: _labelLarge, width: 96),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: SkeletonText(style: _bodySmall, width: 200),
          ),
        ],
        SectionCard(
          first: true,
          children: [
            for (var i = 0; i < rows; i++)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
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
    final top = topInset ?? MediaQuery.paddingOf(context).top + AppSpacing.lg;
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        top,
        AppSpacing.lg,
        AppSpacing.xxl,
      ),
      children: [
        const HeroSkeleton(),
        const SizedBox(height: HeroSpacing.after),
        if (tags) ...const [
          TagsStripSkeleton(),
          SizedBox(height: AppSpacing.md),
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

/// A dashboard while it loads: the SAME slot order and gaps as
/// `DashboardPageBody` (snapshot → gap → period bar → gap → KPI cards → charts →
/// gap → tiles), each slot a block of the height the real card has. The heights
/// default to a typical home; a page with different cards passes its own.
class DashboardPageSkeleton extends StatelessWidget {
  const DashboardPageSkeleton({
    this.snapshots = const [110],
    this.period = true,
    this.kpis = const [90],
    this.charts = const [160, 140],
    this.tilesHeight = 176,
    this.padding = EdgeInsets.zero,
    super.key,
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
  final EdgeInsets padding;

  // A card slot: its height INCLUDES any margin the real card carries.
  Widget _block(double h) => SkeletonBox(height: h, borderRadius: 16);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      children: [
        for (final h in snapshots) _block(h),
        if (period) ...[
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(height: 40, borderRadius: 20),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final h in kpis) _block(h),
        for (final h in charts) _block(h),
        if (tilesHeight > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          SkeletonBox(height: tilesHeight, borderRadius: 16),
        ],
      ],
    );
  }
}
