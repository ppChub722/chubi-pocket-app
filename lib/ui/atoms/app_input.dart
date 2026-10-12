import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show OverflowBoxFit;
import 'package:flutter/services.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_spacing.dart';
import 'detail_stacked_value.dart';
import 'ui_config.dart';

/// How an [AppInput] is drawn.
enum AppInputLook {
  /// The theme's filled box — forms, auth, settings dialogs.
  filled,

  /// An outline (the detail pages' editable boxes, a small amount box).
  outlined,

  /// Only an underline — rows that edit in place (split name / amount, an
  /// identifier number, the header title).
  underline,

  /// A rounded, borderless, grey capsule — the compact search in a sheet.
  pill,

  /// No chrome at all — a hero's big amount, a chat box.
  bare,
}

enum _Kind { field, inline, title, search }

/// THE text input (owner 2026-10-12: one input for the whole app). Replaces
/// the old AppTextField, InlineField, InlineTitleField, AppSearchBar and every
/// raw `TextField` / `TextFormField` in the features.
///
/// - `AppInput(...)` — a form field: label, hint, helper, error, prefix /
///   suffix, password toggle ([obscurable]), validator, formatters, counter.
/// - `AppInput.inline(...)` — one box in view and edit mode on a detail page:
///   borderless + read-only in view (long-press → [onEnterEdit], an empty
///   field shows [viewHint]); outlined in edit. Under a `DetailStacked` label
///   its text lines up with the label.
/// - `AppInput.title(...)` — a hero's name / description: plain text in view,
///   underlined in edit, the same height both ways.
/// - `AppInput.search(...)` — a search box with a leading 🔍 and a ✕ once
///   there is text; owns its controller when none is given.
///
/// [look] picks how it is drawn (default per kind); [style], [textAlign],
/// [contentPadding], [borderColor] tune a look without a new widget. Strings
/// (hint, tooltip, view hint) are always parameters — this atom never reads
/// the app's localisation.
class AppInput extends StatefulWidget {
  const AppInput({
    this.controller,
    this.focusNode,
    this.label,
    this.hint,
    this.helper,
    this.errorText,
    this.prefixIcon,
    this.prefix,
    this.prefixText,
    this.suffix,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.showCounter = false,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.obscurable = false,
    this.autofillHints,
    this.inputFormatters,
    this.textAlign = TextAlign.start,
    this.style,
    this.look = AppInputLook.filled,
    this.contentPadding,
    this.borderColor,
    this.fillColor,
    this.focusColor,
    this.cursorColor,
    this.hintStyle,
    this.minWidth,
    this.onTapOutside,
    this.showCursor,
    this.enableInteractiveSelection,
    super.key,
  }) : _kind = _Kind.field,
       editing = true,
       onEnterEdit = null,
       viewHint = null,
       clearTooltip = null,
       padding = null;

  /// See the class doc.
  const AppInput.inline({
    required this.editing,
    required TextEditingController this.controller,
    this.focusNode,
    this.onEnterEdit,
    this.viewHint,
    this.hint,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength = 200,
    this.keyboardType,
    super.key,
  }) : _kind = _Kind.inline,
       label = null,
       helper = null,
       errorText = null,
       prefixIcon = null,
       prefix = null,
       prefixText = null,
       suffix = null,
       textInputAction = null,
       textCapitalization = TextCapitalization.none,
       minLines = 1,
       showCounter = false,
       onSubmitted = null,
       onTap = null,
       enabled = true,
       readOnly = false,
       autofocus = false,
       obscurable = false,
       autofillHints = null,
       inputFormatters = null,
       textAlign = TextAlign.start,
       style = null,
       look = AppInputLook.outlined,
       contentPadding = null,
       borderColor = null,
       fillColor = null,
       showCursor = null,
       focusColor = null,
       cursorColor = null,
       hintStyle = null,
       minWidth = null,
       onTapOutside = null,
       enableInteractiveSelection = null,
       clearTooltip = null,
       padding = null;

  /// See the class doc.
  const AppInput.title({
    required this.editing,
    required TextEditingController this.controller,
    this.focusNode,
    this.onEnterEdit,
    this.hint,
    this.validator,
    this.onChanged,
    this.maxLength = 100,
    this.maxLines = 1,
    this.style,
    super.key,
  }) : _kind = _Kind.title,
       label = null,
       helper = null,
       errorText = null,
       prefixIcon = null,
       prefix = null,
       prefixText = null,
       suffix = null,
       keyboardType = null,
       textInputAction = null,
       textCapitalization = TextCapitalization.none,
       minLines = 1,
       showCounter = false,
       onSubmitted = null,
       onTap = null,
       enabled = true,
       readOnly = false,
       autofocus = false,
       obscurable = false,
       autofillHints = null,
       inputFormatters = null,
       textAlign = TextAlign.start,
       look = AppInputLook.underline,
       contentPadding = null,
       borderColor = null,
       fillColor = null,
       showCursor = null,
       focusColor = null,
       cursorColor = null,
       hintStyle = null,
       minWidth = null,
       onTapOutside = null,
       enableInteractiveSelection = null,
       viewHint = null,
       clearTooltip = null,
       padding = null;

