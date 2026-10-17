import 'package:equatable/equatable.dart';

import '../../personal_debts/domain/debt_link.dart';
import '../../tags/domain/tag.dart';
import 'refs.dart';
import 'transaction_type.dart';
import '../../../ui/ui.dart';

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

/// Tag ref enriched with color + icon so the FE can render chips inline without
/// consulting the tags cache.
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

  Tag get asTag => Tag(id: id, name: name, iconCode: iconCode);

  @override
  List<Object?> get props => [id, name, iconCode];
}

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
    this.counterparty,
    this.eventBill,
    this.recurringItem,
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

  final double amount;

  final String date;

  final String? categoryId;

  final AccountRef? account;
  final EmbeddedCategory? category;

  final List<EmbeddedTag> tags;

  final String? description;
  final String? note;

  final String? projectId;

  final String? transferGroupId;

  final DebtLink? counterparty;

  bool get isDebtEntry => counterparty != null;

  final EventBillLink? eventBill;

  final RecurringItemLink? recurringItem;

  bool get hasPromptedLink =>
      (eventBill?.linked ?? false) || recurringItem != null;

  final TransferPeer? transferPeer;

  final String? currency;

  bool get hasSplits => splitCount > 0;

  final TransactionAuthor? createdBy;
  final bool isLocked;
  final bool canEditCategory;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  final int splitCount;

  final List<TxSplit> splits;

  final EventRef? project;

  final double? myShare;

  final bool? canSplit;
  final bool? canEditSplits;
  final bool? canJoinEvent;

  bool get isTransferOut =>
      type == TransactionType.transfer && _isTransferOutRow;
  bool get isTransferIn =>
      type == TransactionType.transfer && !_isTransferOutRow;

  bool get _isTransferOutRow =>
      transferPeer?.isOut ?? (category?.isTransferOut ?? false);

  double get signedAmount {
    if (type == TransactionType.income) return amount;
    if (type == TransactionType.expense) return -amount;
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
      recurringItem: json['recurring_item'] is Map
          ? RecurringItemLink.fromJson(
              (json['recurring_item'] as Map).cast<String, dynamic>(),
            )
          : null,
      eventBill: json['event_bill'] is Map
          ? EventBillLink.fromJson(
              (json['event_bill'] as Map).cast<String, dynamic>(),
            )
          : null,
      counterparty: json['counterparty'] is Map
          ? DebtLink.fromJson(
              (json['counterparty'] as Map).cast<String, dynamic>(),
            )
          : null,
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
    DebtLink? counterparty,
    EventBillLink? eventBill,
    RecurringItemLink? recurringItem,
    bool clearRecurringItem = false,
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
      counterparty: counterparty ?? this.counterparty,
      eventBill: eventBill ?? this.eventBill,
      recurringItem: clearRecurringItem
          ? null
          : (recurringItem ?? this.recurringItem),
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
    counterparty,
    eventBill,
    recurringItem,
    transferPeer,
    currency,
    myShare,
    canSplit,
    canEditSplits,
    canJoinEvent,
  ];
}

class TransactionWriteResult {
  const TransactionWriteResult({
    required this.rows,
    this.accountBalances = const {},
    this.upcoming,
  });

  TransactionWriteResult.single(Transaction tx)
    : rows = [tx],
      accountBalances = const {},
      upcoming = null;

  final List<Transaction> rows;

  final Map<String, double> accountBalances;

  final Map<String, dynamic>? upcoming;

  bool get isUpcoming => upcoming != null;

  bool get isTransfer => rows.length > 1;

  Transaction get primary => rows.first;

  factory TransactionWriteResult.fromJson(Map<String, dynamic> json) =>
      TransactionWriteResult(
        rows: ((json['rows'] as List?) ?? const [])
            .cast<Map<String, dynamic>>()
            .map(Transaction.fromJson)
            .toList(),
        accountBalances: WalletBalance.mapOf(json['account_balances']),
        upcoming: json['upcoming'] is Map
            ? (json['upcoming'] as Map).cast<String, dynamic>()
            : null,
      );
}

typedef TransactionMutationResult = TransactionWriteResult;

class DeleteTransactionResult {
  const DeleteTransactionResult({
    required this.id,
    this.accountBalances = const {},
    this.recurringItemId,
    this.billId,
  });

  final String id;
  final Map<String, double> accountBalances;

  final String? recurringItemId;
  final String? billId;

  factory DeleteTransactionResult.fromJson(Map<String, dynamic> json) =>
      DeleteTransactionResult(
        id: json['id'] as String,
        accountBalances: WalletBalance.mapOf(json['account_balances']),
        recurringItemId: json['recurring_item_id'] as String?,
        billId: json['bill_id'] as String?,
      );
}

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

  final String status;

  final bool owedToMe;

  String get personName => person.name;
  String? get contactId => person.contactId;

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
