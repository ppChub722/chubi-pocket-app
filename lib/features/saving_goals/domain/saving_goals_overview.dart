import 'package:equatable/equatable.dart';

import '../../accounts/domain/account.dart';
import 'saving_entry.dart';
import 'saving_goal.dart';

/// Header numbers of the list (BE-computed; the same as Home / More).
class SavingSummary extends Equatable {
  const SavingSummary({
    this.saved = 0,
    this.inGoals = 0,
    this.spare = 0,
    this.currency = '',
  });

  final double saved;
  final double inGoals;
  final double spare;
  final String currency;

  factory SavingSummary.fromJson(Map<String, dynamic> json) => SavingSummary(
    saved: (json['saved'] as num?)?.toDouble() ?? 0,
    inGoals: (json['in_goals'] as num?)?.toDouble() ?? 0,
    spare: (json['spare'] as num?)?.toDouble() ?? 0,
    currency: json['currency'] as String? ?? '',
  );

  @override
  List<Object?> get props => [saved, inGoals, spare, currency];
}

/// The "ยังไม่จัดสรร" bucket: money saved but not in a goal.
class SavingSpare extends Equatable {
  const SavingSpare({this.amount = 0, this.byWallet = const []});

  final double amount;
  final List<SavingWalletShare> byWallet;

  factory SavingSpare.fromJson(Map<String, dynamic> json) => SavingSpare(
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    byWallet: [
      for (final w in (json['by_wallet'] as List? ?? const []))
        SavingWalletShare.fromJson((w as Map).cast<String, dynamic>()),
    ],
  );

  @override
  List<Object?> get props => [amount, byWallet];
}

/// `GET /saving-goals`: the whole list page in one object.
class SavingGoalsOverview extends Equatable {
  const SavingGoalsOverview({
    this.summary = const SavingSummary(),
    this.spare = const SavingSpare(),
    this.goals = const [],
  });

  final SavingSummary summary;
  final SavingSpare spare;
  final List<SavingGoal> goals;

  factory SavingGoalsOverview.fromJson(Map<String, dynamic> json) =>
      SavingGoalsOverview(
        summary: SavingSummary.fromJson(
          (json['summary'] as Map? ?? const {}).cast<String, dynamic>(),
        ),
        spare: SavingSpare.fromJson(
          (json['spare'] as Map? ?? const {}).cast<String, dynamic>(),
        ),
        goals: [
          for (final g in (json['data'] as List? ?? const []))
            SavingGoal.fromJson((g as Map).cast<String, dynamic>()),
        ],
      );

  @override
  List<Object?> get props => [summary, spare, goals];
}

/// One point of the history chart: the balance at the end of a month.
class SavingHistoryPoint extends Equatable {
  const SavingHistoryPoint({required this.month, required this.cumulative});

  final String month; // YYYY-MM
  final double cumulative;

  factory SavingHistoryPoint.fromJson(Map<String, dynamic> json) =>
      SavingHistoryPoint(
        month: json['month'] as String,
        cumulative: (json['cumulative'] as num).toDouble(),
      );

  @override
  List<Object?> get props => [month, cumulative];
}

/// An active recurring ออม into this bucket.
class SavingAutoSave extends Equatable {
  const SavingAutoSave({
    required this.recurringId,
    required this.name,
    required this.amount,
    this.nextDate,
  });

  final String recurringId;
  final String name;
  final double amount;
  final String? nextDate;

  factory SavingAutoSave.fromJson(Map<String, dynamic> json) {
    final r = (json['recurring'] as Map).cast<String, dynamic>();
    return SavingAutoSave(
      recurringId: r['id'] as String,
      name: r['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      nextDate: json['next_date'] as String?,
    );
  }

  @override
  List<Object?> get props => [recurringId, name, amount, nextDate];
}

/// A goal page, or the spare bucket's page (`GET /saving-goals/spare`): then
/// [goal] is null and [spare] is set.
class SavingGoalDetail extends Equatable {
  const SavingGoalDetail({
    this.goal,
    this.spare,
    this.byWallet = const [],
    this.history = const [],
    this.autoSave = const [],
    this.entries = const SavingEntryPage(),
  });

