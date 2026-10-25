import 'package:equatable/equatable.dart';

import '../../transactions/domain/refs.dart';
import '../../transactions/domain/transaction.dart';
import 'debt_direction.dart';

export 'debt_direction.dart';
export 'debt_link.dart';

enum NetSide {
  owedToMe,
  iOwe,
  even;

  static NetSide of(double net) => net > 0.005
      ? NetSide.owedToMe
      : (net < -0.005 ? NetSide.iOwe : NetSide.even);

  String get wire => this == NetSide.owedToMe ? 'owed_to_me' : 'i_owe';
}

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
    this.firstActivityAt,
    this.lastActivity,
    this.nextDueDate,
  });

  /// The earliest due date among the unpaid debts on the person's current
  /// side; null when even or none has one.
  final DateTime? nextDueDate;

  /// The first line's date ever ("ติดต่อกันตั้งแต่ …"; 0.4.0-3).
  final DateTime? firstActivityAt;

  /// The latest line, for the people row's second line (0.4.0-3).
  final DebtLastActivity? lastActivity;

  final String key;
  final EmbeddedPerson person;

  final double net;

  final int openCount;
  final int entryCount;

  final DateTime? lastActivityAt;

  /// The CYCLE boundary: the last entry after which the balance was 0 (null =
  /// it never was).
  final DateTime? clearedAt;

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
    firstActivityAt: _date(json['first_activity_at']),
    lastActivity: json['last_activity'] is Map
        ? DebtLastActivity.fromJson(_map(json['last_activity'])!)
        : null,
    nextDueDate: _date(json['next_due_date']),
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
    firstActivityAt,
    lastActivity,
    nextDueDate,
  ];
}

/// A person's latest statement line (BE `last_activity`, 0.4.0-3): a debt or
/// a repayment, for the people row's "ค่าตั๋ว | 1 ก.ย." line.
class DebtLastActivity extends Equatable {
  const DebtLastActivity({
    required this.isRepayment,
    required this.id,
    required this.direction,
    required this.amount,
    this.title,
    this.date,
  });

  final bool isRepayment;
  final String id;
  final DebtEntryDirection direction;
  final double amount;

  /// Its description; null = word it from kind + direction.
  final String? title;
  final DateTime? date;

  factory DebtLastActivity.fromJson(Map<String, dynamic> json) =>
      DebtLastActivity(
        isRepayment: json['kind'] == 'repayment',
        id: (json['id'] as String?) ?? '',
        direction: DebtEntryDirection.parse(json['direction'] as String?),
        amount: ((json['amount'] as num?)?.toDouble() ?? 0).abs(),
        title: _text(json['title']),
        date: _date(json['date']),
      );

  @override
  List<Object?> get props => [isRepayment, id, direction, amount, title, date];
}

class DebtTotals extends Equatable {
  const DebtTotals({
    this.owedToMe = 0,
    this.iOwe = 0,
    this.net = 0,
    this.openCount = 0,
    this.owedToMePeople = 0,
    this.iOwePeople = 0,
    this.over30DaysPeople = 0,
    this.counts,
  });

  /// The list's filter chips (0.4.0-3): people with something open, per
  /// side, and older than 30 days. Null = an older BE (count on the device).
  final ({int all, int receivable, int payable, int overdue30})? counts;

  final double owedToMe;

  final double iOwe;
  final double net;

  final int openCount;

  final int owedToMePeople;
  final int iOwePeople;

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
          counts: switch (_map(json['counts'])) {
            final c? => (
              all: (c['all'] as num?)?.toInt() ?? 0,
              receivable: (c['receivable'] as num?)?.toInt() ?? 0,
              payable: (c['payable'] as num?)?.toInt() ?? 0,
              overdue30: (c['overdue_30'] as num?)?.toInt() ?? 0,
            ),
            null => null,
          },
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
    counts,
  ];
}

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

class DebtEntrySource extends Equatable {
  const DebtEntrySource({required this.kind, this.id, this.title});

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

class DebtEntryTransaction extends Equatable {
  const DebtEntryTransaction({required this.id, this.account});

  final String id;

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
    this.isRepayment = false,
    this.origin,
    this.runningBalance,
    this.dueDate,
  });

  /// "กำหนดจ่าย" (0.4.0-3); never on a repayment.
  final DateTime? dueDate;

  /// Debts (0.4.0-3): where it came from (the row's sub-line, the debt
  /// detail's "มาจาก" card); null = ledger-only / a repayment.
  final DebtOrigin? origin;

  /// The person's balance right after this line (0.4.0-3).
  final double? runningBalance;

  /// What the line adds to the person's net: + paid, − received.
  double get signedAmount =>
      direction == DebtEntryDirection.paid ? amount : -amount;

  /// A debt's id; on a [isRepayment] statement line, its transaction's id.
  final String id;

  /// A person-statement line that is a REPAYMENT (a transaction tied to the
  /// person, `kind: "repayment"`, 0.4.0-3) rather than a debt. It opens
  /// /transactions/{id}; it has no paid label and no source.
  final bool isRepayment;

  final bool? inCurrentCycle;

  final String? key;
  final DebtEntryDirection direction;

  final double amount;
  final DateTime? date;
  final String? description;
  final String? note;

  /// The "จ่ายแล้ว" label: it never changes any number.
  final bool paid;

  final DebtEntrySource? source;

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
    isRepayment: json['kind'] == 'repayment',
    origin: json['origin'] is Map
        ? DebtOrigin.fromJson(_map(json['origin'])!)
        : null,
    runningBalance: (json['running_balance'] as num?)?.toDouble(),
    dueDate: _date(json['due_date']),
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
    isRepayment,
    origin,
    runningBalance,
    dueDate,
  ];
}

