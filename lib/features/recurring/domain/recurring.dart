import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import '../../pending/domain/pending_transaction.dart';
import '../../personal_debts/domain/debt_direction.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction_type.dart';
import 'recurrence_rule.dart';
import 'recurring_item.dart';
import 'recurring_page.dart' show RecurringCounterparty;

enum RecurringStatus {
  active,
  paused,
  archived,

  /// ครบแล้ว: an item with an end whose every round is recorded / skipped
  /// (0.4.3; the app also derives it, [Recurring.isComplete]).
  done;

  static RecurringStatus fromJson(String? v) => RecurringStatus.values
      .firstWhere((s) => s.name == v, orElse: () => RecurringStatus.active);
}

/// Why a paused setting is paused (0.4.1-1 R7); null unless paused.
enum RecurringPauseReason {
  manual,

  /// "ค้าง 3 งวด": 3 occurrences were waiting when a 4th came due.
  overdueLimit,

  /// ออมเงิน whose goal was closed / archived.
  goalInactive,

  /// หนี้ จ่ายหนี้: nothing owed for 3 rounds; a new debt with the person
  /// starts it again by itself (0.4.1-2 K5).
  noBalance;

  static RecurringPauseReason? fromJson(Object? v) => switch (v) {
    'manual' => manual,
    'overdue_limit' => overdueLimit,
    'goal_inactive' => goalInactive,
    'no_balance' => noBalance,
    _ => null,
  };
}

/// A recurring item's type (0.4.3: 5 types, fixed once created; the type
/// decides what its reminders can do). ค่าสมาชิก / บิล are expenses (a bill
/// asks its amount each round: amount_mode ask).
enum RecurringKind {
  /// รายจ่าย: expense / คนจ่ายแทน / คืนคนจ่ายแทน.
  expense,
  income,

  /// โอน: wallet → wallet.
  transfer,

  /// ออมเงิน: wallet → a saving goal (or ยังไม่จัดสรร).
  saving,

  /// หนี้: each round books a debt / repayment with the item's counterparty.
  /// No category / tags.
  debt;

  /// The wire `type`; an older payload's `kind` (subscription | installment |
  /// income | reminder) still reads.
  static RecurringKind fromJson(String? type, {String? legacyKind}) {
    for (final k in values) {
      if (k.name == type && k != expense && k != income && k != transfer) {
        return k;
      }
    }
    return switch (legacyKind) {
      'saving' => saving,
      'debt' => debt,
      'bill' => expense,
      'expense' => expense,
      'transfer' => transfer,
      'subscription' => expense,
      'installment' => expense,
      'income' => income,
      'reminder' => type == 'transfer' ? transfer : expense,
      _ => switch (type) {
        'income' => income,
        'transfer' => transfer,
        _ => expense,
      },
    };
  }

  String toJson() => name;

  /// The money side of a round: saving leaves the wallet, so it reads as an
  /// expense; a debt's side comes from its direction, not this type.
  TransactionType get defaultType => switch (this) {
    income => TransactionType.income,
    transfer => TransactionType.transfer,
    _ => TransactionType.expense,
  };

  /// May start without an amount (บิล / โอน: เตือนจ่าย before).
  bool get amountOptional => this == expense || this == transfer;
}

/// The wire type as a money type: the item types other than income /
/// transfer read as an expense here (the kind and, for a debt, the direction
/// decide how they show).
TransactionType recurringTypeFromJson(String? v) => switch (v) {
  'income' => TransactionType.income,
  'transfer' => TransactionType.transfer,
  _ => TransactionType.expense,
};

/// A หนี้ rule's entry kind: จดหนี้ (`debt`) or จ่ายหนี้ (`repayment`).
DebtEntrySub? recurringDebtSubFromJson(Object? v) => switch (v) {
  'debt' => DebtEntrySub.record,
  'repayment' => DebtEntrySub.repay,
  _ => null,
};

String recurringDebtSubToJson(DebtEntrySub s) =>
    s == DebtEntrySub.record ? 'debt' : 'repayment';

/// The goal a saving rule saves into (null = ยังไม่จัดสรร).
class SavingGoalRef extends Equatable {
  const SavingGoalRef({required this.id, required this.name});

