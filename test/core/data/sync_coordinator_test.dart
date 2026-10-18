import 'dart:async';
import 'dart:io';

import 'package:chubi_pocket/core/data/sync_coordinator.dart';
import 'package:chubi_pocket/core/data/sync_repository.dart';
import 'package:chubi_pocket/core/data/sync_set.dart';
import 'package:chubi_pocket/core/data/sync_store.dart';
import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

class _Call {
  _Call(this.want, this.have);
  final Set<SyncSet>? want;
  final Map<SyncSet, String> have;
  final done = Completer<SyncResult>();
}

class _FakeRepo implements SyncRepository {
  final calls = <_Call>[];
  Future<SyncResult> Function(_Call call)? answer;

  @override
  Future<SyncResult> sync({
    Set<SyncSet>? want,
    Map<SyncSet, String> have = const {},
  }) {
    final call = _Call(want, have);
    calls.add(call);
    final a = answer;
    if (a != null) return a(call);
    return call.done.future;
  }
}

SyncResult _result({
  Map<SyncSet, String> data = const {},
  Set<SyncSet> unchanged = const {},
  Map<String, String> versions = const {},
  Map<SyncSet, String> errors = const {},
}) => SyncResult(
  syncedAt: DateTime.utc(2026, 10, 18),
  versions: versions,
  data: {
    for (final e in data.entries)
      e.key: SyncPayload(v: e.value, body: {'v': e.value}),
  },
  unchanged: unchanged,
  errors: {
    for (final e in errors.entries)
      e.key: SyncError(code: e.value, message: e.value),
  },
);

