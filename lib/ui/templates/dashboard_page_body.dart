import 'package:flutter/material.dart';

import '../molecules/app_message.dart';
import '../organisms/async_state_view.dart';
import '../organisms/page_skeletons.dart';
import '../organisms/pull_to_refresh.dart';
import '../tokens/app_durations.dart';
import '../tokens/app_spacing.dart';
import '../tokens/tone.dart';

/// The Dashboard template's body (owner 2026-10-12): a home overview is ONE
/// skeleton —
///
///   [banner: a stale-data warning]
///   [snapshot — "right now" blocks: a headline KPI card, the attention block]
///   [period — the month stepper]
///   [kpis — the period's summary stats]
///   [charts — donut / paired bars / trend cards]
///   [tiles — a grid of module tiles]
///   [lists — "coming up" / recent lists, each under a SectionHeader "see all"]
///
/// The page keeps its own Scaffold / top bar; this widget is the content, so
/// the first-load skeleton, the full-page error + retry, pull-to-refresh and
/// the dim-while-reloading behave identically on every dashboard.
///
/// - **Two zones:** [snapshot] does NOT follow the period (a net worth, what
///   is waiting on the user); [period] heads the period-scoped zone below it
///   ([kpis] · [charts] · [tiles] · [lists]). Both zones dim while
///   [refreshing] (a new period loading) — the period bar never does.
/// - **Slots are plain widgets / lists:** pass `[]` / null to leave one out;
///   the template only spaces them ([AppSpacing.md] under the snapshot,
///   [AppSpacing.sm] under the period bar, [AppSpacing.lg] before the tiles).
/// - **Data state:** [loading] / [error] / [isEmpty] / [onRetry] as
///   `AsyncStateView`; [banner] shows above the content (a failed refresh
///   with data still on screen); [skeleton] overrides the default blocks.
class DashboardPageBody extends StatelessWidget {
  const DashboardPageBody({
    required this.loading,
    required this.error,
    required this.isEmpty,
    required this.onRetry,
    this.refreshing = false,
    this.banner,
    this.snapshot = const [],
    this.period,
    this.kpis = const [],
    this.charts = const [],
    this.tiles,
    this.lists = const [],
    this.skeleton,
    this.topInset = AppSpacing.xs,
    this.bottomInset = 96,
    this.sidePadding = AppSpacing.lg,
    super.key,
  });

  final bool loading;
  final Object? error;
  final bool isEmpty;
  final Future<void> Function() onRetry;

  /// Data is on screen but a new period / refresh is loading: both zones dim.
  final bool refreshing;

  /// Above everything (an `AppMessage` banner "couldn't refresh").
  final String? banner;

  /// "Right now" blocks, in order — a net-worth KPI card, the attention block.
  final List<Widget> snapshot;

  /// The period stepper that heads the period-scoped zone.
  final Widget? period;

  /// The period's summary stats / KPI cards.
  final List<Widget> kpis;

  /// Chart cards (donut, paired bars, trend).
  final List<Widget> charts;

  /// A tiles grid (module tiles).
  final Widget? tiles;

  /// Lists under their own `SectionHeader` ("coming up", recent).
  final List<Widget> lists;

  final Widget? skeleton;
  final double topInset;
  final double bottomInset;
  final double sidePadding;

  static Widget _dim(bool dim, Widget child) => AnimatedOpacity(
    duration: AppDurations.fast,
    opacity: dim ? 0.5 : 1,
    child: child,
  );

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.paddingOf(context);
    return AsyncStateView(
      loading: loading,
      error: error,
      isEmpty: isEmpty,
      onRetry: onRetry,
      // Stale data + a failed load → the banner, not a snackbar.
      snackOnRefreshError: false,
      skeleton:
          skeleton ??
          DashboardPageSkeleton(
            padding: EdgeInsets.fromLTRB(
              sidePadding,
              mq.top + topInset,
              sidePadding,
              bottomInset + mq.bottom,
            ),
          ),
      builder: (context) => PullToRefresh(
        onRefresh: onRetry,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          // Body sits under the transparent top bar.
          padding: EdgeInsets.fromLTRB(
            sidePadding,
            mq.top + topInset,
            sidePadding,
            bottomInset + mq.bottom,
          ),
          children: [
            if (banner != null) ...[
              AppMessage(message: banner!, tone: Tone.danger),
              const SizedBox(height: AppSpacing.md),
            ],
            _dim(
              refreshing,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: snapshot,
              ),
            ),
            if (period != null) ...[
              const SizedBox(height: AppSpacing.md),
              // Never dims: the period is what is loading.
              period!,
              const SizedBox(height: AppSpacing.sm),
            ],
            _dim(
              refreshing,
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...kpis,
                  ...charts,
                  if (tiles != null) ...[
                    const SizedBox(height: AppSpacing.lg),
                    tiles!,
                  ],
                  ...lists,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
