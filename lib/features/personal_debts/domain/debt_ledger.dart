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
    this.clearedAt,
    this.daysOutstanding,
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

  /// The CYCLE boundary: the last entry after which the balance was 0 (null
  /// = it never was). Entries after it are the current cycle.
  final DateTime? clearedAt;

  /// Age in days of the oldest unpaid entry of the current cycle (null =
  /// none) — the BE's number, shown as "ค้าง N วัน".
  final int? daysOutstanding;

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
    clearedAt: _date(json['cleared_at']),
    daysOutstanding: (json['days_outstanding'] as num?)?.toInt(),
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
    clearedAt,
    daysOutstanding,
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
    this.owedToMePeople = 0,
    this.iOwePeople = 0,
    this.over30DaysPeople = 0,
  });

  /// Σ net of the people with net > 0.
  final double owedToMe;

  /// Σ |net| of the people with net < 0.
  final double iOwe;
  final double net;

  /// People with something open.
  final int openCount;

  /// People with net > 0 / net < 0 (the tiles' "N คน").
  final int owedToMePeople;
  final int iOwePeople;

  /// People whose oldest open entry (current cycle) is over 30 days old.
  final int over30DaysPeople;

  factory DebtTotals.fromJson(Map<String, dynamic>? json) => json == null
      ? const DebtTotals()
      : DebtTotals(
          owedToMe: (json['owed_to_me'] as num?)?.toDouble() ?? 0,
          iOwe: (json['i_owe'] as num?)?.toDouble() ?? 0,
          net: (json['net'] as num?)?.toDouble() ?? 0,
          openCount: (json['open_count'] as num?)?.toInt() ?? 0,
          owedToMePeople: (json['owed_to_me_people'] as num?)?.toInt() ?? 0,
          iOwePeople: (json['i_owe_people'] as num?)?.toInt() ?? 0,
          over30DaysPeople: (json['over_30_days_people'] as num?)?.toInt() ?? 0,
        );

  @override
  List<Object?> get props => [
    owedToMe,
    iOwe,
    net,
    openCount,
    owedToMePeople,
    iOwePeople,
    over30DaysPeople,
  ];
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
    this.inCurrentCycle,
  });

  final String id;

  /// Only in a person's entry lists: true = after the cycle boundary
  /// (`cleared_at`), false = an earlier cycle; null elsewhere.
  final bool? inCurrentCycle;

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
    inCurrentCycle: json['in_current_cycle'] as bool?,
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
    inCurrentCycle,
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
    this.counts = const DebtCounts(),
    this.message = const DebtSummaryMessage(),
  });

  final PersonBalance balance;

  /// The first page of the asked cycle (the current one by default).
  final DebtEntriesPage entries;
  final DebtCounts counts;

  /// The text to send the person (BE-built, current cycle).
  final DebtSummaryMessage message;

  factory DebtPersonDetail.fromJson(Map<String, dynamic> json) =>
      DebtPersonDetail(
        balance: PersonBalance.fromJson(json),
        entries: DebtEntriesPage.fromJson(json, key: 'items'),
        counts: DebtCounts.fromJson(_map(json['counts'])),
        message: DebtSummaryMessage.fromJson(_map(json['summary_message'])),
      );

  @override
  List<Object?> get props => [balance, entries, counts, message];
}

/// `counts` of the person page: all entries, wallet-money entries, and the
/// current / earlier cycle split (the "รอบก่อนหน้านี้" fold shows when
/// [earlier] > 0).
class DebtCounts extends Equatable {
  const DebtCounts({
    this.entries = 0,
    this.money = 0,
    this.current = 0,
    this.earlier = 0,
  });

  final int entries;
  final int money;
  final int current;
  final int earlier;

  factory DebtCounts.fromJson(Map<String, dynamic>? json) => json == null
      ? const DebtCounts()
      : DebtCounts(
          entries: (json['entries'] as num?)?.toInt() ?? 0,
          money: (json['money'] as num?)?.toInt() ?? 0,
          current: (json['current'] as num?)?.toInt() ?? 0,
          earlier: (json['earlier'] as num?)?.toInt() ?? 0,
        );

  @override
  List<Object?> get props => [entries, money, current, earlier];
}

/// `DebtSummaryMessage`: the BE-built text to send a person (current-cycle
/// entries, both directions) — the person page's message box.
class DebtSummaryMessage extends Equatable {
  const DebtSummaryMessage({this.text = '', this.entries = 0, this.net = 0});

  final String text;

  /// Entries listed in [text].
  final int entries;
  final double net;

  factory DebtSummaryMessage.fromJson(Map<String, dynamic>? json) =>
      json == null
      ? const DebtSummaryMessage()
      : DebtSummaryMessage(
          text: (json['text'] as String?) ?? '',
          entries: (json['entries'] as num?)?.toInt() ?? 0,
          net: (json['net'] as num?)?.toDouble() ?? 0,
        );

  @override
  List<Object?> get props => [text, entries, net];
}

/// The people list's sort (`sort=`): the longest outstanding first (default),
/// the biggest amount, or the latest activity.
enum DebtPeopleSort {
  oldest('oldest'),
  amount('amount'),
  recent('recent');

  const DebtPeopleSort(this.wire);
  final String wire;
}

/// Which debt cycle a person's entries come from (`cycle=`): the current one
/// (after the balance last hit 0) or the earlier ones.
enum DebtCycle {
  current('current'),
  earlier('earlier');

  const DebtCycle(this.wire);
  final String wire;
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
    this.accountId,
  });

  final String q;
  final DebtEntrySort sort;
  final DebtEntryDirection? direction;

  /// The "จ่ายแล้ว" label filter (`paid=false` = the mark-paid list).
  final bool? paid;
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
    accountId: clearAccount ? null : (accountId ?? this.accountId),
  );

  @override
  List<Object?> get props => [q, sort, direction, paid, accountId];
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
