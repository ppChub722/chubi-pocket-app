import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import '../../pending/domain/pending_transaction.dart';
import '../../projects/domain/project.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction_type.dart';
import 'recurrence_rule.dart';
import 'recurring.dart';

class RecurringParent extends Equatable {
  const RecurringParent({
    required this.id,
    required this.name,
    this.iconCode,
    this.kind,
  });

  factory RecurringParent.fromJson(Map<String, dynamic> json) =>
      RecurringParent(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        iconCode: json['icon_code'] is Map<String, dynamic>
            ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
            : null,
        kind: json['kind'] is String
            ? RecurringKind.fromJson(json['kind'] as String)
            : null,
      );

  final String id;
  final String name;
  final IconCode? iconCode;

  /// Null from a BE that doesn't send it yet.
  final RecurringKind? kind;

  @override
  List<Object?> get props => [id, name, iconCode, kind];
}

class RecurringItem extends Equatable {
  const RecurringItem({
    required this.id,
    required this.date,
    required this.type,
    this.amount,
    required this.state,
    this.recurring,
    this.seq,
    this.total,
    this.daysUntil = 0,
    this.account,
    this.toAccount,
    this.category,
    this.tags = const [],
    this.description,
    this.note,
    this.pendingId,
    this.transaction,
    this.edited = false,
    this.manual = false,
    this.createdAt,
    this.updatedAt,
    this.ruleId,
    this.slot,
    this.stored = true,
    this.autoCreated = false,
    this.needsAmount = false,
  });

  /// The stored row's id, or `slot:{rule}:{slot}` for a computed occurrence
  /// (the BE sends id null): a stable key either way.
  final String id;
  final RecurringParent? recurring;

  /// The rule and the occurrence's original date ("YYYY-MM-DD"): its address
  /// on `/recurring/{rule}/occurrences/{slot}`. Null from an old BE.
  final String? ruleId;
  final String? slot;

  /// False = computed by the BE, no row yet.
  final bool stored;

  /// Recorded by the rule's auto-create, no tap.
  final bool autoCreated;

  /// Due or this month with no amount yet (ใส่ยอด).
  final bool needsAmount;

  /// Addressable by rule + slot (the new occurrence API).
  bool get bySlot => ruleId != null && slot != null;

  final int? seq;
  final int? total;
  final DateTime date;

  final int daysUntil;
  final TransactionType type;

  final double? amount;
  final AccountRef? account;
  final AccountRef? toAccount;
  final EmbeddedCategory? category;
  final List<TagRef> tags;
  final String? description;
  final String? note;
  final OccurrenceState state;

  final String? pendingId;

  final BoardSourceTx? transaction;
  final bool edited;
  final bool manual;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get linked => pendingId != null || transaction != null;

  String get title {
    final d = description?.trim() ?? '';
    if (d.isNotEmpty) return d;
    return recurring?.name ?? '';
  }

  double? get signedAmount {
    final a = amount;
    if (a == null) return null;
    return type == TransactionType.expense ? -a : a;
  }

  static const _types = {'expense', 'income', 'transfer'};

  /// Null for a row the app has no type for (the BE's `saving`), so one such
  /// row doesn't break a whole list.
  static RecurringItem? tryParse(Object? json) =>
      json is Map<String, dynamic> &&
          _types.contains((json['type'] as String?) ?? 'expense')
      ? RecurringItem.fromJson(json)
      : null;

  factory RecurringItem.fromJson(Map<String, dynamic> json) {
    final recurring = json['recurring'] is Map<String, dynamic>
        ? RecurringParent.fromJson(json['recurring'] as Map<String, dynamic>)
        : null;
    final ruleId = json['rule_id'] as String? ?? recurring?.id;
    final slot = json['slot'] as String?;
    final id = json['id'] as String?;
    return RecurringItem._fromJson(
      json,
      id: id ?? 'slot:$ruleId:$slot',
      recurring: recurring,
      ruleId: ruleId,
      slot: slot,
      stored: json['stored'] as bool? ?? id != null,
    );
  }

