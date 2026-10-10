import 'package:flutter/material.dart';

import '../../../core/constants/app_icons.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/network/api_exception.dart';
import '../../../l10n/gen/app_localizations.dart';
import '../error_view.dart';
import '../skeletons.dart';

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
  final ApiException? error;
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
    final l = AppLocalizations.of(context)!;
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
                IconButton(
                  tooltip: l.commonClose,
                  icon: const Icon(AppIcons.close),
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
              child: CompactSearchField(
                controller: widget.searchController,
                autofocus: widget.searchAutofocus,
                hint: widget.searchHint ?? l.commonSearch,
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
class PickerRow extends StatelessWidget {
  const PickerRow({
    required this.title,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.trailing,
    this.indent = 0,
    this.selected = false,
    super.key,
  });

  final String title;

  /// After the text (a tree's ▾ / ▴, a count).
  final Widget? trailing;
  final double indent;
  final String? subtitle;
  final Widget? leading;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: 0.10)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg + indent,
              trailing == null ? AppSpacing.md : AppSpacing.xs,
              trailing == null ? AppSpacing.lg : AppSpacing.xs,
              trailing == null ? AppSpacing.md : AppSpacing.xs,
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
                        style: textTheme.bodyLarge?.copyWith(
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

/// A search field at chip height (36) — a picker's filter, not a page's
/// search bar.
class CompactSearchField extends StatelessWidget {
  const CompactSearchField({
    required this.onChanged,
    this.hint,
    this.controller,
    this.autofocus = false,
    super.key,
  });

  final ValueChanged<String> onChanged;
  final String? hint;
  final TextEditingController? controller;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 36,
      child: TextField(
        controller: controller,
        autofocus: autofocus,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        style: Theme.of(context).textTheme.bodyMedium,
        decoration: InputDecoration(
          hintText: hint,
          isDense: true,
          filled: true,
          fillColor: scheme.surfaceContainerHighest,
          prefixIcon: const Icon(AppIcons.search, size: 18),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide.none,
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: const BorderRadius.all(Radius.circular(18)),
            borderSide: BorderSide(color: scheme.primary),
          ),
        ),
      ),
    );
  }
}
