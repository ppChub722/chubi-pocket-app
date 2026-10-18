import 'dart:io';

import 'package:chubi_pocket/core/data/sync_set.dart';
import 'package:chubi_pocket/core/data/sync_store.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory dir;
  late SyncStore store;

  SyncEntry entry(String v) =>
      SyncEntry(v: v, body: {'v': v}, savedAt: DateTime.utc(2026, 10, 18));

  setUp(() async {
    dir = await Directory.systemTemp.createTemp('sync_store_test');
    store = SyncStore(root: () async => Directory('${dir.path}/sync'));
  });

  tearDown(() => dir.delete(recursive: true));

  test('keeps one file per dataset under the user folder', () async {
    await store.write('u1', SyncSet.tags, entry('t1'));
    await store.write('u1', SyncSet.debtPeople, entry('d1'));

    expect(File('${dir.path}/sync/u1/tags.json').existsSync(), isTrue);
    expect(File('${dir.path}/sync/u1/debt_people.json').existsSync(), isTrue);
    final read = await store.readAll('u1');
    expect(read.keys.toSet(), {SyncSet.tags, SyncSet.debtPeople});
    expect(read[SyncSet.tags]!.body, {'v': 't1'});
    expect(read[SyncSet.tags]!.savedAt, DateTime.utc(2026, 10, 18));
  });

  test('a damaged file is a dataset the device does not hold', () async {
    await store.write('u1', SyncSet.tags, entry('t1'));
    await File('${dir.path}/sync/u1/contacts.json').writeAsString('{not json');
    final read = await store.readAll('u1');
    expect(read.keys, [SyncSet.tags]);
  });

  test('clear deletes one user, clearOthers keeps one', () async {
    await store.write('u1', SyncSet.tags, entry('a'));
    await store.write('u2', SyncSet.tags, entry('b'));
    await store.write('u3', SyncSet.tags, entry('c'));

    await store.clear('u1');
    expect(await store.readAll('u1'), isEmpty);
    expect(await store.readAll('u2'), isNotEmpty);

    await store.clearOthers('u3');
    expect(await store.readAll('u2'), isEmpty);
    expect(await store.readAll('u3'), isNotEmpty);
  });
}
