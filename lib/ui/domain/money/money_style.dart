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

/// The user's money style (owner 2026-10-17, settings → money): a [sign] and
/// whether amounts take the income / expense [colored] colours. "Colour
/// only" ([MoneySign.none]) is always coloured — with neither, nothing would
/// tell income from expense. Stored as the `money_style` preference; new
/// users get colour only, users from before it (no value) keep +/− in colour.
@immutable
class MoneyStyle {
  const MoneyStyle({this.sign = MoneySign.plusMinus, bool colored = true})
    : _colored = colored;

  /// What users from before the setting always saw.
  static const legacy = MoneyStyle();

  /// What new users get.
  static const colorOnly = MoneyStyle(sign: MoneySign.none);

  final MoneySign sign;
  final bool _colored;

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

  MoneyStyle copyWith({MoneySign? sign, bool? colored}) =>
      MoneyStyle(sign: sign ?? this.sign, colored: colored ?? _colored);

  @override
  bool operator ==(Object other) =>
      other is MoneyStyle && other.sign == sign && other.colored == colored;

  @override
  int get hashCode => Object.hash(sign, colored);
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
