import 'package:equatable/equatable.dart';

import '../../../ui/ui.dart' show PpForgeIconCode;
import '../../institutions/domain/institution.dart';
import '../../transactions/domain/refs.dart' show AccountRef;
import 'debt_ledger.dart';

/// 0.4.3: a debt's counterparty is a person (a contact or a typed name) or an
/// institution (`i:<id>`). Rows of an older BE carry no kind: a person.
enum DebtCounterpartyKind {
  person,
  institution;

  static DebtCounterpartyKind fromJson(Object? v, {String? key}) =>
      v == 'institution' || (v == null && (key?.startsWith('i:') ?? false))
      ? institution
      : person;
}

/// The recurring item a debt row was made by (`entry.recurring`, 0.4.3):
/// the row's tag "ผ่อนโทรศัพท์ 3/12".
class DebtRecurringRef extends Equatable {
  const DebtRecurringRef({
    required this.id,
    required this.name,
    this.iconCode,
    this.installmentSeq,
    this.installmentCount,
  });

  static DebtRecurringRef? tryParse(Object? json) =>
      json is Map && json['id'] is String
      ? DebtRecurringRef(
          id: json['id'] as String,
          name: (json['name'] as String?) ?? '',
          iconCode: _icon(json['icon_code']),
          installmentSeq: (json['installment_seq'] as num?)?.toInt(),
          installmentCount: (json['installment_count'] as num?)?.toInt(),
        )
      : null;

  final String id;
  final String name;
  final PpForgeIconCode? iconCode;

  /// The installment this row was ticked for; null = none.
  final int? installmentSeq;

  /// Its plan's installments (n/N).
  final int? installmentCount;

  @override
  List<Object?> get props => [
    id,
    name,
    iconCode,
    installmentSeq,
    installmentCount,
  ];
}

/// One installment in short (`plan.next`).
class DebtInstallmentRef extends Equatable {
  const DebtInstallmentRef({required this.seq, this.dueDate, this.amount});

  static DebtInstallmentRef? tryParse(Object? json) =>
      json is Map && json['seq'] is num
      ? DebtInstallmentRef(
          seq: (json['seq'] as num).toInt(),
          dueDate: _date(json['due_date']),
          amount: (json['amount'] as num?)?.toDouble(),
        )
      : null;

  final int seq;
  final DateTime? dueDate;
  final double? amount;

  @override
  List<Object?> get props => [seq, dueDate, amount];
}

/// A debt item's plan as the counterparty page shows it (contract §3 `Plan`,
/// only what the card needs).
class DebtRecurringPlan extends Equatable {
  const DebtRecurringPlan({
    required this.count,
    this.done = 0,
    this.leftCount,
    this.principal,
    this.leftPrincipal,
    this.lastDate,
    this.next,
    this.cardAccountId,
  });

  static DebtRecurringPlan? tryParse(Object? json) {
    if (json is! Map || json['count'] is! num) return null;
    return DebtRecurringPlan(
      count: (json['count'] as num).toInt(),
      done: (json['done'] as num?)?.toInt() ?? 0,
      leftCount: (json['left_count'] as num?)?.toInt(),
      principal: (json['principal'] as num?)?.toDouble(),
      leftPrincipal: (json['left_principal'] as num?)?.toDouble(),
      lastDate: _date(json['last_date']),
      next: DebtInstallmentRef.tryParse(json['next']),
      cardAccountId:
          (json['creditor'] is Map && json['creditor']['account'] is Map)
          ? json['creditor']['account']['id'] as String?
          : null,
    );
  }

  final int count;

  /// Installments ticked "จ่ายงวดแล้ว".
  final int done;
  final int? leftCount;
  final double? principal;
  final double? leftPrincipal;
  final DateTime? lastDate;

  /// The next installment (the oldest one not ticked); null = all done.
  final DebtInstallmentRef? next;