  static SavingGoalRef? tryParse(Object? json) => json is Map<String, dynamic>
      ? SavingGoalRef(
          id: json['id'] as String,
          name: (json['name'] as String?) ?? '',
        )
      : null;

  final String id;
  final String name;

  @override
  List<Object?> get props => [id, name];
}

class RecurringActions extends Equatable {
  const RecurringActions({
    this.pause = false,
    this.resume = false,
    this.archive = false,
    this.restore = false,
    this.extend = false,
  });

  factory RecurringActions.fromJson(Map<String, dynamic>? json) =>
      RecurringActions(
        pause: json?['pause'] == true,
        resume: json?['resume'] == true,
        archive: json?['archive'] == true,
        restore: json?['restore'] == true,
        extend: json?['extend'] == true,
      );

  final bool pause;
  final bool resume;
  final bool archive;
  final bool restore;
  final bool extend;

  @override
  List<Object?> get props => [pause, resume, archive, restore, extend];
}

class RecurringCounts extends Equatable {
  const RecurringCounts({
    this.upcoming = 0,
    this.notCreated = 0,
    this.pending = 0,
    this.done = 0,
    this.archived = 0,
  });

  factory RecurringCounts.fromJson(Map<String, dynamic>? json) {
    int n(String k) => (json?[k] as num?)?.toInt() ?? 0;
    return RecurringCounts(
      upcoming: n('upcoming'),
      notCreated: n('not_created'),
      pending: n('pending'),
      done: n('done'),
      archived: n('archived'),
    );
  }

  final int upcoming;
  final int notCreated;
  final int pending;
  final int done;
  final int archived;

  int get produced => notCreated + pending + done + archived;

  @override
  List<Object?> get props => [upcoming, notCreated, pending, done, archived];
}

class CurrentOccurrence extends Equatable {
  const CurrentOccurrence({
    required this.itemId,
    required this.date,
    required this.daysUntil,
    required this.status,
    required this.ruleId,
    this.amount,
    this.slot,
  });

