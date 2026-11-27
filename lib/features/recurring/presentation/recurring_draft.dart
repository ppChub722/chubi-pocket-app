import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../../ui/ui.dart';
import '../domain/recurring.dart';
import '../domain/recurring_page.dart';

/// A debt item's plan as the form holds it: typed text until saved.
@immutable
class RecurringPlanDraft extends Equatable {
  const RecurringPlanDraft({
    required this.start,
    this.principal = '',
    this.count = 12,
    this.method = PlanInterestMethod.none,
    this.rate = '',
    this.installmentAmount = '',
    this.cardAccountId,
    this.openingAccountId,
  });

  factory RecurringPlanDraft.from(RecurringPlan p) => RecurringPlanDraft(
    start: p.start,
    principal: AmountInput.format(p.principal),
    count: p.count,
    method: p.method,
    rate: p.rate == null ? '' : _num(p.rate!),
    installmentAmount: p.installmentAmount == null
        ? ''
        : AmountInput.format(p.installmentAmount!),
    cardAccountId: p.cardAccountId,
  );

  static String _num(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  final String principal;
  final int count;
  final DateTime start;
  final PlanInterestMethod method;
  final String rate;
  final String installmentAmount;

  /// ผ่อนผ่านบัตร: the card holds the debt; the item has no line.
  final String? cardAccountId;
  final String? openingAccountId;

  bool get onCard => cardAccountId != null;

  /// Enough to preview / save: a principal, a count and what the method needs.
  bool get ok {
    final p = AmountInput.parse(principal);
    if (p == null || p <= 0 || count <= 0) return false;
    return switch (method) {
      PlanInterestMethod.flat ||
      PlanInterestMethod.reducing => double.tryParse(rate.trim()) != null,
      PlanInterestMethod.fixed =>
        (AmountInput.parse(installmentAmount) ?? 0) > 0,
      _ => true,
    };
  }

  RecurringPlanWrite? toWrite() {
    if (!ok) return null;
    return RecurringPlanWrite(
      principal: AmountInput.parse(principal)!,
      count: count,
      start: start,
      method: method,
      rate: double.tryParse(rate.trim()),
      installmentAmount: AmountInput.parse(installmentAmount),
      cardAccountId: cardAccountId,
      openingAccountId: cardAccountId == null ? openingAccountId : null,
    );
  }

  RecurringPlanDraft copyWith({
    String? principal,
    int? count,
    DateTime? start,
    PlanInterestMethod? method,
    String? rate,
    String? installmentAmount,
    String? cardAccountId,
    bool clearCard = false,
    String? openingAccountId,
  }) => RecurringPlanDraft(
    principal: principal ?? this.principal,
    count: count ?? this.count,
    start: start ?? this.start,
    method: method ?? this.method,
    rate: rate ?? this.rate,
    installmentAmount: installmentAmount ?? this.installmentAmount,
    cardAccountId: clearCard ? null : (cardAccountId ?? this.cardAccountId),
    openingAccountId: openingAccountId ?? this.openingAccountId,
  );

  @override
  List<Object?> get props => [
    principal,
    count,
    start,
    method,
    rate,
    installmentAmount,
    cardAccountId,
    openingAccountId,
  ];
}
