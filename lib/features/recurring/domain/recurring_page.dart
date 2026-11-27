import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart' show RecurrenceEnd, RecurrenceFreq, RecurrenceRule;
import '../../categories/domain/category.dart';
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

/// One rule of a recurring (BE `RecurringRule`): its own type, category,
/// tags, goal / debt target, source, amount, schedule and switches. [view]
/// reads it as a whole rule (the recurring's name with this rule's fields).
class RecurringLine extends Equatable {
  const RecurringLine({
    required this.id,
    required this.view,
    required this.json,
    this.paidBy,
    this.repaysReminderId,
    this.seq = 1,
    this.notifyOn = true,
    this.autoAcceptOn = false,
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
      repaysReminderId: json['repays_rule_id'] as String?,
      seq: (json['seq'] as num?)?.toInt() ?? 1,
      notifyOn: json['notify_on'] != false,
      autoAcceptOn: json['auto_accept_on'] == true,
      actions: RecurringLineActions.fromJson(json['actions']),
    );
  }

  final String id;

  /// The BE's line as sent (kept for a PUT of the whole item).
  final Map<String, dynamic> json;
  final Recurring view;

  /// คนจ่ายแทน: the person who pays for me; null = a wallet line.
  final EmbeddedPerson? paidBy;

  /// คืนคนจ่ายแทน: the person-paid rule of the recurring this one pays back
  /// (each round = that rule's latest round).
  final String? repaysReminderId;

  /// "Rule n": its place among the recurring's rules (1-based).
  final int seq;

  /// The switches in effect (the rule's own, else the user's default).
  final bool notifyOn;
  final bool autoAcceptOn;
  final RecurringLineActions actions;

  /// The rule's own switches as stored (null = the user's default).
  bool? get notify => json['notify'] as bool?;
  bool? get autoAccept => json['auto_accept'] as bool?;

  /// fixed | ask | schedule (a plan's installments) | follow (the rule it repays).
  String get amountMode => (json['amount_mode'] as String?) ?? 'fixed';

  /// An asked person repayment next to another rule of that person: the net,
  /// shown, not filled.
  double? get prefillHint => (json['prefill_hint'] as num?)?.toDouble();

  /// goal_reached | debt_cleared: a rule that stops by itself.
  String? get endText => json['end_text'] as String?;
  String? get debtPlanId => json['debt_plan_id'] as String?;
  RecurringCounterparty? get counterparty =>
      RecurringCounterparty.tryParse(json['counterparty']);

  RecurrenceRule get rule => view.rule;
  double? get amount => view.amount;
  AccountRef? get account => view.account;
  RecurringStatus get status => view.status;

  /// This rule as a `RecurringRuleInput` (unchanged), for a whole PUT.
  Map<String, dynamic> toInput() {
    final cp = counterparty;
    return {
      'id': id,
      'type': json['type'],
      'category_id': json['category_id'],
      'tag_ids': json['tag_ids'] ?? const [],
      'goal_id': json['goal_id'],
      if (debtPlanId != null)
        'debt_plan_id': debtPlanId
      else if (cp != null) ...{
        'counterparty': cp.institution != null
            ? {'institution_id': cp.institution!.id}
            : cp.person?.contactId != null
            ? {'contact_id': cp.person!.contactId}
            : {'person_name': cp.name},
        'debt_direction': json['debt_direction'],
      },
      'repays_rule_id': ?repaysReminderId,
      if (amountMode == 'fixed' || amountMode == 'ask')
        'amount_mode': amountMode,
      'amount': json['amount'],
      'source': json['source'],
      'to_account_id': json['to_account_id'],
      'debt_kind': ?json['debt_kind'],
      'schedule': json['schedule'],
      'notify': json['notify'],
      'auto_accept': json['auto_accept'],
    };
  }

  @override
  List<Object?> get props => [id, json, view, paidBy, actions];
}

