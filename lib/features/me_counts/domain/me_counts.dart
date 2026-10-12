import 'package:equatable/equatable.dart';

/// `GET /me/counts` — the header badges and the เพิ่มเติม hub figures.
class MeCounts extends Equatable {
  const MeCounts({
    this.unreadNotifications = 0,
    this.pendingDrafts = 0,
    this.categories = 0,
    this.tags = 0,
    this.contacts = 0,
    this.activeEvents = 0,
    this.openDebts = 0,
    this.budgets = 0,
    this.goals = 0,
    this.goalsProgressPct = 0,
    this.owedToMe = 0,
    this.iOwe = 0,
    this.budgetUtilizationPct = 0,
    this.recurringActive = 0,
    this.recurringUpcoming = 0,
  });

  factory MeCounts.fromJson(Map<String, dynamic> json) {
    int i(Object? v) => v is num ? v.toInt() : 0;
    final badges = (json['badges'] as Map?) ?? const {};
    final counts = (json['counts'] as Map?) ?? const {};
    final goals = (counts['goals'] as Map?) ?? const {};
    final debts = (counts['debts_summary'] as Map?) ?? const {};
    final budgetsSummary = (counts['budgets_summary'] as Map?) ?? const {};
    final recurring = (counts['recurring'] as Map?) ?? const {};
    double d(Object? v) => v is num ? v.toDouble() : 0;
    return MeCounts(
      unreadNotifications: i(badges['unread_notifications']),
      pendingDrafts: i(badges['pending_drafts']),
      categories: i(counts['categories']),
      tags: i(counts['tags']),
      contacts: i(counts['contacts']),
      activeEvents: i(counts['active_events']),
      openDebts: i(counts['open_debts']),
      budgets: i(counts['budgets']),
      goals: i(goals['count']),
      goalsProgressPct: goals['progress_pct'] is num
          ? (goals['progress_pct'] as num).toDouble()
          : 0,
      owedToMe: d(debts['owed_to_me']),
      iOwe: d(debts['i_owe']),
      budgetUtilizationPct: d(budgetsSummary['utilization_pct']),
      recurringActive: i(recurring['active_count']),
      recurringUpcoming: i(recurring['upcoming_count']),
    );
  }

  final int unreadNotifications;
  final int pendingDrafts;
  final int categories;
  final int tags;
  final int contacts;
  final int activeEvents;
  final int openDebts;
  final int budgets;
  final int goals;
  final double goalsProgressPct;
  final double owedToMe;
  final double iOwe;
  final double budgetUtilizationPct;
  final int recurringActive;

  /// Upcoming recurring items dated within the next 14 days.
  final int recurringUpcoming;

  @override
  List<Object?> get props => [
    unreadNotifications,
    pendingDrafts,
    categories,
    tags,
    contacts,
    activeEvents,
    openDebts,
    budgets,
    goals,
    goalsProgressPct,
    owedToMe,
    iOwe,
    budgetUtilizationPct,
    recurringActive,
    recurringUpcoming,
  ];
}
