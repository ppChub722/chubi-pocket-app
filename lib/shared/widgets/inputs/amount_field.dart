import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../core/constants/app_radius.dart';
import '../../../core/constants/app_spacing.dart';

/// Keeps a money field as `#,##0.##` while the user types: digits + one
/// dot, max 2 decimals, commas re-inserted on every edit, caret kept after
/// the same digit it was after.
///
/// [allowNegative] keeps one leading `-` (balances can go below zero —
/// an overdraft, an overpaid card); the sign itself is toggled by
/// [AmountField]'s ± chip rather than typed, since the decimal keypad has
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

/// A quick-fill chip under an [AmountField] ("ทั้งหมด", "ครึ่งหนึ่ง").
class AmountQuickFill {
  const AmountQuickFill({required this.label, required this.amount});

  final String label;
  final double amount;
}

/// Large money input — the hero field of transaction / debt / settle forms.
/// Big digits, currency symbol prefix, decimal-only keyboard, thousands
/// separators inserted while typing ("1,234,567.89"), optional quick-fill
/// chips.
///
/// The controller holds the *formatted* text — read the value with
/// [AmountField.parse], write one with [AmountField.format].
class AmountField extends StatelessWidget {
  /// Parses formatted field text ("1,234.50") → 1234.5; null if empty/bad.
  static double? parse(String? text) {
    final raw = (text ?? '').replaceAll(',', '').trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  /// Formats a number for the field: thousands separators, decimals only
  /// when needed (500 → "500", 1234.5 → "1,234.50").
  static String format(num amount) {
    final whole = amount == amount.roundToDouble();
    return NumberFormat(whole ? '#,##0' : '#,##0.00', 'en_US').format(amount);
  }

  const AmountField({
    required this.controller,
    this.label,
    this.currencySymbol = '฿',
    this.autofocus = false,
    this.enabled = true,
    this.validator,
    this.onChanged,
    this.quickFills = const [],
    this.accent,
    this.allowNegative = false,
    super.key,
  });

  final TextEditingController controller;
  final String? label;
  final String currencySymbol;
  final bool autofocus;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final List<AmountQuickFill> quickFills;

  /// Digit colour (e.g. expense red / income green); defaults to onSurface.
  final Color? accent;

  /// Shows a ± chip before the currency that flips the sign (a balance
  /// below zero). [parse] reads the sign back.
  final bool allowNegative;

  void _toggleSign() {
    final t = controller.text;
    final next = t.startsWith('-') ? t.substring(1) : '-$t';
    controller.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final big = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: accent ?? scheme.onSurface,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: controller,
          enabled: enabled,
          autofocus: autofocus,
          style: big,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            ThousandsInputFormatter(allowNegative: allowNegative),
          ],
          validator: validator,
          onChanged: onChanged,
          decoration: InputDecoration(
            labelText: label,
            hintText: '0.00',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.sm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (allowNegative) ...[
                    Tooltip(
                      message: '+ / −',
                      child: InkWell(
                        onTap: enabled ? _toggleSign : null,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: AppSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Text(
                            '±',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(currencySymbol, style: big),
                ],
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 0,
              minHeight: 0,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.lg,
            ),
          ),
        ),
        if (quickFills.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final q in quickFills)
                ActionChip(
                  label: Text(q.label),
                  onPressed: enabled
                      ? () {
                          final text = format(q.amount);
                          controller.value = TextEditingValue(
                            text: text,
                            selection: TextSelection.collapsed(
                              offset: text.length,
                            ),
                          );
                          onChanged?.call(text);
                        }
                      : null,
                ),
            ],
          ),
        ],
      ],
    );
  }
}
