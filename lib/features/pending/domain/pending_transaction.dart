import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction_type.dart';

enum PendingSource {
  manual('manual'),
  splitPaid('split_paid'),
  projectCopy('project_copy'),
  projectUpdate('project_update'),
  ocr('ocr'),
  chat('chat'),
  other('');

  const PendingSource(this.wire);
  final String wire;

  static PendingSource parse(String? s) => PendingSource.values.firstWhere(
    (v) => v.wire == s && v != other,
    orElse: () => other,
  );

  bool get isManual => this == manual;

  bool get inManualBucket => this == manual || this == chat;
}

enum PendingKind {
  create('create'),
  settleDebt('settle_debt'),
  updateTx('update_tx'),

  /// Saving draft: on submit a saving entry (never a transaction).
  saving('saving');

  const PendingKind(this.wire);
  final String wire;

  static PendingKind parse(String? s) =>
      PendingKind.values.firstWhere((v) => v.wire == s, orElse: () => create);
}

class PendingDraft extends Equatable {
  const PendingDraft({
    this.type,
    this.amount,
    this.accountId,
    this.categoryId,
    this.date,
    this.description,
    this.note,
    this.transferToAccountId,
    this.tagIds = const [],
    this.splits = const [],
    this.projectId,
    this.goalId,
    this.isSaving = false,
  });

  final TransactionType? type;
  final double? amount;
  final String? accountId;
  final String? categoryId;

  final String? date;
  final String? description;
  final String? note;
  final String? transferToAccountId;
  final List<String> tagIds;

  final List<Map<String, dynamic>> splits;

  final String? projectId;

  final String? goalId;

  final bool isSaving;

