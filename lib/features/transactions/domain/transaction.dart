import 'package:equatable/equatable.dart';

import '../../tags/domain/tag.dart';
import 'refs.dart';
import 'transaction_type.dart';
import '../../../ui/ui.dart';

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

/// Tag ref enriched with color + icon so the FE can render chips
/// inline without consulting the tags cache. Mirrors the BE
/// `EmbeddedTag` (id / name / icon_code) on every transaction
/// response.
class EmbeddedTag extends Equatable {
  const EmbeddedTag({required this.id, required this.name, this.iconCode});
  final String id;
  final String name;
  final IconCode? iconCode;

  factory EmbeddedTag.fromJson(Map<String, dynamic> json) {
    return EmbeddedTag(
      id: json['id'] as String,
      name: json['name'] as String,
      iconCode: json['icon_code'] is Map<String, dynamic>
          ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
          : null,
    );
  }

  /// As a [Tag], for the shared tag widgets (`tagAppChip`, `tagColor`).
  Tag get asTag => Tag(id: id, name: name, iconCode: iconCode);

  @override
  List<Object?> get props => [id, name, iconCode];
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
    this.description,
    this.note,
    this.projectId,
    this.transferGroupId,
    this.createdBy,
    this.isLocked = false,
    this.canEditCategory = true,
    this.createdAt,
    this.updatedAt,
    this.splitCount = 0,
    this.splits = const [],
    this.project,
    this.sourcePersonalDebtId,
    this.isRepayment = false,
    this.transferPeer,
    this.currency,
    this.myShare,
    this.canSplit,
    this.canEditSplits,
    this.canJoinEvent,
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

  /// Full embedded refs (API v2): the wallet / category with their own icon,
  /// type and system kind, so no lookup against the accounts / categories
  /// caches. `account` is null on a no-wallet row, `category` on an
  /// uncategorised one. On a shared-wallet row `category` is the author's.
  final AccountRef? account;
  final EmbeddedCategory? category;

  /// Tags attached to this transaction. Ordered by name (BE-side), and
  /// always present (empty list, never null) — the BE serializes the
  /// field even when no tags are attached.
  final List<EmbeddedTag> tags;

  final String? description;
  final String? note;

  /// Auto-managed project link (spec §04): set only on rows that mirror
  /// a project via claim / split-resolve / quick create. `null` on bare
  /// personal rows; the quick-create picker's eligibility filter keys on
  /// this (spec §10/4.24: eligible = `project_id IS NULL`).
  final String? projectId;

  /// Set on both rows of a transfer. Used to identify pair members.
  final String? transferGroupId;

  /// Debt repayment row (replaces `is_resolve`): can't join an event, can't be
  /// moved to another category.
  final bool isRepayment;

  /// The other side of a transfer row (null on every other row); its
  /// `isOut` is for THIS row.
  final TransferPeer? transferPeer;

  /// Row currency (3 letters).
  final String? currency;

  bool get hasSplits => splitCount > 0;

  /// Shared-wallet row surface (API §14 pinned contract). All absent on
  /// personal-wallet rows:
  /// - [createdBy] — the row's author (any member may have logged it).
  /// - [isLocked] — true for the caller's own rows after they left the
  ///   wallet (spec §14/2.3): read-only for them, full form disabled.
  /// - [canEditCategory] — false when the row belongs to another member
  ///   (spec §14/2.2: only the author edits `category_id`). Defaults to
  ///   true when the field is absent (personal rows).
  final TransactionAuthor? createdBy;
  final bool isLocked;
  final bool canEditCategory;

  /// When the row was recorded / last changed (server time, local here).
  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// Debt rows this transaction made in its owner's book ("หารกับ N คน").
  final int splitCount;

  /// Those debt rows — GET /:id only, and only the caller's own (empty for
  /// another member's row on a shared wallet, while [splitCount] shows).
  final List<TxSplit> splits;

  /// `{id, name}` of [projectId]'s project — the detail page's event card.
  final EventRef? project;

  /// Set on a debt repayment (the debt it pays back).
  final String? sourcePersonalDebtId;

  /// My part of an expense / income — what reports count (the total minus
  /// what others owe / get, or my event share). Null on transfers, and
  /// from a BE that doesn't send it yet (then the FE works it out).
  final double? myShare;

