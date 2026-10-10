import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/constants/text_limits.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../../domain/transaction_type.dart';

/// The top card of every transaction form — quick create, แก้ร่าง, event
/// rows, scheduled entries — and of the transaction detail page (owner
/// design 2026-10-10):
///
/// [inline] (a transaction), editing / creating:
///
///   [−รายจ่าย] [+รายรับ] [⇄โอน]          [📅 วันนี้]
///   ค่าอะไร?                               ฿1,250
///
/// [inline], view mode (the detail page) — the same rows, only the type's
/// own chip (no 🔒), plus ✏️ and the footer:
///
///   [−รายจ่าย]                      [📅 วันนี้] ✏️
///   ข้าวมันไก่ (blank if none)            ฿1,250
///   [footer: category · wallet cards]
///
/// [amountNote] goes under the amount in both ("ส่วนของคุณ ฿x · …").
///
/// Event rows and scheduled entries stack it: chips · amount · title ·
/// date. The title line is the "what for": a record's description, a
/// scheduled entry's name. The amount never carries a +/−; the symbol hugs
/// the digits.
///
/// The card's border and wash follow the type colour (expense red, income
/// green, transfer neutral). Swiping the card left / right steps through
/// the types, like tapping the chips.
///
/// [editing] false = view mode: fields read-only and borderless; a
/// long-press on the amount or the title line calls [onLongPressField] with
/// that field's focus node (enter edit + focus).
class TxHeroCard extends StatelessWidget {
  const TxHeroCard({
    required this.type,
    required this.amount,
    required this.title,
    required this.dateLabel,
    this.onTypeChanged,
    this.allowTransfer = true,
    this.onPickDate,
    this.symbol = '฿',
    this.editing = true,
    this.autofocus = false,
    this.compact = false,
    this.amountLabel,
    this.amountError,
    this.titleHint,
    this.titleMaxLength = TextLimits.description,
    this.onTitleTap,
    this.titleLeading,
    this.titleError,
    this.amountFocus,
    this.titleFocus,
    this.onEdit,
    this.onLongPressField,
    this.inline = false,
    this.footer,
    this.amountNote,
    super.key,
  });

  final TransactionType type;

  /// Null = the type is fixed (a saved row): only the chosen chip shows.
  final ValueChanged<TransactionType>? onTypeChanged;

  /// False for project rows and scheduled entries (expense | income).
  final bool allowTransfer;

  final TextEditingController amount;
  final TextEditingController title;
  final String dateLabel;

  /// Null = the date can't be changed here.
  final VoidCallback? onPickDate;

  /// Currency symbol (a project row uses the project's currency).
  final String symbol;

  final bool editing;
  final bool autofocus;

  /// Smaller amount — for several forms on one page.
  final bool compact;

  /// Small caption above the amount ("ยอดต่องวด").
  final String? amountLabel;

  /// Shown under the amount (a failed save).
  final String? amountError;

  /// Defaults to "ค่าอะไร?".
  final String? titleHint;
  final int titleMaxLength;

  /// Non-null → the text line is picked, not typed: tapping it calls this
  /// (an event row's คำอธิบาย opens the past-descriptions picker).
  final VoidCallback? onTitleTap;

  /// Left of the title line (a scheduled entry's icon).
  final Widget? titleLeading;

  /// Shown under the title line (a required name left empty).
  final String? titleError;

  final FocusNode? amountFocus;
  final FocusNode? titleFocus;

  /// View mode: shows the ✏️ chip (enter edit mode).
  final VoidCallback? onEdit;

  /// View mode: long-press on a field → enter edit focused on it.
  final ValueChanged<FocusNode?>? onLongPressField;

  /// A transaction's layout: the date pill in the chip row, description
  /// and amount side by side. Off (event rows, scheduled entries): chips,
  /// amount, title and date stacked.
  final bool inline;

  /// Inline view mode: a row under the description · amount (the detail
  /// page's category · wallet · date chips).
  final Widget? footer;

  /// Inline edit mode: a line under the amount, right-aligned (the
  /// transaction form's "ส่วนของคุณ ฿x · คนอื่นติด ฿y" once it's split).
  final Widget? amountNote;

  List<TransactionType> get _types => [
    TransactionType.expense,
    TransactionType.income,
    if (allowTransfer) TransactionType.transfer,
  ];

