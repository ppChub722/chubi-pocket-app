import 'package:flutter/material.dart';

enum MoneySign { plusMinus, parentheses, none }

enum MoneyDecimals {
  always,

  never,

  auto;

  static MoneyDecimals fromPreference(String? value) => switch (value) {
    'always' => always,
    'never' => never,
    _ => auto,
  };

  String get preference => name;
}

@immutable
class MoneyStyle {
  const MoneyStyle({
    this.sign = MoneySign.plusMinus,
    bool colored = true,
    this.decimals = MoneyDecimals.always,
  }) : _colored = colored;

  static const legacy = MoneyStyle();

  static const colorOnly = MoneyStyle(sign: MoneySign.none);

  final MoneySign sign;
  final bool _colored;

  final MoneyDecimals decimals;

  bool get colored => sign == MoneySign.none || _colored;

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

  factory MoneyStyle.fromPreferences({String? style, String? decimals}) =>
      MoneyStyle.fromPreference(
        style,
      ).copyWith(decimals: MoneyDecimals.fromPreference(decimals));

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

  String get preference => switch (sign) {
    MoneySign.plusMinus => colored ? 'plus_minus' : 'plus_minus_plain',
    MoneySign.parentheses => colored ? 'parentheses' : 'parentheses_plain',
    MoneySign.none => 'color_only',
  };

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

class MoneyStyleScope extends InheritedWidget {
  const MoneyStyleScope({required this.style, required super.child, super.key});

  final MoneyStyle style;

  static MoneyStyle of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<MoneyStyleScope>()?.style ??
      MoneyStyle.legacy;

  @override
  bool updateShouldNotify(MoneyStyleScope old) => style != old.style;
}
