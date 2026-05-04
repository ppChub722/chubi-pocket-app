import 'package:equatable/equatable.dart';

import 'transaction_type.dart';

/// Lightweight ref returned by the BE for embedded `account` /
/// `category` pairs (spec §3.2). Avoids a JOIN in the client.
class EmbeddedRef extends Equatable {
  const EmbeddedRef({required this.id, required this.name});
  final String id;
  final String name;

  factory EmbeddedRef.fromJson(Map<String, dynamic> json) {
    return EmbeddedRef(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }

  @override
  List<Object?> get props => [id, name];
}

/// Tag ref enriched with color + icon so the FE can render chips
/// inline without consulting the tags cache. Mirrors the BE
/// `EmbeddedTag` (id / name / color / icon) on every transaction
/// response.
class EmbeddedTag extends Equatable {
  const EmbeddedTag({
    required this.id,
    required this.name,
    this.color,
    this.icon,
  });
  final String id;
  final String name;
  final String? color;
  final String? icon;

  factory EmbeddedTag.fromJson(Map<String, dynamic> json) {
    return EmbeddedTag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String?,
      icon: json['icon'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, name, color, icon];
}

/// One transaction row. Mirror of `TransactionDetail` from
/// [`design/spec/04-transactions.md §3.2`](../../../../../chubi-pocket-docs/design/spec/04-transactions.md)
/// trimmed to fields the FE actually reads.
///
/// Phase 1a constraints (BE deferred):
/// - `splits` not surfaced (BE `ErrSplitsNotSupportedYet` → 1b)
/// - `project_id` not editable (auto-managed; 1b)
/// - `scheduled_transaction_id` not surfaced (1c)
class Transaction extends Equatable {
  const Transaction({
    required this.id,
    required this.accountId,
    required this.type,
    required this.amount,
    required this.date,
    this.categoryId,
    this.account,
    this.category,
    this.tags = const [],
    this.note,
    this.transferGroupId,
    this.hasSplits = false,
    this.isRecurring = false,
    this.isResolve = false,
    this.accountBalanceAfter,
  });

  final String id;
  final String accountId;
  final TransactionType type;

  /// Always positive — direction encoded in [type] (or in the
  /// embedded category for transfers per spec §2.1).
  final double amount;

  /// Calendar date in the user's timezone, `YYYY-MM-DD`.
  final String date;

  /// Optional for [TransactionType.expense] / [TransactionType.income];
  /// auto-assigned system category for [TransactionType.transfer].
  final String? categoryId;

  /// `{id, name}` embedded ref from the BE response. Saves a separate
  /// lookup against the categories cache; mostly populated, but `null`
  /// when the category is uncategorized or has been hard-deleted.
  final EmbeddedRef? account;
  final EmbeddedRef? category;

  /// Tags attached to this transaction. Ordered by name (BE-side), and
  /// always present (empty list, never null) — the BE serializes the
  /// field even when no tags are attached.
  final List<EmbeddedTag> tags;

  final String? note;

  /// Set on both rows of a transfer. Used to identify pair members.
  final String? transferGroupId;

  /// Spec §3.2 derived booleans — read-only signals from the BE.
  final bool hasSplits;
  final bool isRecurring;
  final bool isResolve;

  /// Set on `POST /v1/transactions` response only — spec §3.1. Lets
  /// the FE update the account row's cached balance surgically without
  /// a follow-up GET. `null` on list responses.
  final double? accountBalanceAfter;

  bool get isTransferOut => type == TransactionType.transfer && _isTransferOutCategory;
  bool get isTransferIn => type == TransactionType.transfer && !_isTransferOutCategory;

  /// Heuristic: BE assigns the OUT category to the source-side row.
  /// Without the system_kind on the wire we fall back to the embedded
  /// category name. Acceptable Phase 1a — system categories can be
  /// renamed (spec §4.14) but the seed defaults to "Transfer Out".
  bool get _isTransferOutCategory {
    final name = category?.name.toLowerCase() ?? '';
    return name.contains('transfer out') || name.contains('out');
  }

  /// Signed effect on the row's account balance. Positive = credit.
  double get signedAmount {
    if (type == TransactionType.income) return amount;
    if (type == TransactionType.expense) return -amount;
    // transfer
    return isTransferIn ? amount : -amount;
  }

