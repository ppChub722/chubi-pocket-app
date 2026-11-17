import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart' show RecurrenceRule;
import '../../institutions/domain/institution.dart';
import '../../personal_debts/domain/debt_direction.dart';
import '../../transactions/domain/refs.dart';
import 'recurrence_rule.dart';
import 'recurring.dart';

/// A debt item's counterparty, page-ready (BE `Counterparty`): a person (a
/// contact or a typed name) or an institution; [key] opens its debt page.
class RecurringCounterparty extends Equatable {
  const RecurringCounterparty({
    required this.key,
    required this.name,
    this.institution,
    this.person,
    this.net = 0,
  });

  static RecurringCounterparty? tryParse(Object? json) {
    if (json is! Map<String, dynamic> || json['key'] is! String) return null;
    final p = json['person'];
    return RecurringCounterparty(
      key: json['key'] as String,
      name: (json['name'] as String?) ?? '',
      institution: InstitutionRef.tryParse(json['institution']),
      person: p is Map<String, dynamic> ? EmbeddedPerson.fromJson(p) : null,
      net: (json['net'] as num?)?.toDouble() ?? 0,
    );
  }

  final String key;
  final String name;
  final InstitutionRef? institution;
  final EmbeddedPerson? person;

  /// Its balance now (> 0 = they owe me).
  final double net;

  bool get isInstitution => institution != null || key.startsWith('i:');

  /// The person for person pieces: the BE's, else one by the name.
  EmbeddedPerson get asPerson => person ?? EmbeddedPerson(name: name);

  /// `/personal-debts/people/<key>`.
  String get debtPath => '/personal-debts/people/${Uri.encodeComponent(key)}';

  @override
  List<Object?> get props => [key, name, institution, person, net];
}

class RecurringLineActions extends Equatable {
  const RecurringLineActions({
    this.pause = false,
    this.resume = false,
    this.archive = false,
    this.restore = false,
    this.extend = false,
    this.delete = false,
  });

  factory RecurringLineActions.fromJson(Object? json) {
    final j = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    return RecurringLineActions(
      pause: j['pause'] == true,
      resume: j['resume'] == true,
      archive: j['archive'] == true,
      restore: j['restore'] == true,
      extend: j['extend'] == true,
      delete: j['delete'] == true,
    );
  }

  final bool pause;
  final bool resume;
  final bool archive;
  final bool restore;
  final bool extend;
  final bool delete;

  @override
  List<Object?> get props => [pause, resume, archive, restore, extend, delete];
}

/// One line of an item (BE `Line`): its source (a wallet or a person paying
/// for me), amount and schedule. [view] reads it as a whole rule (the item's
/// name / type / category with this line's numbers) for the rule pieces.
class RecurringLine extends Equatable {
  const RecurringLine({
    required this.id,
    required this.view,
    required this.json,
    this.paidBy,
    this.actions = const RecurringLineActions(),
  });

  factory RecurringLine.fromJson(
    Map<String, dynamic> json, {
    required Map<String, dynamic> item,
  }) {
    final paidBy = json['paid_by'];
    return RecurringLine(
      id: json['id'] as String,
      json: json,
      view: lineView(item, json),
      paidBy: paidBy is Map<String, dynamic>
          ? EmbeddedPerson.fromJson(paidBy)
          : null,
      actions: RecurringLineActions.fromJson(json['actions']),
    );
  }

  final String id;

  /// The BE's line as sent (kept for a PUT of the whole item).
  final Map<String, dynamic> json;
  final Recurring view;

  /// คนจ่ายแทน: the person who pays for me; null = a wallet line.
  final EmbeddedPerson? paidBy;
  final RecurringLineActions actions;

  RecurrenceRule get rule => view.rule;
  double? get amount => view.amount;
  AccountRef? get account => view.account;
  RecurringStatus get status => view.status;

