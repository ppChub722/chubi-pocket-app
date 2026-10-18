import 'dart:async';

import 'package:chubi_pocket/core/data/data_changes.dart';
import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/personal_debts/data/personal_debts_repository.dart';
import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/cubit/debt_directory_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/cubit/debt_people_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/cubit/debt_person_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/debt_wiring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../shared/fake_sync.dart';

class _MockClient extends Mock implements ApiClient {}

/// Records every call; answers from prod-shaped JSON (fe-debts.md §3).
class _FakeRepo extends PersonalDebtsRepository {
  _FakeRepo() : super(client: _MockClient());

  final calls = <String>[];
  Completer<void>? gate;
  Object? failNext;

  Future<void> _maybe() async {
    if (gate != null) await gate!.future;
    final f = failNext;
    if (f != null) {
      failNext = null;
      throw f;
    }
  }

  @override
  Future<DebtPersonDetail> person(
    String key, {
    int perPage = 30,
    DebtCycle cycle = DebtCycle.current,
  }) async {
    calls.add('person $key ${cycle.wire}');
    await _maybe();
    return DebtPersonDetail.fromJson({
      ..._personJson(key, 'แม่', 200),
      'counts': {'entries': 4, 'money': 1, 'current': 3, 'earlier': 1},
      'summary_message': {'text': 'สรุปยอด\nรวม 200', 'entries': 3, 'net': 200},
      'items': [
        _entryJson('e1', 'paid', 300),
        _entryJson('e2', 'received', 100),
      ],
      'pagination': {
        'page': 1,
        'per_page': perPage,
        'total': 3,
        'total_pages': 2,
      },
    });
  }

  @override
  Future<DebtEntriesPage> entries(
    String key, {
    DebtEntryQuery query = const DebtEntryQuery(),
    int page = 1,
    int perPage = 30,
    DebtCycle? cycle,
  }) async {
    calls.add(
      'entries $key p$page ${cycle?.wire} q=${query.q} '
      'sort=${query.sort.wire}',
    );
    await _maybe();
    return DebtEntriesPage.fromJson({
      'data': [_entryJson('e${page}x', 'paid', 10)],
      'pagination': {
        'page': page,
        'per_page': perPage,
        'total': 2,
        'total_pages': 2,
      },
    });
  }

  @override
  Future<DebtEntryWriteResult> setPaid(String id, bool paid) async {
    calls.add('paid $id $paid');
    return DebtEntryWriteResult.fromJson({
      'entry': {..._entryJson(id, 'paid', 300), 'paid': paid},
      'person_balance': _personJson('c:1', 'แม่', 150),
      'previous_person_balance': null,
      'transaction': null,
      'account_balances': <Object>[],
    });
  }
}

Map<String, dynamic> _personJson(String key, String name, num net) => {
  'key': key,
  'person': {
    'name': name,
    'contact_id': key.startsWith('c:') ? key.substring(2) : null,
    'icon_code': null,
    'linked': false,
    'linked_user_id': null,
  },
  'net': net,
  'open_count': 2,
  'entry_count': 3,
  'last_activity_at': '2026-10-12',
  'cleared_at': '2026-10-05',
  'days_outstanding': 6,
};

Map<String, dynamic> _entryJson(String id, String dir, num amount) => {
  'id': id,
  'direction': dir,
  'amount': amount,
  'date': '2026-10-12',
  'description': '',
  'note': null,
  'paid': false,
  'source': null,
  'transaction': {
    'id': 'tx-$id',
    'account': {
      'id': 'a1',
      'name': 'เงินสด',
      'icon_code': null,
      'logo_url': null,
      'type': 'cash',
      'group': 'asset',
      'currency': 'THB',
      'archived': false,
    },
  },
};

