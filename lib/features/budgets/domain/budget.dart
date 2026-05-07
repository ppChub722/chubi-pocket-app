import 'package:equatable/equatable.dart';

import '../../../shared/icon_maker/icon_code.dart';
import 'budget_period.dart';
import 'budget_scope.dart';
import 'budget_status.dart';

/// One budget — a per-category spending limit with a recurrence period.
///
/// Per [`08-budgets.md`](../../../../../chubi-pocket-docs/design/spec/08-budgets.md):
/// budgets are advisory (warn-not-block); spending rolls up across the
/// category's descendants; uniqueness is enforced on
/// `(user_id, category_id, period, project_id)` for active rows.
///
/// Migration 000037 dropped the per-budget `icon_code` — the icon is now
/// always taken from the linked category (see [BudgetCategoryRef.iconCode]).
/// `description`, when set, is the budget's primary label; otherwise the
/// FE falls back to the category name.
///
/// [currentPeriod] and [childBreakdown] come back populated from the API
/// on every read; the client never stores or computes these for writes.
class Budget extends Equatable {
  const Budget({
    required this.id,
    required this.categoryId,
    required this.amount,
    required this.period,
    required this.scope,
    required this.currency,
    required this.status,
    this.projectId,
    this.description,
    this.note,
    this.category,
    this.currentPeriod,
    this.childBreakdown = const [],
  });

  final String id;
  final String categoryId;
  final double amount;
  final BudgetPeriod period;
  final BudgetScope scope;
  final String currency;
  final BudgetStatus status;
  final String? projectId;
  final String? description;

  /// Free-form longer narrative; rendered as a separate card on the
  /// detail page (mirrors the accounts description / note split).
  final String? note;

  final BudgetCategoryRef? category;
  final BudgetCurrentPeriod? currentPeriod;
  final List<BudgetChildBreakdown> childBreakdown;

  /// Convenience: spent / amount as a 0..1 progress fraction. Null when
  /// the API hasn't populated current-period info yet (e.g. local draft).
  double? get progress {
    final cp = currentPeriod;
    if (cp == null || amount <= 0) return null;
    return (cp.spent / amount).clamp(0.0, 1.0);
  }

  /// The category's icon (if the API embedded it). The budget itself no
  /// longer carries an icon — UI renders this everywhere.
  IconCode? get iconCode => category?.iconCode;

  /// User-facing primary label. `description` if set, else the category
  /// name, else the empty string. Mirrors the BE rule the FE applies on
  /// list cards, detail header, and AppBar titles.
  String get displayTitle {
    if (description != null && description!.isNotEmpty) return description!;
    return category?.name ?? '';
  }

  Budget copyWith({
    String? id,
    String? categoryId,
    double? amount,
    BudgetPeriod? period,
    BudgetScope? scope,
    String? currency,
    BudgetStatus? status,
    String? projectId,
    String? description,
    String? note,
    BudgetCategoryRef? category,
    BudgetCurrentPeriod? currentPeriod,
    List<BudgetChildBreakdown>? childBreakdown,
  }) {
    return Budget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      period: period ?? this.period,
      scope: scope ?? this.scope,
      currency: currency ?? this.currency,
      status: status ?? this.status,
      projectId: projectId ?? this.projectId,
      description: description ?? this.description,
      note: note ?? this.note,
      category: category ?? this.category,
      currentPeriod: currentPeriod ?? this.currentPeriod,
      childBreakdown: childBreakdown ?? this.childBreakdown,
    );
  }

  factory Budget.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as Map<String, dynamic>?;
    final currentPeriod = json['current_period'] as Map<String, dynamic>?;
    final breakdown = (json['child_breakdown'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(BudgetChildBreakdown.fromJson)
        .toList();
    return Budget(
      id: json['id'] as String,
      categoryId: (json['category_id'] as String?) ??
          (category?['id'] as String? ?? ''),
      amount: (json['amount'] as num).toDouble(),
      period: BudgetPeriod.fromJson(json['period'] as String),
      scope: BudgetScope.fromJson(json['scope'] as String),
      currency: json['currency'] as String,
      status: BudgetStatus.fromJson(json['status'] as String),
      projectId: json['project_id'] as String?,
      description: json['description'] as String?,
      note: json['note'] as String?,
      category:
          category != null ? BudgetCategoryRef.fromJson(category) : null,
      currentPeriod: currentPeriod != null
          ? BudgetCurrentPeriod.fromJson(currentPeriod)
          : null,
      childBreakdown: breakdown,
    );
  }

  Map<String, dynamic> toCreateJson() {
    return <String, dynamic>{
      'category_id': categoryId,
      'amount': amount,
      'period': period.toJson(),
      'scope': scope.toJson(),
      if (projectId != null) 'project_id': projectId,
      'currency': currency,
      if (description != null) 'description': description,
      if (note != null) 'note': note,
    };
  }

  /// Spec §3.4: `category_id`, `scope`, and `project_id` are NOT editable.
  /// Status changes go through dedicated archive / restore endpoints.
  Map<String, dynamic> toUpdateJson() {
    return <String, dynamic>{
      'amount': amount,
      'period': period.toJson(),
      'currency': currency,
      'description': description,
      'note': note,
    };
  }

  @override
  List<Object?> get props => [
        id,
        categoryId,
        amount,
        period,
        scope,
        currency,
        status,
        projectId,
        description,
        note,
        category,
        currentPeriod,
        childBreakdown,
      ];
}

/// Embedded category snapshot the BE returns on every Budget read. The
/// FE renders [iconCode] as the budget's icon (per migration 000037 —
/// budgets no longer carry a per-row icon).
class BudgetCategoryRef extends Equatable {
  const BudgetCategoryRef({
    required this.id,
    required this.name,
    this.iconCode,
  });

  final String id;
  final String name;
  final IconCode? iconCode;

  factory BudgetCategoryRef.fromJson(Map<String, dynamic> json) {
    return BudgetCategoryRef(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [id, name, iconCode];
}

class BudgetCurrentPeriod extends Equatable {
  const BudgetCurrentPeriod({
    required this.start,
    required this.end,
    required this.spent,
    required this.remaining,
    required this.utilizationPct,
    required this.overLimit,
  });

  final String start;
  final String end;
  final double spent;
  final double remaining;
  final double utilizationPct;
  final bool overLimit;

  factory BudgetCurrentPeriod.fromJson(Map<String, dynamic> json) {
    return BudgetCurrentPeriod(
      start: json['start'] as String,
      end: json['end'] as String,
      spent: (json['spent'] as num).toDouble(),
      remaining: (json['remaining'] as num).toDouble(),
      utilizationPct: (json['utilization_pct'] as num).toDouble(),
      overLimit: json['over_limit'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props =>
      [start, end, spent, remaining, utilizationPct, overLimit];
}

class BudgetChildBreakdown extends Equatable {
  const BudgetChildBreakdown({
    required this.categoryId,
    required this.name,
    required this.spent,
  });

  final String categoryId;
  final String name;
  final double spent;

  factory BudgetChildBreakdown.fromJson(Map<String, dynamic> json) {
    return BudgetChildBreakdown(
      categoryId: json['category_id'] as String,
      name: json['name'] as String,
      spent: (json['spent'] as num).toDouble(),
    );
  }

  @override
  List<Object?> get props => [categoryId, name, spent];
}
