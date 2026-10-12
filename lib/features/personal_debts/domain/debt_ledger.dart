import 'package:equatable/equatable.dart';

import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction.dart';
import 'debt_direction.dart';

export 'debt_direction.dart';
export 'debt_link.dart';

/// The person ledger (0.3.1-10, owner 2026-10-12; spec tag "Debts"): every
/// debt record is one ENTRY with a person, a fixed direction (paid /
/// received) and a positive amount. Net per person = Σ paid − Σ received;
/// the BE computes every number, the FE only shows it.

/// Net per person: > 0 they owe me (ติดคุณ), < 0 I owe them (คุณติด).
enum NetSide {
  owedToMe,
  iOwe,
  even;

  static NetSide of(double net) => net > 0.005
      ? NetSide.owedToMe
      : (net < -0.005 ? NetSide.iOwe : NetSide.even);

  /// The people-list filter value (`side=`).
  String get wire => this == NetSide.owedToMe ? 'owed_to_me' : 'i_owe';
}

/// `Page`: `{page, per_page, total, total_pages}`.
class DebtPaging extends Equatable {
  const DebtPaging({
    this.page = 1,
    this.perPage = 30,
    this.total = 0,
    this.totalPages = 1,
  });

  final int page;
  final int perPage;
  final int total;
  final int totalPages;
  bool get hasMore => page < totalPages;

  factory DebtPaging.fromJson(Map<String, dynamic>? json) => json == null
      ? const DebtPaging()
      : DebtPaging(
          page: (json['page'] as num?)?.toInt() ?? 1,
          perPage: (json['per_page'] as num?)?.toInt() ?? 30,
          total: (json['total'] as num?)?.toInt() ?? 0,
          totalPages: (json['total_pages'] as num?)?.toInt() ?? 1,
        );

  @override
  List<Object?> get props => [page, perPage, total, totalPages];
}

/// `DebtPerson`: one person's balance — a people list row, the person page
/// header, and `person_balance` in every debt write (patch, never re-fetch).
class PersonBalance extends Equatable {
  const PersonBalance({
    required this.key,
    required this.person,
    required this.net,
    this.openCount = 0,
    this.entryCount = 0,
    this.lastActivityAt,
  });

  /// `c:<contact id>` or `n:<lower-cased typed name>`.
  final String key;
  final EmbeddedPerson person;

  /// Σ paid − Σ received.
  final double net;

  /// Entries not labelled paid.
  final int openCount;
  final int entryCount;

  /// The latest entry date (null with no entries).
  final DateTime? lastActivityAt;

  NetSide get side => NetSide.of(net);

  factory PersonBalance.fromJson(Map<String, dynamic> json) => PersonBalance(
    key: json['key'] as String,
    person: EmbeddedPerson.fromJson(
      (json['person'] as Map).cast<String, dynamic>(),
    ),
    net: (json['net'] as num?)?.toDouble() ?? 0,
    openCount: (json['open_count'] as num?)?.toInt() ?? 0,
    entryCount: (json['entry_count'] as num?)?.toInt() ?? 0,
    lastActivityAt: _date(json['last_activity_at']),
  );

  static PersonBalance? maybe(Object? json) =>
      json is Map ? PersonBalance.fromJson(json.cast<String, dynamic>()) : null;

  @override
  List<Object?> get props => [
    key,
    person,
    net,
    openCount,
    entryCount,
    lastActivityAt,
  ];
}

/// `DebtTotals`: the people list header, the Home tile and the More tile
/// (one rule). They ignore the list's search / side / "ทั้งหมด" / paging.
class DebtTotals extends Equatable {
  const DebtTotals({
    this.owedToMe = 0,
    this.iOwe = 0,
    this.net = 0,
    this.openCount = 0,
  });

  /// Σ net of the people with net > 0.
  final double owedToMe;

  /// Σ |net| of the people with net < 0.
  final double iOwe;
  final double net;

  /// People with something open.
  final int openCount;

  factory DebtTotals.fromJson(Map<String, dynamic>? json) => json == null
      ? const DebtTotals()
      : DebtTotals(
          owedToMe: (json['owed_to_me'] as num?)?.toDouble() ?? 0,
          iOwe: (json['i_owe'] as num?)?.toDouble() ?? 0,
          net: (json['net'] as num?)?.toDouble() ?? 0,
          openCount: (json['open_count'] as num?)?.toInt() ?? 0,
        );

