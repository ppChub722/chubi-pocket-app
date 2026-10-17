import 'package:flutter/material.dart';

import '../molecules/detail_meta.dart';
import '../molecules/hero_shell.dart';
import '../organisms/pull_to_refresh.dart';
import '../tokens/app_spacing.dart';
import 'edit_mode_scope.dart';

/// The 0.4.0 detail template (owner 2026-10-17, reference §0): the section
/// ORDER is fixed by the kind of data, so a page only fills slots:
///
///   hero → [tags] → [actions] → [info] → [settings] → [people] → [note]
///   → [records] → [endZone] → meta
///
/// - [tags]: the tag row (`TagRow`) — in view AND edit, same place.
/// - [actions]: frequent "create something for this" buttons.
/// - [info]: ONE headless box of facts (`InfoBox`).
/// - [settings]: the headed **การตั้งค่า** section (`SettingsSection`).
/// - [people]: members / account link (`PeopleStrip`, a headed section).
/// - [note]: `NoteSection` — always its own box, the last piece of content,
///   right above the records (never below a list).
/// - [records]: child records (a headed list, or the swipe tabs' pager).
/// - [endZone]: `EndZone`, edit mode only (after the note).
/// - [metaLines]: `detailMetaLines(...)`.
///
/// Edit mode keeps this order: the page just stops passing the computed /
/// people / records slots and passes [endZone]. A page with an overview tab
/// puts [DetailSections] (the same slots, without the hero and meta) inside
/// the tab, with the note as the tab's last section.
///
/// The page keeps its own Scaffold, top bar, edit-mode mixin and save bar.
/// Pull-to-refresh follows `DetailPageBody` (off while editing / saving).
class DetailLayout extends StatelessWidget {
  const DetailLayout({
    required this.hero,
    this.tags,
    this.actions,
    this.info,
    this.settings,
    this.people,
    this.note,
    this.records,
    this.endZone,
    this.metaLines = const [],
    this.topInset = 0,
    this.bottomInset = AppSpacing.xxl,
    this.controller,
    this.physics,
    this.onRefresh,
    this.refreshEnabled = true,
    super.key,
  });

  final Widget hero;
  final Widget? tags;
  final Widget? actions;
  final Widget? info;
  final Widget? settings;
  final Widget? people;
  final Widget? note;
  final Widget? records;
  final Widget? endZone;
  final List<String> metaLines;

  /// Space above the hero (a transparent top bar floats over the list).
  final double topInset;
  final double bottomInset;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final Future<void> Function()? onRefresh;
  final bool refreshEnabled;

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
        hero,
        DetailSections(
          tags: tags,
          actions: actions,
          info: info,
          settings: settings,
          people: people,
          note: note,
          records: records,
          endZone: endZone,
        ),
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

/// The detail slots in their fixed order, spaced [HeroSpacing.after] apart —
/// everything [DetailLayout] shows between the hero and the meta. Use it
/// directly inside a tab (the overview tab: info, settings, chart, people,
/// note). Null slots are skipped; each slot is preceded by the one gap (also
/// above the first, i.e. the gap under the hero).
///
/// [chart] (a `ChartSection`) sits right after the settings — a view-only
/// overview slot; edit mode (`DetailLayout`) hides computed data.
class DetailSections extends StatelessWidget {
  const DetailSections({
    this.tags,
    this.actions,
    this.info,
    this.settings,
    this.chart,
    this.people,
    this.note,
    this.records,
    this.endZone,
    super.key,
  });

  final Widget? tags;
  final Widget? actions;
  final Widget? info;
  final Widget? settings;
  final Widget? chart;
  final Widget? people;
  final Widget? note;
  final Widget? records;
  final Widget? endZone;

  @override
  Widget build(BuildContext context) {
    final slots = <Widget>[
      ?tags,
      ?actions,
      ?info,
      ?settings,
      ?chart,
      ?people,
      ?note,
      ?records,
      ?endZone,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final s in slots) ...[
          const SizedBox(height: HeroSpacing.after),
          s,
        ],
      ],
    );
  }
}

/// The `records` slot's content when it is more than one piece (a filter row,
/// chips, grouped record boxes, an add tile): the pieces in a column, one
/// [gap] apart. Null entries are skipped.
class DetailRecords extends StatelessWidget {
  const DetailRecords({required this.children, this.gap = 12, super.key});

  final List<Widget?> children;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final shown = [for (final c in children) ?c];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final (i, c) in shown.indexed) ...[
          if (i > 0) SizedBox(height: gap),
          c,
        ],
      ],
    );
  }
}
