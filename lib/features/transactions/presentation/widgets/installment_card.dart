import 'package:flutter/material.dart';

import '../../../../core/utils/user_currency.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../../recurring/domain/recurring.dart' show PlanInterestMethod;

/// Quick create's ผ่อน (0.4.3): what the card / pay-later wallet splits the
/// purchase into. Null [value] = paid in full.
@immutable
class QuickInstallment {
  const QuickInstallment({
    this.count = 3,
    this.method = PlanInterestMethod.none,
    this.rate = '',
    this.installmentAmount = '',
  });

  final int count;
  final PlanInterestMethod method;
  final String rate;
  final String installmentAmount;

  bool get ok =>
      count > 0 &&
      switch (method) {
        PlanInterestMethod.flat ||
        PlanInterestMethod.reducing => double.tryParse(rate.trim()) != null,
        PlanInterestMethod.fixed =>
          (AmountInput.parse(installmentAmount) ?? 0) > 0,
        _ => true,
      };

  /// `POST /transactions` `installment` (the first due date is the BE's:
  /// the card's next statement day).
  Map<String, dynamic> toJson() => {
    'count': count,
    'interest_method': method.name,
    if (method == PlanInterestMethod.flat ||
        method == PlanInterestMethod.reducing)
      'interest_rate': double.tryParse(rate.trim()),
    if (method == PlanInterestMethod.fixed)
      'installment_amount': AmountInput.parse(installmentAmount),
  };

  QuickInstallment copyWith({
    int? count,
    PlanInterestMethod? method,
    String? rate,
    String? installmentAmount,
  }) => QuickInstallment(
    count: count ?? this.count,
    method: method ?? this.method,
    rate: rate ?? this.rate,
    installmentAmount: installmentAmount ?? this.installmentAmount,
  );
}

class QuickInstallmentCard extends StatefulWidget {
  const QuickInstallmentCard({
    required this.value,
    required this.amount,
    required this.onChanged,
    super.key,
  });

  final QuickInstallment? value;

  /// The purchase's amount (the per-installment hint with no interest).
  final double? amount;
  final ValueChanged<QuickInstallment?> onChanged;

  @override
  State<QuickInstallmentCard> createState() => _QuickInstallmentCardState();
}

class _QuickInstallmentCardState extends State<QuickInstallmentCard> {
  final _count = TextEditingController(text: '3');
  final _rate = TextEditingController();
  final _fixed = TextEditingController();

  @override
  void dispose() {
    _count.dispose();
    _rate.dispose();
    _fixed.dispose();
    super.dispose();
  }

  String _method(AppLocalizations l, PlanInterestMethod m) => switch (m) {
    PlanInterestMethod.none => l.recurringPlanMethodNone,
    PlanInterestMethod.flat => l.recurringPlanMethodFlat,
    PlanInterestMethod.reducing => l.recurringPlanMethodReducing,
    PlanInterestMethod.fixed => l.recurringPlanMethodFixed,
    PlanInterestMethod.manual => l.recurringPlanMethodManual,
  };

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final v = widget.value;
    final symbol = context.readUserCurrencySymbol;
    final amount = widget.amount;
    final per =
        v != null &&
            v.method == PlanInterestMethod.none &&
            amount != null &&
            amount > 0 &&
            v.count > 0
        ? moneyString(context, amount / v.count, symbol: symbol)
        : null;
    return SectionCard(
      key: const ValueKey('quickInstallment'),
      children: [
        SettingToggleRow(
          key: const ValueKey('quickInstallmentToggle'),
          label: l.quickInstallment,
          caption: v == null ? l.quickInstallmentHint : null,
          value: v != null,
          submits: false,
          onChanged: (on) => widget.onChanged(
            on ? QuickInstallment(count: int.tryParse(_count.text) ?? 3) : null,
          ),
        ),
        if (v != null) ...[
          DetailTextField(
            label: l.recurringPlanCount,
            controller: _count,
            editing: true,
            keyboardType: TextInputType.number,
            helper: per == null ? null : '${l.recurringPlanInstallment} $per',
            onChanged: (s) =>
                widget.onChanged(v.copyWith(count: int.tryParse(s) ?? 0)),
          ),
          SettingDropdownRow<PlanInterestMethod>(
            label: l.recurringPlanMethod,
            value: _method(l, v.method),
            selected: v.method,
            submits: false,
            onSelected: (m) => widget.onChanged(v.copyWith(method: m)),
            options: [
              for (final m in PlanInterestMethod.values)
                if (m != PlanInterestMethod.manual)
                  SheetOption(value: m, label: _method(l, m)),
            ],
          ),
          if (v.method == PlanInterestMethod.flat ||
              v.method == PlanInterestMethod.reducing)
            DetailTextField(
              label: l.recurringPlanRate,
              controller: _rate,
              editing: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (s) => widget.onChanged(v.copyWith(rate: s)),
            ),
          if (v.method == PlanInterestMethod.fixed)
            DetailTextField(
              label: l.recurringPlanInstallment,
              controller: _fixed,
              editing: true,
              hint: symbol,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (s) =>
                  widget.onChanged(v.copyWith(installmentAmount: s)),
            ),
        ],
      ],
    );
  }
}