  @override
  List<Object?> get props => [owedToMe, iOwe, net, openCount];
}

/// `DebtPeopleList` (`GET /personal-debts/people`).
class DebtPeoplePage extends Equatable {
  const DebtPeoplePage({
    required this.items,
    required this.totals,
    required this.paging,
  });

  final List<PersonBalance> items;
  final DebtTotals totals;
  final DebtPaging paging;

  factory DebtPeoplePage.fromJson(Map<String, dynamic> json) => DebtPeoplePage(
    items: _list(json['data'], PersonBalance.fromJson),
    totals: DebtTotals.fromJson(_map(json['totals'])),
    paging: DebtPaging.fromJson(_map(json['pagination'])),
  );

  @override
  List<Object?> get props => [items, totals, paging];
}

/// `DebtSource`: where a split-sourced entry came from. Such an entry edits
/// only description / note / paid.
class DebtEntrySource extends Equatable {
  const DebtEntrySource({required this.kind, this.id, this.title});

  /// `transaction` (a split on my bill: [id] = that tx) · `event` (an event
  /// board: [id] = the event) · `partner` (another user's split on me: no
  /// [id], [title] = their name).
  final String kind;
  final String? id;
  final String? title;

  factory DebtEntrySource.fromJson(Map<String, dynamic> json) =>
      DebtEntrySource(
        kind: json['kind'] as String,
        id: json['id'] as String?,
        title: json['title'] as String?,
      );

  @override
  List<Object?> get props => [kind, id, title];
}

/// `DebtEntryTx`: the wallet transaction of an entry (light ref for rows).
class DebtEntryTransaction extends Equatable {
  const DebtEntryTransaction({required this.id, this.account});

  final String id;

  /// Null only for an old floating repayment.
  final AccountRef? account;

  factory DebtEntryTransaction.fromJson(Map<String, dynamic> json) =>
      DebtEntryTransaction(
        id: json['id'] as String,
        account: json['account'] is Map
            ? AccountRef.fromJson(_map(json['account'])!)
            : null,
      );

  @override
  List<Object?> get props => [id, account];
}

/// `DebtEntry`: one ledger entry with a person.
class DebtEntry extends Equatable {
  const DebtEntry({
    required this.id,
    required this.direction,
    required this.amount,
    this.key,
    this.date,
    this.description,
    this.note,
    this.paid = false,
    this.source,
    this.transaction,
    this.createdAt,
    this.updatedAt,
  });

  final String id;

  /// The person's key.
  final String? key;
  final DebtEntryDirection direction;

  /// Always positive; [direction] says which way.
  final double amount;
  final DateTime? date;
  final String? description;
  final String? note;

  /// The "จ่ายแล้ว" label: it never changes any number.
  final bool paid;

  /// Null = a manual entry (fully editable).
  final DebtEntrySource? source;

  /// Null = ledger-only (no wallet).
  final DebtEntryTransaction? transaction;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get iPaid => direction == DebtEntryDirection.paid;
  bool get movedMoney => transaction != null;
  bool get fromSplit => source != null;

  factory DebtEntry.fromJson(Map<String, dynamic> json) => DebtEntry(
    id: json['id'] as String,
    key: json['key'] as String?,
    direction: DebtEntryDirection.parse(json['direction'] as String?),
    amount: (json['amount'] as num).toDouble().abs(),
    date: _date(json['date']),
    description: _text(json['description']),
    note: _text(json['note']),
    paid: (json['paid'] as bool?) ?? false,
    source: json['source'] is Map
        ? DebtEntrySource.fromJson(_map(json['source'])!)
        : null,
    transaction: json['transaction'] is Map
        ? DebtEntryTransaction.fromJson(_map(json['transaction'])!)
        : null,
    createdAt: _date(json['created_at']),
    updatedAt: _date(json['updated_at']),
  );

  static DebtEntry? maybe(Object? json) =>
      json is Map ? DebtEntry.fromJson(json.cast<String, dynamic>()) : null;

  @override
  List<Object?> get props => [
    id,
    key,
    direction,
    amount,
    date,
    description,
    note,
    paid,
    source,
    transaction,
    createdAt,
    updatedAt,
  ];
}

/// `DebtEntryList` (`GET …/people/{key}/entries`), and the first page
/// embedded in the person page.
class DebtEntriesPage extends Equatable {
  const DebtEntriesPage({required this.items, required this.paging});

