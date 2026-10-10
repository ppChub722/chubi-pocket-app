import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../tx_list_filters.dart';
import 'period_sheet.dart';

/// The transactions list's date filter — one pill (owner 2026-10-10):
/// ‹ › step one unit (a day, a week, a month, a year); the label opens the
/// period sheet ([showPeriodSheet]: unit + a picker that follows it).
/// ทั้งหมด / a custom range have no neighbours, so no arrows. Forward
/// stops at the period holding today.
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
    final next = p.canStepForward(DateTime.now()) ? p.step(1) : null;
    return PeriodPill(
      label: p.label(context),
      prevTooltip: l.txPeriodPrev,
      nextTooltip: l.txPeriodNext,
      onPrev: prev == null ? null : () => onChanged(prev),
      // ›dimmed at today's period; both null (no neighbours) hides them.
      onNext: prev != null && next != null ? () => onChanged(next) : null,
      onTap: () async {
        final picked = await showPeriodSheet(context, current: p);
        if (picked != null && picked != p) onChanged(picked);
      },
    );
  }
}
