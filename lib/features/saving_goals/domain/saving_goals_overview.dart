import 'package:equatable/equatable.dart';

import '../../accounts/domain/account.dart';
import 'saving_entry.dart';
import 'saving_goal.dart';

class SavingSummary extends Equatable {
  const SavingSummary({
    this.saved = 0,
    this.inGoals = 0,
    this.spare = 0,
    this.currency = '',
    this.savedTotal = 0,
    this.monthShortTotal = 0,
    this.monthPlanTotal = 0,
    this.monthSavedTotal = 0,
    this.unallocated = 0,
  });

  final double saved;
  final double inGoals;
  final double spare;
  final String currency;

  final double savedTotal;

  final double monthShortTotal;

  final double monthPlanTotal;
  final double monthSavedTotal;

  final double unallocated;

  factory SavingSummary.fromJson(Map<String, dynamic> json) => SavingSummary(
    saved: (json['saved'] as num?)?.toDouble() ?? 0,
    inGoals: (json['in_goals'] as num?)?.toDouble() ?? 0,
    spare: (json['spare'] as num?)?.toDouble() ?? 0,
    currency: json['currency'] as String? ?? '',
    savedTotal: (json['saved_total'] as num?)?.toDouble() ?? 0,
    monthShortTotal: (json['month_short_total'] as num?)?.toDouble() ?? 0,
    monthPlanTotal: (json['month_plan_total'] as num?)?.toDouble() ?? 0,
    monthSavedTotal: (json['month_saved_total'] as num?)?.toDouble() ?? 0,
    unallocated: (json['unallocated'] as num?)?.toDouble() ?? 0,
  );

  @override
  List<Object?> get props => [
    saved,
    inGoals,
    spare,
    currency,
    savedTotal,
    monthShortTotal,
    monthPlanTotal,
    monthSavedTotal,
    unallocated,
  ];
}

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

class SavingHistoryPoint extends Equatable {
  const SavingHistoryPoint({
    required this.month,
    required this.cumulative,
    this.plan,
  });

  final String month; // YYYY-MM
  final double cumulative;

  /// The cumulative plan line (null without a plan; always null on the spare).
  final double? plan;

  factory SavingHistoryPoint.fromJson(Map<String, dynamic> json) =>
      SavingHistoryPoint(
        month: json['month'] as String,
        cumulative: (json['cumulative'] as num).toDouble(),
        plan: (json['plan'] as num?)?.toDouble(),
      );

  @override
  List<Object?> get props => [month, cumulative, plan];
}

class SavingDeletePreview extends Equatable {
  const SavingDeletePreview({
    required this.entries,
    required this.savedAmount,
    required this.canDelete,
  });
  final int entries;
  final double savedAmount;
  final bool canDelete;

  factory SavingDeletePreview.fromJson(Map<String, dynamic> json) =>
      SavingDeletePreview(
        entries: (json['entries'] as num?)?.toInt() ?? 0,
        savedAmount: (json['saved_amount'] as num?)?.toDouble() ?? 0,
        canDelete: json['can_delete'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [entries, savedAmount, canDelete];
}

class SavingGoalDetail extends Equatable {
  const SavingGoalDetail({
    this.goal,
    this.spare,
    this.byWallet = const [],
    this.history = const [],
    this.spareAutoSave,
    this.entries = const SavingEntryPage(),
    this.deletePreview,
  });

  final SavingGoal? goal;
  final SavingSpare? spare;
  final List<SavingWalletShare> byWallet;
  final List<SavingHistoryPoint> history;

  final SavingAutoSave? spareAutoSave;
  final SavingEntryPage entries;

  final SavingDeletePreview? deletePreview;

  bool get isSpare => goal == null;

  SavingAutoSave? get autoSave => goal?.autoSave ?? spareAutoSave;

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
      spareAutoSave: goal == null && json['auto_save'] is Map
          ? SavingAutoSave.fromJson(
              (json['auto_save'] as Map).cast<String, dynamic>(),
            )
          : null,
      entries: json['entries'] is Map
          ? SavingEntryPage.fromJson(
              (json['entries'] as Map).cast<String, dynamic>(),
            )
          : const SavingEntryPage(),
      deletePreview: json['delete_preview'] is Map
          ? SavingDeletePreview.fromJson(
              (json['delete_preview'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  SavingGoalDetail copyWith({SavingEntryPage? entries}) => SavingGoalDetail(
    goal: goal,
    spare: spare,
    byWallet: byWallet,
    history: history,
    spareAutoSave: spareAutoSave,
    entries: entries ?? this.entries,
  );

  @override
  List<Object?> get props => [
    goal,
    spare,
    byWallet,
    history,
    spareAutoSave,
    entries,
    deletePreview,
  ];
}

/// What a saving write answers: every goal it touched, the spare bucket and the
/// entries it wrote — the page patches from it and never re-fetches.
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

  final SavingGoalDetail? page;

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
