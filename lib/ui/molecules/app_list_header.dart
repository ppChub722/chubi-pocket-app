import 'package:flutter/material.dart';

import '../atoms/app_chip.dart';
import '../atoms/list_break.dart';
import '../organisms/option_sheet.dart';
import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../tokens/chip_size.dart';
import 'app_list_toolbar.dart';
import 'card_action_button.dart';
import 'option_menu.dart';

/// The head of a group of [AppListRow]s: title | count, then a value and
/// actions at the end. One look on every list; knows no domain.
class AppListHeader extends StatelessWidget implements ListBreak {
  const AppListHeader({
    required this.title,
    this.count,
    this.leading,
    this.onClearTitle,
    this.trailing,
    this.actions = const [],
    this.padding,
    super.key,
  });

  final String title;
  final int? count;

  /// A small icon before the title.
  final Widget? leading;

  /// Non-null = the title is a picked filter (a day): a chip with ✕ that
  /// calls this.
  final VoidCallback? onClearTitle;
  final ListHeaderTrailing? trailing;
  final List<ListHeaderAction> actions;

  /// Only for a header inside a block that already pads it (a home card).
  final EdgeInsetsGeometry? padding;

  /// What the title (+ count) always keeps on a narrow screen.
  static const double _minTitle = 120;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final titleStyle = textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    );
    final countStyle = textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w400,
      color: scheme.onSurfaceVariant,
    );
    // Over a card of rows the title lines up with a card title; the value
    // ends over the rows' amounts, the actions at the card's edge.
    final carded = CardedListBreak.of(context);
    final trailing = this.trailing;
    final clear = onClearTitle;
    final hasEnd = trailing != null || actions.isNotEmpty;
    return Padding(
      padding:
          padding ??
          EdgeInsetsDirectional.fromSTEB(
            carded ? AppSpacing.md : AppSpacing.lg,
            AppSpacing.md,
            actions.isEmpty ? AppSpacing.lg : 0,
            AppSpacing.xs,
          ),
      child: LayoutBuilder(
        builder: (context, box) {
          final endMax = (box.maxWidth - _minTitle).clamp(0.0, double.infinity);
          return Row(
            children: [
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: clear != null
                          ? AppChip(
                              label: title,
                              selected: true,
                              size: ChipSize.chip,
                              trailing: AppChipTrailing.remove,
                              onRemove: clear,
                              onTap: clear,
                            )
                          : Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle,
                            ),
                    ),
                    if (count != null) ...[
                      const SizedBox(width: AppSpacing.xs),
                      Text('| $count', style: countStyle),
                    ],
                  ],
                ),
              ),
              if (hasEnd) ...[
                const SizedBox(width: AppSpacing.sm),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: endMax),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (trailing != null)
                        Flexible(child: trailing._build(context)),
                      for (final (i, a) in actions.indexed) ...[
                        if (i > 0 || trailing != null)
                          const SizedBox(width: AppSpacing.sm),
                        a._build(context),
                      ],
                    ],
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// The value at a header's end.
sealed class ListHeaderTrailing {
  const ListHeaderTrailing();

  /// [child] (a money widget) in the row value style, after a small muted
  /// [prefix] ("รวม").
  const factory ListHeaderTrailing.value(Widget child, {String? prefix}) =
      _ValueHeaderTrailing;

  /// Muted small words ("฿5,635/เดือน | ฿67,622/ปี").
  const factory ListHeaderTrailing.text(String text) = _TextHeaderTrailing;

  Widget _build(BuildContext context);
}

class _ValueHeaderTrailing extends ListHeaderTrailing {
  const _ValueHeaderTrailing(this.child, {this.prefix});

  final Widget child;
  final String? prefix;

  @override
  Widget _build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final value = DefaultTextStyle.merge(
      style: textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
      child: child,
    );
    final prefix = this.prefix;
    if (prefix == null) return value;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          prefix,
          style: textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(width: AppSpacing.xs),
        value,
      ],
    );
  }
}

class _TextHeaderTrailing extends ListHeaderTrailing {
  const _TextHeaderTrailing(this.text);

  final String text;

  @override
  Widget _build(BuildContext context) => Text(
    text,
    maxLines: 2,
    textAlign: TextAlign.end,
    overflow: TextOverflow.ellipsis,
    style: Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    ),
  );
}

/// Something to press at a header's end.
sealed class ListHeaderAction {
  const ListHeaderAction();

  /// The 🔍 of the list's [AppListToolbar].
  const factory ListHeaderAction.toolbar(
    AppListToolbarState state, {
    bool filtered,
    String? tooltip,
  }) = _ToolbarHeaderAction;

  /// A round icon button (＋, ⇅).
  const factory ListHeaderAction.button(
    IconData icon, {
    required VoidCallback? onTap,
    String? tooltip,
    bool selected,
  }) = _ButtonHeaderAction;

  /// "ดูทั้งหมด ›".
  const factory ListHeaderAction.link(
    String label, {
    required VoidCallback onTap,
  }) = _LinkHeaderAction;

  /// A dropdown chip that filters the list in place ("ทุกสถานะ ▾");
  /// [active] = a value other than "all" is picked.
  static ListHeaderAction filter<T>({
    required String label,
    required T value,
    required List<SheetOption<T>> options,
    required ValueChanged<T> onSelected,
    bool active = false,
  }) => _FilterHeaderAction<T>(
    label: label,
    value: value,
    options: options,
    onSelected: onSelected,
    active: active,
  );

  Widget _build(BuildContext context);
}

class _ToolbarHeaderAction extends ListHeaderAction {
  const _ToolbarHeaderAction(this.state, {this.filtered = false, this.tooltip});

  final AppListToolbarState state;
  final bool filtered;
  final String? tooltip;

  @override
  Widget _build(BuildContext context) =>
      AppListToolbarToggle(state: state, filtered: filtered, tooltip: tooltip);
}

class _ButtonHeaderAction extends ListHeaderAction {
  const _ButtonHeaderAction(
    this.icon, {
    required this.onTap,
    this.tooltip,
    this.selected = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final bool selected;

  @override
  Widget _build(BuildContext context) => CardActionButton(
    icon: icon,
    tooltip: tooltip,
    selected: selected,
    onTap: onTap,
  );
}

class _LinkHeaderAction extends ListHeaderAction {
  const _LinkHeaderAction(this.label, {required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget _build(BuildContext context) => TextButton(
    onPressed: onTap,
    style: TextButton.styleFrom(
      minimumSize: const Size(0, 40),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [Text(label), const Icon(AppIcons.chevronRight, size: 18)],
    ),
  );
}

class _FilterHeaderAction<T> extends ListHeaderAction {
  const _FilterHeaderAction({
    required this.label,
    required this.value,
    required this.options,
    required this.onSelected,
    this.active = false,
  });

  final String label;
  final T value;
  final List<SheetOption<T>> options;
  final ValueChanged<T> onSelected;
  final bool active;

  @override
  Widget _build(BuildContext context) => Flexible(
    child: OptionMenuAnchor<T>(
      selected: value,
      options: options,
      onSelected: onSelected,
      builder: (context, toggle) => AppChip(
        label: label,
        selected: active,
        size: ChipSize.chip,
        trailing: AppChipTrailing.dropdown,
        onTap: toggle,
      ),
    ),
  );
}