  factory RecurringItem._fromJson(
    Map<String, dynamic> json, {
    required String id,
    required RecurringParent? recurring,
    required String? ruleId,
    required String? slot,
    required bool stored,
  }) => RecurringItem(
    id: id,
    recurring: recurring,
    ruleId: ruleId,
    slot: slot,
    stored: stored,
    autoCreated: json['auto_created'] == true,
    needsAmount: json['needs_amount'] == true,
    seq: (json['seq'] as num?)?.toInt(),
    total: (json['total'] as num?)?.toInt(),
    date: parseYmd(json['date'] as String?) ?? DateTime.now(),
    daysUntil: (json['days_until'] as num?)?.toInt() ?? 0,
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
    description: json['description'] as String?,
    note: json['note'] as String?,
    state: OccurrenceState.parse(json['status'] as String?),
    pendingId: json['pending_id'] as String?,
    transaction: BoardSourceTx.tryParse(json['transaction']),
    edited: json['edited'] == true,
    manual: json['manual'] == true,
    createdAt: DateTime.tryParse(
      (json['created_at'] as String?) ?? '',
    )?.toLocal(),
    updatedAt: DateTime.tryParse(
      (json['updated_at'] as String?) ?? '',
    )?.toLocal(),
  );

  PendingDraft toDraft() => PendingDraft(
    type: type,
    amount: amount,
    accountId: account?.id,
    transferToAccountId: toAccount?.id,
    categoryId: category?.id,
    date: ymd(date),
    description: description,
    note: note,
    tagIds: [for (final t in tags) t.id],
  );

  @override
  List<Object?> get props => [
    id,
    recurring,
    seq,
    total,
    date,
    daysUntil,
    type,
    amount,
    account,
    toAccount,
    category,
    tags,
    description,
    note,
    state,
    pendingId,
    transaction,
    edited,
    manual,
    createdAt,
    updatedAt,
    ruleId,
    slot,
    stored,
    autoCreated,
    needsAmount,
  ];
}

extension EditScopeJson on EditScope {
  String toJson() => this == EditScope.thisOne ? 'this' : name;
}

Map<String, dynamic> itemFieldsJson(PendingDraft d) => <String, dynamic>{
  'type': ?d.type?.toJson(),
  'amount': ?d.amount,
  'account_id': d.accountId,
  'to_account_id': d.transferToAccountId,
  'category_id': d.categoryId,
  'description': d.description,
  'note': d.note,
  'tag_ids': d.tagIds,
  'date': ?d.date,
};

class ItemPage extends Equatable {
  const ItemPage({
    this.items = const [],
    this.page = 1,
    this.totalPages = 1,
    this.windowed = false,
    this.nextFrom,
  });

  factory ItemPage.fromJson(Map<String, dynamic>? json) {
    final p = json?['pagination'] as Map<String, dynamic>?;
    final w = json?['window'] as Map<String, dynamic>?;
    return ItemPage(
      items: [
        for (final e in (json?['data'] as List?) ?? const [])
          ?RecurringItem.tryParse(e),
      ],
      page: (p?['page'] as num?)?.toInt() ?? 1,
      totalPages: (p?['total_pages'] as num?)?.toInt() ?? 1,
      windowed: w != null,
      nextFrom: parseYmd(w?['next_from'] as String?),
    );
  }

  final List<RecurringItem> items;
  final int page;
  final int totalPages;

  /// A no-end rule's upcoming list comes a year at a time (`window`), not
  /// by page; [nextFrom] is where the next year starts.
  final bool windowed;
  final DateTime? nextFrom;

  bool get hasMore => page < totalPages;

  ItemPage after(ItemPage previous) => ItemPage(
    items: [...previous.items, ...items],
    page: page,
    totalPages: totalPages,
    windowed: windowed,
    nextFrom: nextFrom,
  );

  @override
  List<Object?> get props => [items, page, totalPages, windowed, nextFrom];
}

class RecurringDetail extends Equatable {
  const RecurringDetail({
    required this.recurring,
    this.produced = const ItemPage(),
    this.upcoming = const ItemPage(),
    this.balances = const {},
    this.deletePreview,
    this.stats,
    this.txUpdateFailed = 0,
  });

