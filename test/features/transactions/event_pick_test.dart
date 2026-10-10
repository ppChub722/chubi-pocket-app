import 'package:chubi_pocket/features/categories/domain/category.dart';
import 'package:chubi_pocket/features/categories/domain/category_type.dart';
import 'package:chubi_pocket/features/projects/data/projects_repository.dart';
import 'package:chubi_pocket/features/projects/domain/project.dart';
import 'package:chubi_pocket/features/transactions/domain/transaction.dart';
import 'package:chubi_pocket/features/transactions/presentation/widgets/event_pick.dart';
import 'package:flutter_test/flutter_test.dart';

Transaction _tx({
  String type = 'expense',
  bool author = true,
  bool locked = false,
  String? repays,
}) => Transaction.fromJson({
  'id': 't1',
  'account_id': 'a1',
  'type': type,
  'amount': 100,
  'date': '2026-10-10',
  'can_edit_category': author,
  'is_locked': locked,
  'source_personal_debt_id': ?repays,
});

const _project = Project(
  id: 'p2',
  ownerUserId: 'u1',
  name: 'Trip',
  status: ProjectStatus.active,
);

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
  }) async {
    calls.add('bills $projectId $transactionIds move=$move');
    return _ok;
  }

  @override
  Future<void> removeBill(String projectId, String transactionId) async {
    calls.add('remove $projectId $transactionId');
  }
}

void main() {
  group('txCanJoinEvent', () {
    test('my own expense / income can', () {
      expect(txCanJoinEvent(_tx()), isTrue);
      expect(txCanJoinEvent(_tx(type: 'income')), isTrue);
    });

    test('a transfer, another member’s row, a locked row can’t', () {
      expect(txCanJoinEvent(_tx(type: 'transfer')), isFalse);
      expect(txCanJoinEvent(_tx(author: false)), isFalse);
      expect(txCanJoinEvent(_tx(locked: true)), isFalse);
    });

    test('a debt repayment or a system category can’t', () {
      expect(txCanJoinEvent(_tx(repays: 'd1')), isFalse);
      const system = Category(
        id: 'c',
        name: 'Opening Balance',
        type: CategoryType.income,
        isSystem: true,
      );
      expect(txCanJoinEvent(_tx(), category: system), isFalse);
    });
  });

  group('applyEventChange', () {
    late _Repo repo;
    setUp(() => repo = _Repo());

    Future<void> apply(String? current, EventTarget change) => applyEventChange(
      repo,
      txId: 't1',
      currentProjectId: current,
      change: change,
    );

    test('none → existing: bills, no move', () async {
      await apply(null, const ExistingEventTarget(_project));
      expect(repo.calls, ['bills p2 [t1] move=false']);
    });

    test('none → new: quick, no move', () async {
      await apply(null, const NewEventTarget('Trip'));
      expect(repo.calls, ['quick Trip [t1] move=false']);
    });

    test('A → B: move', () async {
      await apply('p1', const ExistingEventTarget(_project));
      await apply('p1', const NewEventTarget('New'));
      expect(repo.calls, [
        'bills p2 [t1] move=true',
        'quick New [t1] move=true',
      ]);
    });

    test('A → none: DELETE; same event / nothing to leave: no call', () async {
      await apply('p1', const RemoveFromEvent());
      await apply('p2', const ExistingEventTarget(_project));
      await apply(null, const RemoveFromEvent());
      expect(repo.calls, ['remove p1 t1']);
    });
  });
}
