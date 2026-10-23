import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../ui.dart';
import '../../../features/transactions/domain/transaction_type.dart';

class TransactionHeroCard extends StatelessWidget {
  const TransactionHeroCard({
    required this.type,
    required this.amount,
    required this.title,
    required this.dateLabel,
    this.onTypeChanged,
    this.allowTransfer = true,
    this.debt = false,
    this.repay = false,
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
    this.titleReadOnly = false,
    this.titleLabel,
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
    this.headerLeading,
    this.extraTypeChip,
    this.extraTypeSelected = false,
    super.key,
  });

  final TransactionType type;

  final ValueChanged<TransactionType>? onTypeChanged;

  final bool allowTransfer;

  /// Debt words on the type chips: รอรับ (expense) / รอจ่าย (income).
  final bool debt;

  /// Repayment words: จ่ายคืน (expense) / รับคืน (income). Implies [debt].
  final bool repay;

  final Widget? typeBadge;

  final Color? accentColor;

  final bool amountLocked;

  final Widget? dateNote;

  final TextEditingController amount;
  final TextEditingController title;
  final String dateLabel;

  /// Null = the date can't be changed here.
  final VoidCallback? onPickDate;

  final String symbol;

  final bool editing;
  final bool autofocus;

  final bool compact;

  final String? amountLabel;

  final String? amountError;

  final String? titleHint;

  final bool showTitle;

  final String? titlePlaceholder;
  final int titleMaxLength;

  final VoidCallback? onTitleTap;

  /// The text is made by the app (a debt's "ที่มา"): shown like a field's
  /// value but no cursor, no underline, nothing to type.
  final bool titleReadOnly;

  /// Replaces "คำอธิบาย" above the title cell.
  final String? titleLabel;

  final Widget? titleLeading;

  final String? titleError;

  final FocusNode? amountFocus;
  final FocusNode? titleFocus;

  final VoidCallback? onEdit;

  final ValueChanged<FocusNode?>? onLongPressField;

  final VoidCallback? onLongPressDate;

  final bool inline;

  final Widget? footer;

  final Widget? amountNote;

  /// Before the type chips (a debt's paid checkbox).
  final Widget? headerLeading;

  /// One more type after the built-in chips (an event's จ่ายคืน); the
  /// caller builds it and handles its tap.
  final Widget? extraTypeChip;

  /// The extra type is the picked one: the built-in chips all show unpicked.
  final bool extraTypeSelected;

  List<TransactionType> get _types => [
    TransactionType.expense,
    TransactionType.income,
    if (allowTransfer && !debt && !repay) TransactionType.transfer,
  ];

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    // The card's tint follows its selected chip (debt words: debt colours).
    final accent =
        accentColor ?? txWordsColor(context, type, debt: debt, repay: repay);
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

