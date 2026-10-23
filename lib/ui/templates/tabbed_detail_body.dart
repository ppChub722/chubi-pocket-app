import '../tokens/hero_metrics.dart';
import 'package:flutter/material.dart';

import '../atoms/locked_in_edit.dart';
import '../molecules/app_tab_bar.dart';
import '../molecules/app_compact_hero_card.dart';
import '../molecules/pinned_tab_bar.dart';
import '../tokens/app_durations.dart';
import '../tokens/app_spacing.dart';

class TabbedDetailBody<T> extends StatefulWidget {
  const TabbedDetailBody({
    required this.hero,
    required this.tabs,
    required this.selected,
    required this.onChanged,
    required this.tabBuilder,
    this.belowHero = const [],
    this.compactBar,
    this.editing = false,
    this.showPageDots = true,
    super.key,
  });

  final Widget hero;

  final List<Widget> belowHero;
  final List<AppTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  final Widget Function(BuildContext context, T tab) tabBuilder;

  final AppCompactHeroCard? compactBar;
  final bool editing;

  final bool showPageDots;

  @override
  State<TabbedDetailBody<T>> createState() => _TabbedDetailBodyState<T>();
}

class _TabbedDetailBodyState<T> extends State<TabbedDetailBody<T>> {
  final _heroKey = GlobalKey();
  final _outer = ScrollController();
  late final PageController _pages = PageController(initialPage: _index);

  List<T> get _values => [for (final t in widget.tabs) t.value];
  int get _index => _values.indexOf(widget.selected).clamp(0, 1 << 20);

  @override
  void dispose() {
    _outer.dispose();
    _pages.dispose();
    super.dispose();
  }

  void _scrollToHero() {
    if (!_outer.hasClients) return;
    _outer.animateTo(
      0,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : AppDurations.chrome,
      curve: AppDurations.chromeCurve,
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final top = MediaQuery.paddingOf(context).top;
    final scroll = NestedScrollView(
      controller: _outer,
      headerSliverBuilder: (context, _) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              0,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                KeyedSubtree(key: _heroKey, child: w.hero),
                for (final b in w.belowHero) ...[
                  const SizedBox(height: AppSpacing.md),
                  b,
                ],
              ],
            ),
          ),
        ),
        if (!w.editing) ...[
          SliverToBoxAdapter(
            child: SizedBox(height: HeroMetrics.of(context).after),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: PinnedTabBarDelegate(
              child: AppTabBar<T>(
                tabs: w.tabs,
                selected: w.selected,
                onChanged: w.onChanged,
                pager: _pages,
              ),
            ),
          ),
        ],
      ],
      body: LockedInEdit(
        locked: w.editing,
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: AppTabPager<T>(
            controller: _pages,
            values: _values,
            selected: w.selected,
            onChanged: w.onChanged,
            enabled: !w.editing,
            showPageDots: w.showPageDots,
            builder: w.tabBuilder,
          ),
        ),
      ),
    );
    final bar = w.compactBar;
    return Padding(
      padding: EdgeInsets.only(top: top),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: bar == null
            ? scroll
            : CompactHeroScope(
                heroKey: _heroKey,
                top: w.editing ? 0 : PinnedTabBarDelegate.height,
                bar: AppCompactHeroCard(
                  key: bar.key,
                  style: bar.style,
                  leading: bar.leading,
                  title: bar.title,
                  trailing: bar.trailing,
                  onTap: bar.onTap ?? _scrollToHero,
                ),
                child: scroll,
              ),
      ),
    );
  }
}
