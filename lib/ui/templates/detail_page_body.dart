import 'package:flutter/material.dart';

import '../molecules/detail_meta.dart';
import '../molecules/hero_shell.dart';
import '../tokens/app_spacing.dart';

/// The DetailPage template's body (owner 2026-10-12): every entity's detail
/// page is the same skeleton —
///
///   hero (tinted, watermark, top row · ✏️) → sections → การจัดการ (edit only)
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
    required this.hero,
    required this.sections,
    this.manage,
    this.metaLines = const [],
    this.bottomInset = AppSpacing.xxl,
    this.topInset = 0,
    this.controller,
    this.physics,
    super.key,
  });

  final Widget hero;
  final List<Widget? Function(bool first)> sections;
  final Widget? manage;
  final List<String> metaLines;
  final double bottomInset;

  /// Space above the hero (a transparent top bar floats over the list).
  final double topInset;
  final ScrollController? controller;
  final ScrollPhysics? physics;

  /// The built section widgets, in order, each told whether it is first.
  List<Widget> buildSections() {
    final out = <Widget>[];
    for (final build in sections) {
      final s = build(out.isEmpty);
      if (s != null) out.add(s);
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      physics: physics,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topInset,
        AppSpacing.lg,
        bottomInset,
      ),
      children: [
        hero,
        const SizedBox(height: HeroSpacing.after),
        ...buildSections(),
        ?manage,
        DetailMeta(lines: metaLines),
      ],
    );
  }
}