  /// This line as a `LineInput` (unchanged), for a whole-item PUT.
  Map<String, dynamic> toInput() => {
    'id': id,
    'amount': json['amount'],
    'source': json['source'],
    'to_account_id': json['to_account_id'],
    'debt_kind': ?json['debt_kind'],
    'schedule': json['schedule'],
    'auto_create': json['auto_create'] == true,
  };

  @override
  List<Object?> get props => [id, json, view, paidBy, actions];
}

/// [line] of [item] as one rule: the item's identity, the line's numbers.
Recurring lineView(
  Map<String, dynamic> item,
  Map<String, dynamic> line, {
  bool asItem = false,
}) {
  final schedule = line['schedule'] as Map<String, dynamic>?;
  final counterparty = item['counterparty'];
  final person = counterparty is Map<String, dynamic>
      ? (counterparty['person'] ??
            {'name': counterparty['name'] ?? '', 'contact_id': null})
      : null;
  return Recurring.fromJson({
    ...line,
    'id': item['id'],
    'name': item['name'],
    'description': item['description'],
    'note': item['note'],
    'icon_code': item['icon_code'],
    'type': item['type'],
    'category': item['category'],
    'tags': item['tags'],
    'goal_id': item['goal_id'],
    'goal': item['goal'],
    'person': ?person,
    'direction': item['debt_direction'],
    'rule': schedule,
    'start_date': schedule?['start_date'],
    'end': schedule?['end'],
    'created_at': item['created_at'],
    'updated_at': item['updated_at'],
    if (asItem) ...{
      'status': item['status'],
      'actions': {
        ...?(item['actions'] as Map<String, dynamic>?),
        'extend': (line['actions'] as Map?)?['extend'] == true,
      },
    },
  });
}

enum InstallmentStatus {
  upcoming,
  due,
  paid,
  skipped;

  static InstallmentStatus fromJson(Object? v) =>
      values.firstWhere((s) => s.name == v, orElse: () => upcoming);
}

/// One installment of a plan (BE `Installment`).
class PlanInstallment extends Equatable {
  const PlanInstallment({
    required this.seq,
    required this.dueDate,
    required this.amount,
    this.principal = 0,
    this.interest = 0,
    this.status = InstallmentStatus.upcoming,
    this.paidAt,
    this.personalDebtId,
    this.edited = false,
  });

  static PlanInstallment? tryParse(Object? json) =>
      json is Map<String, dynamic> && json['seq'] is num
      ? PlanInstallment(
          seq: (json['seq'] as num).toInt(),
          dueDate: parseYmd(json['due_date'] as String?) ?? today(),
          amount: (json['amount'] as num?)?.toDouble() ?? 0,
          principal: (json['principal'] as num?)?.toDouble() ?? 0,
          interest: (json['interest'] as num?)?.toDouble() ?? 0,
          status: InstallmentStatus.fromJson(json['status']),
          paidAt: DateTime.tryParse((json['paid_at'] as String?) ?? ''),
          personalDebtId: json['personal_debt_id'] as String?,
          edited: json['edited'] == true,
        )
      : null;

  final int seq;
  final DateTime dueDate;
  final double amount;
  final double principal;
  final double interest;
  final InstallmentStatus status;
  final DateTime? paidAt;
  final String? personalDebtId;

  /// Changed by hand (แก้งวดนี้).
  final bool edited;

  bool get paid => status == InstallmentStatus.paid;

  @override
  List<Object?> get props => [
    seq,
    dueDate,
    amount,
    principal,
    interest,
    status,
    paidAt,
    personalDebtId,
    edited,
  ];
}

/// A debt item's plan (BE `PlanView`): information; the balance counts the
/// debt rows only.
class RecurringPlan extends Equatable {
  const RecurringPlan({
    required this.principal,
    required this.count,
    required this.start,
    this.method = PlanInterestMethod.none,
    this.rate,
    this.installmentAmount,
    this.cardAccount,
    this.cardAccountId,
    this.closed = false,
    this.done = 0,
    this.leftCount = 0,
    this.paidPrincipal = 0,
    this.leftPrincipal = 0,
    this.leftInterest = 0,
    this.leftTotal = 0,
    this.lastDate,
    this.next,
    this.due = const [],
    this.chain = const [],
  });