  factory RecurringDetail.fromJson(Map<String, dynamic> json) =>
      RecurringDetail(
        recurring: Recurring.fromJson(
          json['recurring'] as Map<String, dynamic>,
        ),
        stats: json['stats'] is Map<String, dynamic>
            ? RecurringStats.fromJson(json['stats'] as Map<String, dynamic>)
            : null,
        txUpdateFailed:
            ((json['tx_update'] as Map<String, dynamic>?)?['failed'] as List?)
                ?.length ??
            0,
        produced: ItemPage.fromJson(json['items'] as Map<String, dynamic>?),
        upcoming: ItemPage.fromJson(json['upcoming'] as Map<String, dynamic>?),
        balances: WalletBalance.mapOf(json['account_balances']),
        deletePreview: json['delete_preview'] is Map<String, dynamic>
            ? RecurringDeletePreview.fromJson(
                json['delete_preview'] as Map<String, dynamic>,
              )
            : null,
      );

  final Recurring recurring;

  final ItemPage upcoming;

  final RecurringDeletePreview? deletePreview;

  final ItemPage produced;

  final Map<String, double> balances;

  /// Null from an old BE.
  final RecurringStats? stats;

  /// After a rule edit with `also_update_tx`: recorded tx it couldn't update.
  final int txUpdateFailed;

  @override
  List<Object?> get props => [
    recurring,
    produced,
    upcoming,
    balances,
    deletePreview,
    stats,
    txUpdateFailed,
  ];
}

class RecurringDeletePreview extends Equatable {
  const RecurringDeletePreview({
    this.items = 0,
    this.linkedTransactions = 0,
    this.pendingDrafts = 0,
  });

  factory RecurringDeletePreview.fromJson(Map<String, dynamic> json) =>
      RecurringDeletePreview(
        items: (json['items'] as num?)?.toInt() ?? 0,
        linkedTransactions: (json['linked_transactions'] as num?)?.toInt() ?? 0,
        pendingDrafts: (json['pending_drafts'] as num?)?.toInt() ?? 0,
      );

  final int items;
  final int linkedTransactions;
  final int pendingDrafts;

  @override
  List<Object?> get props => [items, linkedTransactions, pendingDrafts];
}

class ItemWriteResult extends Equatable {
  const ItemWriteResult({
    this.items = const [],
    this.deletedIds = const [],
    this.balances = const {},
    this.setting,
    this.leftOut = const [],
  });

  factory ItemWriteResult.fromJson(Map<String, dynamic> json) =>
      ItemWriteResult(
        items: [
          for (final e in (json['items'] as List?) ?? const [])
            RecurringItem.fromJson(e as Map<String, dynamic>),
          if (json['item'] is Map<String, dynamic>)
            RecurringItem.fromJson(json['item'] as Map<String, dynamic>),
        ],
        deletedIds: [
          for (final e in (json['deleted_ids'] as List?) ?? const [])
            e as String,
          if (json['id'] is String) json['id'] as String,
        ],
        balances: WalletBalance.mapOf(json['account_balances']),
        setting: json['setting'] is Map<String, dynamic>
            ? Recurring.fromJson(json['setting'] as Map<String, dynamic>)
            : null,
        leftOut: [
          for (final e in (json['left_out'] as List?) ?? const [])
            if (e is Map<String, dynamic>)
              (
                slot: (e['slot'] as String?) ?? '',
                reason: (e['reason'] as String?) ?? '',
              ),
        ],
      );

  final List<RecurringItem> items;
  final List<String> deletedIds;
  final Map<String, double> balances;

  final Recurring? setting;

  /// A bulk action's occurrences it didn't settle, and why.
  final List<({String slot, String reason})> leftOut;

  static String? _slotKey(RecurringItem i) =>
      i.bySlot ? '${i.ruleId}:${i.slot}' : null;

  /// Patches [list]: a written occurrence replaces its old row by id, or by
  /// rule + slot when a computed one got stored (its id changed).
  List<RecurringItem> applyTo(List<RecurringItem> list) {
    final byId = {for (final i in items) i.id: i};
    final bySlot = {for (final i in items) ?_slotKey(i): i};
    return [
      for (final i in list)
        if (!deletedIds.contains(i.id)) byId[i.id] ?? bySlot[_slotKey(i)] ?? i,
    ];
  }

  @override
  List<Object?> get props => [items, deletedIds, balances, setting, leftOut];
}
