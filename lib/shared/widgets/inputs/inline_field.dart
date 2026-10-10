import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;

import '../../../core/constants/app_spacing.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../layout/detail_rows.dart';

/// A text field that is the same box in view and edit mode — only the
/// border and editability toggle, so the layout never reflows when a
/// detail page enters edit mode.
///
/// View mode: borderless, read-only; long-press calls [onEnterEdit]
/// (enter edit + focus). Empty shows a "long-press to edit" hint.
///
/// Under a [DetailStacked] label the field hangs its side padding out to
/// the left ([_textInset]), so the text starts exactly under the label in both
/// modes — the edit outline just reaches a little further left.
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
      // Grows up to [maxLines] — an empty field is one line, not a box.
      minLines: 1,
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
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        enabledBorder: _border(editing ? scheme.outline : Colors.transparent),
        focusedBorder: _border(scheme.primary),
        border: _border(editing ? scheme.outline : Colors.transparent),
      ),
    );
    final Widget box = editing
        ? field
        : GestureDetector(
            onLongPress: onEnterEdit,
            behavior: HitTestBehavior.opaque,
            child: AbsorbPointer(child: field),
          );
    if (!DetailStackedValue.of(context)) return box;
    // [_textInset] wider, sticking out on the left — its text then starts at
    // this widget's left edge, under the label.
    return LayoutBuilder(
      builder: (context, c) => OverflowBox(
        minWidth: c.maxWidth + _textInset,
        maxWidth: c.maxWidth + _textInset,
        fit: OverflowBoxFit.deferToChild,
        alignment: AlignmentDirectional.centerEnd,
        child: box,
      ),
    );
  }

  /// Where the text starts inside the field: the 12 content padding plus
  /// the 4 the outlined decorator adds (measured — test/shared/
  /// detail_stacked_test.dart guards it).
  static const double _textInset = AppSpacing.lg;

  static OutlineInputBorder _border(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: c),
  );
}

/// The header-card name field: plain text in view mode, underlined input in
/// edit mode — identical height in both, so the card never grows. Also the
/// header's subtitle line (a description) via [style] / [maxLines].
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
    this.maxLines = 1,
    this.style,
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

  /// > 1 wraps (grows from one line up to this).
  final int maxLines;

  /// Defaults to `titleMedium`.
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textStyle = style ?? Theme.of(context).textTheme.titleMedium;
    final field = TextFormField(
      controller: controller,
      focusNode: focusNode,
      readOnly: !editing,
      maxLength: maxLength,
      minLines: 1,
      maxLines: maxLines,
      style: textStyle,
      decoration: InputDecoration(
        filled: false,
        isDense: true,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        hintText: hint,
        hintStyle: textStyle?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        enabledBorder: _underline(
          editing ? scheme.outline : Colors.transparent,
        ),
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
