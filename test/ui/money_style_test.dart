import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The user's money style (owner 2026-10-17): + / −, ( ) or colour only,
/// coloured or not. No scope (users from before it) = + / − in colour.
void main() {
  final colors = ThemeRegistry.byId(
    ThemeRegistry.defaultThemeId,
  ).colorsFor(Brightness.light);

  Future<void> pump(WidgetTester t, MoneyStyle? style, MoneyTone tone) {
    const money = MoneyText(540, tone: MoneyTone.plain);
    final text = MoneyText(540, tone: tone, symbol: '฿');
    return t.pumpWidget(
      MaterialApp(
        theme: ThemeData(extensions: [colors]),
        home: Scaffold(
          body: style == null
              ? Column(children: [text, money])
              : MoneyStyleScope(style: style, child: text),
        ),
      ),
    );
  }

  Text shown(WidgetTester t) => t.widget<Text>(find.byType(Text).first);

  test('the preference round-trips; unknown / null = legacy', () {
    for (final v in [
      'plus_minus',
      'plus_minus_plain',
      'parentheses',
      'parentheses_plain',
      'color_only',
    ]) {
      expect(MoneyStyle.fromPreference(v).preference, v);
    }
    expect(MoneyStyle.fromPreference(null), MoneyStyle.legacy);
    expect(MoneyStyle.fromPreference('rainbow'), MoneyStyle.legacy);
  });

  test('colour only is always coloured', () {
    expect(MoneyStyle.colorOnly.copyWith(colored: false).colored, isTrue);
  });

  testWidgets('no scope: + / − in colour (users from before it)', (t) async {
    await pump(t, null, MoneyTone.expense);
    expect(shown(t).data, '−฿540.00');
    expect(shown(t).style?.color, colors.expense);
  });

  testWidgets('parentheses, coloured: (฿540) in red; income has no mark', (
    t,
  ) async {
    const s = MoneyStyle(sign: MoneySign.parentheses);
    await pump(t, s, MoneyTone.expense);
    expect(shown(t).data, '(฿540.00)');
    expect(shown(t).style?.color, colors.expense);
    await pump(t, s, MoneyTone.income);
    expect(shown(t).data, '฿540.00');
    expect(shown(t).style?.color, colors.income);
  });

  testWidgets('+ / − without colour: the sign alone', (t) async {
    await pump(t, const MoneyStyle(colored: false), MoneyTone.income);
    expect(shown(t).data, '+฿540.00');
    expect(shown(t).style?.color, isNot(colors.income));
  });

  testWidgets('colour only: no mark, the colour says it', (t) async {
    await pump(t, MoneyStyle.colorOnly, MoneyTone.expense);
    expect(shown(t).data, '฿540.00');
    expect(shown(t).style?.color, colors.expense);
  });

  test('decimals: always / never (rounded) / auto (hide .00 only)', () {
    const always = MoneyStyle();
    const never = MoneyStyle(decimals: MoneyDecimals.never);
    const auto = MoneyStyle(decimals: MoneyDecimals.auto);
    expect(always.digitsFor(1000, 2), 2);
    expect(never.digitsFor(99.5, 2), 0);
    expect(auto.digitsFor(1000, 2), 0);
    expect(auto.digitsFor(99.5, 2), 2);
    expect(auto.digitsFor(1000.004, 2), 0); // shows as 1,000.00 → whole
    expect(formatMoneyWith(never, 99.5, symbol: '฿'), '฿100');
    expect(formatMoneyWith(auto, 99.5, symbol: '฿'), '฿99.50');
    expect(formatMoneyWith(auto, 1000, symbol: '฿'), '฿1,000');
  });

  test('a signed-in user with nothing set: + / − in colour, hide .00', () {
    final s = MoneyStyle.fromPreferences();
    expect(s.sign, MoneySign.plusMinus);
    expect(s.colored, isTrue);
    expect(s.decimals, MoneyDecimals.auto);
    expect(
      MoneyStyle.fromPreferences(decimals: 'never').decimals,
      MoneyDecimals.never,
    );
  });

  testWidgets('auto decimals in MoneyText: ฿540 (no .00)', (t) async {
    await pump(
      t,
      const MoneyStyle(decimals: MoneyDecimals.auto),
      MoneyTone.expense,
    );
    expect(shown(t).data, '−฿540');
  });
}
