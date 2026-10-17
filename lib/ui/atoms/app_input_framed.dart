import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import 'app_icon_button.dart';
import 'app_input_type.dart';
import 'input_formatters.dart';
import 'ui_config.dart';

class FramedInput extends StatefulWidget {
  const FramedInput({
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
    this.suffixText,
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
    this.onTapOutside,
    this.enabled = true,
    this.readOnly = false,
    this.locked = false,
    this.autofocus = false,
    this.obscurable = false,
    this.autofillHints,
    this.inputFormatters,
    this.textAlign,
    this.style,
    this.dense = false,
    this.inCard = false,
    this.type = AppInputType.text,
    this.allowNegative = false,
    this.currencySymbol,
    this.minWidth,
    this.contentPadding,
    this.borderColor,
    this.cursorColor,
    this.showCursor,
    this.enableInteractiveSelection,
    this.underline = true,
    this.symbolScale = 1.0,
    this.hideHintOnFocus = false,
    this.valueRow,
    this.valueBaseline,
    this.focusColor,
    this.hintStyle,
    this.decimals,
    this.allowLetters = false,
    super.key,
  });

  final int? decimals;

  final bool allowLetters;

  final bool underline;

  final double symbolScale;

  final bool hideHintOnFocus;

  final double? valueRow;
  final double? valueBaseline;

  final Color? focusColor;

  final TextStyle? hintStyle;

  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;
  final String? hint;
  final String? helper;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? prefix;
  final String? prefixText;
  final Widget? suffix;
  final String? suffixText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final TextCapitalization textCapitalization;
  final int? minLines;
  final int maxLines;
  final int? maxLength;
  final bool showCounter;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;
  final TapRegionCallback? onTapOutside;
  final bool enabled;
  final bool readOnly;

  /// Read-only AND locked 🔒: no frame, plain text + the lock (a field the user
  /// may not change).
  final bool locked;
  final bool autofocus;
  final bool obscurable;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;
  final TextAlign? textAlign;
  final TextStyle? style;

  final bool dense;

  final bool inCard;
  final AppInputType type;

  final bool allowNegative;

  final String? currencySymbol;
  final double? minWidth;
  final EdgeInsetsGeometry? contentPadding;

  final Color? borderColor;
  final Color? cursorColor;
  final bool? showCursor;
  final bool? enableInteractiveSelection;

  @override
  State<FramedInput> createState() => _FramedInputState();
}

