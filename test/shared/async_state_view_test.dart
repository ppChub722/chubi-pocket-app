import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/core/theme/themes/sweet_theme.dart';
import 'package:chubi_pocket/l10n/gen/app_localizations.dart';
import 'package:chubi_pocket/shared/widgets/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _server = ApiException(
  code: 'INTERNAL_ERROR',
  message: 'List failed',
  statusCode: 500,
);

Widget _view({
  bool loading = false,
  ApiException? error,
  bool isEmpty = true,
  VoidCallback? onRetry,
}) => MaterialApp(
  // Snackbar tones read the AppColors extension.
  theme: ThemeData(extensions: [sweetTheme.lightColors]),
  locale: const Locale('en'),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(
    body: AsyncStateView(
      loading: loading,
      error: error,
      isEmpty: isEmpty,
      onRetry: onRetry ?? () {},
      skeleton: const Text('skeleton'),
      empty: const Text('empty'),
      builder: (_) => const Text('content'),
    ),
  ),
);

void main() {
  testWidgets('nothing yet + loading → skeleton', (t) async {
    await t.pumpWidget(_view(loading: true));
    expect(find.text('skeleton'), findsOneWidget);
  });

  testWidgets('nothing + error → ErrorView with retry, not empty', (t) async {
    var retried = 0;
    await t.pumpWidget(_view(error: _server, onRetry: () => retried++));
    expect(find.byType(ErrorView), findsOneWidget);
    expect(find.text('empty'), findsNothing);
    await t.tap(find.text('Retry'));
    expect(retried, 1);
  });

  testWidgets('nothing + loaded → the page\'s empty view', (t) async {
    await t.pumpWidget(_view());
    expect(find.text('empty'), findsOneWidget);
  });

  testWidgets('data wins over loading / error', (t) async {
    await t.pumpWidget(_view(loading: true, error: _server, isEmpty: false));
    expect(find.text('content'), findsOneWidget);
  });

  testWidgets('a failed refresh with data on screen → snackbar', (t) async {
    await t.pumpWidget(_view(isEmpty: false));
    await t.pumpWidget(_view(isEmpty: false, error: _server));
    await t.pump(); // post-frame callback
    await t.pump(const Duration(milliseconds: 300)); // snackbar animation
    expect(find.text('content'), findsOneWidget);
    expect(find.text('Something went wrong'), findsOneWidget);
  });

  testWidgets('fallback: not found only once loaded without error', (t) async {
    Widget fallback({bool loading = false, ApiException? error}) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: AsyncStateView.fallback(
          loading: loading,
          error: error,
          onRetry: () {},
          skeleton: const Text('skeleton'),
          notFound: const Text('not found'),
        ),
      ),
    );
    await t.pumpWidget(fallback(error: _server));
    expect(find.byType(ErrorView), findsOneWidget);
    await t.pumpWidget(fallback());
    expect(find.text('not found'), findsOneWidget);
  });
}
