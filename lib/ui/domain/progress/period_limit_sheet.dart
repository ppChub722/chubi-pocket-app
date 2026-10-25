import 'package:flutter/material.dart';

import '../../ui.dart';

/// What [showPeriodLimitSheet] changed. [amountChanged]: [amount] is the
/// period's own amount, or null = back to the base amount. [noteChanged]:
/// [note] is the new note (null = none).
@immutable
class PeriodLimitResult {
  const PeriodLimitResult({
    required this.amount,
    required this.note,
    this.amountChanged = true,
    this.noteChanged = true,
  });

  final double? amount;
  final String? note;
  final bool amountChanged;
  final bool noteChanged;
}

/// One period's own amount ("แก้เฉพาะรอบนี้"): [subtitle] says which period
/// and that the others stay; two tiles show the base amount and what is used
/// so far. [resetLabel] puts the base back (shown while the period has its
/// own amount). An amount typed equal to the base is the base. Save is on
/// once something changed.
Future<PeriodLimitResult?> showPeriodLimitSheet(
  BuildContext context, {
  required String title,
  required String amountLabel,
  required String noteLabel,
  required String saveLabel,
  required String symbol,
  required double amount,
  required double baseAmount,
  required String resetLabel,
  String? subtitle,
  String? baseCaption,
  String? baseValue,
  String? usedCaption,
  String? usedValue,
  String? noteHint,
  String? note,
  bool overridden = false,
}) {
  return showAppSheetCustom<PeriodLimitResult>(
    context,
    builder: (_) => _PeriodLimitSheet(
      title: title,
      subtitle: subtitle,
      baseCaption: baseCaption,
      baseValue: baseValue,
      usedCaption: usedCaption,
      usedValue: usedValue,
      amountLabel: amountLabel,
      noteLabel: noteLabel,
      noteHint: noteHint,
      saveLabel: saveLabel,
      symbol: symbol,
      amount: amount,
      baseAmount: baseAmount,
      resetLabel: resetLabel,
      note: note,
      overridden: overridden,
    ),
  );
}

class _PeriodLimitSheet extends StatefulWidget {
  const _PeriodLimitSheet({
    required this.title,
    required this.subtitle,
    required this.baseCaption,
    required this.baseValue,
    required this.usedCaption,
    required this.usedValue,
    required this.amountLabel,
    required this.noteLabel,
    required this.noteHint,
    required this.saveLabel,
    required this.symbol,
    required this.amount,
    required this.baseAmount,
    required this.resetLabel,
    required this.note,
    required this.overridden,
  });

  final String title;
  final String? subtitle;
  final String? baseCaption;
  final String? baseValue;
  final String? usedCaption;
  final String? usedValue;
  final String amountLabel;
  final String noteLabel;
  final String? noteHint;
  final String saveLabel;
  final String symbol;
  final double amount;
  final double baseAmount;
  final String resetLabel;
  final String? note;
  final bool overridden;

  @override
  State<_PeriodLimitSheet> createState() => _PeriodLimitSheetState();
}

class _PeriodLimitSheetState extends State<_PeriodLimitSheet> {
  late final _amount = TextEditingController(
    text: AmountInput.format(widget.amount),
  );
  late final _note = TextEditingController(text: widget.note ?? '');

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _parsed => AmountInput.parse(_amount.text)?.toDouble();

  bool _same(double a, double b) => (a - b).abs() < 0.005;

  /// The period keeps its own amount after save.
  bool get _own => !_same(_parsed ?? widget.baseAmount, widget.baseAmount);

  bool get _amountChanged =>
      _own != widget.overridden ||
      (_own && !_same(_parsed ?? 0, widget.amount));

  bool get _noteChanged => _note.text.trim() != (widget.note ?? '').trim();

  bool get _valid => (_parsed ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final muted = Theme.of(context).colorScheme.onSurfaceVariant;
    final dirty = _amountChanged || _noteChanged;
    final subtitle = widget.subtitle;
    final base = widget.baseValue;
    final used = widget.usedValue;
    return FormSheet(
      title: widget.title,
      primaryLabel: widget.saveLabel,
      dirty: dirty,
      onPrimary: _valid && dirty
          ? () {
              final note = _note.text.trim();
              Navigator.of(context).pop(
                PeriodLimitResult(
                  amount: _own ? _parsed : null,
                  note: note.isEmpty ? null : note,
                  amountChanged: _amountChanged,
                  noteChanged: _noteChanged,
                ),
              );
            }
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (subtitle != null) ...[
            Text(subtitle, style: text.bodyMedium?.copyWith(color: muted)),
            const SizedBox(height: AppSpacing.md),
          ],
          if (base != null || used != null) ...[
            StatGrid(
              children: [
                if (base != null)
                  StatTile(caption: widget.baseCaption ?? '', value: base),
                if (used != null)
                  StatTile(caption: widget.usedCaption ?? '', value: used),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
          ],
          AmountInput(
            controller: _amount,
            currencySymbol: widget.symbol,
            label: widget.amountLabel,
            onChanged: (_) => setState(() {}),
          ),
          if (widget.overridden && _own)
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: HintLine(
                  text: '',
                  linkLabel: widget.resetLabel,
                  onTap: () => setState(
                    () => _amount.text = AmountInput.format(widget.baseAmount),
                  ),
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppInput.card(
            controller: _note,
            label: widget.noteLabel,
            hint: widget.noteHint,
            maxLines: 3,
            maxLength: TextLimits.note,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
