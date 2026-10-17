import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart';
import '../../pending/domain/pending_transaction.dart';
import '../../projects/domain/project.dart';
import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction_type.dart';
import 'recurrence_rule.dart';
import 'recurring.dart';

/// The recurring an item came from (API `RecurringRef`; null on a one-off
/// or a manual item).
class RecurringParent extends Equatable {
  const RecurringParent({required this.id, required this.name, this.iconCode});

  factory RecurringParent.fromJson(Map<String, dynamic> json) =>
      RecurringParent(
        id: json['id'] as String,
        name: (json['name'] as String?) ?? '',
        iconCode: json['icon_code'] is Map<String, dynamic>
            ? IconCode.fromJson(json['icon_code'] as Map<String, dynamic>)
            : null,
      );

  final String id;
  final String name;
  final IconCode? iconCode;

  @override
  List<Object?> get props => [id, name, iconCode];
}

/// One produced / upcoming / manual item (API `RecurringItem`): the
/// recurring module's own record, linked (🔗) to a pending draft or a real
/// transaction the way an event bill is. Its [state] is BE-derived from that
/// link + the date + the archived flag.
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
  });

  final String id;
  final RecurringParent? recurring;

  /// n of N (null on manual / one-off items; [total] null = no end).
  final int? seq;
  final int? total;
  final DateTime date;

  /// Negative = in the past.
  final int daysUntil;
  final TransactionType type;

  /// null = not known yet (a reminder).
  final double? amount;
  final AccountRef? account;
  final AccountRef? toAccount;
  final EmbeddedCategory? category;
  final List<TagRef> tags;
  final String? description;
  final String? note;
  final OccurrenceState state;

  /// The pending draft it became (รอยืนยัน).
  final String? pendingId;

  /// The real transaction it became (บันทึกแล้ว) — same shape as an event
  /// bill's source tx.
  final BoardSourceTx? transaction;
  final bool edited;
  final bool manual;

  /// Linked to a draft or a real tx (🔗).
  bool get linked => pendingId != null || transaction != null;

  /// The row title: its own description, else the recurring's name.
  String get title {
    final d = description?.trim() ?? '';
    if (d.isNotEmpty) return d;
    return recurring?.name ?? '';
  }

  /// Signed for display (expense negative).
  double? get signedAmount {
    final a = amount;
    if (a == null) return null;
    return type == TransactionType.expense ? -a : a;
  }

  factory RecurringItem.fromJson(Map<String, dynamic> json) => RecurringItem(
    id: json['id'] as String,
    recurring: json['recurring'] is Map<String, dynamic>
        ? RecurringParent.fromJson(json['recurring'] as Map<String, dynamic>)
        : null,
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
  );

  /// The item as a tx-shaped draft (what the entry sheet edits).
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
  ];
}

/// The wire value of the kit's [EditScope] (Google Calendar style).
extension EditScopeJson on EditScope {
  String toJson() => this == EditScope.thisOne ? 'this' : name;
}

/// Where "สร้างใหม่" puts an item.
enum ItemTarget {
  pending,
  transaction;

  String toJson() => name;
}

/// The `RecurringFields` body of an item write (+ its date), from a draft.
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

/// A page of items (API `RecurringItemList`, page-numbered).
class ItemPage extends Equatable {
  const ItemPage({this.items = const [], this.page = 1, this.totalPages = 1});

  factory ItemPage.fromJson(Map<String, dynamic>? json) {
    final p = json?['pagination'] as Map<String, dynamic>?;
    return ItemPage(
      items: [
        for (final e in (json?['data'] as List?) ?? const [])
          RecurringItem.fromJson(e as Map<String, dynamic>),
      ],
      page: (p?['page'] as num?)?.toInt() ?? 1,
      totalPages: (p?['total_pages'] as num?)?.toInt() ?? 1,
    );
  }

  final List<RecurringItem> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;

  /// This page appended to [previous] (load more).
  ItemPage after(ItemPage previous) => ItemPage(
    items: [...previous.items, ...items],
    page: page,
    totalPages: totalPages,
  );

  @override
  List<Object?> get props => [items, page, totalPages];
}

/// The recurring page's state, as every recurring read / write returns it
/// (API `RecurringDetail`).
class RecurringDetail extends Equatable {
  const RecurringDetail({
    required this.recurring,
    this.produced = const ItemPage(),
    this.upcoming = const ItemPage(),
    this.balances = const {},
    this.deletePreview,
  });

  factory RecurringDetail.fromJson(Map<String, dynamic> json) =>
      RecurringDetail(
        recurring: Recurring.fromJson(
          json['recurring'] as Map<String, dynamic>,
        ),
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

  /// The first page of the upcoming items (soonest first).
  final ItemPage upcoming;

  /// Only with `include=delete_preview`, else null.
  final RecurringDeletePreview? deletePreview;

  /// Produced items (status ≠ upcoming), newest first — the first page.
  final ItemPage produced;

  /// {account id: balance} for `AccountsCubit.patchBalances`.
  final Map<String, double> balances;

  @override
  List<Object?> get props => [
    recurring,
    produced,
    upcoming,
    balances,
    deletePreview,
  ];
}

/// What deleting a recurring touches (`?include=delete_preview`).
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

/// What an item write changed: the items it returned / removed + the wallet
/// balances it moved.
class ItemWriteResult extends Equatable {
  const ItemWriteResult({
    this.items = const [],
    this.deletedIds = const [],
    this.balances = const {},
    this.setting,
  });

  /// Any of `RecurringItemWriteResult` / `RecurringItemsWriteResult` /
  /// `RecurringItemDeleteResult` / `RecurringItemBatchResult`.
  factory ItemWriteResult.fromJson(
    Map<String, dynamic> json,
  ) => ItemWriteResult(
    items: [
      for (final e in (json['items'] as List?) ?? const [])
        RecurringItem.fromJson(e as Map<String, dynamic>),
      if (json['item'] is Map<String, dynamic>)
        RecurringItem.fromJson(json['item'] as Map<String, dynamic>),
    ],
    deletedIds: [
      for (final e in (json['deleted_ids'] as List?) ?? const []) e as String,
      // A single delete answers `{id, transaction_id, …}`.
      if (json['id'] is String) json['id'] as String,
    ],
    balances: WalletBalance.mapOf(json['account_balances']),
    setting: json['setting'] is Map<String, dynamic>
        ? Recurring.fromJson(json['setting'] as Map<String, dynamic>)
        : null,
  );

  final List<RecurringItem> items;
  final List<String> deletedIds;
  final Map<String, double> balances;

  /// The owning setting after the write; null when the items belong to no /
  /// several settings (the page then re-runs its one call).
  final Recurring? setting;

  /// [list] with this write applied: changed items replaced, deleted dropped
  /// (new items are not inserted: the caller decides where they go).
  List<RecurringItem> applyTo(List<RecurringItem> list) {
    final byId = {for (final i in items) i.id: i};
    return [
      for (final i in list)
        if (!deletedIds.contains(i.id)) byId[i.id] ?? i,
    ];
  }

  @override
  List<Object?> get props => [items, deletedIds, balances, setting];
}