  final SavingGoal? goal;
  final SavingSpare? spare;
  final List<SavingWalletShare> byWallet;
  final List<SavingHistoryPoint> history;
  final List<SavingAutoSave> autoSave;
  final SavingEntryPage entries;

  bool get isSpare => goal == null;

  factory SavingGoalDetail.fromJson(Map<String, dynamic> json) {
    final goal = json['goal'] is Map
        ? SavingGoal.fromJson((json['goal'] as Map).cast<String, dynamic>())
        : null;
    final spare = json['spare'] is Map
        ? SavingSpare.fromJson((json['spare'] as Map).cast<String, dynamic>())
        : null;
    return SavingGoalDetail(
      goal: goal,
      spare: spare,
      byWallet: goal != null
          ? [
              for (final w in (json['by_wallet'] as List? ?? const []))
                SavingWalletShare.fromJson((w as Map).cast<String, dynamic>()),
            ]
          : (spare?.byWallet ?? const []),
      history: [
        for (final p in (json['history'] as List? ?? const []))
          SavingHistoryPoint.fromJson((p as Map).cast<String, dynamic>()),
      ],
      autoSave: [
        for (final a in (json['auto_save'] as List? ?? const []))
          SavingAutoSave.fromJson((a as Map).cast<String, dynamic>()),
      ],
      entries: json['entries'] is Map
          ? SavingEntryPage.fromJson(
              (json['entries'] as Map).cast<String, dynamic>(),
            )
          : const SavingEntryPage(),
    );
  }

  SavingGoalDetail copyWith({SavingEntryPage? entries}) => SavingGoalDetail(
    goal: goal,
    spare: spare,
    byWallet: byWallet,
    history: history,
    autoSave: autoSave,
    entries: entries ?? this.entries,
  );

  @override
  List<Object?> get props => [
    goal,
    spare,
    byWallet,
    history,
    autoSave,
    entries,
  ];
}

/// What a saving write answers: every goal it touched, the spare bucket and
/// the entries it wrote — the page patches from it and never re-fetches.
/// (Each touched wallet's savings go to the wallet page's own cubit.)
class SavingWriteResult extends Equatable {
  const SavingWriteResult({
    this.entries = const [],
    this.goals = const [],
    this.spare = const SavingSpare(),
    this.page,
    this.walletSavings = const {},
  });

  final List<SavingEntry> entries;
  final List<SavingGoal> goals;
  final SavingSpare spare;

  /// The page the action was made from (`goal_page` or `spare_page`): the
  /// new state of the page the user is on, so a button is ONE call.
  final SavingGoalDetail? page;

  /// Each touched wallet's new savings (by wallet id) — the wallet pages and
  /// pickers patch from it.
  final Map<String, WalletSavings> walletSavings;

  factory SavingWriteResult.fromJson(Map<String, dynamic> json) =>
      SavingWriteResult(
        entries: [
          for (final e in (json['entries'] as List? ?? const []))
            SavingEntry.fromJson((e as Map).cast<String, dynamic>()),
        ],
        goals: [
          for (final g in (json['goals'] as List? ?? const []))
            SavingGoal.fromJson((g as Map).cast<String, dynamic>()),
        ],
        spare: json['spare'] is Map
            ? SavingSpare.fromJson(
                (json['spare'] as Map).cast<String, dynamic>(),
              )
            : const SavingSpare(),
        walletSavings: {
          for (final w in (json['wallets'] as List? ?? const []))
            if (w is Map && w['savings'] is Map)
              (w['wallet'] as Map)['id'] as String: WalletSavings.fromJson(
                (w['savings'] as Map).cast<String, dynamic>(),
              ),
        },
        page: json['goal_page'] is Map
            ? SavingGoalDetail.fromJson(
                (json['goal_page'] as Map).cast<String, dynamic>(),
              )
            : json['spare_page'] is Map
            ? SavingGoalDetail.fromJson(
                (json['spare_page'] as Map).cast<String, dynamic>(),
              )
            : null,
      );

  SavingGoal? goalById(String id) {
    for (final g in goals) {
      if (g.id == id) return g;
    }
    return null;
  }

  @override
  List<Object?> get props => [entries, goals, spare, page, walletSavings];
}
