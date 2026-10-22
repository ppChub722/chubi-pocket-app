import 'debt_ledger.dart';

/// The backend's rules for the people list (`personal_debts/store.go`), so the
/// device can filter, sort and total the directory it holds.

bool isOpenPerson(PersonBalance p) => p.net.abs() > 0.005 || p.openCount > 0;

double _round2(double v) => (v * 100).roundToDouble() / 100;

DebtTotals debtTotalsOf(Iterable<PersonBalance> people) {
  var owed = 0.0;
  var owe = 0.0;
  var open = 0;
  var owedPeople = 0;
  var owePeople = 0;
  var over30 = 0;
  for (final p in people) {
    if (p.net > 0.005) {
      owed += p.net;
      owedPeople++;
    } else if (p.net < -0.005) {
      owe -= p.net;
      owePeople++;
    }
    if (isOpenPerson(p)) open++;
    if ((p.daysOutstanding ?? 0) > 30) over30++;
  }
  owed = _round2(owed);
  owe = _round2(owe);
  return DebtTotals(
    owedToMe: owed,
    iOwe: owe,
    net: _round2(owed - owe),
    openCount: open,
    owedToMePeople: owedPeople,
    iOwePeople: owePeople,
    over30DaysPeople: over30,
  );
}

int _nullsLast<T extends Comparable<T>>(T? a, T? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

int _byLastDesc(PersonBalance a, PersonBalance b) =>
    _nullsLast(a.lastActivityAt, b.lastActivityAt);

int _byAmountDesc(PersonBalance a, PersonBalance b) =>
    b.net.abs().compareTo(a.net.abs());

int Function(PersonBalance, PersonBalance) _comparator(DebtPeopleSort sort) {
  switch (sort) {
    case DebtPeopleSort.amount:
      return (a, b) {
        final c = _byAmountDesc(a, b);
        if (c != 0) return c;
        final l = _byLastDesc(a, b);
        return l != 0 ? l : a.key.compareTo(b.key);
      };
    case DebtPeopleSort.recent:
      return (a, b) {
        final l = _byLastDesc(a, b);
        if (l != 0) return l;
        final c = _byAmountDesc(a, b);
        return c != 0 ? c : a.key.compareTo(b.key);
      };
    case DebtPeopleSort.oldest:
      return (a, b) {
        final d = _nullsLast(a.daysOutstanding, b.daysOutstanding);
        if (d != 0) return d;
        final c = _byAmountDesc(a, b);
        if (c != 0) return c;
        final l = _byLastDesc(a, b);
        return l != 0 ? l : a.key.compareTo(b.key);
      };
  }
}

/// What `GET /personal-debts/people` answers for these parameters.
/// The debts list's filter chips (owner 2026-10-22, mock DebtsList).
enum DebtListFilter { all, receivable, payable, overdue30 }

/// How many people each chip keeps: the open people, per side, and those
/// whose oldest open debt is more than 30 days old.
Map<DebtListFilter, int> countPeople(List<PersonBalance> people) {
  final open = [
    for (final p in people)
      if (isOpenPerson(p)) p,
  ];
  return {
    DebtListFilter.all: open.length,
    DebtListFilter.receivable: open.where((p) => p.net > 0.005).length,
    DebtListFilter.payable: open.where((p) => p.net < -0.005).length,
    DebtListFilter.overdue30: open
        .where((p) => (p.daysOutstanding ?? 0) > 30)
        .length,
  };
}

List<PersonBalance> filterPeople(
  List<PersonBalance> people, {
  String q = '',
  bool all = false,
  NetSide? side,
  bool overdue30 = false,
  DebtPeopleSort sort = DebtPeopleSort.oldest,
}) {
  final needle = q.trim().toLowerCase();
  final out = [
    for (final p in people)
      if ((all || isOpenPerson(p)) &&
          (side == null || side == NetSide.even || NetSide.of(p.net) == side) &&
          (!overdue30 || (p.daysOutstanding ?? 0) > 30) &&
          (needle.isEmpty || p.person.name.toLowerCase().contains(needle)))
        p,
  ]..sort(_comparator(sort));
  return out;
}