/// [line] of [item] as one rule: the recurring's identity, the rule's fields.
Recurring lineView(
  Map<String, dynamic> item,
  Map<String, dynamic> line, {
  bool asItem = false,
}) {
  final schedule = line['schedule'] as Map<String, dynamic>?;
  final counterparty = line['counterparty'];
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
    'type': line['type'],
    'category': line['category'],
    'tags': line['tags'],
    'goal_id': line['goal_id'],
    'goal': line['goal'],
    'person': ?person,
    'direction': line['debt_direction'],
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

/// One page a recurring's rules show on (goal / person / institution / plan /
/// card), BE `RecurringTouch`.
class RecurringTouch extends Equatable {
  const RecurringTouch({
    required this.kind,
    required this.id,
    required this.name,
    this.key,
  });

  factory RecurringTouch.fromJson(Map<String, dynamic> json) => RecurringTouch(
    kind: (json['kind'] as String?) ?? 'goal',
    id: (json['id'] as String?) ?? '',
    name: (json['name'] as String?) ?? '',
    key: json['key'] as String?,
  );

  /// goal | person | institution | plan | card
  final String kind;
  final String id;
  final String name;

  /// A person / institution: its debt page key.
  final String? key;

  @override
  List<Object?> get props => [kind, id, name, key];
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

/// A card plan's purchase (BE `PlanPurchase`): the full-price expense on
/// the card it was made from.
class PlanPurchase extends Equatable {
  const PlanPurchase({
    required this.id,
    required this.amount,
    required this.date,
    this.description,
    this.category,
  });

  static PlanPurchase? tryParse(Object? json) {
    if (json is! Map<String, dynamic> || json['id'] is! String) return null;
    final c = json['category'];
    return PlanPurchase(
      id: json['id'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      date: parseYmd(json['date'] as String?) ?? today(),
      description: json['description'] as String?,
      category: c is Map<String, dynamic> ? CategoryRef.fromJson(c) : null,
    );
  }

  final String id;
  final double amount;
  final DateTime date;
  final String? description;
  final CategoryRef? category;

  @override
  List<Object?> get props => [id, amount, date, description, category];
}

/// A debt item's plan (BE `PlanView`): information; the balance counts the
/// debt rows only.
class RecurringPlan extends Equatable {
  const RecurringPlan({
    this.id,
    required this.principal,
    required this.count,
    required this.start,
    this.method = PlanInterestMethod.none,
    this.rate,
    this.installmentAmount,
    this.cardAccount,
    this.cardAccountId,
    this.purchase,
    this.closed = false,
    this.done = 0,
    this.leftCount = 0,
    this.paidPrincipal = 0,
    this.paidTotal = 0,
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
    final creditor = json['creditor'];
    final card = creditor is Map ? creditor['account'] : null;
    return RecurringPlan(
      id: json['id'] as String?,
      principal: (json['principal'] as num?)?.toDouble() ?? 0,
      count: (json['count'] as num).toInt(),
      start: parseYmd(json['start_date'] as String?) ?? today(),
      method: PlanInterestMethod.fromJson(json['interest_method']),
      rate: (json['interest_rate'] as num?)?.toDouble(),
      installmentAmount: (json['installment_amount'] as num?)?.toDouble(),
      cardAccountId: card is Map ? card['id'] as String? : null,
      cardAccount: card is Map<String, dynamic>
          ? AccountRef.fromJson(card)
          : null,
      purchase: PlanPurchase.tryParse(json['purchase']),
      closed: json['closed'] == true,
      done: (json['done'] as num?)?.toInt() ?? 0,
      leftCount: (json['left_count'] as num?)?.toInt() ?? 0,
      paidPrincipal: (json['paid_principal'] as num?)?.toDouble() ?? 0,
      paidTotal: (json['paid_total'] as num?)?.toDouble() ?? 0,
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

  /// The debt plan (0.4.3: /debt-plans/{id}).
  final String? id;

  final String? cardAccountId;
  final AccountRef? cardAccount;

  /// A card plan made by quick create: its purchase on the card.
  final PlanPurchase? purchase;

  /// ปิดแผนก่อนกำหนด: the unmarked installments were skipped.
  final bool closed;

  /// Installments ticked paid.
  final int done;
  final int leftCount;
  final double paidPrincipal;

  /// Principal + interest of the ticked installments (a card plan: billed).
  final double paidTotal;
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

  /// The round as a rule: monthly on the first installment's day, [count]
  /// times (a card plan has no line to read one from).
  RecurrenceRule get rule => RecurrenceRule(
    freq: RecurrenceFreq.monthly,
    start: start,
    monthDays: {start.day},
    end: RecurrenceEnd.afterCount(count),
  );

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
    purchase,
    closed,
    done,
    leftCount,
    paidPrincipal,
    paidTotal,
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
      addLine: j['add_rule'] == true,
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
    this.trackingType = 'other',
    this.touches = const [],
    this.plan,
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
    final rules = (json['rules'] as List?) ?? const [];
    final first = rules.whereType<Map<String, dynamic>>().firstOrNull;
    return RecurringPage(
      id: json['id'] as String,
      json: json,
      name: (json['name'] as String?) ?? '',
      kind: RecurringKind.fromJson(first?['type'] as String?),
      status: RecurringStatus.fromJson(json['status'] as String?),
      trackingType: (json['tracking_type'] as String?) ?? 'other',
      touches: [
        for (final t in (json['touches'] as List?) ?? const [])
          if (t is Map<String, dynamic>) RecurringTouch.fromJson(t),
      ],
      plan: RecurringPlan.tryParse(json['plan']),
      lines: [
        for (final l in rules)
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

  /// The first rule's money type (each rule has its own).
  final RecurringKind kind;
  final RecurringStatus status;

  /// bill | subscription | installment | credit_card | person_debt | income |
  /// saving | other: a filter on the list, no effect on the rules.
  final String trackingType;

  /// What its rules touch on other pages; empty = self-made (ตั้งเอง).
  final List<RecurringTouch> touches;
  final RecurringPlan? plan;
  final List<RecurringLine> lines;

  /// The first debt rule's counterparty / direction (the debt pieces).
  RecurringCounterparty? get counterparty {
    for (final l in lines) {
      final c = l.counterparty;
      if (c != null) return c;
    }
    return null;
  }

  DebtEntryDirection? get direction {
    for (final l in lines) {
      final d = l.json['debt_direction'];
      if (d is String) return DebtEntryDirection.parse(d);
    }
    return null;
  }

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
    trackingType,
    touches,
    plan,
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
