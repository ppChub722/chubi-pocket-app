import 'package:flutter/material.dart';

import '../../atoms/app_input.dart';
import '../../atoms/app_input_type.dart';
import '../../atoms/ui_config.dart';
import '../../tokens/hero_colors.dart';

/// A hero's amount in edit mode: the big underlined number of the transaction
/// hero, in the accent, its label above.
class HeroAmountField extends StatelessWidget {
  const HeroAmountField({
    required this.controller,
    required this.label,
    this.accent,
    this.symbol,
    this.helper,
    this.focusNode,
    this.validator,
    this.onChanged,
    this.autofocus = false,
    super.key,
  });

  final TextEditingController controller;
  final String label;

  final String? helper;

  final Color? accent;
  final String? symbol;
  final FocusNode? focusNode;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color =
        accent ?? HeroColors.maybeOf(context)?.accent ?? scheme.primary;
    final big = Theme.of(context).textTheme.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return AppInput.card(
      controller: controller,
      focusNode: focusNode,
      label: label,
      labelPlacement: AppInputLabelPlacement.above,
      helper: helper,
      type: AppInputType.amount,
      currencySymbol: symbol ?? UiConfig.stringsOf(context).currencySymbol,
      symbolScale: 0.7,
      minWidth: 12,
      size: AppInputSize.hero,
      textAlign: TextAlign.end,
      style: big,
      hint: '0',
      hintStyle: big?.copyWith(color: color.withValues(alpha: 0.35)),
      hideHintOnFocus: true,
      cursorColor: scheme.primary,
      focusColor: color,
      validator: validator,
      onChanged: onChanged,
      autofocus: autofocus,
    );
  }
}
