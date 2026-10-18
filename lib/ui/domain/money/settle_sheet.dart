import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../features/accounts/domain/account.dart';
import '../../../features/transactions/domain/transaction_type.dart';
import '../../ui.dart';

/// The debt (or any outstanding amount) a [SettleSheet] settles, as display
/// data — the sheet never sees the feature's model.
@immutable
class SettleSheetData {
  const SettleSheetData({
    required this.isReceive,
    required this.outstanding,
    required this.symbol,
    this.description,
    this.initialAmount,
  });

  final bool isReceive;

  final double outstanding;

  final String symbol;

  final String? description;

  final double? initialAmount;
}

@immutable
class SettleResult {
  const SettleResult({
    required this.amount,
    required this.date,
    this.account,
    this.description,
    this.note,
  });

  final double amount;
  final DateTime date;
  final Account? account;
  final String? description;
  final String? note;
}

class SettleSheetLabels {
  const SettleSheetLabels({
    required this.title,
    required this.confirm,
    required this.amountLabel,
    required this.amountRequired,
    required this.amountOver,
    required this.all,
    required this.half,
    required this.noteLabel,
    required this.descriptionHint,
    required this.formatDate,
  });

  final String title;
  final String confirm;

  final String amountLabel;
  final String amountRequired;

  final String Function(String outstanding) amountOver;

  final String all;
  final String half;
  final String noteLabel;

  final String descriptionHint;

  final String Function(DateTime date) formatDate;
}

typedef SettleWalletField =
    Widget Function(
      BuildContext context,
      Account? selected,
      ValueChanged<Account?> onChanged,
    );

Future<SettleResult?> showSettleSheet(
  BuildContext context, {
  required SettleSheetData data,
  required SettleSheetLabels labels,
  required SettleWalletField walletField,
  required Future<String?> Function(SettleResult result) onConfirm,
  Account? initialAccount,
}) => showAppSheetCustom<SettleResult>(
  context,
  builder: (_) => SettleSheet(
    data: data,
    labels: labels,
    walletField: walletField,
    onConfirm: onConfirm,
    initialAccount: initialAccount,
  ),
);

class SettleSheet extends StatefulWidget {
  const SettleSheet({
    required this.data,
    required this.labels,
    required this.walletField,
    required this.onConfirm,
    this.initialAccount,
    super.key,
  });

  final SettleSheetData data;
  final SettleSheetLabels labels;
  final SettleWalletField walletField;
  final Future<String?> Function(SettleResult result) onConfirm;
  final Account? initialAccount;

  @override
  State<SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends State<SettleSheet> {
  late final _amount = TextEditingController(
    text: AmountInput.format(
      // An overpaid debt has a negative outstanding — never an upper bound
      // below 0 (clamp would throw).
      (widget.data.initialAmount ?? widget.data.outstanding).clamp(
        0,
        math.max(0, widget.data.outstanding),
      ),
    ),
  );
  final _description = TextEditingController();
  final _note = TextEditingController();

  late Account? _account = widget.initialAccount;
  DateTime _date = DateTime.now();
  bool _saving = false;

  String? _amountError;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final r = await showAppDatePicker(
      context,
      initial: _date,
      first: DateTime(2000),
      last: DateTime.now().add(const Duration(days: 365)),
    );
    if (r is AppDatePicked) setState(() => _date = r.date);
  }

  String? _amountProblem() {
    final n = AmountInput.parse(_amount.text);
    final out = widget.data.outstanding;
    if (n == null || n <= 0) return widget.labels.amountRequired;
    if (n > out + 0.005) {
      return widget.labels.amountOver(
        moneyString(context, out, symbol: widget.data.symbol),
      );
    }
    return null;
  }

  Future<void> _confirm() async {
    final problem = _amountProblem();
    setState(() => _amountError = problem);
    if (problem != null) return;
    String? opt(TextEditingController c) =>
        c.text.trim().isEmpty ? null : c.text.trim();
    final result = SettleResult(
      amount: AmountInput.parse(_amount.text)!,
      date: _date,
      account: _account,
      description: opt(_description),
      note: opt(_note),
    );
    setState(() => _saving = true);
    final error = await widget.onConfirm(result);
    if (!mounted) return;
    if (error == null) {
      Navigator.of(context).pop(result);
      return;
    }
    setState(() => _saving = false);
    showAppSnackBar(context, error, tone: Tone.danger);
  }

  void _fill(double amount) {
    _amount.text = AmountInput.format(amount);
    setState(() => _amountError = null);
  }

  @override
  Widget build(BuildContext context) {
    final labels = widget.labels;
    final data = widget.data;
    final out = data.outstanding;
    return FormSheet(
      title: labels.title,
      primaryLabel: labels.confirm,
      saving: _saving,
      onPrimary: _confirm,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TransactionHeroCard(
            type: data.isReceive
                ? TransactionType.income
                : TransactionType.expense,
            amount: _amount,
            amountLabel: labels.amountLabel,
            amountError: _amountError,
            title: _description,
            titleHint: data.description ?? labels.descriptionHint,
            dateLabel: labels.formatDate(_date),
            onPickDate: _pickDate,
            symbol: data.symbol,
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.xs,
            children: [
              AppChip(label: labels.all, onTap: () => _fill(out)),
              AppChip(
                label: labels.half,
                onTap: () => _fill((out / 2 * 100).roundToDouble() / 100),
              ),
            ],
          ),
          SectionCard(
            children: [
              widget.walletField(
                context,
                _account,
                (a) => setState(() => _account = a),
              ),
              const SizedBox(height: AppSpacing.md),
              AppInput(
                controller: _note,
                label: labels.noteLabel,
                prefixIcon: AppIcons.note,
                maxLines: 3,
                maxLength: TextLimits.note,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
