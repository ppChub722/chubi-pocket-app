import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'row_geometry_harness.dart';

/// [BusyScope] (owner 2026-10-28 loading rule): below a locked scope every
/// interactive kit piece is faded and inert, inputs read-only with their text
/// kept; a piece with its own `loading` spins instead (not faded); pieces
/// outside the scope are untouched; nothing fades twice.
void main() {
  Future<void> pump(WidgetTester t, Widget child) async {
    await t.pumpWidget(
      MaterialApp(
        theme: geometryTheme(),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [child],
            ),
          ),
        ),
      ),
    );
    await t.pump(const Duration(milliseconds: 300));
  }

  /// Every opacity between [f] and the root, multiplied.
  double fade(WidgetTester t, Finder f) {
    RenderObject? o = t.renderObject(f);
    var a = 1.0;
    while (o != null) {
      if (o is RenderOpacity) a *= o.opacity;
      if (o is RenderAnimatedOpacity) a *= o.opacity.value;
      o = o.parent;
    }
    return a;
  }

  testWidgets('locked: controls fade + ignore taps, outside stays usable', (
    t,
  ) async {
    var inside = 0, chip = 0, row = 0, outside = 0;
    bool? flipped;
    await pump(
      t,
      Column(
        children: [
          BusyScope(
            busy: true,
            child: Column(
              children: [
                AppButton(label: 'Inside', onPressed: () => inside++),
                AppChip(label: 'Chip', onTap: () => chip++),
                AppSwitch(value: false, onChanged: (v) => flipped = v),
                AppDetailRow(label: 'Row', onTap: () => row++),
              ],
            ),
          ),
          AppButton(label: 'Outside', onPressed: () => outside++),
        ],
      ),
    );
    for (final label in ['Inside', 'Chip', 'Row']) {
      expect(fade(t, find.text(label)), AppOpacity.disabled, reason: label);
      await t.tap(find.text(label), warnIfMissed: false);
    }
    await t.tap(find.byType(Switch), warnIfMissed: false);
    await t.tap(find.text('Outside'));
    await t.pump();
    expect((inside, chip, row, flipped), (0, 0, 0, null));
    expect(outside, 1);
    expect(fade(t, find.text('Outside')), 1);
    expect(find.byType(AppSpinner), findsNothing);
  });

  testWidgets('explicit loading spins inside a locked scope, not faded', (
    t,
  ) async {
    var saved = 0;
    await pump(
      t,
      BusyScope(
        busy: true,
        child: AppButton(
          label: 'Save',
          loading: true,
          onPressed: () => saved++,
        ),
      ),
    );
    final spinner = find.byType(AppSpinner);
    expect(spinner, findsOneWidget);
    expect(fade(t, spinner), 1);
    await t.tap(find.byType(AppButton), warnIfMissed: false);
    expect(saved, 0);
  });

  testWidgets('a disabled piece keeps its own look (no extra fade)', (t) async {
    await pump(
      t,
      const BusyScope(
        busy: true,
        child: AppButton(label: 'Off', onPressed: null),
      ),
    );
    expect(fade(t, find.text('Off')), 1);
  });

  testWidgets('never fades twice: a switch in a tappable row', (t) async {
    await pump(
      t,
      BusyScope(
        busy: true,
        child: AppDetailRow(
          label: 'Row',
          onTap: () {},
          trailing: AppSwitch(value: true, onChanged: (_) {}),
        ),
      ),
    );
    expect(fade(t, find.byType(Switch)), AppOpacity.disabled);
  });

  testWidgets('inputs: read-only + faded, text and state kept', (t) async {
    final c = TextEditingController();
    addTearDown(c.dispose);
    Widget form(bool busy) => BusyScope(
      busy: busy,
      child: AppInput(label: 'Name', controller: c),
    );
    await pump(t, form(false));
    await t.enterText(find.byType(TextField), 'Mint');
    final state = t.state(find.byType(EditableText));
    await pump(t, form(true));
    expect(t.widget<TextField>(find.byType(TextField)).readOnly, isTrue);
    expect(fade(t, find.text('Mint')), AppOpacity.disabled);
    expect(find.byType(AppSpinner), findsNothing);
    await pump(t, form(false));
    expect(t.widget<TextField>(find.byType(TextField)).readOnly, isFalse);
    expect(fade(t, find.text('Mint')), 1);
    expect(c.text, 'Mint');
    expect(
      t.state(find.byType(EditableText)),
      same(state),
      reason: 'the lock must not rebuild the field (focus, cursor kept)',
    );
  });

  testWidgets('busy: false inherits; BusyScope.free resets', (t) async {
    var free = 0;
    await pump(
      t,
      BusyScope(
        busy: true,
        child: Column(
          children: [
            const BusyScope(
              busy: false,
              child: AppButton(label: 'Inherits', onPressed: _noop),
            ),
            BusyScope.free(
              child: AppButton(label: 'Free', onPressed: () => free++),
            ),
          ],
        ),
      ),
    );
    expect(fade(t, find.text('Inherits')), AppOpacity.disabled);
    expect(fade(t, find.text('Free')), 1);
    await t.tap(find.text('Free'));
    expect(free, 1);
  });

  testWidgets('active: the control spins, its row ignores taps', (t) async {
    var row = 0;
    await pump(
      t,
      BusyScope.active(
        child: Column(
          children: [
            SettingToggleRow(
              label: 'Live',
              value: true,
              submits: false,
              onChanged: (_) => row++,
            ),
            SettingPickRow(label: 'Pick', submits: false, onTap: () => row++),
          ],
        ),
      ),
    );
    // The switch and the pick row's › spin; neither row is faded.
    expect(find.byType(AppSpinner), findsNWidgets(2));
    expect(fade(t, find.text('Live')), 1);
    await t.tap(find.text('Live'), warnIfMissed: false);
    await t.tap(find.text('Pick'), warnIfMissed: false);
    expect(row, 0);
  });

  testWidgets('LiveSetting spins its row while the save runs', (t) async {
    var value = false;
    await pump(
      t,
      StatefulBuilder(
        builder: (context, setState) => LiveSetting<bool>(
          value: value,
          save: (v) async {
            await Future<void>.delayed(const Duration(seconds: 1));
            setState(() => value = v);
            return true;
          },
          failedMessage: (e) => '$e',
          builder: (context, v, onChanged) => SettingToggleRow(
            label: 'Track',
            value: v,
            submits: false,
            onChanged: onChanged,
          ),
        ),
      ),
    );
    expect(find.byType(AppSpinner), findsNothing);
    await t.tap(find.text('Track'));
    await t.pump();
    expect(find.byType(AppSpinner), findsOneWidget);
    await t.pump(const Duration(seconds: 1));
    await t.pump();
    expect(find.byType(AppSpinner), findsNothing);
    expect(value, isTrue);
  });
}

void _noop() {}
