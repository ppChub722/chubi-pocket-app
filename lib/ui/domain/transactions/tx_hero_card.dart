import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../ui.dart';
import '../../../features/transactions/domain/transaction_type.dart';

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
/// own chip (no 🔒), plus ✏️ (the category · wallet cards sit under the
/// card, as when editing — owner 2026-10-11):
///
///   [−รายจ่าย]                      [📅 วันนี้] ✏️
///   ข้าวมันไก่ (blank if none)            ฿1,250
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
    this.debt = false,
    this.typeBadge,
    this.accentColor,
    this.amountLocked = false,
    this.dateNote,
    this.onPickDate,
    this.symbol = '฿',
    this.editing = true,
    this.autofocus = false,
    this.compact = false,
    this.amountLabel,
    this.amountError,
    this.titleHint,
    this.showTitle = true,
    this.titlePlaceholder,
    this.titleMaxLength = TextLimits.description,
    this.onTitleTap,
    this.titleLeading,
    this.titleError,
    this.amountFocus,
    this.titleFocus,
    this.onEdit,
    this.onLongPressField,
    this.onLongPressDate,
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

  /// Debt mode (owner 2026-10-12, quick create + tx detail on a debt
  /// entry): the type chips read Paid / Received — expense = paid (I paid
  /// them), income = received — in the same colours; never a transfer.
  final bool debt;

  /// Replaces the type chips with one badge (a saving entry has no
  /// expense / income: "ออม"). Not tappable here.
  final Widget? typeBadge;

  /// Overrides the type colour (the amount, the cursor) — the saving mode's.
  final Color? accentColor;

  /// Edit mode, but the amount stays as it is (a split-sourced debt entry:
  /// only its description / note / paid label change).
  final bool amountLocked;

  /// A line under the top row, right under the date (quick create: "the
  /// date is ahead → an upcoming item", a [HintLine]). Inline layout only.
  final Widget? dateNote;

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

  /// false = no description at all (a transfer: the system names it); the
  /// amount then takes the whole row.
  final bool showTitle;

  /// The description's stand-in (title = description ?? category): the
  /// category's name, else the type's label. View mode shows it in italic,
  /// muted, where an empty description would leave a blank; edit mode keeps
  /// the input empty with it as the placeholder.
  final String? titlePlaceholder;
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

  /// View mode: a long-press on the date chip (enters edit mode and opens
  /// the date picker).
  final VoidCallback? onLongPressDate;

  /// A transaction's layout: the date pill in the chip row, description
  /// and amount side by side. Off (event rows, scheduled entries): chips,
  /// amount, title and date stacked.
  final bool inline;

  /// Inline, editing and view alike: a row under the description · amount
  /// (a transaction's wallet · category chips, owner 2026-10-12).
  final Widget? footer;

  /// Inline edit mode: a line under the amount, right-aligned (the
  /// transaction form's "ส่วนของคุณ ฿x · คนอื่นติด ฿y" once it's split).
  final Widget? amountNote;

  List<TransactionType> get _types => [
    TransactionType.expense,
    TransactionType.income,
    if (allowTransfer && !debt) TransactionType.transfer,
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final accent = accentColor ?? txTypeColor(context, type);
    final canSwitch = editing && onTypeChanged != null && typeBadge == null;
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

    // The type chips as one group on ONE line (owner 2026-10-11):
    // chips 4 apart; a large text scale shrinks the group rather than
    // wrapping it under itself.
    final chips = [
      if (typeBadge != null)
        typeBadge!
      else
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (i, t) in [
                for (final t in _types)
                  if (canSwitch || t == type) t,
              ].indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                txTypeChip(
                  context,
                  type: t,
                  selected: t == type,
                  onTap: canSwitch && t != type
                      ? () => onTypeChanged!(t)
                      : null,
                  // Dashed = tappable: the OTHER types. The chosen type does
                  // nothing on tap, so it is a plain solid chip (and so is a
                  // locked type, a saved row's — no 🔒; owner 2026-10-17).
                  dashed: canSwitch && t != type,
                  debt: debt,
                ),
              ],
            ],
          ),
        ),
    ];
    // The date: a control-height chip, read-only (no ink) in view mode.
    final datePillChip = AppChip(
      label: dateLabel,
      icon: AppIcons.date,
      onTap: editing ? onPickDate : null,
      // Opens the date picker while editing: changeable = dashed.
      dashed: editing && onPickDate != null,
    );
    final datePill = !editing && onLongPressDate != null
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: onLongPressDate,
            child: datePillChip,
          )
        : datePillChip;
    final editChip = !editing && onEdit != null
        ? CardActionButton(
            icon: AppIcons.edit,
            tooltip: l.commonEdit,
            onTap: onEdit,
          )
        : null;
    final baseAmount = compact
        ? textTheme.titleLarge
        : textTheme.headlineMedium;
    final bigAmount = baseAmount?.copyWith(
      fontWeight: FontWeight.w700,
      color: accent,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    // "฿182" as one unit: no +/− (the colour says which), the symbol hugs the
    // digits at 0.7 of their size; no "0" placeholder while typing.
    Widget amountField({TextAlign align = TextAlign.start}) => longPressable(
      AppInput.card(
        controller: amount,
        focusNode: amountFocus,
        type: AppInputType.amount,
        autofocus: autofocus && editing && !amountLocked,
        readOnly: !editing || amountLocked,
        enableInteractiveSelection: editing && !amountLocked,
        showCursor: editing && !amountLocked ? null : false,
        textAlign: align,
        style: bigAmount,
        cursorColor: scheme.primary,
        focusColor: accent,
        symbolScale: 0.7,
        currencySymbol: symbol,
        minWidth: 12,
        size: AppInputSize.hero,
        label: editing && inline ? l.transactionFormAmountLabel : null,
        labelPlacement: AppInputLabelPlacement.above,
        hint: '0',
        hintStyle: bigAmount?.copyWith(color: accent.withValues(alpha: 0.35)),
        hideHintOnFocus: true,
        underline: editing && !amountLocked,
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
        child: AppInput.card(
          controller: title,
          focusNode: titleFocus,
          readOnly: !editing || onTitleTap != null,
          onTap: editing ? onTitleTap : null,
          showCursor: editing && onTitleTap == null ? null : false,
          enableInteractiveSelection: editing && onTitleTap == null,
          maxLength: titleMaxLength,
          size: inline ? AppInputSize.hero : null,
          label: editing && inline ? l.commonDescription : null,
          labelPlacement: AppInputLabelPlacement.above,
          minLines: 1,
          maxLines: maxLines,
          textInputAction: TextInputAction.done,
          style: titleStyle,
          hint: editing
              ? (titlePlaceholder ?? titleHint ?? l.txHeroTitleHint)
              : (onLongPressField != null ? l.commonLongPressToEdit : null),
          // An underline while editing (focused in the type's colour),
          // plain text in view.
          focusColor: accent,
          underline: editing,
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

    // The kit's hero spacing ([HeroContent] / [HeroTopRow]): 16 inside,
    // 12 between rows, 8 between controls, controls 32 high.
    //
    // Inline (a transaction), editing and view alike (owner 2026-10-10 —
    // view got its type chip back, no 🔒 there):
    //   [chips]                     [📅 date] (✏️ in view)
    //   ค่าอะไร? (≤ 2 lines)           ฿120
    //                    [amountNote: ส่วนของคุณ …]
    //   [footer, view: category · wallet cards]
    // View: an empty description shows nothing.
    final List<Widget?> rows = !inline
        ? const []
        : [
            HeroTopRow(leading: chips, trailing: [datePill, ?editChip]),
            if (dateNote != null)
              Align(alignment: AlignmentDirectional.centerEnd, child: dateNote),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                LayoutBuilder(
                  // Both cells as tall as the row, each centring its
                  // content: the amount's whole cell — the right half of
                  // the row — is its tap target, not just the digits.
                  builder: (context, box) => Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // No IntrinsicHeight: a sized AppInput has a fixed-baseline value row,
                      // whose intrinsic height is not its real one.
                      Stack(
                        children: [
                          Row(
                            // Both fields are AppInputSize.hero: same label top,
                            // baseline and underline y by their own tokens.
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!showTitle)
                                Expanded(child: amountField(align: TextAlign.end))
                              else
                              Expanded(
                                // Bottom-aligned (NOT centred): the description cell is as
                                // tall as the amount cell, its underline on the same y.
                                child: Align(
                                  alignment: AlignmentDirectional.bottomStart,
                                  child: !editing && title.text.trim().isEmpty
                                      ? (titlePlaceholder == null
                                            ? const SizedBox.shrink()
                                            : longPressable(
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: AppSpacing.xs,
                                                      ),
                                                  child: Text(
                                                    titlePlaceholder!,
                                                    maxLines: 2,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                    style: titleStyle?.copyWith(
                                                      fontStyle:
                                                          FontStyle.italic,
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                    ),
                                                  ),
                                                ),
                                                titleFocus,
                                              ))
                                      : titleField(maxLines: 2),
                                ),
                              ),
                              // The amount keeps its spot however long the
                              // description wraps.
                              // A tight width: the numeric field fills its cell, so its
                              // underline spans it like the description's.
                              if (showTitle)
                                SizedBox(
                                  width: box.maxWidth * 0.48,
                                  child: amountField(align: TextAlign.end),
                                ),
                            ],
                          ),
                          // The amount's half of the row, whatever the description's height
                          // (and over its label): the whole cell focuses the amount.
                          if (editing && amountFocus != null)
                            Positioned(
                              top: 0,
                              bottom: 0,
                              right: 0,
                              width: showTitle ? box.maxWidth * 0.48 : box.maxWidth,
                              child: GestureDetector(
                                behavior: HitTestBehavior.translucent,
                                onTap: amountFocus!.requestFocus,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                ?amountErrorText,
              ],
            ),
            if (amountNote != null)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: amountNote,
              ),
            ?footer,
          ];
    // Stacked (event row, scheduled entry): chips · amount · title · date.
    final List<Widget?> stacked = [
      HeroTopRow(leading: chips, trailing: [?editChip]),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (amountLabel != null)
            Text(
              amountLabel!,
              style: textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          amountField(),
          ?amountErrorText,
        ],
      ),
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (titleLeading != null) ...[
                titleLeading!,
                const SizedBox(width: HeroSpacing.itemGap),
              ],
              Expanded(child: titleField()),
            ],
          ),
          ?titleErrorText,
        ],
      ),
      Align(alignment: Alignment.centerLeft, child: datePill),
    ];

    final body = HeroContent(rows: inline ? rows : stacked);

    // An [accentColor] (the saving mode's planning purple) washes the whole
    // card, not just the amount, so it never reads as green income.
    return HeroSurface(
      style: accentColor != null
          ? HeroStyle.tinted(color: accentColor!)
          : txHeroStyle(context, type),
      child: body,
    );
  }
}

