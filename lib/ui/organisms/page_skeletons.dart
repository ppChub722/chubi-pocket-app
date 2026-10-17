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
    const inset = EdgeInsets.symmetric(horizontal: AppSpacing.lg);
    return Padding(
      padding: inset,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (s.headerHeight > 0) ...[
            SkeletonBox(height: s.headerHeight, borderRadius: AppRadius.md),
            const SizedBox(height: AppSpacing.lg),
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
            const SizedBox(height: AppSpacing.md),
          ],
          for (var r = 0; r < 2; r++) ...[
            if (r > 0) const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                for (var c = 0; c < s.gridColumns; c++) ...[
                  if (c > 0) const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: SkeletonBox(
                      height: s.gridItemExtent,
                      borderRadius: AppRadius.lg,
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

class DashboardSkeletonShape {
  const DashboardSkeletonShape({
    this.snapshots = const [110],
    this.period = true,
    this.kpis = const [90],
    this.charts = const [160, 140],
    this.tilesHeight = 176,
  });

  final List<double> snapshots;

  final bool period;

  final List<double> kpis;

  final List<double> charts;

  final double tilesHeight;
}

class DashboardPageSkeleton extends StatelessWidget {
  const DashboardPageSkeleton({
    this.shape = const DashboardSkeletonShape(),
    this.padding = EdgeInsets.zero,
    super.key,
  });

  final DashboardSkeletonShape shape;
  final EdgeInsets padding;

  static const double periodHeight = 36;

  Widget _block(double h) => SkeletonBox(height: h, borderRadius: 16);

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: padding,
      children: [
        for (final h in shape.snapshots) _block(h),
        if (shape.period) ...[
          const SizedBox(height: AppSpacing.md),
          const SkeletonBox(height: periodHeight, borderRadius: 20),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (final h in shape.kpis) _block(h),
        for (final h in shape.charts) _block(h),
        if (shape.tilesHeight > 0) ...[
          const SizedBox(height: AppSpacing.lg),
          SkeletonBox(height: shape.tilesHeight, borderRadius: 16),
        ],
      ],
    );
  }
}
