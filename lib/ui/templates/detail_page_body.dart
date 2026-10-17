import 'package:flutter/material.dart';

import '../molecules/detail_meta.dart';
import '../molecules/detail_rows.dart';
import '../molecules/hero_shell.dart';
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
    this.metaLines = const [],
    this.bottomInset = AppSpacing.xxl,
    this.topInset = 0,
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
  final List<String> metaLines;
  final double bottomInset;

  final double topInset;
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
        topInset,
        AppSpacing.lg,
        bottomInset,
      ),
      children: [
        if (hero != null) ...[hero!, const SizedBox(height: HeroSpacing.after)],
        if (tabBar != null) ...[tabBar!, const SizedBox(height: AppSpacing.md)],
        if (tags != null) ...[tags!, const SizedBox(height: AppSpacing.md)],
        ...buildSections(),
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