  /// See the class doc. [hint] is what the field says when empty; [clearTooltip]
  /// is the ✕'s tooltip. [look]: [AppInputLook.outlined] (default, a list
  /// page's top) or [AppInputLook.pill] (compact, in a sheet).
  const AppInput.search({
    required this.onChanged,
    this.controller,
    this.hint,
    this.clearTooltip,
    this.autofocus = false,
    this.look = AppInputLook.outlined,
    this.padding = const EdgeInsets.fromLTRB(
      AppSpacing.lg,
      AppSpacing.xs,
      AppSpacing.lg,
      AppSpacing.xs,
    ),
    super.key,
  }) : _kind = _Kind.search,
       focusNode = null,
       label = null,
       helper = null,
       errorText = null,
       prefixIcon = null,
       prefix = null,
       prefixText = null,
       suffix = null,
       keyboardType = null,
       textInputAction = TextInputAction.search,
       textCapitalization = TextCapitalization.none,
       minLines = null,
       maxLines = 1,
       maxLength = null,
       showCounter = false,
       validator = null,
       onSubmitted = null,
       onTap = null,
       enabled = true,
       readOnly = false,
       obscurable = false,
       autofillHints = null,
       inputFormatters = null,
       textAlign = TextAlign.start,
       style = null,
       contentPadding = null,
       borderColor = null,
       fillColor = null,
       showCursor = null,
       focusColor = null,
       cursorColor = null,
       hintStyle = null,
       minWidth = null,
       onTapOutside = null,
       enableInteractiveSelection = null,
       editing = true,
       onEnterEdit = null,
       viewHint = null;

  final _Kind _kind;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helper;

  /// Server-side error for this field (e.g. "username taken").
  final String? errorText;
  final IconData? prefixIcon;

  /// A custom leading widget (a currency symbol, a ± toggle) instead of
  /// [prefixIcon]; takes only the room it needs.
  final Widget? prefix;
  final String? prefixText;
  final Widget? suffix;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final int? minLines;
  final int maxLines;
  final int? maxLength;

  /// Show the "n / max" counter (hidden by default).
  final bool showCounter;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;

  /// A password field: ● ● ● with a show / hide toggle.
  final bool obscurable;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign textAlign;

  /// Overrides the text style (a hero's big amount, a bold name).
  final TextStyle? style;
  final AppInputLook look;
  final EdgeInsetsGeometry? contentPadding;

  /// Overrides the border / underline colour (an invalid value in red).
  final Color? borderColor;

  /// The border / underline colour while focused (default: the primary).
  final Color? focusColor;

  /// The caret colour (default: the theme's).
  final Color? cursorColor;

  /// Overrides the hint style (default: [style] at 40% — a hero amount's
  /// faint "0" in its own colour).
  final TextStyle? hintStyle;

  /// A minimum width for the field (an intrinsic-width amount: grows with
  /// what is typed).
  final double? minWidth;

  /// A tap outside the field while it has focus (commit on blur).
  final TapRegionCallback? onTapOutside;
  final Color? fillColor;
  final bool? showCursor;
  final bool? enableInteractiveSelection;

  /// inline / title: false = view mode (read-only, long-press to edit).
  final bool editing;
  final VoidCallback? onEnterEdit;

  /// inline: what an empty field says in view mode when it can be edited
  /// ("long-press to edit").
  final String? viewHint;

  /// search: the ✕'s tooltip.
  final String? clearTooltip;

  /// search: space around the box.
  final EdgeInsetsGeometry? padding;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late bool _obscured = widget.obscurable;
  TextEditingController? _own;

  TextEditingController? get _controller =>
      widget.controller ??
      (widget._kind == _Kind.search
          ? (_own ??= TextEditingController())
          : null);

  @override
  void dispose() {
    _own?.dispose();
    super.dispose();
  }