void main() {
  late Directory dir;
  late SyncStore store;
  late _FakeRepo repo;
  late SyncCoordinator coordinator;

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sync_test');
    store = SyncStore(root: () async => Directory('${dir.path}/sync'));
    repo = _FakeRepo();
    coordinator = SyncCoordinator(
      repository: repo,
      store: store,
      debounce: const Duration(milliseconds: 10),
    );
  });

  tearDown(() async {
    coordinator.dispose();
    await dir.delete(recursive: true);
  });

  Future<void> settle() =>
      Future<void>.delayed(const Duration(milliseconds: 60));

  test(
    'hydrate hands the device data to caches, attached before or after',
    () async {
      await store.write(
        'u1',
        SyncSet.tags,
        SyncEntry(v: 'v1', body: {'data': 1}, savedAt: DateTime.utc(2026)),
      );
      final early = <Map<String, dynamic>>[];
      coordinator.attach(SyncSet.tags, early.add);

      await coordinator.hydrate('u1');
      expect(early.single, {'data': 1});

      final late = <Map<String, dynamic>>[];
      coordinator.attach(SyncSet.tags, late.add);
      expect(late.single, {'data': 1});
      expect(coordinator.held[SyncSet.tags], 'v1');
      expect(coordinator.hasAllData, isFalse);
    },
  );

  test(
    'sync sends the held versions, applies and saves only what came back',
    () async {
      final tags = <Map<String, dynamic>>[];
      final accounts = <Map<String, dynamic>>[];
      coordinator.attach(SyncSet.tags, tags.add);
      coordinator.attach(SyncSet.accounts, accounts.add);
      await store.write(
        'u1',
        SyncSet.accounts,
        SyncEntry(v: 'a1', body: {'old': true}, savedAt: DateTime.utc(2026)),
      );
      await coordinator.hydrate('u1');
      accounts.clear();

      final done = coordinator.sync({SyncSet.tags, SyncSet.accounts});
      await settle();
      expect(repo.calls.single.have, {SyncSet.accounts: 'a1'});
      repo.calls.single.done.complete(
        _result(
          data: {SyncSet.tags: 't2'},
          unchanged: {SyncSet.accounts},
          versions: {'tags': 't2', 'accounts': 'a1'},
        ),
      );

      expect(await done, isTrue);
      expect(tags.single, {'v': 't2'});
      expect(accounts, isEmpty);
      expect(coordinator.held[SyncSet.tags], 't2');
      await settle();
      final saved = await store.readAll('u1');
      expect(saved[SyncSet.tags]?.v, 't2');
    },
  );

  test(
    'calls made during a sync wait and go out together as one next round',
    () async {
      coordinator.attach(SyncSet.tags, (_) {});
      await coordinator.hydrate('u1');

      final first = coordinator.sync({SyncSet.tags});
      await settle();
      final second = coordinator.sync({SyncSet.contacts});
      final third = coordinator.sync({SyncSet.projects});
      await settle();
      expect(repo.calls, hasLength(1));

      repo.calls.first.done.complete(_result());
      await settle();
      expect(repo.calls, hasLength(2));
      expect(repo.calls.last.want, {SyncSet.contacts, SyncSet.projects});
      repo.calls.last.done.complete(_result());

      expect(await Future.wait([first, second, third]), [true, true, true]);
    },
  );

  test(
    'a dataset in errors keeps the old data and reports to its cache',
    () async {
      final failures = <SyncError>[];
      final bodies = <Map<String, dynamic>>[];
      coordinator.attach(SyncSet.tags, bodies.add, onError: failures.add);
      await coordinator.hydrate('u1');
      repo.answer = (_) async =>
          _result(errors: {SyncSet.tags: 'INTERNAL_ERROR'});

      expect(await coordinator.sync({SyncSet.tags}), isFalse);
      expect(failures.single.code, 'INTERNAL_ERROR');
      expect(bodies, isEmpty);
    },
  );

  test(
    'a header that moves a dataset re-syncs just that dataset, debounced',
    () async {
      await coordinator.hydrate('u1');
      repo.answer = (_) async => _result();
      coordinator.onVersions({'accounts': 'a2', 'tags': 't2'});
      coordinator.onVersions({'accounts': 'a2', 'contacts': 'c2'});
      await settle();

      expect(repo.calls, hasLength(1));
      expect(repo.calls.single.want, {
        SyncSet.accounts,
        SyncSet.tags,
        SyncSet.contacts,
      });
    },
  );

  test(
    'page-data keys fire only after a baseline and only when they move',
    () async {
      await coordinator.hydrate('u1');
      final fired = <Set<SyncKey>>[];
      coordinator.onPageDataChanged = fired.add;
      repo.answer = (_) async => _result();

      coordinator.onVersions({'transactions': 'x1', 'pending': 'p1'});
      expect(fired, isEmpty);
      coordinator.onVersions({'transactions': 'x1', 'pending': 'p2'});
      expect(fired.single, {SyncKey.pending});
      coordinator.onVersions({'transactions': 'x2', 'pending': 'p2'});
      expect(fired.last, {SyncKey.transactions});
    },
  );

  test(
    'clear wipes the device and ignores a response that arrives later',
    () async {
      final bodies = <Map<String, dynamic>>[];
      coordinator.attach(SyncSet.tags, bodies.add);
      await coordinator.hydrate('u1');
      final pending = coordinator.sync({SyncSet.tags});
      await settle();

      await coordinator.clear();
      repo.calls.single.done.complete(_result(data: {SyncSet.tags: 't9'}));

      expect(await pending, isFalse);
      expect(bodies, isEmpty);
      expect(coordinator.hasData(SyncSet.tags), isFalse);
      expect(await store.readAll('u1'), isEmpty);
    },
  );

  test('hydrate removes the data another account left behind', () async {
    await store.write(
      'old',
      SyncSet.tags,
      SyncEntry(v: 'x', body: const {}, savedAt: DateTime.utc(2026)),
    );
    await coordinator.hydrate('u1');
    expect(await store.readAll('old'), isEmpty);
  });

  test('parseSyncVersions reads name=version pairs and skips junk', () {
    expect(parseSyncVersions('accounts=17-3.20261018;tags=5-1;;junk;=x'), {
      'accounts': '17-3.20261018',
      'tags': '5-1',
    });
  });
}
