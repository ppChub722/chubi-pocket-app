import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';

// TODO(be-spec): shapes follow fe-saving's goals v2 proposal (ai/inbox/fe-saving.md
// + the message to BE). Re-check every key against openapi.yaml when BE lands it.

/// Lifecycle state of a goal. The BE decides it (thin FE); the FE only maps it
/// to a chip.
enum SavingGoalState {
  active,
  completed,
  archived;

  static SavingGoalState fromJson(String? raw) => switch (raw) {
    'completed' => SavingGoalState.completed,
    'archived' => SavingGoalState.archived,
    _ => SavingGoalState.active,
  };
}

/// Where a goal stands against its plan (BE `status`): the BE decides, the
/// FE only maps it to a chip / badge.
enum SavingStatus {
  none,
  reached,
  onTrack,
  behind;

  static SavingStatus fromJson(String? raw) => switch (raw) {
    'reached' => SavingStatus.reached,
    'on_track' => SavingStatus.onTrack,
    'behind' => SavingStatus.behind,
    _ => SavingStatus.none,
  };
}

/// A wallet as the saving feature sees it (the shared AccountRef, no balance).
class SavingWalletRef extends Equatable {
  const SavingWalletRef({
    required this.id,
    required this.name,
    this.iconCode,
    this.logoUrl,
    this.type,
    this.group,
    this.currency,
    this.archived = false,
  });

  final String id;
  final String name;
  final IconCode? iconCode;
  final String? logoUrl;
  final String? type;
  final String? group;
  final String? currency;
  final bool archived;

