import 'package:dio/dio.dart';

import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../domain/category.dart';

class CategoriesRepository {
  CategoriesRepository({required ApiClient client}) : _client = client;

  final ApiClient _client;

  Future<Category> create(Category draft) async {
    try {
      final res = await _client.dio.post<Map<String, dynamic>>(
        '/categories',
        data: draft.toCreateJson(),
      );
      return Category.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CategoryDetail> get(String id) async {
    try {
      final res = await _client.dio.get<Map<String, dynamic>>(
        '/categories/$id',
      );
      return CategoryDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CategoryDetail> update(Category category) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/categories/${category.id}',
        data: category.toUpdateJson(),
      );
      return CategoryDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PUT /v1/categories/:id` with only `include_in_report` (the view-mode
  /// switch; the BE leaves every field not sent as it is).
  Future<CategoryDetail> setIncludeInReport(String id, bool on) async {
    try {
      final res = await _client.dio.put<Map<String, dynamic>>(
        '/categories/$id',
        data: <String, dynamic>{'include_in_report': on},
      );
      return CategoryDetail.fromJson(res.data!);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<Category>> delete(String id) async {
    try {
      final res = await _client.dio.delete<Map<String, dynamic>>(
        '/categories/$id',
      );
      final data = (res.data?['reparented'] as List?) ?? const [];
      return data.cast<Map<String, dynamic>>().map(Category.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// `PATCH /v1/categories/reorder` — atomic batch (parent_id, sort_order)
  /// rewrite.
  Future<List<Category>> reorder(List<Category> entries) async {
    try {
      final body = <String, dynamic>{
        'categories': [
          for (final c in entries)
            <String, dynamic>{
              'id': c.id,
              'parent_id': c.parentId,
              'sort_order': c.sortOrder,
            },
        ],
      };
      final res = await _client.dio.patch<Map<String, dynamic>>(
        '/categories/reorder',
        data: body,
      );
      final data = (res.data!['data'] as List).cast<Map<String, dynamic>>();
      return data.map(Category.fromJson).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
