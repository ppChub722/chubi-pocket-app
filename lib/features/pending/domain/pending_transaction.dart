import 'package:equatable/equatable.dart';

import '../../transactions/domain/transaction_type.dart';

/// Where a draft came from. Only [manual] exists today; notifications, OCR
/// and chat add theirs later (unknown values fall back to [other]).
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
}

/// What submitting does.
enum PendingKind {
  create('create'),
  settleDebt('settle_debt'),
  updateTx('update_tx');

  const PendingKind(this.wire);
  final String wire;

  static PendingKind parse(String? s) =>
      PendingKind.values.firstWhere((v) => v.wire == s, orElse: () => create);
}

/// A draft transaction — the POST /transactions body, every field optional.
class PendingDraft extends Equatable {
  const PendingDraft({
    this.type,
    this.amount,
    this.accountId,
    this.categoryId,
    this.date,
    this.note,
    this.transferToAccountId,
    this.tagIds = const [],
    this.splits = const [],
  });

  final TransactionType? type;
  final double? amount;
  final String? accountId;
  final String? categoryId;

  /// YYYY-MM-DD.
  final String? date;
  final String? note;
  final String? transferToAccountId;
  final List<String> tagIds;

  /// `{person_name, contact_id?, owed_amount}` rows, as POST /transactions.
  final List<Map<String, dynamic>> splits;

  factory PendingDraft.fromJson(Map<String, dynamic> json) {
    final t = json['type'] as String?;
    return PendingDraft(
      type: t == null ? null : TransactionType.fromJson(t),
      amount: (json['amount'] as num?)?.toDouble(),
      accountId: json['account_id'] as String?,
      categoryId: json['category_id'] as String?,
      date: json['date'] as String?,
      note: json['note'] as String?,
      transferToAccountId: json['transfer_to_account_id'] as String?,
      tagIds: ((json['tag_ids'] as List?) ?? const []).cast<String>(),
      splits: ((json['splits'] as List?) ?? const [])
          .cast<Map<String, dynamic>>(),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'type': ?type?.toJson(),
    'amount': ?amount,
    'account_id': ?accountId,
    'category_id': ?categoryId,
    'date': ?date,
    'note': ?note,
    'transfer_to_account_id': ?transferToAccountId,
    if (tagIds.isNotEmpty) 'tag_ids': tagIds,
    if (splits.isNotEmpty) 'splits': splits,
  };

  @override
  List<Object?> get props => [
    type,
    amount,
    accountId,
    categoryId,
    date,
    note,
    transferToAccountId,
    tagIds,
    splits,
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

class PendingTransaction extends Equatable {
  const PendingTransaction({
    required this.id,
    required this.source,
    required this.kind,
    required this.draft,
    required this.createdAt,
    this.lastError,
    this.sourceRef,
  });

  final String id;
  final PendingSource source;
  final PendingKind kind;
  final PendingDraft draft;
  final DateTime createdAt;

  /// Why the last submit failed; cleared when the draft is edited.
  final PendingError? lastError;

  /// What the draft is based on (display only).
  final Map<String, dynamic>? sourceRef;

  factory PendingTransaction.fromJson(Map<String, dynamic> json) {
    final err = json['last_error'];
    final ref = json['source_ref'];
    return PendingTransaction(
      id: json['id'] as String,
      source: PendingSource.parse(json['source'] as String?),
      kind: PendingKind.parse(json['kind'] as String?),
      draft: PendingDraft.fromJson(
        (json['draft'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      lastError: err is Map
          ? PendingError.fromJson(err.cast<String, dynamic>())
          : null,
      sourceRef: ref is Map ? ref.cast<String, dynamic>() : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    source,
    kind,
    draft,
    createdAt,
    lastError,
    sourceRef,
  ];
}

/// One submit call's outcome: ids that went through, and why the rest didn't.
class PendingSubmitResult {
  const PendingSubmitResult({required this.submitted, required this.failed});
  final List<String> submitted;
  final Map<String, PendingError> failed;

  factory PendingSubmitResult.fromJson(Map<String, dynamic> json) =>
      PendingSubmitResult(
        submitted: [
          for (final s
              in ((json['submitted'] as List?) ?? const [])
                  .cast<Map<String, dynamic>>())
            s['id'] as String,
        ],
        failed: {
          for (final f
              in ((json['failed'] as List?) ?? const [])
                  .cast<Map<String, dynamic>>())
            f['id'] as String: PendingError.fromJson(
              (f['error'] as Map).cast<String, dynamic>(),
            ),
        },
      );
}
