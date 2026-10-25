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

/// A list row's line under the name: the goal's deadline ("ภายใน 31 ธ.ค.
/// 2026"). Null without one.
String? savingGoalDueCaption(
  BuildContext context,
  AppLocalizations l,
  SavingGoal g,
) {
  final due = g.deadline == null ? null : DateTime.tryParse(g.deadline!);
  if (due == null) return null;
  final locale = Localizations.localeOf(context).toLanguageTag();
  return l.fpGoalsDueBy(DateFormat.yMMMd(locale).format(due));
}

/// How far along the goal should be by now, as a share of its target: the
/// time from creation to the deadline that has passed. Null without both.
double? savingGoalPaceRatio(SavingGoal g, {DateTime? now}) {
  final created = g.createdAt;
  final due = g.deadline == null ? null : DateTime.tryParse(g.deadline!);
  if (created == null || due == null) return null;
  final span = due.difference(created).inMilliseconds;
  if (span <= 0) return null;
  final passed = (now ?? DateTime.now()).difference(created).inMilliseconds;
  return (passed / span).clamp(0.0, 1.0);
}
