import 'package:flutter/material.dart';

import '../atoms/connection_scope.dart';
import '../tokens/app_spacing.dart';
import 'app_sheet.dart';
import 'picker_sheet.dart';

class SheetOption<T> {
  const SheetOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
    this.enabled = true,
    this.labelStyle,
    this.destructive = false,
    this.submits = false,
  });

  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;
  final bool enabled;

  final TextStyle? labelStyle;

  final bool destructive;

  final bool submits;
}

Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<SheetOption<T>> options,
  T? selected,
  bool searchable = false,
}) {
  return showAppSheetCustom<T>(
    context,
    builder: (_) => PickerSheet(
      title: title,
      searchable: searchable,
      builder: (context, query) {
        final offline = ConnectionScope.isOffline(context);
        final visible = query.isEmpty
            ? options
            : options
                  .where(
                    (o) =>
                        o.label.toLowerCase().contains(query) ||
                        (o.subtitle?.toLowerCase().contains(query) ?? false),
                  )
                  .toList();
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final o in visible)
              PickerRow(
                leading: o.leading,
                title: o.label,
                titleStyle: o.destructive
                    ? (o.labelStyle ?? const TextStyle()).copyWith(
                        color: Theme.of(context).colorScheme.error,
                      )
                    : o.labelStyle,
                subtitle: o.subtitle,
                selected: o.value == selected,
                onTap: o.enabled && !(o.submits && offline)
                    ? () => Navigator.pop(context, o.value)
                    : null,
              ),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    ),
  );
}