/// A type's colour: expense red, income green, transfer neutral.
/// The transaction hero's look as one [HeroStyle]: the type colour as a wash with
/// a border in it (a transfer's is neutral). The hero card AND its compact
/// bar are built from it.
HeroStyle txHeroStyle(BuildContext context, TransactionType type) {
  return HeroStyle.tinted(
    color: txTypeColor(context, type),
    borderColor: type == TransactionType.transfer
        ? Theme.of(context).colorScheme.outline
        : null,
  );
}

Color txTypeColor(BuildContext context, TransactionType t) {
  final palette = Theme.of(context).extension<AppColors>()!;
  return switch (t) {
    TransactionType.expense => palette.expense,
    TransactionType.income => palette.income,
    TransactionType.transfer => Theme.of(context).colorScheme.onSurfaceVariant,
  };
}

/// One type chip — `[− รายจ่าย]` — as an [AppChip] at control height (owner
/// 2026-10-11): [selected] = a tinted border and faint fill in the type's
/// colour, otherwise the grey outline. [type] null = "ทั้งหมด" (the filter's
/// any-type chip) in the primary colour, no icon. [dashed]: a type that can be
/// tapped to switch to (in an edit form): dashed, no icon (room; the icon
/// shows once you pick it). The chosen type is not tappable, so it is solid.
AppChip txTypeChip(
  BuildContext context, {
  required TransactionType? type,
  required bool selected,
  VoidCallback? onTap,
  bool dashed = false,
  bool debt = false,
}) {
  final l = AppLocalizations.of(context)!;
  final (IconData? icon, label) = switch (type) {
    null => (null, l.transactionsListFilterAll),
    TransactionType.expense => (
      AppIcons.expense,
      debt ? l.debtsDirPaid : l.transactionTypeExpense,
    ),
    TransactionType.income => (
      AppIcons.income,
      debt ? l.debtsDirReceived : l.transactionTypeIncome,
    ),
    TransactionType.transfer => (AppIcons.transfer, l.transactionTypeTransfer),
  };
  return AppChip(
    label: label,
    icon: dashed && !selected ? null : icon,
    color: type == null ? null : txTypeColor(context, type),
    selected: selected,
    onTap: onTap,
    dashed: dashed,
    inset: dashed && selected,
  );
}
