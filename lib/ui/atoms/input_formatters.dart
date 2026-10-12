import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Keeps a money field as `#,##0.##` while the user types: digits + one
/// dot, max 2 decimals, commas re-inserted on every edit, caret kept after
/// the same digit it was after.
///
/// [allowNegative] keeps one leading `-` (balances can go below zero —
/// an overdraft, an overpaid card); the sign itself is toggled by
/// [AmountInput]'s ± chip rather than typed, since the decimal keypad has
/// no minus on most phones.
class ThousandsInputFormatter extends TextInputFormatter {
  ThousandsInputFormatter({this.allowNegative = false});

  final bool allowNegative;

  static final _grouping = NumberFormat('#,##0', 'en_US');

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final negative = allowNegative && newValue.text.startsWith('-');
    if (negative) {
      // Format the magnitude, then put the sign back (caret shifted by 1).
      final inner = _format(
        oldValue.text.startsWith('-')
            ? oldValue.copyWith(text: oldValue.text.substring(1))
            : oldValue,
        TextEditingValue(
          text: newValue.text.substring(1),
          selection: TextSelection.collapsed(
            offset: (newValue.selection.baseOffset - 1).clamp(
              0,
              newValue.text.length - 1,
            ),
          ),
        ),
      );
      return TextEditingValue(
        text: '-${inner.text}',
        selection: TextSelection.collapsed(
          offset: inner.selection.baseOffset + 1,
        ),
      );
    }
    return _format(oldValue, newValue);
  }

  TextEditingValue _format(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final raw = newValue.text.replaceAll(',', '');
    if (raw.isEmpty) return newValue.copyWith(text: '');
    // Digits with at most one dot and two decimals; otherwise reject.
    if (!RegExp(r'^\d*\.?\d{0,2}$').hasMatch(raw)) return oldValue;

    final dot = raw.indexOf('.');
    final intPart = dot == -1 ? raw : raw.substring(0, dot);
    if (intPart.length > 12) return oldValue; // ≤ ฿999,999,999,999
    final decPart = dot == -1 ? '' : raw.substring(dot); // includes '.'
    final groupedInt = intPart.isEmpty
        ? (decPart.isEmpty ? '' : '0')
        : _grouping.format(int.parse(intPart));
    final formatted = '$groupedInt$decPart';

    // Caret: count significant chars (digits / dot) before it in the new
    // raw input, then find the same position in the formatted text.
    final caret = newValue.selection.baseOffset.clamp(0, newValue.text.length);
    final significantBefore =
        newValue.text.substring(0, caret).replaceAll(',', '').length +
        (intPart.isEmpty && decPart.isNotEmpty ? 1 : 0);
    var seen = 0;
    var offset = 0;
    while (offset < formatted.length && seen < significantBefore) {
      if (formatted[offset] != ',') seen++;
      offset++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }
}

/// Keeps a number within [min]..[max] while typing (the percent type): digits
/// and at most one dot, up to [decimals] places (0 = integers only).
class RangeInputFormatter extends TextInputFormatter {
  RangeInputFormatter(this.min, this.max, {this.decimals = 0});

  final num min;
  final num max;
  final int decimals;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var t = newValue.text.replaceAll(RegExp(r'[^0-9.]'), '');
    if (decimals == 0) t = t.replaceAll('.', '');
    final dot = t.indexOf('.');
    if (dot >= 0) {
      // One dot, at most [decimals] places.
      final whole = t.substring(0, dot);
      var frac = t.substring(dot + 1).replaceAll('.', '');
      if (frac.length > decimals) frac = frac.substring(0, decimals);
      t = '$whole.$frac';
    }
    if (t.isEmpty) return newValue.copyWith(text: '');
    final n = double.tryParse(t.endsWith('.') ? '${t}0' : t);
    if (n != null && n > max) {
      t = max == max.truncate() ? '${max.toInt()}' : '$max';
    }
    if (n != null && n < min) {
      t = '$min';
    }
    return TextEditingValue(
      text: t,
      selection: TextSelection.collapsed(offset: t.length),
    );
  }
}
