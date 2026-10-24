import 'app_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import 'app_input_framed.dart';
import 'app_input_type.dart';
import 'ui_config.dart';

enum _Kind { field, card, inline, title, search }

enum AppInputLabelPlacement { left, above }

enum AppInputSize {
  regular(valueRow: 34, valueBaseline: 24),

  title(valueRow: 44, valueBaseline: 32),

  hero(valueRow: 48, valueBaseline: 38);

  const AppInputSize({required this.valueRow, required this.valueBaseline});

  final double valueRow;

  final double valueBaseline;

  static const double labelRow = 24;

  static double scaled(BuildContext context, double v) =>
      MediaQuery.textScalerOf(context).scale(v).roundToDouble();
}

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
    this.type = AppInputType.text,
    this.decimals,
    this.allowLetters = false,
    this.allowNegative = false,
    this.currencySymbol,
    this.minWidth,
    this.contentPadding,
    this.borderColor,
    this.focusColor,
    this.cursorColor,
    this.hintStyle,
    this.showCursor,
    this.enableInteractiveSelection,
    super.key,
  }) : _kind = _Kind.field,
       underline = true,
       symbolScale = 1.0,
       hideHintOnFocus = false,
       labelPlacement = AppInputLabelPlacement.left,
       labelWidth = null,
       size = null,
       editing = true,
       onEnterEdit = null,
       viewHint = null,
       clearTooltip = null,
       padding = null;

  const AppInput.card({
    this.controller,
    this.focusNode,
    this.hint,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.onTapOutside,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.readOnly = false,
    this.locked = false,
    this.autofocus = false,
    this.inputFormatters,
    this.textAlign,
    this.style,
    this.type = AppInputType.text,
    this.decimals,
    this.allowLetters = false,
    this.allowNegative = false,
    this.currencySymbol,
    this.minWidth,
    this.focusColor,
    this.cursorColor,
    this.hintStyle,
    this.showCursor,
    this.enableInteractiveSelection,
    this.underline = true,
    this.symbolScale = 1.0,
    this.hideHintOnFocus = false,
    this.label,
    this.labelPlacement = AppInputLabelPlacement.left,
    this.labelWidth,
    this.size,
    this.helper,
    this.obscurable = false,
    super.key,
  }) : _kind = _Kind.card,
       dense = false,
       prefixIcon = null,
       prefix = null,
       prefixText = null,
       suffix = null,
       suffixText = null,
       showCounter = false,
       autofillHints = null,
       contentPadding = null,
       borderColor = null,
       editing = true,
       onEnterEdit = null,
       viewHint = null,
       clearTooltip = null,
       padding = null;

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
    this.obscurable = false,
    this.helper,
    this.errorText,
    super.key,
  }) : _kind = _Kind.inline,
       label = null,
       prefixIcon = null,
       prefix = null,
       prefixText = null,
       suffix = null,
       suffixText = null,
       textInputAction = null,
       textCapitalization = TextCapitalization.none,
       minLines = 1,
       showCounter = false,
       onSubmitted = null,
       onTap = null,
       onTapOutside = null,
       enabled = true,
       readOnly = false,
       locked = false,
       autofocus = false,
       autofillHints = null,
       inputFormatters = null,
       textAlign = null,
       style = null,
       dense = true,
       type = AppInputType.text,
       decimals = null,
       allowLetters = false,
       allowNegative = false,
       currencySymbol = null,
       minWidth = null,
       contentPadding = null,
       borderColor = null,
       focusColor = null,
       cursorColor = null,
       hintStyle = null,
       showCursor = null,
       enableInteractiveSelection = null,
       underline = true,
       symbolScale = 1.0,
       hideHintOnFocus = false,
       labelPlacement = AppInputLabelPlacement.left,
       labelWidth = null,
       size = null,
       clearTooltip = null,
       padding = null;

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
    this.label,
    this.labelPlacement = AppInputLabelPlacement.left,
    this.labelWidth,
    this.size,
    super.key,
  }) : _kind = _Kind.title,
       helper = null,
       errorText = null,
       prefixIcon = null,
       prefix = null,
       prefixText = null,
       suffix = null,
       suffixText = null,
       keyboardType = null,
       textInputAction = null,
       textCapitalization = TextCapitalization.none,
       minLines = 1,
       showCounter = false,
       onSubmitted = null,
       onTap = null,
       onTapOutside = null,
       enabled = true,
       readOnly = false,
       locked = false,
       autofocus = false,
       obscurable = false,
       autofillHints = null,
       inputFormatters = null,
       textAlign = null,
       dense = false,
       type = AppInputType.text,
       decimals = null,
       allowLetters = false,
       allowNegative = false,
       currencySymbol = null,
       minWidth = null,
       contentPadding = null,
       borderColor = null,
       focusColor = null,
       cursorColor = null,
       hintStyle = null,
       showCursor = null,
       enableInteractiveSelection = null,
       underline = true,
       symbolScale = 1.0,
       hideHintOnFocus = false,
       viewHint = null,
       clearTooltip = null,
       padding = null;

  const AppInput.search({
    required this.onChanged,
    this.controller,
    this.hint,
    this.clearTooltip,
    this.autofocus = false,
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
       suffixText = null,
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
       onTapOutside = null,
       enabled = true,
       readOnly = false,
       locked = false,
       obscurable = false,
       autofillHints = null,
       inputFormatters = null,
       textAlign = null,
       style = null,
       dense = false,
       type = AppInputType.text,
       decimals = null,
       allowLetters = false,
       allowNegative = false,
       currencySymbol = null,
       minWidth = null,
       contentPadding = null,
       borderColor = null,
       focusColor = null,
       cursorColor = null,
       hintStyle = null,
       showCursor = null,
       enableInteractiveSelection = null,
       underline = true,
       symbolScale = 1.0,
       hideHintOnFocus = false,
       labelPlacement = AppInputLabelPlacement.left,
       labelWidth = null,
       size = null,
       editing = true,
       onEnterEdit = null,
       viewHint = null;

  final _Kind _kind;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;

  final AppInputLabelPlacement labelPlacement;
  final double? labelWidth;

  final AppInputSize? size;
  final String? hint;
  final String? helper;

  final String? errorText;
  final IconData? prefixIcon;

  /// A custom leading widget (a currency symbol, a ± toggle) instead of
  /// [prefixIcon].
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

  /// Read-only AND locked 🔒: no frame, plain text + the lock.
  final bool locked;
  final bool autofocus;

  final bool obscurable;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  final TextAlign? textAlign;

  final TextStyle? style;

  final bool dense;

  final AppInputType type;

  final int? decimals;
  final bool allowLetters;

  final bool allowNegative;

  final String? currencySymbol;

  final double? minWidth;
  final EdgeInsetsGeometry? contentPadding;

  final Color? borderColor;

  final Color? focusColor;

  final Color? cursorColor;

  final TextStyle? hintStyle;
  final bool? showCursor;
  final bool? enableInteractiveSelection;

  final bool underline;

  final double symbolScale;

  final bool hideHintOnFocus;

  final bool editing;
  final VoidCallback? onEnterEdit;

  final String? viewHint;

  final String? clearTooltip;

  final EdgeInsetsGeometry? padding;

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  TextEditingController? _own;

  bool _inlineObscured = true;

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

  static OutlineInputBorder _outline(Color c) => OutlineInputBorder(
    borderRadius: BorderRadius.circular(10),
    borderSide: BorderSide(color: c),
  );

  static UnderlineInputBorder _underline(Color c) =>
      UnderlineInputBorder(borderSide: BorderSide(color: c));

  @override
  Widget build(BuildContext context) => switch (widget._kind) {
    _Kind.field => _buildField(context),
    _Kind.card => _withLabel(context, _buildField(context)),
    _Kind.inline => ListenableBuilder(
      listenable: widget.controller!,
      builder: (context, _) => _buildInline(context),
    ),
    _Kind.title => _withLabel(context, _buildTitle(context)),
    _Kind.search => _buildSearch(context),
  };

  Widget _withLabel(BuildContext context, Widget field) {
    final w = widget;
    final label = w.label;
    if (label == null || (w._kind == _Kind.title && !w.editing)) return field;
    final theme = Theme.of(context);
    final text = Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
        color: theme.colorScheme.onSurface,
      ),
    );
    final size = w.size;
    if (w.labelPlacement == AppInputLabelPlacement.above) {
      return Column(
        // Hug the content: under a loose bounded parent (an Align in a row) a
        // max-size Column would take the whole height and push the field up.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          size == null
              ? text
              : SizedBox(
                  height: AppInputSize.scaled(context, AppInputSize.labelRow),
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: text,
                  ),
                ),
          field,
        ],
      );
    }
    return Row(
      crossAxisAlignment: size == null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.baseline,
      textBaseline: size == null ? null : TextBaseline.alphabetic,
      children: [
        w.labelWidth == null
            ? Flexible(flex: 0, child: text)
            : SizedBox(width: w.labelWidth, child: text),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: field),
      ],
    );
  }

  Widget _buildField(BuildContext context) {
    final w = widget;
    return FramedInput(
      controller: w.controller,
      focusNode: w.focusNode,
      label: w._kind == _Kind.field ? w.label : null,
      valueRow: w.size == null
          ? null
          : AppInputSize.scaled(context, w.size!.valueRow),
      valueBaseline: w.size == null
          ? null
          : AppInputSize.scaled(context, w.size!.valueBaseline),
      hint: w.hint,
      helper: w.helper,
      errorText: w.errorText,
      prefixIcon: w.prefixIcon,
      prefix: w.prefix,
      prefixText: w.prefixText,
      suffix: w.suffix,
      suffixText: w.suffixText,
      keyboardType: w.keyboardType,
      textInputAction: w.textInputAction,
      textCapitalization: w.textCapitalization,
      minLines: w.minLines,
      maxLines: w.maxLines,
      maxLength: w.maxLength,
      showCounter: w.showCounter,
      validator: w.validator,
      onChanged: w.onChanged,
      onSubmitted: w.onSubmitted,
      onTap: w.onTap,
      onTapOutside: w.onTapOutside,
      enabled: w.enabled,
      readOnly: w.readOnly,
      locked: w.locked,
      autofocus: w.autofocus,
      obscurable: w.obscurable,
      autofillHints: w.autofillHints,
      inputFormatters: w.inputFormatters,
      textAlign: w.textAlign,
      style: w.style,
      dense: w.dense,
      inCard: w._kind == _Kind.card,
      underline: w.underline,
      symbolScale: w.symbolScale,
      hideHintOnFocus: w.hideHintOnFocus,
      focusColor: w.focusColor,
      hintStyle: w.hintStyle,
      decimals: w.decimals,
      allowLetters: w.allowLetters,
      allowNegative: w.allowNegative,
      type: w.type,
      currencySymbol: w.currencySymbol,
      minWidth: w.minWidth,
      contentPadding: w.contentPadding,
      borderColor: w.borderColor,
      cursorColor: w.cursorColor,
      showCursor: w.showCursor,
      enableInteractiveSelection: w.enableInteractiveSelection,
    );
  }

  Widget _buildInline(BuildContext context) {
    final w = widget;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final editing = w.editing;
    final flush = !editing && w.onEnterEdit == null;
    // The hint is laid out even under text, so a long one would keep a
    // one-line value's box 2 lines tall: it only exists while empty.
    final hasText = w.controller!.text.isNotEmpty;
    final field = TextFormField(
      controller: w.controller,
      focusNode: w.focusNode,
      readOnly: !editing,
      minLines: 1,
      maxLines: w.maxLines,
      maxLength: w.maxLength,
      keyboardType: w.keyboardType,
      obscureText: w.obscurable && _inlineObscured,
      style: text.bodyLarge,
      onChanged: w.onChanged,
      validator: w.validator,
      decoration: InputDecoration(
        helperText: w.helper,
        helperMaxLines: 3,
        errorText: w.errorText,
        errorMaxLines: 3,
        suffixIcon: w.obscurable && editing
            ? AppIconButton.flat(
                icon: _inlineObscured ? AppIcons.visible : AppIcons.hidden,
                iconSize: AppIconButton.glyphSmall,
                onPressed: () =>
                    setState(() => _inlineObscured = !_inlineObscured),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 32,
        ),
        hintText: hasText
            ? null
            : editing
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
        contentPadding: EdgeInsets.symmetric(
          horizontal: flush ? 0 : AppSpacing.md,
          vertical: 10,
        ),
        enabledBorder: flush
            ? InputBorder.none
            : _outline(editing ? scheme.outline : Colors.transparent),
        focusedBorder: flush ? InputBorder.none : _outline(scheme.primary),
        border: flush
            ? InputBorder.none
            : _outline(editing ? scheme.outline : Colors.transparent),
      ),
    );
    return editing
        ? field
        : GestureDetector(
            onLongPress: w.onEnterEdit,
            behavior: HitTestBehavior.opaque,
            child: AbsorbPointer(child: field),
          );
  }

  Widget _buildTitle(BuildContext context) {
    final w = widget;
    final scheme = Theme.of(context).colorScheme;
    final textStyle = w.style ?? Theme.of(context).textTheme.titleMedium;
    final editing = w.editing;
    final sz = w.size;
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
        contentPadding: sz == null
            ? const EdgeInsets.symmetric(vertical: AppSpacing.xs)
            : EdgeInsets.zero,
        hintText: w.hint,
        hintStyle: textStyle?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        enabledBorder: sz == null
            ? _underline(editing ? scheme.outline : Colors.transparent)
            : InputBorder.none,
        focusedBorder: sz == null
            ? _underline(scheme.primary)
            : InputBorder.none,
        border: sz == null
            ? _underline(editing ? scheme.outline : Colors.transparent)
            : InputBorder.none,
      ),
      onChanged: w.onChanged,
      validator: w.validator,
    );
    Widget body = field;
    if (sz != null) {
      body = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        child: Builder(
          builder: (ctx) => DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: !editing
                      ? Colors.transparent
                      : Focus.of(ctx).hasFocus
                      ? scheme.primary
                      : scheme.outline,
                  width: Focus.of(ctx).hasFocus ? 2 : 1,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: AppInputSize.scaled(ctx, sz.valueRow),
                ),
                child: Baseline(
                  baseline: AppInputSize.scaled(ctx, sz.valueBaseline),
                  baselineType: TextBaseline.alphabetic,
                  child: field,
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (editing) return body;
    return GestureDetector(
      onLongPress: w.onEnterEdit,
      behavior: HitTestBehavior.opaque,
      child: AbsorbPointer(child: body),
    );
  }

  Widget _buildSearch(BuildContext context) {
    final w = widget;
    final scheme = Theme.of(context).colorScheme;
    final controller = _controller!;
    const radius = BorderRadius.all(Radius.circular(20));
    OutlineInputBorder border(Color c, double width) => OutlineInputBorder(
      borderRadius: radius,
      borderSide: width == 0
          ? BorderSide.none
          : BorderSide(color: c, width: width),
    );
    final box = ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final field = TextField(
          controller: controller,
          autofocus: w.autofocus,
          textInputAction: TextInputAction.search,
          // Fills the 40-high box (without this the grey capsule only wraps its
          // text, ~34 high).
          expands: true,
          minLines: null,
          maxLines: null,
          textAlignVertical: TextAlignVertical.center,
          style: Theme.of(context).textTheme.bodyMedium,
          onChanged: w.onChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: w.hint ?? UiConfig.stringsOf(context).search,
            prefixIcon: const Icon(AppIcons.search, size: 18),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : AppIconButton.flat(
                    tooltip:
                        w.clearTooltip ?? UiConfig.stringsOf(context).clear,
                    icon: AppIcons.close,
                    iconSize: AppIconButton.glyphXs,
                    onPressed: () {
                      controller.clear();
                      w.onChanged?.call('');
                    },
                  ),
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            border: border(Colors.transparent, 0),
            enabledBorder: border(Colors.transparent, 0),
            focusedBorder: border(scheme.primary, 1.5),
          ),
        );
        return SizedBox(height: 40, child: field);
      },
    );
    return Padding(padding: w.padding ?? EdgeInsets.zero, child: box);
  }
}
