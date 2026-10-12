import 'package:flutter/material.dart';

import '../../../../core/utils/date_formatter.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/saving_goal.dart';

// Wording only: maps the BE's numbers / states to Thai strings and kit chips.
// No layout, no styling (the rows / pages hand these to kit pieces).

/// "฿52,000 จาก ฿80,000 · ครบ 15 มี.ค. 2027" (or "· ไม่มีกำหนด").
String savingGoalDueLine(
  BuildContext context,
  AppLocalizations l,
  SavingGoal g,
  String symbol,
) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final progress = l.savingGoalProgressLine(
    moneyString(context, g.savedAmount, symbol: symbol),
    moneyString(context, g.targetAmount, symbol: symbol),
  );
  final d = g.deadline == null ? null : DateTime.tryParse(g.deadline!);
  final due = d == null
      ? l.sgv2NoDeadline
      : l.sgv2DueOn(DateFormatter.medium(d, locale: locale));
  return '$progress · $due';
}

/// "ต้องออม ฿5,500/เดือน · ออมจริง ฿4,000" — null without a pace to show.
String? savingGoalPaceLine(AppLocalizations l, SavingGoal g, String symbol) {
  final needed = g.neededMonthly;
  final pace = g.paceMonthly;
  if (pace == null) return null;
  String m(double v) => '$symbol${AmountInput.format(v)}';
  return l.sgv2PaceLine(needed == null ? '-' : m(needed), m(pace));
}

/// The one status chip a goal row shows: reached / late / on track — or none.
Widget? savingGoalStatusChip(AppLocalizations l, SavingGoal g) {
  if (g.isArchived) {
    return StatusChip(
      label: l.sgv2FilterArchived,
      kind: StatusKind.archived,
      size: ChipSize.mini,
    );
  }
  if (g.isCompleted || g.pace == SavingPace.reached) {
    return StatusChip(
      label: l.savingGoalCompletedLabel,
      kind: StatusKind.done,
      size: ChipSize.mini,
    );
  }
  return switch (g.pace) {
    SavingPace.late => StatusChip(
      label: g.lateMonths == null
          ? l.sgv2PaceLate(0)
          : l.sgv2PaceLate(g.lateMonths!),
      kind: StatusKind.warning,
      size: ChipSize.mini,
    ),
    SavingPace.onTrack => StatusChip(
      label: l.sgv2PaceOnTrack,
      kind: StatusKind.active,
      size: ChipSize.mini,
    ),
    SavingPace.reached || SavingPace.none => null,
  };
}
