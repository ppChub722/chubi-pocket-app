import 'package:flutter/material.dart';

import '../../../core/constants/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';

/// A text field that is the same box in view and edit mode — only the
/// border and editability toggle, so the layout never reflows when a
/// detail page enters edit mode.
///
/// View mode: borderless, read-only; long-press calls [onEnterEdit]
/// (enter edit + focus). Empty shows a "long-press to edit" hint.
class InlineField extends StatelessWidget {
  const InlineField({
    required this.editing,
    required this.controller,
    this.focusNode,
    this.onEnterEdit,
    this.onChanged,
    this.validator,
    this.maxLines = 1,
    this.maxLength = 200,
    this.keyboardType,
    this.hint,
    super.key,
  });

  final bool editing;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onEnterEdit;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final int? maxLength;
  final TextInputType? keyboardType;

  /// Edit-mode placeholder (view mode always shows the long-press hint).
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: !editing,
      maxLines: maxLines,
      maxLength: maxLength,
      keyboardType: keyboardType,
      style: textTheme.bodyLarge,
      onChanged: onChanged,
      validator: validator,
      decoration: InputDecoration(
        hintText: editing
            ? hint
            : (onEnterEdit != null
                ? AppLocalizations.of(context)!.commonLongPressToEdit
                : null),
        hintStyle: textTheme.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        filled: false,
        isDense: true,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md, vertical: 10),
        enabledBorder: _border(editing ? scheme.outline : Colors.transparent),
        focusedBorder: _border(scheme.primary),
        border: _border(editing ? scheme.outline : Colors.transparent),
      ),
    );
    if (editing) return field;
    return GestureDetector(
      onLongPress: onEnterEdit,
      behavior: HitTestBehavior.opaque,
      child: AbsorbPointer(child: field),
    );
  }

  static OutlineInputBorder _border(Color c) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: c),
      );
}

/// The header-card name field: plain text in view mode, underlined input in
/// edit mode — identical height in both, so the card never grows.
class InlineTitleField extends StatelessWidget {
  const InlineTitleField({
    required this.editing,
    required this.controller,
    this.focusNode,
    this.onEnterEdit,
    this.onChanged,
    this.validator,
    this.hint,
    this.maxLength = 100,
    super.key,
  });

  final bool editing;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onEnterEdit;
  final ValueChanged<String>? onChanged;
  final FormFieldValidator<String>? validator;
  final String? hint;
  final int maxLength;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: !editing,
      maxLength: maxLength,
      style: Theme.of(context).textTheme.titleMedium,
      decoration: InputDecoration(
        filled: false,
        isDense: true,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        hintText: hint,
        enabledBorder: _underline(editing ? scheme.outline : Colors.transparent),
        focusedBorder: _underline(scheme.primary),
        border: _underline(editing ? scheme.outline : Colors.transparent),
      ),
      onChanged: onChanged,
      validator: validator,
    );
    if (editing) return field;
    return GestureDetector(
      onLongPress: onEnterEdit,
      behavior: HitTestBehavior.opaque,
      child: AbsorbPointer(child: field),
    );
  }

  static UnderlineInputBorder _underline(Color c) =>
      UnderlineInputBorder(borderSide: BorderSide(color: c));
}