  /// A computed occurrence has no row: its id is `slot:{line}:{slot}`, the
  /// same key as RecurringItem.id. [recurringId]: the item it belongs to.
  factory CurrentOccurrence.fromJson(
    Map<String, dynamic> json, {
    required String recurringId,
  }) {
    final slot = json['slot'] as String?;
    final line = json['recurring_reminder_id'] as String? ?? recurringId;
    RecurringLineIndex.remember(line: line, item: recurringId);
    return CurrentOccurrence(
      itemId: json['item_id'] as String? ?? 'slot:$line:$slot',
      ruleId: line,
      slot: slot,
      date: parseYmd(json['date'] as String?) ?? DateTime.now(),
      daysUntil: (json['days_until'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble(),
      status: OccurrenceState.parse(json['status'] as String?),
    );
  }

  final String itemId;

  /// Its line (`recurring_reminder_id`): a round is addressed by line + slot.
  final String ruleId;

  /// The original date ("YYYY-MM-DD"); null from an old BE.
  final String? slot;
  final DateTime date;
  final int daysUntil;

  final double? amount;
  final OccurrenceState status;

  @override
  List<Object?> get props => [
    itemId,
    ruleId,
    slot,
    date,
    daysUntil,
    amount,
    status,
  ];
}

/// One occurrence of an installment rule's chain (the BE sends it for rules
/// with an end and ≤ 60 occurrences).
class ChainSlot extends Equatable {
  const ChainSlot({required this.slot, required this.state});

  factory ChainSlot.fromJson(Map<String, dynamic> json) => ChainSlot(
    slot: parseYmd(json['slot'] as String?) ?? DateTime.now(),
    state: OccurrenceState.parse(json['status'] as String?),
  );

  final DateTime slot;
  final OccurrenceState state;

  @override
  List<Object?> get props => [slot, state];
}

/// What the detail hero shows: totals of the recorded occurrences (those with
/// a tx; `paid` without a tx has no amount).
class RecurringStats extends Equatable {
  const RecurringStats({
    this.paidCount = 0,
    this.paidTotal = 0,
    this.remainingTotal,
    this.lastPeriod,
    this.avgAmount,
    this.lastAmount,
    this.maxAmount,
    this.series = const [],
  });

  factory RecurringStats.fromJson(Map<String, dynamic> json) => RecurringStats(
    paidCount: (json['paid_count'] as num?)?.toInt() ?? 0,
    paidTotal: (json['paid_total'] as num?)?.toDouble() ?? 0,
    remainingTotal: (json['remaining_total'] as num?)?.toDouble(),
    lastPeriod: parseYmd(json['last_period'] as String?),
    avgAmount: (json['avg_amount'] as num?)?.toDouble(),
    lastAmount: (json['last_amount'] as num?)?.toDouble(),
    maxAmount: (json['max_amount'] as num?)?.toDouble(),
    series: [
      for (final s in (json['series'] as List?) ?? const [])
        (
          slot:
              parseYmd((s as Map<String, dynamic>)['slot'] as String?) ??
              DateTime.now(),
          amount: (s['amount'] as num?)?.toDouble() ?? 0,
        ),
    ],
  );

  final int paidCount;
  final double paidTotal;

  /// Only for rules with an end.
  final double? remainingTotal;
  final DateTime? lastPeriod;
  final double? avgAmount;
  final double? lastAmount;
  final double? maxAmount;

  /// Recorded occurrences by slot, oldest first (newest 24).
  final List<({DateTime slot, double amount})> series;

  @override
  List<Object?> get props => [
    paidCount,
    paidTotal,
    remainingTotal,
    lastPeriod,
    avgAmount,
    lastAmount,
    maxAmount,
    series,
  ];
}

class Recurring extends Equatable {
  const Recurring({
    required this.id,
    required this.name,
    required this.type,
    required this.rule,
    required this.status,
    this.kind = RecurringKind.expense,
    this.amount,
    this.description,
    this.note,
    this.iconCode,
    this.account,
    this.toAccount,
    this.category,
    this.tags = const [],
    this.goalId,
    this.goal,
    this.trialUntil,
    this.yearlyCost = 0,
    this.monthlyAmount,
    this.savedCount = 0,
    this.pendingCount = 0,
    this.nextAmount,
    this.currentOccurrence,
    this.nextDate,
    this.daysUntil,
    this.progressDone = 0,
    this.progressTotal,
    this.endingSoon = false,
    this.counts = const RecurringCounts(),
    this.editedAny = false,
    this.actions = const RecurringActions(),
    this.avgAmount,
    this.chain,
    this.recordedTxCount = 0,
    this.autoCreate = false,
    this.pauseReason,
    this.person,
    this.debtSub,
    this.direction,
    this.personBalance,
    this.zeroRounds = 0,
    this.createdAt,
    this.updatedAt,
    this.linesCount = 1,
    this.monthTotal,
    this.counterparty,
    this.planDone,
    this.planCount,
    this.paidBy,
  });

  /// 0.4.3 list rows: the item's lines, this month's total over them, its
  /// counterparty (หนี้), its plan's ticked / all installments and a
  /// single line's คนจ่ายแทน.
  final int linesCount;
  final double? monthTotal;
  final RecurringCounterparty? counterparty;
  final int? planDone;
  final int? planCount;
  final EmbeddedPerson? paidBy;

  final String id;
  final String name;
  final String? description;
  final String? note;
  final PpForgeIconCode? iconCode;
  final RecurringKind kind;

  /// หนี้ only: the person, จดหนี้ | จ่ายหนี้, the money's direction, the
  /// person's net now (> 0 = they owe me) and the rounds in a row with
  /// nothing owed (3 = paused, [RecurringPauseReason.noBalance]).
  final EmbeddedPerson? person;
  final DebtEntrySub? debtSub;
  final DebtEntryDirection? direction;
  final double? personBalance;
  final int zeroRounds;
  final TransactionType type;

  final double? amount;
  final AccountRef? account;

  final AccountRef? toAccount;
  final EmbeddedCategory? category;
  final List<TagRef> tags;

  /// Saving only: the goal it saves into; null = ยังไม่จัดสรร.
  final String? goalId;
  final SavingGoalRef? goal;
  final RecurrenceRule rule;
  final RecurringStatus status;

  final DateTime? trialUntil;

  final double yearlyCost;

  final double? monthlyAmount;
  final int savedCount;
  final int pendingCount;

  final double? nextAmount;
  final CurrentOccurrence? currentOccurrence;
  final DateTime? nextDate;
  final int? daysUntil;

  final int progressDone;
  final int? progressTotal;

  final bool endingSoon;
  final RecurringCounts counts;

  final bool editedAny;
  final RecurringActions actions;

  /// Average of the recorded amounts, else the rule amount.
  final double? avgAmount;
  final List<ChainSlot>? chain;

  /// Occurrences recorded as a tx: a rule edit asks whether to update them.
  final int recordedTxCount;

  /// บันทึกอัตโนมัติ: each occurrence becomes a tx on its day, no tap.
  final bool autoCreate;

  final RecurringPauseReason? pauseReason;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasAmount => amount != null && amount! > 0;

  /// The one rule the detail page shows by (owner 2026-11-17): an end (a
  /// count, an end date, or picked dates) vs open-ended.
  bool get hasEnd =>
      rule.freq == RecurrenceFreq.dates ||
      rule.end.kind != RecurrenceEndKind.never;

  /// ครบแล้ว: ended, and nothing is left to come or to handle.
  bool get isComplete =>
      status == RecurringStatus.done ||
      (hasEnd &&
          status != RecurringStatus.archived &&
          counts.produced > 0 &&
          counts.upcoming == 0 &&
          counts.notCreated == 0 &&
          counts.pending == 0);

  bool get isSaving => kind == RecurringKind.saving;

  bool get isDebt => kind == RecurringKind.debt;

  static const _types = {
    'expense',
    'subscription',
    'bill',
    'income',
    'transfer',
    'saving',
    'debt',
  };

  /// Null for a rule the app has no type for, so one such rule doesn't break
  /// a whole list.
  static Recurring? tryParse(Object? json) =>
      json is Map<String, dynamic> &&
          _types.contains((json['type'] as String?) ?? 'expense')
      ? Recurring.fromJson(json)
      : null;

  factory Recurring.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] as Map<String, dynamic>?;
    final next = json['next'] is Map ? json['next'] as Map : null;
    final counterparty = RecurringCounterparty.tryParse(json['counterparty']);
    final plan = json['plan'] is Map ? json['plan'] as Map : null;
    return Recurring(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      note: json['note'] as String?,
      iconCode: json['icon_code'] is Map<String, dynamic>
          ? PpForgeIconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
      kind: RecurringKind.fromJson(
        json['type'] as String?,
        legacyKind: json['kind'] as String?,
      ),
      person: json['person'] is Map
          ? EmbeddedPerson.fromJson(
              (json['person'] as Map).cast<String, dynamic>(),
            )
          : counterparty?.person ??
                (counterparty == null || counterparty.isInstitution
                    ? null
                    : EmbeddedPerson(name: counterparty.name)),
      debtSub: recurringDebtSubFromJson(json['debt_kind']),
      direction: json['direction'] is String
          ? DebtEntryDirection.parse(json['direction'] as String)
          : null,
      personBalance: (json['person_balance'] as num?)?.toDouble(),
      zeroRounds: (json['zero_rounds'] as num?)?.toInt() ?? 0,
      // หนี้: money in or out by its direction (received = in).
      type: json['type'] == 'debt' && json['direction'] == 'received'
          ? TransactionType.income
          : recurringTypeFromJson(json['type'] as String?),
      goalId: json['goal_id'] as String?,
      goal: SavingGoalRef.tryParse(json['goal']),
      amount: (json['amount'] as num?)?.toDouble(),
      account: json['account'] is Map<String, dynamic>
          ? AccountRef.fromJson(json['account'] as Map<String, dynamic>)
          : null,
      toAccount: json['to_account'] is Map<String, dynamic>
          ? AccountRef.fromJson(json['to_account'] as Map<String, dynamic>)
          : null,
      category: json['category'] is Map<String, dynamic>
          ? EmbeddedCategory.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      tags: [
        for (final t in (json['tags'] as List?) ?? const [])
          TagRef.fromJson(t as Map<String, dynamic>),
      ],
      rule: recurrenceFromJson(
        json['rule'] as Map<String, dynamic>?,
        start: json['start_date'] as String?,
        end: json['end'] as Map<String, dynamic>?,
      ),
      status: RecurringStatus.fromJson(json['status'] as String?),
      trialUntil: parseYmd(json['trial_until'] as String?),
      yearlyCost: (json['yearly_cost'] as num?)?.toDouble() ?? 0,
      monthlyAmount: (json['monthly_amount'] as num?)?.toDouble(),
      savedCount: (json['saved_count'] as num?)?.toInt() ?? 0,
      pendingCount: (json['pending_count'] as num?)?.toInt() ?? 0,
      nextAmount: ((json['next_amount'] ?? next?['amount']) as num?)
          ?.toDouble(),
      currentOccurrence: json['current_occurrence'] is Map<String, dynamic>
          ? CurrentOccurrence.fromJson(
              json['current_occurrence'] as Map<String, dynamic>,
              recurringId: json['id'] as String,
            )
          : null,
      nextDate: parseYmd((json['next_date'] ?? next?['date']) as String?),
      daysUntil: ((json['days_until'] ?? next?['days_until']) as num?)?.toInt(),
      progressDone: (progress?['done'] as num?)?.toInt() ?? 0,
      progressTotal: (progress?['total'] as num?)?.toInt(),
      endingSoon: json['ending_soon'] == true,
      counts: RecurringCounts.fromJson(json['counts'] as Map<String, dynamic>?),
      editedAny: json['edited_any'] == true,
      actions: RecurringActions.fromJson(
        json['actions'] as Map<String, dynamic>?,
      ),
      avgAmount: (json['avg_amount'] as num?)?.toDouble(),
      chain: json['chain'] is List
          ? [
              for (final c in json['chain'] as List)
                ChainSlot.fromJson(c as Map<String, dynamic>),
            ]
          : null,
      recordedTxCount: (json['recorded_tx_count'] as num?)?.toInt() ?? 0,
      autoCreate: json['auto_create'] == true,
      pauseReason: RecurringPauseReason.fromJson(json['pause_reason']),
      createdAt: DateTime.tryParse((json['created_at'] as String?) ?? ''),
      updatedAt: DateTime.tryParse((json['updated_at'] as String?) ?? ''),
      linesCount: (json['reminders_count'] as num?)?.toInt() ?? 1,
      monthTotal: (json['month_total'] as num?)?.toDouble(),
      counterparty: counterparty,
      planDone: (plan?['done'] as num?)?.toInt(),
      planCount: (plan?['count'] as num?)?.toInt(),
      paidBy: json['paid_by'] is Map
          ? EmbeddedPerson.fromJson(
              (json['paid_by'] as Map).cast<String, dynamic>(),
            )
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    note,
    iconCode,
    kind,
    type,
    amount,
    account,
    toAccount,
    category,
    tags,
    goalId,
    goal,
    rule,
    status,
    trialUntil,
    yearlyCost,
    monthlyAmount,
    savedCount,
    pendingCount,
    nextAmount,
    currentOccurrence,
    nextDate,
    daysUntil,
    progressDone,
    progressTotal,
    endingSoon,
    counts,
    editedAny,
    actions,
    avgAmount,
    chain,
    recordedTxCount,
    autoCreate,
    pauseReason,
    person,
    debtSub,
    direction,
    personBalance,
    zeroRounds,
    createdAt,
    updatedAt,
    linesCount,
    monthTotal,
    counterparty,
    planDone,
    planCount,
    paidBy,
  ];
}

/// A line's schedule on the wire (0.4.3): the rule's fields inline, then
/// `start_date` and `end`.
Map<String, dynamic> scheduleToJson(RecurrenceRule r) {
  final j = recurrenceToJson(r);
  return {
    ...(j['rule'] as Map<String, dynamic>),
    'start_date': j['start_date'],
    'end': j['end'],
  };
}

/// A line's schedule from the wire (see [scheduleToJson]).
RecurrenceRule scheduleFromJson(Map<String, dynamic>? s) => recurrenceFromJson(
  s,
  start: s?['start_date'] as String?,
  end: s?['end'] as Map<String, dynamic>?,
);

/// One line of an item write (`LineInput`): a wallet or a person paying for
/// me ([paidByContactId] / [paidByName]), its amount and its schedule. [id]
/// = update that line; none = a new one.
class RecurringLineWrite extends Equatable {
  const RecurringLineWrite({
    required this.rule,
    this.id,
    this.amount,
    this.accountId,
    this.paidByContactId,
    this.paidByName,
    this.toAccountId,
    this.debtSub,
    this.repaysReminderId,
    this.notifyOnly = false,
    this.autoCreate = false,
  });

