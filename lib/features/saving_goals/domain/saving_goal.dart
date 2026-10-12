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

/// How the real saving pace compares with what the deadline needs (BE).
enum SavingPace {
  none,
  reached,
  onTrack,
  late;

  static SavingPace fromJson(String? raw) => switch (raw) {
    'on_track' => SavingPace.onTrack,
    'late' => SavingPace.late,
    'reached' => SavingPace.reached,
    _ => SavingPace.none,
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
    required this.targetAmount,
    required this.currency,
    this.state = SavingGoalState.active,
    this.deadline,
    this.iconCode,
    this.description,
    this.note,
    this.savedAmount = 0,
    this.progressPct = 0,
    this.remainingAmount = 0,
    this.daysRemaining,
    this.neededMonthly,
    this.paceMonthly,
    this.etaDate,
    this.pace = SavingPace.none,
    this.lateMonths,
    this.milestones = const [],
    this.actions = const SavingGoalActions(),
    this.closedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final double targetAmount;
  final String currency;
  final SavingGoalState state;
  final String? deadline; // ISO YYYY-MM-DD
  final IconCode? iconCode;
  final String? description;
  final String? note;
  final double savedAmount;

  /// Uncapped (104 % is possible).
  final double progressPct;
  final double remainingAmount;
  final int? daysRemaining;
  final double? neededMonthly;
  final double? paceMonthly;
  final String? etaDate;
  final SavingPace pace;
  final int? lateMonths;
  final List<SavingMilestone> milestones;

  /// What the BE allows right now (buttons follow these flags).
  final SavingGoalActions actions;
  final DateTime? closedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCompleted => state == SavingGoalState.completed;
  bool get isArchived => state == SavingGoalState.archived;

  static DateTime? _date(Object? v) =>
      v is String ? DateTime.tryParse(v)?.toLocal() : null;

  factory SavingGoal.fromJson(Map<String, dynamic> json) {
    final icon = json['icon_code'];
    return SavingGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      currency: json['currency'] as String? ?? '',
      state: SavingGoalState.fromJson(json['state'] as String?),
      deadline: json['deadline'] as String?,
      iconCode: icon is Map<String, dynamic> ? IconCode.fromJson(icon) : null,
      description: json['description'] as String?,
      note: json['note'] as String?,
      savedAmount: (json['saved_amount'] as num?)?.toDouble() ?? 0,
      progressPct: (json['progress_pct'] as num?)?.toDouble() ?? 0,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0,
      daysRemaining: (json['days_remaining'] as num?)?.toInt(),
      neededMonthly: (json['needed_monthly'] as num?)?.toDouble(),
      paceMonthly: (json['pace_monthly'] as num?)?.toDouble(),
      etaDate: json['eta_date'] as String?,
      pace: SavingPace.fromJson(json['pace'] as String?),
      lateMonths: (json['late_months'] as num?)?.toInt(),
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

  /// Create / update body: name, target, deadline, icon, description, note.
  /// No wallet and no % (goals v2).
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
    pace,
    lateMonths,
    milestones,
    actions,
    closedAt,
    createdAt,
    updatedAt,
  ];
}
