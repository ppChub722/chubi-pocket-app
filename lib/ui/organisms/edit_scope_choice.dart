import 'package:flutter/material.dart';

import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'picker_sheet.dart';

enum EditScope {
  thisOne,

  following,

  past,

  upcoming,

  all,
}

Future<EditScope?> showEditScopeChoice(
  BuildContext context, {
  required String title,
  required Map<EditScope, String> options,
  EditScope? selected,
}) {
  assert(options.isNotEmpty, 'showEditScopeChoice needs options');
  return showDialog<EditScope>(
    context: context,
    builder: (ctx) => EditScopeChoice(
      title: title,
      options: options,
      selected: selected,
      onPicked: (s) => Navigator.pop(ctx, s),
    ),
  );
}

class EditScopeChoice extends StatelessWidget {
  const EditScopeChoice({
    required this.title,
    required this.options,
    required this.onPicked,
    this.selected,
    super.key,
  });

  final String title;
  final Map<EditScope, String> options;
  final EditScope? selected;
  final ValueChanged<EditScope> onPicked;

  static const double maxWidth = 304;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Dialog(
      backgroundColor: scheme.surfaceContainerHigh,
      elevation: 4,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md + 2,
                  AppSpacing.xs,
                  AppSpacing.md + 2,
                  AppSpacing.sm,
                ),
                child: Text(
                  title,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              for (final e in options.entries)
                PickerRow(
                  title: e.value,
                  selected: e.key == selected,
                  onTap: () => onPicked(e.key),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
