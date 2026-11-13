import 'package:chubi_pocket/features/projects/data/projects_repository.dart';
import 'package:chubi_pocket/features/projects/domain/paper.dart';
import 'package:chubi_pocket/features/projects/domain/project.dart';
import 'package:chubi_pocket/features/transactions/data/transactions_repository.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/event_pick.dart';
import 'package:chubi_pocket/ui/ui.dart';
import 'package:flutter_test/flutter_test.dart';

const _project = Project(
  id: 'p2',
  ownerUserId: 'u1',
  name: 'Trip',
  status: ProjectStatus.active,
);

class _Detail extends Fake implements ProjectDetail {
  @override
  Project get project => const Project(
    id: 'p9',
    ownerUserId: 'u1',
    name: 'New',
    status: ProjectStatus.active,
  );
}

class _Saved extends Fake implements TransactionWriteResult {}

/// Records the event calls.
class _Repo extends Fake implements ProjectsRepository {
  final calls = <String>[];

  @override
  Future<void> unlinkMyTransaction(String txId) async {
    calls.add('unlink $txId');
  }

  @override
  Future<PaperWriteResult> movePaper(
    String paperId, {
    String? fromProjectId,
    String? toProjectId,
  }) async {
    calls.add('move $paperId $fromProjectId→$toProjectId');
    return PaperWriteResult(paperId: paperId, personIds: const []);
  }

  @override
  Future<ProjectDetail> create({
    required String name,
    String? description,
    String? note,
    String? startDate,
    String? endDate,
    double? plannedAmount,
    List<String> tagIds = const [],
    PpForgeIconCode? iconCode,
  }) async {
    calls.add('create $name');
    return _Detail();
  }
}

class _TxRepo extends Fake implements TransactionsRepository {
  _TxRepo(this.calls);
  final List<String> calls;

  @override
  Future<TransactionWriteResult> update({
    required String id,
    double? amount,
    String? date,
    String? categoryId,
    bool clearCategory = false,
    String? note,
    bool clearNote = false,
    String? description,
    bool clearDescription = false,
    String? accountId,
    bool clearAccount = false,
    String? transferToAccountId,
    List<String>? tagIds,
    bool? alsoUpdateLink,
    Map<String, dynamic>? link,
    String? privateNote,
  }) async {
    final e = link!['event'] as Map;
    calls.add('join $id ${link['link_mode']} ${e['project_id']}');
    return _Saved();
  }
}

void main() {
  test('applyEventChange: which BE call each change makes', () async {
    final cases =
        <
          ({
            String name,
            String? current,
            EventTarget change,
            List<String> calls,
            String? bill,
          })
        >[
          (
            name: 'not in a bill → existing: my tx joins (I paid)',
            current: null,
            change: const ExistingEventTarget(_project),
            calls: ['join t1 event p2'],
            bill: null,
          ),
          (
            name: 'not in a bill → new: the event first, then join',
            current: null,
            change: const NewEventTarget('New'),
            calls: ['create New', 'join t1 event p9'],
            bill: null,
          ),
          (
            name: 'in a bill, A → B: the bill moves',
            current: 'p1',
            change: const ExistingEventTarget(_project),
            calls: ['move b1 p1→p2'],
            bill: 'b1',
          ),
          (
            name: 'in a bill, A → new: the bill moves into it',
            current: 'p1',
            change: const NewEventTarget('New'),
            calls: ['create New', 'move b1 p1→p9'],
            bill: 'b1',
          ),
          (
            name: 'in a bill, leave: my tx unlinks (the bill stays)',
            current: 'p1',
            change: const RemoveFromEvent(),
            calls: ['unlink t1'],
            bill: 'b1',
          ),
          (
            name: 'same event: no call',
            current: 'p2',
            change: const ExistingEventTarget(_project),
            calls: [],
            bill: 'b1',
          ),
          (
            name: 'nothing to leave: no call',
            current: null,
            change: const RemoveFromEvent(),
            calls: [],
            bill: null,
          ),
        ];
    for (final c in cases) {
      final repo = _Repo();
      await applyEventChange(
        repo,
        txRepo: _TxRepo(repo.calls),
        txId: 't1',
        amount: 120,
        currentProjectId: c.current,
        change: c.change,
        billId: c.bill,
      );
      expect(repo.calls, c.calls, reason: c.name);
    }
  });
}
