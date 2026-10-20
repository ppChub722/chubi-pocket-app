import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import '../../recurring/domain/recurrence_rule.dart';

// TODO(be-spec): shapes follow fe-saving's goals v2 proposal (ai/inbox/fe-saving.md
// + the message to BE). Re-check every key against openapi.yaml when BE lands it.

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

class SavingAutoSave extends Equatable {
  const SavingAutoSave({
    required this.amount,
    required this.day,
    this.id,
    this.rule,
    this.wallet,
    this.nextDate,
  });

  final String? id;
  final double amount;

  final int day;

  /// Null from a BE without per-item rules: monthly on [day].
  final RecurrenceRule? rule;
  final SavingWalletRef? wallet;
  final String? nextDate;

  factory SavingAutoSave.fromJson(Map<String, dynamic> json) {
    final rule = json['rule'] is Map
        ? recurrenceFromJson(
            (json['rule'] as Map).cast<String, dynamic>(),
            start: json['start_date'] as String?,
            end: (json['end'] as Map?)?.cast<String, dynamic>(),
          )
        : null;
    return SavingAutoSave(
      id: json['id'] as String?,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      day:
          (json['day'] as num?)?.toInt() ??
          rule?.monthly?.day ??
          rule?.start.day ??
          1,
      rule: rule,
      wallet: json['wallet'] is Map
          ? SavingWalletRef.fromJson(
              (json['wallet'] as Map).cast<String, dynamic>(),
            )
          : null,
      nextDate: json['next_date'] as String?,
    );
  }

  /// `auto_saves` when the BE sends the list, else the single `auto_save`.
  static List<SavingAutoSave> listFromJson(Map<String, dynamic> json) {
    final many = json['auto_saves'];
    if (many is List) {
      return [
        for (final a in many)
          SavingAutoSave.fromJson((a as Map).cast<String, dynamic>()),
      ];
    }
    final one = json['auto_save'];
    return one is Map
        ? [SavingAutoSave.fromJson(one.cast<String, dynamic>())]
        : const [];
  }

  @override
  List<Object?> get props => [id, amount, day, rule, wallet, nextDate];
}

/// One auto-save as the PUT …/auto-saves list sends it.
class SavingAutoSaveWrite {
  const SavingAutoSaveWrite({
    required this.amount,
    required this.rule,
    this.id,
    this.accountId,
  });

  final String? id;
  final double amount;
  final RecurrenceRule rule;
  final String? accountId;

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': ?id,
    'amount': amount,
    'account_id': accountId,
    ...recurrenceToJson(rule),
  };
}

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
    this.autoSaves = const [],
    this.group,
    this.milestones = const [],
    this.actions = const SavingGoalActions(),
    this.closedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;

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

  final double? monthPlan;
  final double monthSaved;
  final double? monthShort;

  final List<SavingAutoSave> autoSaves;

  SavingAutoSave? get autoSave => autoSaves.firstOrNull;

  final String? group;
  final List<SavingMilestone> milestones;

  final SavingGoalActions actions;
  final DateTime? closedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isCompleted => state == SavingGoalState.completed;
  bool get isArchived => state == SavingGoalState.archived;

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
      autoSaves: SavingAutoSave.listFromJson(json),
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
    autoSaves,
    group,
    milestones,
    actions,
    closedAt,
    createdAt,
    updatedAt,
  ];
}