/// Where a debt came from (BE DebtOrigin, 0.4.0-3): `split` (my bill),
/// `paid_by` (someone paid for me), `partner` (another user's split on me),
/// `event` (an event bill), `cash` (a cash loan with its own tx). The debt
/// itself has no wallet; [account] is its transaction's.
class DebtOrigin extends Equatable {
  const DebtOrigin({
    required this.kind,
    this.transactionId,
    this.billId,
    this.eventId,
    this.title,
    this.amount,
    this.date,
    this.account,
  });

  final String kind;
  final String? transactionId;
  final String? billId;
  final String? eventId;
  final String? title;
  final double? amount;
  final DateTime? date;
  final AccountRef? account;

  factory DebtOrigin.fromJson(Map<String, dynamic> json) => DebtOrigin(
    kind: (json['kind'] as String?) ?? '',
    transactionId: json['transaction_id'] as String?,
    billId: json['bill_id'] as String?,
    eventId: json['event_id'] as String?,
    title: _text(json['title']),
    amount: (json['amount'] as num?)?.toDouble(),
    date: _date(json['date']),
    account: json['account'] is Map
        ? AccountRef.fromJson(_map(json['account'])!)
        : null,
  );

  @override
  List<Object?> get props => [
    kind,
    transactionId,
    billId,
    eventId,
    title,
    amount,
    date,
    account,
  ];
}

/// One day of a person's statement (BE `days`, 0.4.0-3): the day's change
/// (+ = they owe me more / I owe less) and the balance at its end.
class DebtDay extends Equatable {
  const DebtDay({
    required this.date,
    required this.change,
    required this.balanceAfter,
  });

  final DateTime date;
  final double change;
  final double balanceAfter;

  factory DebtDay.fromJson(Map<String, dynamic> json) => DebtDay(
    date: _date(json['date']) ?? DateTime(1970),
    change: (json['change'] as num?)?.toDouble() ?? 0,
    balanceAfter: (json['balance_after'] as num?)?.toDouble() ?? 0,
  );

  @override
  List<Object?> get props => [date, change, balanceAfter];
}

class DebtEntriesPage extends Equatable {
  const DebtEntriesPage({
    required this.items,
    required this.paging,
    this.days = const [],
  });

  final List<DebtEntry> items;
  final DebtPaging paging;

  /// The page's day groups (0.4.0-3); empty = an older BE (the app sums).
  final List<DebtDay> days;

  factory DebtEntriesPage.fromJson(Map<String, dynamic> json, {String? key}) =>
      DebtEntriesPage(
        items: _list(json[key ?? 'data'], DebtEntry.fromJson),
        paging: DebtPaging.fromJson(_map(json['pagination'])),
        days: _list(json['days'], DebtDay.fromJson),
      );

  @override
  List<Object?> get props => [items, paging, days];
}

class DebtPersonDetail extends Equatable {
  const DebtPersonDetail({
    required this.balance,
    required this.entries,
    this.counts = const DebtCounts(),
    this.message = const DebtSummaryMessage(),
  });

  final PersonBalance balance;

  final DebtEntriesPage entries;
  final DebtCounts counts;

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

class DebtSummaryMessage extends Equatable {
  const DebtSummaryMessage({
    this.text = '',
    this.entries = 0,
    this.net = 0,
    this.textBalanceOnly = '',
  });

  /// Share variant "รอบนี้".
  final String text;

  /// Share variant "ยอดคงเหลืออย่างเดียว" (0.4.0-3).
  final String textBalanceOnly;

  final int entries;
  final double net;

  factory DebtSummaryMessage.fromJson(Map<String, dynamic>? json) =>
      json == null
      ? const DebtSummaryMessage()
      : DebtSummaryMessage(
          text: (json['text'] as String?) ?? '',
          textBalanceOnly: (json['text_balance_only'] as String?) ?? '',
          entries: (json['entries'] as num?)?.toInt() ?? 0,
          net: (json['net'] as num?)?.toDouble() ?? 0,
        );

  @override
  List<Object?> get props => [text, textBalanceOnly, entries, net];
}

enum DebtPeopleSort {
  oldest('oldest'),
  amount('amount'),
  recent('recent');

  const DebtPeopleSort(this.wire);
  final String wire;
}

enum DebtCycle {
  current('current'),
  earlier('earlier');

  const DebtCycle(this.wire);
  final String wire;
}

class DebtEntryDetail extends Equatable {
  const DebtEntryDetail({
    required this.entry,
    required this.balance,
    this.transaction,
    this.linkedTransaction,
  });

