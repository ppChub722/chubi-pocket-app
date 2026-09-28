import 'package:equatable/equatable.dart';

import '../../../shared/icon_maker/icon_code.dart';
import 'transaction_type.dart';

/// Denormalized author of a shared-wallet row — API §14 pinned
/// `created_by` shape: `{ user_id, display_name, icon_code }`. Present
/// on rows returned for shared wallets so other members can render
/// "who logged this" without a users lookup.
class TransactionAuthor extends Equatable {
  const TransactionAuthor({
    required this.userId,
    required this.displayName,
    this.iconCode,
  });

  final String userId;
  final String displayName;
  final IconCode? iconCode;

  factory TransactionAuthor.fromJson(Map<String, dynamic> json) {
    return TransactionAuthor(
      userId: json['user_id'] as String,
      displayName: json['display_name'] as String? ?? '',
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [userId, displayName, iconCode];
}

/// Read-only rendering of another member's category — API §14 pinned
/// `category_render` shape: `{ name, icon_code }`. Categories always
/// belong to the row's author (spec §14/2.1); other members see this
/// denormalized snapshot instead of resolving `category_id` against
/// their own set.
class CategoryRender extends Equatable {
  const CategoryRender({required this.name, this.iconCode});

  final String name;
  final IconCode? iconCode;

  factory CategoryRender.fromJson(Map<String, dynamic> json) {
    return CategoryRender(
      name: json['name'] as String? ?? '',
      iconCode: json['icon_code'] != null
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  List<Object?> get props => [name, iconCode];
}

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

/// One transaction row — mirror of `TransactionDetail` from
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
    this.projectId,
    this.transferGroupId,
    this.hasSplits = false,
    this.isRecurring = false,
    this.isResolve = false,
    this.accountBalanceAfter,
    this.createdBy,
    this.categoryRender,
    this.isLocked = false,
    this.canEditCategory = true,
  });

  final String id;
  final String? accountId;
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

  /// Auto-managed project link (spec §04): set only on rows that mirror
  /// a project via claim / split-resolve / quick create. `null` on bare
  /// personal rows; the quick-create picker's eligibility filter keys on
  /// this (spec §10/4.24: eligible = `project_id IS NULL`).
  final String? projectId;

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

  /// Shared-wallet row surface (API §14 pinned contract). All absent on
  /// personal-wallet rows:
  /// - [createdBy] — the row's author (any member may have logged it).
  /// - [categoryRender] — read-only rendering of the author's category.
  /// - [isLocked] — true for the caller's own rows after they left the
  ///   wallet (spec §14/2.3): read-only for them, full form disabled.
  /// - [canEditCategory] — false when the row belongs to another member
  ///   (spec §14/2.2: only the author edits `category_id`). Defaults to
  ///   true when the field is absent (personal rows).
  final TransactionAuthor? createdBy;
  final CategoryRender? categoryRender;
  final bool isLocked;
  final bool canEditCategory;

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
      accountId: json['account_id'] as String?,
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
      projectId: json['project_id'] as String?,
      transferGroupId: json['transfer_group_id'] as String?,
      hasSplits: (json['has_splits'] as bool?) ?? false,
      isRecurring: (json['is_recurring'] as bool?) ?? false,
      isResolve: (json['is_resolve'] as bool?) ?? false,
      accountBalanceAfter:
          (json['account_balance_after'] as num?)?.toDouble(),
      createdBy: json['created_by'] is Map<String, dynamic>
          ? TransactionAuthor.fromJson(
              json['created_by'] as Map<String, dynamic>)
          : null,
      categoryRender: json['category_render'] is Map<String, dynamic>
          ? CategoryRender.fromJson(
              json['category_render'] as Map<String, dynamic>)
          : null,
      isLocked: (json['is_locked'] as bool?) ?? false,
      canEditCategory: (json['can_edit_category'] as bool?) ?? true,
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
    String? projectId,
    String? transferGroupId,
    bool? hasSplits,
    bool? isRecurring,
    bool? isResolve,
    double? accountBalanceAfter,
    TransactionAuthor? createdBy,
    CategoryRender? categoryRender,
    bool? isLocked,
    bool? canEditCategory,
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
      projectId: projectId ?? this.projectId,
      transferGroupId: transferGroupId ?? this.transferGroupId,
      hasSplits: hasSplits ?? this.hasSplits,
      isRecurring: isRecurring ?? this.isRecurring,
      isResolve: isResolve ?? this.isResolve,
      accountBalanceAfter: accountBalanceAfter ?? this.accountBalanceAfter,
      createdBy: createdBy ?? this.createdBy,
      categoryRender: categoryRender ?? this.categoryRender,
      isLocked: isLocked ?? this.isLocked,
      canEditCategory: canEditCategory ?? this.canEditCategory,
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
        projectId,
        transferGroupId,
        hasSplits,
        isRecurring,
        isResolve,
        accountBalanceAfter,
        createdBy,
        categoryRender,
        isLocked,
        canEditCategory,
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
