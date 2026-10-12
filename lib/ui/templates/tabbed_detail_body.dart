import 'package:flutter/material.dart';

import '../atoms/locked_in_edit.dart';
import '../molecules/app_tab_bar.dart';
import '../molecules/compact_hero_bar.dart';
import '../molecules/hero_shell.dart';
import '../molecules/pinned_tab_bar.dart';
import '../tokens/app_durations.dart';
import '../tokens/app_spacing.dart';

/// The Tabbed detail template (owner 2026-10-12; debts person page, events,
/// wallets): a detail page whose content splits into tabs —
///
///   [hero]                        ← scrolls away
///   [belowHero…]                  ← e.g. the page's one primary button,
///                                   a DetailRow section, a lock message
///   [tab · tab · tab]             ← pins under the top bar
///   the selected tab's body       ← each tab scrolls on its own
///
/// Once the hero has scrolled away the [compactBar] floats under the tab bar
/// (tap = back to the hero). Each tab body is built lazily the first time it
/// is shown and kept alive after; it is normally a `ListPageBody` (its
/// first-load skeleton, error + retry, empty, paging, pull-to-refresh,
/// toolbar header, hairlines) — the template already clears the top bar, so
/// the tab's list must not (it gets no top inset here).
///
/// The page owns the tab state ([selected] / [onChanged]) and the Scaffold /
/// top bar (`extendBodyBehindAppBar`). [editing] (edit mode): the tab bar
/// goes, the tabs lock, and edit-mode content goes in [belowHero].
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
    super.key,
  });

  /// The hero card (a `HeaderCard`).
  final Widget hero;

  /// Under the hero, in order, [AppSpacing.md] apart.
  final List<Widget> belowHero;
  final List<AppTab<T>> tabs;
  final T selected;
  final ValueChanged<T> onChanged;

  /// One tab's body — built the first time that tab shows.
  final Widget Function(BuildContext context, T tab) tabBuilder;

  /// The small version of the hero once it has scrolled away (null = none).
  final CompactHeroBar? compactBar;
  final bool editing;

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
          const SliverToBoxAdapter(child: SizedBox(height: HeroSpacing.after)),
          SliverPersistentHeader(
            pinned: true,
            delegate: PinnedTabBarDelegate(
              background: Theme.of(context).colorScheme.surface,
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
        // The tab lists start under the pinned bar: no top-bar clearance of
        // their own.
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: AppTabPager<T>(
            controller: _pages,
            values: _values,
            selected: w.selected,
            onChanged: w.onChanged,
            enabled: !w.editing,
            builder: w.tabBuilder,
          ),
        ),
      ),
    );
    final bar = w.compactBar;
    return Padding(
      // The body sits under the floating top bar.
      padding: EdgeInsets.only(top: top),
      child: MediaQuery.removePadding(
        context: context,
        removeTop: true,
        child: bar == null
            ? scroll
            : CompactHeroScope(
                heroKey: _heroKey,
                top: w.editing ? 0 : PinnedTabBarDelegate.height,
                bar: CompactHeroBar(
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
