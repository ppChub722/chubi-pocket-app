import '../tokens/hero_metrics.dart';
import 'package:flutter/material.dart';

import '../molecules/detail_meta.dart';
import '../molecules/detail_rows.dart';
import '../organisms/pull_to_refresh.dart';
import '../tokens/app_spacing.dart';
import 'edit_mode_scope.dart';

class DetailPageBody extends StatelessWidget {
  const DetailPageBody({
    required this.sections,
    this.hero,
    this.tabBar,
    this.tags,
    this.manage,
    this.footnote,
    this.metaLines = const [],
    this.bottomInset = AppSpacing.xxl,
    this.topInset,
    this.controller,
    this.physics,
    this.onRefresh,
    this.refreshEnabled = true,
    super.key,
  });

  final Widget? hero;

  final Widget? tabBar;

  final Widget? tags;
  final List<Widget? Function(bool first)> sections;
  final Widget? manage;

  /// The page's footnote ([DetailFootnote]: under the sections, before
  /// [manage], inset like a card title).
  final String? footnote;
  final List<String> metaLines;
  final double bottomInset;

  /// Space above the first child. Null (default) clears the top bar the page
  /// sits behind: the status-bar + bar height of this body's own context plus
  /// [AppSpacing.lg]. Pass a number only to override (0 = flush, for a body
  /// that is not under the bar).
  final double? topInset;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  final Future<void> Function()? onRefresh;
  final bool refreshEnabled;

  static bool _headless(Widget w) =>
      w is SectionCard && w.title == null && w.trailing == null;

  static bool _mergeable(Widget w) =>
      _headless(w) &&
      w is SectionCard &&
      w.leading == null &&
      w.description == null &&
      w.dividers &&
      !w.locked &&
      w.onHeaderTap == null;

  List<Widget> buildSections() {
    final built = <(int, Widget)>[
      for (final (i, build) in sections.indexed)
        if (build(false) case final s?) (i, s),
    ];
    final merged = <Widget>[
      for (final (_, s) in built)
        if (_mergeable(s)) ...(s as SectionCard).children,
    ];
    final out = <Widget>[];
    if (merged.isNotEmpty) out.add(SectionCard(first: true, children: merged));
    for (final (i, s) in built) {
      if (_headless(s) && !_mergeable(s)) {
        out.add(sections[i](out.isEmpty)!);
      }
    }
    for (final (i, s) in built) {
      if (!_headless(s)) out.add(sections[i](out.isEmpty)!);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final refresh = onRefresh;
    final list = ListView(
      controller: controller,
      physics:
          physics ??
          (refresh == null ? null : const AlwaysScrollableScrollPhysics()),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topInset ?? MediaQuery.paddingOf(context).top + AppSpacing.lg,
        AppSpacing.lg,
        bottomInset,
      ),
      children: [
        if (hero != null) ...[
          hero!,
          SizedBox(height: HeroMetrics.of(context).after),
        ],
        if (tabBar != null) ...[tabBar!, const SizedBox(height: AppSpacing.md)],
        if (tags != null) ...[tags!, const SizedBox(height: AppSpacing.md)],
        ...buildSections(),
        if (footnote case final f?) DetailFootnote(f),
        ?manage,
        DetailMeta(lines: metaLines),
      ],
    );
    if (refresh == null) return list;
    return PullToRefresh(
      onRefresh: refresh,
      enabled: refreshEnabled && !EditModeScope.isBusy(context),
      child: list,
    );
  }
}