  final String? id;
  final double? amount;

  /// คืนคนจ่ายแทน: the person-paid line it pays back.
  final String? repaysReminderId;
  final String? accountId;
  final String? paidByContactId;
  final String? paidByName;
  final String? toAccountId;
  final DebtEntrySub? debtSub;

  /// แค่แจ้งเตือน: nothing is booked.
  final bool notifyOnly;
  final RecurrenceRule rule;
  final bool autoCreate;

  bool get paidBy => paidByContactId != null || paidByName != null;

  /// No amount (0.4.3): the round asks it (amount_mode ask); a debt round
  /// without one takes its plan's installment.
  Map<String, dynamic> toJson() => {
    'id': ?id,
    if ((amount ?? 0) > 0) 'amount': amount,
    if ((amount ?? 0) <= 0 &&
        debtSub == null &&
        repaysReminderId == null &&
        !notifyOnly)
      'amount_mode': 'ask',
    'notify_only': notifyOnly,
    'repays_reminder_id': ?repaysReminderId,
    'source': paidBy
        ? {
            'paid_by': {
              'contact_id': paidByContactId,
              'person_name': paidByContactId == null ? paidByName : null,
            },
          }
        : {'account_id': accountId},
    'to_account_id': toAccountId,
    if (debtSub != null) 'debt_kind': recurringDebtSubToJson(debtSub!),
    'schedule': scheduleToJson(rule),
    'auto_create': autoCreate,
  };