  /// BE capability flags — null while the BE doesn't send them (then the
  /// FE's own rules decide; see tx_rules.dart):
  /// - [canSplit]: the row can carry personal splits at all;
  /// - [canEditSplits]: [canSplit] and I'm its author → the split editor;
  /// - [canJoinEvent]: may go into / move to an event.
  final bool? canSplit;
  final bool? canEditSplits;
  final bool? canJoinEvent;

  bool get isTransferOut =>
      type == TransactionType.transfer && _isTransferOutRow;
  bool get isTransferIn =>
      type == TransactionType.transfer && !_isTransferOutRow;

  /// The peer's direction when the BE sent it (API v2), else the row's
  /// system category kind.
  bool get _isTransferOutRow =>
      transferPeer?.isOut ?? (category?.isTransferOut ?? false);

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
    final account = json['account'] is Map<String, dynamic>
        ? AccountRef.fromJson(json['account'] as Map<String, dynamic>)
        : null;
    final category = json['category'] is Map<String, dynamic>
        ? EmbeddedCategory.fromJson(json['category'] as Map<String, dynamic>)
        : null;
    final project = json['project'] is Map<String, dynamic>
        ? EventRef.fromJson(json['project'] as Map<String, dynamic>)
        : null;
    return Transaction(
      id: json['id'] as String,
      accountId: account?.id,
      type: TransactionType.fromJson(json['type'] as String),
      amount: (json['amount'] as num).toDouble(),
      date: json['date'] as String,
      categoryId: category?.id,
      account: account,
      category: category,
      tags: tags,
      description: json['description'] as String?,
      note: json['note'] as String?,
      projectId: project?.id,
      transferGroupId: json['transfer_group_id'] as String?,
      createdBy: json['created_by'] is Map<String, dynamic>
          ? TransactionAuthor.fromJson(
              json['created_by'] as Map<String, dynamic>,
            )
          : null,
      isLocked: (json['is_locked'] as bool?) ?? false,
      canEditCategory: (json['can_edit_category'] as bool?) ?? true,
      createdAt: DateTime.tryParse(
        (json['created_at'] as String?) ?? '',
      )?.toLocal(),
      updatedAt: DateTime.tryParse(
        (json['updated_at'] as String?) ?? '',
      )?.toLocal(),
      splitCount: (json['split_count'] as num?)?.toInt() ?? 0,
      splits: json['splits'] is List
          ? (json['splits'] as List)
                .cast<Map<String, dynamic>>()
                .map(TxSplit.fromJson)
                .toList()
          : const [],
      project: project,
      sourcePersonalDebtId: json['source_personal_debt_id'] as String?,
      isRepayment: (json['is_repayment'] as bool?) ?? false,
      transferPeer: json['transfer_peer'] is Map<String, dynamic>
          ? TransferPeer.fromJson(json['transfer_peer'] as Map<String, dynamic>)
          : null,
      currency: json['currency'] as String?,
      myShare: (json['my_share'] as num?)?.toDouble(),
      canSplit: json['can_split'] as bool?,
      canEditSplits: json['can_edit_splits'] as bool?,
      canJoinEvent: json['can_join_event'] as bool?,
    );
  }

  Transaction copyWith({
    String? id,
    String? accountId,
    TransactionType? type,
    double? amount,
    String? date,
    String? categoryId,
    AccountRef? account,
    EmbeddedCategory? category,
    List<EmbeddedTag>? tags,
    String? description,
    String? note,
    String? projectId,
    String? transferGroupId,
    TransactionAuthor? createdBy,
    bool? isLocked,
    bool? canEditCategory,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? splitCount,
    List<TxSplit>? splits,
    EventRef? project,
    String? sourcePersonalDebtId,
    bool? isRepayment,
    TransferPeer? transferPeer,
    String? currency,
    double? myShare,
    bool? canSplit,
    bool? canEditSplits,
    bool? canJoinEvent,
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
      description: description ?? this.description,
      note: note ?? this.note,
      projectId: projectId ?? this.projectId,
      transferGroupId: transferGroupId ?? this.transferGroupId,
      createdBy: createdBy ?? this.createdBy,
      isLocked: isLocked ?? this.isLocked,
      canEditCategory: canEditCategory ?? this.canEditCategory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      splitCount: splitCount ?? this.splitCount,
      splits: splits ?? this.splits,
      project: project ?? this.project,
      sourcePersonalDebtId: sourcePersonalDebtId ?? this.sourcePersonalDebtId,
      isRepayment: isRepayment ?? this.isRepayment,
      transferPeer: transferPeer ?? this.transferPeer,
      currency: currency ?? this.currency,
      myShare: myShare ?? this.myShare,
      canSplit: canSplit ?? this.canSplit,
      canEditSplits: canEditSplits ?? this.canEditSplits,
      canJoinEvent: canJoinEvent ?? this.canJoinEvent,
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
    description,
    note,
    projectId,
    transferGroupId,
    createdBy,
    isLocked,
    canEditCategory,
    createdAt,
    updatedAt,
    splitCount,
    splits,
    project,
    sourcePersonalDebtId,
    isRepayment,
    transferPeer,
    currency,
    myShare,
    canSplit,
    canEditSplits,
    canJoinEvent,
  ];
}

