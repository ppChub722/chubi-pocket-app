import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/archived/cubit/archived_cubit.dart';
import 'package:chubi_pocket/features/archived/data/archived_repository.dart';
import 'package:chubi_pocket/features/archived/domain/archived_hub.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _item(
  String id,
  String name, {
  bool? canRestore,
  Map<String, dynamic>? secondary,
}) => {
  'id': id,
  'name': name,
  'icon_code': null,
  'archived_at': '2026-10-01T08:30:00Z',
  'can_restore': ?canRestore,
  'secondary': secondary,
};

Map<String, dynamic> _group(List<Map<String, dynamic>> items) => {
  'count': items.length,
  'items': items,
};

/// Prod-shaped: five groups filled, one (contacts) empty.
final _json = {
  'total': 6,
  'wallets': _group([_item('w1', 'บัญชีเก่า')]),
  'budgets': _group([_item('b1', 'งบกาแฟ')]),
  'goals': _group([_item('g1', 'ซื้อรถ'), _item('g2', 'ทริปญี่ปุ่น')]),
  'events': _group([_item('e1', 'งานเลี้ยง')]),
  'contacts': _group([]),
  'recurring': _group([_item('r1', 'ค่าเน็ต')]),
};

class _Fake extends Fake implements ArchivedRepository {
  bool failRestore = false;
  int fetches = 0;
  final restores = <String>[];

  @override
  Future<ArchivedHub> fetch() async {
    fetches++;
    return ArchivedHub.fromJson(_json);
  }

  @override
  Future<void> restore(ArchivedKind kind, String id) async {
    if (failRestore) {
      throw const ApiException(code: 'X', message: 'boom', statusCode: 500);
    }
    restores.add('${kind.key}:$id');
  }
}

void main() {
  test('hub parse: empty group, can_restore flag, secondary line', () {
    final hub = ArchivedHub.fromJson({
      ..._json,
      'wallets': _group([
        _item(
          'w1',
          'shared',
          canRestore: false,
          secondary: {'kind': 'balance', 'amount': 1250.5},
        ),
      ]),
      'budgets': _group([
        _item(
          'b1',
          'coffee',
          canRestore: true,
          secondary: {'kind': 'limit', 'amount': 3000},
        ),
      ]),
      'goals': _group([
        _item('g1', 'car', secondary: {'kind': 'target', 'amount': 4000}),
        _item('g2', 'trip', secondary: {'kind': 'target'}),
      ]),
    });

    expect(hub.of(ArchivedKind.contacts), isEmpty);
    expect(hub.of(ArchivedKind.wallets).single.canRestore, isFalse);
    expect(hub.of(ArchivedKind.budgets).single.canRestore, isTrue);
    final goals = hub.of(ArchivedKind.goals);
    expect(goals.first.canRestore, isTrue);
    expect(goals.first.secondary!.kind, ArchivedSecondaryKind.target);
    expect(goals.first.secondary!.amount, 4000);
    expect(goals.last.secondary, isNull);
    expect(hub.of(ArchivedKind.wallets).single.secondary!.amount, 1250.5);
  });

  test('restore: one call, the row leaves, no re-fetch', () async {
    final repo = _Fake();
    final cubit = ArchivedCubit(repository: repo);
    addTearDown(cubit.close);
    await cubit.load();
    expect(cubit.state.hub!.total, 6);

    expect(await cubit.restore(ArchivedKind.goals, 'g1'), isNull);

    expect(repo.restores, ['goals:g1']);
    expect(repo.fetches, 1);
    final hub = cubit.state.hub!;
    expect([for (final i in hub.of(ArchivedKind.goals)) i.id], ['g2']);
    expect(hub.total, 5);
    expect(cubit.state.busy, isEmpty);

    repo.failRestore = true;
    final error = await cubit.restore(ArchivedKind.wallets, 'w1');
    expect(error?.code, 'X');
    expect(cubit.state.hub!.of(ArchivedKind.wallets), hasLength(1));
    expect(cubit.state.busy, isEmpty);
  });
}
