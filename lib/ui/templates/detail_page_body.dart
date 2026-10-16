import 'package:flutter/material.dart';

import '../molecules/detail_meta.dart';
import '../molecules/detail_rows.dart';
import '../molecules/hero_shell.dart';
import '../organisms/pull_to_refresh.dart';
import '../tokens/app_spacing.dart';
import 'edit_mode_scope.dart';

/// The DetailPage template's body (owner 2026-10-12): every entity's detail
/// page is the same skeleton —
///
///   hero (tinted, watermark, top row · ✏️) → tags (plain strip) → ONE box of all the heading-less rows → headed sections → การจัดการ (edit only)
///   → record info
///
/// The page keeps its own Scaffold, top bar, edit-mode mixin (`editScope`) and
/// action bar; this widget lays out the scrolling content so spacing, the
/// "first section has no band" rule, the manage section and the meta lines are
/// identical everywhere.
///
/// - [hero]: usually a `HeaderCard` (a hero with no chips collapses its top
///   row by itself).
/// - [sections]: builders, each told whether it is the first section shown (no
///   band above it) and free to return null (nothing to show). A page's
///   sections are `SectionCard`s — each green heading carries a one-line
///   `description`.
/// - [manage]: a `ManageSection` in edit mode, else null. It is never first.
/// - [metaLines]: from `detailMetaLines(...)`; empty = no meta.
/// - [bottomInset]: clearance for a floating bar under the list.
class DetailPageBody extends StatelessWidget {
  const DetailPageBody({
    required this.sections,
    this.hero,
    this.tabBar,
    this.tags,
    this.manage,
    this.metaLines = const [],
    this.bottomInset = PpForgeSpacing.xxl,
    this.topInset = 0,
    this.controller,
    this.physics,
    this.onRefresh,
    this.refreshEnabled = true,
    super.key,
  });

  /// null when the hero lives outside this list (e.g. above a pager) — the
  /// spacer under it goes too.
  final Widget? hero;

  /// A tab bar ([PpForgeTabBar]) directly under the hero, before the tags and
  /// every section (a budget's periods / items tabs). The page swaps what
  /// its sections show on the tab; null = none.
  final Widget? tabBar;

  /// The tag row — ALWAYS directly under the hero (owner 2026-10-12), before
  /// every section. null = the entity has no tags.
  final Widget? tags;
  final List<Widget? Function(bool first)> sections;
  final Widget? manage;
  final List<String> metaLines;
  final double bottomInset;

  /// Space above the hero (a transparent top bar floats over the list).
  final double topInset;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  /// Pull to refresh = re-open the page: re-run its load call. Every detail
  /// page passes it. Switched OFF automatically while the page is being edited
  /// or saved (under `EditModeMixin.editScope`), so a refresh never overwrites
  /// unsaved edits; [refreshEnabled] false turns it off by hand (create mode).
  final Future<void> Function()? onRefresh;
  final bool refreshEnabled;

  /// A group with no heading and no title-row action (basic rows, description,
  /// note).
  static bool _headless(Widget w) =>
      w is SectionCard && w.title == null && w.trailing == null;

  /// A headless group that can be merged into the top box: plain rows with the
  /// standard 2 px gaps (not a locked or button group).
  static bool _mergeable(Widget w) =>
      _headless(w) &&
      w is SectionCard &&
      w.leading == null &&
      w.description == null &&
      w.dividers &&
      !w.locked &&
      w.onHeaderTap == null;

  /// The built section widgets in the page order (owner 2026-10-12): groups
  /// WITHOUT a heading first, right under the hero; then the headed sections
  /// (each with its description). The order the page lists them in is kept
  /// within each kind. Each is told whether it is first.
  List<Widget> buildSections() {
    // Pass 1: build + classify (the `first` flag doesn't change what a section is).
    final built = <(int, Widget)>[
      for (final (i, build) in sections.indexed)
        if (build(false) case final s?) (i, s),
    ];
    final merged = <Widget>[
      for (final (_, s) in built)
        if (_mergeable(s)) ...(s as SectionCard).children,
    ];
    final out = <Widget>[];
    // ALL the heading-less rows (basic rows, description, note) are ONE box
    // right after the hero — like the contact page.
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
        PpForgeSpacing.lg,
        topInset,
        PpForgeSpacing.lg,
        bottomInset,
      ),
      children: [
        if (hero != null) ...[hero!, const SizedBox(height: HeroSpacing.after)],
        if (tabBar != null) ...[
          tabBar!,
          const SizedBox(height: PpForgeSpacing.md),
        ],
        if (tags != null) ...[tags!, const SizedBox(height: PpForgeSpacing.md)],
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
