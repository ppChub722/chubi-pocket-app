import 'package:flutter/material.dart';

import '../atoms/app_input.dart';
import '../atoms/ui_config.dart';
import '../tokens/hero_colors.dart';

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

  final String hint;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;

  final VoidCallback? onEnterEdit;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      color:
          HeroColors.maybeOf(context)?.muted ??
          Theme.of(context).colorScheme.onSurfaceVariant,
    );
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
        size: AppInputSize.regular,
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
    size: AppInputSize.title,
  );
}
