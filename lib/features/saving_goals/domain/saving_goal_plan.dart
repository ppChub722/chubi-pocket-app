import 'saving_goal.dart';

/// Where a goal stands against this month's plan. The enum order is the
/// "needs saving first" order.
enum SavingGoalPlan {
  short,
  done,
  noPlan,
  ongoing;

  static SavingGoalPlan of(SavingGoal g) {
    if (g.isOngoing) return SavingGoalPlan.ongoing;
    final short = g.monthShort;
    if ((short ?? 0) > 0) return SavingGoalPlan.short;
    final reached = g.status == SavingStatus.reached || g.isCompleted;
    return short == 0 || (short == null && reached)
        ? SavingGoalPlan.done
        : SavingGoalPlan.noPlan;
  }
}

/// Where a goal stands against its whole target (the list hero's filter
/// chips, 0.4.0-3). Picked from the goal's BE fields, no maths.
enum SavingGoalProgress {
  /// Has a target, not reached yet.
  short,

  /// Reached (BE status) or closed.
  done,

  /// No target (open-ended saving).
  noTarget;

  static SavingGoalProgress of(SavingGoal g) {
    if (g.targetAmount == null) return SavingGoalProgress.noTarget;
    return g.status == SavingStatus.reached || g.isCompleted
        ? SavingGoalProgress.done
        : SavingGoalProgress.short;
  }
}

/// Short goals, then done, then no plan, then ongoing; ties keep their order.
List<SavingGoal> sortedNeedFirst(List<SavingGoal> goals) {
  final ranked = [
    for (final (i, g) in goals.indexed)
      (goal: g, rank: SavingGoalPlan.of(g).index, at: i),
  ]..sort((a, b) => a.rank != b.rank ? a.rank - b.rank : a.at - b.at);
  return [for (final r in ranked) r.goal];
}
