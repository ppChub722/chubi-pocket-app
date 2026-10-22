import 'dart:async';

import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// LiveSetting: a view-mode setting that saves itself, optimistic, one call.
void main() {
  final colors = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);

  late bool saved; // the "server" value the page shows
  late List<bool> calls;
  late Completer<bool> answer;

  // The completer is made inside the test (the fake-async zone); one made in
  // setUp completes in the real zone and pump never sees it.
  Future<void> pump(WidgetTester t) {
    saved = false;
    calls = [];
    answer = Completer<bool>();
    return t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => LiveSetting<bool>(
              value: saved,
              save: (v) async {
                calls.add(v);
                final ok = await answer.future;
                if (ok) setState(() => saved = v);
                return ok;
              },
              failedMessage: (e) => 'failed: $e',
              builder: (context, value, onChanged) => SettingToggleRow(
                label: 'Track balance',
                value: value,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool shown(WidgetTester t) =>
      t.widget<AppSwitch>(find.byType(AppSwitch)).value;

  testWidgets('a flip shows at once and makes ONE call', (t) async {
    await pump(t);
    await t.tap(find.byType(AppSwitch));
    await t.pump();
    expect(shown(t), isTrue); // before the answer
    expect(calls, [true]);
    // Taps while saving are ignored (still one call).
    await t.tap(find.byType(AppSwitch));
    await t.pump();
    expect(calls, [true]);
    answer.complete(true);
    await t.pumpAndSettle();
    expect(shown(t), isTrue);
    expect(saved, isTrue);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('a failure puts the old value back and offers a retry', (
    t,
  ) async {
    await pump(t);
    await t.tap(find.byType(AppSwitch));
    await t.pump();
    expect(shown(t), isTrue);
    answer.completeError(StateError('offline'));
    await t.pumpAndSettle();
    expect(shown(t), isFalse);
    expect(find.textContaining('failed: Bad state: offline'), findsOneWidget);
    // Retry = the same change again, one more call.
    answer = Completer<bool>();
    await t.tap(find.text('Retry'));
    await t.pump();
    expect(calls, [true, true]);
    expect(shown(t), isTrue);
    answer.complete(true);
    await t.pumpAndSettle();
    expect(saved, isTrue);
  });

  testWidgets('save → false (backed out) puts it back quietly', (t) async {
    await pump(t);
    await t.tap(find.byType(AppSwitch));
    await t.pump();
    answer.complete(false);
    await t.pumpAndSettle();
    expect(shown(t), isFalse);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('no save = read-only row', (t) async {
    await t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: LiveSetting<bool>(
            value: true,
            save: null,
            failedMessage: (_) => '',
            builder: (context, value, onChanged) => SettingToggleRow(
              label: 'Track balance',
              value: value,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    );
    expect(t.widget<AppSwitch>(find.byType(AppSwitch)).onChanged, isNull);
  });
}
