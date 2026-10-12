import 'package:flutter/material.dart';
import '../atoms/app_input.dart';
import '../atoms/input_formatters.dart';
export '../atoms/input_formatters.dart' show ThousandsInputFormatter;
import 'package:intl/intl.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import '../atoms/app_chip.dart';

/// A quick-fill chip under an [AmountInput] ("ทั้งหมด", "ครึ่งหนึ่ง").
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
/// [AmountInput.parse], write one with [AmountInput.format].
class AmountInput extends StatelessWidget {
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

  const AmountInput({
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
        AppInput(
          controller: controller,
          enabled: enabled,
          autofocus: autofocus,
          style: big,
          label: label,
          hint: '0.00',
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            ThousandsInputFormatter(allowNegative: allowNegative),
          ],
          validator: validator,
          onChanged: onChanged,
          prefix: Padding(
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
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.lg,
          ),
        ),
        if (quickFills.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final q in quickFills)
                AppChip(
                  label: q.label,
                  enabled: enabled,
                  onTap: enabled
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