  /// A card installment (ผ่อนผ่านบัตร): the card holds the debt.
  final String? cardAccountId;

  /// The installment a repayment offers to tick: [next], else the one after
  /// the ticked ones; null when every one is ticked.
  int? get seqToMark {
    final n = next?.seq;
    if (n != null) return n;
    return done < count ? done + 1 : null;
  }

  @override
  List<Object?> get props => [
    count,
    done,
    leftCount,
    principal,
    leftPrincipal,
    lastDate,
    next,
    cardAccountId,
  ];
}

/// One line of an item on the counterparty card: when, from where, how much.
/// The BE may send the item's lines; without them the card shows the item's
/// next round only.
class DebtRecurringLine extends Equatable {
  const DebtRecurringLine({
    required this.id,
    this.amount,
    this.accountName,
    this.paidByName,
    this.nextDate,
    this.repayment = false,
  });

  static DebtRecurringLine? tryParse(Object? json) {
    if (json is! Map || json['id'] is! String) return null;
    // BE Line: `account` / `paid_by` are page-ready refs beside `source`.
    final account = json['account'];
    final paidBy = json['paid_by'];
    return DebtRecurringLine(
      id: json['id'] as String,
      amount: (json['amount'] as num?)?.toDouble(),
      accountName: account is Map ? account['name'] as String? : null,
      paidByName: paidBy is Map
          ? (paidBy['name'] as String?) ?? (paidBy['person_name'] as String?)
          : null,
      nextDate: _date(json['next_date']),
      repayment: json['debt_kind'] == 'repayment',
    );
  }

  final String id;
  final double? amount;

  /// The wallet it pays from / into; null with [paidByName] = คนจ่ายแทน.
  final String? accountName;
  final String? paidByName;
  final DateTime? nextDate;

  /// A repayment line (else it makes debts).
  final bool repayment;

  @override
  List<Object?> get props => [
    id,
    amount,
    accountName,
    paidByName,
    nextDate,
    repayment,
  ];
}

/// One recurring item of a counterparty (`recurrings[]` on its page:
/// RecurringSummary + plan). Parsed here, apart from the recurring feature's
/// own models. Also reads the 0.4.1-2 `recurring[]` rows of an older BE.
class DebtCounterpartyRecurring extends Equatable {
  const DebtCounterpartyRecurring({
    required this.id,
    required this.name,
    this.iconCode,
    this.status = 'active',
    this.owedToMe,
    this.balance,
    this.linesCount = 0,
    this.nextDate,
    this.nextAmount,
    this.dueCount = 0,
    this.plan,
    this.lines = const [],
  });

  factory DebtCounterpartyRecurring.fromJson(Map<String, dynamic> json) {
    final next = json['next'];
    // the rework: the direction lives on the rules (the first debt one)
    final rules = (json['rules'] as List?) ?? const [];
    final ruleDirection = rules
        .whereType<Map<String, dynamic>>()
        .map((r) => r['debt_direction'])
        .whereType<String>()
        .firstOrNull;
    final direction =
        (json['debt_direction'] ?? json['direction'] ?? ruleDirection)
            as String?;
    return DebtCounterpartyRecurring(
      id: json['id'] as String,
      name: (json['name'] as String?) ?? '',
      iconCode: _icon(json['icon_code']),
      status: (json['status'] as String?) ?? 'active',
      owedToMe: direction == null
          ? null
          : DebtEntryDirection.parse(direction) == DebtEntryDirection.paid,
      balance: (json['balance'] as num?)?.toDouble(),
      linesCount: (json['rules_count'] as num?)?.toInt() ?? 0,
      nextDate: next is Map ? _date(next['date']) : _date(json['next_date']),
      nextAmount: next is Map
          ? (next['amount'] as num?)?.toDouble()
          : ((json['next_amount'] ?? json['amount']) as num?)?.toDouble(),
      dueCount: (json['due_count'] as num?)?.toInt() ?? 0,
      plan: DebtRecurringPlan.tryParse(json['plan']),
      lines: [for (final l in rules) ?DebtRecurringLine.tryParse(l)],
    );
  }

