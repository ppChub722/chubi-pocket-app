import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import '../../pending/domain/pending_transaction.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction_type.dart';
import 'recurrence_rule.dart';

/// A recurring's lifecycle (the BE decides which moves are allowed:
/// [RecurringActions]).
enum RecurringStatus {
  active,
  paused,
  archived;

  static RecurringStatus fromJson(String? v) => RecurringStatus.values
      .firstWhere((s) => s.name == v, orElse: () => RecurringStatus.active);
}

/// The list filter: current = active + paused (the default).
enum RecurringFilter {
  current,
  archived,
  all;

  String toJson() => name;
}

/// What the BE allows on this recurring right now.
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

/// Items per state — the recurring page's tab badges and filters.
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

  /// Everything whose date came (the produced tab).
  int get produced => notCreated + pending + done + archived;

  @override
  List<Object?> get props => [upcoming, notCreated, pending, done, archived];
}

/// รายการประจำ — the setup that produces the upcoming items.
class Recurring extends Equatable {
  const Recurring({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.rule,
    required this.status,
    this.description,
    this.note,
    this.iconCode,
    this.account,
    this.toAccount,
    this.category,
    this.isSaving = false,
    this.goal,
    this.tags = const [],
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
  final TransactionType type;
  final double amount;
  final AccountRef? account;

  /// Transfers only.
  final AccountRef? toAccount;
  final EmbeddedCategory? category;

  /// ออม (type `saving`): each item becomes a 🐷 pending saving draft from
  /// [account] into [goal] (null = ยังไม่จัดสรร). [type] is a placeholder.
  final bool isSaving;
  final SavingGoalRef? goal;
  final List<TagRef> tags;
  final RecurrenceRule rule;
  final RecurringStatus status;
  final DateTime? nextDate;
  final int? daysUntil;

  /// n / N — [progressTotal] null = no end.
  final int progressDone;
  final int? progressTotal;

  /// ≤ 2 upcoming left: warning + "ต่ออีก".
  final bool endingSoon;
  final RecurringCounts counts;

  /// False → the upcoming tab shows the one-line summary, not the list.
  final bool editedAny;
  final RecurringActions actions;
  final DateTime? createdAt;
  final DateTime? updatedAt;

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
      type: (json['type'] as String?) == 'saving'
          ? TransactionType.expense
          : TransactionType.fromJson((json['type'] as String?) ?? 'expense'),
      isSaving: json['type'] == 'saving',
      goal: json['goal'] is Map<String, dynamic>
          ? SavingGoalRef.fromJson(json['goal'] as Map<String, dynamic>)
          : null,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
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
    type,
    amount,
    account,
    toAccount,
    category,
    isSaving,
    goal,
    tags,
    rule,
    status,
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

/// The create / update body of a recurring (what the settings page edits).
class RecurringWrite extends Equatable {
  const RecurringWrite({
    required this.name,
    required this.type,
    required this.amount,
    required this.rule,
    this.description,
    this.note,
    this.iconCode,
    this.accountId,
    this.toAccountId,
    this.categoryId,
    this.tagIds = const [],
    this.isSaving = false,
    this.goalId,
  });

  final String name;
  final String? description;
  final String? note;
  final IconCode? iconCode;
  final TransactionType type;
  final double amount;
  final String? accountId;
  final String? toAccountId;
  final String? categoryId;
  final List<String> tagIds;
  final RecurrenceRule rule;

  /// ออม: the wire type is `saving`, [goalId] null = ยังไม่จัดสรร.
  final bool isSaving;
  final String? goalId;

  /// The create / PUT body (every key sent: null clears a nullable one).
  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'description': description,
    'note': note,
    'icon_code': iconCode?.toJson(),
    'type': isSaving ? 'saving' : type.toJson(),
    'amount': amount,
    'account_id': accountId,
    'to_account_id': isSaving ? null : toAccountId,
    'category_id': isSaving ? null : categoryId,
    'tag_ids': isSaving ? const <String>[] : tagIds,
    if (isSaving) 'goal_id': goalId,
    ...recurrenceToJson(rule),
  };

  @override
  List<Object?> get props => [
    name,
    description,
    note,
    iconCode,
    type,
    amount,
    accountId,
    toAccountId,
    categoryId,
    tagIds,
    rule,
    isSaving,
    goalId,
  ];
}
