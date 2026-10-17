import 'package:flutter/material.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../tx_list_filters.dart';

Future<TxPeriod?> showPeriodSheet(
  BuildContext context, {
  required TxPeriod current,
}) async {
  final l = AppLocalizations.of(context)!;
  final pick = await showPeriodPickerSheet(
    context,
    current: PeriodPick(
      PeriodUnit.values.byName(current.kind.name),
      current.start,
      current.end,
    ),
    labels: PeriodPickerLabels(
      title: l.transactionsFilterRange,
      weekHint: l.txPeriodWeekHint,
      day: l.txPeriodDay,
      week: l.txPeriodWeek,
      month: l.txPeriodMonth,
      year: l.txPeriodYear,
      all: l.transactionsRangeAll,
      custom: l.txPeriodCustom,
    ),
  );
  if (pick == null) return null;
  return switch (pick.unit) {
    PeriodUnit.all => TxPeriod.all,
    PeriodUnit.custom => TxPeriod.custom(pick.start, pick.end ?? pick.start),
    _ => TxPeriod.of(TxPeriodKind.values.byName(pick.unit.name), pick.start),
  };
}

String txPeriodUnitLabel(AppLocalizations l, TxPeriodKind k) => switch (k) {
  TxPeriodKind.day => l.txPeriodDay,
  TxPeriodKind.week => l.txPeriodWeek,
  TxPeriodKind.month => l.txPeriodMonth,
  TxPeriodKind.year => l.txPeriodYear,
  TxPeriodKind.all => l.transactionsRangeAll,
  TxPeriodKind.custom => l.txPeriodCustom,
};