  @override
  List<Object?> get props => [
    id,
    amount,
    accountId,
    paidByContactId,
    paidByName,
    toAccountId,
    debtSub,
    rule,
    autoCreate,
  ];
}

/// How a plan's interest is worked out (`interest_method`).
enum PlanInterestMethod {
  none,
  flat,
  reducing,
  fixed,
  manual;

  static PlanInterestMethod fromJson(Object? v) =>
      values.firstWhere((m) => m.name == v, orElse: () => none);
}

/// `PlanInput`: a debt item's installment plan.
class RecurringPlanWrite extends Equatable {
  const RecurringPlanWrite({
    required this.principal,
    required this.count,
    required this.start,
    this.method = PlanInterestMethod.none,
    this.rate,
    this.installmentAmount,
    this.cardAccountId,
    this.openingAccountId,
  });

  final double principal;
  final int count;

  /// The first installment's due date.
  final DateTime start;
  final PlanInterestMethod method;

  /// % a year (flat / reducing).
  final double? rate;

  /// fixed: the amount of every installment.
  final double? installmentAmount;

  /// ผ่อนผ่านบัตร: the card that holds the debt (no opening debt row).
  final String? cardAccountId;

  /// The wallet the opening debt row's money went through (optional).
  final String? openingAccountId;

