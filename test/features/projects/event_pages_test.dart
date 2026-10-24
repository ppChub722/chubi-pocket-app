import 'package:chubi_pocket/features/projects/data/projects_repository.dart';
import 'package:chubi_pocket/features/projects/domain/project.dart';
import 'package:chubi_pocket/features/projects/presentation/project_board_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'event_fixtures.dart';

class _Repo extends Fake implements ProjectsRepository {
  final calls = <String>[];
  final payers = <String?>[];

  @override
  Future<List<ProjectTransaction>> listTransactions(
    String projectId, {
    int page = 1,
    int perPage = 20,
    String? type,
    bool mine = false,
    String? q,
    String? tagId,
    String? sort,
    String? payerMemberId,
  }) async {
    calls.add('bills tag=$tagId mine=$mine');
    payers.add(payerMemberId);
    return ProjectTransaction.flatten(
      boardRowJson(id: 'b9', description: 'Tagged bill'),
    );
  }
}

void main() {
  test('the payer filter is ONE server call with payer_member_id', () async {
    final repo = _Repo();
    final board = ProjectBoardController(repository: repo, projectId: 'e1');
    await board.change(payerId: 'm-lee');
    expect(repo.payers, ['m-lee']);
    expect(repo.calls, ['bills tag=null mine=false']);
    expect(board.serverFiltered, isTrue);
    await board.change(payerId: null);
    expect(repo.calls.length, 1);
    expect(board.rows, isNull);
    board.dispose();
  });
}
