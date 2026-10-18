import 'package:flutter/material.dart';

import '../../atoms/app_input.dart';
import '../../atoms/app_input_type.dart';
import '../../atoms/ui_config.dart';

/// A hero's amount in edit mode (an outlined amount input in the accent).
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
  Widget build(BuildContext context) => AppInput(
    controller: controller,
    focusNode: focusNode,
    label: label,
    helper: helper,
    type: AppInputType.amount,
    currencySymbol: symbol ?? UiConfig.stringsOf(context).currencySymbol,
    validator: validator,
    onChanged: onChanged,
    autofocus: autofocus,
    borderColor: accent,
    focusColor: accent,
  );
}
