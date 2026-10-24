import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

/// The user's money style (owner 2026-10-17): + / −, ( ) or colour only,
/// coloured or not. No scope (users from before it) = + / − in colour.
void main() {
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

  test('apply: the mark per sign style; colour only is always coloured', () {
    const parens = MoneyStyle(sign: MoneySign.parentheses);
    for (final c in [
      (
        name: 'plus / minus, expense',
        style: MoneyStyle.legacy,
        negative: true,
        want: '−฿540.00',
        colored: true,
      ),
      (
        name: 'plus / minus, income',
        style: MoneyStyle.legacy,
        negative: false,
        want: '+฿540.00',
        colored: true,
      ),
      (
        name: 'plus / minus without colour',
        style: const MoneyStyle(colored: false),
        negative: false,
        want: '+฿540.00',
        colored: false,
      ),
      (
        name: 'parentheses, expense',
        style: parens,
        negative: true,
        want: '(฿540.00)',
        colored: true,
      ),
      (
        name: 'parentheses, income has no mark',
        style: parens,
        negative: false,
        want: '฿540.00',
        colored: true,
      ),
      (
        name: 'colour only, expense',
        style: MoneyStyle.colorOnly,
        negative: true,
        want: '฿540.00',
        colored: true,
      ),
      (
        name: 'colour only cannot be turned plain',
        style: MoneyStyle.colorOnly.copyWith(colored: false),
        negative: false,
        want: '฿540.00',
        colored: true,
      ),
    ]) {
      expect(
        c.style.apply('฿540.00', negative: c.negative),
        c.want,
        reason: c.name,
      );
      expect(c.style.colored, c.colored, reason: c.name);
    }
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
}