  static RecurringPlan? tryParse(Object? json) {
    if (json is! Map<String, dynamic> || json['count'] is! num) return null;
    final card = json['card_account'];
    return RecurringPlan(
      principal: (json['principal'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num).toInt(),
      start: parseYmd(json['start_date'] as String?) ?? today(),
      method: PlanInterestMethod.fromJson(json['interest_method']),
      rate: (json['interest_rate'] as num?)?.toDouble(),
      installmentAmount: (json['installment_amount'] as num?)?.toDouble(),
      cardAccountId: json['card_account_id'] as String?,
      cardAccount: card is Map<String, dynamic>
          ? AccountRef.fromJson(card)
          : null,
      closed: json['closed'] == true,
      done: (json['done'] as num?)?.toInt() ?? 0,
      leftCount: (json['left_count'] as num?)?.toInt() ?? 0,
      paidPrincipal: (json['paid_principal'] as num?)?.toDouble() ?? 0,
      leftPrincipal: (json['left_principal'] as num?)?.toDouble() ?? 0,
      leftInterest: (json['left_interest'] as num?)?.toDouble() ?? 0,
      leftTotal: (json['left_total'] as num?)?.toDouble() ?? 0,
      lastDate: parseYmd(json['last_date'] as String?),
      next: PlanInstallment.tryParse(json['next']),
      due: [
        for (final d in (json['due'] as List?) ?? const [])
          ?PlanInstallment.tryParse(d),
      ],
      chain: [
        for (final c in (json['chain'] as List?) ?? const [])
          if (c is Map && c['seq'] is num)
            (
              seq: (c['seq'] as num).toInt(),
              status: InstallmentStatus.fromJson(c['status']),
            ),
      ],
    );
  }

  final double principal;
  final int count;

  /// The first installment's due date.
  final DateTime start;
  final PlanInterestMethod method;
  final double? rate;
  final double? installmentAmount;
  final String? cardAccountId;
  final AccountRef? cardAccount;

  /// ปิดแผนก่อนกำหนด: the unmarked installments were skipped.
  final bool closed;

  /// Installments ticked paid.
  final int done;
  final int leftCount;
  final double paidPrincipal;
  final double leftPrincipal;
  final double leftInterest;
  final double leftTotal;
  final DateTime? lastDate;
  final PlanInstallment? next;

  /// Past their date, not ticked.
  final List<PlanInstallment> due;
  final List<({int seq, InstallmentStatus status})> chain;

  /// ผ่อนผ่านบัตร: paid with the card's statement, no line.
  bool get onCard => cardAccountId != null;

  bool get hasInterest => method != PlanInterestMethod.none;

  /// The installment a payment offers to tick: the oldest due one, else the
  /// next.
  PlanInstallment? get toMark => due.isNotEmpty ? due.first : next;

  RecurringPlanWrite toWrite() => RecurringPlanWrite(
    principal: principal,
    count: count,
    start: start,
    method: method,
    rate: rate,
    installmentAmount: installmentAmount,
    cardAccountId: cardAccountId,
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
    cardAccount,
    closed,
    done,
    leftCount,
    paidPrincipal,
    leftPrincipal,
    leftInterest,
    leftTotal,
    lastDate,
    next,
    due,
    chain,
  ];
}

class RecurringItemActions extends Equatable {
  const RecurringItemActions({
    this.pause = false,
    this.resume = false,
    this.archive = false,
    this.restore = false,
    this.delete = false,
    this.addLine = false,
  });

  factory RecurringItemActions.fromJson(Object? json) {
    final j = json is Map<String, dynamic> ? json : const <String, dynamic>{};
    return RecurringItemActions(
      pause: j['pause'] == true,
      resume: j['resume'] == true,
      archive: j['archive'] == true,
      restore: j['restore'] == true,
      delete: j['delete'] == true,
      addLine: j['add_line'] == true,
    );
  }

