import 'dart:async';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/personal_debts/data/personal_debts_repository.dart';
import 'package:chubi_pocket/features/personal_debts/domain/debt_ledger.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/cubit/debt_book.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/cubit/debt_people_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/cubit/debt_person_cubit.dart';
import 'package:chubi_pocket/features/personal_debts/presentation/debt_wiring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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
  Future<DebtPeoplePage> listPeople({
    int page = 1,
    int perPage = 30,
    String? q,
    bool all = false,
    NetSide? side,
  }) async {
    calls.add('people p$page q=${q ?? ''} all=$all side=${side?.wire}');
    await _maybe();
    return DebtPeoplePage.fromJson({
      'data': [
        _personJson('c:c$page', 'แม่ $page', 200),
        _personJson('n:bank$page', 'Bank $page', -50),
      ],
      'totals': {'owed_to_me': 200, 'i_owe': 50, 'net': 150},
      'pagination': {
        'page': page,
        'per_page': perPage,
        'total': 4,
        'total_pages': 2,
      },
    });
  }

  @override
  Future<DebtPersonDetail> person(String key, {int perPage = 30}) async {
    calls.add('person $key');
    await _maybe();
    return DebtPersonDetail.fromJson({
      ..._personJson(key, 'แม่', 200),
      'counts': {'entries': 3, 'money': 1},
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
  }) async {
    calls.add(
      'entries $key p$page money=${query.moneyOnly} q=${query.q} '
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
        moneyOnly: true,
      );
      expect(q.toQuery(), {
        'q': 'rent',
        'sort': 'date_desc',
        'direction': 'paid',
        'paid': 'false',
        'money': 'true',
      });
      expect(q.isFiltered, isTrue);
      expect(const DebtEntryQuery(moneyOnly: true).isFiltered, isFalse);
    });
  });

  group('DebtPeopleCubit', () {
    test('open = 1 call; load more appends page 2', () async {
      final repo = _FakeRepo();
      final c = DebtPeopleCubit(repository: repo);
      await c.load();
      expect(c.state.status, DebtLoadStatus.loaded);
      expect(c.state.items.map((p) => p.key), ['c:c1', 'n:bank1']);
      expect(c.state.totals.net, 150);
      expect(c.state.hasMore, isTrue);
      await c.loadMore();
      expect(c.state.items, hasLength(4));
      expect(c.state.hasMore, isFalse);
      expect(repo.calls, [
        'people p1 q= all=false side=null',
        'people p2 q= all=false side=null',
      ]);
      await c.close();
    });

    test('search is debounced into one call', () async {
      final repo = _FakeRepo();
      final c = DebtPeopleCubit(repository: repo, debounce: Duration.zero);
      c.search('แ');
      c.search('แม่');
      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(repo.calls, ['people p1 q=แม่ all=false side=null']);
      await c.close();
    });

    test('side toggles on / off; ทั้งหมด sends all', () async {
      final repo = _FakeRepo();
      final c = DebtPeopleCubit(repository: repo);
      c.toggleSide(NetSide.owedToMe);
      await Future<void>.delayed(Duration.zero);
      c.toggleSide(NetSide.owedToMe);
      await Future<void>.delayed(Duration.zero);
      c.showAll(true);
      await Future<void>.delayed(Duration.zero);
      expect(repo.calls, [
        'people p1 q= all=false side=owed_to_me',
        'people p1 q= all=false side=null',
        'people p1 q= all=true side=null',
      ]);
      await c.close();
    });

    test('a failed first load → error; a stale response is dropped', () async {
      final repo = _FakeRepo()
        ..failNext = const ApiException(
          code: 'INTERNAL',
          message: 'down',
          statusCode: 500,
        );
      final c = DebtPeopleCubit(repository: repo);
      await c.load();
      expect(c.state.status, DebtLoadStatus.error);
      expect(c.state.error!.message, 'down');

      // An older search answers after a newer one: it's dropped.
      final slow = Completer<void>();
      repo.gate = slow;
      c.search('old');
      final first = c.load();
      repo.gate = null;
      c.search('new');
      await c.load();
      expect(c.state.status, DebtLoadStatus.loaded);
      final before = c.state;
      slow.complete();
      await first;
      expect(c.state, before);
      expect(c.state.q, 'new');
      await c.close();
    });

    test('applyBalance patches the row in place', () async {
      final c = DebtPeopleCubit(repository: _FakeRepo());
      await c.load();
      c.applyBalance(PersonBalance.fromJson(_personJson('c:c1', 'แม่', 0)));
      expect(c.state.items.first.net, 0);
      await c.close();
    });
  });

  group('DebtPersonCubit', () {
    test('open = 1 call with the embedded timeline', () async {
      final repo = _FakeRepo();
      final c = DebtPersonCubit(repository: repo, personKey: 'c:1');
      await c.load();
      expect(repo.calls, ['person c:1']);
      expect(c.state.balance!.net, 200);
      expect(c.state.entryCount, 3);
      expect(c.state.entries.items.map((e) => e.id), ['e1', 'e2']);
      expect(c.state.entries.status, DebtLoadStatus.loaded);
      expect(c.state.money.status, DebtLoadStatus.initial);
      await c.close();
    });

    test('money tab loads once, on its first open', () async {
      final repo = _FakeRepo();
      final c = DebtPersonCubit(repository: repo, personKey: 'c:1');
      await c.load();
      await c.openTab(DebtPersonTab.money);
      await c.openTab(DebtPersonTab.money);
      expect(repo.calls, [
        'person c:1',
        'entries c:1 p1 money=true q= sort=date_desc',
      ]);
      // A refresh now reloads the opened money tab too.
      await c.load();
      expect(repo.calls.last, 'entries c:1 p1 money=true q= sort=date_desc');
      await c.close();
    });

    test('sort = one call; load more appends', () async {
      final repo = _FakeRepo();
      final c = DebtPersonCubit(repository: repo, personKey: 'c:1');
      await c.load();
      c.setQuery(
        DebtPersonTab.entries,
        c.state.entries.query.copyWith(sort: DebtEntrySort.amountDesc),
      );
      await Future<void>.delayed(Duration.zero);
      await c.loadMore(DebtPersonTab.entries);
      expect(repo.calls.skip(1), [
        'entries c:1 p1 money=false q= sort=amount_desc',
        'entries c:1 p2 money=false q= sort=amount_desc',
      ]);
      expect(c.state.entries.items.map((e) => e.id), ['e1x', 'e2x']);
      await c.close();
    });

    test('setPaid patches the entry + the hero from the response', () async {
      final repo = _FakeRepo();
      final c = DebtPersonCubit(repository: repo, personKey: 'c:1');
      await c.load();
      await c.setPaid('e1', true);
      expect(c.state.entries.items.first.paid, isTrue);
      expect(c.state.balance!.net, 150);
      expect(repo.calls, ['person c:1', 'paid e1 true']);
      await c.close();
    });

    DebtEntryWriteResult saved(String id, String date, {int openCount = 3}) =>
        DebtEntryWriteResult.fromJson({
          'entry': {..._entryJson(id, 'received', 50), 'date': date},
          'person_balance': {
            ..._personJson('c:1', 'แม่', 150),
            'open_count': openCount,
          },
          'previous_person_balance': null,
          'transaction': null,
          'account_balances': <Object>[],
        });

    test('addEntry: hero + counts patch; the entry joins in date order, '
        'no call', () async {
      final repo = _FakeRepo();
      final c = DebtPersonCubit(repository: repo, personKey: 'c:1');
      await c.load();
      c.addEntry(saved('new', '2026-10-13'));
      expect(c.state.balance!.net, 150);
      expect(c.state.entryCount, 4);
      expect(c.state.moneyCount, 2);
      expect(c.state.entries.items.first.id, 'new');
      // Older than every loaded row, more pages to come: a later page.
      c.addEntry(saved('old', '2020-01-01', openCount: 4));
      expect(c.state.entries.items.any((e) => e.id == 'old'), isFalse);
      expect(repo.calls, ['person c:1']);
      await c.close();
    });

    test('addEntry: other entries labelled paid → the list re-runs', () async {
      final repo = _FakeRepo();
      final c = DebtPersonCubit(repository: repo, personKey: 'c:1');
      await c.load();
      // open was 2; +1 unpaid entry would be 3 — 1 means 2 got labelled.
      c.addEntry(saved('new', '2026-10-13', openCount: 1));
      await Future<void>.delayed(Duration.zero);
      expect(repo.calls.last, 'entries c:1 p1 money=false q= sort=date_desc');
      await c.close();
    });

    test('DebtBook.entrySaved reaches the people list and the open person '
        'page', () async {
      final repo = _FakeRepo();
      final people = DebtPeopleCubit(repository: repo);
      final person = DebtPersonCubit(repository: repo, personKey: 'c:1');
      await people.load();
      await person.load();
      repo.calls.clear();
      DebtBook.entrySaved(saved('new', '2026-10-13'));
      await Future<void>.delayed(Duration.zero);
      // Person page: patched, no call. People list: row patched + 1 reload
      // (totals and new people come from the server).
      expect(person.state.balance!.net, 150);
      expect(person.state.entries.items.first.id, 'new');
      expect(repo.calls, ['people p1 q= all=false side=null']);
      await people.close();
      await person.close();
      // Closed cubits are detached: no call, no throw.
      DebtBook.entrySaved(saved('later', '2026-10-14'));
      expect(repo.calls.length, 1);
    });

    test('debtDirectionFor: the balance picks the + direction', () {
      expect(debtDirectionFor(120), DebtEntryDirection.received);
      expect(debtDirectionFor(-40), DebtEntryDirection.paid);
      expect(debtDirectionFor(0), isNull);
      expect(debtDirectionFor(null), isNull);
    });

    test('addEntry for another person is ignored', () async {
      final c = DebtPersonCubit(repository: _FakeRepo(), personKey: 'n:x');
      await c.load();
      final before = c.state;
      c.addEntry(saved('new', '2026-10-13'));
      expect(c.state, before);
      await c.close();
    });

    test('a failed open → page error', () async {
      final repo = _FakeRepo()
        ..failNext = const ApiException(
          code: 'NOT_FOUND',
          message: 'x',
          statusCode: 404,
        );
      final c = DebtPersonCubit(repository: repo, personKey: 'n:gone');
      await c.load();
      expect(c.state.status, DebtLoadStatus.error);
      expect(c.state.firstLoad, isFalse);
      expect(c.state.balance, isNull);
      await c.close();
    });
  });
}
