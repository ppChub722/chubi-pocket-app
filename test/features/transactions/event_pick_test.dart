import 'package:chubi_pocket/features/projects/data/projects_repository.dart';
import 'package:chubi_pocket/features/projects/domain/project.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/event_pick.dart';
import 'package:flutter_test/flutter_test.dart';

const _project = Project(
  id: 'p2',
  ownerUserId: 'u1',
  name: 'Trip',
  status: ProjectStatus.active,
);

class _Patch extends Fake implements EventPatch {}

/// Records the event calls.
class _Repo extends Fake implements ProjectsRepository {
  final calls = <String>[];

  QuickCreateResult get _ok =>
      const QuickCreateResult(project: _project, linkedCount: 1);

  @override
  Future<QuickCreateResult> quickCreate({
    required String name,
    Map<String, dynamic>? newTransaction,
    List<String> transactionIds = const [],
    bool move = false,
    Map<String, dynamic>? people,
  }) async {
    calls.add('quick $name $transactionIds move=$move');
    return _ok;
  }

  @override
  Future<QuickCreateResult> addBills(
    String projectId, {
    Map<String, dynamic>? newTransaction,
    List<String> transactionIds = const [],
    bool move = false,
    Map<String, dynamic>? people,
  }) async {
    calls.add('bills $projectId $transactionIds move=$move');
    return _ok;
  }

  @override
  Future<void> removeBill(String projectId, String transactionId) async {
    calls.add('remove $projectId $transactionId');
  }

  @override
  Future<({List<String> relinked, EventPatch patch})> setMyBooks(
    String projectId,
    String ptId, {
    List<String> link = const [],
    List<String> unlink = const [],
  }) async {
    calls.add('books $projectId $ptId unlink=$unlink');
    return (relinked: const <String>[], patch: _Patch());
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
            name: 'none → existing: bills, no move',
            current: null,
            change: const ExistingEventTarget(_project),
            calls: ['bills p2 [t1] move=false'],
            bill: null,
          ),
          (
            name: 'none → new: quick, no move',
            current: null,
            change: const NewEventTarget('Trip'),
            calls: ['quick Trip [t1] move=false'],
            bill: null,
          ),
          (
            name: 'A → B existing: move',
            current: 'p1',
            change: const ExistingEventTarget(_project),
            calls: ['bills p2 [t1] move=true'],
            bill: null,
          ),
          (
            name: 'A → new: move',
            current: 'p1',
            change: const NewEventTarget('New'),
            calls: ['quick New [t1] move=true'],
            bill: null,
          ),
          (
            name: 'A → none, no bill: DELETE',
            current: 'p1',
            change: const RemoveFromEvent(),
            calls: ['remove p1 t1'],
            bill: null,
          ),
          (
            name: 'A → none, in a bill: disconnect only (bill stays)',
            current: 'p1',
            change: const RemoveFromEvent(),
            calls: ['books p1 b1 unlink=[tx]'],
            bill: 'b1',
          ),
          (
            name: 'same event: no call',
            current: 'p2',
            change: const ExistingEventTarget(_project),
            calls: [],
            bill: null,
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
        txId: 't1',
        currentProjectId: c.current,
        change: c.change,
        billId: c.bill,
      );
      expect(repo.calls, c.calls, reason: c.name);
    }
  });
}
