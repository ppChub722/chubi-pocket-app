import 'dart:convert';

import 'package:chubi_pocket/core/network/api_client.dart';
import 'package:chubi_pocket/core/network/api_exception.dart';
import 'package:chubi_pocket/features/categories/data/categories_repository.dart';
import 'package:chubi_pocket/features/categories/domain/category.dart';
import 'package:chubi_pocket/features/categories/presentation/category_errors.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeApi extends Fake implements ApiClient {
  _FakeApi(this.dio);

  @override
  final Dio dio;
}

/// Records the request; answers with [body].
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

/// The shape the server sends (list + detail carry the month figures).
final _prodJson = <String, dynamic>{
  'id': 'cat1',
  'name': 'Food',
  'type': 'expense',
  'include_in_report': true,
  'month_spent': 5100,
  'month_count': 12,
};

void main() {
  test('model: month figures parse (absent = 0), the detail carries the path', () {
    final c = Category.fromJson(_prodJson);
    expect(c.monthSpent, 5100);
    expect(c.monthCount, 12);
    final bare = Category.fromJson({'id': 'x', 'name': 'x', 'type': 'income'});
    expect(bare.monthSpent, 0);
    expect(bare.monthCount, 0);

    final child = CategoryDetail.fromJson({
      'id': 'cat2',
      'name': 'Lunch',
      'type': 'expense',
      'parent_id': 'p2',
      'path': [
        {
          'id': 'p1',
          'name': 'Eating Out',
          'icon_code': {'icon': 'food', 'color': 'orange'},
        },
        {'id': 'p2', 'name': 'Restaurants'},
      ],
    });
    expect(child.path.map((p) => p.name), ['Eating Out', 'Restaurants']);
    expect(child.path.first.iconCode, isNotNull);
    expect(child.path.last.iconCode, isNull);
  });

  test('repository: the view switch sends only include_in_report', () async {
    final http = _Adapter()..body = _prodJson;
    final repo = CategoriesRepository(
      client: _FakeApi(Dio()..httpClientAdapter = http),
    );

    await repo.setIncludeInReport('cat1', false);

    expect(http.last!.method, 'PUT');
    expect(http.last!.path, '/categories/cat1');
    expect(http.last!.data, {'include_in_report': false});
  });

  test('a duplicate name is the 422 code or the old 400 code', () {
    final cases = [
      (
        name: '422 CATEGORY_NAME_DUPLICATE',
        error: const ApiException(
          code: 'CATEGORY_NAME_DUPLICATE',
          message: 'duplicate',
          statusCode: 422,
          details: {'field': 'name'},
        ),
        want: true,
      ),
      (
        name: '400 DUPLICATE_NAME',
        error: const ApiException(
          code: 'DUPLICATE_NAME',
          message: 'dup',
          statusCode: 400,
        ),
        want: true,
      ),
      (
        name: 'another 422',
        error: const ApiException(
          code: 'VALIDATION_ERROR',
          message: 'bad',
          statusCode: 422,
        ),
        want: false,
      ),
    ];
    for (final c in cases) {
      expect(isCategoryNameDuplicate(c.error), c.want, reason: c.name);
    }
  });
}