  final String id;
  final String name;
  final PpForgeIconCode? iconCode;

  /// active | paused | archived | done.
  final String status;

  /// The item's side: it makes debts they owe me (true) or I owe (false);
  /// null = not sent.
  final bool? owedToMe;

  /// What it still adds up to, signed like a net (> 0 = they owe me), when
  /// the BE sends it; else the plan's principal left on [owedToMe]'s side.
  final double? balance;
  final int linesCount;
  final DateTime? nextDate;
  final double? nextAmount;
  final int dueCount;
  final DebtRecurringPlan? plan;
  final List<DebtRecurringLine> lines;

  bool get paused => status == 'paused';

  /// Signed like a net; null = nothing to say.
  double? get signedLeft {
    final b = balance;
    if (b != null) return b;
    final left = plan?.leftPrincipal;
    final side = owedToMe;
    if (left == null || side == null) return null;
    return side ? left : -left;
  }

  @override
  List<Object?> get props => [
    id,
    name,
    iconCode,
    status,
    owedToMe,
    balance,
    linesCount,
    nextDate,
    nextAmount,
    dueCount,
    plan,
    lines,
  ];
}

/// "หนี้บัตรเครดิต" on an institution's page (`card_debts[]`): a card's
/// balance less the unbilled principal of its card plans. No row of its own.
class DebtCardDebt extends Equatable {
  const DebtCardDebt({required this.account, required this.amount, this.due});

  static DebtCardDebt? tryParse(Object? json) {
    if (json is! Map || json['account'] is! Map) return null;
    final a = (json['account'] as Map).cast<String, dynamic>();
    if (a['id'] is! String) return null;
    return DebtCardDebt(
      account: AccountRef.fromJson(a),
      amount: ((json['amount'] as num?)?.toDouble() ?? 0).abs(),
      due: _date(json['due_date']),
    );
  }

  final AccountRef account;

  /// What I owe on it (≥ 0).
  final double amount;
  final DateTime? due;

  @override
  List<Object?> get props => [account, amount, due];
}

enum DebtPreviewKind { entry, recurring, cardDebt, general }

/// One of a list group's first rows (`entries_preview`): a debt / repayment
/// row, or (when the BE groups them) a recurring item, a card's debt or the
/// counterparty's general debts in one line.
class DebtPreviewRow extends Equatable {
  const DebtPreviewRow({
    required this.kind,
    required this.amount,
    this.id,
    this.title,
    this.iconCode,
    this.date,
    this.nextAmount,
    this.plan,
    this.count,
    this.entry,
    this.account,
  });

