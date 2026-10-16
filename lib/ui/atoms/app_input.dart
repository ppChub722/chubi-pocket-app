import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../tokens/app/app_icons.dart';
import '../tokens/app_spacing.dart';
import 'app_input_framed.dart';
import 'app_input_type.dart';
import 'ui_config.dart';

enum _Kind { field, card, inline, title, search }

/// Where an in-card / title field's NAME label sits (owner 2026-10-12): [left]
/// of the underline (entity heroes) or [above] it (the transaction hero /
/// EntryCard two-column layout).
enum PpForgeInputLabelPlacement { left, above }

/// The GEOMETRY of an in-card / title field, fixed by tokens — not by the
/// value's font (owner 2026-10-12: "both are PpForgeInput, so they are the same
/// height; labels use the same token, so they line up"). A sized field is:
/// a label row of [labelRow] (when it has a label, placement above), then a
/// value row of at least [valueRow], the value's text BASELINE at
/// [valueBaseline] from the row's top, and the underline right under the row.
/// Two sized fields side by side therefore share their label top, their
/// baseline and their underline y — whatever their text styles (a big amount
/// vs a normal description), empty or filled, focused, TH / EN, text scale.
/// A field without a size keeps the old, font-driven geometry. Pick the SAME
/// size for fields that sit side by side.
enum PpForgeInputSize {
  /// Normal text (about 16-18 px) alone in a card.
  regular(valueRow: 34, valueBaseline: 24),

  /// A hero's name (about 20-22 px).
  title(valueRow: 44, valueBaseline: 32),

  /// A hero's big value (the amount, about 28 px) and whatever sits beside it.
  hero(valueRow: 52, valueBaseline: 38);

  const PpForgeInputSize({required this.valueRow, required this.valueBaseline});

  /// Minimum height of the value row (grows for a multi-line value).
  final double valueRow;

  /// Distance from the value row's top to the text baseline.
  final double valueBaseline;

  /// The label row's height (one line of the row-label role).
  static const double labelRow = 24;

  /// A token scaled with the user's text scale.
  static double scaled(BuildContext context, double v) =>
      MediaQuery.textScalerOf(context).scale(v).roundToDouble();
}

