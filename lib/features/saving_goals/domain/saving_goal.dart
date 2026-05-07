import 'package:equatable/equatable.dart';

import '../../../shared/icon_maker/icon_code.dart';
import 'saving_goal_status.dart';

/// One saving goal — a target overlaid on top of a real account balance.
///
/// Per [`09-saving-goals.md`](../../../../../chubi-pocket-docs/design/spec/09-saving-goals.md):
/// progress = `linkedAccount.balance × allocationPct / 100`. Sum of
/// allocations on a single account ≤ 100% (server-enforced).
///
/// Server-computed fields ([currentAmount], [progressPct], [isCompleted],
/// [remainingAmount], [daysRemaining]) come back populated from the API
/// on every read. [requiredMonthly] is FE-computed per spec §2 / §4.6.
/// None of these are sent on writes.
class SavingGoal extends Equatable {
  const SavingGoal({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.linkedAccountId,
    required this.allocationPct,
    required this.currency,
    required this.status,
    this.deadline,
    this.iconCode,
    this.note,
    this.linkedAccount,
    this.currentAmount = 0,
    this.progressPct = 0,
    this.isCompleted = false,
    this.remainingAmount = 0,
    this.daysRemaining,
  });

  final String id;
  final String name;
  final double targetAmount;
  final String linkedAccountId;
  final double allocationPct;

  /// Inherited from the linked account; can't differ per-goal.
  final String currency;
  final SavingGoalStatus status;
  final String? deadline; // ISO YYYY-MM-DD
  final IconCode? iconCode;
  final String? note;

  /// Embedded ref returned in list responses so rows can render the
  /// linked account name + current balance without a separate fetch.
  final SavingGoalLinkedAccount? linkedAccount;

  /// Computed: linkedAccount.balance × allocationPct / 100.
  final double currentAmount;

  /// Computed: (currentAmount / targetAmount) × 100.
  final double progressPct;

  /// Computed: currentAmount >= targetAmount. Non-sticky — flips back to
  /// false if balance drops, matching reality (spec §4.3).
  final bool isCompleted;

  /// Computed: max(0, targetAmount - currentAmount).
  final double remainingAmount;

  /// Computed: deadline - today, when [deadline] is set.
  final int? daysRemaining;

  /// Suggested monthly contribution to hit [targetAmount] by [deadline].
  ///
  /// Per spec §2 / §4.6 this is **frontend-computed** — the BE doesn't
  /// send it, so we derive it from [remainingAmount] and [daysRemaining]
  /// on demand. Returns null when there's no deadline or the goal is
  /// already met (no remaining work).
  double? get requiredMonthly {
    final days = daysRemaining;
    if (days == null || remainingAmount <= 0) return null;
    // 30.44 = average days/month; matches spec's months_remaining formula.
    final months = days / 30.44;
    if (months <= 1) return remainingAmount;
    return remainingAmount / months;
  }

  SavingGoal copyWith({
    String? id,
    String? name,
    double? targetAmount,
    String? linkedAccountId,
    double? allocationPct,
    String? currency,
    SavingGoalStatus? status,
    String? deadline,
    IconCode? iconCode,
    String? note,
    SavingGoalLinkedAccount? linkedAccount,
    double? currentAmount,
    double? progressPct,
    bool? isCompleted,
    double? remainingAmount,
    int? daysRemaining,
  }) {
    return SavingGoal(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      linkedAccountId: linkedAccountId ?? this.linkedAccountId,
      allocationPct: allocationPct ?? this.allocationPct,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      deadline: deadline ?? this.deadline,
      iconCode: iconCode ?? this.iconCode,
      note: note ?? this.note,
      linkedAccount: linkedAccount ?? this.linkedAccount,
      currentAmount: currentAmount ?? this.currentAmount,
      progressPct: progressPct ?? this.progressPct,
      isCompleted: isCompleted ?? this.isCompleted,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      daysRemaining: daysRemaining ?? this.daysRemaining,
    );
  }

  factory SavingGoal.fromJson(Map<String, dynamic> json) {
    final embedded = json['linked_account'] as Map<String, dynamic>?;
    return SavingGoal(
      id: json['id'] as String,
      name: json['name'] as String,
      targetAmount: (json['target_amount'] as num).toDouble(),
      linkedAccountId: (json['linked_account_id'] as String?) ??
          (embedded?['id'] as String? ?? ''),
      allocationPct: (json['allocation_pct'] as num).toDouble(),
      currency: json['currency'] as String,
      status: SavingGoalStatus.fromJson(json['status'] as String),
      deadline: json['deadline'] as String?,
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
      note: json['note'] as String?,
      linkedAccount: embedded != null
          ? SavingGoalLinkedAccount.fromJson(embedded)
          : null,
      currentAmount: (json['current_amount'] as num?)?.toDouble() ?? 0,
      progressPct: (json['progress_pct'] as num?)?.toDouble() ?? 0,
      isCompleted: json['is_completed'] as bool? ?? false,
      remainingAmount: (json['remaining_amount'] as num?)?.toDouble() ?? 0,
      daysRemaining: json['days_remaining'] as int?,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'name': name,
      'target_amount': targetAmount,
      'linked_account_id': linkedAccountId,
      // Spec §3.1: omit allocation_pct → server proposes a default.
      // Send only when explicitly set (> 0).
      if (allocationPct > 0) 'allocation_pct': allocationPct,
      if (deadline != null) 'deadline': deadline,
      if (iconCode != null) 'icon_code': iconCode!.toJson(),
      if (note != null) 'note': note,
    };
  }

  /// Spec §3.4: `linked_account_id` is NOT editable. Sending it would be
  /// ignored server-side; we omit it to keep the wire honest. `status`
  /// changes go through dedicated archive / restore endpoints, not PUT.
  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'name': name,
      'target_amount': targetAmount,
      'allocation_pct': allocationPct,
      'deadline': deadline,
      'icon_code': iconCode?.toJson(),
      'note': note,
    };
  }

  @override
  List<Object?> get props => [
        id,
        name,
        targetAmount,
        linkedAccountId,
        allocationPct,
        currency,
        status,
        deadline,
        iconCode,
        note,
        linkedAccount,
        currentAmount,
        progressPct,
        isCompleted,
        remainingAmount,
        daysRemaining,
      ];
}

/// Embedded linked-account ref returned alongside each saving goal so the
/// list / detail UI can show the account name + current balance without
/// a follow-up `/v1/accounts/:id` fetch.
class SavingGoalLinkedAccount extends Equatable {
  const SavingGoalLinkedAccount({
    required this.id,
    required this.name,
    required this.balance,
  });

  final String id;
  final String name;
  final double balance;

  factory SavingGoalLinkedAccount.fromJson(Map<String, dynamic> json) {
    return SavingGoalLinkedAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      balance: (json['balance'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [id, name, balance];
}