  final List<DebtEntry> items;
  final DebtPaging paging;

  factory DebtEntriesPage.fromJson(Map<String, dynamic> json, {String? key}) =>
      DebtEntriesPage(
        items: _list(json[key ?? 'data'], DebtEntry.fromJson),
        paging: DebtPaging.fromJson(_map(json['pagination'])),
      );

  @override
  List<Object?> get props => [items, paging];
}

/// `DebtPersonPage` (`GET /personal-debts/people/{key}`): the balance, the
/// counts and the first page of the timeline, in one call.
class DebtPersonDetail extends Equatable {
  const DebtPersonDetail({
    required this.balance,
    required this.entries,
    this.entryCount = 0,
    this.moneyCount = 0,
  });

  final PersonBalance balance;
  final DebtEntriesPage entries;

  /// Tab "รายการหนี้".
  final int entryCount;

  /// Tab "ประวัติการจ่าย" (entries with a wallet transaction).
  final int moneyCount;

  factory DebtPersonDetail.fromJson(Map<String, dynamic> json) {
    final counts = _map(json['counts']);
    return DebtPersonDetail(
      balance: PersonBalance.fromJson(json),
      entries: DebtEntriesPage.fromJson(json, key: 'items'),
      entryCount: (counts?['entries'] as num?)?.toInt() ?? 0,
      moneyCount: (counts?['money'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [balance, entries, entryCount, moneyCount];
}

/// `DebtEntryDetail` (`GET /personal-debts/{id}`): the tx detail page in
/// debt mode — the entry, the person's balance and the linked transaction
/// as a full row (null = ledger-only).
class DebtEntryDetail extends Equatable {
  const DebtEntryDetail({
    required this.entry,
    required this.balance,
    this.transaction,
  });

  final DebtEntry entry;
  final PersonBalance balance;
  final Transaction? transaction;

  factory DebtEntryDetail.fromJson(Map<String, dynamic> json) =>
      DebtEntryDetail(
        entry: DebtEntry.fromJson(_map(json['entry'])!),
        balance: PersonBalance.fromJson(_map(json['person_balance'])!),
        transaction: json['transaction'] is Map
            ? Transaction.fromJson(_map(json['transaction'])!)
            : null,
      );

  @override
  List<Object?> get props => [entry, balance, transaction];
}

/// `DebtEntryWriteResult`: every debt write (create, update, the paid label,
/// accepting a split) returns the final state.
class DebtEntryWriteResult extends Equatable {
  const DebtEntryWriteResult({
    required this.entry,
    required this.balance,
    this.previousBalance,
    this.transaction,
    this.accountBalances = const {},
  });

  final DebtEntry entry;

  /// The person's new balance.
  final PersonBalance balance;

  /// Set only when an edit moved the entry to another person (the old
  /// person's new balance).
  final PersonBalance? previousBalance;

  /// The linked transaction, full row (null = ledger-only).
  final Transaction? transaction;

  /// {wallet id: balance} for every wallet the write touched.
  final Map<String, double> accountBalances;

  factory DebtEntryWriteResult.fromJson(Map<String, dynamic> json) =>
      DebtEntryWriteResult(
        entry: DebtEntry.fromJson(_map(json['entry'])!),
        balance: PersonBalance.fromJson(_map(json['person_balance'])!),
        previousBalance: PersonBalance.maybe(json['previous_person_balance']),
        transaction: json['transaction'] is Map
            ? Transaction.fromJson(_map(json['transaction'])!)
            : null,
        accountBalances: WalletBalance.mapOf(json['account_balances']),
      );

  @override
  List<Object?> get props => [
    entry,
    balance,
    previousBalance,
    transaction,
    accountBalances,
  ];
}

/// `DebtEntryDeleteResult`: the entry is gone, with its wallet transaction.
class DebtEntryDeleteResult extends Equatable {
  const DebtEntryDeleteResult({
    required this.id,
    required this.balance,
    this.transactionId,
    this.accountBalances = const {},
  });

  final String id;

  /// The linked transaction deleted with it (null = ledger-only).
  final String? transactionId;
  final PersonBalance balance;
  final Map<String, double> accountBalances;

  factory DebtEntryDeleteResult.fromJson(Map<String, dynamic> json) =>
      DebtEntryDeleteResult(
        id: json['id'] as String,
        transactionId: json['transaction_id'] as String?,
        balance: PersonBalance.fromJson(_map(json['person_balance'])!),
        accountBalances: WalletBalance.mapOf(json['account_balances']),
      );

  @override
  List<Object?> get props => [id, transactionId, balance, accountBalances];
}

/// `DebtSplitChangeResult` ("อัปเดตตาม" on a split_changed).
class DebtSplitChangeResult extends Equatable {
  const DebtSplitChangeResult({
    required this.deleted,
    required this.balance,
    this.entry,
  });

  /// true = the split was removed and my entry is gone.
  final bool deleted;

  /// My entry with the new amount (null when [deleted]).
  final DebtEntry? entry;
  final PersonBalance balance;

  factory DebtSplitChangeResult.fromJson(Map<String, dynamic> json) =>
      DebtSplitChangeResult(
        deleted: json['result'] == 'deleted',
        entry: DebtEntry.maybe(json['entry']),
        balance: PersonBalance.fromJson(_map(json['person_balance'])!),
      );

  @override
  List<Object?> get props => [deleted, entry, balance];
}

/// The timeline's sort orders (`sort=`).
enum DebtEntrySort {
  dateDesc('date_desc'),
  dateAsc('date_asc'),
  amountDesc('amount_desc'),
  amountAsc('amount_asc');

  const DebtEntrySort(this.wire);
  final String wire;
}

/// Search / filter / sort of one person's entries.
class DebtEntryQuery extends Equatable {
  const DebtEntryQuery({
    this.q = '',
    this.sort = DebtEntrySort.dateDesc,
    this.direction,
    this.paid,
    this.moneyOnly = false,
    this.accountId,
  });

  final String q;
  final DebtEntrySort sort;
  final DebtEntryDirection? direction;

  /// The "จ่ายแล้ว" label filter (`paid=false` = the mark-paid list).
  final bool? paid;

  /// Only entries that moved wallet money (the "ประวัติการจ่าย" tab).
  final bool moneyOnly;
  final String? accountId;

  /// Search / filter / sort differ from the default view.
  bool get isFiltered =>
      q.trim().isNotEmpty ||
      sort != DebtEntrySort.dateDesc ||
      direction != null ||
      paid != null ||
      accountId != null;

  Map<String, dynamic> toQuery() => <String, dynamic>{
    if (q.trim().isNotEmpty) 'q': q.trim(),
    'sort': sort.wire,
    'direction': ?direction?.wire,
    if (paid != null) 'paid': paid.toString(),
    if (moneyOnly) 'money': 'true',
    'account_id': ?accountId,
  };

  DebtEntryQuery copyWith({
    String? q,
    DebtEntrySort? sort,
    DebtEntryDirection? direction,
    bool clearDirection = false,
    bool? paid,
    bool clearPaid = false,
    String? accountId,
    bool clearAccount = false,
  }) => DebtEntryQuery(
    q: q ?? this.q,
    sort: sort ?? this.sort,
    direction: clearDirection ? null : (direction ?? this.direction),
    paid: clearPaid ? null : (paid ?? this.paid),
    moneyOnly: moneyOnly,
    accountId: clearAccount ? null : (accountId ?? this.accountId),
  );

  @override
  List<Object?> get props => [q, sort, direction, paid, moneyOnly, accountId];
}

/// The person key for a contact / a typed name (what the BE groups by; it
/// always returns `n:` keys lower-cased and trimmed).
String debtPersonKey({String? contactId, String? name}) => contactId != null
    ? 'c:$contactId'
    : 'n:${(name ?? '').trim().toLowerCase()}';

/// `yyyy-MM-dd` for the API's `Date` fields.
String debtDateWire(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
    '${d.month.toString().padLeft(2, '0')}-'
    '${d.day.toString().padLeft(2, '0')}';

Map<String, dynamic>? _map(Object? raw) =>
    raw is Map ? raw.cast<String, dynamic>() : null;

List<T> _list<T>(Object? raw, T Function(Map<String, dynamic>) parse) =>
    ((raw as List?) ?? const [])
        .map((e) => parse((e as Map).cast<String, dynamic>()))
        .toList();

DateTime? _date(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

String? _text(Object? raw) {
  final s = raw as String?;
  return (s == null || s.trim().isEmpty) ? null : s;
}
