import 'dart:async';

import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Page loads fail fast and safely, in the template (owner 2026-10-12): any
/// failure → error + retry (not an endless skeleton); a first load that never
/// answers offers retry after `slowAfter`; with data on screen a reload keeps it.
void main() {
  Widget host(Widget child) => MaterialApp(home: Scaffold(body: child));

  Widget view({
    required bool loading,
    Object? error,
    bool isEmpty = true,
    Duration? slowAfter = const Duration(seconds: 8),
    VoidCallback? onRetry,
  }) => AsyncStateView(
    loading: loading,
    error: error,
    isEmpty: isEmpty,
    onRetry: onRetry ?? () {},
    slowAfter: slowAfter,
    empty: const Text('empty'),
    builder: (_) => const Text('content'),
  );

  testWidgets('a NON-API failure (parse TypeError) → error view + retry', (
    t,
  ) async {
    await t.pumpWidget(host(view(loading: false, error: TypeError())));
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(ListPageSkeleton), findsNothing);
  });

  testWidgets('first load never answers → retry shown after slowAfter', (
    t,
  ) async {
    var retried = 0;
    await t.pumpWidget(host(view(loading: true, onRetry: () => retried++)));
    expect(find.byType(ErrorView), findsNothing);
    await t.pump(const Duration(seconds: 7));
    expect(find.byType(ErrorView), findsNothing);
    await t.pump(const Duration(seconds: 2));
    expect(find.byType(ErrorView), findsOneWidget);
    // The retry button re-runs the load and the timer starts again.
    await t.tap(find.text('Retry'));
    await t.pump();
    expect(retried, 1);
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('the load finishing before slowAfter never shows the retry', (
    t,
  ) async {
    await t.pumpWidget(host(view(loading: true)));
    await t.pump(const Duration(seconds: 3));
    await t.pumpWidget(host(view(loading: false, isEmpty: false)));
    await t.pump(const Duration(seconds: 20));
    expect(find.text('content'), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('data on screen: a reload keeps it (no skeleton, no retry)', (
    t,
  ) async {
    await t.pumpWidget(host(view(loading: true, isEmpty: false)));
    await t.pump(const Duration(seconds: 20));
    expect(find.text('content'), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('a slow load that then succeeds replaces the retry view', (
    t,
  ) async {
    await t.pumpWidget(host(view(loading: true)));
    await t.pump(const Duration(seconds: 9));
    expect(find.byType(ErrorView), findsOneWidget);
    await t.pumpWidget(host(view(loading: false, isEmpty: false)));
    await t.pump();
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('slowAfter: null never times out', (t) async {
    await t.pumpWidget(host(view(loading: true, slowAfter: null)));
    await t.pump(const Duration(minutes: 5));
    expect(find.byType(ErrorView), findsNothing);
    final timer = Timer(Duration.zero, () {});
    timer.cancel();
  });
}
