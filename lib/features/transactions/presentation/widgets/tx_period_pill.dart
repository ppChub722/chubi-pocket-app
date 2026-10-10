import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../shared/widgets/ui.dart';
import '../tx_list_filters.dart';

/// The transactions period as one pill — the list's top and the filter
/// sheet's ช่วงเวลา (owner 2026-10-10):
/// - a month: [MonthPill] (‹ › step a month, the label opens the month
///   grid);
/// - a week / year: [PeriodPill], ‹ › step it, [onTapLabel] on the label;
/// - ทั้งหมด / a custom range: no neighbours, so no arrows.
/// Forward stops at the period holding today.
class TxPeriodPill extends StatelessWidget {
  const TxPeriodPill({
    required this.period,
    required this.onChanged,
    this.onTapLabel,
    super.key,
  });

  final TxPeriod period;
  final ValueChanged<TxPeriod> onChanged;

  /// The label of a non-month period (a month's opens its grid).
  final VoidCallback? onTapLabel;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final p = period;
    final now = DateTime.now();
    if (p.kind == TxPeriodKind.month) {
      return MonthPill(
        month: p.start,
        last: now,
        onChanged: (m) => onChanged(TxPeriod.month(m)),
      );
    }
    final prev = p.step(-1);
    final next = p.canStepForward(now) ? p.step(1) : null;
    return PeriodPill(
      label: p.label(context),
      prevTooltip: l.txPeriodPrev,
      nextTooltip: l.txPeriodNext,
      onPrev: prev == null ? null : () => onChanged(prev),
      // ›dimmed at today's period; both null (no neighbours) hides them.
      onNext: prev != null && next != null ? () => onChanged(next) : null,
      onTap: onTapLabel,
    );
  }
}