  /// Swipe left (+1) → the next type, right (−1) → the previous one (no
  /// wrap).
  void _step(int by) {
    final types = _types;
    final i = types.indexOf(type);
    final next = (i + by).clamp(0, types.length - 1);
    if (next == i) return;
    HapticFeedback.selectionClick();
    onTypeChanged!(types[next]);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = txTypeColor(context, type);
    final canSwitch = editing && onTypeChanged != null;
    final titleStyle = textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
    );

    // View mode: the field itself takes no gestures (it would win the
    // long-press), the wrapper does.
    Widget longPressable(Widget child, FocusNode? focus) {
      if (editing) return child;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: onLongPressField == null
            ? null
            : () => onLongPressField!(focus),
        child: AbsorbPointer(child: child),
      );
    }

    final chips = Wrap(
      spacing: AppSpacing.xs,
      runSpacing: AppSpacing.xs,
      children: [
        for (final t in _types)
          if (canSwitch || t == type)
            TxTypeChip(
              type: t,
              selected: t == type,
              onTap: canSwitch && t != type ? () => onTypeChanged!(t) : null,
              locked: editing && onTypeChanged == null,
            ),
      ],
    );
    final datePill = _DatePill(
      label: dateLabel,
      onTap: editing ? onPickDate : null,
    );
    final editChip = !editing && onEdit != null
        ? AppIconButton(
            icon: AppIcons.edit,
            size: 32,
            tooltip: l.commonEdit,
            onPressed: onEdit,
          )
        : null;
    Widget amountField({TextAlign align = TextAlign.start}) => longPressable(
      _AmountInput(
        controller: amount,
        type: type,
        compact: compact,
        autofocus: autofocus && editing,
        editing: editing,
        symbol: symbol,
        focusNode: amountFocus,
        textAlign: align,
      ),
      amountFocus,
    );
    final amountErrorText = amountError == null
        ? null
        : Text(
            amountError!,
            style: textTheme.bodySmall?.copyWith(color: scheme.error),
          );
    Widget titleField({int maxLines = 3}) => longPressable(
      Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: TextField(
          controller: title,
          focusNode: titleFocus,
          readOnly: !editing || onTitleTap != null,
          onTap: editing ? onTitleTap : null,
          showCursor: editing && onTitleTap == null ? null : false,
          enableInteractiveSelection: editing && onTitleTap == null,
          maxLength: titleMaxLength,
          minLines: 1,
          maxLines: maxLines,
          textInputAction: TextInputAction.done,
          style: titleStyle,
          decoration: InputDecoration(
            hintText: editing
                ? (titleHint ?? l.txHeroTitleHint)
                : (onLongPressField != null ? l.commonLongPressToEdit : null),
            hintStyle: titleStyle?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            counterText: '',
            isDense: true,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            border: InputBorder.none,
            enabledBorder: editing
                ? UnderlineInputBorder(
                    borderSide: BorderSide(color: scheme.outlineVariant),
                  )
                : InputBorder.none,
            focusedBorder: editing
                ? UnderlineInputBorder(borderSide: BorderSide(color: accent))
                : InputBorder.none,
          ),
        ),
      ),
      titleFocus,
    );
    final titleErrorText = titleError == null
        ? null
        : Text(
            titleError!,
            style: textTheme.bodySmall?.copyWith(color: scheme.error),
          );

    // Inline: a transaction (owner 2026-10-10).
    final List<Widget> rows = !inline
        ? const []
        // Edit / create and view alike (owner 2026-10-10 — view got its type
        // chip back, no 🔒 there):
        //   [chips]                     [📅 date] (✏️ in view)
        //   ค่าอะไร? (≤ 2 lines)           ฿120
        //                    [amountNote: ส่วนของคุณ …]
        //   [footer, view: category · wallet cards]
        // View: an empty description shows nothing.
        : [
            Row(
              children: [
                Expanded(child: chips),
                const SizedBox(width: AppSpacing.xs),
                datePill,
                ?editChip,
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            LayoutBuilder(
              builder: (context, box) => Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: !editing && title.text.trim().isEmpty
                        ? const SizedBox.shrink()
                        : titleField(maxLines: 2),
                  ),
                  // The amount keeps its spot however long the
                  // description wraps.
                  SizedBox(
                    width: box.maxWidth * 0.48,
                    child: amountField(align: TextAlign.end),
                  ),
                ],
              ),
            ),
            ?amountErrorText,
            if (amountNote != null)
              Padding(
                padding: const EdgeInsets.only(
                  top: AppSpacing.xs,
                  right: AppSpacing.xs,
                ),
                child: Align(
                  alignment: AlignmentDirectional.centerEnd,
                  child: amountNote,
                ),
              ),
            if (!editing && footer != null) ...[
              const SizedBox(height: AppSpacing.md),
              footer!,
            ],
          ];
    // Stacked (event row, scheduled entry): chips · amount · title · date.
    final List<Widget> stacked = [
      Row(
        children: [
          Expanded(child: chips),
          // Keeps the row the same height with or without the ✏️.
          editChip ?? const SizedBox(height: 32),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      if (amountLabel != null)
        Text(
          amountLabel!,
          style: textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      amountField(),
      ?amountErrorText,
      Row(
        children: [
          if (titleLeading != null) ...[
            titleLeading!,
            const SizedBox(width: AppSpacing.sm),
          ],
          Expanded(child: titleField()),
        ],
      ),
      ?titleErrorText,
      const SizedBox(height: AppSpacing.sm),
      Align(alignment: Alignment.centerLeft, child: datePill),
    ];

    final body = Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: inline ? rows : stacked,
      ),
    );

    final card = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          accent.withValues(alpha: 0.06),
          scheme.surfaceContainerLow,
        ),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: type == TransactionType.transfer
              ? scheme.outline
              : accent.withValues(alpha: 0.6),
          width: 1.5,
        ),
      ),
      child: body,
    );
    if (!canSwitch) return card;
    return _SwipeSteps(onStep: _step, child: card);
  }
}

