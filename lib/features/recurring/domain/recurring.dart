import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import '../../pending/domain/pending_transaction.dart';
import '../../personal_debts/domain/debt_direction.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction_type.dart';
import 'recurrence_rule.dart';

enum RecurringStatus {
  active,
  paused,
  archived;

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

enum RecurringKind {
  subscription,
  installment,
  income,
  reminder,

  /// ออมเงิน: wallet → a saving goal (or ยังไม่จัดสรร); the BE's type `saving`.
  saving,

  /// หนี้ (0.4.1-2 K): each occurrence books a person-book entry (จดหนี้ |
  /// จ่ายหนี้) with one person; the BE's type `debt`. No category / tags.
  debt;

  static RecurringKind fromJson(String? v) => RecurringKind.values.firstWhere(
    (k) => k.name == v,
    orElse: () => RecurringKind.subscription,
  );

  String toJson() => name;

  /// Saving leaves the wallet, so the app treats it as an expense; a debt's
  /// side comes from its direction, not this type.
  TransactionType get defaultType =>
      this == income ? TransactionType.income : TransactionType.expense;
}

/// The wire type: `saving` / `debt` read as an expense here (the kind and,
/// for a debt, the direction decide how they show).
TransactionType recurringTypeFromJson(String? v) => v == 'saving' || v == 'debt'
    ? TransactionType.expense
    : TransactionType.fromJson(v ?? 'expense');

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
    this.amount,
    this.slot,
  });

  /// A computed occurrence has no row: its id is `slot:{rule}:{slot}`, the
  /// same key as RecurringItem.id.
  factory CurrentOccurrence.fromJson(
    Map<String, dynamic> json, {
    required String ruleId,
  }) {
    final slot = json['slot'] as String?;
    return CurrentOccurrence(
      itemId: json['item_id'] as String? ?? 'slot:$ruleId:$slot',
      slot: slot,
      date: parseYmd(json['date'] as String?) ?? DateTime.now(),
      daysUntil: (json['days_until'] as num?)?.toInt() ?? 0,
      amount: (json['amount'] as num?)?.toDouble(),
      status: OccurrenceState.parse(json['status'] as String?),
    );
  }

  final String itemId;

  /// The original date ("YYYY-MM-DD"); null from an old BE.
  final String? slot;
  final DateTime date;
  final int daysUntil;

  final double? amount;
  final OccurrenceState status;

  @override
  List<Object?> get props => [itemId, slot, date, daysUntil, amount, status];
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
    this.kind = RecurringKind.subscription,
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
  });

  final String id;
  final String name;
  final String? description;
  final String? note;
  final IconCode? iconCode;
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

  bool get isSaving => kind == RecurringKind.saving;

  bool get isDebt => kind == RecurringKind.debt;

  static const _types = {'expense', 'income', 'transfer', 'saving', 'debt'};

  /// Null for a rule the app has no type for, so one such rule doesn't break
  /// a whole list.
  static Recurring? tryParse(Object? json) =>
      json is Map<String, dynamic> &&
          _types.contains((json['type'] as String?) ?? 'expense')
      ? Recurring.fromJson(json)
      : null;

  factory Recurring.fromJson(Map<String, dynamic> json) {
    final progress = json['progress'] as Map<String, dynamic>?;
    return Recurring(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
      note: json['note'] as String?,
      iconCode: json['icon_code'] is Map<String, dynamic>
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
      kind: switch (json['type']) {
        'saving' => RecurringKind.saving,
        'debt' => RecurringKind.debt,
        _ => RecurringKind.fromJson(json['kind'] as String?),
      },
      person: json['person'] is Map
          ? EmbeddedPerson.fromJson(
              (json['person'] as Map).cast<String, dynamic>(),
            )
          : null,
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
      nextAmount: (json['next_amount'] as num?)?.toDouble(),
      currentOccurrence: json['current_occurrence'] is Map<String, dynamic>
          ? CurrentOccurrence.fromJson(
              json['current_occurrence'] as Map<String, dynamic>,
              ruleId: json['id'] as String,
            )
          : null,
      nextDate: parseYmd(json['next_date'] as String?),
      daysUntil: (json['days_until'] as num?)?.toInt(),
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
  ];
}

class RecurringWrite extends Equatable {
  const RecurringWrite({
    required this.name,
    required this.kind,
    required this.type,
    required this.rule,
    this.amount,
    this.trialUntil,
    this.description,
    this.note,
    this.iconCode,
    this.accountId,
    this.toAccountId,
    this.categoryId,
    this.tagIds = const [],
    this.goalId,
    this.autoCreate = false,
    this.contactId,
    this.personName,
    this.debtSub,
    this.direction,
  });

  final String name;
  final RecurringKind kind;

  /// หนี้ only: the person (a contact, else a typed name), จดหนี้ | จ่ายหนี้
  /// and the money's direction.
  final String? contactId;
  final String? personName;
  final DebtEntrySub? debtSub;
  final DebtEntryDirection? direction;

  /// Saving only (null = ยังไม่จัดสรร).
  final String? goalId;
  final String? description;
  final String? note;
  final IconCode? iconCode;
  final TransactionType type;

  final double? amount;

  final DateTime? trialUntil;
  final String? accountId;
  final String? toAccountId;
  final String? categoryId;
  final List<String> tagIds;
  final RecurrenceRule rule;
  final bool autoCreate;

  Map<String, dynamic> toJson({bool forUpdate = false}) {
    final saving = kind == RecurringKind.saving;
    if (kind == RecurringKind.debt) {
      // No category / tags / goal / transfer on a debt rule (400 otherwise).
      return <String, dynamic>{
        'name': name,
        'kind': kind.toJson(),
        'type': 'debt',
        'description': description,
        'note': note,
        'icon_code': iconCode?.toJson(),
        'amount': amount ?? 0,
        'account_id': accountId,
        'contact_id': contactId,
        'person_name': contactId == null ? personName : null,
        'debt_kind': recurringDebtSubToJson(debtSub ?? DebtEntrySub.record),
        'direction': (direction ?? DebtEntryDirection.paid).wire,
        'auto_create': autoCreate,
        ...recurrenceToJson(rule),
      };
    }
    return <String, dynamic>{
      'name': name,
      'kind': kind.toJson(),
      'description': description,
      'note': note,
      'icon_code': iconCode?.toJson(),
      'type': saving ? 'saving' : type.toJson(),
      'amount': amount ?? 0,
      'account_id': accountId,
      'to_account_id': type == TransactionType.transfer ? toAccountId : null,
      'category_id': saving || type == TransactionType.transfer
          ? null
          : categoryId,
      'tag_ids': saving ? const <String>[] : tagIds,
      'goal_id': saving ? goalId : null,
      'auto_create': autoCreate,
      if (kind == RecurringKind.subscription && trialUntil != null)
        'trial_until': ymd(trialUntil!)
      else if (forUpdate)
        'trial_until': '',
      ...recurrenceToJson(rule),
    };
  }

  @override
  List<Object?> get props => [
    name,
    kind,
    description,
    note,
    iconCode,
    type,
    amount,
    trialUntil,
    accountId,
    toAccountId,
    categoryId,
    tagIds,
    goalId,
    rule,
    autoCreate,
    contactId,
    personName,
    debtSub,
    direction,
  ];
}