void main() {
  group('models', () {
    test('entry: direction + positive amount; blank description = null', () {
      final e = DebtEntry.fromJson(_entryJson('e1', 'received', -120));
      expect(e.direction, DebtEntryDirection.received);
      expect(e.amount, 120);
      expect(e.description, isNull);
      expect(e.movedMoney, isTrue);
      expect(e.transaction!.account!.name, 'เงินสด');
    });

    test('net side', () {
      expect(NetSide.of(1), NetSide.owedToMe);
      expect(NetSide.of(-1), NetSide.iOwe);
      expect(NetSide.of(0.001), NetSide.even);
    });

    test('person key', () {
      expect(debtPersonKey(contactId: 'x'), 'c:x');
      expect(debtPersonKey(name: ' Mom '), 'n:mom');
    });

    test('query: wire params', () {
      const q = DebtEntryQuery(
        q: ' rent ',
        direction: DebtEntryDirection.paid,
        paid: false,
      );
      expect(q.toQuery(), {
        'q': 'rent',
        'sort': 'date_desc',
        'direction': 'paid',
        'paid': 'false',
      });
      expect(q.isFiltered, isTrue);
      expect(const DebtEntryQuery().isFiltered, isFalse);
    });

    test('0.4.0 fields: cycle boundary, age, counts, message, people', () {
      final b = PersonBalance.fromJson(_personJson('c:1', 'แม่', 200));
      expect(b.clearedAt, DateTime.parse('2026-10-05').toLocal());
      expect(b.daysOutstanding, 6);
      final none = PersonBalance.fromJson({
        ..._personJson('c:1', 'แม่', 0),
        'cleared_at': null,
        'days_outstanding': null,
      });
      expect((none.clearedAt, none.daysOutstanding), (null, null));
      final totals = DebtTotals.fromJson({
        'owed_to_me': 5,
        'i_owe': 1,
        'net': 4,
        'owed_to_me_people': 3,
        'i_owe_people': 2,
        'over_30_days_people': 1,
      });
      expect(
        (totals.owedToMePeople, totals.iOwePeople, totals.over30DaysPeople),
        (3, 2, 1),
      );
      final e = DebtEntry.fromJson({
        ..._entryJson('e1', 'paid', 5),
        'in_current_cycle': false,
      });
      expect(e.inCurrentCycle, isFalse);
      final d = DebtPersonDetail.fromJson({
        ..._personJson('c:1', 'แม่', 200),
        'counts': {'entries': 4, 'money': 1, 'current': 3, 'earlier': 1},
        'summary_message': {'text': 'hi', 'entries': 3, 'net': 200},
        'items': <Object>[],
        'pagination': {'page': 1, 'per_page': 30, 'total': 0, 'total_pages': 1},
      });
      expect((d.counts.current, d.counts.earlier), (3, 1));
      expect(d.message.text, 'hi');
    });
  });

  group('DebtPeopleCubit (derived from the directory)', () {
    DebtDirectoryCubit directory() {
      final d = DebtDirectoryCubit(coordinator: testCoordinator());
      d.applySync({
        'data': [
          _personJson('c:c1', 'แม่', 200),
          _personJson('n:bank1', 'Bank', -50),
          {
            ..._personJson('n:old', 'Old friend', 0),
            'open_count': 0,
            'days_outstanding': null,
          },
        ],
        'totals': <String, dynamic>{},
        'pagination': {'page': 1, 'per_page': 3, 'total': 3, 'total_pages': 1},
      });
      return d;
    }

    test('it lists who is open and totals everyone, with no request', () async {
      final dir = directory();
      final c = DebtPeopleCubit(directory: dir);
      expect(c.state.status, DebtLoadStatus.loaded);
      expect(c.state.items.map((p) => p.key), ['c:c1', 'n:bank1']);
      expect(c.state.totals.owedToMe, 200);
      expect(c.state.totals.iOwe, 50);
      expect(c.state.hasMore, isFalse);
      await c.loadMore();
      await c.close();
      await dir.close();
    });

    test('search, all, side and sort apply at once', () async {
      final dir = directory();
      final c = DebtPeopleCubit(directory: dir);
      c.search('bank');
      expect(c.state.items.map((p) => p.key), ['n:bank1']);
      c.search('');
      c.showAll(true);
      expect(c.state.items.map((p) => p.key), contains('n:old'));
      c.showAll(false);
      c.toggleSide(NetSide.owedToMe);
      expect(c.state.items.map((p) => p.key), ['c:c1']);
      c.toggleSide(NetSide.owedToMe);
      expect(c.state.side, isNull);
      c.setSort(DebtPeopleSort.amount);
      expect(c.state.items.first.key, 'c:c1');
      await c.close();
      await dir.close();
    });

    test('the directory status and error come through', () async {
      final dir = DebtDirectoryCubit(coordinator: testCoordinator());
      final c = DebtPeopleCubit(directory: dir);
      expect(c.state.status, DebtLoadStatus.initial);
      dir.syncFailed(const ApiException(code: 'INTERNAL', message: 'down'));
      await Future<void>.delayed(Duration.zero);
      expect(c.state.status, DebtLoadStatus.error);
      expect(c.state.error!.message, 'down');
      await c.close();
      await dir.close();
    });

    test('a balance a write returned patches the person at once', () async {
      final dir = directory();
      final c = DebtPeopleCubit(directory: dir);
      dir.applyBalance(PersonBalance.fromJson(_personJson('c:c1', 'แม่', 0)));
      await Future<void>.delayed(Duration.zero);
      expect(dir.byKey('c:c1')!.net, 0);
      expect(c.state.totals.owedToMe, 0);
      await c.close();
      await dir.close();
    });
  });

  group('DebtPersonCubit', () {
    test(
      'open = 1 call: balance, counts, message, the current cycle',
      () async {
        final repo = _FakeRepo();
        final c = DebtPersonCubit(repository: repo, personKey: 'c:1');
        await c.load();
        expect(repo.calls, ['person c:1 current']);
        expect(c.state.balance!.net, 200);
        expect(c.state.balance!.daysOutstanding, 6);
        expect((c.state.counts.current, c.state.counts.earlier), (3, 1));
        expect(c.state.message.text, 'สรุปยอด\nรวม 200');
        expect(c.state.current.items.map((e) => e.id), ['e1', 'e2']);
        expect(c.state.current.status, DebtLoadStatus.loaded);
        expect(c.state.earlier.opened, isFalse);
        await c.close();
      },
    );

    test('earlier cycles load once, on the first open; a refresh reloads '
        'them too', () async {
      final repo = _FakeRepo();
      final c = DebtPersonCubit(repository: repo, personKey: 'c:1');
      await c.load();
      await c.openEarlier();
      await c.openEarlier();
      expect(repo.calls, [
        'person c:1 current',
        'entries c:1 p1 earlier q= sort=date_desc',
      ]);
      expect(c.state.earlier.items.map((e) => e.id), ['e1x']);
      await c.load();
      expect(repo.calls.last, 'entries c:1 p1 earlier q= sort=date_desc');
      await c.close();
    });

    test('sort = one call for the current cycle; load more appends', () async {
      final repo = _FakeRepo();
      final c = DebtPersonCubit(repository: repo, personKey: 'c:1');
      await c.load();
      c.setQuery(c.state.query.copyWith(sort: DebtEntrySort.amountDesc));
      await Future<void>.delayed(Duration.zero);
      await c.loadMore();
      expect(repo.calls.skip(1), [
        'entries c:1 p1 current q= sort=amount_desc',
        'entries c:1 p2 current q= sort=amount_desc',
      ]);
      expect(c.state.current.items.map((e) => e.id), ['e1x', 'e2x']);
      await c.close();
    });

    test(
      'load more goes on to the earlier cycles once those are open',
      () async {
        final repo = _FakeRepo();
        final c = DebtPersonCubit(repository: repo, personKey: 'c:1');
        await c.load();
        await c.openEarlier();
        repo.calls.clear();
        // The current cycle still has page 2 (the fake says 2 pages).
        await c.loadMore();
        expect(repo.calls, ['entries c:1 p2 current q= sort=date_desc']);
        await c.close();
      },
    );

    test(
      'setPaid patches the row + hero, then re-runs the page call',
      () async {
        final repo = _FakeRepo();
        final c = DebtPersonCubit(repository: repo, personKey: 'c:1');
        await c.load();
        await c.setPaid('e1', true);
        expect(c.state.current.items.first.paid, isTrue);
        expect(c.state.balance!.net, 150);
        await Future<void>.delayed(Duration.zero);
        expect(repo.calls, [
          'person c:1 current',
          'paid e1 true',
          'person c:1 current',
        ]);
        await c.close();
      },
    );

    test(
      'a debts change re-runs the page call without a loading flash',
      () async {
        final repo = _FakeRepo();
        final c = DebtPersonCubit(repository: repo, personKey: 'c:1');
        await c.load();
        repo.calls.clear();
        final states = <DebtLoadStatus>[];
        final sub = c.stream.listen((s) => states.add(s.status));
        await DataChanges.instance.changed({DataTable.debts});
        await Future<void>.delayed(Duration.zero);
        expect(repo.calls, ['person c:1 current']);
        expect(states, everyElement(DebtLoadStatus.loaded));
        await sub.cancel();
        await c.close();
      },
    );

    test('debtDirectionFor: the balance picks the + direction', () {
      expect(debtDirectionFor(120), DebtEntryDirection.received);
      expect(debtDirectionFor(-40), DebtEntryDirection.paid);
      expect(debtDirectionFor(0), isNull);
      expect(debtDirectionFor(null), isNull);
    });

    test(
      'a failed reload keeps the statement; a failed open → error',
      () async {
        final repo = _FakeRepo();
        final c = DebtPersonCubit(repository: repo, personKey: 'c:1');
        await c.load();
        repo.failNext = const ApiException(
          code: 'INTERNAL',
          message: 'down',
          statusCode: 500,
        );
        await c.load();
        expect(c.state.status, DebtLoadStatus.error);
        expect(c.state.balance, isNotNull);
        expect(c.state.current.items, hasLength(2));
        await c.close();

        final gone = DebtPersonCubit(
          repository: _FakeRepo()
            ..failNext = const ApiException(
              code: 'NOT_FOUND',
              message: 'x',
              statusCode: 404,
            ),
          personKey: 'n:gone',
        );
        await gone.load();
        expect(gone.state.status, DebtLoadStatus.error);
        expect(gone.state.firstLoad, isFalse);
        expect(gone.state.balance, isNull);
        await gone.close();
      },
    );
  });
}
