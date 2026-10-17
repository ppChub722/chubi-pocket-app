import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/gen/app_localizations.dart';
import '../../../../ui/ui.dart';
import '../../domain/saving_goal.dart';

Widget? savingGoalStatusChip(AppLocalizations l, SavingGoal g) {
  if (g.isArchived) {
    return StatusChip(label: l.sgv2FilterArchived, kind: StatusKind.archived);
  }
  if (g.isCompleted) {
    return StatusChip(label: l.fpGoalsClosed, kind: StatusKind.done);
  }
  if (g.isOngoing) {
    return StatusChip(label: l.fpGoalsGroupOngoing, kind: StatusKind.active);
  }
  return switch (g.status) {
    SavingStatus.reached => StatusChip(
      label: l.fpGoalsReached,
      kind: StatusKind.done,
    ),
    SavingStatus.behind => StatusChip(
      label: (g.behindMonths ?? 0) > 0
          ? l.sgv2PaceLate(g.behindMonths!)
          : l.fpGoalsBehind,
      kind: StatusKind.warning,
    ),
    SavingStatus.onTrack => StatusChip(
      label: l.sgv2PaceOnTrack,
      kind: StatusKind.active,
    ),
    SavingStatus.none => null,
  };
}

({String label, Tone tone})? savingGoalEtaBadge(
  BuildContext context,
  AppLocalizations l,
  SavingGoal g,
) {
  if (g.isArchived) {
    return (label: l.sgv2FilterArchived, tone: Tone.neutral);
  }
  if (g.isCompleted) return (label: l.fpGoalsClosed, tone: Tone.success);
  if (g.status == SavingStatus.reached) {
    return (label: l.savingGoalCompletedLabel, tone: Tone.success);
  }
  final locale = Localizations.localeOf(context).toLanguageTag();
  final eta = g.etaDate == null ? null : DateTime.tryParse(g.etaDate!);
  final month = eta == null ? null : DateFormat.yMMM(locale).format(eta);
  final months = g.behindMonths ?? 0;
  return switch (g.status) {
    SavingStatus.behind when month != null && months > 0 => (
      label: l.fpGoalsEtaBehind(month, months),
      tone: Tone.warning,
    ),
    SavingStatus.behind when month != null => (
      label: l.fpGoalsEtaOn(month),
      tone: Tone.warning,
    ),
    SavingStatus.behind => (
      label: months > 0 ? l.sgv2PaceLate(months) : l.fpGoalsBehind,
      tone: Tone.warning,
    ),
    SavingStatus.onTrack when month != null => (
      label: l.fpGoalsEtaOn(month),
      tone: Tone.success,
    ),
    _ => null,
  };
}

String savingAutoSaveCaption(
  BuildContext context,
  AppLocalizations l,
  SavingAutoSave a,
  String symbol,
) => l.fpGoalsAutoCaption(
  dayOfMonthLabel(context, a.day),
  moneyString(context, a.amount, symbol: symbol),
  a.wallet?.name ?? l.fpGoalsNoWallet,
);
