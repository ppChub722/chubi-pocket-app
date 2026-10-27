import 'package:chubi_pocket/features/personal_debts/domain/debt_directory.dart';
import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:chubi_pocket/features/transactions/domain/refs.dart';
import 'package:flutter_test/flutter_test.dart';

PersonBalance _p(
  String key,
  double net, {
  String? name,
  int open = 0,
  int? days,
  DateTime? last,
}) => PersonBalance(
  key: key,
  person: EmbeddedPerson(name: name ?? key),
  net: net,
  openCount: open,
  daysOutstanding: days,
  lastActivityAt: last,
);

void main() {
  final people = [
    _p(
      'n:ann',
      120.5,
      name: 'Ann',
      open: 2,
      days: 10,
      last: DateTime(2026, 10, 1),
    ),
    _p(
      'n:bob',
      -40,
      name: 'Bob',
      open: 1,
      days: 45,
      last: DateTime(2026, 9, 1),
    ),
    _p('n:cat', 0, name: 'Cat', open: 0, last: DateTime(2026, 10, 10)),
    _p('n:dan', 0, name: 'Dan', open: 1, days: 3, last: DateTime(2026, 10, 12)),
    _p('n:eve', 60, name: 'Eve', open: 1, days: 45),
  ];

  List<String> keys(List<PersonBalance> l) => [for (final p in l) p.key];

  test('settled people are hidden unless all; open means net or an open entry; '
      'search is a case-insensitive substring', () {
    expect(keys(filterPeople(people)), isNot(contains('n:cat')));
    expect(keys(filterPeople(people)), contains('n:dan'));
    expect(keys(filterPeople(people, all: true)), contains('n:cat'));
    expect(keys(filterPeople(people, all: true, q: ' A')), [
      'n:ann',
      'n:dan',
      'n:cat',
    ]);
    expect(keys(filterPeople(people, all: true, q: 'EVE')), ['n:eve']);
  });

  test('side filters on the net with the 0.005 margin', () {
    expect(keys(filterPeople(people, side: NetSide.owedToMe)), [
      'n:eve',
      'n:ann',
    ]);
    expect(keys(filterPeople(people, side: NetSide.iOwe)), ['n:bob']);
    expect(
      keys(filterPeople([_p('n:z', 0.004, open: 1)], side: NetSide.owedToMe)),
      isEmpty,
    );
  });

  test('sorts', () {
    for (final c in [
      (
        name:
            'oldest: days outstanding desc (none last), then amount, then last',
        sort: DebtPeopleSort.oldest,
        want: ['n:eve', 'n:bob', 'n:ann', 'n:dan', 'n:cat'],
      ),
      (
        name: 'amount: |net| desc, then last desc (none last), then key',
        sort: DebtPeopleSort.amount,
        want: ['n:ann', 'n:eve', 'n:bob', 'n:dan', 'n:cat'],
      ),
      (
        name: 'recent: last desc (none last), then |net| desc',
        sort: DebtPeopleSort.recent,
        want: ['n:dan', 'n:cat', 'n:ann', 'n:bob', 'n:eve'],
      ),
    ]) {
      expect(
        keys(filterPeople(people, all: true, sort: c.sort)),
        c.want,
        reason: c.name,
      );
    }
  });

  test('totals cover everyone, however the list is filtered', () {
    final t = debtTotalsOf(people);
    expect(t.owedToMe, 180.5);
    expect(t.iOwe, 40);
    expect(t.net, 140.5);
    expect(t.openCount, 4);
    expect(t.owedToMePeople, 2);
    expect(t.iOwePeople, 1);
    expect(t.over30DaysPeople, 2);
  });

  test('totals round to cents', () {
    expect(
      debtTotalsOf([_p('a', 0.1, open: 1), _p('b', 0.2, open: 1)]).owedToMe,
      0.3,
    );
  });
}