  Map<String, dynamic> toJson() => {
    'principal': principal,
    'count': count,
    'start_date': ymd(start),
    'interest_method': method.name,
    'interest_rate': rate,
    'installment_amount': installmentAmount,
    'opening_account_id': ?openingAccountId,
  };

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

/// When a reminder fires (`anchor`): before a round is due, before the item
/// starts or before it ends.
enum ReminderAnchor {
  due,
  start,
  end;

  static ReminderAnchor fromJson(Object? v) =>
      values.firstWhere((a) => a.name == v, orElse: () => due);
}

class RecurringReminder extends Equatable {
  const RecurringReminder({
    this.anchor = ReminderAnchor.due,
    this.daysBefore = 1,
    this.time = '09:00',
    this.id,
  });

  factory RecurringReminder.fromJson(Map<String, dynamic> json) =>
      RecurringReminder(
        id: json['id'] as String?,
        anchor: ReminderAnchor.fromJson(json['anchor']),
        daysBefore: (json['days_before'] as num?)?.toInt() ?? 0,
        time: (json['time'] as String?) ?? '09:00',
      );

  final String? id;
  final ReminderAnchor anchor;
  final int daysBefore;

  /// "HH:mm".
  final String time;

  RecurringReminder copyWith({
    ReminderAnchor? anchor,
    int? daysBefore,
    String? time,
  }) => RecurringReminder(
    id: id,
    anchor: anchor ?? this.anchor,
    daysBefore: daysBefore ?? this.daysBefore,
    time: time ?? this.time,
  );