    final chips = [
      ?headerLeading,
      if (typeBadge != null)
        typeBadge!
      else
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final (i, t) in [
                for (final t in _types)
                  if (canSwitch || (t == type && !extraTypeSelected)) t,
              ].indexed) ...[
                if (i > 0) const SizedBox(width: AppSpacing.xs),
                txTypeChip(
                  context,
                  type: t,
                  selected: t == type && !extraTypeSelected,
                  onTap: canSwitch && (t != type || extraTypeSelected)
                      ? () => onTypeChanged!(t)
                      : null,
                  dashed: canSwitch && (t != type || extraTypeSelected),
                  debt: debt,
                  repay: repay,
                ),
              ],
              if (extraTypeChip != null) ...[
                const SizedBox(width: AppSpacing.xs),
                extraTypeChip!,
              ],
            ],
          ),
        ),
    ];
    final datePillChip = AppChip(
      label: dateLabel,
      icon: AppIcons.date,
      onTap: editing ? onPickDate : null,
      dashed: editing && onPickDate != null,
    );
    final datePill = !editing && onLongPressDate != null
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onLongPress: onLongPressDate,
            child: datePillChip,
          )
        : datePillChip;
    final baseAmount = compact
        ? textTheme.titleLarge
        : textTheme.headlineMedium;
    final bigAmount = baseAmount?.copyWith(
      fontWeight: FontWeight.w700,
      color: accent,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
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
        label: editing && inline
            ? (amountLabel ?? l.transactionFormAmountLabel)
            : null,
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
          readOnly: !editing || titleReadOnly || onTitleTap != null,
          onTap: editing ? onTitleTap : null,
          showCursor: editing && onTitleTap == null && !titleReadOnly
              ? null
              : false,
          enableInteractiveSelection:
              editing && onTitleTap == null && !titleReadOnly,
          maxLength: titleMaxLength,
          size: inline ? AppInputSize.hero : null,
          label: editing && inline ? (titleLabel ?? l.commonDescription) : null,
          labelPlacement: AppInputLabelPlacement.above,
          minLines: 1,
          maxLines: maxLines,
          textInputAction: TextInputAction.done,
          style: titleStyle,
          hint: editing
              ? (titlePlaceholder ?? titleHint ?? l.txHeroTitleHint)
              : (onLongPressField != null ? l.commonLongPressToEdit : null),
          focusColor: accent,
          underline: editing && !titleReadOnly,
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

    final titleCell = !showTitle
        ? null
        : !editing && title.text.trim().isEmpty
        ? (titlePlaceholder == null
              ? const SizedBox.shrink()
              : longPressable(
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    child: Text(
                      titlePlaceholder!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle?.copyWith(
                        fontStyle: FontStyle.italic,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  titleFocus,
                ))
        : titleField(maxLines: 2);
    final List<Widget?> inlineRows = [
      if (dateNote != null)
        HeroNote(alignment: AlignmentDirectional.centerEnd, child: dateNote!),
      HeroFields(
        // With labels above the inputs, give the labels the same air under
        // the chips as the other rows get (the label row adds ~4 itself).
        gapBefore: editing ? AppSpacing.sm : 0,
        start: titleCell,
        end: amountField(align: TextAlign.end),
        onEndAreaTap: editing && amountFocus != null
            ? amountFocus!.requestFocus
            : null,
        below: [?amountErrorText],
      ),
      if (amountNote != null)
        HeroNote(alignment: AlignmentDirectional.centerEnd, child: amountNote!),
    ];
    final List<Widget?> stacked = [
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
                SizedBox(width: HeroMetrics.of(context).itemGap),
              ],
              Expanded(child: titleField()),
            ],
          ),
          ?titleErrorText,
        ],
      ),
      Align(alignment: Alignment.centerLeft, child: datePill),
    ];

    // An [accentColor] (the saving mode's planning purple) washes the whole
    // card, not just the amount, so it never reads as green income. Debt
    // words wash it in the debt-state colour, like their chips and amount.
    return AppHeroCard(
      style: accentColor != null || debt || repay
          ? HeroStyle.tinted(color: accent)
          : txHeroStyle(context, type),
      mode: editing ? HeroCardMode.edit : HeroCardMode.view,
      header: HeroHeader(
        leading: chips,
        actions: inline ? [datePill] : const [],
        onEdit: onEdit,
      ),
      content: inline ? inlineRows : stacked,
      // A little air under the amount / description line, whose underline
      // sits right under the text.
      footer: [
        if (inline && footer != null)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: footer,
          ),
      ],
    );
  }
}

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

/// The type's colour with debt words (owner 2026-10-21): the DEBT-STATE
/// colours (`debtStateColor`), not the money ones. Recording a debt:
/// รอรับ (expense) = green, รอจ่าย (income) = red. A
/// repayment: จ่ายคืน = I owed (red), รับคืน = they owed me (green).
Color txWordsColor(
  BuildContext context,
  TransactionType t, {
  bool debt = false,
  bool repay = false,
}) {
  if (t == TransactionType.transfer || !(debt || repay)) {
    return txTypeColor(context, t);
  }
  final expense = t == TransactionType.expense;
  return debtStateColor(context, owedToMe: repay ? !expense : expense);
}

AppChip txTypeChip(
  BuildContext context, {
  required TransactionType? type,
  required bool selected,
  VoidCallback? onTap,
  bool dashed = false,
  bool debt = false,
  bool repay = false,
}) {
  final l = AppLocalizations.of(context)!;
  // Debt words (owner 2026-10-21): recording a debt says who owes whom;
  // a repayment says which way the money goes back.
  final (IconData? icon, label) = switch (type) {
    null => (null, l.transactionsListFilterAll),
    TransactionType.expense => (
      AppIcons.expense,
      repay
          ? l.debtPay
          : debt
          ? l.debtDirectionOwedToMe
          : l.transactionTypeExpense,
    ),
    TransactionType.income => (
      AppIcons.income,
      repay
          ? l.debtRepayReceive
          : debt
          ? l.debtDirectionIOwe
          : l.transactionTypeIncome,
    ),
    TransactionType.transfer => (AppIcons.transfer, l.transactionTypeTransfer),
  };
  return AppChip(
    label: label,
    icon: dashed && !selected ? null : icon,
    color: type == null
        ? null
        : txWordsColor(context, type, debt: debt, repay: repay),
    selected: selected,
    onTap: onTap,
    dashed: dashed,
    inset: dashed && selected,
  );
}
