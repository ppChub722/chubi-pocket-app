import 'package:flutter/material.dart';
import '../atoms/app_input.dart';
import '../atoms/input_formatters.dart';
export '../atoms/input_formatters.dart' show ThousandsInputFormatter;
import 'package:intl/intl.dart';

import '../tokens/app_spacing.dart';
import '../atoms/app_chip.dart';
import '../atoms/ui_config.dart';

class AmountQuickFill {
  const AmountQuickFill({required this.label, required this.amount});

  final String label;
  final double amount;
}

class AmountInput extends StatelessWidget {
  static double? parse(String? text) {
    final raw = (text ?? '').replaceAll(',', '').trim();
    if (raw.isEmpty) return null;
    return double.tryParse(raw);
  }

  static String format(num amount) {
    final whole = amount == amount.roundToDouble();
    return NumberFormat(whole ? '#,##0' : '#,##0.00', 'en_US').format(amount);
  }

  const AmountInput({
    required this.controller,
    this.label,
    this.currencySymbol,
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

  /// Null = the user's currency.
  final String? currencySymbol;
  final bool autofocus;
  final bool enabled;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final List<AmountQuickFill> quickFills;

  final Color? accent;

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
                  AppChip(
                    label: '±',
                    tooltip: '+ / −',
                    bold: true,
                    enabled: enabled,
                    onTap: enabled ? _toggleSign : null,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                ],
                Text(
                  currencySymbol ?? UiConfig.stringsOf(context).currencySymbol,
                  style: big,
                ),
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