  Map<String, dynamic> toJson() => {
    'anchor': anchor.name,
    'days_before': daysBefore,
    'time': time,
  };

  @override
  List<Object?> get props => [id, anchor, daysBefore, time];
}

/// `POST / PUT /recurring` (`RecurringInput`, 0.4.3): the item, its
/// counterparty (หนี้: a contact, a typed name or an institution), its plan,
/// reminders and every line ([lines]: one with an id = update, none = new,
/// one left out = deleted).
class RecurringWrite extends Equatable {
  const RecurringWrite({
    required this.name,
    required this.kind,
    required this.lines,
    this.description,
    this.note,
    this.iconCode,
    this.categoryId,
    this.tagIds = const [],
    this.goalId,
    this.contactId,
    this.personName,
    this.institutionId,
    this.direction,
    this.plan,
    this.reminders = const [],
  });

  final String name;
  final RecurringKind kind;
  final String? description;
  final String? note;
  final PpForgeIconCode? iconCode;
  final String? categoryId;
  final List<String> tagIds;

  /// Saving only (null = ยังไม่จัดสรร).
  final String? goalId;

  /// หนี้ only: exactly one of these.
  final String? contactId;
  final String? personName;
  final String? institutionId;

  /// หนี้ only: paid = they owe me, received = I owe them.
  final DebtEntryDirection? direction;
  final RecurringPlanWrite? plan;
  final List<RecurringReminder> reminders;

  /// LineInput JSON per line ([RecurringLineWrite.toJson], or a line kept as
  /// the BE sent it).
  final List<Map<String, dynamic>> lines;

  /// [debtPlanId] — the debt plan the item pays (0.4.3: the plan is written
  /// apart, see RecurringRepository.create).
  Map<String, dynamic> toJson({String? debtPlanId}) {
    final debt = kind == RecurringKind.debt;
    final paysPlan = debt && debtPlanId != null;
    final alerts = [for (final r in reminders) r.toJson()];
    final saving = kind == RecurringKind.saving;
    final noCategory = debt || saving || kind == RecurringKind.transfer;
    return {
      'name': name,
      'type': kind.toJson(),
      'description': description,
      'note': note,
      'icon_code': iconCode?.toJson(),
      'category_id': noCategory ? null : categoryId,
      'tag_ids': debt || saving ? const <String>[] : tagIds,
      'goal_id': saving ? goalId : null,
      'debt_plan_id': paysPlan ? debtPlanId : null,
      'counterparty': debt && !paysPlan
          ? {
              'contact_id': institutionId == null ? contactId : null,
              'person_name': institutionId == null && contactId == null
                  ? personName
                  : null,
              'institution_id': institutionId,
            }
          : null,
      'debt_direction': debt && !paysPlan
          ? (direction ?? DebtEntryDirection.paid).wire
          : null,
      // 0.4.3: alerts sit on each reminder; the form still edits one set
      'reminders': [
        for (final l in lines) {...l, 'alerts': alerts},
      ],
    };
  }

  @override
  List<Object?> get props => [
    name,
    kind,
    description,
    note,
    iconCode,
    categoryId,
    tagIds,
    goalId,
    contactId,
    personName,
    institutionId,
    direction,
    plan,
    reminders,
    lines,
  ];
}