/// THE text input (owner 2026-10-12: one input for the whole app). Replaces
/// the old AppTextField, InlineField, InlineTitleField, AppSearchBar and every
/// raw `TextField` / `TextFormField` in the features.
///
/// The rule: **anything editable has a frame; the only exception is editing
/// inside a card, which is an underline.**
///
/// - `PpForgeInput(...)` — the FIELD: ONE outlined frame, no fill, the label
///   (optional) notched on the border. States: empty (muted outline + faint
///   placeholder) · focused (primary) · filled (neutral) · error (red + the
///   message) · disabled (dimmed) · locked 🔒 ([locked]: no frame). [dense] =
///   the in-row size. Forms, detail pages in edit mode, split rows, chat.
/// - `PpForgeInput.card(...)` — IN-CARD: an underline, no frame, no label; for
///   editing inside a card (a hero's title / amount, the quick-create card).
/// - `PpForgeInput.inline(...)` — a detail page's value: plain text in view
///   (long-press → [onEnterEdit]; an empty field shows [viewHint]), the dense
///   Field in edit. The editable-text indent rule: an editable value's text is
///   indented by the frame's padding in view AND edit (so the frame appears
///   around it without anything moving and its left edge lines up with the
///   title); a read-only value has no frame and is flush with the title.
/// - `PpForgeInput.title(...)` — a hero's name: plain text in view, underlined in
///   edit, the same height both ways.
/// - `PpForgeInput.search(...)` — the grey capsule with a leading 🔍 and a ✕ once
///   there is text; owns its controller when none is given.
///
/// Data TYPES ([PpForgeInputType]: amount, number, percent, reference) layer on
/// the Field and the in-card look. Strings (hint, tooltip, view hint) are
/// always parameters — this atom never reads the app's localisation.
class PpForgeInput extends StatefulWidget {
  const PpForgeInput({
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
    this.type = PpForgeInputType.text,
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
       labelPlacement = PpForgeInputLabelPlacement.left,
       labelWidth = null,
       size = null,
       editing = true,
       onEnterEdit = null,
       viewHint = null,
       clearTooltip = null,
       padding = null;

  /// IN-CARD field: an underline, no frame, no label — for editing inside a
  /// card (hero title / amount, the quick-create / draft card's "what for?"
  /// and ฿). Types layer on it too: `type: PpForgeInputType.amount` is the hero
  /// amount (pass a big [style]). [underline] false = plain text until it is
  /// focused or in error; [symbolScale] sizes the amount symbol relative to the
  /// digits; [hideHintOnFocus] drops the faint "0" while typing.
  const PpForgeInput.card({
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
    this.type = PpForgeInputType.text,
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
    this.labelPlacement = PpForgeInputLabelPlacement.left,
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

  /// See the class doc.
  const PpForgeInput.inline({
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
       type = PpForgeInputType.text,
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
       labelPlacement = PpForgeInputLabelPlacement.left,
       labelWidth = null,
       size = null,
       clearTooltip = null,
       padding = null;

  /// See the class doc.
  const PpForgeInput.title({
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
    this.labelPlacement = PpForgeInputLabelPlacement.left,
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
       type = PpForgeInputType.text,
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

  /// See the class doc. [hint] is what the field says when empty;
  /// [clearTooltip] is the ✕'s tooltip; [padding] the space around the
  /// capsule.
  const PpForgeInput.search({
    required this.onChanged,
    this.controller,
    this.hint,
    this.clearTooltip,
    this.autofocus = false,
    this.padding = const EdgeInsets.fromLTRB(
      PpForgeSpacing.lg,
      PpForgeSpacing.xs,
      PpForgeSpacing.lg,
      PpForgeSpacing.xs,
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
       type = PpForgeInputType.text,
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
       labelPlacement = PpForgeInputLabelPlacement.left,
       labelWidth = null,
       size = null,
       editing = true,
       onEnterEdit = null,
       viewHint = null;

  final _Kind _kind;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? label;

  /// In-card / title only: where [label] sits, and (left only) a fixed label
  /// column width so several fields' underlines start at the same x.
  final PpForgeInputLabelPlacement labelPlacement;
  final double? labelWidth;

  /// In-card / title only: the token geometry (see [PpForgeInputSize]); null =
  /// the font-driven legacy geometry.
  final PpForgeInputSize? size;
  final String? hint;
  final String? helper;

  /// Server-side error for this field (e.g. "username taken").
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

  /// Show the "n / max" counter (hidden by default).
  final bool showCounter;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onTap;

  /// A tap outside the field while it has focus (commit on blur).
  final TapRegionCallback? onTapOutside;
  final bool enabled;
  final bool readOnly;

  /// Read-only AND locked 🔒: no frame, plain text + the lock.
  final bool locked;
  final bool autofocus;

  /// A password field: ● ● ● with a show / hide toggle.
  final bool obscurable;
  final Iterable<String>? autofillHints;
  final List<TextInputFormatter>? inputFormatters;

  /// null = numbers right, text left.
  final TextAlign? textAlign;

  /// Overrides the text style (a hero's big amount, a bold name).
  final TextStyle? style;

  /// The in-row size of the Field.
  final bool dense;

  /// The data type layered on the look ([PpForgeInputType]).
  final PpForgeInputType type;

  /// Percent: decimal places allowed (default 2); reference: allow letters.
  final int? decimals;
  final bool allowLetters;

  /// [PpForgeInputType.amount]: accept a leading "-" (an adjust-balance field);
  /// every other amount stays positive-only.
  final bool allowNegative;

  /// [PpForgeInputType.amount]'s symbol; null = [PpForgeStrings.currencySymbol].
  final String? currencySymbol;

  /// A minimum width for the field (an intrinsic-width amount).
  final double? minWidth;
  final EdgeInsetsGeometry? contentPadding;

  /// Overrides the idle outline colour (an invalid value in red).
  final Color? borderColor;

  /// The focused outline / underline colour (default: the primary).
  final Color? focusColor;

  /// The caret colour (default: the theme's).
  final Color? cursorColor;

  /// Overrides the hint style (default: [style] at 40 %).
  final TextStyle? hintStyle;
  final bool? showCursor;
  final bool? enableInteractiveSelection;

  /// In-card: false = plain text, no underline until focused / in error.
  final bool underline;

  /// In-card amount: the symbol's size relative to the digits (hero ฿ = 0.7).
  final double symbolScale;

  /// Drop the placeholder while focused.
  final bool hideHintOnFocus;

  /// inline / title: false = view mode (read-only, long-press to edit).
  final bool editing;
  final VoidCallback? onEnterEdit;

  /// inline: what an empty field says in view mode when it can be edited
  /// ("long-press to edit").
  final String? viewHint;

  /// search: the ✕'s tooltip.
  final String? clearTooltip;

  /// search: space around the capsule.
  final EdgeInsetsGeometry? padding;

  @override
  State<PpForgeInput> createState() => _AppInputState();
}

class _AppInputState extends State<PpForgeInput> {
  TextEditingController? _own;

  /// PpForgeInput.inline with [PpForgeInput.obscurable]: the text is hidden until the
  /// eye is pressed.
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
    _Kind.inline => _buildInline(context),
    _Kind.title => _withLabel(context, _buildTitle(context)),
    _Kind.search => _buildSearch(context),
  };

  /// An in-card / title field's NAME label ("ชื่อ", "คำอธิบาย", "จำนวนเงิน"):
  /// the row-label text role, left of the underline or above it; the hint
  /// stays the friendly placeholder. Shown only when [label] is given (the
  /// caller passes it in create / edit, null in view).
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
    if (w.labelPlacement == PpForgeInputLabelPlacement.above) {
      return Column(
        // Hug the content: under a loose bounded parent (an Align in a row) a
        // max-size Column would take the whole height and push the field up.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          size == null
              ? text
              : SizedBox(
                  height: PpForgeInputSize.scaled(
                    context,
                    PpForgeInputSize.labelRow,
                  ),
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
      // A sized field's value baseline is fixed: the label sits on it.
      crossAxisAlignment: size == null
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.baseline,
      textBaseline: size == null ? null : TextBaseline.alphabetic,
      children: [
        w.labelWidth == null
            ? Flexible(flex: 0, child: text)
            : SizedBox(width: w.labelWidth, child: text),
        const SizedBox(width: PpForgeSpacing.md),
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
          : PpForgeInputSize.scaled(context, w.size!.valueRow),
      valueBaseline: w.size == null
          ? null
          : PpForgeInputSize.scaled(context, w.size!.valueBaseline),
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
    // The EDITABLE-TEXT INDENT rule (owner 2026-10-12): an editable value's
    // text is indented by the frame's padding in view AND edit mode, so the
    // frame appears around it without anything moving and the frame's left
    // edge lines up with the title; a read-only value (nothing to enter) has
    // no frame and its text is flush with the title.
    final flush = !editing && w.onEnterEdit == null;
    final field = TextFormField(
      controller: w.controller,
      focusNode: w.focusNode,
      readOnly: !editing,
      // Grows up to [maxLines] — an empty field is one line, not a box.
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
        // The eye, INSIDE the frame at the right end.
        suffixIcon: w.obscurable && editing
            ? IconButton(
                tooltip: null,
                icon: Icon(
                  _inlineObscured ? PpForgeIcons.visible : PpForgeIcons.hidden,
                  size: 20,
                ),
                onPressed: () =>
                    setState(() => _inlineObscured = !_inlineObscured),
              )
            : null,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 40,
          minHeight: 32,
        ),
        hintText: editing
            ? w.hint
            : (w.onEnterEdit != null
                  ? (w.viewHint ??
                        PpForgeConfig.stringsOf(context).longPressToEdit)
                  : null),
        hintStyle: text.bodyLarge?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
        ),
        filled: false,
        isDense: true,
        counterText: '',
        contentPadding: EdgeInsets.symmetric(
          horizontal: flush ? 0 : PpForgeSpacing.md,
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
            ? const EdgeInsets.symmetric(vertical: PpForgeSpacing.xs)
            : EdgeInsets.zero,
        hintText: w.hint,
        hintStyle: textStyle?.copyWith(
          color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
        ),
        // A sized title draws its own underline under the fixed value row.
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
              padding: const EdgeInsets.only(bottom: PpForgeSpacing.xs),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: PpForgeInputSize.scaled(ctx, sz.valueRow),
                ),
                child: Baseline(
                  baseline: PpForgeInputSize.scaled(ctx, sz.valueBaseline),
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

  /// The search CAPSULE: a grey pill, one height (40), on lists and in sheets.
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
          // Fills the 40-high box (without this the grey capsule only wraps
          // its text, ~34 high).
          expands: true,
          minLines: null,
          maxLines: null,
          textAlignVertical: TextAlignVertical.center,
          style: Theme.of(context).textTheme.bodyMedium,
          onChanged: w.onChanged,
          decoration: InputDecoration(
            isDense: true,
            hintText: w.hint ?? PpForgeConfig.stringsOf(context).search,
            prefixIcon: const Icon(PpForgeIcons.search, size: 18),
            prefixIconConstraints: const BoxConstraints(minWidth: 36),
            suffixIconConstraints: const BoxConstraints(
              minWidth: 40,
              minHeight: 40,
            ),
            suffixIcon: value.text.isEmpty
                ? null
                : IconButton(
                    tooltip:
                        w.clearTooltip ??
                        PpForgeConfig.stringsOf(context).clear,
                    icon: const Icon(PpForgeIcons.close, size: 18),
                    onPressed: () {
                      controller.clear();
                      w.onChanged?.call('');
                    },
                  ),
            filled: true,
            fillColor: scheme.surfaceContainerHighest,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: PpForgeSpacing.md,
              vertical: PpForgeSpacing.sm,
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