/// Reports a quick horizontal flick anywhere over [child] — −1 right,
/// +1 left. Watches raw pointers instead of joining the gesture arena, so
/// a flick that starts on the amount or title field still counts (a drag
/// recognizer would lose to the text field's own).
class _SwipeSteps extends StatefulWidget {
  const _SwipeSteps({required this.onStep, required this.child});
  final ValueChanged<int> onStep;
  final Widget child;

  @override
  State<_SwipeSteps> createState() => _SwipeStepsState();
}

class _SwipeStepsState extends State<_SwipeSteps> {
  int? _pointer;
  Offset _start = Offset.zero;
  Duration _startTime = Duration.zero;

  void _down(PointerDownEvent e) {
    if (_pointer != null) return;
    _pointer = e.pointer;
    _start = e.position;
    _startTime = e.timeStamp;
  }

  void _up(PointerUpEvent e) {
    if (e.pointer != _pointer) return;
    _pointer = null;
    final d = e.position - _start;
    final ms = (e.timeStamp - _startTime).inMilliseconds;
    // Mostly sideways, far enough, quick enough.
    if (d.dx.abs() < 48 || d.dx.abs() < d.dy.abs() * 2 || ms > 600) return;
    widget.onStep(d.dx < 0 ? 1 : -1);
  }

  void _cancel(PointerCancelEvent e) {
    if (e.pointer == _pointer) _pointer = null;
  }

  @override
  Widget build(BuildContext context) => Listener(
    onPointerDown: _down,
    onPointerUp: _up,
    onPointerCancel: _cancel,
    child: widget.child,
  );
}

/// A type's colour: expense red, income green, transfer neutral.
Color txTypeColor(BuildContext context, TransactionType t) {
  final palette = Theme.of(context).extension<AppColors>()!;
  return switch (t) {
    TransactionType.expense => palette.expense,
    TransactionType.income => palette.income,
    TransactionType.transfer => Theme.of(context).colorScheme.onSurfaceVariant,
  };
}

/// One small type chip — `[− รายจ่าย]`: filled in the type's colour when
/// [selected], faint text otherwise. [type] null = "ทั้งหมด" (the filter's
/// any-type chip), in a neutral ink — no icon.
class TxTypeChip extends StatelessWidget {
  const TxTypeChip({
    required this.type,
    required this.selected,
    this.onTap,
    this.locked = false,
    super.key,
  });

  final TransactionType? type;
  final bool selected;
  final VoidCallback? onTap;

