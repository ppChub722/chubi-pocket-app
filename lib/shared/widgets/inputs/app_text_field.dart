import 'package:flutter/material.dart';

/// Standard form text field (auth, settings dialogs, sheets). Uses the
/// theme's filled input decoration; adds a show/hide toggle when
/// [obscurable] is set (passwords).
///
/// Detail pages should prefer [InlineField] so view/edit share one box.
class AppTextField extends StatefulWidget {
  const AppTextField({
    this.controller,
    this.label,
    this.hint,
    this.helper,
    this.prefixIcon,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.obscurable = false,
    this.focusNode,
    super.key,
  });

  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? helper;
  final IconData? prefixIcon;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;
  final int? maxLength;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final bool obscurable;
  final FocusNode? focusNode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _obscured = widget.obscurable;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    return TextFormField(
      controller: w.controller,
      focusNode: w.focusNode,
      enabled: w.enabled,
      readOnly: w.readOnly,
      autofocus: w.autofocus,
      keyboardType: w.keyboardType,
      textInputAction: w.textInputAction,
      maxLines: w.obscurable ? 1 : w.maxLines,
      maxLength: w.maxLength,
      obscureText: _obscured,
      validator: w.validator,
      onChanged: w.onChanged,
      onFieldSubmitted: w.onSubmitted,
      decoration: InputDecoration(
        labelText: w.label,
        hintText: w.hint,
        helperText: w.helper,
        helperMaxLines: 3,
        prefixIcon: w.prefixIcon == null ? null : Icon(w.prefixIcon),
        suffixIcon: w.obscurable
            ? IconButton(
                icon: Icon(_obscured
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : w.suffix,
      ),
    );
  }
}