/// `POST` / `PUT /transactions` result (API v2): the written rows (a transfer
/// = both, OUT first) and the wallets' balances after the write, for
/// `AccountsCubit.patchBalances`.
class TransactionWriteResult {
  const TransactionWriteResult({
    required this.rows,
    this.accountBalances = const {},
  });

  /// One row (expense / income); balances unknown.
  TransactionWriteResult.single(Transaction tx)
    : rows = [tx],
      accountBalances = const {};

  final List<Transaction> rows;

  /// {account id: balance after the write}.
  final Map<String, double> accountBalances;

  bool get isTransfer => rows.length > 1;

  /// The only row, or the OUT row of a transfer (the BE sends it first).
  Transaction get primary => rows.first;

  factory TransactionWriteResult.fromJson(Map<String, dynamic> json) =>
      TransactionWriteResult(
        rows: (json['rows'] as List)
            .cast<Map<String, dynamic>>()
            .map(Transaction.fromJson)
            .toList(),
        accountBalances: WalletBalance.mapOf(json['account_balances']),
      );
}

typedef TransactionMutationResult = TransactionWriteResult;

/// `DELETE /transactions/:id` result: the id and the wallets' balances.
class DeleteTransactionResult {
  const DeleteTransactionResult({
    required this.id,
    this.accountBalances = const {},
  });

  final String id;
  final Map<String, double> accountBalances;

  factory DeleteTransactionResult.fromJson(Map<String, dynamic> json) =>
      DeleteTransactionResult(
        id: json['id'] as String,
        accountBalances: WalletBalance.mapOf(json['account_balances']),
      );
}

/// One debt row a transaction's split made (GET /transactions/:id). The
/// person comes embedded with its live name and icon ([EmbeddedPerson]).
class TxSplit extends Equatable {
  const TxSplit({
    required this.debtId,
    required this.person,
    required this.amount,
    this.settledAmount = 0,
    this.status = 'open',
    this.owedToMe = true,
  });

  final String debtId;
  final EmbeddedPerson person;
  final double amount;
  final double settledAmount;

  /// open · settled · cancelled.
  final String status;

  /// owed_to_me (they pay me back) vs i_owe (I pay them).
  final bool owedToMe;

  String get personName => person.name;
  String? get contactId => person.contactId;

  /// amount − repaid. Negative = overpaid (repayments don't limit edits,
  /// owner 2026-10-10).
  double get outstanding => amount - settledAmount;

  bool get isOverpaid => outstanding < -0.005;

  factory TxSplit.fromJson(Map<String, dynamic> json) => TxSplit(
    debtId: json['debt_id'] as String,
    person: json['person'] is Map<String, dynamic>
        ? EmbeddedPerson.fromJson(json['person'] as Map<String, dynamic>)
        : EmbeddedPerson(
            name: (json['person_name'] as String?) ?? '',
            contactId: json['contact_id'] as String?,
          ),
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    settledAmount: (json['settled_amount'] as num?)?.toDouble() ?? 0,
    status: (json['status'] as String?) ?? 'open',
    owedToMe: json['direction'] != 'i_owe',
  );

  @override
  List<Object?> get props => [
    debtId,
    person,
    amount,
    settledAmount,
    status,
    owedToMe,
  ];
}