class _FramedInputState extends State<FramedInput> {
  /// A text affix (prefix / suffix text) is one line, ellipsised past a cap, so
  /// a long one can never push the field out of its frame.
  static Widget _capped(Text t) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 120),
    child: Text(
      t.data ?? "",
      style: t.style,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );

  TextEditingController? _ownController;
  FocusNode? _ownFocus;
  bool _obscured = false;

  TextEditingController get _c =>
      widget.controller ?? (_ownController ??= TextEditingController());
  FocusNode get _focus => widget.focusNode ?? (_ownFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscurable;
    _focus.addListener(_refresh);
    _c.addListener(_refresh);
  }

  @override
  void didUpdateWidget(covariant FramedInput old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      (old.controller ?? _ownController)?.removeListener(_refresh);
      _c.addListener(_refresh);
    }
    if (old.focusNode != widget.focusNode) {
      (old.focusNode ?? _ownFocus)?.removeListener(_refresh);
      _focus.addListener(_refresh);
    }
  }

  @override
  void dispose() {
    _c.removeListener(_refresh);
    _focus.removeListener(_refresh);
    _ownController?.dispose();
    _ownFocus?.dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool get _numeric =>
      widget.type == AppInputType.amount ||
      widget.type == AppInputType.number ||
      widget.type == AppInputType.percent;

  @override
  Widget build(BuildContext context) {
    final w = widget;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final style = w.style ?? text.bodyLarge;

    if (w.locked) return _locked(context, style);

    final symbol = w.type == AppInputType.amount
        ? (w.currencySymbol ?? UiConfig.stringsOf(context).currencySymbol)
        : null;
    final suffixText =
        w.suffixText ?? (w.type == AppInputType.percent ? '%' : null);
    final align = w.textAlign ?? (_numeric ? TextAlign.end : TextAlign.start);
    final formatters = <TextInputFormatter>[
      if (w.type == AppInputType.amount)
        ThousandsInputFormatter(allowNegative: w.allowNegative),
      if (w.type == AppInputType.number)
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
      if (w.type == AppInputType.percent)
        RangeInputFormatter(0, 100, decimals: w.decimals ?? 2),
      if (w.type == AppInputType.reference && !w.allowLetters)
        FilteringTextInputFormatter.digitsOnly,
      ...?w.inputFormatters,
    ];
    final keyboard =
        w.keyboardType ??
        switch (w.type) {
          AppInputType.amount ||
          AppInputType.number => TextInputType.numberWithOptions(
            decimal: true,
            signed: w.allowNegative,
          ),
          AppInputType.percent => const TextInputType.numberWithOptions(
            decimal: true,
          ),
          AppInputType.reference =>
            w.allowLetters ? TextInputType.text : TextInputType.number,
          AppInputType.text => null,
        };
    final faint = scheme.onSurfaceVariant.withValues(alpha: 0.4);

    return FormField<String>(
      initialValue: _c.text,
      validator: w.validator == null ? null : (_) => w.validator!(_c.text),
      builder: (state) {
        final error = w.errorText ?? state.errorText;
        final hasError = error != null;
        final empty = _c.text.isEmpty;
        final focused = _focus.hasFocus;
        final idle =
            w.borderColor ?? (empty ? scheme.outlineVariant : scheme.outline);

        final accent = w.focusColor ?? scheme.primary;
        InputBorder frame(Color c, double width) => w.inCard
            ? (w.underline || focused || hasError
                  ? UnderlineInputBorder(
                      borderSide: BorderSide(color: c, width: width),
                    )
                  : InputBorder.none)
            : OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: c, width: width),
              );

        // The text field itself: NO fill, NO border of its own (the theme's
        // filled decoration must not leak in — one frame only).
        final inner = TextField(
          controller: _c,
          focusNode: _focus,
          enabled: w.enabled,
          readOnly: w.readOnly,
          autofocus: w.autofocus,
          keyboardType: keyboard,
          textInputAction: w.textInputAction,
          textCapitalization: w.textCapitalization,
          textAlign: align,
          minLines: w.obscurable ? 1 : w.minLines,
          maxLines: w.obscurable ? 1 : w.maxLines,
          maxLength: w.maxLength,
          obscureText: _obscured,
          autofillHints: w.autofillHints,
          inputFormatters: formatters,
          style: style,
          cursorColor: w.cursorColor,
          showCursor: w.showCursor,
          enableInteractiveSelection: w.enableInteractiveSelection,
          onTap: w.onTap,
          onTapOutside: w.onTapOutside,
          onChanged: (v) {
            state.didChange(v);
            w.onChanged?.call(v);
          },
          onSubmitted: w.onSubmitted,
          decoration: InputDecoration(
            isCollapsed: true,
            isDense: true,
            filled: false,
            fillColor: Colors.transparent,
            hoverColor: Colors.transparent,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            errorBorder: InputBorder.none,
            focusedErrorBorder: InputBorder.none,
            disabledBorder: InputBorder.none,
            contentPadding: EdgeInsets.zero,
            hintText: w.hideHintOnFocus && focused ? null : w.hint,
            hintStyle: w.hintStyle ?? style?.copyWith(color: faint),
            counterText: '',
          ),
        );

        final affixStyle = style?.copyWith(
          color: w.enabled
              ? (style.color ?? scheme.onSurface)
              : scheme.onSurface.withValues(alpha: 0.4),
        );
        final lead = <Widget>[
          if (w.prefixIcon != null) ...[
            Icon(w.prefixIcon, size: 20, color: scheme.onSurfaceVariant),
            const SizedBox(width: AppSpacing.sm),
          ],
          ?w.prefix,
          if (symbol != null)
            Text(
              symbol,
              style: w.symbolScale == 1
                  ? affixStyle
                  : affixStyle?.copyWith(
                      fontSize: (style?.fontSize ?? 16) * w.symbolScale,
                    ),
            ),
          if (w.prefixText != null)
            _capped(Text(w.prefixText!, style: affixStyle)),
        ];
        final trail = <Widget>[
          if (suffixText != null)
            Padding(
              padding: const EdgeInsets.only(left: 4),
              child: _capped(Text(suffixText, style: affixStyle)),
            ),
          ?w.suffix,
          if (w.obscurable)
            // Does not make the field taller than its siblings: the button
            // overflows the one text line instead (same height for every
            // AppInput, with or without the eye).
            SizedBox(
              width: 40,
              height: 24,
              child: OverflowBox(
                maxWidth: 40,
                maxHeight: 40,
                child: AppIconButton.flat(
                  icon: _obscured ? AppIcons.visible : AppIcons.hidden,
                  dense: true,
                  onPressed: () => setState(() => _obscured = !_obscured),
                ),
              ),
            ),
        ];
        final Widget content;
        if (lead.isEmpty && trail.isEmpty) {
          content = inner;
        } else if (_numeric) {
          content = Align(
            alignment: switch (align) {
              TextAlign.start || TextAlign.left => Alignment.centerLeft,
              TextAlign.center => Alignment.center,
              _ => Alignment.centerRight,
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                ...lead,
                Flexible(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 12),
                    child: IntrinsicWidth(child: inner),
                  ),
                ),
                ...trail,
              ],
            ),
          );
        } else {
          content = Row(
            children: [
              ...lead,
              Expanded(child: inner),
              ...trail,
            ],
          );
        }

        Widget decorator = InputDecorator(
          isFocused: focused,
          isEmpty: empty,
          baseStyle: style,
          decoration: InputDecoration(
            labelText: w.inCard ? null : w.label,
            floatingLabelBehavior: FloatingLabelBehavior.always,
            floatingLabelStyle: TextStyle(
              color: hasError
                  ? scheme.error
                  : focused
                  ? accent
                  : scheme.onSurfaceVariant,
            ),
            helperText: w.helper,
            helperMaxLines: 3,
            errorText: error,
            errorMaxLines: 3,
            counterText: w.showCounter && w.maxLength != null
                ? '${_c.text.length}/${w.maxLength}'
                : '',
            isDense: true,
            filled: false,
            fillColor: Colors.transparent,
            hoverColor: Colors.transparent,
            contentPadding:
                w.contentPadding ??
                (w.inCard
                    // No bottom inset: the underline sits right under the text.
                    ? const EdgeInsets.only(top: AppSpacing.xs)
                    : EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: w.dense ? 10 : 14,
                      )),
            border: frame(idle, 1),
            enabledBorder: frame(idle, 1),
            focusedBorder: frame(accent, 2),
            errorBorder: frame(scheme.error, 1.5),
            focusedErrorBorder: frame(scheme.error, 2),
            disabledBorder: frame(idle, 1),
          ),
          child: w.valueRow == null || w.valueBaseline == null
              ? content
              : ConstrainedBox(
                  constraints: BoxConstraints(minHeight: w.valueRow!),
                  child: Baseline(
                    baseline: w.valueBaseline!,
                    baselineType: TextBaseline.alphabetic,
                    child: content,
                  ),
                ),
        );
        decorator = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: w.enabled ? _focus.requestFocus : null,
          child: decorator,
        );
        if (w.minWidth != null) {
          decorator = ConstrainedBox(
            constraints: BoxConstraints(minWidth: w.minWidth!),
            child: decorator,
          );
        }
        return w.enabled ? decorator : Opacity(opacity: 0.38, child: decorator);
      },
    );
  }

  Widget _locked(BuildContext context, TextStyle? style) {
    final scheme = Theme.of(context).colorScheme;
    final w = widget;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: w.dense ? 10 : 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (w.label != null)
            Text(
              w.label!,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          Row(
            children: [
              Expanded(child: Text(_c.text, style: style)),
              Icon(AppIcons.lock, size: 16, color: scheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}
