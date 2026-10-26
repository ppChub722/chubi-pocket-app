import 'package:flutter/material.dart';

import '../atoms/app_button.dart';
import '../molecules/amount_input.dart';
import '../molecules/hint_line.dart';
import '../templates/form_sheet.dart';
import '../tokens/app_spacing.dart';
import 'app_sheet.dart';

/// What [AppAmountSheet.show] answers: an [amount], or [cleared] (the clear
/// link was tapped).
@immutable
class AppAmountResult {
  const AppAmountResult.amount(double this.amount) : cleared = false;
  const AppAmountResult.cleared() : amount = null, cleared = true;

  final double? amount;
  final bool cleared;
}

/// One amount in a sheet (a setting such as เป้าต่อรอบ): [label] over the
/// amount input, an optional [helper] line, and [clearLabel] (shown while
/// there is an [initial]) to take the value away. Save is on once the amount
/// is above 0 and differs from [initial]; null = dismissed.
abstract final class AppAmountSheet {
  static Future<AppAmountResult?> show(
    BuildContext context, {
    required String title,
    required String label,
    required String symbol,
    required String saveLabel,
    double? initial,
    String? helper,
    String? clearLabel,
  }) => showAppSheetCustom<AppAmountResult>(
    context,
    builder: (_) => _AmountSheet(
      title: title,
      label: label,
      symbol: symbol,
      saveLabel: saveLabel,
      initial: initial,
      helper: helper,
      clearLabel: clearLabel,
    ),
  );
}

class _AmountSheet extends StatefulWidget {
  const _AmountSheet({
    required this.title,
    required this.label,
    required this.symbol,
    required this.saveLabel,
    required this.initial,
    required this.helper,
    required this.clearLabel,
  });

  final String title;
  final String label;
  final String symbol;
  final String saveLabel;
  final double? initial;
  final String? helper;
  final String? clearLabel;

  @override
  State<_AmountSheet> createState() => _AmountSheetState();
}

class _AmountSheetState extends State<_AmountSheet> {
  late final _amount = TextEditingController(
    text: widget.initial == null ? '' : AmountInput.format(widget.initial!),
  );

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double? get _parsed => AmountInput.parse(_amount.text)?.toDouble();

  bool get _changed {
    final v = _parsed;
    final i = widget.initial;
    return v != null && (i == null || (v - i).abs() >= 0.005);
  }

  @override
  Widget build(BuildContext context) {
    final v = _parsed;
    final helper = widget.helper;
    final clear = widget.clearLabel;
    return FormSheet(
      title: widget.title,
      primaryLabel: widget.saveLabel,
      dirty: _changed,
      onPrimary: v != null && v > 0 && _changed
          ? () => Navigator.of(context).pop(AppAmountResult.amount(v))
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          AmountInput(
            controller: _amount,
            currencySymbol: widget.symbol,
            label: widget.label,
            onChanged: (_) => setState(() {}),
          ),
          if (helper != null) ...[
            const SizedBox(height: AppSpacing.sm),
            HintLine(text: helper),
          ],
          if (clear != null && widget.initial != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: AppButton(
                label: clear,
                variant: AppButtonVariant.text,
                size: AppButtonSize.chip,
                onPressed: () =>
                    Navigator.of(context).pop(const AppAmountResult.cleared()),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
