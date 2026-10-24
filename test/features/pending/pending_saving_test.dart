import 'package:chubi_pocket/features/pending/data/pending_repository.dart';
import 'package:chubi_pocket/features/pending/domain/pending_transaction.dart';
import 'package:chubi_pocket/features/pending/presentation/cubit/pending_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _saving(
  String id, {
  bool goal = true,
  bool wallet = true,
}) => {
  'id': id,
  'source': 'recurring',
  'kind': 'saving',
  'draft': {
    'type': 'saving',
    'amount': 4000,
    'account_id': wallet ? 'a1' : null,
    'goal_id': goal ? 'g1' : null,
    'date': '2026-10-13',
    'note': null,
  },
  'resolved': {
    'account': wallet
        ? {
            'id': 'a1',
            'name': 'KBank',
            'icon_code': null,
            'logo_url': null,
            'type': 'bank',
            'group': 'asset',
            'currency': 'THB',
            'archived': false,
          }
        : null,
    'transfer_to_account': null,
    'category': null,
    'tags': [],
    'project': null,
    'splits': [],
    'goal': goal ? {'id': 'g1', 'name': 'Japan trip', 'icon_code': null} : null,
    'missing': [],
  },
  'target_debt_id': null,
  'target_transaction_id': null,
  'source_ref': {
    'item_id': 'i1',
    'recurring': {'id': 'r1', 'name': 'Save monthly', 'icon_code': null},
    'seq': 2,
    'total': 12,
  },
  'last_error': null,
  'created_at': '2026-10-13T08:00:00Z',
  'updated_at': '2026-10-13T08:00:00Z',
};

class _Repo implements PendingRepository {
  _Repo(this.rows);
  final List<PendingTransaction> rows;
  List<String>? submitted;

  @override
  Future<PendingList> list() async => PendingList(items: rows);

  @override
  Future<PendingSubmitResult> submit(List<String> ids) async {
    submitted = ids;
    return PendingSubmitResult.fromJson({
      'submitted': [
        for (final id in ids)
          {'id': id, 'saving_entry_id': 's-$id', 'rows': []},
      ],
      'failed': [],
      'account_balances': {},
      'badges': {'pending_drafts': 0},
    });
  }

  @override
  dynamic noSuchMethod(Invocation i) => super.noSuchMethod(i);
}

void main() {
  test('parses a saving draft with resolved.goal', () {
    final p = PendingTransaction.fromJson(_saving('p1'));
    expect(p.kind, PendingKind.saving);
    expect(p.isSaving, isTrue);
    expect(p.draft.type, isNull);
    expect(p.draft.goalId, 'g1');
    expect(p.draft.amount, 4000);
    expect(p.resolved.goal?.name, 'Japan trip');
    expect(p.resolved.account?.name, 'KBank');
    expect(p.draft.toJson()['type'], 'saving');
    final spare = PendingTransaction.fromJson(_saving('p2', goal: false));
    expect(spare.draft.goalId, isNull);
    expect(spare.resolved.goal, isNull);
  });

  test('submit removes the saving row via the existing endpoint', () async {
    final repo = _Repo([
      PendingTransaction.fromJson(_saving('p1')),
      PendingTransaction.fromJson(_saving('p2', goal: false)),
    ]);
    final cubit = PendingCubit(repository: repo);
    await cubit.load();
    final r = await cubit.submit(['p1']);
    expect(repo.submitted, ['p1']);
    expect(r.submitted, ['p1']);
    expect(cubit.state.items.map((e) => e.id), ['p2']);
    await cubit.close();
  });
}