  static DebtPreviewRow? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.cast<String, dynamic>();
    final kind = json['kind'] ?? json['type'];
    double signed() =>
        ((json['net'] ?? json['amount'] ?? json['balance']) as num?)
            ?.toDouble() ??
        0;
    switch (kind) {
      case 'recurring':
        final next = json['next'];
        final plan = json['plan'];
        return DebtPreviewRow(
          kind: DebtPreviewKind.recurring,
          id: json['id'] as String?,
          title: _text(json['name']) ?? _text(json['title']),
          iconCode: _icon(json['icon_code']),
          amount: signed(),
          date: next is Map ? _date(next['date']) : _date(json['date']),
          nextAmount: next is Map ? (next['amount'] as num?)?.toDouble() : null,
          plan: plan is Map
              ? (
                  done: (plan['done'] as num?)?.toInt() ?? 0,
                  count: (plan['count'] as num?)?.toInt() ?? 0,
                )
              : null,
        );
      case 'card_debt':
        final card = DebtCardDebt.tryParse(json);
        if (card == null) return null;
        return DebtPreviewRow(
          kind: DebtPreviewKind.cardDebt,
          id: card.account.id,
          title: card.account.name,
          amount: -card.amount,
          date: card.due,
          account: card.account,
        );
      case 'general':
        return DebtPreviewRow(
          kind: DebtPreviewKind.general,
          amount: signed(),
          date: _date(json['date']),
          count: (json['count'] as num?)?.toInt(),
        );
    }
    if (json['id'] is! String || json['amount'] is! num) return null;
    final e = DebtEntry.fromJson(json);
    return DebtPreviewRow(
      kind: DebtPreviewKind.entry,
      id: e.id,
      title: e.description ?? e.recurring?.name,
      amount: e.signedAmount,
      date: e.dueDate ?? e.date,
      entry: e,
    );
  }

  final DebtPreviewKind kind;

  /// The entry / item / card account's id.
  final String? id;
  final String? title;
  final PpForgeIconCode? iconCode;

  /// Signed like a net (> 0 = they owe me).
  final double amount;

  /// Its due / next date (an entry: due date, else its date).
  final DateTime? date;
  final double? nextAmount;
  final ({int done, int count})? plan;

  /// [DebtPreviewKind.general]: how many rows it stands for.
  final int? count;
  final DebtEntry? entry;
  final AccountRef? account;

  @override
  List<Object?> get props => [
    kind,
    id,
    title,
    iconCode,
    amount,
    date,
    nextAmount,
    plan,
    count,
    entry,
    account,
  ];
}

/// The installment a repayment with this counterparty offers to tick
/// ("ทำเครื่องหมายว่าจ่ายงวดแล้ว"): the oldest unticked installment of the
/// item with the nearest one, among items with a plan on the repayment's
/// side ([owedToMe] = they pay me back). Card plans are paid with the card's
/// statement: never offered. Null = none.
({DebtCounterpartyRecurring item, int seq})? installmentToMark(
  List<DebtCounterpartyRecurring> items, {
  bool? owedToMe,
}) {
  ({DebtCounterpartyRecurring item, int seq})? best;
  DateTime? bestDue;
  for (final r in items) {
    final plan = r.plan;
    if (plan == null || plan.cardAccountId != null) continue;
    if (r.status == 'archived') continue;
    if (owedToMe != null && r.owedToMe != null && r.owedToMe != owedToMe) {
      continue;
    }
    final seq = plan.seqToMark;
    if (seq == null) continue;
    final due = plan.next?.dueDate;
    final better =
        best == null ||
        (due != null && (bestDue == null || due.isBefore(bestDue)));
    if (better) {
      best = (item: r, seq: seq);
      bestDue = due;
    }
  }
  return best;
}

/// The tag a statement row made by an item carries: its name, and n/N when
/// the row was ticked for an installment of a plan the page knows.
String debtRecurringTagText(
  DebtRecurringRef ref,
  List<DebtCounterpartyRecurring> items,
) {
  final seq = ref.installmentSeq;
  if (seq == null) return ref.name;
  final count =
      ref.installmentCount ??
      items.where((r) => r.id == ref.id).firstOrNull?.plan?.count;
  return count == null ? '${ref.name} $seq' : '${ref.name} $seq/$count';
}

/// The institution of a row / page, or null for a person.
InstitutionRef? institutionOf(Map<String, dynamic> json, String key) {
  final ref = InstitutionRef.tryParse(json['institution']);
  if (ref != null) return ref;
  final id = institutionIdOfKey(key);
  if (id == null) return null;
  final person = json['person'];
  return InstitutionRef(
    id: id,
    name: person is Map ? (person['name'] as String?) ?? '' : '',
  );
}

PpForgeIconCode? _icon(Object? v) =>
    v is Map ? PpForgeIconCode.fromJson(v.cast<String, dynamic>()) : null;

DateTime? _date(Object? raw) =>
    raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

String? _text(Object? raw) {
  final s = raw as String?;
  return (s == null || s.trim().isEmpty) ? null : s;
}
