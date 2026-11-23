import 'package:equatable/equatable.dart';

import '../../recurring/domain/recurrence_rule.dart' show parseYmd;
import '../../recurring/domain/recurring_page.dart';
import '../../transactions/domain/refs.dart';

/// A debt plan (0.4.3, `/debt-plans/{id}`): ผ่อน / a loan repaid in
/// installments. Its creditor is a card / PayLater wallet (the card holds the
/// debt; its bill pays the rounds), an institution or a person.
class DebtPlan extends Equatable {
  const DebtPlan({
    required this.id,
    required this.name,
    required this.plan,
    required this.creditorKind,
    required this.creditorName,
    this.creditorKey = '',
    this.creditorAccount,
    this.direction = 'received',
    this.origin = 'purchase',
    this.recurringId,
    this.installments = const [],
  });

  static DebtPlan? tryParse(Object? json) {
    if (json is! Map<String, dynamic> || json['id'] is! String) return null;
    final plan = RecurringPlan.tryParse(json);
    if (plan == null) return null;
    final c = json['creditor'];
    final cm = c is Map<String, dynamic> ? c : const <String, dynamic>{};
    final acc = cm['account'];
    return DebtPlan(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      plan: plan,
      creditorKind: (cm['kind'] as String?) ?? 'person',
      creditorName: (cm['name'] as String?) ?? '',
      creditorKey: (cm['key'] as String?) ?? '',
      creditorAccount: acc is Map<String, dynamic>
          ? AccountRef.fromJson(acc)
          : null,
      direction: (json['direction'] as String?) ?? 'received',
      origin: (json['origin'] as String?) ?? 'purchase',
      recurringId: json['recurring_id'] as String?,
      installments: [
        for (final i in (json['installments'] as List?) ?? const [])
          ?PlanInstallment.tryParse(i),
      ],
    );
  }

  final String id;
  final String name;
  final RecurringPlan plan;

  /// card | institution | person.
  final String creditorKind;
  final String creditorName;

  /// The debts page key (c: / n: / i:); empty for a card.
  final String creditorKey;
  final AccountRef? creditorAccount;

  /// received = I owe; paid = they owe me.
  final String direction;

  /// purchase | cash.
  final String origin;

  /// The recurring item whose reminder pays it.
  final String? recurringId;
  final List<PlanInstallment> installments;

  bool get isCard => creditorKind == 'card';
  bool get iOwe => direction == 'received';

  @override
  List<Object?> get props => [
    id,
    name,
    plan,
    creditorKind,
    creditorName,
    creditorKey,
    creditorAccount,
    direction,
    origin,
    recurringId,
    installments,
  ];
}

/// One statement cycle of a card.
class CardBill extends Equatable {
  const CardBill({
    required this.cycleEnd,
    this.dueDate,
    this.spending = 0,
    this.installments = 0,
    this.total = 0,
    this.paid = 0,
    this.left = 0,
  });

  factory CardBill.fromJson(Object? json) {
    final j = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    double n(String k) => (j[k] as num?)?.toDouble() ?? 0;
    return CardBill(
      cycleEnd: parseYmd(j['cycle_end'] as String?) ?? DateTime.now(),
      dueDate: parseYmd(j['due_date'] as String?),
      spending: n('spending'),
      installments: n('installments'),
      total: n('total'),
      paid: n('paid'),
      left: n('left'),
    );
  }

  final DateTime cycleEnd;
  final DateTime? dueDate;
  final double spending;
  final double installments;
  final double total;
  final double paid;
  final double left;

  @override
  List<Object?> get props => [
    cycleEnd,
    dueDate,
    spending,
    installments,
    total,
    paid,
    left,
  ];
}

/// A card / PayLater wallet as a debt (`/card-summaries`).
class CardSummary extends Equatable {
  const CardSummary({
    required this.account,
    required this.bill,
    this.owed = 0,
    this.unbilled = 0,
    this.plans = const [],
    this.recurringId,
  });

  static CardSummary? tryParse(Object? json) {
    if (json is! Map<String, dynamic> || json['account'] is! Map) return null;
    return CardSummary(
      account: AccountRef.fromJson(json['account'] as Map<String, dynamic>),
      bill: CardBill.fromJson(json['bill']),
      owed: (json['owed'] as num?)?.toDouble() ?? 0,
      unbilled: (json['unbilled'] as num?)?.toDouble() ?? 0,
      plans: [
        for (final p in (json['plans'] as List?) ?? const [])
          ?DebtPlan.tryParse(p),
      ],
      recurringId: json['recurring_id'] as String?,
    );
  }

  final AccountRef account;
  final CardBill bill;
  final double owed;
  final double unbilled;
  final List<DebtPlan> plans;

  /// The recurring item that pays its bill.
  final String? recurringId;

  @override
  List<Object?> get props => [account, bill, owed, unbilled, plans, recurringId];
}
