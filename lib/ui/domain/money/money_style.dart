import 'package:flutter/material.dart';

/// How an income / expense amount marks its direction.
enum MoneySign {
  /// +฿1,000 / −฿540.
  plusMinus,

  /// ฿1,000 / (฿540) — the accounting way.
  parentheses,

  /// ฿1,000 / ฿540 — the colour alone says it.
  none,
}

/// The satang / cents of an amount (owner 2026-10-17).
enum MoneyDecimals {
  /// ฿1,000.00 · ฿99.50.
  always,

  /// Rounded to whole units: ฿1,000 · ฿99.50 → ฿100.
  never,

  /// No .00: ฿1,000 · ฿99.50 stays (the default).
  auto;

  /// From the `money_decimals` preference (null / unknown = [auto]).
  static MoneyDecimals fromPreference(String? value) => switch (value) {
    'always' => always,
    'never' => never,
    _ => auto,
  };

  String get preference => name;
}

/// The user's money style (owner 2026-10-17, settings → money): a [sign] and
/// whether amounts take the income / expense [colored] colours. "Colour
/// only" ([MoneySign.none]) is always coloured — with neither, nothing would
/// tell income from expense. Stored as the `money_style` preference; new
/// users get colour only, users from before it (no value) keep +/− in colour.
@immutable
class MoneyStyle {
  const MoneyStyle({
    this.sign = MoneySign.plusMinus,
    bool colored = true,
    this.decimals = MoneyDecimals.always,
  }) : _colored = colored;

  /// What users from before the settings always saw (+ / − in colour, .00);
  /// also the style with no [MoneyStyleScope] (tests, the hub). A signed-in
  /// user's unset `money_decimals` is [MoneyDecimals.auto]
  /// ([MoneyStyle.fromPreferences]).
  static const legacy = MoneyStyle();

  /// What new users get.
  static const colorOnly = MoneyStyle(sign: MoneySign.none);

  final MoneySign sign;
  final bool _colored;

  /// How many satang / cents show ([digitsFor]).
  final MoneyDecimals decimals;

  bool get colored => sign == MoneySign.none || _colored;

  /// From the `money_style` preference (null / unknown = [legacy]).
  factory MoneyStyle.fromPreference(String? value) => switch (value) {
    'plus_minus_plain' => const MoneyStyle(colored: false),
    'parentheses' => const MoneyStyle(sign: MoneySign.parentheses),
    'parentheses_plain' => const MoneyStyle(
      sign: MoneySign.parentheses,
      colored: false,
    ),
    'color_only' => colorOnly,
    _ => legacy,
  };

  /// The style from both preferences (`money_style`, `money_decimals`).
  factory MoneyStyle.fromPreferences({String? style, String? decimals}) =>
      MoneyStyle.fromPreference(
        style,
      ).copyWith(decimals: MoneyDecimals.fromPreference(decimals));

  /// The decimal digits [amount] shows with, given the currency's own
  /// ([currencyDigits]: 2, or 0 for ¥): never → 0; auto → 0 when it is a
  /// whole amount at the currency's digits.
  int digitsFor(num amount, int currencyDigits) {
    switch (decimals) {
      case MoneyDecimals.always:
        return currencyDigits;
      case MoneyDecimals.never:
        return 0;
      case MoneyDecimals.auto:
        var scale = 1;
        for (var i = 0; i < currencyDigits; i++) {
          scale *= 10;
        }
        final units = (amount.abs() * scale).round();
        return units % scale == 0 ? 0 : currencyDigits;
    }
  }

  /// The `money_style` preference value.
  String get preference => switch (sign) {
    MoneySign.plusMinus => colored ? 'plus_minus' : 'plus_minus_plain',
    MoneySign.parentheses => colored ? 'parentheses' : 'parentheses_plain',
    MoneySign.none => 'color_only',
  };

  /// [text] (the formatted magnitude) marked for an income ([negative]
  /// false) or an expense.
  String apply(String text, {required bool negative}) => switch (sign) {
    MoneySign.plusMinus => negative ? '−$text' : '+$text',
    MoneySign.parentheses => negative ? '($text)' : text,
    MoneySign.none => text,
  };

  MoneyStyle copyWith({
    MoneySign? sign,
    bool? colored,
    MoneyDecimals? decimals,
  }) => MoneyStyle(
    sign: sign ?? this.sign,
    colored: colored ?? _colored,
    decimals: decimals ?? this.decimals,
  );

  @override
  bool operator ==(Object other) =>
      other is MoneyStyle &&
      other.sign == sign &&
      other.colored == colored &&
      other.decimals == decimals;

  @override
  int get hashCode => Object.hash(sign, colored, decimals);
}

/// Provides the user's [MoneyStyle] (AppUiConfig installs it from /me).
/// With none above (tests, the hub) amounts read as [MoneyStyle.legacy].
class MoneyStyleScope extends InheritedWidget {
  const MoneyStyleScope({required this.style, required super.child, super.key});

  final MoneyStyle style;

  static MoneyStyle of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MoneyStyleScope>()?.style ??
      MoneyStyle.legacy;

  @override
  bool updateShouldNotify(MoneyStyleScope old) => style != old.style;
}
