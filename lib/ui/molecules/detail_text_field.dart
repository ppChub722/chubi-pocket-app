import 'package:flutter/material.dart';

import '../atoms/app_input.dart';
import 'detail_rows.dart';

class DetailTextField extends StatelessWidget {
  const DetailTextField({
    required this.label,
    required this.controller,
    required this.editing,
    this.notSetLabel,
    this.focusNode,
    this.hint,
    this.viewHint,
    this.locked = false,
    this.placeholderWhenEmpty = false,
    this.maxLines = 1,
    this.maxLength,
    this.keyboardType,
    this.validator,
    this.onChanged,
    this.onEnterEdit,
    this.obscurable = false,
    this.helper,
    this.errorText,
    this.leading,
    super.key,
  });

  /// An icon left of the label and field (see [DetailStacked.leading]).
  final Widget? leading;

  final String label;
  final TextEditingController controller;
  final bool editing;

  final String? notSetLabel;
  final FocusNode? focusNode;

  final String? hint;

  final String? viewHint;
  final bool locked;
  final bool placeholderWhenEmpty;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  final VoidCallback? onEnterEdit;

  final bool obscurable;

  final String? helper;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        if (placeholderWhenEmpty &&
            !editing &&
            !locked &&
            controller.text.trim().isEmpty) {
          return DetailRow(
            label: label,
            trailing: DetailPlaceholder(notSetLabel ?? '—'),
            onTap: onEnterEdit,
          );
        }
        return DetailStacked(
          label: label,
          leading: leading,
          child: AppInput.inline(
            editing: editing && !locked,
            controller: controller,
            focusNode: focusNode,
            maxLines: maxLines,
            maxLength: maxLength,
            keyboardType: keyboardType,
            hint: hint,
            viewHint: viewHint,
            onEnterEdit: locked ? null : onEnterEdit,
            onChanged: onChanged,
            validator: validator,
            obscurable: obscurable,
            helper: helper,
            errorText: errorText,
          ),
        );
      },
    );
  }
}