  factory SavingWalletRef.fromJson(Map<String, dynamic> json) {
    final icon = json['icon_code'];
    return SavingWalletRef(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCode: icon is Map<String, dynamic> ? IconCode.fromJson(icon) : null,
      logoUrl: json['logo_url'] as String?,
      type: json['type'] as String?,
      group: json['group'] as String?,
      currency: json['currency'] as String?,
      archived: json['archived'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    iconCode,
    logoUrl,
    type,
    group,
    currency,
    archived,
  ];
}

/// A goal's (or the spare bucket's) auto-saving: on [day] of each month a
/// pending saving draft of [amount] is made — from [wallet], or none.
class SavingAutoSave extends Equatable {
  const SavingAutoSave({
    required this.amount,
    required this.day,
    this.wallet,
    this.nextDate,
  });

  final double amount;

  /// 1–31 (31 = the last day of the month).
  final int day;
  final SavingWalletRef? wallet;
  final String? nextDate;

  factory SavingAutoSave.fromJson(Map<String, dynamic> json) => SavingAutoSave(
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    day: (json['day'] as num?)?.toInt() ?? 1,
    wallet: json['wallet'] is Map
        ? SavingWalletRef.fromJson(
            (json['wallet'] as Map).cast<String, dynamic>(),
          )
        : null,
    nextDate: json['next_date'] as String?,
  );

  @override
  List<Object?> get props => [amount, day, wallet, nextDate];
}

/// One 25 / 50 / 75 / 100 % step of a goal (BE computes `reached`).
class SavingMilestone extends Equatable {
  const SavingMilestone({
    required this.pct,
    required this.amount,
    required this.reached,
  });

  final int pct;
  final double amount;
  final bool reached;

  factory SavingMilestone.fromJson(Map<String, dynamic> json) =>
      SavingMilestone(
        pct: (json['pct'] as num).toInt(),
        amount: (json['amount'] as num).toDouble(),
        reached: json['reached'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [pct, amount, reached];
}

/// Which buttons the BE allows for a goal right now.
class SavingGoalActions extends Equatable {
  const SavingGoalActions({
    this.save = true,
    this.withdraw = true,
    this.move = true,
    this.close = true,
    this.archive = true,
    this.restore = false,
    this.delete = true,
  });

  final bool save;
  final bool withdraw;
  final bool move;
  final bool close;
  final bool archive;
  final bool restore;
  final bool delete;

  factory SavingGoalActions.fromJson(Map<String, dynamic> json) =>
      SavingGoalActions(
        save: json['save'] as bool? ?? false,
        withdraw: json['withdraw'] as bool? ?? false,
        move: json['move'] as bool? ?? false,
        close: json['close'] as bool? ?? false,
        archive: json['archive'] as bool? ?? false,
        restore: json['restore'] as bool? ?? false,
        delete: json['delete'] as bool? ?? false,
      );

  @override
  List<Object?> get props => [
    save,
    withdraw,
    move,
    close,
    archive,
    restore,
    delete,
  ];
}

/// One saving goal: a target in a notebook of saved money. Saved money is a
/// sum of saving entries (never real transactions); every number below is
/// computed by the BE.
class SavingGoal extends Equatable {
  const SavingGoal({
    required this.id,
    required this.name,
    required this.currency,
    this.targetAmount,
    this.state = SavingGoalState.active,
    this.deadline,
    this.iconCode,
    this.description,
    this.note,
    this.savedAmount = 0,
    this.progressPct,
    this.remainingAmount,
    this.daysRemaining,
    this.neededMonthly,
    this.paceMonthly,
    this.etaDate,
    this.status = SavingStatus.none,
    this.behindMonths,
    this.monthPlan,
    this.monthSaved = 0,
    this.monthShort,
    this.autoSave,
    this.group,
    this.milestones = const [],
    this.actions = const SavingGoalActions(),
    this.closedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;

  /// Null = no target: an open-ended goal (ออมต่อเนื่อง, 0.4.0-1).
  final double? targetAmount;
  final String currency;
  final SavingGoalState state;
  final String? deadline; // ISO YYYY-MM-DD
  final IconCode? iconCode;
  final String? description;
  final String? note;
  final double savedAmount;

  /// Uncapped (104 % is possible); null without a target.
  final double? progressPct;

  /// Null without a target.
  final double? remainingAmount;
  final int? daysRemaining;
  final double? neededMonthly;
  final double? paceMonthly;
  final String? etaDate;
  final SavingStatus status;
  final int? behindMonths;

  /// This month: the plan (auto-saving amount, else the needed monthly),
  /// what is saved so far and what is still short — all BE numbers.
  final double? monthPlan;
  final double monthSaved;
  final double? monthShort;

  /// The goal's auto-saving (null = off).
  final SavingAutoSave? autoSave;

  /// The list group the BE puts the goal in whatever this month:
  /// `ongoing` (ออมต่อเนื่อง) for a goal with no target; null = by month.
  final String? group;
  final List<SavingMilestone> milestones;

  /// What the BE allows right now (buttons follow these flags).
  final SavingGoalActions actions;
  final DateTime? closedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCompleted => state == SavingGoalState.completed;
  bool get isArchived => state == SavingGoalState.archived;

  /// No target: no bar, %, ETA or behind / on-track (ออมต่อเนื่อง).
  bool get isOngoing => targetAmount == null;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  factory SavingGoal.fromJson(Map<String, dynamic> json) {
    final icon = json['icon_code'];
    return SavingGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['target_amount'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? '',
      state: SavingGoalState.fromJson(json['state'] as String?),
      deadline: json['deadline'] as String?,
      iconCode: icon is Map<String, dynamic> ? IconCode.fromJson(icon) : null,
      description: json['description'] as String?,
      note: json['note'] as String?,
      savedAmount: (json['saved_amount'] as num?)?.toDouble() ?? 0,
      progressPct: (json['progress_pct'] as num?)?.toDouble(),
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble(),
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      neededMonthly: (json['needed_monthly'] as num?)?.toDouble(),
      paceMonthly: (json['pace_monthly'] as num?)?.toDouble(),
      etaDate: json['eta_date'] as String?,
      status: SavingStatus.fromJson(json['status'] as String?),
      behindMonths: (json['behind_months'] as num?)?.toInt(),
      monthPlan: (json['month_plan'] as num?)?.toDouble(),
      monthSaved: (json['month_saved'] as num?)?.toDouble() ?? 0,
      monthShort: (json['month_short'] as num?)?.toDouble(),
      autoSave: json['auto_save'] is Map
          ? SavingAutoSave.fromJson(
              (json['auto_save'] as Map).cast<String, dynamic>(),
            )
          : null,
      group: json['group'] as String?,
      milestones: [
        for (final m in (json['milestones'] as List? ?? const []))
          SavingMilestone.fromJson((m as Map).cast<String, dynamic>()),
      ],
      actions: json['actions'] is Map
          ? SavingGoalActions.fromJson(
              (json['actions'] as Map).cast<String, dynamic>(),
            )
          : const SavingGoalActions(),
      closedAt: _date(json['closed_at']),
      createdAt: _date(json['created_at']),
      updatedAt: _date(json['updated_at']),
    );
  }

  /// Create / update body: name, target (null = none: clears it on update),
  /// deadline, icon, description, note. No wallet and no % (goals v2).
  Map<String, dynamic> toWriteJson() => <String, dynamic>{
    'name': name,
    'target_amount': targetAmount,
    'deadline': deadline,
    'icon_code': iconCode?.toJson(),
    'description': description,
    'note': note,
  };

  @override
  List<Object?> get props => [
    id,
    name,
    targetAmount,
    currency,
    state,
    deadline,
    iconCode,
    description,
    note,
    savedAmount,
    progressPct,
    remainingAmount,
    daysRemaining,
    neededMonthly,
    paceMonthly,
    etaDate,
    status,
    behindMonths,
    monthPlan,
    monthSaved,
    monthShort,
    autoSave,
    group,
    milestones,
    actions,
    closedAt,
    createdAt,
    updatedAt,
  ];
}
