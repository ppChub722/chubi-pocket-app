import 'package:flutter/material.dart';

import '../molecules/app_message.dart';
import '../organisms/async_state_view.dart';
import '../organisms/page_skeletons.dart';
import '../organisms/pull_to_refresh.dart';
import '../tokens/app_durations.dart';
import '../tokens/app_spacing.dart';
import '../tokens/tone.dart';

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
    this.skeletonShape = const DashboardSkeletonShape(),
    this.topInset = AppSpacing.xs,
    this.bottomInset = 96,
    this.sidePadding = AppSpacing.lg,
    super.key,
  });

  final bool loading;
  final Object? error;
  final bool isEmpty;
  final Future<void> Function() onRetry;

  final bool refreshing;

  final String? banner;

  final List<Widget> snapshot;

  final Widget? period;

  final List<Widget> kpis;

  final List<Widget> charts;

  final Widget? tiles;

  final List<Widget> lists;

  final DashboardSkeletonShape skeletonShape;
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
      skeleton: DashboardPageSkeleton(
        shape: skeletonShape,
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
