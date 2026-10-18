import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../atoms/app_icon_button.dart';
import '../atoms/select_check.dart';
import '../atoms/app_input.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import '../atoms/ui_config.dart';
import '../molecules/error_view.dart';
import '../atoms/skeletons.dart';
import '../atoms/add_tile.dart';

class PickerSheet extends StatefulWidget {
  const PickerSheet({
    required this.title,
    required this.builder,
    this.searchable = false,
    this.searchHint,
    this.searchController,
    this.searchAutofocus = false,
    this.searchToggle = false,
    this.loading = false,
    this.error,
    this.onRetry,
    this.footer,
    this.header,
    super.key,
  });

  final String title;

  /// The body for the current search text ('' without [searchable]).
  final Widget Function(BuildContext context, String query) builder;
  final bool searchable;
  final String? searchHint;

  final TextEditingController? searchController;

  final bool searchAutofocus;

  final bool searchToggle;

  final bool loading;
  final Object? error;
  final VoidCallback? onRetry;

  final Widget? footer;

  /// Under the search, above the list, not scrolling with it (filter chips).
  final Widget? header;

  @override
  State<PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<PickerSheet> {
  String _query = '';
  bool _searchOpen = false;

  void _toggleSearch() {
    setState(() {
      _searchOpen = !_searchOpen;
      if (!_searchOpen) {
        widget.searchController?.clear();
        _query = '';
      }
    });
  }

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
                if (widget.searchable && widget.searchToggle)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: AppIconButton(
                      icon: AppIcons.search,
                      tooltip: widget.searchHint ?? strings.search,
                      selected: _searchOpen,
                      onPressed: _toggleSearch,
                    ),
                  ),
                AppIconButton.close(
                  tooltip: strings.close,
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          if (widget.searchable && (!widget.searchToggle || _searchOpen))
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: AppInput.search(
                controller: widget.searchController,
                autofocus: widget.searchAutofocus || widget.searchToggle,
                hint: widget.searchHint ?? strings.search,
                padding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          if (widget.header != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                0,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: widget.header,
            ),
          Flexible(child: SingleChildScrollView(child: body)),
          ?widget.footer,
        ],
      ),
    );
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

class PickerRow extends StatelessWidget {
  const PickerRow({
    required this.title,
    required this.onTap,
    this.leading,
    this.subtitle,
    this.trailing,
    this.chevron = false,
    this.indent = 0,
    this.selected = false,
    this.titleStyle,
    this.checked,
    super.key,
  });

  final bool? checked;

  static const double rowHeight = 56;

  final String title;

  final Widget? trailing;

  final bool chevron;
  final double indent;
  final String? subtitle;
  final Widget? leading;
  final bool selected;

  final VoidCallback? onTap;

  final TextStyle? titleStyle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final selected = this.selected || (checked ?? false);
    final row = Material(
      color: selected
          ? scheme.primary.withValues(alpha: 0.10)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: rowHeight),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg + indent,
              AppSpacing.xs,
              trailing == null && !chevron ? AppSpacing.lg : AppSpacing.xs,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                if (checked != null) ...[
                  SelectCheck(value: checked, onTap: null),
                  const SizedBox(width: AppSpacing.md),
                ],
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
                if (trailing != null)
                  trailing!
                else if (chevron)
                  Icon(AppIcons.chevronRight, color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
    return Semantics(
      selected: selected,
      checked: checked,
      button: true,
      enabled: onTap != null,
      child: onTap == null ? Opacity(opacity: 0.38, child: row) : row,
    );
  }
}

class PickerConfirmBar extends StatelessWidget {
  const PickerConfirmBar({
    required this.label,
    required this.onPressed,
    this.submits = false,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;

  final bool submits;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: AppButton(
        label: label,
        expand: true,
        size: AppButtonSize.large,
        submits: submits,
        onPressed: onPressed,
      ),
    );
  }
}

class PickerCreateRow extends StatelessWidget {
  const PickerCreateRow({required this.label, required this.onTap, super.key});

  final String label;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      child: AddTile(label: label, onTap: onTap, variant: AddTileVariant.row),
    );
    return onTap == null ? Opacity(opacity: 0.38, child: row) : row;
  }
}
