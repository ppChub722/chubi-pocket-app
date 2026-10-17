import 'package:flutter/material.dart';

import '../../ui.dart';

@immutable
class PeriodLimitResult {
  const PeriodLimitResult({required this.amount, required this.note});

  final double? amount;
  final String? note;
}

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
  String? note,
  bool overridden = false,
}) {
  return showAppSheetCustom<PeriodLimitResult>(
    context,
    builder: (_) => _PeriodLimitSheet(
      title: title,
      amountLabel: amountLabel,
      noteLabel: noteLabel,
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
    required this.amountLabel,
    required this.noteLabel,
    required this.saveLabel,
    required this.symbol,
    required this.amount,
    required this.baseAmount,
    required this.resetLabel,
    required this.note,
    required this.overridden,
  });

  final String title;
  final String amountLabel;
  final String noteLabel;
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

  bool _useBase = false;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  double? get _parsed => AmountInput.parse(_amount.text);

  bool get _valid => _useBase || ((_parsed ?? 0) > 0);

  bool get _dirty =>
      _useBase ||
      _parsed != widget.amount ||
      _note.text.trim() != (widget.note ?? '');

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: widget.title,
      primaryLabel: widget.saveLabel,
      dirty: _dirty,
      onPrimary: _valid
          ? () {
              final note = _note.text.trim();
              Navigator.of(context).pop(
                PeriodLimitResult(
                  amount: _useBase ? null : _parsed,
                  note: note.isEmpty ? null : note,
                ),
              );
            }
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AmountInput(
            controller: _amount,
            currencySymbol: widget.symbol,
            label: widget.amountLabel,
            onChanged: (_) => setState(() => _useBase = false),
          ),
          if (widget.overridden || widget.amount != widget.baseAmount)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: AppChip(
                label: widget.resetLabel,
                selected: _useBase,
                onTap: () => setState(() {
                  _useBase = !_useBase;
                  if (_useBase) {
                    _amount.text = AmountInput.format(widget.baseAmount);
                  }
                }),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppInput.card(
            controller: _note,
            label: widget.noteLabel,
            maxLines: 3,
            maxLength: TextLimits.note,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
