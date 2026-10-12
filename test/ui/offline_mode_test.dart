import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Offline mode in the kit (owner 2026-10-12): a page with no data errors at
/// once; saves disable but typed text stays; coming back reloads the page; the
/// banner has an offline / reconnecting / back state.
void main() {
  Widget host(Widget child, {bool offline = false, int reconnects = 0}) =>
      MaterialApp(
        theme: ThemeData(
          extensions: [
            ThemeRegistry.byId(
              ThemeRegistry.defaultThemeId,
            ).colorsFor(Brightness.light),
          ],
        ),
        home: ConnectionScope(
          offline: offline,
          reconnects: reconnects,
          child: Scaffold(body: child),
        ),
      );

  testWidgets('no data + offline: error + retry at once, no skeleton', (
    t,
  ) async {
    await t.pumpWidget(
      host(
        AsyncStateView(
          loading: true,
          error: null,
          isEmpty: true,
          onRetry: () {},
          empty: const Text('empty'),
          builder: (_) => const Text('content'),
        ),
        offline: true,
      ),
    );
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.byType(ListPageSkeleton), findsNothing);
  });

  testWidgets('data on screen + offline: the page stays as it is', (t) async {
    await t.pumpWidget(
      host(
        AsyncStateView(
          loading: true,
          error: null,
          isEmpty: false,
          onRetry: () {},
          builder: (_) => const Text('content'),
        ),
        offline: true,
      ),
    );
    expect(find.text('content'), findsOneWidget);
    expect(find.byType(ErrorView), findsNothing);
  });

  testWidgets('offline: Save is disabled and the typed text stays', (t) async {
    final ctrl = TextEditingController(text: 'half-written note');
    Widget bar({required bool offline}) => host(
      Column(
        children: [
          TextField(controller: ctrl),
          ModeActionBar(
            canSave: true,
            saving: false,
            canUndo: false,
            cancelLabel: 'Cancel',
            saveLabel: 'Save',
            undoTooltip: 'Undo',
            onCancel: () {},
            onUndo: () {},
            onSave: () {},
          ),
        ],
      ),
      offline: offline,
    );
    await t.pumpWidget(bar(offline: false));
    expect(
      t.widget<AppButton>(find.widgetWithText(AppButton, 'Save')).onPressed,
      isNotNull,
    );
    await t.pumpWidget(bar(offline: true));
    expect(
      t.widget<AppButton>(find.widgetWithText(AppButton, 'Save')).onPressed,
      isNull,
    );
    expect(ctrl.text, 'half-written note');
    expect(find.text('half-written note'), findsOneWidget);
  });

  testWidgets('coming back online re-runs the page load (pull-to-refresh)', (
    t,
  ) async {
    var loads = 0;
    Widget page({required bool offline, required int reconnects}) => host(
      PullToRefresh(
        onRefresh: () async => loads++,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: const [Text('row')],
        ),
      ),
      offline: offline,
      reconnects: reconnects,
    );
    await t.pumpWidget(page(offline: true, reconnects: 0));
    expect(loads, 0);
    await t.pumpWidget(page(offline: false, reconnects: 1));
    await t.pump();
    await t.pump();
    expect(loads, 1);
    // Staying online does not reload again.
    await t.pumpWidget(page(offline: false, reconnects: 1));
    await t.pump();
    expect(loads, 1);
  });

  testWidgets('connection banner: offline has Retry; back is a success note', (
    t,
  ) async {
    var retried = 0;
    Widget banner(ConnectionBannerState s) => host(
      ConnectionBanner(
        state: s,
        offlineText: 'Offline',
        reconnectingText: 'Reconnecting',
        backText: 'Back',
        retryLabel: 'Retry',
        onRetry: () => retried++,
      ),
    );
    await t.pumpWidget(banner(ConnectionBannerState.offline));
    expect(find.text('Offline'), findsOneWidget);
    await t.tap(find.text('Retry'));
    expect(retried, 1);
    await t.pumpWidget(banner(ConnectionBannerState.reconnecting));
    expect(find.text('Reconnecting'), findsOneWidget);
    await t.pumpWidget(banner(ConnectionBannerState.backOnline));
    expect(find.text('Back'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });
}