  final bool pause;
  final bool resume;
  final bool archive;
  final bool restore;
  final bool delete;
  final bool addLine;

  @override
  List<Object?> get props => [pause, resume, archive, restore, delete, addLine];
}

/// `GET /recurring/{id}` and every item write (BE `ItemPage`, 0.4.3).
class RecurringPage extends Equatable {
  const RecurringPage({
    required this.id,
    required this.name,
    required this.kind,
    required this.status,
    required this.lines,
    required this.json,
    this.counterparty,
    this.direction,
    this.plan,
    this.reminders = const [],
    this.stats,
    this.dueCount = 0,
    this.nextLineId,
    this.nextDate,
    this.nextAmount,
    this.monthTotal = 0,
    this.actions = const RecurringItemActions(),
    this.balances = const {},
  });

  factory RecurringPage.fromJson(Map<String, dynamic> json) {
    final next = json['next'];
    return RecurringPage(
      id: json['id'] as String,
      json: json,
      name: (json['name'] as String?) ?? '',
      kind: RecurringKind.fromJson(json['type'] as String?),
      status: RecurringStatus.fromJson(json['status'] as String?),
      counterparty: RecurringCounterparty.tryParse(json['counterparty']),
      direction: json['debt_direction'] is String
          ? DebtEntryDirection.parse(json['debt_direction'] as String)
          : null,
      plan: RecurringPlan.tryParse(json['plan']),
      reminders: [
        for (final r in (json['reminders'] as List?) ?? const [])
          if (r is Map<String, dynamic>) RecurringReminder.fromJson(r),
      ],
      lines: [
        for (final l in (json['lines'] as List?) ?? const [])
          if (l is Map<String, dynamic> && l['id'] is String)
            RecurringLine.fromJson(l, item: json),
      ],
      stats: json['stats'] is Map<String, dynamic>
          ? RecurringStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      dueCount: (json['due_count'] as num?)?.toInt() ?? 0,
      nextLineId: next is Map ? next['recurring_rule_id'] as String? : null,
      nextDate: next is Map ? parseYmd(next['date'] as String?) : null,
      nextAmount: next is Map ? (next['amount'] as num?)?.toDouble() : null,
      monthTotal: (json['month_total'] as num?)?.toDouble() ?? 0,
      actions: RecurringItemActions.fromJson(json['actions']),
      balances: WalletBalance.mapOf(json['account_balances']),
    );
  }

  final String id;

  /// The BE's item as sent.
  final Map<String, dynamic> json;
  final String name;
  final RecurringKind kind;
  final RecurringStatus status;
  final RecurringCounterparty? counterparty;
  final DebtEntryDirection? direction;
  final RecurringPlan? plan;
  final List<RecurringReminder> reminders;
  final List<RecurringLine> lines;
  final RecurringStats? stats;
  final int dueCount;
  final String? nextLineId;
  final DateTime? nextDate;
  final double? nextAmount;
  final double monthTotal;
  final RecurringItemActions actions;
  final Map<String, double> balances;

  /// The line the item's pieces read when one is needed: the next one's,
  /// else the first active, else the first. Null = no line (a card plan).
  RecurringLine? get mainLine {
    for (final l in lines) {
      if (l.id == nextLineId) return l;
    }
    for (final l in lines) {
      if (l.status == RecurringStatus.active) return l;
    }
    return lines.firstOrNull;
  }

  /// The item as one rule: [mainLine]'s numbers with the item's status and
  /// actions; an item with no line (a card plan) has no schedule.
  Recurring get view =>
      lineView(json, mainLine?.json ?? const {}, asItem: true);

  @override
  List<Object?> get props => [
    id,
    json,
    name,
    kind,
    status,
    counterparty,
    direction,
    plan,
    reminders,
    lines,
    stats,
    dueCount,
    nextLineId,
    nextDate,
    nextAmount,
    monthTotal,
    actions,
    balances,
  ];
}