  factory PendingDraft.fromJson(Map<String, dynamic> json) {
    final t = json['type'] as String?;
    final saving = t == 'saving';
    return PendingDraft(
      isSaving: saving,
      goalId: json['goal_id'] as String?,
      type: t == null || saving ? null : TransactionType.fromJson(t),
      amount: (json['amount'] as num?)?.toDouble(),
      accountId: json['account_id'] as String?,
      categoryId: json['category_id'] as String?,
      date: json['date'] as String?,
      description: json['description'] as String?,
      note: json['note'] as String?,
      transferToAccountId: json['transfer_to_account_id'] as String?,
      tagIds: ((json['tag_ids'] as List?) ?? const []).cast<String>(),
      splits: ((json['splits'] as List?) ?? const [])
          .cast<Map<String, dynamic>>(),
      projectId: json['project_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': ?(isSaving ? 'saving' : type?.toJson()),
    'goal_id': ?goalId,
    'amount': ?amount,
    'account_id': ?accountId,
    'category_id': ?categoryId,
    'date': ?date,
    'description': ?description,
    'note': ?note,
    'transfer_to_account_id': ?transferToAccountId,
    if (tagIds.isNotEmpty) 'tag_ids': tagIds,
    if (splits.isNotEmpty) 'splits': splits,
    'project_id': ?projectId,
  };

  @override
  List<Object?> get props => [
    type,
    amount,
    accountId,
    categoryId,
    date,
    description,
    note,
    transferToAccountId,
    tagIds,
    splits,
    projectId,
    goalId,
    isSaving,
  ];
}

class PendingError extends Equatable {
  const PendingError({required this.code, required this.message});
  final String code;
  final String message;

  factory PendingError.fromJson(Map<String, dynamic> json) => PendingError(
    code: json['code'] as String? ?? '',
    message: json['message'] as String? ?? '',
  );

  @override
  List<Object?> get props => [code, message];
}

class TagRef extends Equatable {
  const TagRef({required this.id, required this.name, this.iconCode});

  final String id;
  final String name;
  final IconCode? iconCode;

  factory TagRef.fromJson(Map<String, dynamic> json) => TagRef(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    iconCode: json['icon_code'] is Map<String, dynamic>
        ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
        : null,
  );

  @override
  List<Object?> get props => [id, name, iconCode];
}

class SavingGoalRef extends Equatable {
  const SavingGoalRef({required this.id, required this.name, this.iconCode});

  final String id;
  final String name;
  final IconCode? iconCode;

  factory SavingGoalRef.fromJson(Map<String, dynamic> json) => SavingGoalRef(
    id: json['id'] as String,
    name: (json['name'] as String?) ?? '',
    iconCode: json['icon_code'] is Map<String, dynamic>
        ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
        : null,
  );

  @override
  List<Object?> get props => [id, name, iconCode];
}

class ResolvedSplit extends Equatable {
  const ResolvedSplit({required this.person, required this.owedAmount});

  final EmbeddedPerson person;
  final double owedAmount;

  factory ResolvedSplit.fromJson(Map<String, dynamic> json) => ResolvedSplit(
    person: EmbeddedPerson.fromJson(
      (json['person'] as Map).cast<String, dynamic>(),
    ),
    owedAmount: (json['owed_amount'] as num?)?.toDouble() ?? 0,
  );

  @override
  List<Object?> get props => [person, owedAmount];
}

/// `DraftResolved`: the draft's ids resolved so a row renders without other
/// calls.
class DraftResolved extends Equatable {
  const DraftResolved({
    this.account,
    this.transferToAccount,
    this.category,
    this.tags = const [],
    this.project,
    this.splits = const [],
    this.goal,
    this.missing = const [],
  });

  final AccountRef? account;
  final AccountRef? transferToAccount;
  final EmbeddedCategory? category;
  final List<TagRef> tags;
  final EventRef? project;
  final List<ResolvedSplit> splits;

  final SavingGoalRef? goal;

  final List<String> missing;

  static T? _obj<T>(Object? v, T Function(Map<String, dynamic>) f) =>
      v is Map ? f(v.cast<String, dynamic>()) : null;

  static List<T> _list<T>(Object? v, T Function(Map<String, dynamic>) f) => [
    if (v is List)
      for (final e in v.cast<Map<String, dynamic>>()) f(e),
  ];

  factory DraftResolved.fromJson(Map<String, dynamic> json) => DraftResolved(
    account: _obj(json['account'], AccountRef.fromJson),
    transferToAccount: _obj(json['transfer_to_account'], AccountRef.fromJson),
    category: _obj(json['category'], EmbeddedCategory.fromJson),
    tags: _list(json['tags'], TagRef.fromJson),
    project: _obj(json['project'], EventRef.fromJson),
    splits: _list(json['splits'], ResolvedSplit.fromJson),
    goal: _obj(json['goal'], SavingGoalRef.fromJson),
    missing: ((json['missing'] as List?) ?? const []).cast<String>(),
  );

  @override
  List<Object?> get props => [
    account,
    transferToAccount,
    category,
    tags,
    project,
    splits,
    goal,
    missing,
  ];
}

class PendingTransaction extends Equatable {
  const PendingTransaction({
    required this.id,
    required this.source,
    required this.kind,
    required this.draft,
    required this.createdAt,
    this.resolved = const DraftResolved(),
    this.targetDebtId,
    this.targetTransactionId,
    this.lastError,
    this.sourceRef,
    this.needsInput,
    this.canConfirm = true,
  });

  final String id;
  final PendingSource source;
  final PendingKind kind;
  final PendingDraft draft;
  final DateTime createdAt;

  final DraftResolved resolved;
  final String? targetDebtId;
  final String? targetTransactionId;

  final PendingError? lastError;

  final Map<String, dynamic>? sourceRef;

  final List<String>? needsInput;

  /// False while a hard key is missing: confirming it directly would fail, so
  /// the list opens the draft sheet instead.
  final bool canConfirm;

  bool needs(String key) => needsInput?.contains(key) ?? false;

  bool get isSaving => kind == PendingKind.saving || draft.isSaving;

  factory PendingTransaction.fromJson(Map<String, dynamic> json) {
    final err = json['last_error'];
    final ref = json['source_ref'];
    final resolved = json['resolved'];
    return PendingTransaction(
      id: json['id'] as String,
      source: PendingSource.parse(json['source'] as String?),
      kind: PendingKind.parse(json['kind'] as String?),
      draft: PendingDraft.fromJson(
        (json['draft'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      resolved: resolved is Map
          ? DraftResolved.fromJson(resolved.cast<String, dynamic>())
          : const DraftResolved(),
      targetDebtId: json['target_debt_id'] as String?,
      targetTransactionId: json['target_transaction_id'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      lastError: err is Map
          ? PendingError.fromJson(err.cast<String, dynamic>())
          : null,
      sourceRef: ref is Map ? ref.cast<String, dynamic>() : null,
      needsInput: json['needs_input'] is List
          ? (json['needs_input'] as List).whereType<String>().toList()
          : null,
      canConfirm: json['can_confirm'] as bool? ?? true,
    );
  }

  @override
  List<Object?> get props => [
    id,
    source,
    kind,
    draft,
    createdAt,
    resolved,
    targetDebtId,
    targetTransactionId,
    lastError,
    sourceRef,
    needsInput,
    canConfirm,
  ];
}

class PendingSummary extends Equatable {
  const PendingSummary({
    required this.count,
    this.expenseTotal = 0,
    this.incomeTotal = 0,
    this.needsInputCount = 0,
    this.readyCount = 0,
    this.recurring = 0,
    this.manual = 0,
    this.otherPeople = 0,
    this.slip = 0,
    this.other = 0,
  });

  final int count;
  final double expenseTotal;
  final double incomeTotal;
  final int needsInputCount;
  final int readyCount;

  final int recurring;
  final int manual;
  final int otherPeople;
  final int slip;
  final int other;

  int get notManual => count - manual;

  static PendingSummary? maybe(Object? json) => json is Map
      ? PendingSummary.fromJson(json.cast<String, dynamic>())
      : null;

  factory PendingSummary.fromJson(Map<String, dynamic> json) {
    int i(Object? v) => (v as num?)?.toInt() ?? 0;
    double d(Object? v) => (v as num?)?.toDouble() ?? 0;
    final by = json['by_source'] is Map
        ? (json['by_source'] as Map).cast<String, dynamic>()
        : const <String, dynamic>{};
    return PendingSummary(
      count: i(json['count']),
      expenseTotal: d(json['expense_total']),
      incomeTotal: d(json['income_total']),
      needsInputCount: i(json['needs_input_count']),
      readyCount: i(json['ready_count']),
      recurring: i(by['recurring']),
      manual: i(by['manual']),
      otherPeople: i(by['other_people']),
      slip: i(by['slip']),
      other: i(by['other']),
    );
  }

  @override
  List<Object?> get props => [
    count,
    expenseTotal,
    incomeTotal,
    needsInputCount,
    readyCount,
    recurring,
    manual,
    otherPeople,
    slip,
    other,
  ];
}

class PendingList {
  const PendingList({required this.items, this.summary});
  final List<PendingTransaction> items;
  final PendingSummary? summary;
}

class PendingUpdated {
  const PendingUpdated({required this.draft, this.summary});
  final PendingTransaction draft;
  final PendingSummary? summary;
}

class PendingSubmitResult {
  const PendingSubmitResult({
    required this.submitted,
    required this.failed,
    this.failedDrafts = const {},
    this.accountBalances = const {},
    this.pendingDrafts,
    this.summary,
  });
  final List<String> submitted;
  final Map<String, PendingError> failed;

  final Map<String, PendingTransaction> failedDrafts;

  final Map<String, double> accountBalances;
  final int? pendingDrafts;

  final PendingSummary? summary;

  factory PendingSubmitResult.fromJson(Map<String, dynamic> json) {
    final failed = ((json['failed'] as List?) ?? const [])
        .cast<Map<String, dynamic>>();
    final badges = json['badges'];
    return PendingSubmitResult(
      submitted: [
        for (final s
            in ((json['submitted'] as List?) ?? const [])
                .cast<Map<String, dynamic>>())
          s['id'] as String,
      ],
      failed: {
        for (final f in failed)
          f['id'] as String: PendingError.fromJson(
            (f['error'] as Map).cast<String, dynamic>(),
          ),
      },
      failedDrafts: {
        for (final f in failed)
          if (f['pending'] is Map)
            f['id'] as String: PendingTransaction.fromJson(
              (f['pending'] as Map).cast<String, dynamic>(),
            ),
      },
      accountBalances: WalletBalance.mapOf(json['account_balances']),
      pendingDrafts: badges is Map
          ? (badges['pending_drafts'] as num?)?.toInt()
          : null,
      summary: PendingSummary.maybe(json['summary']),
    );
  }
}

class DiscardResult {
  const DiscardResult({
    required this.discarded,
    required this.skipped,
    required this.remainingCount,
    this.summary,
  });
  final List<String> discarded;
  final List<String> skipped;
  final int remainingCount;

  final PendingSummary? summary;

  factory DiscardResult.fromJson(Map<String, dynamic> json) => DiscardResult(
    discarded: ((json['discarded'] as List?) ?? const []).cast<String>(),
    skipped: ((json['skipped'] as List?) ?? const []).cast<String>(),
    remainingCount: (json['remaining_count'] as num?)?.toInt() ?? 0,
    summary: PendingSummary.maybe(json['summary']),
  );
}
