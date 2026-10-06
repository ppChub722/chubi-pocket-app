import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../inputs/app_search_bar.dart';
import 'app_sheet.dart';

/// One choice in [showOptionSheet].
class SheetOption<T> {
  const SheetOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.leading,
    this.enabled = true,
    this.labelStyle,
  });

  final T value;
  final String label;
  final String? subtitle;
  final Widget? leading;
  final bool enabled;

  /// Per-option label style (e.g. render a font name in that font).
  final TextStyle? labelStyle;
}

/// Single-select list sheet — language, font, currency, status, sort, …
/// Resolves the picked value, or null on dismiss. [searchable] adds a
/// filter field on top (long lists: currencies, contacts).
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<SheetOption<T>> options,
  T? selected,
  bool searchable = false,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    useRootNavigator: true,
    builder: (_) => _OptionSheet<T>(
      title: title,
      options: options,
      selected: selected,
      searchable: searchable,
    ),
  );
}

class _OptionSheet<T> extends StatefulWidget {
  const _OptionSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.searchable,
  });

  final String title;
  final List<SheetOption<T>> options;
  final T? selected;
  final bool searchable;

  @override
  State<_OptionSheet<T>> createState() => _OptionSheetState<T>();
}

class _OptionSheetState<T> extends State<_OptionSheet<T>> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final q = _query.trim().toLowerCase();
    final visible = q.isEmpty
        ? widget.options
        : widget.options
            .where((o) =>
                o.label.toLowerCase().contains(q) ||
                (o.subtitle?.toLowerCase().contains(q) ?? false))
            .toList();
    return AppSheetScaffold(
      title: widget.title,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.searchable)
            AppSearchBar(onChanged: (v) => setState(() => _query = v)),
          for (final o in visible)
            ListTile(
              enabled: o.enabled,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              leading: o.leading,
              title: Text(o.label, style: o.labelStyle),
              subtitle: o.subtitle == null ? null : Text(o.subtitle!),
              trailing: o.value == widget.selected
                  ? Icon(AppIcons.check, color: scheme.primary)
                  : null,
              selected: o.value == widget.selected,
              onTap: () => Navigator.pop(context, o.value),
            ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}
