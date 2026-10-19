import 'package:flutter/material.dart';

import '../atoms/app_icon.dart';
import '../molecules/detail_rows.dart';
import '../molecules/detail_text_field.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';

/// The note section: ITS OWN box (never merged into another).
class NoteSection extends StatelessWidget {
  const NoteSection({
    required this.label,
    required this.editing,
    this.text,
    this.hint,
    this.onLongPress,
    this.controller,
    this.editField,
    this.maxLength,
    this.first = false,
    super.key,
  }) : assert(
         !editing || editField != null || controller != null,
         'edit mode needs editField or controller',
       );

  final String label;
  final bool editing;

  final String? text;

  final String? hint;
  final VoidCallback? onLongPress;

  final TextEditingController? controller;

  final Widget? editField;
  final int? maxLength;
  final bool first;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final empty = text == null || text!.trim().isEmpty;
    final Widget child;
    if (editing) {
      // The same 📝 as in view mode, whatever field the page passes.
      child = DetailLeadingScope(
        leading: const AppIcon(AppIcons.note),
        child:
            editField ??
            DetailTextField(
              label: label,
              controller: controller!,
              editing: true,
              maxLines: 5,
              maxLength: maxLength,
            ),
      );
    } else {
      final row = Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconTheme.merge(
              data: IconThemeData(color: scheme.onSurfaceVariant, size: 22),
              child: const AppIcon(AppIcons.note),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: detailLabelStyle(context)),
                  const SizedBox(height: AppSpacing.xs),
                  empty
                      ? DetailPlaceholder(hint ?? '—')
                      : Text(
                          text!,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                ],
              ),
            ),
          ],
        ),
      );
      child = onLongPress == null
          ? row
          : GestureDetector(
              behavior: HitTestBehavior.opaque,
              onLongPress: onLongPress,
              child: row,
            );
    }
    return SectionCard(first: first, children: [child]);
  }
}
