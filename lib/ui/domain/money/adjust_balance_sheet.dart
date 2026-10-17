import 'package:flutter/material.dart';

import '../../ui.dart';

typedef AdjustBalanceSheetResult = ({
  double balance,
  String? description,
  String? note,
});

/// The words of [AdjustBalanceSheet] — the caller passes its localised strings
/// (the kit never reads the app's l10n).
class AdjustBalanceStrings {
  const AdjustBalanceStrings({
    required this.title,
    required this.primaryLabel,
    required this.currentLabel,
    required this.newLabel,
    required this.diffLabel,
    required this.descriptionLabel,
    required this.noteLabel,
    required this.noChange,
    required this.willCreate,
  });

  final String title;
  final String primaryLabel;

  final String currentLabel;

  final String newLabel;
  final String diffLabel;
  final String descriptionLabel;
  final String noteLabel;

  /// Caption while nothing would change.
  final String noChange;

  final String Function(String diff) willCreate;
}

Future<AdjustBalanceSheetResult?> showAdjustBalanceFormSheet(
  BuildContext context, {
  required String name,
  required double balance,
  required String symbol,
  required AdjustBalanceStrings strings,
  Color? tint,
  bool isCredit = false,
  bool setOnly = false,
}) {
  return showAppSheetCustom<AdjustBalanceSheetResult>(
    context,
    builder: (_) => AdjustBalanceSheet(
      name: name,
      balance: balance,
      symbol: symbol,
      strings: strings,
      tint: tint,
      isCredit: isCredit,
      setOnly: setOnly,
    ),
  );
}

class AdjustBalanceSheet extends StatefulWidget {
  const AdjustBalanceSheet({
    required this.name,
    required this.balance,
    required this.symbol,
    required this.strings,
    this.tint,
    this.isCredit = false,
    this.setOnly = false,
    super.key,
  });

  final String name;
  final double balance;
  final String symbol;
  final AdjustBalanceStrings strings;
  final Color? tint;
  final bool isCredit;

  final bool setOnly;

  @override
  State<AdjustBalanceSheet> createState() => _AdjustBalanceSheetState();
}

class _AdjustBalanceSheetState extends State<AdjustBalanceSheet> {
  late final TextEditingController _controller;
  final _description = TextEditingController();
  final _note = TextEditingController();

  bool get _isCredit => widget.isCredit;

  @override
  void initState() {
    super.initState();
    final b = widget.balance;
    final shown = _isCredit ? -b : b;
    _controller = TextEditingController(
      text: widget.setOnly ? '' : AmountInput.format(shown),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _description.dispose();
    _note.dispose();
    super.dispose();
  }

  static String? _opt(TextEditingController c) {
    final v = c.text.trim();
    return v.isEmpty ? null : v;
  }

  double? get _newBalance {
    final v = AmountInput.parse(_controller.text);
    if (v == null) return null;
    return _isCredit ? -v : v;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final s = widget.strings;
    final symbol = widget.symbol;
    final tint = widget.tint ?? scheme.primary;
    final next = _newBalance;
    // Rounded to satang so float noise never reads as a change.
    final diff = next == null
        ? 0.0
        : ((next - widget.balance) * 100).roundToDouble() / 100;
    final canAdjust = next != null && (widget.setOnly || diff != 0);
    final diffText =
        '${diff > 0 ? '+' : '−'}${moneyString(context, diff.abs(), symbol: symbol)}';
    final bigAmount = text.headlineMedium?.copyWith(
      fontWeight: FontWeight.w700,
      color: tint,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    final moneyStyle = AppTypography.of(context, AppTextRole.money);

    return FormSheet(
      title: s.title,
      primaryLabel: s.primaryLabel,
      onPrimary: canAdjust
          ? () => Navigator.of(context).pop((
              balance: next,
              description: _opt(_description),
              note: _opt(_note),
            ))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AppCard(
            style: AppCardStyle.tinted,
            color: tint,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                if (!widget.setOnly) ...[
                  _CardLine(
                    label: s.currentLabel,
                    value: MoneyText(
                      widget.balance,
                      symbol: symbol,
                      style: moneyStyle?.copyWith(color: tint),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                Text(
                  s.newLabel,
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                AppInput.card(
                  controller: _controller,
                  type: AppInputType.amount,
                  allowNegative: true,
                  autofocus: true,
                  style: bigAmount,
                  cursorColor: scheme.primary,
                  focusColor: tint,
                  symbolScale: 0.7,
                  currencySymbol: symbol,
                  hint: '0',
                  hintStyle: bigAmount?.copyWith(
                    color: tint.withValues(alpha: 0.35),
                  ),
                  hideHintOnFocus: true,
                  onChanged: (_) => setState(() {}),
                ),
                if (!widget.setOnly) ...[
                  const SizedBox(height: AppSpacing.md),
                  _CardLine(
                    label: s.diffLabel,
                    value: MoneyText(
                      diff,
                      symbol: symbol,
                      tone: MoneyTone.signed,
                      hideable: false,
                      style: moneyStyle,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (!widget.setOnly) ...[
            const SizedBox(height: AppSpacing.md),
            _FieldRow(
              label: s.descriptionLabel,
              child: AppInput(
                controller: _description,
                dense: true,
                maxLength: TextLimits.description,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            _FieldRow(
              label: s.noteLabel,
              child: AppInput(
                controller: _note,
                dense: true,
                maxLength: TextLimits.note,
                maxLines: 3,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              canAdjust ? s.willCreate(diffText) : s.noChange,
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
        ],
      ),
    );
  }
}

class _CardLine extends StatelessWidget {
  const _CardLine({required this.label, required this.value});
  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        value,
      ],
    );
  }
}

class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 88,
          child: Padding(
            padding: const EdgeInsets.only(top: AppSpacing.md),
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
        Expanded(child: child),
      ],
    );
  }
}
