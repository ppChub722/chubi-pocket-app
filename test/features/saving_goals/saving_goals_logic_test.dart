import 'dart:convert';
import 'dart:typed_data';

import 'package:chubi_pocket/core/data/data_changes.dart';
import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/core/storage/secure_token_storage.dart';
import 'package:chubi_pocket/features/saving_goals/data/saving_goals_repository.dart';
import 'package:chubi_pocket/features/saving_goals/domain/saving_goals_overview.dart';
import 'package:chubi_pocket/features/saving_goals/presentation/cubit/saving_goals_cubit.dart';
import 'package:chubi_pocket/features/saving_goals/presentation/saving_goal_delete_guard.dart';
import 'package:chubi_pocket/ui/ui.dart' show Currencies;
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'saving_goal_parse_test.dart' show prodDetail, prodList;

class _NoTokens extends Fake implements SecureTokenStorage {
  @override
  Future<String?> readAuthToken() async => null;
}

class _Adapter implements HttpClientAdapter {
  _Adapter(this.body);
  Map<String, dynamic> body;
  RequestOptions? last;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
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

class _Repo extends Fake implements SavingGoalsRepository {
  bool networkDown = false;
  int listCalls = 0;
  final sorts = <String>[];

  @override
  Future<SavingGoalsOverview> list({
    String status = 'active',
    String sort = 'created',
  }) async {
    sorts.add(sort);
    listCalls++;
    if (networkDown) {
      throw const ApiException(code: 'NETWORK_ERROR', message: 'no connection');
    }
    return SavingGoalsOverview.fromJson(prodList());
  }
}

void main() {
  test('the list reloads on a saving-goals change and keeps its rows', () async {
    final repo = _Repo();
    final cubit = SavingGoalsCubit(repository: repo);
    addTearDown(cubit.close);
    await DataChanges.instance.changed({DataTable.savingGoals});
    expect(repo.listCalls, 0, reason: 'never opened: untouched');
    await cubit.load();
    expect(repo.sorts, ['created']);
    await DataChanges.instance.changed({DataTable.transactions});
    expect(repo.listCalls, 1, reason: 'other tables do not reload it');
    await DataChanges.instance.changed({DataTable.savingGoals});
    expect(repo.listCalls, 2);
    repo.networkDown = true;
    await cubit.load();
    expect(cubit.state.status, SavingGoalsStatus.error);
    expect(cubit.state.overview.goals, hasLength(1));
    repo.networkDown = false;
    await cubit.setSort(SavingGoalsSort.deadline);
    expect(repo.sorts.last, 'deadline');
    expect(cubit.state.status, SavingGoalsStatus.loaded);
    expect(SavingGoalsSort.needFirst.query, 'created');
    expect(SavingGoalsSort.byName.query, 'name');
  });

  test('delete guard: money held blocks, GOAL_HAS_SAVINGS says close first', () {
    for (final c in <({String name, SavingDeletePreview? preview, bool blocked})>[
      (name: 'no preview', preview: null, blocked: false),
      (
        name: 'money held',
        preview: const SavingDeletePreview(
          entries: 4,
          savedAmount: 52000,
          canDelete: false,
        ),
        blocked: true,
      ),
      (
        name: 'empty goal',
        preview: const SavingDeletePreview(
          entries: 4,
          savedAmount: 0,
          canDelete: true,
        ),
        blocked: false,
      ),
    ]) {
      expect(deleteBlockedByMoney(c.preview), c.blocked, reason: c.name);
    }
    for (final c in [('GOAL_HAS_SAVINGS', true), ('NETWORK_ERROR', false)]) {
      expect(
        deleteRefusedForMoney(ApiException(code: c.$1, message: 'x')),
        c.$2,
        reason: c.$1,
      );
    }
  });

  test('the user currency symbol; an unknown code shows as itself', () {
    for (final c in [
      ('THB', '฿'),
      ('USD', r'$'),
      ('EUR', '€'),
      ('XYZ', 'XYZ'),
    ]) {
      expect(Currencies.symbolOf(c.$1), c.$2, reason: c.$1);
    }
  });

  test('repository requests', () async {
    final adapter = _Adapter(prodDetail());
    final repo = SavingGoalsRepository(
      client: ApiClient(
        tokenStorage: _NoTokens(),
        dio: Dio()..httpClientAdapter = adapter,
        baseUrl: 'http://test',
        appBuild: () async => null,
        timezone: () async => null,
      ),
    );
    final calls = <({
      String name,
      Future<void> Function() run,
      String method,
      String path,
      Map<String, dynamic> query,
    })>[
      (
        name: 'detail',
        run: () => repo.detail('g1'),
        method: 'GET',
        path: '/saving-goals/g1',
        query: {},
      ),
      (
        name: 'detail with the delete preview',
        run: () => repo.detail('g1', deletePreview: true),
        method: 'GET',
        path: '/saving-goals/g1',
        query: {'include': 'delete_preview'},
      ),
    ];
    for (final c in calls) {
      await c.run();
      expect(adapter.last!.method, c.method, reason: c.name);
      expect(adapter.last!.path, c.path, reason: c.name);
      expect(adapter.last!.queryParameters, c.query, reason: c.name);
    }
  });
}
