import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../tx_list_filters.dart';
import 'period_sheet.dart';

class TxPeriodPill extends StatelessWidget {
  const TxPeriodPill({
    required this.period,
    required this.onChanged,
    super.key,
  });

  final TxPeriod period;
  final ValueChanged<TxPeriod> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = period;
    final prev = p.step(-1);
    final next = p.step(1);
    return StepperPill(
      label: p.label(context),
      prevTooltip: l.txPeriodPrev,
      nextTooltip: l.txPeriodNext,
      onPrev: prev == null ? null : () => onChanged(prev),
      onNext: prev != null && next != null ? () => onChanged(next) : null,
      onTap: () async {
        final picked = await showPeriodSheet(context, current: p);
        if (picked != null && picked != p) onChanged(picked);
      },
    );
  }
}
