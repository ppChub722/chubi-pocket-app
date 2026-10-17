import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import '../../pending/domain/pending_transaction.dart';
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

enum RecurringKind {
  subscription,
  installment,
  income,
  reminder;

  static RecurringKind fromJson(String? v) => RecurringKind.values.firstWhere(
    (k) => k.name == v,
    orElse: () => RecurringKind.subscription,
  );

  String toJson() => name;

  TransactionType get defaultType =>
      this == income ? TransactionType.income : TransactionType.expense;
}

enum RecurringFilter {
  current,
  archived,
  all;

  String toJson() => name;
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
  });

  factory CurrentOccurrence.fromJson(Map<String, dynamic> json) =>
      CurrentOccurrence(
        itemId: json['item_id'] as String,
        date: parseYmd(json['date'] as String?) ?? DateTime.now(),
        daysUntil: (json['days_until'] as num?)?.toInt() ?? 0,
        amount: (json['amount'] as num?)?.toDouble(),
        status: OccurrenceState.parse(json['status'] as String?),
      );

  final String itemId;
  final DateTime date;
  final int daysUntil;

  final double? amount;
  final OccurrenceState status;

  @override
  List<Object?> get props => [itemId, date, daysUntil, amount, status];
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
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String? description;
  final String? note;
  final IconCode? iconCode;
  final RecurringKind kind;
  final TransactionType type;

  final double? amount;
  final AccountRef? account;

  final AccountRef? toAccount;
  final EmbeddedCategory? category;
  final List<TagRef> tags;
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
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get hasAmount => amount != null && amount! > 0;

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
      kind: RecurringKind.fromJson(json['kind'] as String?),
      type: TransactionType.fromJson((json['type'] as String?) ?? 'expense'),
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
  });

  final String name;
  final RecurringKind kind;
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

  Map<String, dynamic> toJson({bool forUpdate = false}) => <String, dynamic>{
    'name': name,
    'kind': kind.toJson(),
    'description': description,
    'note': note,
    'icon_code': iconCode?.toJson(),
    'type': type.toJson(),
    'amount': amount ?? 0,
    'account_id': accountId,
    'to_account_id': type == TransactionType.transfer ? toAccountId : null,
    'category_id': type == TransactionType.transfer ? null : categoryId,
    'tag_ids': tagIds,
    if (kind == RecurringKind.subscription && trialUntil != null)
      'trial_until': ymd(trialUntil!)
    else if (forUpdate)
      'trial_until': '',
    ...recurrenceToJson(rule),
  };

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
    rule,
  ];
}
