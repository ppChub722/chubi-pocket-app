import 'package:flutter/material.dart';

import '../../atoms/app_button.dart';
import '../../atoms/app_input.dart';
import '../../atoms/app_input_type.dart';
import '../../molecules/amount_input.dart';
import '../../molecules/day_of_month_picker.dart';
import '../../molecules/detail_rows.dart';
import '../../organisms/app_sheet.dart';
import '../../tokens/app_spacing.dart';

class SavingAutoSaveWallet {
  const SavingAutoSaveWallet({required this.label, this.id});

  final String? id;
  final String label;
}

typedef SavingAutoSaveResult = ({double amount, int day, String? accountId});

Future<SavingAutoSaveResult?> showSavingAutoSaveSheet(
  BuildContext context, {
  required String title,
  required String amountLabel,
  required String dayLabel,
  required String walletLabel,
  required String saveLabel,
  required double amount,
  required int day,
  required SavingAutoSaveWallet wallet,
  required Future<SavingAutoSaveWallet?> Function() onPickWallet,
  String currencySymbol = '฿',
}) => showAppSheetCustom<SavingAutoSaveResult>(
  context,
  builder: (_) => SavingAutoSaveSheet(
    title: title,
    amountLabel: amountLabel,
    dayLabel: dayLabel,
    walletLabel: walletLabel,
    saveLabel: saveLabel,
    amount: amount,
    day: day,
    wallet: wallet,
    onPickWallet: onPickWallet,
    currencySymbol: currencySymbol,
  ),
);

class SavingAutoSaveSheet extends StatefulWidget {
  const SavingAutoSaveSheet({
    required this.title,
    required this.amountLabel,
    required this.dayLabel,
    required this.walletLabel,
    required this.saveLabel,
    required this.amount,
    required this.day,
    required this.wallet,
    required this.onPickWallet,
    this.currencySymbol = '฿',
    super.key,
  });

  final String title;
  final String amountLabel;
  final String dayLabel;
  final String walletLabel;
  final String saveLabel;
  final double amount;
  final int day;
  final SavingAutoSaveWallet wallet;
  final Future<SavingAutoSaveWallet?> Function() onPickWallet;
  final String currencySymbol;

  @override
  State<SavingAutoSaveSheet> createState() => _SavingAutoSaveSheetState();
}

class _SavingAutoSaveSheetState extends State<SavingAutoSaveSheet> {
  late final TextEditingController _amount = TextEditingController(
    text: widget.amount > 0 ? AmountInput.format(widget.amount) : '',
  );
  late int _day = widget.day;
  late SavingAutoSaveWallet _wallet = widget.wallet;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _value => AmountInput.parse(_amount.text) ?? 0;

  Future<void> _pickDay() async {
    final picked = await showDayOfMonthPicker(
      context,
      title: widget.dayLabel,
      selected: _day,
      allowNone: false,
    );
    final d = picked?.day;
    if (d != null && mounted) setState(() => _day = d);
  }

  Future<void> _pickWallet() async {
    final picked = await widget.onPickWallet();
    if (picked != null && mounted) setState(() => _wallet = picked);
  }

  void _save() => Navigator.pop(context, (
    amount: _value,
    day: _day,
    accountId: _wallet.id,
  ));

  @override
  Widget build(BuildContext context) {
    return AppSheetScaffold(
      title: widget.title,
      footer: AppButton(
        label: widget.saveLabel,
        size: AppButtonSize.large,
        expand: true,
        submits: true,
        onPressed: _value > 0 ? _save : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppInput(
              controller: _amount,
              label: widget.amountLabel,
              type: AppInputType.amount,
              currencySymbol: widget.currencySymbol,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.sm),
            DetailRow.pick(
              label: widget.dayLabel,
              value: dayOfMonthLabel(context, _day),
              emptyText: dayOfMonthLabel(context, null),
              horizontalInset: 0,
              onTap: _pickDay,
            ),
            DetailRow.pick(
              label: widget.walletLabel,
              value: _wallet.label,
              emptyText: _wallet.label,
              horizontalInset: 0,
              onTap: _pickWallet,
            ),
          ],
        ),
      ),
    );
  }
}
