import 'package:flutter/material.dart';

import '../atoms/app_input.dart';
import 'detail_rows.dart';

/// One editable text value of a detail page's box — ONE implementation for
/// every detail page (contact, profile, …), so the same field never looks
/// different on two pages (owner 2026-10-12):
///
/// - view, nothing set, [placeholderWhenEmpty] (and not [locked]): ONE row —
///   label left, the faint [notSetLabel] right; tap → [onEnterEdit];
/// - otherwise a stacked [DetailStacked] label + [PpForgeInput.inline] (long-press
///   → edit in view; typed in edit; locked = never editable).
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
    super.key,
  });

  final String label;
  final TextEditingController controller;
  final bool editing;

  /// The faint "not set" text of the one-row empty state.
  final String? notSetLabel;
  final FocusNode? focusNode;

  /// In edit: what goes here.
  final String? hint;

  /// In view, empty: the long-press hint.
  final String? viewHint;
  final bool locked;
  final bool placeholderWhenEmpty;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  /// Enter edit mode (tap on the empty row, long-press on the value).
  final VoidCallback? onEnterEdit;

  /// A secret: hidden text, the eye at the right inside the frame.
  final bool obscurable;

  /// Under the frame.
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
          child: PpForgeInput.inline(
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
