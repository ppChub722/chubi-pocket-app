import 'package:flutter/material.dart';

import '../../atoms/app_input.dart';
import '../../organisms/app_sheet.dart';
import '../../templates/form_sheet.dart';
import '../../tokens/app/text_limits.dart';

/// Naming a new tag (the tag picker's "add a tag" with nothing typed).
Future<String?> showNewTagNameSheet(
  BuildContext context, {
  required String title,
  required String saveLabel,
  required String hint,
  int maxLength = TextLimits.tagName,
}) async {
  final name = await showAppSheetCustom<String>(
    context,
    builder: (_) => _NewTagNameSheet(
      title: title,
      saveLabel: saveLabel,
      hint: hint,
      maxLength: maxLength,
    ),
  );
  final n = name?.trim() ?? '';
  return n.isEmpty ? null : n;
}

class _NewTagNameSheet extends StatefulWidget {
  const _NewTagNameSheet({
    required this.title,
    required this.saveLabel,
    required this.hint,
    required this.maxLength,
  });

  final String title;
  final String saveLabel;
  final String hint;
  final int maxLength;

  @override
  State<_NewTagNameSheet> createState() => _NewTagNameSheetState();
}

class _NewTagNameSheetState extends State<_NewTagNameSheet> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: widget.title,
      primaryLabel: widget.saveLabel,
      onPrimary: () => Navigator.pop(context, _text.text),
      child: AppInput(
        controller: _text,
        autofocus: true,
        maxLength: widget.maxLength,
        hint: widget.hint,
        textInputAction: TextInputAction.done,
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
    );
  }
}