  final DebtEntry entry;
  final PersonBalance balance;
  final Transaction? transaction;

  /// One of my own transactions linked to the entry (บันทึกในรายการ); never
  /// set together with [transaction].
  final Transaction? linkedTransaction;

  factory DebtEntryDetail.fromJson(Map<String, dynamic> json) =>
      DebtEntryDetail(
        entry: DebtEntry.fromJson(_map(json['entry'])!),
        balance: PersonBalance.fromJson(_map(json['person_balance'])!),
        transaction: json['transaction'] is Map
            ? Transaction.fromJson(_map(json['transaction'])!)
            : null,
        linkedTransaction: json['linked_transaction'] is Map
            ? Transaction.fromJson(_map(json['linked_transaction'])!)
            : null,
      );

  @override
  List<Object?> get props => [entry, balance, transaction, linkedTransaction];
}

class DebtEntryWriteResult extends Equatable {
  const DebtEntryWriteResult({
    required this.entry,
    required this.balance,
    this.previousBalance,
    this.transaction,
    this.linkedTransaction,
    this.accountBalances = const {},
  });

  final DebtEntry entry;

  final PersonBalance balance;

  final PersonBalance? previousBalance;

  final Transaction? transaction;
  final Transaction? linkedTransaction;

  final Map<String, double> accountBalances;

  factory DebtEntryWriteResult.fromJson(Map<String, dynamic> json) =>
      DebtEntryWriteResult(
        entry: DebtEntry.fromJson(_map(json['entry'])!),
        balance: PersonBalance.fromJson(_map(json['person_balance'])!),
        previousBalance: PersonBalance.maybe(json['previous_person_balance']),
        transaction: json['transaction'] is Map
            ? Transaction.fromJson(_map(json['transaction'])!)
            : null,
        linkedTransaction: json['linked_transaction'] is Map
            ? Transaction.fromJson(_map(json['linked_transaction'])!)
            : null,
        accountBalances: WalletBalance.mapOf(json['account_balances']),
      );

  @override
  List<Object?> get props => [
    entry,
    balance,
    previousBalance,
    transaction,
    linkedTransaction,
    accountBalances,
  ];
}

/// What `POST /personal-debts/people/{key}/repayments` answers (0.4.0-3): the
/// ONE transaction it made, the person's balance after it and the wallet
/// balances it moved.
class DebtRepaymentResult extends Equatable {
  const DebtRepaymentResult({
    required this.transaction,
    required this.balance,
    this.accountBalances = const {},
  });

  final Transaction transaction;
  final PersonBalance balance;
  final Map<String, double> accountBalances;

  factory DebtRepaymentResult.fromJson(Map<String, dynamic> json) =>
      DebtRepaymentResult(
        transaction: Transaction.fromJson(_map(json['transaction'])!),
        balance: PersonBalance.fromJson(_map(json['person_balance'])!),
        accountBalances: WalletBalance.mapOf(json['account_balances']),
      );

  @override
  List<Object?> get props => [transaction, balance, accountBalances];
}

class DebtEntryDeleteResult extends Equatable {
  const DebtEntryDeleteResult({
    required this.id,
    required this.balance,
    this.transactionId,
    this.accountBalances = const {},
  });

  final String id;

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

class DebtSplitChangeResult extends Equatable {
  const DebtSplitChangeResult({
    required this.deleted,
    required this.balance,
    this.entry,
  });

  final bool deleted;

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

enum DebtEntrySort {
  dateDesc('date_desc'),
  dateAsc('date_asc'),
  amountDesc('amount_desc'),
  amountAsc('amount_asc');

  const DebtEntrySort(this.wire);
  final String wire;
}

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

  final bool? paid;
  final String? accountId;

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

String debtPersonKey({String? contactId, String? name}) => contactId != null
    ? 'c:$contactId'
    : 'n:${(name ?? '').trim().toLowerCase()}';

/// A debt write's `?preview=true` answer (0.4.0-3, BE DebtPreview): the
/// person's net before → after (> 0 = they owe me) and the wallet effect.
/// Nothing is saved.
class DebtPreview extends Equatable {
  const DebtPreview({
    required this.before,
    required this.after,
    this.flipped = false,
    this.walletDelta,
  });

  final double before;
  final double after;

  /// The side crossed (e.g. รอจ่าย 160, pay 200 → รอรับ 40).
  final bool flipped;

  /// The wallet's change; null = no wallet moves.
  final double? walletDelta;

  factory DebtPreview.fromJson(Map<String, dynamic> json) {
    final people = _list(json['people'], (p) => p);
    final wallets = _list(json['wallets'], (w) => w);
    double n(Object? v) => (v as num?)?.toDouble() ?? 0;
    final p = people.firstOrNull ?? const <String, dynamic>{};
    return DebtPreview(
      before: n(p['before']),
      after: n(p['after']),
      flipped: p['flipped'] == true,
      walletDelta: wallets.isEmpty ? null : n(wallets.first['delta']),
    );
  }

  @override
  List<Object?> get props => [before, after, flipped, walletDelta];
}

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
