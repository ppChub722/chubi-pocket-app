import 'package:flutter/material.dart';

import '../atoms/connection_scope.dart';
import '../tokens/app_spacing.dart';
import 'app_sheet.dart';
import 'picker_sheet.dart';

/// One choice in [showOptionSheet].
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

  /// Per-option label style (e.g. render a font name in that font).
  final TextStyle? labelStyle;

  /// A destructive choice (remove, leave): its label in the error colour.
  final bool destructive;

  /// Picking it sends to the server (delete, archive, a save choice): the row
  /// is disabled while the app is offline ([ConnectionScope]), in popovers and
  /// option sheets alike. Default false.
  final bool submits;
}

/// Single-select list sheet — language, font, currency, status, sort, …
/// Resolves the picked value, or null on dismiss. On the kit [PickerSheet]
/// shell (owner 2026-10-11): title + ✕, [searchable] adds the compact
/// search (long lists: currencies, banks), rows are [PickerRow]s and the
/// selected one is highlighted — never a ✓.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<SheetOption<T>> options,
  T? selected,
  bool searchable = false,
}) {
  return showPpForgeSheetCustom<T>(
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
            const SizedBox(height: PpForgeSpacing.md),
          ],
        );
      },
    ),
  );
}
