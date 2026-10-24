import 'dart:convert';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/features/projects/data/projects_repository.dart';
import 'package:chubi_pocket/features/projects/domain/project.dart';
import 'package:chubi_pocket/features/projects/presentation/cubit/projects_cubit.dart';
import 'package:chubi_pocket/features/projects/presentation/event_delete_choice.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'event_fixtures.dart';

class _FakeApi extends Fake implements ApiClient {
  _FakeApi(this.dio);

  @override
  final Dio dio;
}

class _Adapter implements HttpClientAdapter {
  Object? body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<dynamic>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    last = options;
    return ResponseBody.fromString(
      jsonEncode(body),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

class _Repo extends Fake implements ProjectsRepository {
  int totalPages = 1;
  final lists = <({String? status, int page})>[];
  final calls = <String>[];

  @override
  Future<ProjectPage> list({
    String? status,
    String? q,
    List<String> tagIds = const [],
    ProjectSort? sort,
    int page = 1,
    int perPage = 20,
  }) async {
    lists.add((status: status, page: page));
    return ProjectPage(
      projects: [
        for (var i = 0; i < 2; i++)
          Project.fromJson(eventJson(id: 'p$page-$i', name: 'Event $page-$i')),
      ],
      page: page,
      totalPages: totalPages,
      summary: ProjectListSummary.fromJson(listSummaryJson()),
    );
  }

  @override
  Future<EventPatch> archive(String id) async {
    calls.add('archive $id');
    return EventPatch.fromJson({
      ...patchJson(),
      'event': eventJson(id: id, status: 'archived'),
    });
  }

  @override
  Future<Map<String, double>> delete(
    String id, {
    bool deleteLinkedTxs = false,
  }) async {
    calls.add('delete $id txs=$deleteLinkedTxs');
    return const {'a1': 900};
  }
}

void main() {
  test('events list: the status goes to the server as is; paging appends and '
      'stops at the last page', () async {
    final repo = _Repo()..totalPages = 2;
    final cubit = ProjectsCubit(repository: repo);
    for (final status in ['current', 'unsettled', 'ended']) {
      await cubit.load(statusFilter: status);
      expect(repo.lists.last, (status: status, page: 1), reason: status);
    }
    expect(repo.lists, hasLength(3));

    await cubit.loadMore();
    expect(repo.lists.last, (status: 'ended', page: 2));
    expect(cubit.state.projects.map((p) => p.id), [
      'p1-0',
      'p1-1',
      'p2-0',
      'p2-1',
    ]);
    expect(cubit.state.hasMore, isFalse);
    await cubit.loadMore();
    expect(repo.lists, hasLength(4));
    await cubit.close();
  });

  test('archive is one call and the event leaves the current list; delete '
      'passes the txs choice and drops the row', () async {
    final repo = _Repo();
    final cubit = ProjectsCubit(repository: repo);
    await cubit.load();

    await cubit.archive('p1-0');
    expect(repo.calls, ['archive p1-0']);
    expect(cubit.state.projects.map((p) => p.id), ['p1-1']);

    final balances = await cubit.delete('p1-1', deleteLinkedTxs: true);
    expect(repo.calls.last, 'delete p1-1 txs=true');
    expect(balances, {'a1': 900});
    expect(cubit.state.projects, isEmpty);

    await cubit.load();
    await cubit.delete('p1-0');
    expect(repo.calls.last, 'delete p1-0 txs=false');
    expect(repo.lists, hasLength(2));
    await cubit.close();
  });

  test('delete dialog: the choice is the txs flag; closed or "not now" is no '
      'call', () {
    for (final c in [
      (choice: null, want: null),
      (choice: DeleteChoice.notYet, want: null),
      (choice: DeleteChoice.keepTxs, want: false),
      (choice: DeleteChoice.withTxs, want: true),
    ]) {
      expect(deleteLinkedTxsOf(c.choice), c.want, reason: '${c.choice}');
    }
  });

  test('event requests: status, page, delete_linked_txs only when asked, '
      'archive is one POST', () async {
    final http = _Adapter();
    final repo = ProjectsRepository(
      client: _FakeApi(Dio()..httpClientAdapter = http),
    );

    http.body = {
      'data': [eventJson()],
      'pagination': {'page': 2, 'total_pages': 3},
      'summary': listSummaryJson(),
    };
    final page = await repo.list(status: 'ended', page: 2);
    expect(http.last!.path, '/projects');
    expect(http.last!.queryParameters['status'], 'ended');
    expect(http.last!.queryParameters['page'], '2');
    expect((page.page, page.totalPages), (2, 3));

    http.body = {
      'account_balances': [
        {'account_id': 'a1', 'balance': 900},
      ],
    };
    expect(await repo.delete('e1', deleteLinkedTxs: true), {'a1': 900});
    expect(http.last!.method, 'DELETE');
    expect(http.last!.path, '/projects/e1');
    expect(http.last!.queryParameters, {'delete_linked_txs': 'true'});
    await repo.delete('e1');
    expect(http.last!.queryParameters, isEmpty);

    http.body = patchJson();
    await repo.archive('e1');
    expect(http.last!.method, 'POST');
    expect(http.last!.path, '/projects/e1/archive');
  });
}