  factory Transaction.fromJson(Map<String, dynamic> json) {
    final rawTags = json['tags'];
    final tags = rawTags is List
        ? rawTags
            .cast<Map<String, dynamic>>()
            .map(EmbeddedTag.fromJson)
            .toList()
        : <EmbeddedTag>[];
    return Transaction(
      id: json['id'] as String,
      accountId: json['account_id'] as String,
      type: TransactionType.fromJson(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] as String,
      categoryId: json['category_id'] as String?,
      account: json['account'] is Map<String, dynamic>
          ? EmbeddedRef.fromJson(json['account'] as Map<String, dynamic>)
          : null,
      category: json['category'] is Map<String, dynamic>
          ? EmbeddedRef.fromJson(json['category'] as Map<String, dynamic>)
          : null,
      tags: tags,
      note: json['note'] as String?,
      transferGroupId: json['transfer_group_id'] as String?,
      hasSplits: (json['has_splits'] as bool?) ?? false,
      isRecurring: (json['is_recurring'] as bool?) ?? false,
      isResolve: (json['is_resolve'] as bool?) ?? false,
      accountBalanceAfter:
          (json['account_balance_after'] as num?)?.toDouble(),
    );
  }

  Transaction copyWith({
    String? id,
    String? accountId,
    TransactionType? type,
    double? amount,
    String? date,
    String? categoryId,
    EmbeddedRef? account,
    EmbeddedRef? category,
    List<EmbeddedTag>? tags,
    String? note,
    String? transferGroupId,
    bool? hasSplits,
    bool? isRecurring,
    bool? isResolve,
    double? accountBalanceAfter,
  }) {
    return Transaction(
      id: id ?? this.id,
      accountId: accountId ?? this.accountId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      categoryId: categoryId ?? this.categoryId,
      account: account ?? this.account,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      note: note ?? this.note,
      transferGroupId: transferGroupId ?? this.transferGroupId,
      hasSplits: hasSplits ?? this.hasSplits,
      isRecurring: isRecurring ?? this.isRecurring,
      isResolve: isResolve ?? this.isResolve,
      accountBalanceAfter: accountBalanceAfter ?? this.accountBalanceAfter,
    );
  }

  @override
  List<Object?> get props => [
        id,
        accountId,
        type,
        amount,
        date,
        categoryId,
        account,
        category,
        tags,
        note,
        transferGroupId,
        hasSplits,
        isRecurring,
        isResolve,
        accountBalanceAfter,
      ];
}

/// Polymorphic shape of `POST /v1/transactions` and the transfer branch
/// of `PUT /v1/transactions/:id`. Either [single] is set (expense /
/// income) or [transfer] is set (transfer pair) — never both.
class TransactionMutationResult {
  const TransactionMutationResult.single(Transaction tx)
      : single = tx,
        transfer = null;
  const TransactionMutationResult.transfer(TransferResult result)
      : single = null,
        transfer = result;

  final Transaction? single;
  final TransferResult? transfer;

  /// Convenience: every row affected by the mutation. Single = 1 row;
  /// transfer = 2 rows. Used by the cubit's surgical-update path.
  List<Transaction> get rows {
    if (single != null) return [single!];
    return transfer!.rows;
  }

  factory TransactionMutationResult.fromJson(Map<String, dynamic> json) {
    if (json['transfer_group_id'] != null && json['rows'] is List) {
      return TransactionMutationResult.transfer(TransferResult.fromJson(json));
    }
    return TransactionMutationResult.single(Transaction.fromJson(json));
  }
}

/// `{ transfer_group_id, rows: [out_row, in_row] }` shape.
class TransferResult {
  const TransferResult({required this.transferGroupId, required this.rows});

  final String transferGroupId;
  final List<Transaction> rows;

  factory TransferResult.fromJson(Map<String, dynamic> json) {
    final raw = (json['rows'] as List).cast<Map<String, dynamic>>();
    return TransferResult(
      transferGroupId: json['transfer_group_id'] as String,
      rows: raw.map(Transaction.fromJson).toList(),
    );
  }
}
