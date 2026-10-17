import 'package:flutter/material.dart';

import '../molecules/detail_meta.dart';
import '../molecules/hero_shell.dart';
import '../organisms/pull_to_refresh.dart';
import '../tokens/app_spacing.dart';
import 'edit_mode_scope.dart';

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
