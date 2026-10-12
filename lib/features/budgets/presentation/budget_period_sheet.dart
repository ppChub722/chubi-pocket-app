import 'package:flutter/material.dart';

import '../../../l10n/gen/app_localizations.dart';
import '../../../ui/ui.dart';
import '../domain/budget_period.dart';

/// What "แก้เฉพาะรอบนี้" returns: [amount] null = back to the base amount.
class BudgetPeriodEdit {
  const BudgetPeriodEdit({required this.amount, required this.note});

  final double? amount;
  final String? note;
}

/// The sheet for one period's own amount + note (kit [FormSheet]; a thin
/// wrapper — controllers live in the State and are disposed).
Future<BudgetPeriodEdit?> showBudgetPeriodSheet(
  BuildContext context, {
  required BudgetPeriod period,
}) {
  return showAppSheetCustom<BudgetPeriodEdit>(
    context,
    builder: (_) => _PeriodSheet(period: period),
  );
}

class _PeriodSheet extends StatefulWidget {
  const _PeriodSheet({required this.period});

  final BudgetPeriod period;

  @override
  State<_PeriodSheet> createState() => _PeriodSheetState();
}

class _PeriodSheetState extends State<_PeriodSheet> {
  late final _amount = TextEditingController(
    text: AmountInput.format(widget.period.amount),
  );
  late final _note = TextEditingController(text: widget.period.note ?? '');

  /// "Use the base amount" was tapped.
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
      _parsed != widget.period.amount ||
      _note.text.trim() != (widget.period.note ?? '');

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = widget.period;
    return FormSheet(
      title: l.bgPeriodEditTitle,
      primaryLabel: l.commonSave,
      dirty: _dirty,
      onPrimary: _valid
          ? () {
              final note = _note.text.trim();
              Navigator.of(context).pop(
                BudgetPeriodEdit(
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
            label: l.bgPeriodAmountField,
            onChanged: (_) => setState(() => _useBase = false),
          ),
          if (p.overridden || p.amount != p.baseAmount)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: AppChip(
                label: l.bgPeriodUseBase(moneyString(context, p.baseAmount)),
                selected: _useBase,
                onTap: () => setState(() {
                  _useBase = !_useBase;
                  if (_useBase) {
                    _amount.text = AmountInput.format(p.baseAmount);
                  }
                }),
              ),
            ),
          const SizedBox(height: AppSpacing.lg),
          AppInput.card(
            controller: _note,
            label: l.commonNote,
            maxLines: 3,
            maxLength: TextLimits.note,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }
}
