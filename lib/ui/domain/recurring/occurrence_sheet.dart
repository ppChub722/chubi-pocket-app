import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../ui.dart';

@immutable
class OccurrenceEdit {
  const OccurrenceEdit({required this.date, this.amount});

  final DateTime date;
  final double? amount;
}

enum OccurrenceFocus { amount, date }

Future<OccurrenceEdit?> showOccurrenceSheet(
  BuildContext context, {
  required String title,
  required String saveLabel,
  required String dateLabel,
  required DateTime date,
  required String symbol,
  required DateTime first,
  required DateTime last,
  String? amountLabel,
  double? amount,
  bool withAmount = true,
  bool amountRequired = false,
  OccurrenceFocus focus = OccurrenceFocus.amount,
}) {
  return showAppSheetCustom<OccurrenceEdit>(
    context,
    builder: (_) => _OccurrenceSheet(
      title: title,
      saveLabel: saveLabel,
      dateLabel: dateLabel,
      date: date,
      symbol: symbol,
      first: first,
      last: last,
      amountLabel: amountLabel,
      amount: amount,
      withAmount: withAmount,
      amountRequired: amountRequired,
      focus: focus,
    ),
  );
}

class _OccurrenceSheet extends StatefulWidget {
  const _OccurrenceSheet({
    required this.title,
    required this.saveLabel,
    required this.dateLabel,
    required this.date,
    required this.symbol,
    required this.first,
    required this.last,
    required this.amountLabel,
    required this.amount,
    required this.withAmount,
    required this.amountRequired,
    required this.focus,
  });

  final String title;
  final String saveLabel;
  final String dateLabel;
  final DateTime date;
  final String symbol;
  final DateTime first;
  final DateTime last;
  final String? amountLabel;
  final double? amount;
  final bool withAmount;
  final bool amountRequired;
  final OccurrenceFocus focus;

  @override
  State<_OccurrenceSheet> createState() => _OccurrenceSheetState();
}

class _OccurrenceSheetState extends State<_OccurrenceSheet> {
  late final _amount = TextEditingController(
    text: widget.amount == null ? '' : AmountInput.format(widget.amount!),
  );
  late DateTime _date = widget.date;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double? get _parsed => AmountInput.parse(_amount.text);

  bool get _valid {
    if (!widget.withAmount) return true;
    final n = _parsed;
    return widget.amountRequired ? (n ?? 0) > 0 : (n ?? 0) >= 0;
  }

  bool get _dirty => _date != widget.date || _parsed != widget.amount;

  Future<void> _pickDate() async {
    final r = await AppDatePicker.show(
      context,
      initial: _date,
      first: widget.first,
      last: widget.last,
    );
    if (mounted && r is AppDatePicked) setState(() => _date = r.date);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return FormSheet(
      title: widget.title,
      primaryLabel: widget.saveLabel,
      dirty: _dirty,
      onPrimary: _valid && _dirty
          ? () => Navigator.of(context).pop(
              OccurrenceEdit(
                date: _date,
                amount: widget.withAmount ? _parsed : null,
              ),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (widget.withAmount)
            AmountInput(
              controller: _amount,
              currencySymbol: widget.symbol,
              label: widget.amountLabel,
              autofocus: widget.focus == OccurrenceFocus.amount,
              onChanged: (_) => setState(() {}),
            ),
          if (widget.withAmount) const SizedBox(height: AppSpacing.sm),
          DetailRow.pick(
            label: widget.dateLabel,
            value: DateFormat.yMMMd(locale).format(_date),
            emptyText: '',
            onTap: _pickDate,
          ),
        ],
      ),
    );
  }
}

Future<int?> showCountSheet(
  BuildContext context, {
  required String title,
  required String label,
  required String saveLabel,
  int? initial,
  int min = 1,
  int max = 999,
}) {
  return showAppSheetCustom<int>(
    context,
    builder: (_) => _CountSheet(
      title: title,
      label: label,
      saveLabel: saveLabel,
      initial: initial,
      min: min,
      max: max,
    ),
  );
}

class _CountSheet extends StatefulWidget {
  const _CountSheet({
    required this.title,
    required this.label,
    required this.saveLabel,
    required this.initial,
    required this.min,
    required this.max,
  });

  final String title;
  final String label;
  final String saveLabel;
  final int? initial;
  final int min;
  final int max;

  @override
  State<_CountSheet> createState() => _CountSheetState();
}

class _CountSheetState extends State<_CountSheet> {
  late final _c = TextEditingController(text: '${widget.initial ?? ''}');

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  int? get _n {
    final n = int.tryParse(_c.text.trim());
    return n != null && n >= widget.min && n <= widget.max ? n : null;
  }

  @override
  Widget build(BuildContext context) {
    return FormSheet(
      title: widget.title,
      primaryLabel: widget.saveLabel,
      dirty: _n != widget.initial,
      onPrimary: _n == null ? null : () => Navigator.of(context).pop(_n),
      child: AppInput(
        controller: _c,
        label: widget.label,
        type: AppInputType.number,
        autofocus: true,
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}