  /// A saved row's type: a 🔒 on the chip and a tap-to-read tooltip ("can't
  /// change after saving") instead of silently doing nothing.
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final t = type;
    final color = t == null ? scheme.onSurface : txTypeColor(context, t);
    final fg = selected
        ? (t == TransactionType.expense || t == TransactionType.income
              ? Colors.white
              : scheme.surface)
        : scheme.onSurfaceVariant.withValues(alpha: 0.7);
    final (IconData? icon, label) = switch (t) {
      null => (null, l.transactionsListFilterAll),
      TransactionType.expense => (AppIcons.expense, l.transactionTypeExpense),
      TransactionType.income => (AppIcons.income, l.transactionTypeIncome),
      TransactionType.transfer => (
        AppIcons.transfer,
        l.transactionTypeTransfer,
      ),
    };
    final chip = Semantics(
      selected: selected,
      button: onTap != null,
      child: Material(
        color: selected ? color : Colors.transparent,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedPadding(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 6,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: fg),
                  const SizedBox(width: 2),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
                if (locked) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Icon(AppIcons.lock, size: 14, color: fg),
                ],
              ],
            ),
          ),
        ),
      ),
    );
    if (!locked) return chip;
    return Tooltip(
      message: l.txTypeLockedHint,
      triggerMode: TooltipTriggerMode.tap,
      child: chip,
    );
  }
}

/// The amount — numeric keyboard, coloured by type, sign + symbol prefix.
class _AmountInput extends StatefulWidget {
  const _AmountInput({
    required this.controller,
    required this.type,
    required this.compact,
    required this.autofocus,
    required this.editing,
    required this.symbol,
    this.focusNode,
    this.textAlign = TextAlign.start,
  });
  final TextEditingController controller;
  final TransactionType type;
  final bool compact;
  final bool autofocus;
  final bool editing;
  final String symbol;
  final FocusNode? focusNode;
  final TextAlign textAlign;

  @override
  State<_AmountInput> createState() => _AmountInputState();
}

class _AmountInputState extends State<_AmountInput> {
  /// No "0" placeholder while typing (owner 2026-10-10) — only the cursor.
  FocusNode? _own;
  FocusNode get _focus => widget.focusNode ?? (_own ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focus.addListener(_onFocus);
  }

  @override
  void didUpdateWidget(_AmountInput old) {
    super.didUpdateWidget(old);
    final before = old.focusNode ?? _own;
    if (before != null && before != _focus) {
      before.removeListener(_onFocus);
      _focus.addListener(_onFocus);
    }
  }

  void _onFocus() => setState(() {});

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _own?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final color = txTypeColor(context, widget.type);
    final base = widget.compact
        ? Theme.of(context).textTheme.titleLarge
        : Theme.of(context).textTheme.headlineMedium;
    final big = base?.copyWith(
      fontWeight: FontWeight.w700,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // "฿182" as one unit (owner 2026-10-10): no +/− (the colour says
    // which), and the symbol hugs the digits — the field is only as wide
    // as what's typed, so the pair grows together from the aligned side.
    final field = IntrinsicWidth(
      child: TextField(
        controller: widget.controller,
        focusNode: _focus,
        autofocus: widget.autofocus,
        readOnly: !widget.editing,
        enableInteractiveSelection: widget.editing,
        showCursor: widget.editing ? null : false,
        textAlign: widget.textAlign,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [ThousandsInputFormatter()],
        style: big,
        cursorColor: Theme.of(context).colorScheme.primary,
        decoration: InputDecoration(
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          isDense: true,
          constraints: const BoxConstraints(minWidth: 12),
          contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          hintText: _focus.hasFocus ? null : '0',
          hintStyle: big?.copyWith(color: color.withValues(alpha: 0.35)),
          semanticCounterText: l.transactionFormAmountLabel,
        ),
      ),
    );
    return Align(
      alignment: widget.textAlign == TextAlign.end
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: GestureDetector(
        // The symbol is part of the field: tapping it types into it.
        onTap: widget.editing ? _focus.requestFocus : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              widget.symbol,
              style: big?.copyWith(fontSize: (big.fontSize ?? 28) * 0.7),
            ),
            Flexible(child: field),
          ],
        ),
      ),
    );
  }
}

/// `[📅 วันนี้]` — small pill; null [onTap] = read-only.
class _DatePill extends StatelessWidget {
  const _DatePill({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surface,
      shape: StadiumBorder(side: BorderSide(color: scheme.outlineVariant)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: 6,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.date, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
