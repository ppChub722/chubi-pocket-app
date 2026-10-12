import 'package:flutter/material.dart';

import '../atoms/app_icon_button.dart';
import '../atoms/app_input.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../atoms/ui_config.dart';
import '../molecules/error_view.dart';
import '../atoms/skeletons.dart';

/// The shell every picker sheet shares (owner 2026-10-10) — open it with
/// `showAppSheetCustom`:
///
///   title                                   ✕
///   [🔍 ค้นหา…]                  (optional, chip height, filters live)
///   rows…            ([PickerRow]: selected = a highlight tint, no ✓)
///   ＋ สร้างใหม่ / buttons       ([footer], pinned under the rows)
///
/// [builder] gets the search text and returns the body; while [loading]
/// with nothing to show yet it's row skeletons, [error] an error with
/// [onRetry]. The keyboard is handled here (content must not pad for it
/// again). The event sheet uses it; the other pickers move to it next.
class PickerSheet extends StatefulWidget {
  const PickerSheet({
    required this.title,
    required this.builder,
    this.searchable = false,
    this.searchHint,
    this.searchController,
    this.searchAutofocus = false,
    this.loading = false,
    this.error,
    this.onRetry,
    this.footer,
    super.key,
  });

  final String title;

  /// The body for the current search text ('' without [searchable]).
  final Widget Function(BuildContext context, String query) builder;
  final bool searchable;
  final String? searchHint;

  /// The search text, when the picker needs it (clear it after a create
  /// that used it); the sheet follows its changes.
  final TextEditingController? searchController;

  /// Open with the keyboard up, typing into the search.
  final bool searchAutofocus;

  /// Still fetching and nothing to show yet → skeleton rows.
  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;

  /// Pinned under the scrolling body (a create row, a confirm button).
  final Widget? footer;

  @override
  State<PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<PickerSheet> {
  String _query = '';

  @override
  void initState() {
    super.initState();
    widget.searchController?.addListener(_follow);
  }

  @override
  void dispose() {
    widget.searchController?.removeListener(_follow);
    super.dispose();
  }

  void _follow() {
    final t = widget.searchController!.text;
    if (t != _query) setState(() => _query = t);
  }

  @override
  Widget build(BuildContext context) {
    final strings = UiConfig.stringsOf(context);
    final textTheme = Theme.of(context).textTheme;
    final error = widget.error;
    final Widget body;
    if (error != null) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: ErrorView(error: error, onRetry: widget.onRetry),
      );
    } else if (widget.loading) {
      body = Column(
        mainAxisSize: MainAxisSize.min,
        children: [for (var i = 0; i < 3; i++) const SkeletonListTile()],
      );
    } else {
      body = widget.builder(context, _query.trim().toLowerCase());
    }
    final content = SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // The standard header: title + ✕ (no big custom title).
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              0,
              AppSpacing.xs,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AppIconButton.close(
                  tooltip: strings.close,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          if (widget.searchable)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: AppInput.search(
                controller: widget.searchController,
                autofocus: widget.searchAutofocus,
                hint: widget.searchHint ?? strings.search,
                look: AppInputLook.pill,
                padding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          Flexible(child: SingleChildScrollView(child: body)),
          ?widget.footer,
        ],
      ),
    );
    // The keyboard is handled right here — below this, viewInsets read
    // zero (no double gap above it).
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: MediaQuery.removeViewInsets(
        context: context,
        removeBottom: true,
        child: content,
      ),
    );
  }
}

/// One row of a [PickerSheet]: [leading] · [title] / [subtitle] ·
/// [trailing]. [selected] = a highlight tint behind the row (owner rule for
/// every picker: never a ✓). [indent] shifts it right (a tree's levels).
/// [titleStyle] merges into the title (a font name in its font); a null
/// [onTap] = disabled, faded.
class PickerRow extends StatelessWidget {
  const PickerRow({
    required this.title,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.trailing,
    this.indent = 0,
    this.selected = false,
    this.titleStyle,
    super.key,
  });

  /// Every row's height (an [IconButton] ▾ fits inside it).
  static const double rowHeight = 56;

  final String title;

  /// After the text (a tree's ▾ / ▴, a count).
  final Widget? trailing;
  final double indent;
  final String? subtitle;
  final Widget? leading;
  final bool selected;

  /// Null = disabled: the row fades and ignores taps.
  final VoidCallback? onTap;

  /// Merged into the title's style (colour / weight for [selected] still
  /// win).
  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final row = Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        // One height for every row, with or without a ▾ / subtitle (QA
        // F6: 48 vs 56 before).
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: rowHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg + indent,
              AppSpacing.xs,
              trailing == null ? AppSpacing.lg : AppSpacing.xs,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  IconTheme.merge(
                    data: IconThemeData(
                      size: 22,
                      color: selected
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                    child: leading!,
                  ),
                  const SizedBox(width: AppSpacing.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodyLarge
                            ?.merge(titleStyle)
                            .copyWith(
                              color: selected ? scheme.primary : null,
                              fontWeight: selected ? FontWeight.w700 : null,
                            ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                ?trailing,
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      enabled: onTap != null,
      child: onTap == null ? Opacity(opacity: 0.38, child: row) : row,
    );
  }
}

/// "＋ สร้าง…" — the row that adds a new one at the end of a picker.
class PickerCreateRow extends StatelessWidget {
  const PickerCreateRow({required this.label, required this.onTap, super.key});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(AppIcons.add, size: 22, color: scheme.primary),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: scheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
