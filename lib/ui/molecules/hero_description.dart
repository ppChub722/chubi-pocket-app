import 'package:flutter/material.dart';

import '../atoms/app_input.dart';
import '../atoms/ui_config.dart';

/// The entity's description inside its hero, under the name (owner
/// 2026-10-12, every detail page): pass it as `HeaderCard.description`.
///
/// - view: muted text, at most 2 lines with an ellipsis; an EMPTY description
///   shows nothing at all;
/// - edit ([editing]): edited in place — an `AppInput.card` underline with the
///   small field-name label "คำอธิบาย" on its left (edit / create only) and the
///   friendly [hint] as the placeholder, 2 lines.
class HeroDescription extends StatelessWidget {
  const HeroDescription({
    required this.controller,
    required this.editing,
    required this.hint,
    this.maxLength,
    this.onChanged,
    this.focusNode,
    this.onEnterEdit,
    super.key,
  });

  final TextEditingController controller;
  final bool editing;

  /// The placeholder in edit mode.
  final String hint;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  /// Long-press on the text in view mode → enter edit.
  final VoidCallback? onEnterEdit;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant);
    if (editing) {
      return AppInput.card(
        controller: controller,
        focusNode: focusNode,
        hint: hint,
        label: UiConfig.stringsOf(context).fieldDescription,
        maxLines: 2,
        maxLength: maxLength,
        onChanged: onChanged,
        style: style,
      );
    }
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final text = value.text.trim();
        if (text.isEmpty) return const SizedBox.shrink();
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onLongPress: onEnterEdit,
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        );
      },
    );
  }
}

/// The entity's NAME inside its hero (`HeaderCard.title`): plain text in view;
/// in create / edit the underline input carries the small field-name label
/// "ชื่อ" on its left, the friendly [hint] stays the placeholder. Same
/// parameters as `AppInput.title`.
class HeroNameInput extends StatelessWidget {
  const HeroNameInput({
    required this.editing,
    required this.controller,
    this.focusNode,
    this.onEnterEdit,
    this.hint,
    this.validator,
    this.onChanged,
    this.maxLength = 100,
    this.maxLines = 1,
    this.style,
    super.key,
  });

  final bool editing;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final VoidCallback? onEnterEdit;
  final String? hint;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final int maxLength;
  final int maxLines;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => AppInput.title(
    editing: editing,
    controller: controller,
    focusNode: focusNode,
    onEnterEdit: onEnterEdit,
    hint: hint,
    validator: validator,
    onChanged: onChanged,
    maxLength: maxLength,
    maxLines: maxLines,
    style: style,
    label: UiConfig.stringsOf(context).fieldName,
  );
}