  // ── decoration ────────────────────────────────────────────────────
  InputBorder _border(AppInputLook look, Color c, {double radius = 10}) =>
      switch (look) {
        AppInputLook.underline => UnderlineInputBorder(
          borderSide: BorderSide(color: c),
        ),
        AppInputLook.pill => const OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(18)),
          borderSide: BorderSide.none,
        ),
        AppInputLook.bare => InputBorder.none,
        _ => OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: c),
        ),
      };

  InputDecoration _decoration(
    BuildContext context, {
    required Color idle,
    String? hint,
    TextStyle? hintStyle,
    Widget? suffixIcon,
    Widget? prefixIcon,
    BoxConstraints? prefixConstraints,
  }) {
    final w = widget;
    final scheme = Theme.of(context).colorScheme;
    final look = w.look;
    final base = w.borderColor ?? idle;
    final theme = look == AppInputLook.filled;
    return InputDecoration(
      labelText: w.label,
      hintText: hint,
      hintStyle: hintStyle,
      helperText: w.helper,
      helperMaxLines: 3,
      errorText: w.errorText,
      errorMaxLines: 3,
      prefixIcon: prefixIcon,
      prefixIconConstraints: prefixConstraints,
      prefixText: w.prefixText,
      suffixIcon: suffixIcon,
      constraints: w.minWidth == null
          ? null
          : BoxConstraints(minWidth: w.minWidth!),
      isDense: look != AppInputLook.filled,
      filled: theme || look == AppInputLook.pill || w.fillColor != null,
      fillColor:
          w.fillColor ??
          (look == AppInputLook.pill ? scheme.surfaceContainerHighest : null),
      counterText: w.showCounter ? null : '',
      contentPadding: w.contentPadding ?? _padding(look),
      // `filled` keeps the theme's own borders (its input decoration theme).
      border: theme && w.borderColor == null ? null : _border(look, base),
      enabledBorder: theme && w.borderColor == null
          ? null
          : _border(look, base),
      focusedBorder: theme && w.borderColor == null
          ? null
          : _border(look, w.focusColor ?? scheme.primary),
    );
  }

  EdgeInsetsGeometry? _padding(AppInputLook look) => switch (look) {
    AppInputLook.underline => const EdgeInsets.symmetric(
      vertical: AppSpacing.sm,
    ),
    AppInputLook.pill => const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    AppInputLook.bare => EdgeInsets.zero,
    AppInputLook.outlined => const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: 10,
    ),
    AppInputLook.filled => null,
  };

  // ── kinds ─────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) => switch (widget._kind) {
    _Kind.field => _buildField(context),
    _Kind.inline => _buildInline(context),
    _Kind.title => _buildTitle(context),
    _Kind.search => _buildSearch(context),
  };

  Widget _buildField(BuildContext context) {
    final w = widget;
    final scheme = Theme.of(context).colorScheme;
    return TextFormField(
      controller: w.controller,
      focusNode: w.focusNode,
      enabled: w.enabled,
      readOnly: w.readOnly,
      autofocus: w.autofocus,
      keyboardType: w.keyboardType,
      textInputAction: w.textInputAction,
      textCapitalization: w.textCapitalization,
      textAlign: w.textAlign,
      minLines: w.obscurable ? 1 : w.minLines,
      maxLines: w.obscurable ? 1 : w.maxLines,
      maxLength: w.maxLength,
      obscureText: _obscured,
      autofillHints: w.autofillHints,
      inputFormatters: w.inputFormatters,
      validator: w.validator,
      onChanged: w.onChanged,
      onFieldSubmitted: w.onSubmitted,
      onTap: w.onTap,
      onTapOutside: w.onTapOutside,
      showCursor: w.showCursor,
      cursorColor: w.cursorColor,
      enableInteractiveSelection: w.enableInteractiveSelection,
      style: w.style,
      decoration: _decoration(
        context,
        idle: scheme.outlineVariant,
        hint: w.hint,
        hintStyle:
            w.hintStyle ??
            w.style?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
        prefixIcon:
            w.prefix ?? (w.prefixIcon == null ? null : Icon(w.prefixIcon)),
        prefixConstraints: w.prefix == null
            ? null
            : const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: w.obscurable
            ? IconButton(
                icon: Icon(_obscured ? AppIcons.visible : AppIcons.hidden),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : w.suffix,
      ),
    );
  }

  Widget _buildInline(BuildContext context) {
    final w = widget;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final editing = w.editing;
    final field = TextFormField(
      controller: w.controller,
      focusNode: w.focusNode,
      readOnly: !editing,
      // Grows up to [maxLines] — an empty field is one line, not a box.
      minLines: 1,
      maxLines: w.maxLines,
      maxLength: w.maxLength,
      keyboardType: w.keyboardType,
      style: text.bodyLarge,
      onChanged: w.onChanged,
      validator: w.validator,
      decoration: InputDecoration(
        hintText: editing
            ? w.hint
            : (w.onEnterEdit != null
                  ? (w.viewHint ?? UiConfig.stringsOf(context).longPressToEdit)
                  : null),
        hintStyle: text.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        filled: false,
        isDense: true,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 10,
        ),
        enabledBorder: _border(
          AppInputLook.outlined,
          editing ? scheme.outline : Colors.transparent,
        ),
        focusedBorder: _border(AppInputLook.outlined, scheme.primary),
        border: _border(
          AppInputLook.outlined,
          editing ? scheme.outline : Colors.transparent,
        ),
      ),
    );
    final Widget box = editing
        ? field
        : GestureDetector(
            onLongPress: w.onEnterEdit,
            behavior: HitTestBehavior.opaque,
            child: AbsorbPointer(child: field),
          );
    if (!DetailStackedValue.of(context)) return box;
    // [_textInset] wider, sticking out on the left — its text then starts at
    // this widget's left edge, under the label.
    return LayoutBuilder(
      builder: (context, c) => OverflowBox(
        minWidth: c.maxWidth + _textInset,
        maxWidth: c.maxWidth + _textInset,
        fit: OverflowBoxFit.deferToChild,
        alignment: AlignmentDirectional.centerEnd,
        child: box,
      ),
    );
  }

  /// Where the text starts inside an inline field: the 12 content padding
  /// plus the 4 the outlined decorator adds (measured — test/shared/
  /// detail_stacked_test.dart guards it).
  static const double _textInset = AppSpacing.lg;

  Widget _buildTitle(BuildContext context) {
    final w = widget;
    final scheme = Theme.of(context).colorScheme;
    final textStyle = w.style ?? Theme.of(context).textTheme.titleMedium;
    final editing = w.editing;
    final field = TextFormField(
      controller: w.controller,
      focusNode: w.focusNode,
      readOnly: !editing,
      maxLength: w.maxLength,
      minLines: 1,
      maxLines: w.maxLines,
      style: textStyle,
      decoration: InputDecoration(
        filled: false,
        isDense: true,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        hintText: w.hint,
        hintStyle: textStyle?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        enabledBorder: _border(
          AppInputLook.underline,
          editing ? scheme.outline : Colors.transparent,
        ),
        focusedBorder: _border(AppInputLook.underline, scheme.primary),
        border: _border(
          AppInputLook.underline,
          editing ? scheme.outline : Colors.transparent,
        ),
      ),
      onChanged: w.onChanged,
      validator: w.validator,
    );
    if (editing) return field;
    return GestureDetector(
      onLongPress: w.onEnterEdit,
      behavior: HitTestBehavior.opaque,
      child: AbsorbPointer(child: field),
    );
  }

  Widget _buildSearch(BuildContext context) {
    final w = widget;
    final scheme = Theme.of(context).colorScheme;
    final controller = _controller!;
    final pill = w.look == AppInputLook.pill;
    final box = ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final decoration = InputDecoration(
          isDense: true,
          hintText: w.hint ?? UiConfig.stringsOf(context).search,
          prefixIcon: Icon(AppIcons.search, size: pill ? 18 : null),
          prefixIconConstraints: pill
              ? const BoxConstraints(minWidth: 36)
              : null,
          suffixIcon: value.text.isEmpty
              ? null
              : IconButton(
                  tooltip: w.clearTooltip ?? UiConfig.stringsOf(context).clear,
                  icon: Icon(AppIcons.close, size: pill ? 18 : null),
                  onPressed: () {
                    controller.clear();
                    w.onChanged?.call('');
                  },
                ),
          filled: pill,
          fillColor: pill ? scheme.surfaceContainerHighest : null,
          contentPadding: pill
              ? const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                )
              : null,
          border: pill
              ? _border(AppInputLook.pill, scheme.primary)
              : OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
          enabledBorder: pill
              ? _border(AppInputLook.pill, scheme.primary)
              : null,
          focusedBorder: pill
              ? OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(18)),
                  borderSide: BorderSide(color: scheme.primary),
                )
              : null,
        );
        final field = TextField(
          controller: controller,
          autofocus: w.autofocus,
          textInputAction: TextInputAction.search,
          style: pill ? Theme.of(context).textTheme.bodyMedium : null,
          onChanged: w.onChanged,
          decoration: decoration,
        );
        return pill ? SizedBox(height: 36, child: field) : field;
      },
    );
    return pill
        ? box
        : Padding(padding: w.padding ?? EdgeInsets.zero, child: box);
  }
}
